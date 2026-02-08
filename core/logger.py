"""
Standardized logging utility for Synapse RAG system.

Features:
- Consistent log format across all modules
- Configurable log levels (DEBUG, INFO, WARNING, ERROR)
- Thread-safe singleton logger instances
- Environment detection (dev vs prod)
- Log level priority: --debug flag > LOG_LEVEL env > config file > env detection
- File logging with rotation
"""

import logging
import os
import sys
from pathlib import Path
from typing import Optional, Dict

# Singleton logger manager instance
_logger_manager: Optional['LoggerManager'] = None


class LoggerManager:
    """Manages logging configuration and logger instances."""

    def __init__(self):
        """Initialize LoggerManager with empty logger cache."""
        self._loggers: Dict[str, logging.Logger] = {}
        self._configured = False

    def setup_logging(
        self,
        level: Optional[str] = None,
        log_file: Optional[str] = None,
        debug_flag: bool = False,
        config_file: Optional[str] = None
    ) -> None:
        """
        Configure root logging with environment detection.

        Log Level Priority:
        1. debug_flag (if True, always DEBUG)
        2. LOG_LEVEL environment variable
        3. Config file (if provided)
        4. Environment detection (dev: DEBUG, prod: INFO)
        5. Default: INFO

        Args:
            level: Optional explicit log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
            log_file: Optional path to log file
            debug_flag: If True, force DEBUG level
            config_file: Optional path to logging config JSON file
        """
        # Priority 1: Debug flag (always wins)
        if debug_flag:
            log_level = logging.DEBUG
            effective_source = "--debug flag"
        # Priority 2: Environment variable
        elif os.environ.get("LOG_LEVEL"):
            env_level = os.environ["LOG_LEVEL"].upper()
            log_level = getattr(logging, env_level, logging.INFO)
            effective_source = f"LOG_LEVEL environment variable ({env_level})"
        # Priority 3: Config file
        elif config_file:
            try:
                import json
                if os.path.exists(config_file):
                    with open(config_file, 'r') as f:
                        config = json.load(f)
                    config_level = config.get("default_level", {}).get(os.environ.get("ENV", "dev"), "INFO")
                    log_level = getattr(logging, config_level.upper(), logging.INFO)
                    effective_source = f"config file ({config_file})"
                else:
                    # Config file doesn't exist, fall through to env detection
                    log_level = None
                    effective_source = "config file (not found)"
            except Exception as e:
                # Config file error, fall through to env detection
                log_level = None
                effective_source = f"config file (error: {e})"
        # Priority 4: Environment detection
        else:
            env = os.environ.get("ENV", "dev").lower()
            if env == "production":
                log_level = logging.INFO
                effective_source = "environment detection (production)"
            else:
                log_level = logging.DEBUG
                effective_source = "environment detection (dev)"

        # Use configured or default level
        final_level = log_level or logging.INFO

        # Create log format
        formatter = logging.Formatter(
            '%(asctime)s | %(levelname)-8s | %(name)s | %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )

        # Console handler
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(final_level)
        console_handler.setFormatter(formatter)

        # File handler (if log_file specified)
        file_handler = None
        if log_file:
            try:
                from logging.handlers import RotatingFileHandler
                log_path = Path(log_file)
                log_path.parent.mkdir(parents=True, exist_ok=True)

                file_handler = RotatingFileHandler(
                    log_file,
                    maxBytes=10485760,  # 10MB
                    backupCount=5
                )
                file_handler.setLevel(final_level)
                file_handler.setFormatter(formatter)
            except Exception as e:
                # Log file creation failed, continue with console only
                print(f"Warning: Failed to create file handler: {e}", file=sys.stderr)

        # Configure root logger
        root_logger = logging.getLogger()
        root_logger.setLevel(final_level)
        root_logger.handlers.clear()
        root_logger.addHandler(console_handler)

        if file_handler:
            root_logger.addHandler(file_handler)

        self._configured = True

        # Log configuration for debugging
        if log_level == logging.DEBUG or effective_source == "--debug flag":
            print(f"Logger configured: {effective_source}, level={logging.getLevelName(final_level)}")

    def get_logger(self, name: str) -> logging.Logger:
        """
        Get or create logger instance.

        Args:
            name: Module name (typically __name__)

        Returns:
            Logger instance
        """
        if not self._configured:
            # Auto-setup if not configured yet
            self.setup_logging()

        if name not in self._loggers:
            self._loggers[name] = logging.getLogger(name)

        return self._loggers[name]


def get_logger(name: str) -> logging.Logger:
    """
    Get logger instance (singleton pattern).

    This is the main entry point for logging in Synapse modules.

    Usage:
        from core.logger import get_logger
        logger = get_logger(__name__)
        logger.info("Hello, world!")
        logger.warning("Something unusual happened")
        logger.error("An error occurred")

    Args:
        name: Module name (typically __name__)

    Returns:
        Logger instance
    """
    global _logger_manager
    if _logger_manager is None:
        _logger_manager = LoggerManager()
    return _logger_manager.get_logger(name)


def setup_logging(
    level: Optional[str] = None,
    log_file: Optional[str] = None,
    debug_flag: bool = False,
    config_file: Optional[str] = None
) -> None:
    """
    Setup logging configuration.

    This can be called explicitly to configure logging before using get_logger().

    Usage in CLI scripts:
        from core.logger import setup_logging
        import argparse

        parser = argparse.ArgumentParser()
        parser.add_argument('--debug', '-d', action='store_true')
        args = parser.parse_args()

        if args.debug:
            os.environ["LOG_LEVEL"] = "DEBUG"

        setup_logging(log_file="/opt/synapse/logs/synapse.log")

    Args:
        level: Optional explicit log level
        log_file: Optional path to log file
        debug_flag: If True, force DEBUG level
        config_file: Optional path to logging config JSON file
    """
    global _logger_manager
    if _logger_manager is None:
        _logger_manager = LoggerManager()
    _logger_manager.setup_logging(level, log_file, debug_flag, config_file)
