"""
SYNAPSE CLI: Stop Command

Stop SYNAPSE MCP server running in either Docker or native mode.
"""

import subprocess
import time
from pathlib import Path
import typer


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
    
    # Find and kill Python processes running the server
    try:
        # Use lsof to find process using port 8002, then kill it
        # This is more precise than pkill
        result = subprocess.run(
            ["lsof", "-t", "-i", ":8002"],
            capture_output=True,
            text=True,
            timeout=5
        )
        
        if result.returncode == 0 and result.stdout:
            # Parse output to get PID
            # Format: COMMAND  PID USER   FD  TYPE DEVICE SIZE/OFF NODE NAME
            lines = result.stdout.strip().split('\n')
            for line in lines[1:]:  # Skip header
                parts = line.split()
                if len(parts) >= 2:
                    pid = parts[1]
                    try:
                        subprocess.run(
                            ["kill", pid],
                            timeout=5,
                            check=True
                        )
                        print(f"✓ Killed server process (PID: {pid})")
                    except Exception:
                        pass
            
            # Wait for port to be released
            max_wait = 10
            for i in range(max_wait):
                time.sleep(1)
                # Check if port is still in use
                check_result = subprocess.run(
                    ["lsof", "-t", "-i", ":8002"],
                    capture_output=True,
                    timeout=2
                )
                if check_result.returncode != 0:
                    # Port is free
                    print(f"✓ Port 8002 released after {i+1} seconds")
                    break
            
            # Check one more time
            check_result = subprocess.run(
                ["lsof", "-t", "-i", ":8002"],
                capture_output=True,
                timeout=2
            )
            if check_result.returncode == 0:
                print("⚠️  Warning: Port may still be in use")
                return False
            
            print("✓ SYNAPSE native server stopped")
            return True
        else:
            print("✓ SYNAPSE server not running")
            return True
            
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
            print("✓ SYNAPSE native server stopped (fallback)")
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
