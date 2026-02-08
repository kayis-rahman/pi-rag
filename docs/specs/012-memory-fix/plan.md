# Memory Fix - Technical Plan

**Feature ID**: 012-memory-fix
**Status**: [In Progress]
**Created**: February 1, 2026
**Last Updated**: February 1, 2026

---

## Implementation Strategy

This plan covers:
1. OS-aware configuration with shortname "sy"
2. MCP tool renaming (rag.* → sy.*)
3. CLI command renaming (rag → sy)
4. Memory persistence bug fix

---

## Plan 1: OS-Aware Configuration

### File: `synapse/config/config.py`

```python
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
        data_path = self.config_dir / "data"
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
    def logs_dir(self) -> Path:
        """Get logs directory."""
        logs_path = self.data_dir / "logs"
        logs_path.mkdir(parents=True, exist_ok=True)
        return logs_path
    
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
        
        defaults = {
            "shortname": SHORTNAME,
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
        }
        
        # OS-specific data directory
        if system == "Darwin":
            defaults["data_dir"] = str(Path.home() / ".synapse" / "data")
        elif system == "Linux":
            opt_path = Path("/opt/synapse/data")
            if opt_path.exists() and os.access(opt_path, os.W_OK):
                defaults["data_dir"] = "/opt/synapse/data"
            else:
                defaults["data_dir"] = str(Path.home() / ".synapse" / "data")
        else:
            defaults["data_dir"] = str(Path.home() / ".synapse" / "data")
        
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
```

### File: `synapse/config/__init__.py`

```python
"""Synapse configuration module."""

from synapse.config.config import (
    SynapseConfig,
    get_config,
    get_data_dir,
    get_database_path,
    get_index_dir,
    get_shortname,
    SHORTNAME,
)

__all__ = [
    "SynapseConfig",
    "get_config",
    "get_data_dir",
    "get_database_path",
    "get_index_dir",
    "get_shortname",
    "SHORTNAME",
]
```

---

## Plan 2: MCP Tool Renaming

### File: `mcp_server/rag_server.py`

**Changes:**
1. Import `get_shortname` from synapse.config
2. Update tool names from `core.*` to `sy.*`

```python
# Add to imports
from synapse.config import get_shortname

# In tool registration, change:
# FROM:
Tool(
    name="rag.list_projects",
    description="...",
    inputSchema=...
)
# TO:
Tool(
    name=f"{get_shortname()}.list_projects",  # "sy.list_projects"
    description="...",
    inputSchema=...
)
```

**All 8 tools to rename:**
- `core.list_projects` → `sy.list_projects`
- `core.list_sources` → `sy.list_sources`
- `core.search` → `sy.search`
- `core.get_context` → `sy.get_context`
- `core.ingest_file` → `sy.ingest_file`
- `core.add_fact` → `sy.add_fact`
- `core.add_episode` → `sy.add_episode`
- `core.analyze_conversation` → `sy.analyze_conversation`

---

## Plan 3: CLI Renaming

### File: `synapse/main.py`

```python
# FROM:
app = typer.Typer(
    name="rag",
    help="SYNAPSE CLI",
    ...
)

# TO:
from synapse.config import get_shortname

app = typer.Typer(
    name=get_shortname(),  # "sy"
    help="SYNAPSE CLI",
    ...
)
```

---

## Plan 4: Memory Bug Fix

### File: `mcp_server/rag_server.py`

**Changes to use new config:**

```python
# FROM:
def _get_data_dir(self) -> str:
    # Hardcoded path that may not exist
    return os.environ.get("SYNAPSE_DATA_DIR", "/opt/synapse/data")

# TO:
from synapse.config import get_data_dir

def _get_data_dir(self) -> str:
    """Get data directory using OS-aware config."""
    return get_data_dir()
```

**Add path validation:**

```python
def _ensure_data_dir(self) -> None:
    """Ensure data directory exists."""
    data_dir = self._get_data_dir()
    Path(data_dir).mkdir(parents=True, exist_ok=True)
    
    # Verify it's writable
    test_file = Path(data_dir) / ".write_test"
    try:
        test_file.write_text("test")
        test_file.unlink()
    except Exception as e:
        logger.error(f"Data directory not writable: {data_dir}: {e}")
```

---

## Plan 5: Semantic Store API Fix

### File: `core/semantic_store.py`

**Ensure search method signature is correct:**

```python
def search(
    self,
    query: str,
    top_k: int = 5,
    filters: Optional[Dict[str, Any]] = None
) -> List[Dict[str, Any]]:
    """
    Search semantic memory.
    
    Args:
        query: Search query string
        top_k: Number of results to return
        filters: Optional metadata filters
        
    Returns:
        List of results with content and score
    """
    # Implementation...
```

---

## Plan 6: Test Files

### File: `tests/unit/test_memory_paths.py`

```python
"""Test database path resolution."""

import pytest
from unittest.mock import patch, MagicMock
from pathlib import Path

class TestConfig:
    """Test configuration with OS detection."""
    
    @patch('synapse.config.config.platform.system')
    def test_macos_data_directory(self, mock_system):
        mock_system.return_value = "Darwin"
        from synapse.config.config import get_config
        config = get_config()
        assert str(config.data_dir) == str(Path.home() / ".synapse" / "data")
    
    @patch('synapse.config.config.platform.system')
    @patch('synapse.config.config.os.access')
    def test_linux_data_directory_writable(self, mock_access, mock_system):
        mock_system.return_value = "Linux"
        mock_access.return_value = True
        from synapse.config.config import get_config
        config = get_config()
        assert str(config.data_dir) == "/opt/synapse/data"
```

### File: `tests/unit/test_semantic_api.py`

```python
"""Test semantic store API."""

import pytest
from unittest.mock import patch

class TestSemanticAPI:
    """Test semantic store API signatures."""
    
    def test_search_method_signature(self):
        from core.semantic_store import SemanticStore
        import inspect
        sig = inspect.signature(SemanticStore.search)
        params = list(sig.parameters.keys())
        assert 'self' in params
        assert 'query' in params
        assert 'top_k' in params
```

---

## Execution Order

1. Create `synapse/config/config.py`
2. Update `synapse/config/__init__.py`
3. Update `mcp_server/rag_server.py` (renaming + config)
4. Update `synapse/main.py`
5. Create `tests/unit/test_memory_paths.py`
6. Create `tests/unit/test_semantic_api.py`
7. Run tests and verify

---

**Plan Status**: Ready for implementation
**Created**: February 1, 2026
