"""
SYNAPSE Configuration Module

Provides centralized configuration management with:
- Auto-detection of paths and environment
- Configuration layering (defaults < config files < env vars < CLI args)
- OS-aware configuration with shortname support
- Validation and error handling
"""

from synapse.config.defaults import (
    DEFAULT_CONFIG,
    get_config as _get_config_old,
    load_config_file,
    apply_environment_variables,
    validate_config,
    print_config_summary,
    detect_data_directory,
    detect_models_directory,
    detect_environment
)

# New OS-aware configuration (Feature 012)
from synapse.config.config import (
    SynapseConfig,
    get_config,
    get_data_dir,
    get_database_path,
    get_index_dir,
    get_shortname,
    get_registry_path,
    get_episodic_db_path,
    get_logs_dir,
    get_models_dir,
    SHORTNAME,
)

__all__ = [
    # Old exports (backward compatibility)
    "DEFAULT_CONFIG",
    "load_config_file",
    "apply_environment_variables",
    "validate_config",
    "print_config_summary",
    "detect_data_directory",
    "detect_models_directory",
    "detect_environment",
    # New exports (Feature 012)
    "SynapseConfig",
    "get_config",
    "get_data_dir",
    "get_database_path",
    "get_index_dir",
    "get_shortname",
    "get_registry_path",
    "get_episodic_db_path",
    "get_logs_dir",
    "get_models_dir",
    "SHORTNAME",
]
