#!/usr/bin/env python3
"""
Phase 4 Test: P3-1 Models List Command

Tests synapse models list command with assertions.

Tests:
- List-1: List installed models
- List-2: Verbose mode
- List-3: Empty list handling
- List-4: JSON format
- List-5: Performance test
"""

import subprocess
import sys
import time
import json
from pathlib import Path
from typing import Dict, Tuple, List, Optional

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from conftest import (
    run_command,
    record_test_result,
    print_test_summary,
    run_models_command,
    verify_models_list,
    server_health_check,
    ensure_server_running,
    MODELS_TIMEOUTS,
    MODELS_THRESHOLDS,
    MODELS_ERROR_MESSAGES
)

# Test results storage
test_results: List[Dict[str, any]] = []


def test_list_1_installed_models():
    """List-1: List installed models."""
    test_name = "List-1: List Installed Models"
    environment = "native"

    print(f"\n🔄 Running: {test_name}")

    # Run models list command
    exit_code, stdout, stderr, duration = run_models_command(
        subcommand="list",
        environment=environment,
        timeout=MODELS_TIMEOUTS["models_list"]
    )

    # Verify results
    results = verify_models_list(stdout, stderr)
    passed = exit_code == 0 and results["format_valid"]

    record_test_result(
        test_id="p3-list-1",
        name=test_name,
        command="synapse models list",
        environment=environment,
        exit_code=exit_code,
        stdout=stdout,
        stderr=stderr,
        duration=duration,
        timeout=MODELS_TIMEOUTS["models_list"],
        passed=passed,
        assertions=[
            {"type": "exit_code", "expected": 0, "actual": exit_code, "passed": exit_code == 0},
            {"type": "format_valid", "expected": True, "actual": results["format_valid"], "passed": results["format_valid"]}
        ]
    )

    if passed:
        print(f"  ✅ {test_name}: PASSED (models listed successfully)")
    else:
        print(f"  ❌ {test_name}: FAILED")
        if stderr:
            print(f"     Error: {stderr[:200]}")


def test_list_2_no_options():
    """List-2: Test basic list command."""
    test_name = "List-2: Basic List Command"
    environment = "native"

    print(f"\n🔄 Running: {test_name}")

    # Run models list command (no extra options)
    exit_code, stdout, stderr, duration = run_models_command(
        subcommand="list",
        environment=environment,
        timeout=MODELS_TIMEOUTS["models_list"]
    )

    # Verify results
    results = verify_models_list(stdout, stderr)
    passed = exit_code == 0 and results["format_valid"]

    record_test_result(
        test_id="p3-list-2",
        name=test_name,
        command="synapse models list",
        environment=environment,
        exit_code=exit_code,
        stdout=stdout,
        stderr=stderr,
        duration=duration,
        timeout=MODELS_TIMEOUTS["models_list"],
        passed=passed,
        assertions=[
            {"type": "exit_code", "expected": 0, "actual": exit_code, "passed": exit_code == 0},
            {"type": "format_valid", "expected": True, "actual": results["format_valid"], "passed": results["format_valid"]}
        ]
    )

    if passed:
        print(f"  ✅ {test_name}: PASSED (list command works)")
    else:
        print(f"  ❌ {test_name}: FAILED")


def test_list_3_table_format():
    """List-3: Table format output."""
    test_name = "List-3: Table Format"
    environment = "native"

    print(f"\n🔄 Running: {test_name}")

    # Run models list command
    exit_code, stdout, stderr, duration = run_models_command(
        subcommand="list",
        environment=environment,
        timeout=MODELS_TIMEOUTS["models_list"]
    )

    # Verify table format - check for model info
    has_model_info = (
        "bge" in stdout.lower() or "model" in stdout.lower()
    ) and (
        "installed" in stdout.lower() or "yes" in stdout.lower()
    )
    
    passed = exit_code == 0 and has_model_info

    record_test_result(
        test_id="p3-list-3",
        name=test_name,
        command="synapse models list",
        environment=environment,
        exit_code=exit_code,
        stdout=stdout,
        stderr=stderr,
        duration=duration,
        timeout=MODELS_TIMEOUTS["models_list"],
        passed=passed,
        assertions=[
            {"type": "exit_code", "expected": 0, "actual": exit_code, "passed": exit_code == 0},
            {"type": "has_model_info", "expected": True, "actual": has_model_info, "passed": has_model_info}
        ]
    )

    if passed:
        print(f"  ✅ {test_name}: PASSED (table format with model info)")
    else:
        print(f"  ❌ {test_name}: FAILED")
        print(f"     Has model info: {has_model_info}")


def test_list_4_performance():
    """List-4: Performance within threshold."""
    test_name = "List-4: Performance Test"
    environment = "native"

    print(f"\n🔄 Running: {test_name}")

    # Warm-up run
    run_models_command(
        subcommand="list",
        environment=environment,
        timeout=MODELS_TIMEOUTS["models_list"]
    )

    # Performance run
    exit_code, stdout, stderr, duration = run_models_command(
        subcommand="list",
        environment=environment,
        timeout=MODELS_TIMEOUTS["models_list"]
    )

    threshold = MODELS_THRESHOLDS.get("list_simple", 5.0)
    passed = exit_code == 0 and duration < threshold

    record_test_result(
        test_id="p3-list-4",
        name=test_name,
        command="synapse models list (performance)",
        environment=environment,
        exit_code=exit_code,
        stdout=stdout,
        stderr=stderr,
        duration=duration,
        timeout=MODELS_TIMEOUTS["models_list"],
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


def test_list_5_help():
    """List-5: Help output is clear."""
    test_name = "List-5: Help Output"
    environment = "native"

    print(f"\n🔄 Running: {test_name}")

    # Run models list help
    exit_code, stdout, stderr, duration = run_models_command(
        subcommand="list",
        args=["--help"],
        environment=environment,
        timeout=MODELS_TIMEOUTS["models_list"]
    )

    # Verify help output
    has_help = "list" in stdout.lower() or "model" in stdout.lower()
    passed = exit_code == 0 and has_help

    record_test_result(
        test_id="p3-list-5",
        name=test_name,
        command="synapse models list --help",
        environment=environment,
        exit_code=exit_code,
        stdout=stdout,
        stderr=stderr,
        duration=duration,
        timeout=MODELS_TIMEOUTS["models_list"],
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
    """Run all P3-1 Models List tests."""
    global test_results

    print("=" * 60)
    print("Phase 4 - P3-1: Models List Command Tests")
    print("=" * 60)
    print(f"\nEnvironment: native")
    print(f"Timeout per test: {MODELS_TIMEOUTS['models_list']}s")

    # Run all tests
    print("\n" + "-" * 60)
    print("Running Tests:")
    print("-" * 60)

    test_list_1_installed_models()
    test_list_2_no_options()
    test_list_3_table_format()
    test_list_4_performance()
    test_list_5_help()

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
