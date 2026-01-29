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

    # Find the config file - search in multiple locations
    config_path = None
    possible_paths = [
        Path(__file__).parent.parent.parent / "configs" / "rag_config.json",  # From synapse/cli/commands/ -> synapse/configs
        Path.cwd() / "configs" / "rag_config.json",  # Current working directory
        Path("/opt/synapse/configs/rag_config.json"),  # Installation path
    ]

    for path in possible_paths:
        if path.exists():
            config_path = str(path)
            break

    if config_path is None:
        print(f"❌ Error: Cannot find rag_config.json")
        print(f"   Searched in:")
        for p in possible_paths:
            print(f"   - {p}")
        return False

    env["RAG_CONFIG_PATH"] = config_path

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
                # Get stderr for more details
                stderr_output = process.stderr.read().decode('utf-8') if process.stderr else ""
                stdout_output = process.stdout.read().decode('utf-8') if process.stdout else ""
                raise subprocess.CalledProcessError(
                    returncode=proc_exit_code,
                    cmd="python3 -m mcp_server.http_wrapper",
                    stderr=stderr_output,
                    output=stdout_output
                )
            print(f"❌ Server process exited immediately")
            return False
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to start native server: {e}")
        # Print stderr if available for debugging
        if hasattr(e, 'stderr') and e.stderr:
            print(f"   stderr: {e.stderr}")
        if hasattr(e, 'output') and e.output:
            print(f"   stdout: {e.output}")
        return False
    except subprocess.TimeoutExpired:
        print("❌ Server start timed out")
        return False
    except FileNotFoundError:
        print("❌ Error: Python3 not found in PATH")
        return False