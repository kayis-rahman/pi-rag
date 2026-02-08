#!/usr/bin/env python3
"""Benchmark heuristic extraction performance."""
import time
import sys
sys.path.insert(0, '.')

from core.conversation_analyzer import ConversationAnalyzer

# Sample text for testing
test_text = """
API endpoint is https://api.example.com/v1
The version is 1.3.0
I prefer Python over JavaScript
We decided to use FastAPI
I found a workaround for the issue
This didn't work, it was a mistake
The lesson is important
"""

def benchmark_heuristic_extraction(iterations=1000):
    """Benchmark heuristic extraction."""
    analyzer = ConversationAnalyzer(
        model_manager=None,
        config={"extraction_mode": "heuristic"}
    )

    print(f"Benchmarking heuristic extraction ({iterations} iterations)...")

    # Warm-up
    for _ in range(10):
        analyzer._extract_facts_heuristic(test_text)
        analyzer._extract_episodes_heuristic(test_text)

    # Benchmark
    start_time = time.perf_counter()
    for _ in range(iterations):
        facts = analyzer._extract_facts_heuristic(test_text)
        episodes = analyzer._extract_episodes_heuristic(test_text)
    end_time = time.perf_counter()

    elapsed = end_time - start_time
    avg_time_ms = (elapsed / iterations) * 1000

    print(f"\n{'='*60}")
    print(f"Heuristic Extraction Benchmark Results:")
    print(f"  Iterations: {iterations}")
    print(f"  Total time: {elapsed:.3f}s")
    print(f"  Average: {avg_time_ms:.3f}ms")
    print(f"  Target: <10ms")
    print(f"  Status: {'✓ PASS' if avg_time_ms < 10 else '✗ FAIL'}")
    print(f"{'='*60}\n")

    return avg_time_ms < 10

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Benchmark heuristic extraction")
    parser.add_argument("--iterations", type=int, default=1000,
                       help="Number of iterations (default: 1000)")
    args = parser.parse_args()

    success = benchmark_heuristic_extraction(args.iterations)
    sys.exit(0 if success else 1)
