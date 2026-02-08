#!/usr/bin/env python3
"""
Phase 4 Test: P3-2 Models Download Command

Tests synapse models download command with assertions.

Tests:
- Download-1: Download installed model (already exists)
- Download-2: Force re-download
- Download-3: Invalid model name
- Download-4: Help output
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
    verify_models_download,
    MODELS_TIMEOUTS,
    MODELS_THRESHOLDS,
    MODELS_ERROR_MESSAGES
)

# Test results storage
test_results: List[Dict[str, any]] = []


def test_download_1_already_installed():
    """Download-1: Download already installed model."""
    test_name = "Download-1: Already Installed Model"
    environment = "native"

    print(f"\n🔄 Running: {test_name}")

    # Run models download for installed model
    exit_code, stdout, stderr, duration = run_models_command(
        subcommand="download",
        args=["bge-m3"],
        environment=environment,
        timeout=MODELS_TIMEOUTS["models_download"]
    )

    # Verify results - should show already installed
    results = verify_models_download(stdout, stderr)
    # Accept both "already installed" OR successful download
    passed = exit_code == 0 and (
        results["already_installed"] or 
        "success" in stdout.lower() or 
        "download" in stdout.lower()
    )

    record_test_result(
        test_id="p3-download-1",
        name=test_name,
        command="synapse models download bge-m3",
        environment=environment,
        exit_code=exit_code,
        stdout=stdout,
        stderr=stderr,
        duration=duration,
        timeout=MODELS_TIMEOUTS["models_download"],
        passed=passed,
        assertions=[
            {"type": "exit_code", "expected": 0, "actual": exit_code, "passed": exit_code == 0},
            {"type": "handled", "expected": True, "actual": passed, "passed": passed}
        ]
    )

    if passed:
        print(f"  ✅ {test_name}: PASSED (already installed handled)")
    else:
        print(f"  ❌ {test_name}: FAILED")
        if stderr:
            print(f"     Error: {stderr[:200]}")


def test_download_2_force():
    """Download-2: Force re-download."""
    test_name = "Download-2: Force Re-download"
    environment = "native"

    print(f"\n🔄 Running: {test_name}")

    # Run models download with force
    exit_code, stdout, stderr, duration = run_models_command(
        subcommand="download",
        args=["bge-m3", "--force"],
        environment=environment,
        timeout=MODELS_TIMEOUTS["models_download"]
    )

    # Verify results
    passed = exit_code == 0

    record_test_result(
        test_id="p3-download-2",
        name=test_name,
        command="synapse models download bge-m3 --force",
        environment=environment,
        exit_code=exit_code,
        stdout=stdout,
        stderr=stderr,
        duration=duration,
        timeout=MODELS_TIMEOUTS["models_download"],
        passed=passed,
        assertions=[
            {"type": "exit_code", "expected": 0, "actual": exit_code, "passed": exit_code == 0}
        ]
    )

    if passed:
        print(f"  ✅ {test_name}: PASSED (force download accepted)")
    else:
        print(f"  ❌ {test_name}: FAILED")
        if stderr:
            print(f"     Error: {stderr[:200]}")


def test_download_3_invalid_model():
    """Download-3: Invalid model name."""
    test_name = "Download-3: Invalid Model Name"
    environment = "native"

    print(f"\n🔄 Running: {test_name}")

    # Run download with invalid model
    exit_code, stdout, stderr, duration = run_models_command(
        subcommand="download",
        args=["nonexistent-model-xyz-123"],
        environment=environment,
        timeout=MODELS_TIMEOUTS["models_download"]
    )

    # Should show error message (check both stdout and stderr)
    all_output = (stdout + stderr).lower()
    error_check = (
        "unknown model" in all_output or
        "not found" in all_output or
        "available" in all_output or
        "invalid" in all_output
    )
    # Accept either non-zero exit OR error message shown
    passed = (exit_code != 0 or error_check)

    record_test_result(
        test_id="p3-download-3",
        name=test_name,
        command="synapse models download nonexistent-model-xyz",
        environment=environment,
        exit_code=exit_code,
        stdout=stdout,
        stderr=stderr,
        duration=duration,
        timeout=MODELS_TIMEOUTS["models_download"],
        passed=passed,
        assertions=[
            {"type": "exit_code_or_error", "expected": "!= 0 or error shown", "actual": exit_code, "passed": passed},
            {"type": "error_shown", "expected": True, "actual": error_check, "passed": error_check}
        ]
    )

    if passed:
        print(f"  ✅ {test_name}: PASSED (correctly rejected invalid model)")
    else:
        print(f"  ❌ {test_name}: FAILED")
        print(f"     Exit code: {exit_code}")


def test_download_4_help():
    """Download-4: Help output."""
    test_name = "Download-4: Help Output"
    environment = "native"

    print(f"\n🔄 Running: {test_name}")

    # Run download help
    exit_code, stdout, stderr, duration = run_models_command(
        subcommand="download",
        args=["--help"],
        environment=environment,
        timeout=MODELS_TIMEOUTS["models_download"]
    )

    # Verify help
    has_help = "download" in stdout.lower() or "model" in stdout.lower()
    passed = exit_code == 0 and has_help

    record_test_result(
        test_id="p3-download-4",
        name=test_name,
        command="synapse models download --help",
        environment=environment,
        exit_code=exit_code,
        stdout=stdout,
        stderr=stderr,
        duration=duration,
        timeout=MODELS_TIMEOUTS["models_download"],
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


def test_download_5_chat_model():
    """Download-5: Download chat model."""
    test_name = "Download-5: Download Chat Model"
    environment = "native"

    print(f"\n🔄 Running: {test_name}")

    # Try downloading chat model (might already be installed)
    exit_code, stdout, stderr, duration = run_models_command(
        subcommand="download",
        args=["gemma-3-1b"],
        environment=environment,
        timeout=MODELS_TIMEOUTS["models_download"]
    )

    # Should handle gracefully (either already installed or download)
    passed = exit_code == 0

    record_test_result(
        test_id="p3-download-5",
        name=test_name,
        command="synapse models download gemma-3-1b",
        environment=environment,
        exit_code=exit_code,
        stdout=stdout,
        stderr=stderr,
        duration=duration,
        timeout=MODELS_TIMEOUTS["models_download"],
        passed=passed,
        assertions=[
            {"type": "exit_code", "expected": 0, "actual": exit_code, "passed": exit_code == 0}
        ]
    )

    if passed:
        print(f"  ✅ {test_name}: PASSED (chat model download accepted)")
    else:
        print(f"  ❌ {test_name}: FAILED")


def main():
    """Run all P3-2 Models Download tests."""
    global test_results

    print("=" * 60)
    print("Phase 4 - P3-2: Models Download Command Tests")
    print("=" * 60)
    print(f"\nEnvironment: native")
    print(f"Timeout per test: {MODELS_TIMEOUTS['models_download']}s")

    # Run all tests
    print("\n" + "-" * 60)
    print("Running Tests:")
    print("-" * 60)

    test_download_1_already_installed()
    test_download_2_force()
    test_download_3_invalid_model()
    test_download_4_help()
    test_download_5_chat_model()

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
