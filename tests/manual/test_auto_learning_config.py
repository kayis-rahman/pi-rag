#!/usr/bin/env python3
"""
Quick test to verify auto-learning configuration and behavior.
"""
import json
import sys
from pathlib import Path

# Add rag module to path
sys.path.insert(0, str(Path(__file__).parent))

from rag.auto_learning_tracker import AutoLearningTracker

# Load config
config_path = Path("configs/rag_config.json")
with open(config_path, 'r') as f:
    config = json.load(f)

auto_config = config.get("automatic_learning", {})

print("=" * 60)
print("AUTO-LEARNING CONFIGURATION TEST")
print("=" * 60)
print(f"\nConfiguration file: {config_path}")
print(f"\nAuto-learning config:")
for key, value in auto_config.items():
    print(f"  {key}: {value}")

# Create tracker
print(f"\nInitializing AutoLearningTracker...")
tracker = AutoLearningTracker(
    config=auto_config,
    model_manager=None  # No model manager for this test
)

print(f"  enabled: {tracker.enabled}")
print(f"  mode: {tracker.mode}")
print(f"  track_tasks: {tracker.track_tasks}")
print(f"  track_code_changes: {tracker.track_code_changes}")

# Test should_auto_track
print(f"\nTesting should_auto_track():")

# Test 1: Disabled globally, no override
operation = {"tool_name": "rag.search", "arguments": {}}
should_track = tracker.should_auto_track(operation)
print(f"  Test 1 (enabled=False, no override): {should_track}  (expected: False)")
assert should_track is False, f"Expected False, got {should_track}"

# Test 2: Disabled globally, auto_learn=false
operation["arguments"]["auto_learn"] = False
should_track = tracker.should_auto_track(operation)
print(f"  Test 2 (enabled=False, auto_learn=False): {should_track}  (expected: False)")
assert should_track is False, f"Expected False, got {should_track}"

# Test 3: Enabled globally, no override
tracker.enabled = True  # Simulate enabled config
operation["arguments"] = {}
should_track = tracker.should_auto_track(operation)
print(f"  Test 3 (enabled=True, no override): {should_track}  (expected: True)")
assert should_track is True, f"Expected True, got {should_track}"

# Test 4: Enabled globally, auto_learn=false
operation["arguments"]["auto_learn"] = False
should_track = tracker.should_auto_track(operation)
print(f"  Test 4 (enabled=True, auto_learn=False): {should_track}  (expected: False)")
assert should_track is False, f"Expected False, got {should_track}"

# Test 5: Enabled globally, auto_learn=true
operation["arguments"]["auto_learn"] = True
should_track = tracker.should_auto_track(operation)
print(f"  Test 5 (enabled=True, auto_learn=True): {should_track}  (expected: True)")
assert should_track is True, f"Expected True, got {should_track}"

print("\n" + "=" * 60)
print("ALL TESTS PASSED!")
print("=" * 60)
