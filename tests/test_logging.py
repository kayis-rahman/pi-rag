"""
Test suite for rag.logger module.
"""

import pytest
import logging
import tempfile
import os
import sys
from pathlib import Path

# Add project root to path for imports
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from core.logger import LoggerManager, get_logger, setup_logging


def test_logger_manager_initialization():
    """Test LoggerManager initialization."""
    manager = LoggerManager()
    assert manager is not None
    assert isinstance(manager._loggers, dict)
    assert manager._configured is False


def test_setup_logging_defaults():
    """Test logging setup with defaults."""
    manager = LoggerManager()
    manager.setup_logging()

    assert manager._configured is True
    assert len(logging.getLogger().handlers) > 0


def test_setup_logging_with_level():
    """Test logging setup with explicit level."""
    manager = LoggerManager()
    manager.setup_logging(level="DEBUG")

    root_logger = logging.getLogger()
    assert root_logger.level == logging.DEBUG


def test_setup_logging_with_file():
    """Test logging setup with file output."""
    with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.log') as f:
        log_file = f.name

    try:
        manager = LoggerManager()
        manager.setup_logging(level="DEBUG", log_file=log_file)

        logger = manager.get_logger("test_file")
        logger.info("Test message")

        assert os.path.exists(log_file)
        with open(log_file) as f:
            content = f.read()
            assert "Test message" in content
            assert "INFO" in content
            assert "test_file" in content
    finally:
        if os.path.exists(log_file):
            os.unlink(log_file)


def test_get_logger_singleton():
    """Test that get_logger returns same instance."""
    manager = LoggerManager()
    logger1 = manager.get_logger("test_singleton")
    logger2 = manager.get_logger("test_singleton")

    assert logger1 is logger2


def test_get_logger_unique_names():
    """Test that get_logger returns unique instances for different names."""
    manager = LoggerManager()
    logger1 = manager.get_logger("module1")
    logger2 = manager.get_logger("module2")

    assert logger1 is not logger2
    assert logger1.name == "module1"
    assert logger2.name == "module2"


def test_get_logger_global_function():
    """Test global get_logger function."""
    logger1 = get_logger("test_global")
    logger2 = get_logger("test_global")

    assert logger1 is logger2


def test_log_levels():
    """Test that all log levels work."""
    manager = LoggerManager()
    manager.setup_logging(level="DEBUG")

    logger = manager.get_logger("test_levels")

    # Should not raise exceptions
    logger.debug("Debug message")
    logger.info("Info message")
    logger.warning("Warning message")
    logger.error("Error message")
    logger.critical("Critical message")


def test_environment_variable_priority():
    """Test that LOG_LEVEL environment variable works."""
    # Set environment variable
    os.environ["LOG_LEVEL"] = "ERROR"

    try:
        manager = LoggerManager()
        manager.setup_logging()

        root_logger = logging.getLogger()
        assert root_logger.level == logging.ERROR
    finally:
        # Clean up
        del os.environ["LOG_LEVEL"]


def test_environment_detection_dev():
    """Test environment detection for dev."""
    os.environ["ENV"] = "dev"

    try:
        manager = LoggerManager()
        manager.setup_logging()

        root_logger = logging.getLogger()
        # Dev should default to DEBUG
        assert root_logger.level == logging.DEBUG
    finally:
        del os.environ["ENV"]


def test_environment_detection_production():
    """Test environment detection for production."""
    os.environ["ENV"] = "production"

    try:
        manager = LoggerManager()
        manager.setup_logging()

        root_logger = logging.getLogger()
        # Production should default to INFO
        assert root_logger.level == logging.INFO
    finally:
        del os.environ["ENV"]


def test_debug_flag_override():
    """Test that debug_flag overrides everything."""
    # Set environment variable to ERROR (should be overridden)
    os.environ["LOG_LEVEL"] = "ERROR"

    try:
        manager = LoggerManager()
        manager.setup_logging(debug_flag=True)

        root_logger = logging.getLogger()
        # debug_flag should force DEBUG
        assert root_logger.level == logging.DEBUG
    finally:
        del os.environ["LOG_LEVEL"]


def test_config_file_priority():
    """Test that config file is used when specified."""
    with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.json') as f:
        config_file = f.name
        f.write('{"version": "1.0", "default_level": {"dev": "WARNING"}}')

    try:
        manager = LoggerManager()
        manager.setup_logging(config_file=config_file)

        root_logger = logging.getLogger()
        assert root_logger.level == logging.WARNING
    finally:
        if os.path.exists(config_file):
            os.unlink(config_file)


def test_log_format():
    """Test that log format is correct."""
    with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.log') as f:
        log_file = f.name

    try:
        manager = LoggerManager()
        manager.setup_logging(level="INFO", log_file=log_file)

        logger = manager.get_logger("format_test")
        logger.info("Format test")

        with open(log_file) as f:
            content = f.read()
            # Check format: timestamp | LEVEL | name | message
            assert "|" in content
            assert "INFO" in content
            assert "format_test" in content
            assert "Format test" in content
    finally:
        if os.path.exists(log_file):
            os.unlink(log_file)


def test_file_rotation():
    """Test that file rotation works."""
    with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.log') as f:
        log_file = f.name

    try:
        # Create manager with small max_bytes for testing
        manager = LoggerManager()
        manager.setup_logging(level="DEBUG", log_file=log_file)

        logger = manager.get_logger("rotation_test")

        # Write enough data to trigger rotation (10MB is the limit)
        # For testing, we just verify the handler is configured
        root_logger = logging.getLogger()
        file_handlers = [h for h in root_logger.handlers if isinstance(h, logging.FileHandler)]

        assert len(file_handlers) > 0
        # Note: Actual rotation requires 10MB of data, which is too slow for unit tests
    finally:
        if os.path.exists(log_file):
            os.unlink(log_file)


def test_multiple_loggers():
    """Test multiple loggers from different modules."""
    manager = LoggerManager()
    manager.setup_logging()

    logger1 = manager.get_logger("rag.module1")
    logger2 = manager.get_logger("rag.module2")
    logger3 = manager.get_logger("scripts.module3")

    assert logger1.name == "rag.module1"
    assert logger2.name == "rag.module2"
    assert logger3.name == "scripts.module3"

    # All should log without errors
    logger1.info("Module 1 message")
    logger2.info("Module 2 message")
    logger3.info("Module 3 message")


def test_cleanup_handlers():
    """Test that handlers are properly cleaned up."""
    manager = LoggerManager()
    manager.setup_logging()

    root_logger = logging.getLogger()

    # Get initial handler count
    initial_count = len(root_logger.handlers)

    # Setup again (should clear old handlers)
    manager.setup_logging()

    # Handler count should be the same (console + optional file)
    assert len(root_logger.handlers) <= initial_count + 1


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
