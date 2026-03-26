#!/usr/bin/env python3
"""
Evaluation harness for GymScan equipment detection prompts.
Compares Claude Vision output against ground truth labels.

Usage:
    python scripts/eval_loop.py                          # eval prompts/v1.txt
    python scripts/eval_loop.py --prompt prompts/v3.txt  # eval specific version
    python scripts/eval_loop.py --verbose                # show per-image details

Can also be imported and called from optimize.py.
"""

import anthropic
import argparse
import base64
import json
import os
import sys
import time
from dataclasses import dataclass, field, asdict
from datetime import datetime
from pathlib import Path
from typing import Optional
from tqdm import tqdm

# Paths
BASE_DIR = Path(__file__).resolve().parent.parent
IMAGES_DIR = BASE_DIR / "dataset" / "images"
LABELS_PATH = BASE_DIR / "dataset" / "labels.json"
PROMPTS_DIR = BASE_DIR / "prompts"
RESULTS_DIR = BASE_DIR / "results"

# Valid equipment types
EQUIPMENT_TYPES = {
    "dumbbell", "barbell", "cable_machine", "smith_machine",
    "bench_flat", "bench_incline", "bench_adjustable",
    "treadmill", "elliptical", "rowing_machine", "pull_up_bar",
    "resistance_bands", "kettlebell", "leg_press", "lat_pulldown",
    "pec_deck", "leg_curl", "leg_extension", "shoulder_press_machine",
    "chest_press_machine", "seated_row", "hack_squat",
    "preacher_curl_bench", "ab_bench", "hyperextension_bench",
    "battle_ropes", "trx_suspension", "medicine_ball", "stability_ball",
    "foam_roller", "yoga_mat", "stair_climber", "stationary_bike",
    "spin_bike", "functional_trainer",
}

# Equipment categories for semantic similarity scoring
EQUIPMENT_CATEGORIES = {
    "cardio": {"treadmill", "elliptical", "rowing_machine", "stair_climber", "stationary_bike", "spin_bike"},
    "bench": {"bench_flat", "bench_incline", "bench_adjustable", "preacher_curl_bench", "ab_bench", "hyperextension_bench"},
    "cable": {"cable_machine", "functional_trainer", "lat_pulldown"},
    "free_weight": {"dumbbell", "barbell", "kettlebell"},
    "machine": {"leg_press", "pec_deck", "leg_curl", "leg_extension", "shoulder_press_machine", "chest_press_machine", "seated_row", "hack_squat", "smith_machine"},
    "accessory": {"resistance_bands", "battle_ropes", "trx_suspension", "medicine_ball", "stability_ball", "foam_roller", "yoga_mat", "pull_up_bar"},
}


def get_category(eq_type: str) -> str:
    """Get the category for an equipment type."""
    for cat, types in EQUIPMENT_CATEGORIES.items():
        if eq_type in types:
            return cat
    return "unknown"


@dataclass
class ImageScore:
    """Score for a single image evaluation."""
    image: str
    precision: float = 0.0
    recall: float = 0.0
    f1: float = 0.0
    count_accuracy: float = 0.0
    true_positives: list = field(default_factory=list)
    false_positives: list = field(default_factory=list)
    false_negatives: list = field(default_factory=list)
    count_errors: list = field(default_factory=list)
    raw_response: str = ""
    error: str = ""


@dataclass
class EvalResults:
    """Aggregate evaluation results."""
    prompt_version: str
    timestamp: str
    num_images: int = 0
    avg_precision: float = 0.0
    avg_recall: float = 0.0
    avg_f1: float = 0.0
    avg_count_accuracy: float = 0.0
    image_scores: list = field(default_factory=list)
    worst_failures: list = field(default_factory=list)
    errors: int = 0

    def to_dict(self) -> dict:
        return {
            "prompt_version": self.prompt_version,
            "timestamp": self.timestamp,
            "num_images": self.num_images,
            "avg_precision": round(self.avg_precision, 4),
            "avg_recall": round(self.avg_recall, 4),
            "avg_f1": round(self.avg_f1, 4),
            "avg_count_accuracy": round(self.avg_count_accuracy, 4),
            "errors": self.errors,
            "image_scores": [
                {
                    "image": s.image,
                    "precision": round(s.precision, 4),
                    "recall": round(s.recall, 4),
                    "f1": round(s.f1, 4),
                    "count_accuracy": round(s.count_accuracy, 4),
                    "true_positives": s.true_positives,
                    "false_positives": s.false_positives,
                    "false_negatives": s.false_negatives,
                    "count_errors": s.count_errors,
                }
                for s in self.image_scores
            ],
            "worst_failures": [
                {
                    "image": s.image,
                    "f1": round(s.f1, 4),
                    "false_positives": s.false_positives,
                    "false_negatives": s.false_negatives,
                    "count_errors": s.count_errors,
                }
                for s in self.worst_failures
            ],
        }


def encode_image(image_path: Path) -> tuple[str, str]:
    """Read and base64 encode an image file."""
    data = image_path.read_bytes()
    b64 = base64.standard_b64encode(data).decode("utf-8")
    suffix = image_path.suffix.lower()
    media_type_map = {
        ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
        ".png": "image/png", ".gif": "image/gif", ".webp": "image/webp",
    }
    return b64, media_type_map.get(suffix, "image/jpeg")


def call_vision_api(
    client: anthropic.Anthropic,
    image_path: Path,
    prompt_text: str,
    model: str = "claude-sonnet-4-20250514",
) -> tuple[list[dict], str]:
    """Send image + prompt to Claude Vision, return parsed equipment list and raw response."""
    b64_data, media_type = encode_image(image_path)

    message = client.messages.create(
        model=model,
        max_tokens=2000,
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "type": "image",
                        "source": {
                            "type": "base64",
                            "media_type": media_type,
                            "data": b64_data,
                        },
                    },
                    {"type": "text", "text": prompt_text},
                ],
            }
        ],
    )

    raw = message.content[0].text.strip()

    # Strip markdown code blocks
    cleaned = raw
    if cleaned.startswith("```"):
        lines = cleaned.split("\n")
        lines = [l for l in lines if not l.strip().startswith("```")]
        cleaned = "\n".join(lines)

    try:
        equipment = json.loads(cleaned)
        if not isinstance(equipment, list):
            equipment = [equipment] if isinstance(equipment, dict) else []
        return equipment, raw
    except json.JSONDecodeError:
        return [], raw


def score_image(
    predicted: list[dict],
    ground_truth: list[dict],
) -> ImageScore:
    """Compare predicted equipment against ground truth for a single image."""
    score = ImageScore(image="")

    # Extract type sets
    gt_types = set()
    gt_counts = {}
    for item in ground_truth:
        t = item.get("type", "").lower().strip()
        if t in EQUIPMENT_TYPES:
            gt_types.add(t)
            gt_counts[t] = item.get("count", 1)

    pred_types = set()
    pred_counts = {}
    for item in predicted:
        t = item.get("type", "").lower().strip()
        if t in EQUIPMENT_TYPES:
            pred_types.add(t)
            pred_counts[t] = item.get("count", 1)

    # True positives: types in both predicted and ground truth
    tp = gt_types & pred_types
    fp = pred_types - gt_types
    fn = gt_types - pred_types

    # Allow partial credit for same-category matches
    # e.g., predicting bench_flat when ground truth is bench_adjustable
    remaining_fp = set()
    remaining_fn = set(fn)
    partial_tp = set()

    for fp_type in fp:
        fp_cat = get_category(fp_type)
        matched = False
        for fn_type in list(remaining_fn):
            fn_cat = get_category(fn_type)
            if fp_cat == fn_cat and fp_cat != "unknown":
                # Partial match: same category but wrong specific type
                partial_tp.add((fp_type, fn_type))
                remaining_fn.discard(fn_type)
                matched = True
                break
        if not matched:
            remaining_fp.add(fp_type)

    # Calculate precision and recall
    # Full matches count as 1.0, partial matches as 0.5
    tp_count = len(tp) + 0.5 * len(partial_tp)
    total_predicted = len(pred_types)
    total_actual = len(gt_types)

    score.precision = tp_count / total_predicted if total_predicted > 0 else 1.0
    score.recall = tp_count / total_actual if total_actual > 0 else 1.0

    if score.precision + score.recall > 0:
        score.f1 = 2 * (score.precision * score.recall) / (score.precision + score.recall)
    else:
        score.f1 = 0.0

    # Count accuracy for matched types
    count_scores = []
    for t in tp:
        gt_c = gt_counts.get(t, 1)
        pred_c = pred_counts.get(t, 1)
        if gt_c > 0:
            accuracy = 1.0 - abs(gt_c - pred_c) / max(gt_c, pred_c)
            count_scores.append(max(0.0, accuracy))
            if gt_c != pred_c:
                score.count_errors.append({
                    "type": t,
                    "predicted_count": pred_c,
                    "actual_count": gt_c,
                })

    score.count_accuracy = sum(count_scores) / len(count_scores) if count_scores else 1.0

    score.true_positives = sorted(tp)
    score.false_positives = sorted(remaining_fp)
    score.false_negatives = sorted(remaining_fn)

    return score


def evaluate_prompt(
    prompt_text: str,
    prompt_version: str = "unknown",
    client: Optional[anthropic.Anthropic] = None,
    model: str = "claude-sonnet-4-20250514",
    max_images: Optional[int] = None,
    verbose: bool = False,
) -> EvalResults:
    """Run full evaluation of a prompt against the labeled dataset."""

    if client is None:
        api_key = os.environ.get("ANTHROPIC_API_KEY")
        if not api_key:
            print("Error: ANTHROPIC_API_KEY not set")
            sys.exit(1)
        client = anthropic.Anthropic(api_key=api_key)

    # Load ground truth
    if not LABELS_PATH.exists():
        print(f"Error: Labels file not found at {LABELS_PATH}")
        print("Run label_images.py first.")
        sys.exit(1)

    labels = json.loads(LABELS_PATH.read_text())
    labels_lookup = {item["image"]: item for item in labels}

    # Find images that have labels
    image_files = []
    for label in labels:
        img_path = IMAGES_DIR / label["image"]
        if img_path.exists():
            image_files.append((img_path, label))

    if max_images:
        image_files = image_files[:max_images]

    if not image_files:
        print("No labeled images found")
        sys.exit(1)

    results = EvalResults(
        prompt_version=prompt_version,
        timestamp=datetime.now().isoformat(),
        num_images=len(image_files),
    )

    print(f"\nEvaluating prompt '{prompt_version}' on {len(image_files)} images...")
    print(f"Model: {model}")
    print()

    all_scores = []

    for img_path, label in tqdm(image_files, desc="Evaluating"):
        try:
            predicted, raw_response = call_vision_api(client, img_path, prompt_text, model)
            ground_truth = label.get("equipment", [])

            img_score = score_image(predicted, ground_truth)
            img_score.image = label["image"]
            img_score.raw_response = raw_response

            all_scores.append(img_score)

            if verbose:
                status = "OK" if img_score.f1 >= 0.8 else "POOR" if img_score.f1 >= 0.5 else "FAIL"
                print(f"  [{status}] {label['image']}: P={img_score.precision:.2f} R={img_score.recall:.2f} F1={img_score.f1:.2f}")
                if img_score.false_positives:
                    print(f"         FP: {img_score.false_positives}")
                if img_score.false_negatives:
                    print(f"         FN: {img_score.false_negatives}")

            # Rate limiting
            time.sleep(1.0)

        except anthropic.RateLimitError:
            print(f"\nRate limited, waiting 30s...")
            time.sleep(30)
            results.errors += 1

        except Exception as e:
            print(f"\nError evaluating {label['image']}: {e}")
            results.errors += 1

    # Calculate aggregates
    if all_scores:
        results.avg_precision = sum(s.precision for s in all_scores) / len(all_scores)
        results.avg_recall = sum(s.recall for s in all_scores) / len(all_scores)
        results.avg_f1 = sum(s.f1 for s in all_scores) / len(all_scores)
        results.avg_count_accuracy = sum(s.count_accuracy for s in all_scores) / len(all_scores)
        results.image_scores = all_scores

        # Get worst failures (bottom 20% by F1)
        sorted_scores = sorted(all_scores, key=lambda s: s.f1)
        n_worst = max(3, len(all_scores) // 5)
        results.worst_failures = sorted_scores[:n_worst]

    return results


def print_results(results: EvalResults):
    """Print a human-readable summary of evaluation results."""
    print(f"\n{'=' * 60}")
    print(f"EVALUATION RESULTS: {results.prompt_version}")
    print(f"{'=' * 60}")
    print(f"  Images evaluated: {results.num_images}")
    print(f"  Errors: {results.errors}")
    print()
    print(f"  AGGREGATE SCORES:")
    print(f"    Precision:      {results.avg_precision:.1%}")
    print(f"    Recall:         {results.avg_recall:.1%}")
    print(f"    F1 Score:       {results.avg_f1:.1%}")
    print(f"    Count Accuracy: {results.avg_count_accuracy:.1%}")
    print()

    # Score distribution
    if results.image_scores:
        f1s = [s.f1 for s in results.image_scores]
        bins = {"Perfect (1.0)": 0, "Good (0.8-1.0)": 0, "Fair (0.5-0.8)": 0, "Poor (<0.5)": 0}
        for f1 in f1s:
            if f1 >= 1.0:
                bins["Perfect (1.0)"] += 1
            elif f1 >= 0.8:
                bins["Good (0.8-1.0)"] += 1
            elif f1 >= 0.5:
                bins["Fair (0.5-0.8)"] += 1
            else:
                bins["Poor (<0.5)"] += 1

        print(f"  SCORE DISTRIBUTION:")
        for label, count in bins.items():
            bar = "#" * count
            print(f"    {label:20s} {count:3d} {bar}")
        print()

    # Worst failures
    if results.worst_failures:
        print(f"  WORST FAILURES:")
        for s in results.worst_failures[:5]:
            print(f"    {s.image}: F1={s.f1:.2f}")
            if s.false_positives:
                print(f"      False positives: {', '.join(s.false_positives)}")
            if s.false_negatives:
                print(f"      False negatives: {', '.join(s.false_negatives)}")
            if s.count_errors:
                for ce in s.count_errors:
                    print(f"      Count error: {ce['type']} predicted={ce['predicted_count']} actual={ce['actual_count']}")
        print()

    # Common false positives and negatives
    all_fp = []
    all_fn = []
    for s in results.image_scores:
        all_fp.extend(s.false_positives)
        all_fn.extend(s.false_negatives)

    if all_fp:
        from collections import Counter
        fp_counts = Counter(all_fp).most_common(5)
        print(f"  MOST COMMON FALSE POSITIVES:")
        for eq_type, count in fp_counts:
            print(f"    {eq_type}: {count}")
        print()

    if all_fn:
        from collections import Counter
        fn_counts = Counter(all_fn).most_common(5)
        print(f"  MOST COMMON FALSE NEGATIVES (missed equipment):")
        for eq_type, count in fn_counts:
            print(f"    {eq_type}: {count}")
        print()

    target = 0.90
    if results.avg_f1 >= target:
        print(f"  TARGET MET: F1 {results.avg_f1:.1%} >= {target:.0%}")
    else:
        gap = target - results.avg_f1
        print(f"  TARGET NOT MET: F1 {results.avg_f1:.1%} < {target:.0%} (gap: {gap:.1%})")


def save_results(results: EvalResults):
    """Save evaluation results to JSON."""
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"eval_{results.prompt_version}_{timestamp}.json"
    filepath = RESULTS_DIR / filename

    # Don't include raw_response in saved file (too large)
    data = results.to_dict()
    filepath.write_text(json.dumps(data, indent=2))
    print(f"  Results saved: {filepath}")
    return filepath


def main():
    parser = argparse.ArgumentParser(description="Evaluate equipment detection prompt")
    parser.add_argument("--prompt", type=str, default=None,
                        help="Path to prompt file (default: prompts/v1.txt)")
    parser.add_argument("--max-images", type=int, default=None,
                        help="Max images to evaluate (for quick testing)")
    parser.add_argument("--model", type=str, default="claude-sonnet-4-20250514",
                        help="Claude model to use")
    parser.add_argument("--verbose", action="store_true",
                        help="Show per-image scores")
    args = parser.parse_args()

    # Load prompt
    if args.prompt:
        prompt_path = Path(args.prompt)
        if not prompt_path.is_absolute():
            prompt_path = BASE_DIR / prompt_path
    else:
        prompt_path = PROMPTS_DIR / "v1.txt"

    if not prompt_path.exists():
        print(f"Error: Prompt file not found: {prompt_path}")
        sys.exit(1)

    prompt_text = prompt_path.read_text().strip()
    prompt_version = prompt_path.stem  # e.g., "v1"

    print(f"Prompt: {prompt_path}")
    print(f"Version: {prompt_version}")

    # Run evaluation
    results = evaluate_prompt(
        prompt_text=prompt_text,
        prompt_version=prompt_version,
        model=args.model,
        max_images=args.max_images,
        verbose=args.verbose,
    )

    # Print and save
    print_results(results)
    save_results(results)


if __name__ == "__main__":
    main()
