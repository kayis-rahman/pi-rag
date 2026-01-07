#!/usr/bin/env python3
"""
Phase 2 Test: P1-4 Docker Integration

Tests Docker Compose operations for SYNAPSE server management.
"""

import subprocess
import sys
import time
from pathlib import Path
from typing import Dict, Tuple, List, Optional

# Import shared utilities
sys.path.insert(0, str(Path(__file__).parent))
from conftest import (
    TIMEOUTS,
    check_docker_container,
    record_test_result,
    print_test_summary,
    print_success_rate
)


def run_command(
    command: List[str],
    timeout: int,
    check_exit_code: bool = True
) -> Tuple[int, str, str, float]:
    """
    Run command and return (exit_code, stdout, stderr, duration).
    """
    start_time = time.time()
    try:
        result = subprocess.run(
            command,
            timeout=timeout,
            capture_output=True,
            text=True,
            check=not check_exit_code
        )
        duration = time.time() - start_time
        return (result.returncode, result.stdout, result.stderr, duration)
    except subprocess.TimeoutExpired:
        duration = time.time() - start_time
        return (-1, "", f"Command timed out after {timeout}s", duration)
    except Exception as e:
        duration = time.time() - start_time
        return (-1, "", str(e), duration)


def assert_success(
    test_name: str,
    exit_code: int,
    stdout: str,
    stderr: str,
    duration: float,
    timeout: int
) -> None:
    """Assert command succeeded."""
    if exit_code != 0:
        raise AssertionError(
            f"{test_name}: FAILED - Exit code {exit_code}\n"
            f"STDOUT:\n{stdout}\n\n"
            f"STDERR:\n{stderr}"
        )
    if duration > timeout:
        raise AssertionError(
            f"{test_name}: FAILED - Performance degradation\n"
            f"Duration: {duration:.2f}s (timeout: {timeout}s)"
        )
    print(f"✅ {test_name}: PASSED (duration: {duration:.2f}s)")


def main():
    """Main test execution."""
    print(f"\n{'='*60}")
    print(f"Phase 2 Test: P1-4 Docker Integration")
    print(f"{'='*60}\n")

    tests = [
        ("Docker-1: Docker Compose Up", None),  # We'll implement inline
        ("Docker-2: Docker Compose Stop", None),
        ("Docker-3: Docker Compose Ps", None),
        ("Docker-4: Docker Compose Logs", None),
    ]

    # Test Docker-1: Docker Compose Up
    test_name_1 = "Docker-1: Docker Compose Up"
    print(f"\n{'='*60}")
    print(f"Testing: {test_name_1}")
    print(f"{'='*60}")

    try:
        # Stop container first
        subprocess.run(["docker", "compose", "-f", "docker-compose.mcp.yml", "down"], timeout=10, capture_output=True, text=True)
        time.sleep(2)

        cmd = ["docker", "compose", "-f", "docker-compose.mcp.yml", "up", "-d", "rag-mcp"]
        exit_code_1, stdout_1, stderr_1, duration_1 = run_command(cmd, 10)
        assert_success(test_name_1, exit_code_1, stdout_1, stderr_1, duration_1, TIMEOUTS["compose"])

        # Verify container is running
        check_cmd = ["docker", "ps", "--filter", "name=rag-mcp", "--format", "{{.Status}}"]
        check_result = subprocess.run(check_cmd, capture_output=True, text=True, timeout=5)
        if "running" not in check_result.stdout.lower():
            raise AssertionError(f"Container not running: {check_result.stdout}")
        
        print(f"  Container started successfully: Yes")
        print(f"  Health check: Running")

        record_test_result(
            test_id="docker-1-compose-up",
            name=test_name_1,
            command=" ".join(cmd),
            environment="docker_compose",
            exit_code=exit_code_1,
            stdout=stdout_1,
            stderr=stderr_1,
            duration=duration_1,
            timeout=10,
            passed=True,
            assertions=[{"name": "exit_code", "expected": 0, "actual": exit_code_1, "passed": True},
                    {"name": "container_running", "expected": "running", "actual": "running", "passed": True}]
        )

    except AssertionError as e:
        print(f"❌ {test_name_1}: FAILED")
        print(f"  {str(e)}")
        record_test_result(
            test_id="docker-1-compose-up",
            name=test_name_1,
            command=" ".join(cmd),
            environment="docker_compose",
            exit_code=exit_code_1 if 'exit_code_1' in locals() else -1,
            stdout=stdout_1 if 'stdout_1' in locals() else "",
            stderr=stderr_1 if 'stderr_1' in locals() else str(e),
            duration=duration_1 if 'duration_1' in locals() else 0,
            timeout=10,
            passed=False,
            assertions=[]
        )
    finally:
        subprocess.run(["docker", "compose", "-f", "docker-compose.mcp.yml", "down"], timeout=10, capture_output=True, text=True)

    # Test Docker-2: Docker Compose Stop
    test_name_2 = "Docker-2: Docker Compose Stop"
    print(f"\n{'='*60}")
    print(f"Testing: {test_name_2}")
    print(f"{'='*60}")

    try:
        # Start container first
        subprocess.run(["docker", "compose", "-f", "docker-compose.mcp.yml", "up", "-d", "rag-mcp"], timeout=10, capture_output=True, text=True)
        time.sleep(2)

        cmd = ["docker", "compose", "-f", "docker-compose.mcp.yml", "down"]
        exit_code_2, stdout_2, stderr_2, duration_2 = run_command(cmd, 5)
        assert_success(test_name_2, exit_code_2, stdout_2, stderr_2, duration_2, TIMEOUTS["compose"])

        # Verify container stopped
        check_cmd = ["docker", "ps", "--filter", "name=rag-mcp", "--format", "{{.Status}}"]
        check_result = subprocess.run(check_cmd, capture_output=True, text=True, timeout=5)
        if "running" in check_result.stdout.lower():
            raise AssertionError(f"Container still running: {check_result.stdout}")
        
        print(f"  Container stopped gracefully: Yes")

        record_test_result(
            test_id="docker-2-compose-stop",
            name=test_name_2,
            command=" ".join(cmd),
            environment="docker_compose",
            exit_code=exit_code_2,
            stdout=stdout_2,
            stderr=stderr_2,
            duration=duration_2,
            timeout=5,
            passed=True,
            assertions=[{"name": "exit_code", "expected": 0, "actual": exit_code_2, "passed": True}]
        )

    except AssertionError as e:
        print(f"❌ {test_name_2}: FAILED")
        print(f"  {str(e)}")
        record_test_result(
            test_id="docker-2-compose-stop",
            name=test_name_2,
            command=" ".join(cmd),
            environment="docker_compose",
            exit_code=exit_code_2 if 'exit_code_2' in locals() else -1,
            stdout=stdout_2 if 'stdout_2' in locals() else "",
            stderr=stderr_2 if 'stderr_2' in locals() else str(e),
            duration=duration_2 if 'duration_2' in locals() else 0,
            timeout=5,
            passed=False,
            assertions=[]
        )

    # Test Docker-3: Docker Compose Ps
    test_name_3 = "Docker-3: Docker Compose Ps"
    print(f"\n{'='*60}")
    print(f"Testing: {test_name_3}")
    print(f"{'='*60}")

    try:
        # Start container
        subprocess.run(["docker", "compose", "-f", "docker-compose.mcp.yml", "up", "-d", "rag-mcp"], timeout=10, capture_output=True, text=True)
        time.sleep(2)

        cmd = ["docker", "compose", "-f", "docker-compose.mcp.yml", "ps"]
        exit_code_3, stdout_3, stderr_3, duration_3 = run_command(cmd, 2)
        assert_success(test_name_3, exit_code_3, stdout_3, stderr_3, duration_3, TIMEOUTS["compose"])

        # Check output contains service status
        if "rag-mcp" not in stdout_3.lower():
            raise AssertionError(f"Service status not shown: {stdout_3[:200]}")
        if "Status" not in stdout_3:
            raise AssertionError(f"No status column: {stdout_3[:200]}")
        
        print(f"  Service status displayed: Yes")

        record_test_result(
            test_id="docker-3-compose-ps",
            name=test_name_3,
            command=" ".join(cmd),
            environment="docker_compose",
            exit_code=exit_code_3,
            stdout=stdout_3,
            stderr=stderr_3,
            duration=duration_3,
            timeout=2,
            passed=True,
            assertions=[{"name": "exit_code", "expected": 0, "actual": exit_code_3, "passed": True}]
        )

    except AssertionError as e:
        print(f"❌ {test_name_3}: FAILED")
        print(f"  {str(e)}")
        record_test_result(
            test_id="docker-3-compose-ps",
            name=test_name_3,
            command=" ".join(cmd),
            environment="docker_compose",
            exit_code=exit_code_3 if 'exit_code_3' in locals() else -1,
            stdout=stdout_3 if 'stdout_3' in locals() else "",
            stderr=stderr_3 if 'stderr_3' in locals() else str(e),
            duration=duration_3 if 'duration_3' in locals() else 0,
            timeout=2,
            passed=False,
            assertions=[]
        )
    finally:
        subprocess.run(["docker", "compose", "-f", "docker-compose.mcp.yml", "down"], timeout=10, capture_output=True, text=True)

    # Test Docker-4: Docker Compose Logs
    test_name_4 = "Docker-4: Docker Compose Logs"
    print(f"\n{'='*60}")
    print(f"Testing: {test_name_4}")
    print(f"{'='*60}")

    try:
        # Start container and let it generate logs
        subprocess.run(["docker", "compose", "-f", "docker-compose.mcp.yml", "up", "-d", "rag-mcp"], timeout=10, capture_output=True, text=True)
        time.sleep(2)

        cmd = ["docker", "compose", "-f", "docker-compose.mcp.yml", "logs", "rag-mcp"]
        exit_code_4, stdout_4, stderr_4, duration_4 = run_command(cmd, 5)
        assert_success(test_name_4, exit_code_4, stdout_4, stderr_4, duration_4, TIMEOUTS["compose"])

        # Check if logs show startup messages
        if "SYNAPSE" not in stdout_4:
            raise AssertionError(f"No SYNAPSE startup messages in logs")
        
        # Check if logs are in readable format
        if not stdout_4.strip():
            raise AssertionError(f"No logs available")
        
        print(f"  Logs accessible: Yes")
        print(f"  Startup messages shown: Yes")
        print(f"  Logs in readable format: Yes")

        record_test_result(
            test_id="docker-4-compose-logs",
            name=test_name_4,
            command=" ".join(cmd),
            environment="docker_compose",
            exit_code=exit_code_4,
            stdout=stdout_4,
            stderr=stderr_4,
            duration=duration_4,
            timeout=5,
            passed=True,
            assertions=[{"name": "exit_code", "expected": 0, "actual": exit_code_4, "passed": True}]
        )

    except AssertionError as e:
        print(f"❌ {test_name_4}: FAILED")
        print(f"  {str(e)}")
        record_test_result(
            test_id="docker-4-compose-logs",
            name=test_name_4,
            command=" ".join(cmd),
            environment="docker_compose",
            exit_code=exit_code_4 if 'exit_code_4' in locals() else -1,
            stdout=stdout_4 if 'stdout_4' in locals() else "",
            stderr=stderr_4 if 'stderr_4' in locals() else str(e),
            duration=duration_4 if 'duration_4' in locals() else 0,
            timeout=5,
            passed=False,
            assertions=[]
        )
    finally:
        subprocess.run(["docker", "compose", "-f", "docker-compose.mcp.yml", "down"], timeout=10, capture_output=True, text=True)

    # Print summary
    print_test_summary()

    # Exit with appropriate code
    exit_code = print_success_rate()
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
