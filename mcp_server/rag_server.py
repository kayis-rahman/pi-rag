"""
DEPRECATED: RAG MCP Server - Model Context Protocol server for RAG memory system.

This module is DEPRECATED and will be removed in a future version.

Use mcp_server.http_wrapper instead - it provides the active MCP server
implementation with FastMCP and HTTP transport.

Last Updated: 2026-02-08

---

This was a thin, stateless wrapper that exposes RAG memory functionality
via the MCP protocol with stdio transport.

Memory Authority Hierarchy (ENFORCED):
1. SYMBOLIC MEMORY (Authoritative - Highest)
2. EPISODIC MEMORY (Advisory - Medium)
3. SEMANTIC MEMORY (Non-authoritative - Lowest)

Features:
- 7 MCP tools for memory operations
- Project ID management with short UUIDs
- Comprehensive error handling with logging
- Detailed metrics tracking
- Docker deployment ready
"""

import asyncio
import json
import logging
import os
import uuid
from typing import Dict, List, Any, Optional
from datetime import datetime

# MCP SDK imports
from mcp.server import Server
from mcp.types import Tool, TextContent, ImageContent, EmbeddedResource

# RAG system imports
from rag import (
    MemoryStore, MemoryFact, get_memory_store,
    EpisodicStore, Episode, get_episodic_store,
    SemanticStore, get_semantic_store,
    SemanticIngestor, get_semantic_ingestor,
    SemanticRetriever, get_semantic_retriever
)
from rag.auto_learning_tracker import AutoLearningTracker
from rag.learning_extractor import LearningExtractor
from rag.model_manager import get_model_manager
from rag.conversation_analyzer import ConversationAnalyzer

# Local imports
from .metrics import Metrics, get_metrics
from .project_manager import ProjectManager
from synapse.config import get_shortname


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Deprecation warning
import warnings
warnings.warn(
    "rag_server.py is deprecated. Use mcp_server.http_wrapper instead. "
    "This module will be removed in a future version.",
    DeprecationWarning,
    stacklevel=2
)
logger.warning("DEPRECATED: rag_server.py is deprecated. Use mcp_server.http_wrapper instead.")


class RAGMemoryBackend:
    """
    Thin, stateless wrapper for RAG memory operations.

    This class delegates all memory operations to the RAG Python APIs.
    It does not maintain state, ensuring the server remains stateless.

    Authority Hierarchy:
    - Symbolic memory is authoritative (highest priority)
    - Episodic memory is advisory (medium priority)
    - Semantic memory is non-authoritative (lowest priority)
    """

    def __init__(self):
        """Initialize RAG backend (lazy initialization of stores)."""
        self._symbolic_store: Optional[MemoryStore] = None
        self._episodic_store: Optional[EpisodicStore] = None
        self._semantic_store: Optional[SemanticStore] = None
        self._semantic_ingestor: Optional[SemanticIngestor] = None
        self._semantic_retriever: Optional[SemanticRetriever] = None

        # Metrics
        self.metrics: Metrics = get_metrics()
        self.metrics.load_metrics()

        # Project Manager for dynamic project resolution
        self.project_manager = ProjectManager()
        self._project_cache: Dict[str, str] = {}

        # Upload configuration for remote file ingestion
        self._upload_config = self._load_upload_config()

        # Auto-learning components
        self.auto_learning_config = self._load_auto_learning_config()
        self._auto_learning_tracker: Optional[AutoLearningTracker] = None
        self._learning_extractor: Optional[LearningExtractor] = None
        self.operation_buffer: List[Dict[str, Any]] = []

        # Initialize auto-learning if enabled
        if self.auto_learning_config.get("enabled", False):
            self._auto_learning_tracker = AutoLearningTracker(
                config=self.auto_learning_config,
                model_manager=get_model_manager()
            )
            self._learning_extractor = LearningExtractor(
                model_manager=get_model_manager()
            )
            logger.info(f"Auto-learning enabled: mode={self.auto_learning_config.get('mode', 'moderate')}")

        # Universal hooks configuration
        self.universal_hooks_config = self._load_universal_hooks_config()

    def _get_data_dir(self) -> str:
        """
        Get data directory using OS-aware config.

        Uses the new synapse.config module for consistent path resolution
        across all platforms.

        Returns:
            Path to data directory (always exists and is writable)
        """
        from synapse.config import get_data_dir
        data_dir = get_data_dir()
        logger.info(f"Using data directory from config: {data_dir}")
        return data_dir

    def _ensure_data_dir(self) -> None:
        """
        Ensure data directory exists and is writable.

        Creates the directory if missing and validates write access.
        Logs the data directory path for debugging.
        """
        data_dir = self._get_data_dir()
        Path(data_dir).mkdir(parents=True, exist_ok=True)

        # Verify it's writable
        test_file = Path(data_dir) / ".write_test"
        try:
            test_file.write_text("test")
            test_file.unlink()
            logger.debug(f"Data directory verified writable: {data_dir}")
        except Exception as e:
            logger.error(f"Data directory not writable: {data_dir}: {e}")
            raise

    def _get_symbolic_store(self) -> MemoryStore:
        """Get or create symbolic memory store (Phase 1)."""
        if self._symbolic_store is None:
            db_path = os.path.join(self._get_data_dir(), "memory.db")
            logger.info(f"Initializing symbolic memory store at: {db_path}")
            self._symbolic_store = get_memory_store(db_path)
        return self._symbolic_store

    def _get_episodic_store(self) -> EpisodicStore:
        """Get or create episodic memory store (Phase 3)."""
        if self._episodic_store is None:
            db_path = os.path.join(self._get_data_dir(), "episodic.db")
            logger.info(f"Initializing episodic memory store at: {db_path}")
            self._episodic_store = get_episodic_store(db_path)
        return self._episodic_store

    def _get_semantic_store(self) -> SemanticStore:
        """Get or create semantic memory store (Phase 4)."""
        if self._semantic_store is None:
            index_path = os.path.join(self._get_data_dir(), "semantic_index")
            logger.info(f"Initializing semantic memory store at: {index_path}")
            self._semantic_store = get_semantic_store(index_path)
        return self._semantic_store

    def _get_semantic_ingestor(self) -> SemanticIngestor:
        """Get or create semantic ingestor."""
        if self._semantic_ingestor is None:
            self._semantic_ingestor = get_semantic_ingestor(
                semantic_store=self._get_semantic_store()
            )
        return self._semantic_ingestor

    def _get_semantic_retriever(self) -> SemanticRetriever:
        """Get or create semantic retriever."""
        if self._semantic_retriever is None:
            self._semantic_retriever = get_semantic_retriever(
                semantic_store=self._get_semantic_store()
            )
        return self._semantic_retriever

    def generate_short_uuid(self) -> str:
        """
        Generate short UUID for project ID.

        Returns:
            Short UUID string (8 characters)
        """
        return str(uuid.uuid4())[:8]

    def _load_upload_config(self) -> Dict[str, Any]:
        """
        Load upload configuration from config file and environment.

        Returns:
            Upload configuration dictionary
        """
        import json

        config = {
            "enabled": True,
            "directory": "/tmp/rag-uploads",
            "max_age": 3600,
            "max_size_mb": 50
        }

        # Load from environment variables (highest priority)
        config["enabled"] = os.environ.get("RAG_REMOTE_UPLOAD_ENABLED", "true").lower() == "true"
        config["directory"] = os.environ.get("RAG_UPLOAD_DIR", config["directory"])
        config["max_age"] = int(os.environ.get("RAG_UPLOAD_MAX_AGE", str(config["max_age"])))
        config["max_size_mb"] = int(os.environ.get("RAG_UPLOAD_MAX_SIZE", str(config["max_size_mb"])))

        # Load from config file (medium priority)
        try:
            config_path = os.environ.get("RAG_CONFIG_PATH", "./configs/rag_config.json")
            if os.path.exists(config_path):
                with open(config_path, 'r') as f:
                    file_config = json.load(f)

                if "remote_file_upload_enabled" in file_config:
                    config["enabled"] = file_config["remote_file_upload_enabled"]
                if "remote_upload_directory" in file_config:
                    config["directory"] = file_config["remote_upload_directory"]
                if "remote_upload_max_age_seconds" in file_config:
                    config["max_age"] = file_config["remote_upload_max_age_seconds"]
                if "remote_upload_max_file_size_mb" in file_config:
                    config["max_size_mb"] = file_config["remote_upload_max_file_size_mb"]
        except Exception as e:
            logger.warning(f"Failed to load upload config: {e}")

        logger.info(f"Upload config: enabled={config['enabled']}, dir={config['directory']}")

        return config

    def _load_auto_learning_config(self) -> Dict[str, Any]:
        """
        Load automatic learning configuration from rag_config.json.

        Returns:
            Auto-learning configuration dictionary
        """
        config = {
            "enabled": False,
            "mode": "moderate",
            "track_tasks": True,
            "track_code_changes": True,
            "track_operations": True,
            "min_episode_confidence": 0.6,
            "episode_deduplication": True
        }

        try:
            config_path = os.environ.get("RAG_CONFIG_PATH", "./configs/rag_config.json")
            if os.path.exists(config_path):
                with open(config_path, 'r') as f:
                    file_config = json.load(f)

                if "automatic_learning" in file_config:
                    auto_config = file_config["automatic_learning"]
                    config["enabled"] = auto_config.get("enabled", config["enabled"])
                    config["mode"] = auto_config.get("mode", config["mode"])
                    config["track_tasks"] = auto_config.get("track_tasks", config["track_tasks"])
                    config["track_code_changes"] = auto_config.get("track_code_changes", config["track_code_changes"])
                    config["track_operations"] = auto_config.get("track_operations", config["track_operations"])
                    config["min_episode_confidence"] = auto_config.get("min_episode_confidence", config["min_episode_confidence"])
                    config["episode_deduplication"] = auto_config.get("episode_deduplication", config["episode_deduplication"])
        except Exception as e:
            logger.warning(f"Failed to load auto-learning config: {e}, using defaults")

        logger.info(f"Auto-learning config: enabled={config['enabled']}, mode={config['mode']}")

        return config

    def _load_universal_hooks_config(self) -> Dict[str, Any]:
        """
        Load universal hooks configuration from rag_config.json.

        Returns:
            Universal hooks configuration dictionary
        """
        config = {
            "enabled": True,
            "default_project_id": "synapse",
            "adapters": {},
            "conversation_analyzer": {
                "extraction_mode": "heuristic",
                "use_llm": False,
                "min_fact_confidence": 0.7,
                "min_episode_confidence": 0.6,
                "deduplicate_facts": True,
                "deduplicate_episodes": True,
                "deduplication_mode": "per_day",
                "deduplication_window_days": 7
            },
            "performance": {
                "async_processing": True,
                "analyze_every_n_messages": 1,
                "timeout_ms": 5000
            }
        }

        try:
            config_path = os.environ.get("RAG_CONFIG_PATH", "./configs/rag_config.json")
            if os.path.exists(config_path):
                with open(config_path, 'r') as f:
                    file_config = json.load(f)

                if "universal_hooks" in file_config:
                    hooks_config = file_config["universal_hooks"]
                    config["enabled"] = hooks_config.get("enabled", config["enabled"])
                    config["default_project_id"] = hooks_config.get("default_project_id", config["default_project_id"])
                    config["adapters"] = hooks_config.get("adapters", config["adapters"])

                    # Merge conversation_analyzer config
                    if "conversation_analyzer" in hooks_config:
                        for key, value in hooks_config["conversation_analyzer"].items():
                            config["conversation_analyzer"][key] = value

                    # Merge performance config
                    if "performance" in hooks_config:
                        for key, value in hooks_config["performance"].items():
                            config["performance"][key] = value
        except Exception as e:
            logger.warning(f"Failed to load universal hooks config: {e}, using defaults")

        logger.info(f"Universal hooks config: enabled={config['enabled']}, extraction_mode={config['conversation_analyzer']['extraction_mode']}")

        return config

    def _ensure_upload_directory(self) -> str:
        """
        Ensure upload directory exists.

        Returns:
            Upload directory path
        """
        upload_dir = self._upload_config["directory"]

        # Create directory if not exists
        os.makedirs(upload_dir, exist_ok=True)

        # Set permissions (owner read/write only)
        try:
            os.chmod(upload_dir, 0o700)
        except Exception as e:
            logger.warning(f"Failed to set permissions on {upload_dir}: {e}")

        return upload_dir

    def _validate_remote_file_path(
        self,
        file_path: str
    ) -> tuple:
        """
        Validate that file path is within allowed directory.

        Args:
            file_path: Absolute file path to validate

        Returns:
            Tuple of (is_valid, error_message)
        """
        # Normalize path
        abs_path = os.path.abspath(file_path)
        upload_dir = os.path.abspath(self._upload_config["directory"])

        # Check if remote upload is enabled
        if not self._upload_config["enabled"]:
            return (False, "Remote file upload is disabled")

        # Check if within upload directory
        if not abs_path.startswith(upload_dir):
            return (False, f"File path must be within upload directory: {upload_dir}")

        # Check if path tries to escape with symlinks (realpath)
        real_path = os.path.realpath(abs_path)
        if not real_path.startswith(upload_dir):
            return (False, "File path contains invalid symlinks")

        # Check if file exists
        if not os.path.isfile(real_path):
            return (False, f"File not found: {abs_path}")

        # Check file size
        file_size = os.path.getsize(real_path)
        max_size = self._upload_config["max_size_mb"] * 1024 * 1024
        if file_size > max_size:
            size_mb = file_size / (1024 * 1024)
            return (False, f"File too large: {size_mb:.1f}MB (max: {self._upload_config['max_size_mb']}MB)")

        # Check file permissions
        if not os.access(real_path, os.R_OK):
            return (False, "File not readable")

        return (True, "")

    def _cleanup_old_uploads(self) -> None:
        """
        Clean up old uploaded files.
        """
        import time

        upload_dir = self._ensure_upload_directory()
        max_age = self._upload_config["max_age"]
        current_time = time.time()

        for filename in os.listdir(upload_dir):
            file_path = os.path.join(upload_dir, filename)

            # Skip directories
            if not os.path.isfile(file_path):
                continue

            # Check age
            file_age = current_time - os.path.getmtime(file_path)

            if file_age > max_age:
                try:
                    os.remove(file_path)
                    logger.info(f"Cleaned up old upload: {filename}")
                except Exception as e:
                    logger.warning(f"Failed to clean up {filename}: {e}")

    async def _delete_upload_file_async(self, file_path: str) -> None:
        """
        Delete uploaded file asynchronously after successful ingestion.

        Args:
            file_path: Path to file to delete
        """
        try:
            # Small delay to ensure ingestion completes
            await asyncio.sleep(0.5)

            if os.path.exists(file_path):
                os.remove(file_path)
                logger.info(f"Auto-deleted uploaded file after ingestion: {file_path}")
            else:
                logger.warning(f"File already deleted or not found: {file_path}")
        except Exception as e:
            logger.warning(f"Failed to auto-delete file {file_path}: {e}")

    async def list_projects(
        self,
        scope_type: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        List all projects in RAG memory system.

        Args:
            scope_type: Optional filter by scope type

        Returns:
            Dict with projects list and metadata
        """
        project_id = "global"
        start_time = datetime.now()

        # Build operation record
        operation = {
            "tool_name": "sy.list_projects",
            "project_id": project_id,
            "arguments": {"scope_type": scope_type},
            "start_time": start_time
        }

        request_id = self.metrics.record_tool_call(project_id, "list_projects")

        try:
            logger.info(f"Listing projects with scope_type filter: {scope_type}")

            # Get all scopes from symbolic memory
            symbolic_store = self._get_symbolic_store()

            # Collect unique scopes
            projects = list(symbolic_store.VALID_SCOPES)

            # Filter if scope_type specified
            if scope_type:
                projects = [p for p in projects if p == scope_type]

            operation["result"] = "success"
            operation["outcome"] = "completed"

            self.metrics.record_tool_completion(project_id, "list_projects", request_id)

            return {
                "projects": projects,
                "total": len(projects),
                "message": f"Found {len(projects)} project(s)",
                "authority": "system"
            }

        except Exception as e:
            operation["result"] = "error"
            operation["outcome"] = "failed"
            operation["error"] = str(e)

            logger.error(f"Error listing projects: {e}", exc_info=True)
            self.metrics.record_tool_completion(
                project_id, "list_projects", request_id,
                error=True, error_message=str(e)
            )
            raise
        finally:
            # Calculate duration
            operation["duration_ms"] = (datetime.now() - start_time).total_seconds() * 1000
            operation["timestamp"] = start_time

            # Track operation (if auto-learning enabled)
            if self._auto_learning_tracker and self._should_auto_track(operation):
                self._auto_learning_tracker.track_operation(operation)
                self.operation_buffer.append(operation)

    async def list_sources(
        self,
        project_id: str,
        source_type: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        List document sources for a project in semantic memory.

        Args:
            project_id: Project identifier
            source_type: Optional filter by source type (file, code, web)

        Returns:
            Dict with sources list and metadata
        """
        start_time = datetime.now()
        operation = {
            "tool_name": "sy.list_sources",
            "project_id": project_id,
            "arguments": {"source_type": source_type},
            "start_time": start_time
        }

        request_id = self.metrics.record_tool_call(project_id, "list_sources")

        try:
            logger.info(f"Listing sources for project {project_id} with type filter: {source_type}")

            semantic_store = self._get_semantic_store()

            # Get all chunks
            sources = {}
            for chunk in semantic_store.chunks:
                src = chunk.metadata.get("source", "unknown")
                src_type = chunk.metadata.get("type", "unknown")

                # Filter by source_type if specified
                if source_type and src_type != source_type:
                    continue

                if src not in sources:
                    sources[src] = {
                        "path": src,
                        "type": src_type,
                        "doc_type": src_type,
                        "chunk_count": 0,
                        "last_updated": chunk.created_at
                    }

                sources[src]["chunk_count"] += 1

            sources_list = list(sources.values())

            operation["result"] = "success"
            operation["outcome"] = "completed"

            self.metrics.record_tool_completion(project_id, "list_sources", request_id)

            return {
                "sources": sources_list,
                "total": len(sources_list),
                "message": f"Found {len(sources_list)} source(s)",
                "authority": "non-authoritative"
            }

        except Exception as e:
            operation["result"] = "error"
            operation["outcome"] = "failed"
            operation["error"] = str(e)

            logger.error(f"Error listing sources for project {project_id}: {e}", exc_info=True)
            self.metrics.record_tool_completion(
                project_id, "list_sources", request_id,
                error=True, error_message=str(e)
            )
            raise
        finally:
            operation["duration_ms"] = (datetime.now() - start_time).total_seconds() * 1000
            operation["timestamp"] = start_time

            if self._auto_learning_tracker and self._should_auto_track(operation):
                self._auto_learning_tracker.track_operation(operation)
                self.operation_buffer.append(operation)

    async def get_context(
        self,
        project_id: str,
        context_type: str = "all",
        query: Optional[str] = None,
        max_results: int = 10
    ) -> Dict[str, Any]:
        """
        Get project context with authority hierarchy.

        Returns context respecting authority order:
        1. Symbolic memory (authoritative)
        2. Episodic memory (advisory)
        3. Semantic memory (non-authoritative)

        Args:
            project_id: Project identifier
            context_type: Type of context (all, symbolic, episodic, semantic)
            query: Optional query for semantic retrieval
            max_results: Maximum results per memory type

        Returns:
            Dict with context from each memory type
        """
        start_time = datetime.now()
        operation = {
            "tool_name": "sy.get_context",
            "project_id": project_id,
            "arguments": {
                "context_type": context_type,
                "query": query,
                "max_results": max_results
            },
            "start_time": start_time
        }

        request_id = self.metrics.record_tool_call(project_id, "get_context")

        try:
            logger.info(
                f"Getting context for project {project_id}: "
                f"type={context_type}, query={query}, max_results={max_results}"
            )

            result = {
                "symbolic": [],
                "episodic": [],
                "semantic": [],
                "message": ""
            }

            # Get symbolic memory (authoritative - highest priority)
            if context_type in ["all", "symbolic"]:
                symbolic_store = self._get_symbolic_store()
                facts = symbolic_store.query_memory(
                    scope=project_id,
                    min_confidence=0.5
                )

                result["symbolic"] = [
                    {
                        **fact.to_dict(),
                        "authority": "authoritative"
                    }
                    for fact in facts[:max_results]
                ]

                logger.debug(f"Retrieved {len(result['symbolic'])} symbolic facts")

            # Get episodic memory (advisory - medium priority)
            if context_type in ["all", "episodic"]:
                episodic_store = self._get_episodic_store()
                episodes = episodic_store.list_recent_episodes(
                    project_id=project_id,  # FIX: Pass project_id to filter by scope
                    days=30,
                    min_confidence=0.5,
                    limit=max_results
                )

                result["episodic"] = [
                    {
                        **episode.to_dict(),
                        "authority": "advisory"
                    }
                    for episode in episodes
                ]

                logger.debug(f"Retrieved {len(result['episodic'])} episodic episodes")

            # Get semantic memory (non-authoritative - lowest priority)
            if context_type in ["all", "semantic"] and query:
                retriever = self._get_semantic_retriever()

                try:
                    results = retriever.retrieve(
                        query=query,
                        trigger="external_info_needed",
                        top_k=max_results
                    )

                    result["semantic"] = [
                        {
                            "chunk_id": r["chunk_id"],
                            "content": r["content"],
                            "source": r["metadata"].get("source", "unknown"),
                            "similarity": r["score"],
                            "citation": f"[source:{r['chunk_id']}]",
                            "authority": "non-authoritative"
                        }
                        for r in results
                    ]

                    logger.debug(f"Retrieved {len(result['semantic'])} semantic chunks")

                except ValueError as e:
                    # Trigger validation error
                    logger.warning(f"Semantic retrieval trigger validation failed: {e}")
                    result["semantic"] = []

            # Build message
            total_results = len(result["symbolic"]) + len(result["episodic"]) + len(result["semantic"])
            result["message"] = f"Retrieved {total_results} context item(s)"

            operation["result"] = "success"
            operation["outcome"] = "completed"

            self.metrics.record_tool_completion(project_id, "get_context", request_id)

            return result

        except Exception as e:
            operation["result"] = "error"
            operation["outcome"] = "failed"
            operation["error"] = str(e)

            logger.error(f"Error getting context for project {project_id}: {e}", exc_info=True)
            self.metrics.record_tool_completion(
                project_id, "get_context", request_id,
                error=True, error_message=str(e)
            )
            raise
        finally:
            operation["duration_ms"] = (datetime.now() - start_time).total_seconds() * 1000
            operation["timestamp"] = start_time

            if self._auto_learning_tracker and self._should_auto_track(operation):
                self._auto_learning_tracker.track_operation(operation)
                self.operation_buffer.append(operation)
                
                # Check for task completion
                task_completion = self._auto_learning_tracker.detect_task_completion()
                if task_completion and self.auto_learning_config.get("track_tasks", True):
                    self._auto_store_episode(project_id, task_completion)

                # Check for patterns
                pattern = self._auto_learning_tracker.detect_pattern()
                if pattern and self.auto_learning_config.get("track_operations", True):
                    self._auto_store_episode(project_id, pattern)

    async def search(
        self,
        project_id: str,
        query: str,
        memory_type: str = "all",
        top_k: int = 10,
        situation_contains: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Semantic search across all memory types.

        Args:
            project_id: Project identifier
            query: Search query
            memory_type: Memory type to search (all, symbolic, episodic, semantic)
            top_k: Number of results
            situation_contains: For episodic search, filter by situation content

        Returns:
            Dict with search results
        """
        start_time = datetime.now()
        operation = {
            "tool_name": "sy.search",
            "project_id": project_id,
            "arguments": {
                "query": query,
                "memory_type": memory_type,
                "top_k": top_k,
                "situation_contains": situation_contains
            },
            "start_time": start_time
        }

        request_id = self.metrics.record_tool_call(project_id, "search")

        try:
            logger.info(
                f"Searching for project {project_id}: "
                f"query='{query}', type={memory_type}, top_k={top_k}"
            )

            results = []

            # Search symbolic memory (authoritative)
            if memory_type in ["all", "symbolic"]:
                symbolic_store = self._get_symbolic_store()
                # Enable partial matching with wildcards
                search_key = f"%{query}%" if '%' not in query and '_' not in query else query
                facts = symbolic_store.query_memory(
                    key=search_key,  # Use LIKE pattern with wildcards for partial matching
                    min_confidence=0.0
                )

                for fact in facts[:top_k]:
                    results.append({
                        "type": "symbolic",
                        "authority": "authoritative",
                        **fact.to_dict()
                    })

                logger.debug(f"Found {len([r for r in results if r['type'] == 'symbolic'])} symbolic results")

            # Search episodic memory (advisory)
            if memory_type in ["all", "episodic"]:
                episodic_store = self._get_episodic_store()
                # Use situation_contains if provided, otherwise search by lesson
                episodes = episodic_store.query_episodes(
                    project_id=project_id,  # Add required project_id parameter
                    lesson=query if not situation_contains else None,
                    situation_contains=situation_contains,
                    min_confidence=0.0,
                    limit=top_k
                )

                for episode in episodes:
                    results.append({
                        "type": "episodic",
                        "authority": "advisory",
                        **episode.to_dict()
                    })

                logger.debug(f"Found {len([r for r in results if r['type'] == 'episodic'])} episodic results")

            # Search semantic memory (non-authoritative)
            if memory_type in ["all", "semantic"]:
                retriever = self._get_semantic_retriever()

                try:
                    semantic_results = retriever.retrieve(
                        query=query,
                        trigger="external_info_needed",
                        top_k=top_k
                    )

                    for r in semantic_results:
                        results.append({
                            "type": "semantic",
                            "authority": "non-authoritative",
                            "chunk_id": r["chunk_id"],
                            "content": r["content"],
                            "source": r["metadata"].get("source", "unknown"),
                            "similarity": r["score"],
                            "citation": f"[source:{r['chunk_id']}]"
                        })

                    logger.debug(f"Found {len([r for r in results if r['type'] == 'semantic'])} semantic results")

                except ValueError as e:
                    logger.warning(f"Semantic retrieval trigger validation failed: {e}")

            # Sort results by authority (symbolic first, then episodic, then semantic)
            authority_order = {"symbolic": 0, "episodic": 1, "semantic": 2}
            results.sort(key=lambda x: authority_order.get(x["type"], 99))

            operation["result"] = "success"
            operation["outcome"] = "completed"

            self.metrics.record_tool_completion(project_id, "search", request_id)

            return {
                "results": results[:top_k],
                "total": len(results),
                "message": f"Found {len(results)} result(s)"
            }

        except Exception as e:
            operation["result"] = "error"
            operation["outcome"] = "failed"
            operation["error"] = str(e)

            logger.error(f"Error searching for project {project_id}: {e}", exc_info=True)
            self.metrics.record_tool_completion(
                project_id, "search", request_id,
                error=True, error_message=str(e)
            )
            raise
        finally:
            operation["duration_ms"] = (datetime.now() - start_time).total_seconds() * 1000
            operation["timestamp"] = start_time

            if self._auto_learning_tracker and self._should_auto_track(operation):
                self._auto_learning_tracker.track_operation(operation)
                self.operation_buffer.append(operation)

                # Check for task completion
                task_completion = self._auto_learning_tracker.detect_task_completion()
                if task_completion and self.auto_learning_config.get("track_tasks", True):
                    self._auto_store_episode(project_id, task_completion)

                # Check for patterns
                pattern = self._auto_learning_tracker.detect_pattern()
                if pattern and self.auto_learning_config.get("track_operations", True):
                    self._auto_store_episode(project_id, pattern)

    async def ingest_file(
        self,
        project_id: str,
        file_path: str,
        source_type: str = "file",
        metadata: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Ingest a file into semantic memory.

        Supports remote file uploads:
        - Upload file to server's upload directory first
        - Provide full absolute path to this tool
        - Server validates path and reads file

        Args:
            project_id: Project identifier
            file_path: Path to file to ingest (absolute path)
            source_type: Type of source (file, code, web)
            metadata: Optional metadata to attach

            Returns:
            Dict with ingestion results
        """
        start_time = datetime.now()
        operation = {
            "tool_name": "sy.ingest_file",
            "project_id": project_id,
            "arguments": {
                "file_path": file_path,
                "source_type": source_type,
                "metadata": metadata
            },
            "start_time": start_time
        }

        request_id = self.metrics.record_tool_call(project_id, "ingest_file")

        try:
            logger.info(f"Ingesting file for project {project_id}: {file_path}")

            # Phase A: Ensure upload directory and clean old files
            self._ensure_upload_directory()
            self._cleanup_old_uploads()

            # Phase B: Validate remote file path
            is_valid, error_msg = self._validate_remote_file_path(file_path)
            if not is_valid:
                operation["result"] = "error"
                operation["outcome"] = "validation_failed"

                self.metrics.record_tool_completion(
                    project_id, "ingest_file", request_id,
                    error=True, error_message=error_msg
                )
                return {
                    "status": "error",
                    "error": error_msg,
                    "message": f"File validation failed: {error_msg}"
                }

            # Phase C: Read file from validated path
            real_path = os.path.realpath(os.path.abspath(file_path))
            logger.info(f"Reading file from: {real_path}")

            # Build metadata
            file_metadata = metadata or {}
            file_metadata["project_id"] = project_id
            file_metadata["source_type"] = source_type
            file_metadata["ingested_at"] = datetime.utcnow().isoformat()
            file_metadata["original_path"] = real_path  # Track original path

            # Phase D: Ingest file using existing ingestor
            ingestor = self._get_semantic_ingestor()
            chunk_ids = ingestor.ingest_file(
                file_path=real_path,
                metadata=file_metadata
            )

            # Phase E: Auto-delete uploaded file after successful ingestion (async, non-blocking)
            # Only delete if file is within upload directory (security check)
            upload_dir = os.path.abspath(self._upload_config["directory"])
            if real_path.startswith(upload_dir):
                asyncio.create_task(self._delete_upload_file_async(real_path))
                logger.info(f"Scheduled async deletion of uploaded file: {real_path}")

            # Generate document ID
            doc_id = chunk_ids[0].split("_")[0] if chunk_ids else "unknown"

            self.metrics.record_tool_completion(project_id, "ingest_file", request_id)

            return {
                "status": "success",
                "file_path": file_path,
                "real_path": real_path,
                "chunk_count": len(chunk_ids),
                "doc_id": doc_id,
                "authority": "non-authoritative",
                "message": f"Successfully ingested {len(chunk_ids)} chunk(s)",
                "upload_config": {
                    "enabled": self._upload_config["enabled"],
                    "directory": self._upload_config["directory"],
                    "max_size_mb": self._upload_config["max_size_mb"]
                }
            }

        except Exception as e:
            operation["result"] = "error"
            operation["outcome"] = "failed"
            operation["error"] = str(e)

            logger.error(f"Error ingesting file {file_path} for project {project_id}: {e}", exc_info=True)
            self.metrics.record_tool_completion(
                project_id, "ingest_file", request_id,
                error=True, error_message=str(e)
            )
            raise
        finally:
            operation["duration_ms"] = (datetime.now() - start_time).total_seconds() * 1000
            operation["timestamp"] = start_time

            if self._auto_learning_tracker and self._should_auto_track(operation):
                self._auto_learning_tracker.track_operation(operation)
                self.operation_buffer.append(operation)

                # Auto-extract and store facts from file ingestion
                if operation["result"] == "success" and self._learning_extractor and self.auto_learning_config.get("track_code_changes", True):
                    facts = self._learning_extractor.extract_facts_from_ingestion(real_path)
                    for fact in facts:
                        await self._auto_store_fact(project_id, fact)

                # Check for task completion
                task_completion = self._auto_learning_tracker.detect_task_completion()
                if task_completion and self.auto_learning_config.get("track_tasks", True):
                    self._auto_store_episode(project_id, task_completion)

                # Check for patterns
                pattern = self._auto_learning_tracker.detect_pattern()
                if pattern and self.auto_learning_config.get("track_operations", True):
                    self._auto_store_episode(project_id, pattern)

    async def analyze_conversation(
        self,
        project_id: str,
        user_message: str,
        agent_response: str = "",
        context: Optional[Dict] = None,
        auto_store: bool = True,
        return_only: bool = False,
        extraction_mode: str = "heuristic"
    ) -> Dict[str, Any]:
        """
        Analyze conversation and extract facts/episodes using heuristics.

        Args:
            project_id: Project identifier
            user_message: User's message
            agent_response: Agent's response
            context: Additional context (tool_name, etc.)
            auto_store: Automatically store facts/episodes
            return_only: Return facts/episodes without storing
            extraction_mode: Extraction mode (heuristic/llm/hybrid)

        Returns:
            Dict with facts_stored, episodes_stored, facts, episodes
        """
        start_time = datetime.now()

        # Load conversation analyzer config
        analyzer_config = self.universal_hooks_config["conversation_analyzer"].copy()
        analyzer_config["extraction_mode"] = extraction_mode or analyzer_config["extraction_mode"]

        # Initialize conversation analyzer (no model_manager for heuristics)
        analyzer = ConversationAnalyzer(model_manager=None, config=analyzer_config)

        # Analyze conversation
        try:
            learnings = await analyzer.analyze_conversation_async(
                user_message=user_message,
                agent_response=agent_response,
                context=context
            )

            # Separate facts and episodes
            facts = [l for l in learnings if l["type"] == "fact"]
            episodes = [l for l in learnings if l["type"] == "episode"]

            # Filter by confidence
            min_fact_conf = analyzer_config.get("min_fact_confidence", 0.7)
            min_episode_conf = analyzer_config.get("min_episode_confidence", 0.6)

            facts = [f for f in facts if f.get("confidence", 0) >= min_fact_conf]
            episodes = [e for e in episodes if e.get("confidence", 0) >= min_episode_conf]

            facts_stored = 0
            episodes_stored = 0

            if return_only:
                return {
                    "facts_stored": 0,
                    "episodes_stored": 0,
                    "facts": facts,
                    "episodes": episodes,
                    "duration_ms": (datetime.now() - start_time).total_seconds() * 1000
                }

            if auto_store:
                # Parallel storage of facts and episodes
                storage_tasks = []

                for fact in facts:
                    storage_tasks.append(self.add_fact(
                        project_id=project_id,
                        fact_key=fact.get("key", ""),
                        fact_value=fact.get("value", ""),
                        confidence=fact.get("confidence", 0.8),
                        category="user"
                    ))

                for episode in episodes:
                    storage_tasks.append(self.add_episode(
                        project_id=project_id,
                        title=episode.get("title", ""),
                        content=episode.get("content", ""),
                        lesson_type=episode.get("lesson_type", "pattern"),
                        quality=episode.get("confidence", 0.8)
                    ))

                # Wait for all storage operations to complete
                if storage_tasks:
                    results = await asyncio.gather(*storage_tasks, return_exceptions=True)

                    # Count successful operations
                    facts_stored = sum(1 for r in results if isinstance(r, dict) and r.get("success"))
                    episodes_stored = sum(1 for r in results if isinstance(r, dict) and r.get("success"))

            duration_ms = (datetime.now() - start_time).total_seconds() * 1000

            return {
                "facts_stored": facts_stored,
                "episodes_stored": episodes_stored,
                "facts": facts,
                "episodes": episodes,
                "duration_ms": duration_ms,
                "success": True
            }

        except Exception as e:
            logger.error(f"Conversation analysis failed: {e}", exc_info=True)
            duration_ms = (datetime.now() - start_time).total_seconds() * 1000

            return {
                "facts_stored": 0,
                "episodes_stored": 0,
                "facts": [],
                "episodes": [],
                "duration_ms": duration_ms,
                "success": False,
                "error": str(e)
            }

    async def add_fact(
        self,
        project_id: str,
        fact_key: str,
        fact_value: Any,
        confidence: float = 0.9,
        category: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Add a symbolic memory fact (authoritative).

        Args:
            project_id: Project identifier
            fact_key: The fact key
            fact_value: The fact value
            confidence: Confidence level (0.0-1.0)
            category: Fact category

        Returns:
            Dict with fact creation result
        """
        start_time = datetime.now()
        operation = {
            "tool_name": "sy.add_fact",
            "project_id": project_id,
            "arguments": {
                "fact_key": fact_key,
                "fact_value": fact_value,
                "confidence": confidence,
                "category": category
            },
            "start_time": start_time
        }

        request_id = self.metrics.record_tool_call(project_id, "add_fact")

        try:
            logger.info(
                f"Adding fact for project {project_id}: "
                f"key={fact_key}, confidence={confidence}"
            )

            # Create memory fact
            fact = MemoryFact(
                scope=project_id,
                category=category or "fact",
                key=fact_key,
                value=fact_value,
                confidence=confidence,
                source="agent"
            )

            # Store fact (RAG API handles conflict resolution)
            symbolic_store = self._get_symbolic_store()
            stored_fact = symbolic_store.store_memory(fact)

            operation["result"] = "success"
            operation["outcome"] = "completed"

            self.metrics.record_tool_completion(project_id, "add_fact", request_id)

            return {
                "status": "success",
                "fact_id": stored_fact.id,
                "action": "created",
                "authority": "authoritative",
                "message": "Successfully created fact",
                **stored_fact.to_dict()
            }

        except Exception as e:
            operation["result"] = "error"
            operation["outcome"] = "failed"
            operation["error"] = str(e)

            logger.error(f"Error adding fact for project {project_id}: {e}", exc_info=True)
            self.metrics.record_tool_completion(
                project_id, "add_fact", request_id,
                error=True, error_message=str(e)
            )
            raise
        finally:
            operation["duration_ms"] = (datetime.now() - start_time).total_seconds() * 1000
            operation["timestamp"] = start_time

            if self._auto_learning_tracker and self._should_auto_track(operation):
                self._auto_learning_tracker.track_operation(operation)
                self.operation_buffer.append(operation)

    async def add_episode(
        self,
        project_id: str,
        title: str,
        content: str,
        lesson_type: str = "general",
        quality: float = 0.8
    ) -> Dict[str, Any]:
        """
        Add an episodic memory episode (advisory).

        Args:
            project_id: Project identifier
            title: Episode title
            content: Episode content (situation, action, outcome, lesson)
            lesson_type: Type of lesson
            quality: Quality score (0.0-1.0)

        Returns:
            Dict with episode creation result
        """
        start_time = datetime.now()
        operation = {
            "tool_name": "sy.add_episode",
            "project_id": project_id,
            "arguments": {
                "title": title,
                "content": content,
                "lesson_type": lesson_type,
                "quality": quality
            },
            "start_time": start_time
        }

        request_id = self.metrics.record_tool_call(project_id, "add_episode")

        try:
            logger.info(
                f"Adding episode for project {project_id}: "
                f"title={title}, quality={quality}"
            )

            # Parse episode from content
            # Expected format: "Situation: ... Action: ... Outcome: ... Lesson: ..."
            episode_dict = self._parse_episode_content(content, title)

            # Create episode with project_id
            episode = Episode(
                project_id=project_id,  # Add project_id parameter
                situation=episode_dict["situation"],
                action=episode_dict["action"],
                outcome=episode_dict["outcome"],
                lesson=episode_dict["lesson"],
                confidence=quality
            )

            # Store episode (RAG API validates abstraction)
            episodic_store = self._get_episodic_store()
            stored_episode = episodic_store.store_episode(episode)

            operation["result"] = "success"
            operation["outcome"] = "completed"

            self.metrics.record_tool_completion(project_id, "add_episode", request_id)

            return {
                "status": "success",
                "episode_id": stored_episode.id,
                "authority": "advisory",
                "message": "Successfully created episode",
                **stored_episode.to_dict()
            }

        except Exception as e:
            operation["result"] = "error"
            operation["outcome"] = "failed"
            operation["error"] = str(e)

            logger.error(f"Error adding episode for project {project_id}: {e}", exc_info=True)
            self.metrics.record_tool_completion(
                project_id, "add_episode", request_id,
                error=True, error_message=str(e)
            )
            raise
        finally:
            operation["duration_ms"] = (datetime.now() - start_time).total_seconds() * 1000
            operation["timestamp"] = start_time

            if self._auto_learning_tracker and self._should_auto_track(operation):
                self._auto_learning_tracker.track_operation(operation)
                self.operation_buffer.append(operation)

    def _parse_episode_content(self, content: str, title: str) -> Dict[str, str]:
        """
        Parse episode content into situation, action, outcome, lesson.

        Args:
            content: Episode content
            title: Episode title

        Returns:
            Dict with episode components
        """
        # Try structured format
        parts = {
            "situation": "",
            "action": "",
            "outcome": "",
            "lesson": ""
        }

        # Parse by section markers
        for line in content.split('\n'):
            line = line.strip()
            if line.lower().startswith("situation:"):
                parts["situation"] = line[len("situation:"):].strip()
            elif line.lower().startswith("action:"):
                parts["action"] = line[len("action:"):].strip()
            elif line.lower().startswith("outcome:"):
                parts["outcome"] = line[len("outcome:"):].strip()
            elif line.lower().startswith("lesson:"):
                parts["lesson"] = line[len("lesson:"):].strip()

        # If structured format not found, use title as situation and content as lesson
        if not parts["situation"]:
            parts["situation"] = title
            parts["action"] = "Recorded via MCP"
            parts["outcome"] = "Success"
            parts["lesson"] = content[:500]  # Limit lesson length

        return parts

    def _auto_store_episode(self, project_id: str, episode_data: Dict[str, Any]) -> Optional[str]:
        """
        Automatically store an episode to episodic memory.

        Args:
            project_id: Project identifier
            episode_data: Episode data from tracker/extractor

        Returns:
            Episode ID or None if not stored
        """
        if not self._auto_learning_tracker or not self._learning_extractor:
            return None

        try:
            # Check if tracking enabled for this type
            if episode_data.get("type") == "task_completion" and not self.auto_learning_config.get("track_tasks", True):
                logger.debug(f"Task tracking disabled, skipping episode storage")
                return None

            # Extract episode using LLM
            episode = self._learning_extractor.extract_episode_from_task(episode_data)
            if not episode:
                logger.debug(f"Episode extraction returned None, skipping storage")
                return None

            # Check confidence threshold
            confidence = episode.get("confidence", 0.7)
            min_confidence = self.auto_learning_config.get("min_episode_confidence", 0.6)
            if confidence < min_confidence:
                logger.debug(f"Episode confidence {confidence} below threshold {min_confidence}, skipping")
                return None

            # Check deduplication
            if self.auto_learning_config.get("episode_deduplication", True):
                episodic_store = self._get_episodic_store()
                # Check for similar episodes (same lesson)
                existing_episodes = episodic_store.query_episodes(
                    project_id=project_id,
                    lesson=episode.get("lesson", ""),
                    min_confidence=0.5,
                    limit=5
                )
                for existing in existing_episodes:
                    # Simple similarity check
                    similarity = self._calculate_episode_similarity(
                        episode.get("lesson", ""),
                        existing.lesson
                    )
                    if similarity > 0.85:  # High similarity threshold
                        logger.debug(f"Duplicate episode detected (similarity: {similarity:.2f}), skipping")
                        return None

            # Store episode
            episodic_store = self._get_episodic_store()
            stored_episode = episodic_store.store_episode(
                Episode(
                    project_id=project_id,
                    situation=episode.get("situation", ""),
                    action=episode.get("action", ""),
                    outcome=episode.get("outcome", ""),
                    lesson=episode.get("lesson", ""),
                    confidence=confidence
                )
            )

            logger.info(f"Auto-stored episode: {stored_episode.lesson[:50]}... (id: {stored_episode.id})")
            return str(stored_episode.id)

        except Exception as e:
            logger.error(f"Failed to auto-store episode for project {project_id}: {e}", exc_info=True)
            return None

    def _auto_store_fact(self, project_id: str, fact_data: Dict[str, Any]) -> Optional[str]:
        """
        Automatically store a fact to symbolic memory.

        Args:
            project_id: Project identifier
            fact_data: Fact data from extractor

        Returns:
            Fact ID or None if not stored
        """
        if not self._auto_learning_tracker:
            return None

        try:
            # Check if tracking enabled for facts
            if not self.auto_learning_config.get("track_code_changes", True):
                logger.debug(f"Fact tracking disabled, skipping fact storage")
                return None

            # Extract fact components
            fact_key = fact_data.get("key", "")
            fact_value = fact_data.get("value", {})
            category = fact_data.get("category", "fact")
            confidence = fact_data.get("confidence", 1.0)

            # Check deduplication
            symbolic_store = self._get_symbolic_store()
            existing_facts = symbolic_store.query_memory(
                scope=project_id,
                key=fact_key,
                min_confidence=0.0
            )

            for existing in existing_facts:
                # Check for identical key
                if existing.key == fact_key:
                    logger.debug(f"Duplicate fact key detected: {fact_key}, skipping")
                    return None

            # Store fact
            fact = MemoryFact(
                scope=project_id,
                category=category or "fact",
                key=fact_key,
                value=fact_value,
                confidence=confidence,
                source="auto_learning"
            )

            stored_fact = symbolic_store.store_memory(fact)

            logger.info(f"Auto-stored fact: {fact_key} (id: {stored_fact.id})")
            return str(stored_fact.id)

        except Exception as e:
            logger.error(f"Failed to auto-store fact for project {project_id}: {e}", exc_info=True)
            return None

    def _calculate_episode_similarity(self, lesson1: str, lesson2: str) -> float:
        """
        Calculate similarity between two lesson strings.

        Args:
            lesson1: First lesson string
            lesson2: Second lesson string

        Returns:
            Similarity score (0.0 to 1.0)
        """
        if not lesson1 or not lesson2:
            return 0.0

        # Simple word overlap similarity
        words1 = set(lesson1.lower().split())
        words2 = set(lesson2.lower().split())

        if not words1 or not words2:
            return 0.0

        # Calculate Jaccard similarity
        intersection = words1.intersection(words2)
        union = words1.union(words2)

        return len(intersection) / len(union) if union else 0.0

    def _should_auto_track(self, operation: Dict[str, Any]) -> bool:
        """
        Check if operation should be auto-tracked.

        Args:
            operation: Operation dict with arguments

        Returns:
            True if should track, False otherwise
        """
        # Check for manual override
        auto_learn = operation.get("arguments", {}).get("auto_learn", None)

        if auto_learn is not None:
            # Explicit override - use it
            return auto_learn

        # Default to global setting
        return self.auto_learning_config.get("enabled", False)


# Create MCP server
server = Server("rag-memory-server")
backend = RAGMemoryBackend()


# Define tools
tools = [
    Tool(
        name="sy.add_episode",
        description="Add an advisory episode to episodic memory",
        inputSchema={
            "type": "object",
            "properties": {
                "project_id": {
                    "type": "string",
                    "description": "Project identifier"
                },
                "title": {
                    "type": "string",
                    "description": "Episode title"
                },
                "content": {
                    "type": "string",
                    "description": "Episode content (situation, action, outcome, lesson)"
                },
                "lesson_type": {
                    "type": "string",
                    "description": "Type of lesson (success, pattern, mistake, failure, general)",
                    "enum": ["success", "pattern", "mistake", "failure", "general"],
                    "default": "general"
                },
                "quality": {
                    "type": "number",
                    "description": "Quality score (0.0-1.0)",
                    "minimum": 0.0,
                    "maximum": 1.0
                }
            },
            "required": ["project_id", "title", "content"]
        }
    ),
    Tool(
        name="sy.analyze_conversation",
        description="Analyze conversation for automatic learning of facts and episodes. Works with ANY agent that supports MCP tools. Universal compatibility: Claude Code, OpenCode, Aider, Goose, etc.",
        inputSchema={
            "type": "object",
            "properties": {
                "project_id": {
                    "type": "string",
                    "description": "RAG project ID"
                },
                "user_message": {
                    "type": "string",
                    "description": "User's message (what was said)"
                },
                "agent_response": {
                    "type": "string",
                    "description": "Agent's response (what was replied)"
                },
                "context": {
                    "type": "object",
                    "description": "Optional context (tool calls, session info)"
                },
                "auto_store": {
                    "type": "boolean",
                    "description": "Auto-store learnings (default: true)"
                },
                "return_only": {
                    "type": "boolean",
                    "description": "Return learnings without storing (default: false)"
                },
                "extraction_mode": {
                    "type": "string",
                    "description": "Extraction mode (heuristic, llm, hybrid)",
                    "enum": ["heuristic", "llm", "hybrid"],
                    "default": "hybrid"
                }
            },
            "required": ["project_id", "user_message", "agent_response"]
        }
    ),
    Tool(
        name="sy.list_sources",
        description="List document sources for a project in semantic memory",
        inputSchema={
            "type": "object",
            "required": ["project_id"],
            "properties": {
                "project_id": {
                    "type": "string",
                    "description": "Project identifier"
                },
                "source_type": {
                    "type": "string",
                    "description": "Filter by source type (file, code, web)",
                    "enum": ["file", "code", "web"]
                }
            }
        }
    ),
    Tool(
        name="sy.get_context",
        description="Get comprehensive project context with authority hierarchy",
        inputSchema={
            "type": "object",
            "required": ["project_id"],
            "properties": {
                "project_id": {
                    "type": "string",
                    "description": "Project identifier"
                },
                "context_type": {
                    "type": "string",
                    "description": "Type of context to retrieve",
                    "enum": ["all", "symbolic", "episodic", "semantic"],
                    "default": "all"
                },
                "query": {
                    "type": "string",
                    "description": "Query for semantic retrieval (required if context_type='semantic' or 'all')"
                },
                "max_results": {
                    "type": "number",
                    "description": "Maximum results per memory type",
                    "default": 10
                }
            }
        }
    ),
    Tool(
        name="sy.search",
        description="Semantic search across all memory types",
        inputSchema={
            "type": "object",
            "required": ["project_id", "query"],
            "properties": {
                "project_id": {
                    "type": "string",
                    "description": "Project identifier"
                },
                "query": {
                    "type": "string",
                    "description": "Search query"
                },
                "memory_type": {
                    "type": "string",
                    "description": "Type of memory to search",
                    "enum": ["all", "symbolic", "episodic", "semantic"],
                    "default": "all"
                },
                "top_k": {
                    "type": "number",
                    "description": "Number of results",
                    "default": 10
                },
                "situation_contains": {
                    "type": "string",
                    "description": "For episodic memory search, filter by situation content (optional)"
                }
            }
        }
    ),
    Tool(
        name="sy.ingest_file",
        description="Ingest a file into semantic memory with automatic validation and chunking",
        inputSchema={
            "type": "object",
            "required": ["project_id", "file_path"],
            "properties": {
                "project_id": {
                    "type": "string",
                    "description": "Project identifier"
                },
                "file_path": {
                    "type": "string",
                    "description": "Path to file to ingest"
                },
                "source_type": {
                    "type": "string",
                    "description": "Type of source",
                    "enum": ["file", "code", "web"],
                    "default": "file"
                },
                "metadata": {
                    "type": "object",
                    "description": "Optional metadata to attach"
                }
            }
        }
    ),
    Tool(
        name="sy.add_fact",
        description="Add a symbolic memory fact (authoritative)",
        inputSchema={
            "type": "object",
            "required": ["project_id", "fact_key", "fact_value"],
            "properties": {
                "project_id": {
                    "type": "string",
                    "description": "Project identifier"
                },
                "fact_key": {
                    "type": "string",
                    "description": "The fact key"
                },
                "fact_value": {
                    "description": "The fact value (any JSON-serializable type)"
                },
                "confidence": {
                    "type": "number",
                    "description": "Confidence level (0.0-1.0)",
                    "minimum": 0.0,
                    "maximum": 1.0,
                    "default": 0.9
                },
                "category": {
                    "type": "string",
                    "description": "Fact category (preference, constraint, decision, fact)",
                    "enum": ["preference", "constraint", "decision", "fact"],
                    "default": "fact"
                }
            }
        }
    ),
    Tool(
        name="sy.add_episode",
        description="Add an episodic memory episode (advisory)",
        inputSchema={
            "type": "object",
            "required": ["project_id", "title", "content"],
            "properties": {
                "project_id": {
                    "type": "string",
                    "description": "Project identifier"
                },
                "title": {
                    "type": "string",
                    "description": "Episode title"
                },
                "content": {
                    "type": "string",
                    "description": "Episode content (situation, action, outcome, lesson)"
                },
                "lesson_type": {
                    "type": "string",
                    "description": "Type of lesson",
                    "enum": ["general", "pattern", "mistake", "success", "failure"],
                    "default": "general"
                },
                "quality": {
                    "type": "number",
                    "description": "Quality score (0.0-1.0).",
                    "minimum": 0.0,
                    "maximum": 1.0,
                    "default": 0.8
                }
            }
        }
    ),
    Tool(
        name="sy.analyze_conversation",
        description="Analyze conversation and extract facts/episodes using heuristics (no LLM)",
        inputSchema={
            "type": "object",
            "required": ["project_id", "user_message"],
            "properties": {
                "project_id": {
                    "type": "string",
                    "description": "Project identifier"
                },
                "user_message": {
                    "type": "string",
                    "description": "User's message"
                },
                "agent_response": {
                    "type": "string",
                    "description": "Agent's response",
                    "default": ""
                },
                "context": {
                    "type": "object",
                    "description": "Additional context (tool_name, etc.)"
                },
                "auto_store": {
                    "type": "boolean",
                    "description": "Automatically store facts/episodes in memory",
                    "default": True
                },
                "return_only": {
                    "type": "boolean",
                    "description": "Return facts/episodes without storing",
                    "default": False
                },
                "extraction_mode": {
                    "type": "string",
                    "description": "Extraction mode",
                    "enum": ["heuristic", "llm", "hybrid"],
                    "default": "heuristic"
                }
            }
        }
    )
]


# Tool handlers
@server.call_tool()
async def handle_tool_call(name: str, arguments: Dict[str, Any]) -> List[TextContent]:
    """Handle tool calls and delegate to backend."""

    try:
        if name == "sy.list_projects":
            scope_type = arguments.get("scope_type")
            result = await backend.list_projects(scope_type=scope_type)

        elif name == "sy.list_sources":
            project_id = arguments.get("project_id")
            source_type = arguments.get("source_type")
            result = await backend.list_sources(
                project_id=project_id,
                source_type=source_type
            )

        elif name == "sy.get_context":
            project_id = arguments.get("project_id")
            context_type = arguments.get("context_type", "all")
            query = arguments.get("query")
            max_results = arguments.get("max_results", 10)
            result = await backend.get_context(
                project_id=project_id,
                context_type=context_type,
                query=query,
                max_results=max_results
            )

        elif name == "sy.search":
            project_id = arguments.get("project_id")
            query = arguments.get("query")
            memory_type = arguments.get("memory_type", "all")
            top_k = arguments.get("top_k", 10)
            situation_contains = arguments.get("situation_contains")
            result = await backend.search(
                project_id=project_id,
                query=query,
                memory_type=memory_type,
                top_k=top_k,
                situation_contains=situation_contains
            )

        elif name == "sy.ingest_file":
            project_id = arguments.get("project_id")
            file_path = arguments.get("file_path")
            source_type = arguments.get("source_type", "file")
            metadata = arguments.get("metadata")
            result = await backend.ingest_file(
                project_id=project_id,
                file_path=file_path,
                source_type=source_type,
                metadata=metadata
            )

        elif name == "sy.add_fact":
            project_id = arguments.get("project_id")
            fact_key = arguments.get("fact_key")
            fact_value = arguments.get("fact_value")
            confidence = arguments.get("confidence", 0.9)
            category = arguments.get("category")
            result = await backend.add_fact(
                project_id=project_id,
                fact_key=fact_key,
                fact_value=fact_value,
                confidence=confidence,
                category=category
            )

        elif name == "sy.add_episode":
            project_id = arguments.get("project_id")
            title = arguments.get("title")
            content = arguments.get("content")
            lesson_type = arguments.get("lesson_type", "general")
            quality = arguments.get("quality", 0.8)
            result = await backend.add_episode(
                project_id=project_id,
                title=title,
                content=content,
                lesson_type=lesson_type,
                quality=quality
            )

        elif name == "sy.analyze_conversation":
            project_id = arguments.get("project_id")
            user_message = arguments.get("user_message")
            agent_response = arguments.get("agent_response", "")
            context = arguments.get("context")
            auto_store = arguments.get("auto_store", True)
            return_only = arguments.get("return_only", False)
            extraction_mode = arguments.get("extraction_mode", "heuristic")
            result = await backend.analyze_conversation(
                project_id=project_id,
                user_message=user_message,
                agent_response=agent_response,
                context=context,
                auto_store=auto_store,
                return_only=return_only,
                extraction_mode=extraction_mode
            )

        else:
            raise ValueError(f"Unknown tool: {name}")

        # Return result as JSON text
        return [TextContent(
            type="text",
            text=json.dumps(result, indent=2)
        )]

    except Exception as e:
        logger.error(f"Tool call failed: {name} - {e}", exc_info=True)
        # Return error as JSON text
        return [TextContent(
            type="text",
            text=json.dumps({
                "status": "error",
                "tool": name,
                "error": str(e),
                "message": "Tool execution failed"
            }, indent=2)
        )]


@server.list_tools()
async def list_tools() -> List[Tool]:
    """List all available tools."""
    return tools


# Main entry point
async def main():
    """Main entry point for MCP server."""
    from mcp.server.stdio import stdio_server

    async with stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            server.create_initialization_options()
        )


if __name__ == "__main__":
    logger.info("Starting RAG MCP Server...")
    logger.info(f"Data directory: {os.environ.get('RAG_DATA_DIR', '/app/data')}")
    logger.info(f"Log level: {os.environ.get('LOG_LEVEL', 'INFO')}")
    logger.info(f"Available tools: {len(tools)}")

    # Run server
    asyncio.run(main())
