#!/usr/bin/env python3
"""
Karpathy-style prompt optimization for GymScan equipment detection.

Iteratively refines the prompt by:
1. Evaluating current prompt against labeled dataset
2. Analyzing worst failures
3. Using Claude to generate an improved prompt
4. Evaluating the new prompt
5. Keeping the better version
6. Repeating for N rounds

Usage:
    python scripts/optimize.py                    # 5 rounds, start from latest
    python scripts/optimize.py --rounds 10        # 10 rounds
    python scripts/optimize.py --start-from v1    # start from specific version
    python scripts/optimize.py --quick            # eval on 20 images per round (faster)
"""

import anthropic
import argparse
import json
import os
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Optional

# Add parent to path so we can import eval_loop
sys.path.insert(0, str(Path(__file__).resolve().parent))
from eval_loop import evaluate_prompt, print_results, save_results, EvalResults, EQUIPMENT_TYPES

# Paths
BASE_DIR = Path(__file__).resolve().parent.parent
PROMPTS_DIR = BASE_DIR / "prompts"
RESULTS_DIR = BASE_DIR / "results"
HISTORY_PATH = RESULTS_DIR / "optimization_history.json"

# The meta-prompt for generating improved prompts
REFINEMENT_PROMPT = """You are an expert at prompt engineering for computer vision tasks. Your job is to improve a prompt that instructs an AI to detect gym equipment from photos.

## Current Prompt
{current_prompt}

## Current Performance
- Precision: {precision:.1%} (what % of detected items are actually in the image)
- Recall: {recall:.1%} (what % of actual items were detected)
- F1 Score: {f1:.1%}
- Count Accuracy: {count_accuracy:.1%}

## Failure Analysis

### Most Common False Positives (AI detected but not actually present):
{false_positives}

### Most Common False Negatives (Actually present but AI missed):
{false_negatives}

### Worst Performing Images:
{worst_failures}

### Count Errors (wrong quantity):
{count_errors}

## Valid Equipment Types
{equipment_types}

## Your Task

Analyze the failure patterns and write an improved version of the prompt that:
1. Fixes the most common false positive patterns (add rules to prevent hallucination of those types)
2. Fixes the most common false negative patterns (add hints to look for those types)
3. Improves count accuracy where it's off
4. Maintains or improves performance on types that are already working well
5. Keeps the same output format: JSON array with "type", "details", "count", "confidence" keys

Important constraints:
- The prompt will be sent alongside a single gym photo to Claude Vision
- Output must be a raw JSON array (no markdown, no code blocks, no explanation)
- The equipment type must be from the enum list provided
- Be specific about common confusion cases (e.g., bench types, cable vs functional trainer)
- Don't make the prompt excessively long -- aim for clear, actionable instructions

Return ONLY the improved prompt text. No explanation, no comparison, no meta-commentary. Just the prompt itself."""


def get_latest_version() -> int:
    """Find the highest version number in the prompts directory."""
    max_v = 0
    for f in PROMPTS_DIR.glob("v*.txt"):
        try:
            v = int(f.stem[1:])
            max_v = max(max_v, v)
        except ValueError:
            continue
    return max_v


def load_prompt(version: int) -> str:
    """Load a prompt by version number."""
    path = PROMPTS_DIR / f"v{version}.txt"
    if not path.exists():
        raise FileNotFoundError(f"Prompt not found: {path}")
    return path.read_text().strip()


def save_prompt(version: int, text: str) -> Path:
    """Save a prompt with version number."""
    PROMPTS_DIR.mkdir(parents=True, exist_ok=True)
    path = PROMPTS_DIR / f"v{version}.txt"
    path.write_text(text)
    return path


def analyze_failures(results: EvalResults) -> dict:
    """Extract failure patterns from evaluation results."""
    from collections import Counter

    all_fp = []
    all_fn = []
    all_count_errors = []

    for s in results.image_scores:
        all_fp.extend(s.false_positives)
        all_fn.extend(s.false_negatives)
        all_count_errors.extend(s.count_errors)

    fp_counts = Counter(all_fp).most_common(10)
    fn_counts = Counter(all_fn).most_common(10)

    # Format worst failures
    worst = results.worst_failures[:8]
    worst_details = []
    for s in worst:
        detail = f"- {s.image} (F1={s.f1:.2f})"
        if s.false_positives:
            detail += f"\n  Hallucinated: {', '.join(s.false_positives)}"
        if s.false_negatives:
            detail += f"\n  Missed: {', '.join(s.false_negatives)}"
        if s.count_errors:
            for ce in s.count_errors:
                detail += f"\n  Count wrong: {ce['type']} (said {ce['predicted_count']}, actual {ce['actual_count']})"
        worst_details.append(detail)

    # Format count errors
    count_error_summary = []
    type_errors = {}
    for ce in all_count_errors:
        t = ce["type"]
        if t not in type_errors:
            type_errors[t] = {"over": 0, "under": 0}
        if ce["predicted_count"] > ce["actual_count"]:
            type_errors[t]["over"] += 1
        else:
            type_errors[t]["under"] += 1

    for t, errs in sorted(type_errors.items(), key=lambda x: sum(x[1].values()), reverse=True):
        count_error_summary.append(f"- {t}: overcounted {errs['over']}x, undercounted {errs['under']}x")

    return {
        "false_positives": "\n".join(f"- {t}: {c} times" for t, c in fp_counts) or "None",
        "false_negatives": "\n".join(f"- {t}: {c} times" for t, c in fn_counts) or "None",
        "worst_failures": "\n".join(worst_details) or "None",
        "count_errors": "\n".join(count_error_summary) or "None",
    }


def generate_improved_prompt(
    client: anthropic.Anthropic,
    current_prompt: str,
    results: EvalResults,
) -> str:
    """Use Claude to generate an improved prompt based on failure analysis."""

    failures = analyze_failures(results)

    meta_prompt = REFINEMENT_PROMPT.format(
        current_prompt=current_prompt,
        precision=results.avg_precision,
        recall=results.avg_recall,
        f1=results.avg_f1,
        count_accuracy=results.avg_count_accuracy,
        false_positives=failures["false_positives"],
        false_negatives=failures["false_negatives"],
        worst_failures=failures["worst_failures"],
        count_errors=failures["count_errors"],
        equipment_types=", ".join(sorted(EQUIPMENT_TYPES)),
    )

    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=4000,
        messages=[{"role": "user", "content": meta_prompt}],
    )

    return message.content[0].text.strip()


def load_history() -> list[dict]:
    """Load optimization history."""
    if HISTORY_PATH.exists():
        return json.loads(HISTORY_PATH.read_text())
    return []


def save_history(history: list[dict]):
    """Save optimization history."""
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    HISTORY_PATH.write_text(json.dumps(history, indent=2))


def main():
    parser = argparse.ArgumentParser(description="Auto-optimize equipment detection prompt")
    parser.add_argument("--rounds", type=int, default=5,
                        help="Number of optimization rounds (default: 5)")
    parser.add_argument("--start-from", type=str, default=None,
                        help="Start from this prompt version (e.g., 'v1'). Default: latest.")
    parser.add_argument("--model", type=str, default="claude-sonnet-4-20250514",
                        help="Model for evaluation")
    parser.add_argument("--quick", action="store_true",
                        help="Quick mode: eval on 20 images per round")
    parser.add_argument("--target-f1", type=float, default=0.90,
                        help="Target F1 score to stop early (default: 0.90)")
    args = parser.parse_args()

    # Check API key
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("Error: ANTHROPIC_API_KEY environment variable not set")
        sys.exit(1)

    client = anthropic.Anthropic(api_key=api_key)

    max_images = 20 if args.quick else None

    # Determine starting version
    if args.start_from:
        start_version = int(args.start_from.replace("v", ""))
    else:
        start_version = get_latest_version()
        if start_version == 0:
            print("Error: No prompts found in prompts/ directory")
            sys.exit(1)

    current_version = start_version
    current_prompt = load_prompt(current_version)
    best_f1 = 0.0
    best_version = current_version

    # Load history
    history = load_history()

    print("=" * 60)
    print("GymScan Prompt Optimization")
    print("=" * 60)
    print(f"  Starting version: v{current_version}")
    print(f"  Rounds: {args.rounds}")
    print(f"  Target F1: {args.target_f1:.0%}")
    print(f"  Model: {args.model}")
    print(f"  Quick mode: {args.quick}")
    print()

    # Phase 1: Evaluate baseline
    print(f"\n--- Baseline Evaluation: v{current_version} ---")
    baseline_results = evaluate_prompt(
        prompt_text=current_prompt,
        prompt_version=f"v{current_version}",
        client=client,
        model=args.model,
        max_images=max_images,
    )
    print_results(baseline_results)
    save_results(baseline_results)

    best_f1 = baseline_results.avg_f1
    best_version = current_version

    history.append({
        "round": 0,
        "version": f"v{current_version}",
        "f1": baseline_results.avg_f1,
        "precision": baseline_results.avg_precision,
        "recall": baseline_results.avg_recall,
        "action": "baseline",
        "timestamp": datetime.now().isoformat(),
    })
    save_history(history)

    if best_f1 >= args.target_f1:
        print(f"\nBaseline already meets target! F1={best_f1:.1%} >= {args.target_f1:.0%}")
        print(f"Best prompt: v{best_version}")
        return

    # Phase 2: Optimization rounds
    current_results = baseline_results

    for round_num in range(1, args.rounds + 1):
        print(f"\n{'=' * 60}")
        print(f"OPTIMIZATION ROUND {round_num}/{args.rounds}")
        print(f"{'=' * 60}")
        print(f"Current best: v{best_version} (F1={best_f1:.1%})")

        # Generate improved prompt
        print(f"\nGenerating improved prompt from v{current_version} failures...")
        try:
            new_prompt = generate_improved_prompt(client, current_prompt, current_results)
        except Exception as e:
            print(f"Error generating prompt: {e}")
            continue

        new_version = get_latest_version() + 1
        prompt_path = save_prompt(new_version, new_prompt)
        print(f"Saved as v{new_version}: {prompt_path}")

        # Evaluate new prompt
        print(f"\nEvaluating v{new_version}...")
        new_results = evaluate_prompt(
            prompt_text=new_prompt,
            prompt_version=f"v{new_version}",
            client=client,
            model=args.model,
            max_images=max_images,
        )
        print_results(new_results)
        save_results(new_results)

        # Compare
        improved = new_results.avg_f1 > current_results.avg_f1
        delta = new_results.avg_f1 - current_results.avg_f1

        if improved:
            print(f"\n  IMPROVED! F1: {current_results.avg_f1:.1%} -> {new_results.avg_f1:.1%} (+{delta:.1%})")
            current_prompt = new_prompt
            current_version = new_version
            current_results = new_results

            if new_results.avg_f1 > best_f1:
                best_f1 = new_results.avg_f1
                best_version = new_version
        else:
            print(f"\n  No improvement. F1: {current_results.avg_f1:.1%} -> {new_results.avg_f1:.1%} ({delta:+.1%})")
            print(f"  Keeping v{current_version}, discarding v{new_version}")
            # Still use the new prompt as input for next round's failure analysis
            # to explore different directions (but keep tracking best)

        history.append({
            "round": round_num,
            "version": f"v{new_version}",
            "f1": new_results.avg_f1,
            "precision": new_results.avg_precision,
            "recall": new_results.avg_recall,
            "delta": delta,
            "improved": improved,
            "action": "accepted" if improved else "rejected",
            "timestamp": datetime.now().isoformat(),
        })
        save_history(history)

        # Early stopping
        if best_f1 >= args.target_f1:
            print(f"\nTarget reached! F1={best_f1:.1%} >= {args.target_f1:.0%}")
            break

        # If we've seen 3 rounds without improvement, try a different strategy
        recent = history[-3:]
        if len(recent) >= 3 and all(not h.get("improved", True) for h in recent):
            print(f"\n3 rounds without improvement. Resetting to best (v{best_version}).")
            current_prompt = load_prompt(best_version)
            current_version = best_version
            current_results = evaluate_prompt(
                prompt_text=current_prompt,
                prompt_version=f"v{best_version}",
                client=client,
                model=args.model,
                max_images=max_images,
            )

    # Final summary
    print(f"\n{'=' * 60}")
    print(f"OPTIMIZATION COMPLETE")
    print(f"{'=' * 60}")
    print(f"\n  Best version: v{best_version}")
    print(f"  Best F1: {best_f1:.1%}")
    print(f"  Prompt file: {PROMPTS_DIR / f'v{best_version}.txt'}")
    print(f"  History: {HISTORY_PATH}")
    print()

    # Print improvement trajectory
    print(f"  Trajectory:")
    for h in history:
        marker = " *" if h.get("improved", False) or h.get("action") == "baseline" else ""
        print(f"    Round {h['round']:2d}: {h['version']} F1={h['f1']:.1%} [{h['action']}]{marker}")

    # Final recommendation
    if best_f1 >= args.target_f1:
        print(f"\n  Target of {args.target_f1:.0%} F1 ACHIEVED.")
        print(f"  Use prompts/v{best_version}.txt for production.")
    else:
        print(f"\n  Target of {args.target_f1:.0%} F1 not yet achieved (best: {best_f1:.1%}).")
        print(f"  Consider:")
        print(f"    - Running more rounds: --rounds 10")
        print(f"    - Adding more diverse images to the dataset")
        print(f"    - Manually reviewing labels.json for labeling errors")
        print(f"    - Trying claude-sonnet-4-20250514 for eval: --model claude-sonnet-4-20250514")


if __name__ == "__main__":
    main()
