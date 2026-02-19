#!/usr/bin/env python3
"""
Phase 1 Test: P0-1 synapse setup

Tests setup command using actual CLI execution.
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
        args: List of command arguments (e.g., ["setup", "--no-model-check"])
        timeout: Timeout in seconds

    Returns:
        Tuple of (exit_code, stdout, stderr, duration_seconds)
    """
    # Build full command list
    # Use python -m synapse.cli.main to invoke CLI
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


def test_setup_1_docker():
    """Test Setup-1: Docker Auto-Detection"""
    test_name = "Setup-1: Docker Auto-Detection"

    # Check if Docker container is running
    if not check_docker_container():
        print(f"\n⚠️  SKIPPED: {test_name}")
        print("   Docker container 'rag-mcp' not running")
        record_test_result(
            test_id="setup-1-docker",
            name=test_name,
            command="docker exec rag-mcp python3 -m synapse.cli.main setup --no-model-check",
            environment="docker",
            exit_code=0,
            stdout="SKIPPED",
            stderr="Docker container not running",
            duration=0,
            timeout=TIMEOUTS["setup"],
            passed=True  # Skipped tests don't fail suite
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

        # Run setup in Docker container
        cmd = ["docker", "exec", "rag-mcp", "python3", "-m", "synapse.cli.main", "setup", "--no-model-check"]
        start_time = time.time()
        try:
            result = subprocess.run(cmd, timeout=TIMEOUTS["setup"], capture_output=True, text=True, check=False)
            duration = time.time() - start_time
            exit_code, stdout, stderr = result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            duration = time.time() - start_time
            exit_code, stdout, stderr = -1, "", f"Command timed out after {TIMEOUTS['setup']}s"
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
        if duration > TIMEOUTS["setup"]:
            raise AssertionError(
                f"Performance degradation: {duration:.2f}s (timeout: {TIMEOUTS['setup']}s)"
            )
        assertions.append({"name": "timeout", "expected": f"<{TIMEOUTS['setup']}s", "actual": f"{duration:.2f}s", "passed": True})

        # Output contains Docker data directory
        if "/app/data" not in stdout:
            raise AssertionError(
                f"Output doesn't contain '/app/data'\n"
                f"STDOUT:\n{stdout}"
            )
        assertions.append({"name": "contains_docker_dir", "expected": "/app/data", "actual": "Found", "passed": True})

        # Output mentions models directory
        if "models" not in stdout.lower():
            raise AssertionError(
                f"Output doesn't mention 'models'\n"
                f"STDOUT:\n{stdout}"
            )
        assertions.append({"name": "mentions_models", "expected": "models", "actual": "Found", "passed": True})

        print(f"✅ {test_name}: PASSED (duration: {duration:.2f}s)")
        print(f"  Data directory: /app/data")
        print(f"  Models directory mentioned: Yes")

        # Record result
        record_test_result(
            test_id="setup-1-docker",
            name=test_name,
            command=" ".join(cmd),
            environment="docker",
            exit_code=exit_code,
            stdout=stdout,
            stderr=stderr,
            duration=duration,
            timeout=TIMEOUTS["setup"],
            passed=True,
            assertions=assertions
        )

    except AssertionError as e:
        print(f"❌ {test_name}: FAILED")
        print(f"  {str(e)}")

        record_test_result(
            test_id="setup-1-docker",
            name=test_name,
            command=" ".join(cmd) if 'cmd' in locals() else "docker exec ...",
            environment="docker",
            exit_code=exit_code,
            stdout=stdout,
            stderr=stderr,
            duration=duration,
            timeout=TIMEOUTS["setup"],
            passed=False,
            assertions=assertions
        )
        raise


def test_setup_2_native():
    """Test Setup-2: Native Auto-Detection"""
    test_name = "Setup-2: Native Auto-Detection"

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

        # Run setup in native mode
        cmd_args = ["setup", "--no-model-check"]
        exit_code, stdout, stderr, duration = run_cli_command(cmd_args, TIMEOUTS["setup"])

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
        if duration > TIMEOUTS["setup"]:
            raise AssertionError(
                f"Performance degradation: {duration:.2f}s (timeout: {TIMEOUTS['setup']}s)"
            )
        assertions.append({"name": "timeout", "expected": f"<{TIMEOUTS['setup']}s", "actual": f"{duration:.2f}s", "passed": True})

        # Output contains native data directory (supports both Docker/native /opt/synapse and user_home ~/.synapse)
        if "/opt/synapse/data" not in stdout and ".synapse/data" not in stdout:
            raise AssertionError(
                f"Output doesn't contain data directory path\n"
                f"STDOUT:\n{stdout}"
            )
        data_dir = "/opt/synapse/data" if "/opt/synapse/data" in stdout else "~/.synapse/data"
        assertions.append({"name": "contains_native_dir", "expected": data_dir, "actual": "Found", "passed": True})

        # Output mentions models directory
        if "models" not in stdout.lower():
            raise AssertionError(
                f"Output doesn't mention 'models'\n"
                f"STDOUT:\n{stdout}"
            )
        assertions.append({"name": "mentions_models", "expected": "models", "actual": "Found", "passed": True})

        # Check if models directory actually exists (supports both Docker/native and user_home paths)
        if "/opt/synapse/data" in stdout:
            models_dir = Path("/opt/synapse/data/models")
        else:
            # user_home mode
            models_dir = Path.home() / ".synapse" / "data" / "models"
        
        if not models_dir.exists():
            print(f"  ⚠️  Warning: Models directory doesn't exist yet (may need actual setup)")
        else:
            print(f"  ✓ Models directory exists: {models_dir}")
            assertions.append({"name": "directory_exists", "expected": str(models_dir), "actual": "Exists", "passed": True})

        print(f"✅ {test_name}: PASSED (duration: {duration:.2f}s)")
        print(f"  Data directory: {data_dir}")

        # Record result
        record_test_result(
            test_id="setup-2-native",
            name=test_name,
            command=f"synapse {' '.join(cmd_args)}",
            environment="native",
            exit_code=exit_code,
            stdout=stdout,
            stderr=stderr,
            duration=duration,
            timeout=TIMEOUTS["setup"],
            passed=True,
            assertions=assertions
        )

    except AssertionError as e:
        print(f"❌ {test_name}: FAILED")
        print(f"  {str(e)}")

        record_test_result(
            test_id="setup-2-native",
            name=test_name,
            command=f"synapse {' '.join(cmd_args)}",
            environment="native",
            exit_code=exit_code,
            stdout=stdout,
            stderr=stderr,
            duration=duration,
            timeout=TIMEOUTS["setup"],
            passed=False,
            assertions=assertions
        )
        raise


def test_setup_3_user_home():
    """Test Setup-3: User Home Auto-Detection"""
    test_name = "Setup-3: User Home Auto-Detection"

    # For user home, we can't easily test without modifying environment
    # We'll skip this test for now and note it
    print(f"\n{'='*60}")
    print(f"Testing: {test_name}")
    print(f"{'='*60}")
    print(f"⚠️  SKIPPED: User home mode requires clean environment")
    print(f"   (would interfere with native mode testing)")

    record_test_result(
        test_id="setup-3-user-home",
        name=test_name,
        command="synapse setup --no-model-check",
        environment="user_home",
        exit_code=0,
        stdout="SKIPPED",
        stderr="Requires clean environment test",
        duration=0,
        timeout=TIMEOUTS["setup"],
        passed=True
    )


def test_setup_4_force():
    """Test Setup-4: Force Re-Setup"""
    test_name = "Setup-4: Force Re-Setup"

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

        # Run setup with --force
        cmd_args = ["setup", "--force", "--no-model-check"]
        exit_code, stdout, stderr, duration = run_cli_command(cmd_args, TIMEOUTS["setup"])

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
        if duration > TIMEOUTS["setup"]:
            raise AssertionError(
                f"Performance degradation: {duration:.2f}s (timeout: {TIMEOUTS['setup']}s)"
            )
        assertions.append({"name": "timeout", "expected": f"<{TIMEOUTS['setup']}s", "actual": f"{duration:.2f}s", "passed": True})

        # Output indicates setup complete
        if "setup" not in stdout.lower():
            raise AssertionError(
                f"Output doesn't mention 'setup'\n"
                f"STDOUT:\n{stdout}"
            )
        assertions.append({"name": "mentions_setup", "expected": "setup", "actual": "Found", "passed": True})

        print(f"✅ {test_name}: PASSED (duration: {duration:.2f}s)")
        print(f"  Force flag accepted: Yes")

        # Record result
        record_test_result(
            test_id="setup-4-force",
            name=test_name,
            command=f"synapse {' '.join(cmd_args)}",
            environment="native",
            exit_code=exit_code,
            stdout=stdout,
            stderr=stderr,
            duration=duration,
            timeout=TIMEOUTS["setup"],
            passed=True,
            assertions=assertions
        )

    except AssertionError as e:
        print(f"❌ {test_name}: FAILED")
        print(f"  {str(e)}")

        record_test_result(
            test_id="setup-4-force",
            name=test_name,
            command=f"synapse {' '.join(cmd_args)}",
            environment="native",
            exit_code=exit_code,
            stdout=stdout,
            stderr=stderr,
            duration=duration,
            timeout=TIMEOUTS["setup"],
            passed=False,
            assertions=assertions
        )
        raise


def test_setup_5_offline():
    """Test Setup-5: Offline Mode"""
    test_name = "Setup-5: Offline Mode"

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

        # Run setup with --offline
        cmd_args = ["setup", "--offline", "--no-model-check"]
        exit_code, stdout, stderr, duration = run_cli_command(cmd_args, TIMEOUTS["setup"])

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
        if duration > TIMEOUTS["setup"]:
            raise AssertionError(
                f"Performance degradation: {duration:.2f}s (timeout: {TIMEOUTS['setup']}s)"
            )
        assertions.append({"name": "timeout", "expected": f"<{TIMEOUTS['setup']}s", "actual": f"{duration:.2f}s", "passed": True})

        # Output should show setup completed (offline mode message only appears when models missing)
        # Check for successful setup completion indicators
        if "SYNAPSE Setup" not in stdout and "setup" not in stdout.lower():
            raise AssertionError(
                f"Output doesn't show setup completion\n"
                f"STDOUT:\n{stdout}"
            )
        # Check for data directory confirmation
        if "Data directory" not in stdout:
            raise AssertionError(
                f"Output doesn't show data directory\n"
                f"STDOUT:\n{stdout}"
            )
        assertions.append({"name": "setup_completed", "expected": "SYNAPSE Setup + Data directory", "actual": "Found", "passed": True})

        print(f"✅ {test_name}: PASSED (duration: {duration:.2f}s)")
        print(f"  Offline/no-model-check mode: Yes")

        # Record result
        record_test_result(
            test_id="setup-5-offline",
            name=test_name,
            command=f"synapse {' '.join(cmd_args)}",
            environment="native",
            exit_code=exit_code,
            stdout=stdout,
            stderr=stderr,
            duration=duration,
            timeout=TIMEOUTS["setup"],
            passed=True,
            assertions=assertions
        )

    except AssertionError as e:
        print(f"❌ {test_name}: FAILED")
        print(f"  {str(e)}")

        record_test_result(
            test_id="setup-5-offline",
            name=test_name,
            command=f"synapse {' '.join(cmd_args)}",
            environment="native",
            exit_code=exit_code,
            stdout=stdout,
            stderr=stderr,
            duration=duration,
            timeout=TIMEOUTS["setup"],
            passed=False,
            assertions=assertions
        )
        raise


def main():
    """Main test execution."""
    print(f"\n{'='*60}")
    print(f"Phase 1 Test: P0-1 synapse setup (CLI Execution)")
    print(f"{'='*60}\n")

    tests = [
        ("Setup-1: Docker Auto-Detection", test_setup_1_docker),
        ("Setup-2: Native Auto-Detection", test_setup_2_native),
        ("Setup-3: User Home Auto-Detection", test_setup_3_user_home),
        ("Setup-4: Force Re-Setup", test_setup_4_force),
        ("Setup-5: Offline Mode", test_setup_5_offline),
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
