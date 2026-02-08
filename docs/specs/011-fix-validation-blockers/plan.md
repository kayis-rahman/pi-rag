# Fix Validation Blockers - Technical Plan

**Feature ID**: 011-fix-validation-blockers  
**Status**: [In Progress]  
**Created**: January 31, 2026  
**Last Updated**: January 31, 2026

---

## Implementation Strategy

This plan details the technical implementation for fixing 4 critical bugs blocking full validation completion. The approach uses OS-aware data directory detection and improved server management logic.

**Key Approach:**
1. OS-aware data directory detection (priority: env > config > OS-specific)
2. Proper process detection for server management
3. Comprehensive pytest coverage with mocked dependencies
4. OpenCode manual verification

---

## Fix 1: MCP Data Directory (BUG-010)

### File: `mcp_server/rag_server.py`

**Current Code (fails on Mac):**
```python
def _get_data_dir(self) -> str:
    """Get data directory from config file."""
    try:
        config_path = os.environ.get("SYNAPSE_CONFIG_PATH", "./configs/rag_config.json")
        if os.path.exists(config_path):
            with open(config_path, 'r') as f:
                config = json.load(f)
                if "index_path" in config:
                    index_path = config["index_path"]
                    return os.path.dirname(index_path)
    except Exception as e:
        logger.warning(f"Failed to read data dir from config: {e}")
    
    # HARDCODED - fails on Mac!
    return os.environ.get("SYNAPSE_DATA_DIR", "/opt/synapse/data")
```

**Proposed Implementation:**
```python
def _get_data_dir(self) -> str:
    """
    Get data directory with OS-aware detection.
    
    Priority:
    1. Environment variable (SYNAPSE_DATA_DIR)
    2. Config file (data_dir or index_path)
    3. OS-specific defaults:
       - macOS: ~/.synapse/data
       - Linux: /opt/synapse/data (if writable), else ~/.synapse/data
       - Windows: ~/.synapse/data
    """
    
    # Priority 1: Environment variable
    if "SYNAPSE_DATA_DIR" in os.environ:
        data_dir = os.environ["SYNAPSE_DATA_DIR"]
        logger.info(f"Using data directory from environment: {data_dir}")
        return data_dir
    
    # Priority 2: Config file
    try:
        config_path = os.environ.get("SYNAPSE_CONFIG_PATH", "./configs/rag_config.json")
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
    import platform
    system = platform.system()
    
    if system == "Darwin":  # macOS
        data_dir = os.path.expanduser("~/.synapse/data")
        logger.info(f"Using macOS default data directory: {data_dir}")
        return data_dir
    
    elif system == "Linux":
        # Try system path first (for backward compatibility)
        system_path = "/opt/synapse/data"
        if os.access(system_path, os.W_OK):
            logger.info(f"Using Linux system data directory: {system_path}")
            return system_path
        # Fall back to user home
        data_dir = os.path.expanduser("~/.synapse/data")
        logger.info(f"Linux system path not writable, using: {data_dir}")
        return data_dir
    
    else:  # Windows and others
        data_dir = os.path.expanduser("~/.synapse/data")
        logger.info(f"Using default data directory: {data_dir}")
        return data_dir
```

### Changes in Other Files

**File: `mcp_server/project_manager.py`**
- Update `_init_registry()` to use `self._get_data_dir()` instead of hardcoded path
- Registry database location: `{data_dir}/registry.db`

**File: `scripts/bulk_ingest.py`**
- Update data directory detection to use same logic
- Can reuse logic from rag_server.py or import it

---

## Fix 2: Server Management (BUG-001, 002, 003)

### File: `synapse/cli/commands/start.py`

**Current Issues:**
- May not detect already-running server
- Permission errors not handled gracefully

**Proposed Improvements:**
```python
def start(port: int = 8002, docker: bool = False, debug: bool = False):
    """Start SYNAPSE server."""
    
    # Check if server already running
    try:
        response = requests.get(f"http://localhost:{port}/health", timeout=2)
        if response.status_code == 200:
            console.print(f"[yellow]⚠ Server already running on port {port}[/yellow]")
            console.print(f"[cyan]Health check: {response.json()}[/cyan]")
            return
    except requests.exceptions.RequestException:
        pass  # Server not running, proceed with start
    
    # Check if process already running (defensive)
    for proc in psutil.process_iter(['pid', 'cmdline']):
        try:
            cmdline = proc.info.get('cmdline', [])
            if cmdline and 'mcp_server.http_wrapper' in ' '.join(cmdline):
                console.print(f"[yellow]⚠ Server process already running (PID: {proc.info['pid']})[/yellow]")
                return
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass
    
    # Proceed with start
    console.print(f"[cyan]🚀 Starting SYNAPSE server...[/cyan]")
    console.print(f"  Port: {port}")
    console.print(f"  Environment: {'docker' if docker else 'native'}")
    
    # Start server logic...
```

### File: `synapse/cli/commands/stop.py`

**Current Issues:**
- May not find correct process
- May not send proper signals
- May not verify stop succeeded

**Proposed Improvements:**
```python
def stop(port: int = 8002, docker: bool = False):
    """Stop SYNAPSE server."""
    
    # Find server process
    server_process = None
    for proc in psutil.process_iter(['pid', 'cmdline', 'status']):
        try:
            cmdline = proc.info.get('cmdline', [])
            if cmdline and 'mcp_server.http_wrapper' in ' '.join(cmdline):
                server_process = proc
                break
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    
    if not server_process:
        console.print("[yellow]⚠ Server not running[/yellow]")
        return
    
    # Try graceful shutdown first (SIGTERM)
    console.print(f"[cyan]🛑 Stopping SYNAPSE server (PID: {server_process.pid})...[/cyan]")
    
    try:
        server_process.terminate()
        
        # Wait for graceful shutdown
        gone, alive = psutil.wait_procs([server_process], timeout=3)
        
        if alive:
            # Force kill if still alive
            console.print("[yellow]⚠ Force killing process...[/yellow]")
            for proc in alive:
                proc.kill()
                gone, alive = psutil.wait_procs([proc], timeout=2)
        
        # Verify server stopped
        try:
            response = requests.get(f"http://localhost:{port}/health", timeout=1)
            console.print("[red]❌ Server still running![/red]")
        except requests.exceptions.RequestException:
            console.print("[green]✅ Server stopped successfully[/green]")
    
    except psutil.NoSuchProcess:
        console.print("[green]✅ Server stopped successfully[/green]")
    except Exception as e:
        console.print(f"[red]❌ Error stopping server: {e}[/red]")
```

### File: `synapse/cli/commands/status.py`

**Current Issues:**
- May show incorrect state

**Proposed Improvements:**
```python
def status(port: int = 8002, verbose: bool = False):
    """Check SYNAPSE system status."""
    
    # Primary check: Health endpoint
    server_running = False
    try:
        response = requests.get(f"http://localhost:{port}/health", timeout=2)
        if response.status_code == 200:
            server_running = True
            health_data = response.json()
    except requests.exceptions.RequestException:
        health_data = None
    
    # Secondary check: Process list
    process_found = False
    for proc in psutil.process_iter(['pid', 'cmdline', 'status']):
        try:
            cmdline = proc.info.get('cmdline', [])
            if cmdline and 'mcp_server.http_wrapper' in ' '.join(cmdline):
                process_found = True
                break
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    
    # Display status
    if server_running:
        console.print(f"[green]✅ Server: Running on port {port}[/green]")
        if verbose:
            console.print(f"[cyan]  Health: {health_data}[/cyan]")
    elif process_found:
        console.print(f"[yellow]⚠ Server: Process found but not responding[/yellow]")
    else:
        console.print(f"[red]❌ Server: Stopped[/red]")
```

### Dependencies Required

Add to imports:
```python
import psutil
import requests
```

---

## Test 1: MCP Data Directory

**File: `tests/unit/test_mcp_data_directory.py`**

```python
import pytest
from unittest.mock import patch, MagicMock
import os

class TestMCPDataDirectory:
    """Test MCP data directory detection for different OS."""
    
    @patch('mcp_server.rag_server.platform.system')
    @patch('mcp_server.rag_server.os.path.exists')
    @patch('mcp_server.rag_server.os.access')
    def test_macos_data_directory(self, mock_access, mock_exists, mock_system):
        """Test that Mac uses ~/.synapse/data"""
        mock_system.return_value = "Darwin"
        mock_exists.return_value = False
        mock_access.return_value = True
        
        # Import after patching
        from mcp_server.rag_server import MemoryBackend
        backend = MemoryBackend()
        
        data_dir = backend._get_data_dir()
        expected = os.path.expanduser("~/.synapse/data")
        assert data_dir == expected, f"Expected {expected}, got {data_dir}"
    
    @patch('mcp_server.rag_server.platform.system')
    @patch('mcp_server.rag_server.os.path.exists')
    @patch('mcp_server.rag_server.os.access')
    def test_linux_data_directory_writable(self, mock_access, mock_exists, mock_system):
        """Test that Linux uses /opt/synapse/data if writable"""
        mock_system.return_value = "Linux"
        mock_exists.return_value = True  # Config file exists
        mock_access.return_value = True  # Path is writable
        
        from mcp_server.rag_server import MemoryBackend
        backend = MemoryBackend()
        
        data_dir = backend._get_data_dir()
        assert data_dir == "/opt/synapse/data"
    
    @patch('mcp_server.rag_server.platform.system')
    @patch('mcp_server.rag_server.os.path.exists')
    @patch('mcp_server.rag_server.os.access')
    def test_linux_data_directory_not_writable(self, mock_access, mock_exists, mock_system):
        """Test that Linux falls back to user home if /opt not writable"""
        mock_system.return_value = "Linux"
        mock_exists.return_value = True
        mock_access.return_value = False  # Path NOT writable
        
        from mcp_server.rag_server import MemoryBackend
        backend = MemoryBackend()
        
        data_dir = backend._get_data_dir()
        expected = os.path.expanduser("~/.synapse/data")
        assert data_dir == expected, f"Expected {expected}, got {data_dir}"
    
    @patch('mcp_server.rag_server.os.environ.get')
    def test_environment_variable_override(self, mock_env):
        """Test that SYNAPSE_DATA_DIR environment variable takes priority"""
        # Set environment variable
        mock_env.side_effect = lambda key, default: {
            "SYNAPSE_DATA_DIR": "/custom/test/path"
        }.get(key, default)
        
        from mcp_server.rag_server import MemoryBackend
        backend = MemoryBackend()
        
        data_dir = backend._get_data_dir()
        assert data_dir == "/custom/test/path"
    
    @patch('mcp_server.rag_server.os.path.exists')
    @patch('builtins.open', new_callable=mock_open, read_data='{"data_dir": "/config/path"}')
    def test_config_file_override(self, mock_file, mock_exists):
        """Test that config file takes priority over OS defaults"""
        mock_exists.return_value = True
        
        from mcp_server.rag_server import MemoryBackend
        backend = MemoryBackend()
        
        data_dir = backend._get_data_dir()
        assert data_dir == "/config/path"
```

---

## Test 2: Server Management

**File: `tests/unit/test_server_management.py`**

```python
import pytest
from unittest.mock import patch, MagicMock
import requests

class TestServerManagement:
    """Test server start/stop/status commands."""
    
    @patch('synapse.cli.commands.start.requests.get')
    def test_start_already_running(self, mock_get):
        """Test start command when server already running"""
        # Mock health check response
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"status": "ok"}
        mock_get.return_value = mock_response
        
        from synapse.cli.commands.start import start
        from synapse.cli import console
        
        # Should detect already running server
        # and show warning instead of starting new one
    
    @patch('psutil.process_iter')
    def test_stop_finds_process(self, mock_process_iter):
        """Test stop command finds correct process"""
        mock_proc = MagicMock()
        mock_proc.pid = 12345
        mock_proc.info = {'cmdline': ['python', '-m', 'mcp_server.http_wrapper']}
        mock_process_iter.return_value = [mock_proc]
        
        from synapse.cli.commands.stop import stop
        # Should find and terminate the process
    
    @patch('psutil.process_iter')
    @patch('psutil.wait_procs')
    def test_stop_sends_sigterm_then_sigkill(self, mock_wait_procs, mock_process_iter):
        """Test stop sends SIGTERM first, then SIGKILL if needed"""
        mock_proc = MagicMock()
        mock_proc.pid = 12345
        mock_proc.info = {'cmdline': ['python', '-m', 'mcp_server.http_wrapper']}
        mock_process_iter.return_value = [mock_proc]
        
        # Mock graceful termination
        mock_wait_procs.return_value = ([], [])  # All terminated gracefully
        
        from synapse.cli.commands.stop import stop
        # Should send SIGTERM and succeed without SIGKILL
    
    @patch('synapse.cli.commands.status.requests.get')
    @patch('psutil.process_iter')
    def test_status_running(self, mock_process_iter, mock_get):
        """Test status shows running when health endpoint responds"""
        # Mock health check
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"status": "ok"}
        mock_get.return_value = mock_response
        
        # Mock process found
        mock_proc = MagicMock()
        mock_proc.info = {'cmdline': ['python', '-m', 'mcp_server.http_wrapper']}
        mock_process_iter.return_value = [mock_proc]
        
        from synapse.cli.commands.status import status
        # Should show "running" state
    
    @patch('synapse.cli.commands.status.requests.get')
    @patch('psutil.process_iter')
    def test_status_stopped(self, mock_process_iter, mock_get):
        """Test status shows stopped when health endpoint fails"""
        # Mock health check failure
        mock_get.side_effect = requests.exceptions.ConnectionError()
        
        # No process found
        mock_process_iter.return_value = []
        
        from synapse.cli.commands.status import status
        # Should show "stopped" state
```

---

## OpenCode Testing Commands

After implementing fixes, test with OpenCode:

```bash
# Test 1: List projects (verifies MCP permission fix)
# In OpenCode:
/rag list_projects

# Test 2: Search knowledge (verifies MCP search works)
/rag search project_id="synapse" query="What is Synapse?" memory_type="all" top_k=5

# Test 3: Add fact (verifies symbolic memory works)
/rag add_fact project_id="synapse" fact_key="opencode_test" fact_value="Testing from OpenCode after fix" category="validation"

# Test 4: Add episode (verifies episodic memory works)
/rag add_episode project_id="synapse" title="OpenCode Fix Verification" content="Verified MCP tools work after implementing OS-aware data directory" lesson_type="success"

# Test 5: Analyze conversation (verifies learning extraction works)
/rag analyze_conversation project_id="synapse" user_message="Is the server working?" agent_response="Yes, all 8 MCP tools are functional on Mac now" auto_store=true

# Test 6: Verify data persistence
/rag list_sources project_id="synapse"
```

**Expected Results:**
- All 6 commands succeed
- No permission denied errors
- Data persists in `~/.synapse/data/`

---

## Risk Mitigation

### Risk 1: OS Detection Fails
**Mitigation:** Add comprehensive fallback logic and test on all platforms

### Risk 2: Process Detection Fails
**Mitigation:** Use multiple methods (health endpoint + process list)

### Risk 3: Breaking Linux Users
**Mitigation:** Only change Mac behavior, keep Linux default as `/opt/synapse/data`

### Risk 4: Test Dependencies
**Mitigation:** Use mocks for external dependencies (psutil, requests)

---

## Success Metrics

### Code Quality
- [ ] All modified files pass linting
- [ ] 90%+ pytest coverage for modified code
- [ ] Type hints added where appropriate

### Functionality
- [ ] All 4 bugs fixed (010, 003, 001, 002)
- [ ] OpenCode tests 1-6 pass
- [ ] Pytest tests pass
- [ ] No Linux regression

### Performance
- [ ] Data directory detection: < 10ms
- [ ] Server start: < 5 seconds
- [ ] Server stop: < 3 seconds
- [ ] Status check: < 1 second

---

## Implementation Order

1. **Fix MCP Data Directory** (highest priority, unblocks everything)
   - Modify `mcp_server/rag_server.py`
   - Test with OpenCode (verify `core.list_projects` works)
   - Run pytest for data directory

2. **Fix Server Management**
   - Modify `start.py`, `stop.py`, `status.py`
   - Test with OpenCode (start/stop/status workflow)
   - Run pytest for server management

3. **Final Validation**
   - Re-run full validation (Phases 6-7-8 from 010)
   - Complete documentation
   - Update central index

---

**Plan Status**: Ready for implementation  
**Created**: January 31, 2026  
**Last Updated**: January 31, 2026
