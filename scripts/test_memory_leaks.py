#!/usr/bin/env python3
"""Test for memory leaks during repeated operations."""
import time
import sys
sys.path.insert(0, '.')

try:
    import tracemalloc
    TRACEMALLOC_AVAILABLE = True
except ImportError:
    TRACEMALLOC_AVAILABLE = False
    tracemalloc = None

from core.conversation_analyzer import ConversationAnalyzer

def test_memory_leaks(iterations=1000):
    """Test for memory leaks."""
    analyzer = ConversationAnalyzer(
        model_manager=None,
        config={"extraction_mode": "heuristic"}
    )

    test_text = "API endpoint is https://api.example.com/v1"

    print(f"Running {iterations} iterations...")

    # Start memory tracking if available
    if TRACEMALLOC_AVAILABLE:
        tracemalloc.start()
        snapshot1 = tracemalloc.take_snapshot()
    else:
        print("Note: tracemalloc not available, memory tracking skipped")
        snapshot1 = None

    # Run iterations
    for i in range(iterations):
        facts = analyzer._extract_facts_heuristic(test_text)
        episodes = analyzer._extract_episodes_heuristic(test_text)

        # Print progress every 100 iterations
        if (i + 1) % 100 == 0:
            print(f"  Progress: {i + 1}/{iterations}")

    # Take final snapshot
    if TRACEMALLOC_AVAILABLE:
        snapshot2 = tracemalloc.take_snapshot()

        # Compare memory usage
        top_stats = snapshot2.compare_to(snapshot1, 'lineno')

        print(f"\n{'='*60}")
        print(f"Memory Leak Test Results:")
        print(f"  Iterations: {iterations}")

        # Find largest memory blocks
        if top_stats:
            print(f"  Top 5 memory differences:")
            for stat in top_stats[:5]:
                print(f"    {stat}")

        # Check for significant memory growth (>10MB)
        total_growth = sum(stat.size_diff for stat in top_stats)
        growth_mb = total_growth / (1024 * 1024)

        print(f"  Total memory growth: {growth_mb:.2f}MB")

        if growth_mb > 10:
            print(f"  Status: ✗ FAIL (possible memory leak)")
            return False
        else:
            print(f"  Status: ✓ PASS (memory stable)")
            return True

        tracemalloc.stop()
    else:
        print(f"\n{'='*60}")
        print(f"Memory Leak Test Results:")
        print(f"  Iterations: {iterations}")
        print(f"  Status: ✓ N/A (tracemalloc unavailable)")
        return True

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Test for memory leaks")
    parser.add_argument("--iterations", type=int, default=1000,
                       help="Number of iterations (default: 1000)")
    args = parser.parse_args()

    success = test_memory_leaks(args.iterations)
    sys.exit(0 if success else 1)
