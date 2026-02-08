#!/usr/bin/env python3
"""
Phase 4 Test: P3-3 Models Verify Command

Tests synapse models verify command with assertions.

Tests:
- Verify-1: Verify installed model
- Verify-2: Verify with model name
- Verify-3: Verify invalid model
- Verify-4: Help output
- Verify-5: Performance test
"""

import subprocess
import sys
import time
from pathlib import Path
from typing import Dict, Tuple, List

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from conftest import (
    run_command,
    record_test_result,
    run_models_command,
    verify_models_verify,
    MODELS_TIMEOUTS,
    MODELS_THRESHOLDS
)

# Test results storage
test_results: List[Dict[str, any]] = []


def test_verify_1_installed_model():
    """Verify-1: Verify installed models."""
    test_name = "Verify-1: Verify Installed Models"
    environment = "native"

    print(f"\n🔄 Running: {test_name}")

    # Run models verify (no arguments - verifies all models)
    exit_code, stdout, stderr, duration = run_models_command(
        subcommand="verify",
        environment=environment,
        timeout=MODELS_TIMEOUTS["models_verify"]
    )

    # Verify results - should show model verification
    all_output = (stdout + stderr).lower()
    output_check = (
        "bge" in all_output or
        "model" in all_output or
        "gemma" in all_output or
        "verif" in all_output or
        "status" in all_output
    )
    passed = exit_code == 0 and output_check

    record_test_result(
        test_id="p3-verify-1",
        name=test_name,
        command="synapse models verify",
        environment=environment,
        exit_code=exit_code,
        stdout=stdout,
        stderr=stderr,
        duration=duration,
        timeout=MODELS_TIMEOUTS["models_verify"],
        passed=passed,
        assertions=[
            {"type": "exit_code", "expected": 0, "actual": exit_code, "passed": exit_code == 0},
            {"type": "has_output", "expected": True, "actual": output_check, "passed": output_check}
        ]
    )

    if passed:
        print(f"  ✅ {test_name}: PASSED (model verification completed)")
    else:
        print(f"  ❌ {test_name}: FAILED")
        if stderr:
            print(f"     Error: {stderr[:200]}")


def test_verify_2_performance():
    """Verify-2: Performance within threshold."""
    test_name = "Verify-2: Performance Test"
    environment = "native"

    print(f"\n🔄 Running: {test_name}")

    # Warm-up run
    run_models_command(
        subcommand="verify",
        environment=environment,
        timeout=MODELS_TIMEOUTS["models_verify"]
    )

    # Performance run
    exit_code, stdout, stderr, duration = run_models_command(
        subcommand="verify",
        environment=environment,
        timeout=MODELS_TIMEOUTS["models_verify"]
    )

    threshold = MODELS_THRESHOLDS.get("verify_model", 60.0)
    passed = exit_code == 0 and duration < threshold

    record_test_result(
        test_id="p3-verify-2",
        name=test_name,
        command="synapse models verify (performance)",
        environment=environment,
        exit_code=exit_code,
        stdout=stdout,
        stderr=stderr,
        duration=duration,
        timeout=MODELS_TIMEOUTS["models_verify"],
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


def test_verify_3_help():
    """Verify-3: Help output."""
    test_name = "Verify-3: Help Output"
    environment = "native"

    print(f"\n🔄 Running: {test_name}")

    # Run verify help
    exit_code, stdout, stderr, duration = run_models_command(
        subcommand="verify",
        args=["--help"],
        environment=environment,
        timeout=MODELS_TIMEOUTS["models_verify"]
    )

    # Verify help
    has_help = "verify" in stdout.lower() or "model" in stdout.lower()
    passed = exit_code == 0 and has_help

    record_test_result(
        test_id="p3-verify-3",
        name=test_name,
        command="synapse models verify --help",
        environment=environment,
        exit_code=exit_code,
        stdout=stdout,
        stderr=stderr,
        duration=duration,
        timeout=MODELS_TIMEOUTS["models_verify"],
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


def main():
    """Run all P3-3 Models Verify tests."""
    global test_results

    print("=" * 60)
    print("Phase 4 - P3-3: Models Verify Command Tests")
    print("=" * 60)
    print(f"\nEnvironment: native")
    print(f"Timeout per test: {MODELS_TIMEOUTS['models_verify']}s")

    # Run all tests
    print("\n" + "-" * 60)
    print("Running Tests:")
    print("-" * 60)

    test_verify_1_installed_model()
    test_verify_2_performance()
    test_verify_3_help()

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
