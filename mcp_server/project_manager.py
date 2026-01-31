"""
Project Manager - Multi-client project isolation with ChromaDB.

Manages projects with:
- name-shortUUID format
- Isolated databases per project
- Isolated ChromaDB per project (Option A)
- Central project registry
"""
import os
import json
import shutil
import sqlite3
import uuid
from typing import Dict, List, Any, Optional
from datetime import datetime
from pathlib import Path
import logging

logger = logging.getLogger(__name__)


def generate_short_uuid(length: int = 8) -> str:
    """Generate short UUID."""
    return str(uuid.uuid4())[:length]


class ProjectManager:
    """
    Manages multi-client projects with complete isolation.

    Each project gets:
    - Isolated memory.db (symbolic memory)
    - Isolated episodic.db (episodic memory)
    - Isolated ChromaDB instance (semantic memory)
    - Project metadata
    """

    def __init__(self, base_data_dir: Optional[str] = None):
        """
        Initialize project manager.

        Args:
            base_data_dir: Base data directory (auto-detected if None)
        """
        if base_data_dir is None:
            base_data_dir = self._get_os_aware_data_dir()
        self.base_data_dir = base_data_dir
        self.registry_db = os.path.join(base_data_dir, "registry.db")
        self._init_registry()

    def _get_os_aware_data_dir(self) -> str:
        """
        Get data directory with OS-aware detection.
        
        Priority:
        1. Environment variable (RAG_DATA_DIR)
        2. Config file (data_dir or index_path)
        3. OS-specific defaults:
           - macOS: ~/.synapse/data
           - Linux: /opt/synapse/data (if writable), else ~/.synapse/data
           - Windows: ~/.synapse/data
        """
        import platform
        
        # Priority 1: Environment variable
        if "RAG_DATA_DIR" in os.environ:
            data_dir = os.environ["RAG_DATA_DIR"]
            logger.info(f"Using data directory from environment: {data_dir}")
            return data_dir
        
        # Priority 2: Config file
        try:
            config_path = os.environ.get("RAG_CONFIG_PATH", "./configs/rag_config.json")
            if os.path.exists(config_path):
                with open(config_path, 'r') as f:
                    config = json.load(f)
                    if "data_dir" in config:
                        data_dir = config["data_dir"]
                        logger.info(f"Using data directory from config: {data_dir}")
                        return data_dir
                    if "index_path" in config:
                        data_dir = os.path.dirname(config["index_path"])
                        logger.info(f"Using data directory from index_path: {data_dir}")
                        return data_dir
        except Exception as e:
            logger.warning(f"Failed to read data dir from config: {e}")
        
        # Priority 3: OS-specific defaults
        system = platform.system()
        
        if system == "Darwin":  # macOS
            data_dir = os.path.expanduser("~/.synapse/data")
            logger.info(f"Using macOS default data directory: {data_dir}")
            return data_dir
        
        elif system == "Linux":
            system_path = "/opt/synapse/data"
            if os.access(system_path, os.W_OK):
                logger.info(f"Using Linux system data directory: {system_path}")
                return system_path
            data_dir = os.path.expanduser("~/.synapse/data")
            logger.info(f"Linux system path not writable, using user home: {data_dir}")
            return data_dir
        
        else:  # Windows and others
            data_dir = os.path.expanduser("~/.synapse/data")
            logger.info(f"Using default data directory: {data_dir}")
            return data_dir

    def _init_registry(self):
        """Initialize project registry database."""
        os.makedirs(os.path.dirname(self.registry_db), exist_ok=True)

        with sqlite3.connect(self.registry_db) as conn:
            cursor = conn.cursor()

            # Create projects table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS projects (
                    project_id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    short_uuid TEXT NOT NULL,
                    chroma_path TEXT,
                    created_at TEXT,
                    updated_at TEXT,
                    status TEXT DEFAULT 'active',
                    metadata TEXT
                )
            """)

            conn.commit()
            logger.info(f"Project registry initialized at {self.registry_db}")

    def create_project(
        self,
        name: str,
        metadata: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Create new isolated project.

        Args:
            name: Project name (e.g., "myproject", "anotherapp")
            metadata: Optional additional metadata

        Returns:
            Project metadata dict
        """
        short_uuid = generate_short_uuid()
        project_id = f"{name}-{short_uuid}"
        project_dir = os.path.join(self.base_data_dir, project_id)

        # Validate project name
        self._validate_project_name(name)

        # Create project directory structure
        os.makedirs(project_dir, exist_ok=True)

        # Create ChromaDB directory
        chroma_dir = os.path.join(project_dir, "chroma_semantic")
        os.makedirs(chroma_dir, exist_ok=True)

        # Initialize databases (they'll be created on first use)
        # Just create empty files to reserve the paths
        Path(os.path.join(project_dir, "memory.db")).touch()
        Path(os.path.join(project_dir, "episodic.db")).touch()

        # Create project metadata file
        project_metadata = {
            "project_id": project_id,
            "name": name,
            "short_uuid": short_uuid,
            "chroma_path": chroma_dir,
            "created_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat(),
            "status": "active"
        }

        if metadata:
            project_metadata.update(metadata)

        # Save project metadata
        with open(os.path.join(project_dir, "project.json"), 'w') as f:
            json.dump(project_metadata, f, indent=2)

        # Register in global registry
        self._register_project(project_metadata)

        logger.info(f"Created project: {project_id}")

        return project_metadata

    def delete_project(self, project_id: str) -> bool:
        """
        Delete project and all its data.

        Args:
            project_id: Project identifier

        Returns:
            True if deleted, False if not found
        """
        # Validate project exists
        project = self.get_project(project_id)
        if not project:
            logger.warning(f"Project not found: {project_id}")
            return False

        # Unregister from registry
        self._unregister_project(project_id)

        # Delete entire project directory (includes DBs and ChromaDB)
        project_dir = os.path.join(self.base_data_dir, project_id)
        if os.path.exists(project_dir):
            shutil.rmtree(project_dir)
            logger.info(f"Deleted project directory: {project_dir}")

        return True

    def get_project(self, project_id: str) -> Optional[Dict[str, Any]]:
        """
        Get project metadata.

        Args:
            project_id: Project identifier

        Returns:
            Project metadata dict or None
        """
        with sqlite3.connect(self.registry_db) as conn:
            cursor = conn.cursor()
            cursor.execute(
                "SELECT * FROM projects WHERE project_id = ?",
                (project_id,)
            )
            row = cursor.fetchone()

            if row:
                return {
                    "project_id": row[0],
                    "name": row[1],
                    "short_uuid": row[2],
                    "chroma_path": row[3],
                    "created_at": row[4],
                    "updated_at": row[5],
                    "status": row[6],
                    "metadata": json.loads(row[7]) if row[7] else {}
                }

            return None

    def list_projects(
        self,
        status_filter: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        List all projects.

        Args:
            status_filter: Optional filter by status

        Returns:
            List of project metadata dicts
        """
        with sqlite3.connect(self.registry_db) as conn:
            cursor = conn.cursor()

            if status_filter:
                cursor.execute(
                    "SELECT * FROM projects WHERE status = ?",
                    (status_filter,)
                )
            else:
                cursor.execute("SELECT * FROM projects")

            rows = cursor.fetchall()

            return [
                {
                    "project_id": row[0],
                    "name": row[1],
                    "short_uuid": row[2],
                    "chroma_path": row[3],
                    "created_at": row[4],
                    "updated_at": row[5],
                    "status": row[6],
                    "metadata": json.loads(row[7]) if row[7] else {}
                }
                for row in rows
            ]

    def validate_project_id(self, project_id: str) -> bool:
        """
        Validate project exists and is accessible.

        Args:
            project_id: Project identifier

        Returns:
            True if valid, False otherwise
        """
        project_dir = os.path.join(self.base_data_dir, project_id)
        return os.path.isdir(project_dir)

    def get_project_dir(self, project_id: str) -> str:
        """
        Get project directory path.

        Args:
            project_id: Project identifier

        Returns:
            Project directory path

        Raises:
            ValueError: If project not found
        """
        if not self.validate_project_id(project_id):
            raise ValueError(f"Project not found: {project_id}")

        return os.path.join(self.base_data_dir, project_id)

    def _validate_project_name(self, name: str) -> None:
        """
        Validate project name.

        Args:
            name: Project name

        Raises:
            ValueError: If name is invalid
        """
        # Check for invalid characters
        invalid_chars = ['/', '\\', ':', '*', '?', '"', '<', '>', '|']
        for char in invalid_chars:
            if char in name:
                raise ValueError(f"Project name cannot contain '{char}'")

        # Check length
        if len(name) < 1 or len(name) > 100:
            raise ValueError("Project name must be 1-100 characters")

        # Check for spaces at start/end
        if name != name.strip():
            raise ValueError("Project name cannot start or end with spaces")

    def _register_project(self, metadata: Dict[str, Any]) -> None:
        """Register project in global registry."""
        with sqlite3.connect(self.registry_db) as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT OR REPLACE INTO projects
                (project_id, name, short_uuid, chroma_path, created_at, updated_at, status, metadata)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                metadata["project_id"],
                metadata["name"],
                metadata["short_uuid"],
                metadata.get("chroma_path", ""),
                metadata["created_at"],
                metadata["updated_at"],
                metadata.get("status", "active"),
                json.dumps({k: v for k, v in metadata.items()
                           if k not in ["project_id", "name", "short_uuid", "chroma_path", "created_at", "updated_at", "status"]})
            ))
            conn.commit()

    def _unregister_project(self, project_id: str) -> None:
        """Unregister project from global registry."""
        with sqlite3.connect(self.registry_db) as conn:
            cursor = conn.cursor()
            cursor.execute(
                "DELETE FROM projects WHERE project_id = ?",
                (project_id,)
            )
            conn.commit()
