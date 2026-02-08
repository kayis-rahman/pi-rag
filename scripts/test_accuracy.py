#!/usr/bin/env python3
"""Test extraction accuracy against known dataset."""
import json
import sys
sys.path.insert(0, '.')

from core.conversation_analyzer import ConversationAnalyzer

def test_fact_accuracy(dataset_path):
    """Test fact extraction accuracy."""
    analyzer = ConversationAnalyzer(
        model_manager=None,
        config={"extraction_mode": "heuristic"}
    )

    with open(dataset_path) as f:
        dataset = json.load(f)

    fact_examples = dataset["fact_examples"]

    print(f"Testing fact extraction accuracy ({len(fact_examples)} examples)...\n")

    true_positives = 0
    false_positives = 0
    false_negatives = 0
    correct_key_matches = 0

    for example in fact_examples:
        text = example["text"]
        facts = analyzer._extract_facts_heuristic(text)

        # Check if any fact was extracted
        if len(facts) > 0:
            # Check if correct key was extracted
            key_correct = any(
                fact["key"] == example["expected_key"]
                for fact in facts
            )

            if key_correct:
                true_positives += 1
                correct_key_matches += 1
                print(f"  ✓ '{text}' - Correct: {example['expected_key']}")
            else:
                false_positives += 1
                extracted_keys = [f["key"] for f in facts]
                print(f"  ✗ '{text}' - Wrong keys: {extracted_keys} (expected: {example['expected_key']})")
        else:
            false_negatives += 1
            print(f"  ✗ '{text}' - Missed: {example['expected_key']}")

    # Calculate metrics
    total_examples = len(fact_examples)
    precision = true_positives / (true_positives + false_positives) if (true_positives + false_positives) > 0 else 0
    recall = true_positives / total_examples if total_examples > 0 else 0

    print(f"\n{'='*60}")
    print(f"Fact Extraction Accuracy Results:")
    print(f"  Total examples: {total_examples}")
    print(f"  True Positives: {true_positives}")
    print(f"  False Positives: {false_positives}")
    print(f"  False Negatives: {false_negatives}")
    print(f"  Precision: {precision:.2%} (target: >75%)")
    print(f"  Recall: {recall:.2%}")
    print(f"  Status: {'✓ PASS' if precision > 0.75 else '✗ FAIL'}")
    print(f"{'='*60}\n")

    return precision > 0.75

def test_episode_accuracy(dataset_path):
    """Test episode extraction accuracy."""
    analyzer = ConversationAnalyzer(
        model_manager=None,
        config={"extraction_mode": "heuristic"}
    )

    with open(dataset_path) as f:
        dataset = json.load(f)

    episode_examples = dataset["episode_examples"]

    print(f"Testing episode extraction accuracy ({len(episode_examples)} examples)...\n")

    true_positives = 0
    false_positives = 0
    false_negatives = 0

    for example in episode_examples:
        text = example["text"]
        episodes = analyzer._extract_episodes_heuristic(text)

        # Check if any episode was extracted
        if len(episodes) > 0:
            # Check if correct type was extracted
            type_correct = any(
                ep["lesson_type"] == example["expected_type"]
                for ep in episodes
            )

            if type_correct:
                true_positives += 1
                print(f"  ✓ '{text}' - Correct: {example['expected_type']}")
            else:
                false_positives += 1
                extracted_types = [e["lesson_type"] for e in episodes]
                print(f"  ✗ '{text}' - Wrong types: {extracted_types} (expected: {example['expected_type']})")
        else:
            false_negatives += 1
            print(f"  ✗ '{text}' - Missed: {example['expected_type']}")

    # Calculate metrics
    total_examples = len(episode_examples)
    precision = true_positives / (true_positives + false_positives) if (true_positives + false_positives) > 0 else 0
    recall = true_positives / total_examples if total_examples > 0 else 0

    print(f"\n{'='*60}")
    print(f"Episode Extraction Accuracy Results:")
    print(f"  Total examples: {total_examples}")
    print(f"  True Positives: {true_positives}")
    print(f"  False Positives: {false_positives}")
    print(f"  False Negatives: {false_negatives}")
    print(f"  Precision: {precision:.2%} (target: >70%)")
    print(f"  Recall: {recall:.2%}")
    print(f"  Status: {'✓ PASS' if precision > 0.70 else '✗ FAIL'}")
    print(f"{'='*60}\n")

    return precision > 0.70

def test_non_matching_examples(dataset_path):
    """Test that non-matching examples are not extracted."""
    analyzer = ConversationAnalyzer(
        model_manager=None,
        config={"extraction_mode": "heuristic"}
    )

    with open(dataset_path) as f:
        dataset = json.load(f)

    non_matching = dataset["non_matching_examples"]

    print(f"Testing non-matching examples ({len(non_matching)} examples)...\n")

    all_correct = True

    for example in non_matching:
        text = example["text"]
        facts = analyzer._extract_facts_heuristic(text)
        episodes = analyzer._extract_episodes_heuristic(text)

        total_extractions = len(facts) + len(episodes)

        if total_extractions == 0:
            print(f"  ✓ '{text}' - Correctly not extracted")
        else:
            all_correct = False
            print(f"  ✗ '{text}' - Incorrectly extracted: {total_extractions} items")

    print(f"\n{'='*60}")
    print(f"Non-Matching Examples Test Results:")
    print(f"  Status: {'✓ ALL CORRECT' if all_correct else '✗ SOME FAILED'}")
    print(f"{'='*60}\n")

    return all_correct

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Test extraction accuracy")
    parser.add_argument("--dataset", type=str,
                       default="tests/fixtures/accuracy_test_dataset.json",
                       help="Path to accuracy test dataset")
    args = parser.parse_args()

    fact_pass = test_fact_accuracy(args.dataset)
    episode_pass = test_episode_accuracy(args.dataset)
    non_matching_pass = test_non_matching_examples(args.dataset)

    print(f"\nFinal Results:")
    print(f"  Fact extraction: {'✓ PASS' if fact_pass else '✗ FAIL'}")
    print(f"  Episode extraction: {'✓ PASS' if episode_pass else '✗ FAIL'}")
    print(f"  Non-matching: {'✓ PASS' if non_matching_pass else '✗ FAIL'}")

    all_pass = fact_pass and episode_pass and non_matching_pass
    print(f"\nOverall: {'✓ ALL TESTS PASSED' if all_pass else '✗ SOME TESTS FAILED'}")

    sys.exit(0 if all_pass else 1)
