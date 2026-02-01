#!/usr/bin/env python3
"""
Phase 3 Completion Test Suite

Tests Phase 3 Model Bundling & Management and Phase 3b integration.
"""

import subprocess
import sys


def run_test(name, args):
    """Run a test and check result."""
    print(f"\n{'='*60}")
    print(f"TEST: {name}")
    print(f"{'='*60}")

    cmd = ["python3", "-m", "synapse.cli.main"] + args

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=10
        )

        success = result.returncode == 0
        if success:
            print(f"✓ PASS - Exit code: {result.returncode}")
        else:
            print(f"✗ FAIL - Exit code: {result.returncode}")
            print(f"stderr: {result.stderr[:200]}")

        return success
    except subprocess.TimeoutExpired:
        print(f"⏱ TIMEOUT")
        return False
    except Exception as e:
        print(f"✗ ERROR: {e}")
        return False


def main():
    """Run all tests."""
    print("╔" + "═" * 58 + "╗")
    print("║  SYNAPSE Phase 3 Completion Test Suite        ║")
    print("╚" + "═" * 58 + "╝")

    tests = [
        # Phase 3 tests
        ("Models list command", ["models", "list"]),
        ("Models verify command", ["models", "verify"]),
        ("Models download help", ["models", "download", "--help"]),
        ("Models remove help", ["models", "remove", "--help"]),
        ("Models subcommand help", ["models", "--help"]),

        # Phase 3 integration tests
        ("Setup command help", ["setup", "--help"]),
        ("Setup --no-model-check", ["setup", "--no-model-check", "--offline"]),
        ("Setup with offline", ["setup", "--offline"]),
        ("Onboard command help", ["onboard", "--help"]),
        ("Onboard --quick --offline", ["onboard", "--quick", "--offline", "--skip-test", "--skip-ingest"]),
    ]

    results = []
    for test_name, args in tests:
        result = run_test(test_name, args)
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
