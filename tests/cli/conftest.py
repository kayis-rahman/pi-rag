"""
Phase 1 Test Utilities (Shared)

Common test fixtures and utility functions for Phase 1 CLI tests.
"""

import subprocess
import sys
import time
from pathlib import Path
from typing import Dict, Tuple, List, Optional

# Test results storage
test_results: List[Dict[str, any]] = []

# Timeouts for different command types
TIMEOUTS = {
    "setup": 60,      # seconds
    "config": 2,       # seconds
    "models_list": 2,    # seconds
    "start": 10,       # seconds
    "stop": 5,         # seconds
    "status": 2,        # seconds
    "compose": 10,      # seconds (docker compose operations)
}

# Environments to test
ENVIRONMENTS = {
    "docker": {
        "command_prefix": ["docker", "exec", "rag-mcp"],
        "data_dir": "/app/data",
        "expected": True
    },
    "native": {
        "command_prefix": [],
        "data_dir": "/opt/synapse/data",
        "expected": True
    },
    "user_home": {
        "command_prefix": [],
        "data_dir": str(Path.home() / ".synapse" / "data"),
        "expected": False  # May not exist initially
    }
}


def run_command(
    command: List[str],
    timeout: int,
    check_exit_code: bool = True
) -> Tuple[int, str, str, float]:
    """
    Run command and return (exit_code, stdout, stderr, duration).

    Args:
        command: Command to execute (list of strings)
        timeout: Timeout in seconds
        check_exit_code: If True, raise AssertionError on non-zero exit

    Returns:
        Tuple of (exit_code, stdout, stderr, duration_seconds)

    Raises:
        AssertionError: If check_exit_code=True and exit_code != 0
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
    """
    Assert command succeeded (exit code 0, within timeout).

    Args:
        test_name: Name of the test
        exit_code: Command exit code
        stdout: Command stdout
        stderr: Command stderr
        duration: Command duration in seconds
        timeout: Expected timeout threshold

    Raises:
        AssertionError: If exit code != 0 or duration > timeout
    """
    # Assert exit code
    if exit_code != 0:
        raise AssertionError(
            f"{test_name}: FAILED - Exit code {exit_code}\n"
            f"STDOUT:\n{stdout}\n\n"
            f"STDERR:\n{stderr}"
        )

    # Assert timeout
    if duration > timeout:
        raise AssertionError(
            f"{test_name}: FAILED - Performance degradation\n"
            f"Duration: {duration:.2f}s (timeout: {timeout}s)"
        )

    print(f"✅ {test_name}: PASSED (duration: {duration:.2f}s)")


def assert_output_contains(
    test_name: str,
    stdout: str,
    expected_text: str
) -> None:
    """
    Assert output contains expected text.

    Args:
        test_name: Name of the test
        stdout: Command stdout
        expected_text: Expected substring in output

    Raises:
        AssertionError: If expected_text not found in stdout
    """
    if expected_text not in stdout:
        raise AssertionError(
            f"{test_name}: FAILED - Output missing expected text\n"
            f"Expected: '{expected_text}'\n"
            f"Got:\n{stdout}"
        )

    print(f"  ✓ Output contains: '{expected_text}'")


def assert_directory_exists(
    test_name: str,
    directory: str
) -> None:
    """
    Assert directory exists.

    Args:
        test_name: Name of the test
        directory: Directory path to check

    Raises:
        AssertionError: If directory doesn't exist
    """
    if not Path(directory).exists():
        raise AssertionError(
            f"{test_name}: FAILED - Directory not found\n"
            f"Expected: '{directory}'"
        )

    print(f"  ✓ Directory exists: {directory}")


def assert_timeout(
    test_name: str,
    duration: float,
    timeout: int
) -> None:
    """
    Assert command completed within timeout.

    Args:
        test_name: Name of the test
        duration: Command duration in seconds
        timeout: Expected timeout threshold

    Raises:
        AssertionError: If duration > timeout
    """
    if duration > timeout:
        raise AssertionError(
            f"{test_name}: FAILED - Performance degradation\n"
            f"Duration: {duration:.2f}s (timeout: {timeout}s)"
        )

    print(f"  ✓ Timeout check: {duration:.2f}s <= {timeout}s")


def check_docker_container() -> bool:
    """
    Check if Docker container 'rag-mcp' is running.

    Returns:
        True if container is running, False otherwise
    """
    try:
        result = subprocess.run(
            ["docker", "inspect", "-f", "{{.State}}", "rag-mcp"],
            capture_output=True,
            text=True,
            timeout=5
        )
        return result.returncode == 0 and "running" in result.stdout.lower()
    except Exception:
        return False


def check_directory_exists(directory: str) -> bool:
    """
    Check if directory exists.

    Args:
        directory: Directory path to check

    Returns:
        True if directory exists, False otherwise
    """
    return Path(directory).exists()


def record_test_result(
    test_id: str,
    name: str,
    command: str,
    environment: str,
    exit_code: int,
    stdout: str,
    stderr: str,
    duration: float,
    timeout: int,
    passed: bool,
    assertions: List[Dict[str, any]] = None
) -> None:
    """
    Record test result for later summary.

    Args:
        test_id: Unique test identifier
        name: Test name
        command: Command that was executed
        environment: Test environment (docker, native, user_home)
        exit_code: Command exit code
        stdout: Command stdout
        stderr: Command stderr
        duration: Command duration in seconds
        timeout: Timeout threshold
        passed: Whether test passed
        assertions: List of assertions (optional)
    """
    global test_results

    from datetime import datetime

    test_result = {
        "test_id": test_id,
        "name": name,
        "command": " ".join(command) if isinstance(command, list) else command,
        "environment": environment,
        "exit_code": exit_code,
        "stdout": stdout,
        "stderr": stderr,
        "duration": duration,
        "timeout": timeout,
        "passed": passed,
        "timestamp": datetime.now().isoformat(),
        "assertions": assertions or []
    }

    test_results.append(test_result)


def print_test_summary() -> None:
    """
    Print summary of all test results.
    """
    global test_results

    print(f"\n{'=' * 60}")
    print(f"Phase 1 Test Summary")
    print(f"{'=' * 60}")
    print(f"\nTotal tests: {len(test_results)}")
    print(f"Passed: {sum(1 for r in test_results if r['passed'])}")
    print(f"Failed: {sum(1 for r in test_results if not r['passed'])}")
    if len(test_results) > 0:
        print(f"Success rate: {sum(1 for r in test_results if r['passed']) / len(test_results) * 100:.1f}%")
    else:
        print(f"Success rate: 0.0%")

    # Print individual results
    print(f"\nTest Results:")
    print(f"{'-' * 60}")
    for result in test_results:
        status = "✅ PASS" if result['passed'] else "❌ FAIL"
        print(f"{status}: {result['name']} ({result['duration']:.2f}s, env: {result['environment']})")

        # Show failures
        if not result['passed']:
            print(f"  Exit code: {result['exit_code']}")
            if result['stderr']:
                print(f"  Error: {result['stderr'][:200]}")

    print(f"{'-' * 60}\n")


def print_success_rate() -> int:
    """
    Calculate and print success rate.

    Returns:
        Exit code (0 if all passed, 1 if any failed)
    """
    global test_results

    if not test_results:
        print("⚠️  No tests run")
        return 0

    failed_count = sum(1 for r in test_results if not r['passed'])

    if failed_count > 0:
        print(f"\n❌ {failed_count} test(s) failed")
        print(f"Phase 1 incomplete - Fix failures and re-run")
        return 1
    else:
        print(f"\n✅ All {len(test_results)} tests passed!")
        print(f"Phase 1 complete - Ready for Phase 2")
        return 0
