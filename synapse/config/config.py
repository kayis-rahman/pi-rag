"""
Synapse Configuration - OS-Aware Unified Configuration

Single source of truth for all synapse configuration.
Detects OS and applies appropriate defaults.

Configuration Priority (lowest to highest):
1. OS-specific defaults
2. Project config (.synapse/config.json)
3. User config (~/.synapse/config.json)
4. Environment variables (SYNAPSE_*)
5. CLI arguments

Config Values:
- shortname: "sy" (used for MCP tools and CLI)
"""

import os
import json
import platform
from pathlib import Path
from typing import Dict, Any, Optional
from functools import lru_cache

# Project shortname - used for MCP tools and CLI
SHORTNAME = "sy"


class SynapseConfig:
    """Unified configuration manager for synapse with OS-aware defaults."""

    def __init__(self):
        self._config: Dict[str, Any] = {}
        self._loaded = False

    @property
    def config_dir(self) -> Path:
        """Get configuration directory based on OS."""
        system = platform.system()
        if system == "Darwin":
            return Path.home() / ".synapse"
        elif system == "Linux":
            return Path("/opt/synapse")
        else:
            return Path.home() / ".synapse"

    @property
    def data_dir(self) -> Path:
        """Get data directory (creates if missing)."""
        system = platform.system()
        if system == "Darwin":
            data_path = Path.home() / ".synapse" / "data"
        elif system == "Linux":
            opt_path = Path("/opt/synapse/data")
            if opt_path.exists() and os.access(opt_path, os.W_OK):
                data_path = opt_path
            else:
                data_path = Path.home() / ".synapse" / "data"
        else:
            data_path = Path.home() / ".synapse" / "data"

        data_path.mkdir(parents=True, exist_ok=True)
        return data_path

    @property
    def database_path(self) -> Path:
        """Get main database path."""
        return self.data_dir / "memory.db"

    @property
    def index_dir(self) -> Path:
        """Get semantic index directory."""
        return self.data_dir / "semantic_index"

    @property
    def registry_path(self) -> Path:
        """Get project registry database path."""
        return self.data_dir / "registry.db"

    @property
    def episodic_db_path(self) -> Path:
        """Get episodic memory database path."""
        return self.data_dir / "episodic.db"

    @property
    def logs_dir(self) -> Path:
        """Get logs directory."""
        logs_path = self.data_dir / "logs"
        logs_path.mkdir(parents=True, exist_ok=True)
        return logs_path

    @property
    def models_dir(self) -> Path:
        """Get models directory."""
        models_path = Path.home() / ".synapse" / "models"
        models_path.mkdir(parents=True, exist_ok=True)
        return models_path

    def load(self) -> None:
        """Load configuration from all sources."""
        if self._loaded:
            return

        # Start with OS-specific defaults
        self._load_os_defaults()

        # Apply project config
        self._load_project_config()

        # Apply user config
        self._load_user_config()

        # Apply environment overrides
        self._load_env_overrides()

        self._loaded = True

    def _load_os_defaults(self) -> None:
        """Load OS-specific default configuration."""
        system = platform.system()

        # Determine environment
        if system == "Darwin":
            env = "user_home"
        elif system == "Linux":
            opt_path = Path("/opt/synapse/data")
            if opt_path.exists() and os.access(opt_path, os.W_OK):
                env = "native"
            else:
                env = "user_home"
        else:
            env = "user_home"

        defaults = {
            "shortname": SHORTNAME,
            "environment": env,
            "chunk_size": 500,
            "chunk_overlap": 50,
            "top_k": 3,
            "min_retrieval_score": 0.3,
            "embedding_model": "bge-m3-q8_0.gguf",
            "chat_model": "gemma-3-1b-it-UD-Q4_K_XL.gguf",
            "mcp_port": 8002,
            "mcp_host": "0.0.0.0",
            "semantic_memory_enabled": True,
            "episodic_memory_enabled": True,
            "symbolic_memory_enabled": True,
            "query_expansion_enabled": True,
            "num_expansions": 3,
            "data_dir": "",  # Set below based on OS
            "models_dir": "",  # Set below based on OS
            "docs_dir": "",  # Set below based on OS
            "logs_dir": "",  # Set below based on OS
            "index_dir": "",  # Set below based on OS
            "rag_index_dir": "",  # Set below based on OS (alias for index_dir)
        }

        # OS-specific data directory
        if system == "Darwin":
            defaults["data_dir"] = str(Path.home() / ".synapse" / "data")
            defaults["models_dir"] = str(Path.home() / ".synapse" / "models")
            defaults["docs_dir"] = str(Path.home() / ".synapse" / "docs")
            defaults["logs_dir"] = str(Path.home() / ".synapse" / "logs")
            defaults["index_dir"] = str(Path.home() / ".synapse" / "data" / "semantic_index")
            defaults["rag_index_dir"] = str(Path.home() / ".synapse" / "data" / "semantic_index")
        elif system == "Linux":
            opt_path = Path("/opt/synapse/data")
            if opt_path.exists() and os.access(opt_path, os.W_OK):
                defaults["data_dir"] = "/opt/synapse/data"
                defaults["models_dir"] = "/opt/synapse/models"
                defaults["docs_dir"] = "/opt/synapse/docs"
                defaults["logs_dir"] = "/opt/synapse/data/logs"
                defaults["index_dir"] = "/opt/synapse/data/semantic_index"
                defaults["rag_index_dir"] = "/opt/synapse/data/semantic_index"
            else:
                defaults["data_dir"] = str(Path.home() / ".synapse" / "data")
                defaults["models_dir"] = str(Path.home() / ".synapse" / "models")
                defaults["docs_dir"] = str(Path.home() / ".synapse" / "docs")
                defaults["logs_dir"] = str(Path.home() / ".synapse" / "logs")
                defaults["index_dir"] = str(Path.home() / ".synapse" / "data" / "semantic_index")
                defaults["rag_index_dir"] = str(Path.home() / ".synapse" / "data" / "semantic_index")
        else:
            defaults["data_dir"] = str(Path.home() / ".synapse" / "data")
            defaults["models_dir"] = str(Path.home() / ".synapse" / "models")
            defaults["docs_dir"] = str(Path.home() / ".synapse" / "docs")
            defaults["logs_dir"] = str(Path.home() / ".synapse" / "logs")
            defaults["index_dir"] = str(Path.home() / ".synapse" / "data" / "semantic_index")
            defaults["rag_index_dir"] = str(Path.home() / ".synapse" / "data" / "semantic_index")

        self._config.update(defaults)

    def _load_project_config(self) -> None:
        """Load project-specific configuration."""
        project_config = Path(".synapse") / "config.json"
        if project_config.exists():
            try:
                with open(project_config, 'r') as f:
                    config = json.load(f)
                self._config.update(config)
            except Exception:
                pass

    def _load_user_config(self) -> None:
        """Load user-wide configuration."""
        user_config = Path.home() / ".synapse" / "config.json"
        if user_config.exists():
            try:
                with open(user_config, 'r') as f:
                    config = json.load(f)
                self._config.update(config)
            except Exception:
                pass

    def _load_env_overrides(self) -> None:
        """Apply environment variable overrides."""
        env_mappings = {
            "SYNAPSE_DATA_DIR": "data_dir",
            "SYNAPSE_INDEX_DIR": "index_path",
            "SYNAPSE_PORT": "mcp_port",
            "SYNAPSE_HOST": "mcp_host",
            "SYNAPSE_CHUNK_SIZE": "chunk_size",
            "SYNAPSE_TOP_K": "top_k",
            "LOG_LEVEL": "log_level",
        }

        for env_var, config_key in env_mappings.items():
            if env_var in os.environ:
                value = os.environ[env_var]
                if config_key in ["mcp_port", "chunk_size", "top_k"]:
                    value = int(value)
                self._config[config_key] = value

    def get(self, key: str, default: Any = None) -> Any:
        """Get configuration value."""
        return self._config.get(key, default)

    def set(self, key: str, value: Any) -> None:
        """Set configuration value."""
        self._config[key] = value

    def __getitem__(self, key: str) -> Any:
        """Enable dict-style subscript access (e.g., config['key'])."""
        return self._config[key]

    def __setitem__(self, key: str, value: Any) -> None:
        """Enable dict-style subscript assignment (e.g., config['key'] = value)."""
        self._config[key] = value

    def __contains__(self, key: str) -> bool:
        """Enable 'in' operator (e.g., 'key' in config)."""
        return key in self._config

    def is_loaded(self) -> bool:
        """Check if configuration has been loaded."""
        return self._loaded


@lru_cache(maxsize=1)
def get_config() -> SynapseConfig:
    """Get configuration singleton."""
    config = SynapseConfig()
    config.load()
    return config


# Convenience accessors
def get_data_dir() -> str:
    """Get the data directory path."""
    return str(get_config().data_dir)


def get_database_path() -> str:
    """Get the database file path."""
    return str(get_config().database_path)


def get_index_dir() -> str:
    """Get the semantic index directory."""
    return str(get_config().index_dir)


def get_shortname() -> str:
    """Get the project shortname."""
    return SHORTNAME


def get_registry_path() -> str:
    """Get the registry database path."""
    return str(get_config().registry_path)


def get_episodic_db_path() -> str:
    """Get the episodic memory database path."""
    return str(get_config().episodic_db_path)


def get_logs_dir() -> str:
    """Get the logs directory path."""
    return str(get_config().logs_dir)


def get_models_dir() -> str:
    """Get the models directory path."""
    return str(get_config().models_dir)
