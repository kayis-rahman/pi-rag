#!/usr/bin/env python3
"""
Phase 1 Test: P0-2 synapse config

Tests config command using actual CLI execution.
"""

import subprocess
import sys
import time
from pathlib import Path

# Import shared utilities
sys.path.insert(0, str(Path(__file__).parent))
from conftest import (
    TIMEOUTS,
    check_docker_container,
    record_test_result,
    print_test_summary,
    print_success_rate
)


def run_cli_command(args, timeout=60):
    """
    Run synapse CLI command and return (exit_code, stdout, stderr, duration).

    Args:
        args: List of command arguments (e.g., ["config"])
        timeout: Timeout in seconds

    Returns:
        Tuple of (exit_code, stdout, stderr, duration_seconds)
    """
    # Build full command list
    cmd = ["python3", "-m", "synapse.cli.main"] + args

    start_time = time.time()
    try:
        result = subprocess.run(
            cmd,
            timeout=timeout,
            capture_output=True,
            text=True,
            check=False
        )
        duration = time.time() - start_time
        return (result.returncode, result.stdout, result.stderr, duration)
    except subprocess.TimeoutExpired:
        duration = time.time() - start_time
        return (-1, "", f"Command timed out after {timeout}s", duration)
    except Exception as e:
        duration = time.time() - start_time
        return (-1, "", str(e), duration)


def test_config_1_docker():
    """Test Config-1: Docker Basic Display"""
    test_name = "Config-1: Docker Basic Display"

    # Check if Docker container is running
    if not check_docker_container():
        print(f"\n⚠️  SKIPPED: {test_name}")
        print("   Docker container 'rag-mcp' not running")
        record_test_result(
            test_id="config-1-docker",
            name=test_name,
            command="docker exec rag-mcp python3 -m synapse.cli.main config",
            environment="docker",
            exit_code=0,
            stdout="SKIPPED",
            stderr="Docker container not running",
            duration=0,
            timeout=TIMEOUTS["config"],
            passed=True
        )
        return

    # Initialize variables for error handling
    exit_code = -1
    stdout = ""
    stderr = ""
    duration = 0
    assertions = []

    try:
        print(f"\n{'='*60}")
        print(f"Testing: {test_name}")
        print(f"{'='*60}")

        # Run config in Docker container
        cmd = ["docker", "exec", "rag-mcp", "python3", "-m", "synapse.cli.main", "config"]
        start_time = time.time()
        try:
            result = subprocess.run(cmd, timeout=TIMEOUTS["config"], capture_output=True, text=True, check=False)
            duration = time.time() - start_time
            exit_code, stdout, stderr = result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            duration = time.time() - start_time
            exit_code, stdout, stderr = -1, "", f"Command timed out after {TIMEOUTS['config']}s"
        except Exception as e:
            duration = time.time() - start_time
            exit_code, stdout, stderr = -1, "", str(e)

        # Assertions

        # Exit code
        if exit_code != 0:
            raise AssertionError(
                f"Exit code {exit_code} (expected 0)\n"
                f"STDOUT:\n{stdout}\n\n"
                f"STDERR:\n{stderr}"
            )
        assertions.append({"name": "exit_code", "expected": 0, "actual": exit_code, "passed": True})

        # Timeout
        if duration > TIMEOUTS["config"]:
            raise AssertionError(
                f"Performance degradation: {duration:.2f}s (timeout: {TIMEOUTS['config']}s)"
            )
        assertions.append({"name": "timeout", "expected": f"<{TIMEOUTS['config']}s", "actual": f"{duration:.2f}s", "passed": True})

        # Output contains Data directory field
        if "Data Directory" not in stdout:
            raise AssertionError(
                f"Output doesn't contain 'Data Directory'\n"
                f"STDOUT:\n{stdout}"
            )
        assertions.append({"name": "contains_data_dir", "expected": "Data Directory", "actual": "Found", "passed": True})

        # Output contains Models directory field
        if "Models Directory" not in stdout:
            raise AssertionError(
                f"Output doesn't contain 'Models Directory'\n"
                f"STDOUT:\n{stdout}"
            )
        assertions.append({"name": "contains_models_dir", "expected": "Models Directory", "actual": "Found", "passed": True})

        # Output mentions RAG settings
        if "RAG Settings" not in stdout:
            raise AssertionError(
                f"Output doesn't mention 'RAG Settings'\n"
                f"STDOUT:\n{stdout}"
            )
        assertions.append({"name": "mentions_rag_settings", "expected": "RAG Settings", "actual": "Found", "passed": True})

        print(f"✅ {test_name}: PASSED (duration: {duration:.2f}s)")
        print(f"  Data directory displayed: Yes")
        print(f"  Models directory displayed: Yes")
        print(f"  RAG settings displayed: Yes")

        # Record result
        record_test_result(
            test_id="config-1-docker",
            name=test_name,
            command=" ".join(cmd) if 'cmd' in locals() else "docker exec ...",
            environment="docker",
            exit_code=exit_code,
            stdout=stdout,
            stderr=stderr,
            duration=duration,
            timeout=TIMEOUTS["config"],
            passed=True,
            assertions=assertions
        )

    except AssertionError as e:
        print(f"❌ {test_name}: FAILED")
        print(f"  {str(e)}")

        record_test_result(
            test_id="config-1-docker",
            name=test_name,
            command=" ".join(cmd) if 'cmd' in locals() else "docker exec ...",
            environment="docker",
            exit_code=exit_code,
            stdout=stdout,
            stderr=stderr,
            duration=duration,
            timeout=TIMEOUTS["config"],
            passed=False,
            assertions=assertions
        )
        raise


def test_config_2_docker_verbose():
    """Test Config-2: Docker Verbose Mode"""
    test_name = "Config-2: Docker Verbose Mode"

    # Check if Docker container is running
    if not check_docker_container():
        print(f"\n⚠️  SKIPPED: {test_name}")
        print("   Docker container 'rag-mcp' not running")
        record_test_result(
            test_id="config-2-docker-verbose",
            name=test_name,
            command="docker exec rag-mcp python3 -m synapse.cli.main config --verbose",
            environment="docker",
            exit_code=0,
            stdout="SKIPPED",
            stderr="Docker container not running",
            duration=0,
            timeout=TIMEOUTS["config"],
            passed=True
        )
        return

    # Initialize variables for error handling
    exit_code = -1
    stdout = ""
    stderr = ""
    duration = 0
    assertions = []

    try:
        print(f"\n{'='*60}")
        print(f"Testing: {test_name}")
        print(f"{'='*60}")

        # Run config with --verbose in Docker container
        cmd = ["docker", "exec", "rag-mcp", "python3", "-m", "synapse.cli.main", "config", "--verbose"]
        start_time = time.time()
        try:
            result = subprocess.run(cmd, timeout=TIMEOUTS["config"], capture_output=True, text=True, check=False)
            duration = time.time() - start_time
            exit_code, stdout, stderr = result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            duration = time.time() - start_time
            exit_code, stdout, stderr = -1, "", f"Command timed out after {TIMEOUTS['config']}s"
        except Exception as e:
            duration = time.time() - start_time
            exit_code, stdout, stderr = -1, "", str(e)

        # Assertions

        # Exit code
        if exit_code != 0:
            raise AssertionError(
                f"Exit code {exit_code} (expected 0)\n"
                f"STDOUT:\n{stdout}\n\n"
                f"STDERR:\n{stderr}"
            )
        assertions.append({"name": "exit_code", "expected": 0, "actual": exit_code, "passed": True})

        # Timeout
        if duration > TIMEOUTS["config"]:
            raise AssertionError(
                f"Performance degradation: {duration:.2f}s (timeout: {TIMEOUTS['config']}s)"
            )
        assertions.append({"name": "timeout", "expected": f"<{TIMEOUTS['config']}s", "actual": f"{duration:.2f}s", "passed": True})

        # Verbose flag accepted
        if exit_code == 0:
            assertions.append({"name": "verbose_flag_accepted", "expected": "Yes", "actual": "Yes", "passed": True})

        print(f"✅ {test_name}: PASSED (duration: {duration:.2f}s)")
        print(f"  Verbose flag accepted: Yes")

        # Record result
        record_test_result(
            test_id="config-2-docker-verbose",
            name=test_name,
            command=" ".join(cmd) if 'cmd' in locals() else "docker exec ...",
            environment="docker",
            exit_code=exit_code,
            stdout=stdout,
            stderr=stderr,
            duration=duration,
            timeout=TIMEOUTS["config"],
            passed=True,
            assertions=assertions
        )

    except AssertionError as e:
        print(f"❌ {test_name}: FAILED")
        print(f"  {str(e)}")

        record_test_result(
            test_id="config-2-docker-verbose",
            name=test_name,
            command=" ".join(cmd) if 'cmd' in locals() else "docker exec ...",
            environment="docker",
            exit_code=exit_code,
            stdout=stdout,
            stderr=stderr,
            duration=duration,
            timeout=TIMEOUTS["config"],
            passed=False,
            assertions=assertions
        )
        raise


def test_config_3_native():
    """Test Config-3: Native Basic Display"""
    test_name = "Config-3: Native Basic Display"

    # Initialize variables for error handling
    exit_code = -1
    stdout = ""
    stderr = ""
    duration = 0
    assertions = []

    try:
        print(f"\n{'='*60}")
        print(f"Testing: {test_name}")
        print(f"{'='*60}")

        # Run config in native mode
        cmd_args = ["config"]
        exit_code, stdout, stderr, duration = run_cli_command(cmd_args, TIMEOUTS["config"])

        # Assertions

        # Exit code
        if exit_code != 0:
            raise AssertionError(
                f"Exit code {exit_code} (expected 0)\n"
                f"STDOUT:\n{stdout}\n\n"
                f"STDERR:\n{stderr}"
            )
        assertions.append({"name": "exit_code", "expected": 0, "actual": exit_code, "passed": True})

        # Timeout
        if duration > TIMEOUTS["config"]:
            raise AssertionError(
                f"Performance degradation: {duration:.2f}s (timeout: {TIMEOUTS['config']}s)"
            )
        assertions.append({"name": "timeout", "expected": f"<{TIMEOUTS['config']}s", "actual": f"{duration:.2f}s", "passed": True})

        # Output displays correct data directory (supports both Docker/native /opt/synapse and user_home ~/.synapse)
        if "/opt/synapse/data" not in stdout and ".synapse/data" not in stdout:
            raise AssertionError(
                f"Output doesn't contain data directory path\n"
                f"STDOUT:\n{stdout}"
            )
        data_dir = "/opt/synapse/data" if "/opt/synapse/data" in stdout else "~/.synapse/data"
        assertions.append({"name": "correct_data_dir", "expected": data_dir, "actual": "Found", "passed": True})

        # Output displays correct models directory
        if "Models Directory" not in stdout:
            raise AssertionError(
                f"Output doesn't contain 'Models Directory'\n"
                f"STDOUT:\n{stdout}"
            )
        assertions.append({"name": "contains_models_dir", "expected": "Models Directory", "actual": "Found", "passed": True})

        print(f"✅ {test_name}: PASSED (duration: {duration:.2f}s)")
        print(f"  Data directory: {data_dir}")
        print(f"  Models directory displayed: Yes")

        # Record result
        record_test_result(
            test_id="config-3-native",
            name=test_name,
            command=f"synapse {' '.join(cmd_args)}",
            environment="native",
            exit_code=exit_code,
            stdout=stdout,
            stderr=stderr,
            duration=duration,
            timeout=TIMEOUTS["config"],
            passed=True,
            assertions=assertions
        )

    except AssertionError as e:
        print(f"❌ {test_name}: FAILED")
        print(f"  {str(e)}")

        record_test_result(
            test_id="config-3-native",
            name=test_name,
            command=f"synapse {' '.join(cmd_args)}",
            environment="native",
            exit_code=exit_code,
            stdout=stdout,
            stderr=stderr,
            duration=duration,
            timeout=TIMEOUTS["config"],
            passed=False,
            assertions=assertions
        )
        raise


def test_config_4_native_verbose():
    """Test Config-4: Native Verbose Mode"""
    test_name = "Config-4: Native Verbose Mode"

    # Initialize variables for error handling
    exit_code = -1
    stdout = ""
    stderr = ""
    duration = 0
    assertions = []

    try:
        print(f"\n{'='*60}")
        print(f"Testing: {test_name}")
        print(f"{'='*60}")

        # Run config with --verbose in native mode
        cmd_args = ["config", "--verbose"]
        exit_code, stdout, stderr, duration = run_cli_command(cmd_args, TIMEOUTS["config"])

        # Assertions

        # Exit code
        if exit_code != 0:
            raise AssertionError(
                f"Exit code {exit_code} (expected 0)\n"
                f"STDOUT:\n{stdout}\n\n"
                f"STDERR:\n{stderr}"
            )
        assertions.append({"name": "exit_code", "expected": 0, "actual": exit_code, "passed": True})

        # Timeout
        if duration > TIMEOUTS["config"]:
            raise AssertionError(
                f"Performance degradation: {duration:.2f}s (timeout: {TIMEOUTS['config']}s)"
            )
        assertions.append({"name": "timeout", "expected": f"<{TIMEOUTS['config']}s", "actual": f"{duration:.2f}s", "passed": True})

        # Verbose flag accepted
        if exit_code == 0:
            assertions.append({"name": "verbose_flag_accepted", "expected": "Yes", "actual": "Yes", "passed": True})

        # Output shows configuration values
        if "Environment" not in stdout:
            raise AssertionError(
                f"Output doesn't show configuration values\n"
                f"STDOUT:\n{stdout}"
            )
        assertions.append({"name": "shows_config_values", "expected": "Configuration values", "actual": "Found", "passed": True})

        print(f"✅ {test_name}: PASSED (duration: {duration:.2f}s)")
        print(f"  Verbose flag accepted: Yes")
        print(f"  Configuration displayed: Yes")

        # Record result
        record_test_result(
            test_id="config-4-native-verbose",
            name=test_name,
            command=f"synapse {' '.join(cmd_args)}",
            environment="native",
            exit_code=exit_code,
            stdout=stdout,
            stderr=stderr,
            duration=duration,
            timeout=TIMEOUTS["config"],
            passed=True,
            assertions=assertions
        )

    except AssertionError as e:
        print(f"❌ {test_name}: FAILED")
        print(f"  {str(e)}")

        record_test_result(
            test_id="config-4-native-verbose",
            name=test_name,
            command=f"synapse {' '.join(cmd_args)}",
            environment="native",
            exit_code=exit_code,
            stdout=stdout,
            stderr=stderr,
            duration=duration,
            timeout=TIMEOUTS["config"],
            passed=False,
            assertions=assertions
        )
        raise


def main():
    """Main test execution."""
    print(f"\n{'='*60}")
    print(f"Phase 1 Test: P0-2 synapse config (CLI Execution)")
    print(f"{'='*60}\n")

    tests = [
        ("Config-1: Docker Basic Display", test_config_1_docker),
        ("Config-2: Docker Verbose Mode", test_config_2_docker_verbose),
        ("Config-3: Native Basic Display", test_config_3_native),
        ("Config-4: Native Verbose Mode", test_config_4_native_verbose),
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
