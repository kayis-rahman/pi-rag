"""
Pytest tests for MCP data directory detection (BUG-010 fix).

Tests that the MCP server correctly detects and uses OS-appropriate data directories.
"""

import pytest
from unittest.mock import patch, MagicMock
import os
import sys

# Add project root to path
project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, project_root)


class TestMCPDataDirectory:
    """Test MCP data directory detection for different OS and configurations."""
    
    @patch('mcp_server.synapse_server.platform.system')
    @patch('mcp_server.synapse_server.os.path.exists')
    @patch('mcp_server.synapse_server.os.access')
    def test_macos_data_directory(self, mock_access, mock_exists, mock_system):
        """Test that Mac uses ~/.synapse/data"""
        # Setup mocks
        mock_system.return_value = "Darwin"
        mock_exists.return_value = False
        mock_access.return_value = True
        
        # Import after patching
        from mcp_server.synapse_server import MemoryBackend
        backend = MemoryBackend()
        
        # Test the method
        data_dir = backend._get_data_dir()
        expected = os.path.expanduser("~/.synapse/data")
        
        assert data_dir == expected, f"Expected {expected}, got {data_dir}"
        print(f"✅ Mac test passed: {data_dir}")
    
    @patch('mcp_server.synapse_server.platform.system')
    @patch('mcp_server.synapse_server.os.path.exists')
    @patch('mcp_server.synapse_server.os.access')
    def test_linux_data_directory_writable(self, mock_access, mock_exists, mock_system):
        """Test that Linux uses /opt/synapse/data if writable"""
        # Setup mocks
        mock_system.return_value = "Linux"
        mock_exists.return_value = True  # Config file exists
        mock_access.return_value = True  # Path is writable
        
        from mcp_server.synapse_server import MemoryBackend
        backend = MemoryBackend()
        
        # Test the method
        data_dir = backend._get_data_dir()
        
        assert data_dir == "/opt/synapse/data", f"Expected /opt/synapse/data, got {data_dir}"
        print(f"✅ Linux (writable) test passed: {data_dir}")
    
    @patch('mcp_server.synapse_server.platform.system')
    @patch('mcp_server.synapse_server.os.path.exists')
    @patch('mcp_server.synapse_server.os.access')
    def test_linux_data_directory_not_writable(self, mock_access, mock_exists, mock_system):
        """Test that Linux falls back to user home if /opt not writable"""
        # Setup mocks
        mock_system.return_value = "Linux"
        mock_exists.return_value = True
        mock_access.return_value = False  # Path NOT writable
        
        from mcp_server.synapse_server import MemoryBackend
        backend = MemoryBackend()
        
        # Test the method
        data_dir = backend._get_data_dir()
        expected = os.path.expanduser("~/.synapse/data")
        
        assert data_dir == expected, f"Expected {expected}, got {data_dir}"
        print(f"✅ Linux (not writable) test passed: {data_dir}")
    
    @patch('mcp_server.synapse_server.platform.system')
    @patch('mcp_server.synapse_server.os.path.exists')
    @patch('mcp_server.synapse_server.os.access')
    def test_windows_data_directory(self, mock_access, mock_exists, mock_system):
        """Test that Windows uses user home"""
        # Setup mocks
        mock_system.return_value = "Windows"
        mock_exists.return_value = False
        mock_access.return_value = True
        
        from mcp_server.synapse_server import MemoryBackend
        backend = MemoryBackend()
        
        # Test the method
        data_dir = backend._get_data_dir()
        expected = os.path.expanduser("~/.synapse/data")
        
        assert data_dir == expected, f"Expected {expected}, got {data_dir}"
        print(f"✅ Windows test passed: {data_dir}")
    
    @patch('mcp_server.synapse_server.os.environ.get')
    def test_environment_variable_override(self, mock_env):
        """Test that SYNAPSE_DATA_DIR environment variable takes priority"""
        # Set environment variable
        mock_env.side_effect = lambda key, default: {
            "SYNAPSE_DATA_DIR": "/custom/test/path"
        }.get(key, default)
        
        from mcp_server.synapse_server import MemoryBackend
        backend = MemoryBackend()
        
        # Test the method
        data_dir = backend._get_data_dir()
        
        assert data_dir == "/custom/test/path", f"Expected /custom/test/path, got {data_dir}"
        print(f"✅ Environment variable test passed: {data_dir}")
    
    @patch('mcp_server.synapse_server.os.path.exists')
    @patch('builtins.open', new_callable=MagicMock)
    def test_config_file_data_dir(self, mock_file, mock_exists):
        """Test that config file data_dir takes priority"""
        # Mock config file with data_dir
        mock_exists.return_value = True
        mock_file.return_value.__enter__.return_value.read.return_value = '{"data_dir": "/config/path"}'
        
        from mcp_server.synapse_server import MemoryBackend
        backend = MemoryBackend()
        
        # Test the method
        data_dir = backend._get_data_dir()
        
        assert data_dir == "/config/path", f"Expected /config/path, got {data_dir}"
        print(f"✅ Config file (data_dir) test passed: {data_dir}")
    
    @patch('mcp_server.synapse_server.os.path.exists')
    @patch('builtins.open', new_callable=MagicMock)
    def test_config_file_index_path(self, mock_file, mock_exists):
        """Test that config file index_path derivation works"""
        # Mock config file with index_path
        mock_exists.return_value = True
        mock_file.return_value.__enter__.return_value.read.return_value = '{"index_path": "/some/path/index.json"}'
        
        from mcp_server.synapse_server import MemoryBackend
        backend = MemoryBackend()
        
        # Test the method
        data_dir = backend._get_data_dir()
        expected = "/some/path"
        
        assert data_dir == expected, f"Expected {expected}, got {data_dir}"
        print(f"✅ Config file (index_path) test passed: {data_dir}")


class TestProjectManagerDataDirectory:
    """Test ProjectManager data directory detection."""
    
    @patch('mcp_server.project_manager.platform.system')
    @patch('mcp_server.project_manager.os.path.exists')
    @patch('mcp_server.project_manager.os.access')
    def test_project_manager_macos(self, mock_access, mock_exists, mock_system):
        """Test that ProjectManager uses Mac data directory"""
        # Setup mocks
        mock_system.return_value = "Darwin"
        mock_exists.return_value = False
        mock_access.return_value = True
        
        from mcp_server.project_manager import ProjectManager
        
        # Create instance (should auto-detect data directory)
        manager = ProjectManager()
        
        # Test
        expected = os.path.expanduser("~/.synapse/data")
        assert manager.base_data_dir == expected, f"Expected {expected}, got {manager.base_data_dir}"
        print(f"✅ ProjectManager Mac test passed: {manager.base_data_dir}")
    
    @patch('mcp_server.project_manager.os.environ.get')
    def test_project_manager_env_override(self, mock_env):
        """Test that ProjectManager respects environment variable"""
        mock_env.side_effect = lambda key, default: {
            "SYNAPSE_DATA_DIR": "/env/override/path"
        }.get(key, default)
        
        from mcp_server.project_manager import ProjectManager
        
        # Create instance
        manager = ProjectManager()
        
        # Test
        assert manager.base_data_dir == "/env/override/path", f"Expected /env/override/path, got {manager.base_data_dir}"
        print(f"✅ ProjectManager env override test passed: {manager.base_data_dir}")


if __name__ == "__main__":
    # Run tests manually if executed directly
    print("Running MCP data directory tests...")
    
    # Create test instance
    test_instance = TestMCPDataDirectory()
    
    # Run tests
    try:
        print("\n1. Testing Mac data directory...")
        test_instance.test_macos_data_directory()
        print("   ✅ PASSED")
        
        print("\n2. Testing Linux (writable) data directory...")
        test_instance.test_linux_data_directory_writable()
        print("   ✅ PASSED")
        
        print("\n3. Testing Linux (not writable) data directory...")
        test_instance.test_linux_data_directory_not_writable()
        print("   ✅ PASSED")
        
        print("\n4. Testing Windows data directory...")
        test_instance.test_windows_data_directory()
        print("   ✅ PASSED")
        
        print("\n5. Testing environment variable override...")
        test_instance.test_environment_variable_override()
        print("   ✅ PASSED")
        
        print("\n6. Testing config file data_dir...")
        test_instance.test_config_file_data_dir()
        print("   ✅ PASSED")
        
        print("\n7. Testing config file index_path...")
        test_instance.test_config_file_index_path()
        print("   ✅ PASSED")
        
        print("\n" + "="*60)
        print("✅ ALL MCP DATA DIRECTORY TESTS PASSED!")
        print("="*60)
        
    except Exception as e:
        print(f"\n❌ TEST FAILED: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
