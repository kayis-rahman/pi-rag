#!/usr/bin/env python3
"""Phase 1 Simple Test: synapse setup"""

import subprocess

print("="*60)
print("Phase 1 Manual Test: synapse setup")
print("="*60)
print()

# Test 1: Run setup --no-model-check
print("--- Test 1: Run setup --no-model-check ---")
result = subprocess.run(
    ["python3", "-m", "synapse.cli.commands.setup", "run_setup", "--no-model-check"],
    capture_output=True,
    text=True,
    timeout=60
)
print(f"Exit code: {result.returncode}")
print(f"STDOUT:\n{result.stdout}")

if result.returncode == 0:
    print("✅ Test 1 PASSED")
    success_count = 1
else:
    print("❌ Test 1 FAILED")
    success_count = 0

# Test 2: Check /opt/synapse/data exists
print("\n--- Test 2: Check /opt/synapse/data ---")
import os
if os.path.exists("/opt/synapse/data"):
    print("✅ Test 2 PASSED")
    success_count += 1
else:
    print("❌ Test 2 FAILED")
    
# Test 3: Check /opt/synapse/data/models exists
print("\n--- Test 3: Check /opt/synapse/data/models ---")
if os.path.exists("/opt/synapse/data/models"):
    print("✅ Test 3 PASSED")
    success_count += 1
else:
    print("❌ Test 3 FAILED")

# Summary
print("\n" + "="*60)
print("Summary")
print("="*60)
print(f"Passed: {success_count}/3")
print(f"Success rate: {success_count/3*100:.0f}%")

if success_count >= 2:
    print("\n✅ Phase 1 PASSED - Core setup works")
else:
    print("\n❌ Phase 1 FAILED - Critical issues")

print()
