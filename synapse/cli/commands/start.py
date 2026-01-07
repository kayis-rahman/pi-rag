"""
SYNAPSE CLI: Start Command

Start SYNAPSE server in either Docker or native mode.
"""

import os
import subprocess
import time
from pathlib import Path
from typing import Optional


def check_docker_running(container_name: str = "synapse-mcp") -> bool:
    """Check if Docker container is running."""
    try:
        result = subprocess.run(
            ["docker", "ps", "--filter", f"name={container_name}", "--format", "{{.Status}}"],
            capture_output=True,
            text=True,
            timeout=5
        )
        return result.stdout.strip() == "running"
    except Exception:
        return False


def check_docker_available() -> bool:
    """Check if Docker and docker-compose are available."""
    try:
        subprocess.run(["docker", "--version"], capture_output=True, timeout=5)
        return True
    except Exception:
        return False


def check_docker_compose_file() -> Optional[Path]:
    """Find Docker Compose file if default doesn't exist."""
    compose_file = Path("docker-compose.mcp.yml")
    if compose_file.exists():
        return compose_file

    # Try common locations
    possible_locations = [
        Path("docker-compose.synapse.yml"),
        Path("docker-compose.yml")
    ]

    for loc in possible_locations:
        if loc.exists():
            return loc

    return None


def start_docker(docker_compose_file: str = "docker-compose.mcp.yml", port: int = 8002) -> bool:
    """Start SYNAPSE server in Docker mode."""
    print(f"🐳 Starting SYNAPSE server in Docker mode on port {port}...")
    
    # Check if already running
    if check_docker_running("synapse-mcp"):
        print("✓ SYNAPSE container is already running")
        print("  Use 'synapse status' to check health")
        return True
    
    # Check for compose file
    compose_file = check_docker_compose_file()
    if compose_file is None:
        print(f"❌ Error: Docker compose file not found")
        print(f"   Searched for: {docker_compose_file}")
        print(f"   Please ensure you're in the synapse directory")
        return False
    
    # Start container
    try:
        subprocess.run(
            ["docker", "compose", "-f", str(compose_file), "up", "-d"],
            check=True,
            timeout=60
        )
        print(f"✓ SYNAPSE server started successfully")
        print(f"  Docker container: synapse-mcp")
        print(f"  Port: {port}")
        print(f"  Health check: http://localhost:{port}/health")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to start Docker container: {e}")
        return False
    except subprocess.TimeoutExpired:
        print("❌ Docker start timed out")
        return False
    except FileNotFoundError:
        print("❌ Error: Docker not found in PATH")
        print("   Please install Docker: https://docs.docker.com/get-docker/")
        return False


def start_native(port: int = 8002) -> bool:
    """Start SYNAPSE server in native (Python) mode."""
    print(f"🚀 Starting SYNAPSE server in native mode on port {port}...")

    # Set environment for native mode
    env = os.environ.copy()
    env["RAG_ENV"] = "native"
    env["RAG_CONFIG_PATH"] = str(Path.cwd() / "configs" / "rag_config.json")
    # Pass port to HTTP server via environment variable
    env["MCP_PORT"] = str(port)

    # Start HTTP server
    try:
        # Use Popen to run server in background
        process = subprocess.Popen(
            ["python3", "-m", "mcp_server.http_wrapper"],
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            start_new_session=True  # Detach from parent process
        )

        # Check if process started successfully
        time.sleep(2)  # Wait a moment for process to initialize

        if process.poll() is None:
            # Process is still running (started successfully)
            print(f"✓ SYNAPSE server started successfully")
            print(f"  Port: {port}")
            print(f"  Health check: http://localhost:{port}/health")
            print(f"  PID: {process.pid}")
            return True
        else:
            # Process exited immediately
            proc_exit_code = process.returncode
            if proc_exit_code != 0:
                raise subprocess.CalledProcessError(
                    f"Server exited with code {proc_exit_code}",
                    returncode=proc_exit_code
                )
            print(f"❌ Server process exited immediately")
            return False
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to start native server: {e}")
        return False
    except subprocess.TimeoutExpired:
        print("❌ Server start timed out")
        return False
    except FileNotFoundError:
        print("❌ Error: Python3 not found in PATH")
        return False