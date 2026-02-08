#!/usr/bin/env python3
"""Phase 1 Simple Test: sy setup with new naming convention"""

import subprocess
import sys

print("="*60)
print("Phase 1 Manual Test: sy setup (NEW sy NAMING)")
print("="*60)
print()

# Test 1: Run sy --help
print("--- Test 1: Run sy --help ---")
result = subprocess.run(
    [sys.executable, "-m", "synapse.cli.main", "--help"],
    capture_output=True,
    text=True,
    timeout=30
)
print(f"Exit code: {result.returncode}")
if "sy" in result.stdout or "SYNAPSE" in result.stdout:
    print("✅ Test 1 PASSED - sy help works")
    success_count = 1
else:
    print("❌ Test 1 FAILED")
    success_count = 0

# Test 2: Run sy config
print("\n--- Test 2: Run sy config ---")
result = subprocess.run(
    [sys.executable, "-m", "synapse.cli.main", "config"],
    capture_output=True,
    text=True,
    timeout=30
)
print(f"Exit code: {result.returncode}")
if result.returncode == 0 and "Configuration" in result.stdout:
    print("✅ Test 2 PASSED - sy config works")
    success_count += 1
else:
    print("❌ Test 2 FAILED")

# Test 3: Run sy status
print("\n--- Test 3: Run sy status ---")
result = subprocess.run(
    [sys.executable, "-m", "synapse.cli.main", "status"],
    capture_output=True,
    text=True,
    timeout=30
)
print(f"Exit code: {result.returncode}")
if result.returncode == 0 and "Status" in result.stdout:
    print("✅ Test 3 PASSED - sy status works")
    success_count += 1
else:
    print("❌ Test 3 FAILED")

# Test 4: Run sy models list
print("\n--- Test 4: Run sy models list ---")
result = subprocess.run(
    [sys.executable, "-m", "synapse.cli.main", "models", "list"],
    capture_output=True,
    text=True,
    timeout=30
)
print(f"Exit code: {result.returncode}")
if result.returncode == 0 and "Models" in result.stdout:
    print("✅ Test 4 PASSED - sy models list works")
    success_count += 1
else:
    print("❌ Test 4 FAILED")

# Test 5: Run sy setup --help
print("\n--- Test 5: Run sy setup --help ---")
result = subprocess.run(
    [sys.executable, "-m", "synapse.cli.main", "setup", "--help"],
    capture_output=True,
    text=True,
    timeout=30
)
print(f"Exit code: {result.returncode}")
if result.returncode == 0 and "offline" in result.stdout:
    print("✅ Test 5 PASSED - sy setup --help works")
    success_count += 1
else:
    print("❌ Test 5 FAILED")

# Test 6: Run sy onboard --help
print("\n--- Test 6: Run sy onboard --help ---")
result = subprocess.run(
    [sys.executable, "-m", "synapse.cli.main", "onboard", "--help"],
    capture_output=True,
    text=True,
    timeout=30
)
print(f"Exit code: {result.returncode}")
if result.returncode == 0 and "quick" in result.stdout.lower():
    print("✅ Test 6 PASSED - sy onboard --help works")
    success_count += 1
else:
    print("❌ Test 6 FAILED")

# Summary
print("\n" + "="*60)
print("Summary - sy Naming Convention Tests")
print("="*60)
print(f"Passed: {success_count}/6")
print(f"Success rate: {success_count/6*100:.0f}%")

if success_count >= 5:
    print("\n✅ Phase 1 PASSED - sy naming convention works")
else:
    print("\n⚠️  Phase 1 PARTIAL - Some sy commands need attention")

print()
