#!/usr/bin/env python3
"""Benchmark full conversation analysis."""
import asyncio
import time
import sys
sys.path.insert(0, '.')

from core.conversation_analyzer import ConversationAnalyzer

test_conversations = [
    {
        "user": "API endpoint is https://api.example.com/v1",
        "agent": "I've stored that fact for you."
    },
    {
        "user": "I found a workaround for the issue",
        "agent": "Good to know!"
    },
]

async def benchmark_conversation_analysis(iterations=100):
    """Benchmark conversation analysis."""
    analyzer = ConversationAnalyzer(
        model_manager=None,  # Heuristic only
        config={"extraction_mode": "heuristic"}
    )

    print(f"Benchmarking conversation analysis ({iterations} iterations)...")

    # Warm-up
    for conv in test_conversations * 5:
        await analyzer.analyze_conversation_async(
            user_message=conv["user"],
            agent_response=conv["agent"]
        )

    # Benchmark
    start_time = time.perf_counter()
    for _ in range(iterations):
        for conv in test_conversations:
            await analyzer.analyze_conversation_async(
                user_message=conv["user"],
                agent_response=conv["agent"]
            )
    end_time = time.perf_counter()

    elapsed = end_time - start_time
    avg_time_ms = (elapsed / (iterations * len(test_conversations))) * 1000

    print(f"\n{'='*60}")
    print(f"Conversation Analysis Benchmark Results:")
    print(f"  Iterations: {iterations}")
    print(f"  Conversations per iteration: {len(test_conversations)}")
    print(f"  Total operations: {iterations * len(test_conversations)}")
    print(f"  Total time: {elapsed:.3f}s")
    print(f"  Average: {avg_time_ms:.3f}ms")
    print(f"  Target: <50ms")
    print(f"  Status: {'✓ PASS' if avg_time_ms < 50 else '✗ FAIL'}")
    print(f"{'='*60}\n")

    return avg_time_ms < 50

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Benchmark conversation analysis")
    parser.add_argument("--iterations", type=int, default=100,
                       help="Number of iterations (default: 100)")
    args = parser.parse_args()

    success = asyncio.run(benchmark_conversation_analysis(args.iterations))
    sys.exit(0 if success else 1)
