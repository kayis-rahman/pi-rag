#!/usr/bin/env python3
"""
Model Commands Test Suite

Tests model management commands without actually downloading models.
"""

import subprocess
import sys
from pathlib import Path


def run_test(name, args, check_output_contains=None):
    """Run a test and verify output."""
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

        if check_output_contains:
            contains = check_output_contains in result.stdout or check_output_contains in result.stderr
            if contains:
                print(f"✓ PASS - Output contains: {check_output_contains}")
            else:
                print(f"✗ FAIL - Output missing: {check_output_contains}")
                print(f"stdout: {result.stdout[:200]}")
                return False
        elif success:
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
    print("║  SYNAPSE Model Commands Test Suite              ║")
    print("╚" + "═" * 58 + "╝")

    tests = [
        # List models tests
        ("Models list command", ["models", "list"], "Available Models"),
        ("Models list table format", ["models", "list"], "Model Registry"),

        # Verify models tests
        ("Models verify command", ["models", "verify"], "Verifying Models"),

        # Download command tests (without actual download)
        ("Download command help", ["models", "download", "--help"], "MODEL_NAME"),
        ("Download unknown model", ["models", "download", "invalid"], "Unknown model"),

        # Remove command tests
        ("Remove command help", ["models", "remove", "--help"], "MODEL_NAME"),
        ("Remove unknown model", ["models", "remove", "invalid"], "Unknown model"),

        # Models subcommand help
        ("Models subcommand help", ["models", "--help"], "Model management"),
    ]

    results = []
    for test_name, args, check in tests:
        result = run_test(test_name, args, check_output_contains=check)
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
