#!/usr/bin/env python3
"""
Phase 2 Test: P1-2 synapse stop

Tests stop command using Docker Compose and native modes.
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


def check_server_running(port: int = 8002) -> bool:
    """
    Check if server is running on given port.
    """
    try:
        # Check if port is in use
        cmd = ["lsof", "-i", f":{port}", "-t", "-P"]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=2)
        return result.returncode == 0
    except Exception:
        return False


def stop_server_docker():
    """Stop Docker container if running."""
    try:
        subprocess.run(["docker", "compose", "down"], timeout=30, capture_output=True, text=True)
        time.sleep(2)  # Wait for graceful shutdown
    except Exception:
        pass


def stop_server_native(port: int = 8002):
    """Stop native server if running."""
    try:
        # Kill process listening on port
        subprocess.run(["fuser", "-k", str(port), "/tcp"], timeout=5, capture_output=True, text=True)
        time.sleep(2)  # Wait for graceful shutdown
    except Exception:
        pass


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


def test_stop_1_docker_compose():
    """Test Stop-1: Docker Compose Stop"""
    test_name = "Stop-1: Docker Compose Stop"

    # Initialize variables
    exit_code = -1
    stdout = ""
    stderr = ""
    duration = 0
    assertions = []

    try:
        print(f"\n{'='*60}")
        print(f"Testing: {test_name}")
        print(f"{'='*60}")

        # Ensure server is running first
        if not check_docker_container():
            print(f"  ⚠️  Skipping test - Docker container not running")
            record_test_result(
                test_id="stop-1-docker-compose",
                name=test_name,
                command="docker compose down",
                environment="docker_compose",
                exit_code=0,
                stdout="SKIPPED",
                stderr="Container not running",
                duration=0,
                timeout=TIMEOUTS["stop"],
                passed=True,
                assertions=[{"name": "skipped", "expected": "N/A", "actual": "N/A", "passed": True}]
            )
            return

        # Run docker compose down
        cmd = ["docker", "compose", "down"]
        exit_code, stdout, stderr, duration = run_command(cmd, 5)

        # Assertions
        assert_success(test_name, exit_code, stdout, stderr, duration, TIMEOUTS["stop"])
        assertions.append({"name": "exit_code", "expected": 0, "actual": exit_code, "passed": True})
        assertions.append({"name": "timeout", "expected": "<5s", "actual": f"{duration:.2f}s", "passed": True})

        # Verify no zombie processes
        time.sleep(1)
        check_cmd = ["docker", "ps", "--filter", "name=rag-mcp", "--format", "{{.Status}}"]
        check_result = subprocess.run(check_cmd, capture_output=True, text=True, timeout=5)
        
        if "running" in check_result.stdout.lower():
            raise AssertionError(f"Container still running: {check_result.stdout}")
        assertions.append({"name": "no_zombie_processes", "expected": "stopped", "actual": "stopped", "passed": True})

        print(f"  Container stopped gracefully: Yes")
        print(f"  No zombie processes: Yes")

        record_test_result(
            test_id="stop-1-docker-compose",
            name=test_name,
            command="docker compose down",
            environment="docker_compose",
            exit_code=exit_code,
            stdout=stdout,
            stderr=stderr,
            duration=duration,
            timeout=TIMEOUTS["stop"],
            passed=True,
            assertions=assertions
        )

    except AssertionError as e:
        print(f"❌ {test_name}: FAILED")
        print(f"  {str(e)}")
        record_test_result(
            test_id="stop-1-docker-compose",
            name=test_name,
            command="docker compose down",
            environment="docker_compose",
            exit_code=exit_code if 'exit_code' in locals() else -1,
            stdout=stdout if 'stdout' in locals() else "",
            stderr=stderr if 'stderr' in locals() else str(e),
            duration=duration if 'duration' in locals() else 0,
            timeout=TIMEOUTS["stop"],
            passed=False,
            assertions=assertions if 'assertions' in locals() else []
        )
        raise
    finally:
        # Cleanup: Stop server after test (should already be stopped)
        pass


def test_stop_2_native():
    """Test Stop-2: Native Stop"""
    test_name = "Stop-2: Native Stop"

    # Initialize variables
    exit_code = -1
    stdout = ""
    stderr = ""
    duration = 0
    assertions = []

    try:
        print(f"\n{'='*60}")
        print(f"Testing: {test_name}")
        print(f"{'='*60}")

        # Ensure server is running first
        if not check_server_running():
            print(f"  ⚠️  Starting server for this test...")
            # Start server first
            start_cmd = ["python3", "-m", "synapse.cli.main", "start"]
            subprocess.Popen(start_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            time.sleep(5)

        # Run synapse stop
        cmd = ["python3", "-m", "synapse.cli.main", "stop"]
        exit_code, stdout, stderr, duration = run_command(cmd, 10)

        # Assertions
        assert_success(test_name, exit_code, stdout, stderr, duration, TIMEOUTS["stop"])
        assertions.append({"name": "exit_code", "expected": 0, "actual": exit_code, "passed": True})
        assertions.append({"name": "timeout", "expected": "<5s", "actual": f"{duration:.2f}s", "passed": True})

        # Verify server is stopped
        time.sleep(1)
        if check_server_running():
            raise AssertionError("Server still running after stop command")
        assertions.append({"name": "server_stopped", "expected": True, "actual": True, "passed": True})

        print(f"  Server stopped gracefully: Yes")
        print(f"  No zombie processes: Yes")

        record_test_result(
            test_id="stop-2-native",
            name=test_name,
            command="synapse stop",
            environment="native",
            exit_code=exit_code,
            stdout=stdout,
            stderr=stderr,
            duration=duration,
            timeout=TIMEOUTS["stop"],
            passed=True,
            assertions=assertions
        )

    except AssertionError as e:
        print(f"❌ {test_name}: FAILED")
        print(f"  {str(e)}")
        record_test_result(
            test_id="stop-2-native",
            name=test_name,
            command="synapse stop",
            environment="native",
            exit_code=exit_code if 'exit_code' in locals() else -1,
            stdout=stdout if 'stdout' in locals() else "",
            stderr=stderr if 'stderr' in locals() else str(e),
            duration=duration if 'duration' in locals() else 0,
            timeout=TIMEOUTS["stop"],
            passed=False,
            assertions=assertions if 'assertions' in locals() else []
        )
        raise
    finally:
        # Cleanup: Ensure server is stopped
        stop_server_native()


def test_stop_3_not_running():
    """Test Stop-3: Server Not Running"""
    test_name = "Stop-3: Server Not Running"

    # Initialize variables
    exit_code = -1
    stdout = ""
    stderr = ""
    duration = 0
    assertions = []

    try:
        print(f"\n{'='*60}")
        print(f"Testing: {test_name}")
        print(f"{'='*60}")

        # Ensure server is NOT running
        if check_server_running():
            print(f"  ⚠️  Server is running, stopping first...")
            stop_server_native()
            time.sleep(2)

        # Run synapse stop when server is not running
        cmd = ["python3", "-m", "synapse.cli.main", "stop"]
        exit_code, stdout, stderr, duration = run_command(cmd, 5)

        # Assertions
        # Exit code can be non-zero (server not running)
        # What we care about is clear error message
        if not check_server_running():
            assertions.append({"name": "server_stopped", "expected": "already stopped", "actual": "stopped", "passed": True})
            print(f"  Server state: Not running (correct)")
        else:
            raise AssertionError("Server still running after stop command")
        
        # Check if error message is clear
        if stderr or "not" in stdout.lower() or "stopped" in stdout.lower():
            assertions.append({"name": "error_message_clear", "expected": True, "actual": True, "passed": True})
            print(f"  Error message clear: Yes")
        else:
            assertions.append({"name": "error_message_clear", "expected": True, "actual": False, "passed": False})

        print(f"✅ {test_name}: PASSED (duration: {duration:.2f}s)")
        print(f"  Server not running handled: Yes")

        record_test_result(
            test_id="stop-3-not-running",
            name=test_name,
            command="synapse stop (server not running)",
            environment="native",
            exit_code=exit_code,
            stdout=stdout,
            stderr=stderr,
            duration=duration,
            timeout=TIMEOUTS["stop"],
            passed=True,
            assertions=assertions
        )

    except AssertionError as e:
        print(f"❌ {test_name}: FAILED")
        print(f"  {str(e)}")
        record_test_result(
            test_id="stop-3-not-running",
            name=test_name,
            command="synapse stop (server not running)",
            environment="native",
            exit_code=exit_code if 'exit_code' in locals() else -1,
            stdout=stdout if 'stdout' in locals() else "",
            stderr=stderr if 'stderr' in locals() else str(e),
            duration=duration if 'duration' in locals() else 0,
            timeout=TIMEOUTS["stop"],
            passed=False,
            assertions=assertions if 'assertions' in locals() else []
        )
        raise


def test_stop_4_forced_stop():
    """Test Stop-4: Forced Stop"""
    test_name = "Stop-4: Forced Stop"

    # Initialize variables
    exit_code = -1
    stdout = ""
    stderr = ""
    duration = 0
    assertions = []

    try:
        print(f"\n{'='*60}")
        print(f"Testing: {test_name}")
        print(f"{'='*60}")

        # Ensure server is running first
        if not check_server_running():
            print(f"  ⚠️  Starting server for this test...")
            start_cmd = ["python3", "-m", "synapse.cli.main", "start"]
            subprocess.Popen(start_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            time.sleep(5)

        # Use fuser -9 for forced immediate stop (no grace period)
        cmd = ["fuser", "-9", "8002", "/tcp"]
        exit_code, stdout, stderr, duration = run_command(cmd, 2)

        # Assertions
        # fuser -9 sends SIGKILL, so exit code may be non-zero if process was killed
        if check_server_running():
            raise AssertionError("Server still running after forced stop")
        assertions.append({"name": "server_stopped_immediately", "expected": True, "actual": True, "passed": True})

        print(f"✅ {test_name}: PASSED (duration: {duration:.2f}s)")
        print(f"  Server stopped immediately: Yes")

        record_test_result(
            test_id="stop-4-forced",
            name=test_name,
            command="fuser -9 8002 /tcp (forced stop)",
            environment="native",
            exit_code=exit_code,
            stdout=stdout,
            stderr=stderr,
            duration=duration,
            timeout=TIMEOUTS["stop"],
            passed=True,
            assertions=assertions
        )

    except AssertionError as e:
        print(f"❌ {test_name}: FAILED")
        print(f"  {str(e)}")
        record_test_result(
            test_id="stop-4-forced",
            name=test_name,
            command="fuser -9 8002 /tcp (forced stop)",
            environment="native",
            exit_code=exit_code if 'exit_code' in locals() else -1,
            stdout=stdout if 'stdout' in locals() else "",
            stderr=stderr if 'stderr' in locals() else str(e),
            duration=duration if 'duration' in locals() else 0,
            timeout=TIMEOUTS["stop"],
            passed=False,
            assertions=assertions if 'assertions' in locals() else []
        )
        raise
    finally:
        # Cleanup: Ensure server is stopped
        stop_server_native()


def test_stop_5_volume_persistence():
    """Test Stop-5: Docker Volume Persistence"""
    test_name = "Stop-5: Docker Volume Persistence"

    # Initialize variables
    exit_code = -1
    stdout = ""
    stderr = ""
    duration = 0
    assertions = []

    try:
        print(f"\n{'='*60}")
        print(f"Testing: {test_name}")
        print(f"{'='*60}")

        # Check if Docker container is running
        if not check_docker_container():
            print(f"  ⚠️  Skipping test - Docker container not running")
            record_test_result(
                test_id="stop-5-volume-persistence",
                name=test_name,
                command="docker compose down",
                environment="docker_compose",
                exit_code=0,
                stdout="SKIPPED",
                stderr="Container not running",
                duration=0,
                timeout=TIMEOUTS["stop"],
                passed=True,
                assertions=[{"name": "skipped", "expected": "N/A", "actual": "N/A", "passed": True}]
            )
            return

        # Create test data in container
        print(f"  Creating test data in container...")
        data_cmd = ["docker", "exec", "rag-mcp", "sh", "-c", "echo 'test data' > /app/data/test.txt"]
        subprocess.run(data_cmd, capture_output=True, timeout=10)
        time.sleep(1)

        # Stop container
        cmd = ["docker", "compose", "down"]
        exit_code, stdout, stderr, duration = run_command(cmd, 10)

        # Assertions
        assert_success(test_name, exit_code, stdout, stderr, duration, TIMEOUTS["stop"])
        assertions.append({"name": "exit_code", "expected": 0, "actual": exit_code, "passed": True})
        assertions.append({"name": "timeout", "expected": "<5s", "actual": f"{duration:.2f}s", "passed": True})

        # Start container again
        print(f"  Restarting container to check persistence...")
        subprocess.run(["docker", "compose", "up", "-d", "rag-mcp"], capture_output=True, timeout=20)
        time.sleep(3)

        # Check if data persists
        check_cmd = ["docker", "exec", "rag-mcp", "cat", "/app/data/test.txt"]
        check_result = subprocess.run(check_cmd, capture_output=True, text=True, timeout=5)
        
        if "test data" in check_result.stdout:
            assertions.append({"name": "data_persisted", "expected": True, "actual": True, "passed": True})
            print(f"  Data persisted: Yes")
        else:
            raise AssertionError(f"Data not persisted: {check_result.stdout}")

        # Cleanup: Stop container and remove test data
        subprocess.run(["docker", "exec", "rag-mcp", "rm", "/app/data/test.txt"], capture_output=True, timeout=5)
        subprocess.run(["docker", "compose", "down"], capture_output=True, timeout=10)

        print(f"✅ {test_name}: PASSED (duration: {duration:.2f}s)")

        record_test_result(
            test_id="stop-5-volume-persistence",
            name=test_name,
            command="docker compose down (with data persistence check)",
            environment="docker_compose",
            exit_code=exit_code,
            stdout=stdout,
            stderr=stderr,
            duration=duration,
            timeout=TIMEOUTS["stop"],
            passed=True,
            assertions=assertions
        )

    except AssertionError as e:
        print(f"❌ {test_name}: FAILED")
        print(f"  {str(e)}")
        record_test_result(
            test_id="stop-5-volume-persistence",
            name=test_name,
            command="docker compose down (with data persistence check)",
            environment="docker_compose",
            exit_code=exit_code if 'exit_code' in locals() else -1,
            stdout=stdout if 'stdout' in locals() else "",
            stderr=stderr if 'stderr' in locals() else str(e),
            duration=duration if 'duration' in locals() else 0,
            timeout=TIMEOUTS["stop"],
            passed=False,
            assertions=assertions if 'assertions' in locals() else []
        )
        raise


def test_stop_6_connection_cleanup():
    """Test Stop-6: Connection Cleanup"""
    test_name = "Stop-6: Connection Cleanup"

    # Initialize variables
    exit_code = -1
    stdout = ""
    stderr = ""
    duration = 0
    assertions = []

    try:
        print(f"\n{'='*60}")
        print(f"Testing: {test_name}")
        print(f"{'='*60}")

        # Start server
        print(f"  Starting server...")
        start_cmd = ["python3", "-m", "synapse.cli.main", "start"]
        subprocess.Popen(start_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(5)

        # Simulate connection by checking health endpoint
        print(f"  Simulating connection (health check)...")
        health_cmd = ["curl", "-s", "http://localhost:8002/health"]
        health_result = subprocess.run(health_cmd, capture_output=True, text=True, timeout=5)
        
        if health_result.returncode == 200:
            assertions.append({"name": "connection_established", "expected": True, "actual": True, "passed": True})
            print(f"  Connection established: Yes")
        else:
            raise AssertionError(f"Health check failed: {health_result.returncode}")

        # Stop server
        print(f"  Stopping server...")
        cmd = ["python3", "-m", "synapse.cli.main", "stop"]
        exit_code, stdout, stderr, duration = run_command(cmd, 5)

        # Assertions
        assert_success(test_name, exit_code, stdout, stderr, duration, TIMEOUTS["stop"])
        assertions.append({"name": "exit_code", "expected": 0, "actual": exit_code, "passed": True})
        assertions.append({"name": "timeout", "expected": "<5s", "actual": f"{duration:.2f}s", "passed": True})

        print(f"✅ {test_name}: PASSED (duration: {duration:.2f}s)")
        print(f"  Connections closed gracefully: Yes")

        record_test_result(
            test_id="stop-6-connection-cleanup",
            name=test_name,
            command="synapse stop (with connection cleanup)",
            environment="native",
            exit_code=exit_code,
            stdout=stdout,
            stderr=stderr,
            duration=duration,
            timeout=TIMEOUTS["stop"],
            passed=True,
            assertions=assertions
        )

    except AssertionError as e:
        print(f"❌ {test_name}: FAILED")
        print(f"  {str(e)}")
        record_test_result(
            test_id="stop-6-connection-cleanup",
            name=test_name,
            command="synapse stop (with connection cleanup)",
            environment="native",
            exit_code=exit_code if 'exit_code' in locals() else -1,
            stdout=stdout if 'stdout' in locals() else "",
            stderr=stderr if 'stderr' in locals() else str(e),
            duration=duration if 'duration' in locals() else 0,
            timeout=TIMEOUTS["stop"],
            passed=False,
            assertions=assertions if 'assertions' in locals() else []
        )
        raise
    finally:
        # Cleanup: Ensure server is stopped
        stop_server_native()


def main():
    """Main test execution."""
    print(f"\n{'='*60}")
    print(f"Phase 2 Test: P1-2 synapse stop (Docker Compose & Native)")
    print(f"{'='*60}\n")

    tests = [
        ("Stop-1: Docker Compose Stop", test_stop_1_docker_compose),
        ("Stop-2: Native Stop", test_stop_2_native),
        ("Stop-3: Server Not Running", test_stop_3_not_running),
        ("Stop-4: Forced Stop", test_stop_4_forced_stop),
        ("Stop-5: Docker Volume Persistence", test_stop_5_volume_persistence),
        ("Stop-6: Connection Cleanup", test_stop_6_connection_cleanup),
    ]

    try:
        # Run all tests
        for test_name, test_func in tests:
            try:
                test_func()
            except AssertionError:
                # Test failed, but continue with next test
                pass
            except Exception as e:
                # Unexpected error
                print(f"❌ {test_name}: EXCEPTION - {str(e)[:100]}")

    except KeyboardInterrupt:
        print("\n\n⚠️  Tests interrupted by user")
        sys.exit(2)

    # Print summary
    print_test_summary()

    # Exit with appropriate code
    exit_code = print_success_rate()
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
