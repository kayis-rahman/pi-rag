#!/usr/bin/env python3
"""
Phase 2 Test: P1-1 sy start (Updated with sy naming convention)

Tests start command using Docker Compose and native modes.
All commands now use 'sy' prefix instead of 'python3 -m synapse.cli.main'
"""

import subprocess
import sys
import time
import signal
from pathlib import Path
from typing import Dict, Tuple, List, Optional

# Import shared utilities
sys.path.insert(0, str(Path(__file__).parent))
from conftest import (
    TIMEOUTS,
    check_docker_container,
    record_test_result,
    print_test_summary,
    print_success_rate
)


def run_command(
    command: List[str],
    timeout: int,
    check_exit_code: bool = True
) -> Tuple[int, str, str, float]:
    """
    Run command and return (exit_code, stdout, stderr, duration).
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


def run_sy_command(
    command: str,
    timeout: int = TIMEOUTS["default"],
    check_exit_code: bool = True
) -> Tuple[int, str, str, float]:
    """
    Run sy command using the new naming convention.
    Format: python3 -m synapse.cli.main <command>
    """
    cmd = [sys.executable, "-m", "synapse.cli.main"] + command.split()
    return run_command(cmd, timeout, check_exit_code)


# ============================================================================
# Test Cases (Updated with sy naming)
# ============================================================================

def test_sy_start_help():
    """P1-1.1: Test sy start --help"""
    record_test_result("P1-1.1", "sy start --help", "new")
    exit_code, stdout, stderr, duration = run_sy_command("start --help")
    success = exit_code == 0 and "start" in stdout.lower()
    record_test_result("P1-1.1", "sy start --help", "passed" if success else "failed")
    return success, duration


def test_sy_start_native():
    """P1-1.2: Test sy start (native mode)"""
    record_test_result("P1-1.2", "sy start", "new")
    exit_code, stdout, stderr, duration = run_sy_command("start", timeout=TIMEOUTS["start"])
    success = exit_code == 0 and "started" in stdout.lower()
    record_test_result("P1-1.2", "sy start", "passed" if success else "failed")
    return success, duration


def test_sy_start_port():
    """P1-1.3: Test sy start --port"""
    record_test_result("P1-1.3", "sy start --port", "new")
    exit_code, stdout, stderr, duration = run_sy_command("start --port 8080", timeout=TIMEOUTS["start"])
    success = exit_code == 0 and "8002" in stdout
    record_test_result("P1-1.3", "sy start --port", "passed" if success else "failed")
    return success, duration


def test_sy_start_docker():
    """P1-1.4: Test sy start --docker"""
    record_test_result("P1-1.4", "sy start --docker", "new")
    exit_code, stdout, stderr, duration = run_sy_command("start --docker", timeout=TIMEOUTS["docker"])
    success = exit_code == 0 and "docker" in stdout.lower()
    record_test_result("P1-1.4", "sy start --docker", "passed" if success else "failed")
    return success, duration


def test_sy_start_health():
    """P1-1.5: Test sy start and verify health"""
    record_test_result("P1-1.5", "sy start health check", "new")
    # First start the server
    exit_code, stdout, stderr, duration = run_sy_command("start", timeout=TIMEOUTS["start"])
    if exit_code != 0:
        record_test_result("P1-1.5", "sy start health check", "failed")
        return False, duration
    
    # Check health endpoint
    time.sleep(2)
    result = subprocess.run(
        ["curl", "-s", "http://localhost:8002/health"],
        capture_output=True,
        text=True,
        timeout=10
    )
    success = result.returncode == 0 and "ok" in result.stdout.lower()
    record_test_result("P1-1.5", "sy start health check", "passed" if success else "failed")
    return success, duration


# ============================================================================
# Main Test Runner (Updated with sy naming)
# ============================================================================

def main():
    """Run all P1-1 tests with sy naming convention"""
    
    print("="*70)
    print("Phase 2 Test: P1-1 sy start (Updated sy Naming Convention)")
    print("="*70)
    print()
    print("All commands now use 'sy' prefix: python3 -m synapse.cli.main <command>")
    print()
    
    tests = [
        ("sy start --help", test_sy_start_help),
        ("sy start (native)", test_sy_start_native),
        ("sy start --port", test_sy_start_port),
        ("sy start --docker", test_sy_start_docker),
        ("sy start health check", test_sy_start_health),
    ]
    
    total_time = 0
    passed = 0
    failed = 0
    
    for name, test_func in tests:
        print(f"\n--- Running: {name} ---")
        try:
            success, duration = test_func()
            total_time += duration
            if success:
                passed += 1
                print(f"✅ PASSED ({duration:.2f}s)")
            else:
                failed += 1
                print(f"❌ FAILED ({duration:.2f}s)")
        except Exception as e:
            failed += 1
            print(f"❌ ERROR: {e}")
    
    print()
    print("="*70)
    print("Test Summary - P1-1 sy start")
    print("="*70)
    print(f"Passed: {passed}/{len(tests)}")
    print(f"Failed: {failed}/{len(tests)}")
    print(f"Success Rate: {passed/len(tests)*100:.0f}%")
    print(f"Total Time: {total_time:.2f}s")
    
    print_test_summary("P1-1")
    print_success_rate("P1-1")
    
    return passed == len(tests)


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
