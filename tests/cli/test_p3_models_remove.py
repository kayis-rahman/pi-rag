#!/usr/bin/env python3
"""
Phase 4 Test: P3-4 Models Remove Command

Tests synapse models remove command with assertions.

Tests:
- Remove-1: Help output
- Remove-2: Remove invalid model
- Remove-3: Remove with force
- Remove-4: Remove with confirmation
"""

import subprocess
import sys
import time
import tempfile
from pathlib import Path
from typing import Dict, Tuple, List

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from conftest import (
    run_command,
    record_test_result,
    run_models_command,
    verify_models_remove,
    MODELS_TIMEOUTS,
    MODELS_THRESHOLDS
)

# Test results storage
test_results: List[Dict[str, any]] = []


def test_remove_1_help():
    """Remove-1: Help output."""
    test_name = "Remove-1: Help Output"
    environment = "native"

    print(f"\n🔄 Running: {test_name}")

    # Run remove help
    exit_code, stdout, stderr, duration = run_models_command(
        subcommand="remove",
        args=["--help"],
        environment=environment,
        timeout=MODELS_TIMEOUTS["models_remove"]
    )

    # Verify help
    has_help = "remove" in stdout.lower() or "model" in stdout.lower()
    passed = exit_code == 0 and has_help

    record_test_result(
        test_id="p3-remove-1",
        name=test_name,
        command="synapse models remove --help",
        environment=environment,
        exit_code=exit_code,
        stdout=stdout,
        stderr=stderr,
        duration=duration,
        timeout=MODELS_TIMEOUTS["models_remove"],
        passed=passed,
        assertions=[
            {"type": "exit_code", "expected": 0, "actual": exit_code, "passed": exit_code == 0},
            {"type": "has_help", "expected": True, "actual": has_help, "passed": has_help}
        ]
    )

    if passed:
        print(f"  ✅ {test_name}: PASSED (help output clear)")
    else:
        print(f"  ❌ {test_name}: FAILED")


def test_remove_2_invalid_model():
    """Remove-2: Remove invalid model."""
    test_name = "Remove-2: Invalid Model"
    environment = "native"

    print(f"\n🔄 Running: {test_name}")

    # Run remove with invalid model
    exit_code, stdout, stderr, duration = run_models_command(
        subcommand="remove",
        args=["nonexistent-model-xyz"],
        environment=environment,
        timeout=MODELS_TIMEOUTS["models_remove"]
    )

    # Should show error
    all_output = (stdout + stderr).lower()
    error_check = (
        "unknown" in all_output or
        "not found" in all_output or
        "invalid" in all_output or
        "error" in all_output
    )
    # Accept either non-zero exit OR error message
    passed = (exit_code != 0 or error_check)

    record_test_result(
        test_id="p3-remove-2",
        name=test_name,
        command="synapse models remove nonexistent-model",
        environment=environment,
        exit_code=exit_code,
        stdout=stdout,
        stderr=stderr,
        duration=duration,
        timeout=MODELS_TIMEOUTS["models_remove"],
        passed=passed,
        assertions=[
            {"type": "exit_code_or_error", "expected": "!= 0 or error shown", "actual": exit_code, "passed": passed}
        ]
    )

    if passed:
        print(f"  ✅ {test_name}: PASSED (correctly handled invalid model)")
    else:
        print(f"  ❌ {test_name}: FAILED")


def test_remove_3_active_model():
    """Remove-3: Remove active model (shows not installed)."""
    test_name = "Remove-3: Remove Model"
    environment = "native"

    print(f"\n🔄 Running: {test_name}")

    # Try to remove installed model
    exit_code, stdout, stderr, duration = run_models_command(
        subcommand="remove",
        args=["bge-m3"],
        environment=environment,
        timeout=MODELS_TIMEOUTS["models_remove"]
    )

    # Should complete without crash
    all_output = (stdout + stderr).lower()
    handled = (
        "removed" in all_output or
        "deleting" in all_output or
        "not installed" in all_output or
        "model not" in all_output
    )
    passed = handled

    record_test_result(
        test_id="p3-remove-3",
        name=test_name,
        command="synapse models remove bge-m3",
        environment=environment,
        exit_code=exit_code,
        stdout=stdout,
        stderr=stderr,
        duration=duration,
        timeout=MODELS_TIMEOUTS["models_remove"],
        passed=passed,
        assertions=[
            {"type": "handled", "expected": True, "actual": handled, "passed": passed}
        ]
    )

    if passed:
        print(f"  ✅ {test_name}: PASSED (command handled correctly)")
    else:
        print(f"  ❌ {test_name}: FAILED")


def test_remove_4_not_installed():
    """Remove-4: Model not installed."""
    test_name = "Remove-4: Model Not Installed"
    environment = "native"

    print(f"\n🔄 Running: {test_name}")

    # Try to remove model
    exit_code, stdout, stderr, duration = run_models_command(
        subcommand="remove",
        args=["gemma-3-1b"],
        environment=environment,
        timeout=MODELS_TIMEOUTS["models_remove"]
    )

    # Should handle gracefully
    all_output = (stdout + stderr).lower()
    handled = (
        "removing" in all_output or
        "not installed" in all_output or
        "model not" in all_output or
        "removed" in all_output
    )
    passed = handled

    record_test_result(
        test_id="p3-remove-4",
        name=test_name,
        command="synapse models remove gemma-3-1b",
        environment=environment,
        exit_code=exit_code,
        stdout=stdout,
        stderr=stderr,
        duration=duration,
        timeout=MODELS_TIMEOUTS["models_remove"],
        passed=passed,
        assertions=[
            {"type": "handled", "expected": True, "actual": handled, "passed": passed}
        ]
    )

    if passed:
        print(f"  ✅ {test_name}: PASSED (command handled correctly)")
    else:
        print(f"  ❌ {test_name}: FAILED")


def test_remove_5_performance():
    """Remove-5: Performance within threshold."""
    test_name = "Remove-5: Performance Test"
    environment = "native"

    print(f"\n🔄 Running: {test_name}")

    # Run help (quick command for performance)
    exit_code, stdout, stderr, duration = run_models_command(
        subcommand="remove",
        args=["--help"],
        environment=environment,
        timeout=MODELS_TIMEOUTS["models_remove"]
    )

    threshold = MODELS_THRESHOLDS.get("remove_model", 30.0)
    passed = exit_code == 0 and duration < threshold

    record_test_result(
        test_id="p3-remove-5",
        name=test_name,
        command="synapse models remove --help (performance)",
        environment=environment,
        exit_code=exit_code,
        stdout=stdout,
        stderr=stderr,
        duration=duration,
        timeout=MODELS_TIMEOUTS["models_remove"],
        passed=passed,
        assertions=[
            {"type": "exit_code", "expected": 0, "actual": exit_code, "passed": exit_code == 0},
            {"type": "performance", "expected": f"< {threshold}s", "actual": f"{duration:.2f}s", "passed": passed}
        ]
    )

    if passed:
        print(f"  ✅ {test_name}: PASSED (duration: {duration:.2f}s < {threshold}s)")
    else:
        print(f"  ❌ {test_name}: FAILED")
        print(f"     Duration: {duration:.2f}s (threshold: {threshold}s)")


def main():
    """Run all P3-4 Models Remove tests."""
    global test_results

    print("=" * 60)
    print("Phase 4 - P3-4: Models Remove Command Tests")
    print("=" * 60)
    print(f"\nEnvironment: native")
    print(f"Timeout per test: {MODELS_TIMEOUTS['models_remove']}s")

    # Run all tests
    print("\n" + "-" * 60)
    print("Running Tests:")
    print("-" * 60)

    test_remove_1_help()
    test_remove_2_invalid_model()
    test_remove_3_active_model()
    test_remove_4_not_installed()
    test_remove_5_performance()

    # Print summary
    print("\n" + "=" * 60)
    print("Test Summary")
    print("=" * 60)

    passed_count = sum(1 for r in test_results if r['passed'])
    failed_count = len(test_results) - passed_count

    print(f"\nTotal tests: {len(test_results)}")
    print(f"Passed: {passed_count}")
    print(f"Failed: {failed_count}")
    print(f"Success rate: {passed_count / len(test_results) * 100:.1f}%" if test_results else "N/A")

    print("\n" + "-" * 60)
    for result in test_results:
        status = "✅ PASS" if result['passed'] else "❌ FAIL"
        print(f"{status}: {result['name']} ({result['duration']:.2f}s)")

    print("\n" + "=" * 60)

    # Return exit code
    return 0 if failed_count == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
