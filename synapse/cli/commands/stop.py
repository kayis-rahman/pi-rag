"""
SYNAPSE CLI: Stop Command

Stop SYNAPSE MCP server running in either Docker or native mode.
"""

import os
import signal
import subprocess
import time
from pathlib import Path
import requests
import typer


def check_server_healthy(port: int = 8002) -> bool:
    """Check if server is healthy via health endpoint."""
    try:
        response = requests.get(f"http://localhost:{port}/health", timeout=2)
        return response.status_code == 200
    except requests.exceptions.RequestException:
        return False


def stop_docker(container_name: str = "synapse-mcp") -> bool:
    """Stop SYNAPSE Docker container."""
    print(f"🐳 Stopping SYNAPSE Docker container...")
    
    try:
        # Check if running
        result = subprocess.run(
            ["docker", "ps", "--filter", f"name={container_name}", "--format", "{{.Status}}"],
            capture_output=True,
            text=True,
            timeout=5
        )
        
        if result.stdout.strip() != "running":
            print("✓ SYNAPSE container is not running")
            return True
        
        # Stop container
        subprocess.run(
            ["docker", "compose", "-f", "docker-compose.mcp.yml", "stop"],
            check=True,
            timeout=30
        )
        print("✓ SYNAPSE container stopped successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to stop container: {e}")
        return False
    except subprocess.TimeoutExpired:
        print("❌ Stop operation timed out")
        return False
    except FileNotFoundError:
        print("❌ Error: Docker not found in PATH")
        return False


def stop_native() -> bool:
    """Stop SYNAPSE native server."""
    print("🚀 Stopping SYNAPSE native server...")
    
    # First check if server is even running
    if not check_server_healthy():
        print("✓ SYNAPSE server is not running")
        return True
    
    # Find and kill Python processes running the server
    try:
        # Method 1: Use lsof to find process using port 8002
        result = subprocess.run(
            ["lsof", "-t", "-i", ":8002"],
            capture_output=True,
            text=True,
            timeout=5
        )
        
        pids = []
        if result.returncode == 0 and result.stdout:
            # lsof -t -i :8002 returns just PIDs, one per line
            lines = result.stdout.strip().split('\n')
            for line in lines:
                line = line.strip()
                if line:
                    try:
                        pid = int(line)
                        pids.append(pid)
                    except ValueError:
                        # Try parsing as regular lsof output with columns
                        parts = line.split()
                        if len(parts) >= 2:
                            try:
                                pid = int(parts[1])
                                if pid not in pids:
                                    pids.append(pid)
                            except ValueError:
                                pass
        
        # Method 2: If lsof didn't find it, search by cmdline
        if not pids:
            try:
                result = subprocess.run(
                    ["ps", "aux"],
                    capture_output=True,
                    text=True,
                    timeout=5
                )
                for line in result.stdout.split('\n'):
                    if 'mcp_server.http_wrapper' in line and 'python' in line:
                        parts = line.split()
                        if len(parts) >= 2:
                            try:
                                pid = int(parts[1])
                                if pid not in pids:
                                    pids.append(pid)
                            except ValueError:
                                pass
            except Exception:
                pass
        
        # Kill processes with proper signal handling
        for pid in pids:
            try:
                # First try SIGTERM for graceful shutdown
                subprocess.run(
                    ["kill", "-TERM", str(pid)],
                    timeout=5,
                    check=False
                )
                print(f"  Sent SIGTERM to PID {pid}")
            except Exception:
                pass
        
        # Wait for graceful shutdown
        time.sleep(3)
        
        # Check if still running, send SIGKILL if needed
        for pid in pids:
            try:
                # Check if process still exists
                result = subprocess.run(
                    ["ps", "-p", str(pid)],
                    capture_output=True,
                    text=True,
                    timeout=2
                )
                if result.returncode == 0:  # Process still exists
                    subprocess.run(
                        ["kill", "-KILL", str(pid)],
                        timeout=5,
                        check=False
                    )
                    print(f"  Sent SIGKILL to PID {pid}")
            except Exception:
                pass
        
        # Wait for port to be released
        max_wait = 10
        for i in range(max_wait):
            time.sleep(1)
            if not check_server_healthy():
                print(f"✓ Server stopped after {i+1} seconds")
                break
        else:
            print("⚠️  Warning: Server may still be running")
        
        # Final verification
        if not check_server_healthy():
            print("✓ SYNAPSE native server stopped")
            return True
        else:
            print("❌ Failed to stop server - still responding to health check")
            return False
            
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to stop native server: {e}")
        return False
    except subprocess.TimeoutExpired:
        print("❌ Stop operation timed out")
        return False
    except FileNotFoundError:
        print("ℹ️  Note: lsof not available")
        # Fall back to pkill
        try:
            subprocess.run(
                ["pkill", "-f", "mcp_server.http_wrapper"],
                check=False,
                timeout=10
            )
            time.sleep(3)  # Wait for graceful shutdown
            if not check_server_healthy():
                print("✓ SYNAPSE native server stopped (fallback)")
                return True
            else:
                # Try harder
                subprocess.run(
                    ["pkill", "-9", "-f", "mcp_server.http_wrapper"],
                    check=False,
                    timeout=10
                )
                time.sleep(2)
                print("✓ SYNAPSE native server stopped (forced)")
                return True
        except Exception as e:
            print(f"❌ Failed to stop native server: {e}")
            return False


def stop_server() -> bool:
    """
    Stop SYNAPSE server.

    Auto-detects mode (Docker vs native) and stops appropriately.
    """
    # Try Docker first
    try:
        result = subprocess.run(
            ["docker", "ps", "--filter", "name=synapse-mcp", "--format", "{{.Status}}"],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.stdout.strip() == "running":
            success = stop_docker()
            if success:
                # Wait for Docker container to fully stop
                time.sleep(2)
            return success
    except Exception:
        pass
    
    # Fall back to native
    success = stop_native()
    if success:
        # Wait a bit for native process cleanup
        time.sleep(1)
    return success
