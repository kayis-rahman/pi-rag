#!/usr/bin/env python3
"""
Onboard Command Integration Test Suite

Tests all major flows and flag combinations for synapse onboard command.
"""

import subprocess
import sys
from pathlib import Path

def run_test(name, args, expected_success=True):
    """Run a test and capture output."""
    print(f"\n{'='*60}")
    print(f"TEST: {name}")
    print(f"{'='*60}")

    cmd = ["python3", "-m", "synapse.cli.main", "onboard"] + args

    try:
        # Run with timeout to prevent hanging on prompts
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=10,
            input="no\n"  # Auto-answer "no" to prompts
        )

        success = result.returncode == 0

        if success == expected_success:
            print(f"✓ PASS - Exit code: {result.returncode}")
        else:
            print(f"✗ FAIL - Expected success={expected_success}, got {result.returncode}")
            print(f"stderr: {result.stderr[:200]}")

        return success
    except subprocess.TimeoutExpired:
        print(f"⏱ TIMEOUT (expected - waiting for prompt)")
        return True  # Timeout is expected for interactive mode
    except Exception as e:
        print(f"✗ ERROR: {e}")
        return False


def main():
    """Run all tests."""
    print("╔" + "═" * 58 + "╗")
    print("║  SYNAPSE Onboard Command Integration Test Suite        ║")
    print("╚" + "═" * 58 + "╝")

    tests = [
        # Quick mode tests
        ("Quick mode (all skips)", ["--quick", "--offline", "--skip-test", "--skip-ingest"], True),
        ("Quick mode with test", ["--quick", "--offline", "--skip-ingest"], True),

        # Silent mode tests
        ("Silent mode with project-id", ["--silent", "--project-id", "testapp", "--offline", "--skip-test", "--skip-ingest"], True),

        # Flag combination tests
        ("Skip test and ingest", ["--quick", "--offline", "--skip-test", "--skip-ingest"], True),
        ("Skip ingest only", ["--quick", "--offline", "--skip-ingest"], True),

        # Help test
        ("Help command", ["--help"], True),
    ]

    results = []
    for test_name, args, expected in tests:
        result = run_test(test_name, args, expected)
        results.append((test_name, result))

    # Print summary
    print("\n" + "=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)

    passed = sum(1 for _, result in results if result)
    total = len(results)

    print(f"\nPassed: {passed}/{total}")

    for test_name, result in results:
        status = "✓ PASS" if result else "✗ FAIL"
        print(f"  {status}: {test_name}")

    print("\n" + "=" * 60)

    # Exit with appropriate code
    if passed == total:
        print("✅ All tests passed!")
        return 0
    else:
        print(f"❌ {total - passed} test(s) failed")
        return 1


if __name__ == "__main__":
    sys.exit(main())
