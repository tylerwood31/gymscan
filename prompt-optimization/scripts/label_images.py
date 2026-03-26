#!/usr/bin/env python3
"""
Label gym images using Claude Vision API to generate initial ground truth.
Uses claude-sonnet-4-20250514 for cost efficiency.

Usage: python scripts/label_images.py
"""

import anthropic
import base64
import json
import os
import sys
import time
from pathlib import Path
from tqdm import tqdm

# Paths
BASE_DIR = Path(__file__).resolve().parent.parent
IMAGES_DIR = BASE_DIR / "dataset" / "images"
LABELS_PATH = BASE_DIR / "dataset" / "labels.json"
MANIFEST_PATH = BASE_DIR / "dataset" / "image_manifest.json"

# Valid equipment types enum
EQUIPMENT_TYPES = [
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
]

LABELING_PROMPT = """You are labeling gym equipment in this image for a machine learning dataset.

Identify every piece of exercise equipment visible. Be thorough and precise.

For each piece of equipment, return:
- type: must be one of: {types}
- details: describe what you see (weight range, brand, condition, adjustability)
- count: integer, how many distinct units of this equipment type are visible

Rules:
- A dumbbell rack counts as 1 "dumbbell" entry with details about the range
- Count individual machines (3 treadmills = count: 3)
- Include small items: yoga mats, foam rollers, medicine balls, resistance bands
- Ignore non-equipment: TVs, water fountains, towels, mirrors, clocks
- Be conservative: only report what you can clearly see or reasonably identify
- If an item is partially visible but identifiable, include it

Return ONLY a JSON array. No markdown formatting, no code blocks, no explanation. Example:
[{{"type": "dumbbell", "details": "rack with 5-50 lb pairs", "count": 1}}, {{"type": "treadmill", "details": "commercial, Life Fitness brand", "count": 2}}]""".format(
    types=", ".join(EQUIPMENT_TYPES)
)


def encode_image(image_path: Path) -> tuple[str, str]:
    """Read and base64 encode an image file. Returns (data, media_type)."""
    data = image_path.read_bytes()
    b64 = base64.standard_b64encode(data).decode("utf-8")

    suffix = image_path.suffix.lower()
    media_type_map = {
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".png": "image/png",
        ".gif": "image/gif",
        ".webp": "image/webp",
    }
    media_type = media_type_map.get(suffix, "image/jpeg")
    return b64, media_type


def label_single_image(client: anthropic.Anthropic, image_path: Path) -> list[dict]:
    """Send a single image to Claude Vision and get equipment labels."""
    b64_data, media_type = encode_image(image_path)

    message = client.messages.create(
        model="claude-sonnet-4-20250514",
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
                    {
                        "type": "text",
                        "text": LABELING_PROMPT,
                    },
                ],
            }
        ],
    )

    response_text = message.content[0].text.strip()

    # Strip markdown code block if present
    if response_text.startswith("```"):
        lines = response_text.split("\n")
        # Remove first and last lines (```json and ```)
        lines = [l for l in lines if not l.strip().startswith("```")]
        response_text = "\n".join(lines)

    try:
        equipment = json.loads(response_text)
        if not isinstance(equipment, list):
            print(f"  Warning: response is not a list, wrapping: {image_path.name}")
            equipment = [equipment] if isinstance(equipment, dict) else []

        # Validate and clean
        cleaned = []
        for item in equipment:
            eq_type = item.get("type", "").lower().strip()
            if eq_type not in EQUIPMENT_TYPES:
                # Try fuzzy match
                for valid in EQUIPMENT_TYPES:
                    if eq_type in valid or valid in eq_type:
                        eq_type = valid
                        break
                else:
                    print(f"  Warning: unknown type '{eq_type}' in {image_path.name}, skipping")
                    continue

            cleaned.append({
                "type": eq_type,
                "details": str(item.get("details", "")),
                "count": int(item.get("count", 1)),
            })

        return cleaned

    except json.JSONDecodeError as e:
        print(f"  Error parsing JSON for {image_path.name}: {e}")
        print(f"  Raw response: {response_text[:200]}")
        return []


def main():
    # Check API key
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("Error: ANTHROPIC_API_KEY environment variable not set")
        sys.exit(1)

    client = anthropic.Anthropic(api_key=api_key)

    # Load existing labels if any
    existing_labels = {}
    if LABELS_PATH.exists():
        existing_data = json.loads(LABELS_PATH.read_text())
        existing_labels = {item["image"]: item for item in existing_data}
        print(f"Loaded {len(existing_labels)} existing labels")

    # Load manifest for source info
    manifest_lookup = {}
    if MANIFEST_PATH.exists():
        manifest_data = json.loads(MANIFEST_PATH.read_text())
        manifest_lookup = {item["filename"]: item for item in manifest_data}

    # Find all images
    image_extensions = {".jpg", ".jpeg", ".png", ".webp"}
    image_files = sorted([
        f for f in IMAGES_DIR.iterdir()
        if f.suffix.lower() in image_extensions
    ])

    if not image_files:
        print(f"No images found in {IMAGES_DIR}")
        print("Run download_images.py first.")
        sys.exit(1)

    # Filter to unlabeled images (or images not yet reviewed)
    to_label = [
        f for f in image_files
        if f.name not in existing_labels
    ]

    print(f"\nFound {len(image_files)} total images")
    print(f"Already labeled: {len(existing_labels)}")
    print(f"To label: {len(to_label)}")

    if not to_label:
        print("All images already labeled. Delete labels.json to re-label.")
        return

    print(f"\nLabeling {len(to_label)} images with Claude Vision...")
    print(f"Estimated cost: ~${len(to_label) * 0.01:.2f}")
    print()

    labels = list(existing_labels.values())
    errors = 0

    for image_path in tqdm(to_label, desc="Labeling"):
        try:
            equipment = label_single_image(client, image_path)

            # Look up source info from manifest
            source_info = manifest_lookup.get(image_path.name, {})
            source = source_info.get("query", "unknown")

            label_entry = {
                "image": image_path.name,
                "source": source,
                "equipment": equipment,
                "labeled_by": "claude-vision-initial",
                "reviewed": False,
            }

            labels.append(label_entry)

            # Save after each image (in case of interruption)
            LABELS_PATH.write_text(json.dumps(labels, indent=2))

            # Rate limiting: ~1 request per second
            time.sleep(1.0)

        except anthropic.RateLimitError:
            print(f"\nRate limited. Waiting 30 seconds...")
            time.sleep(30)
            # Retry this image
            try:
                equipment = label_single_image(client, image_path)
                source_info = manifest_lookup.get(image_path.name, {})
                label_entry = {
                    "image": image_path.name,
                    "source": source_info.get("query", "unknown"),
                    "equipment": equipment,
                    "labeled_by": "claude-vision-initial",
                    "reviewed": False,
                }
                labels.append(label_entry)
                LABELS_PATH.write_text(json.dumps(labels, indent=2))
            except Exception as e2:
                print(f"  Retry failed for {image_path.name}: {e2}")
                errors += 1

        except Exception as e:
            print(f"\nError labeling {image_path.name}: {e}")
            errors += 1

    # Final save
    LABELS_PATH.write_text(json.dumps(labels, indent=2))

    print(f"\n{'=' * 60}")
    print(f"Labeling complete!")
    print(f"  Total labeled: {len(labels)}")
    print(f"  Errors: {errors}")
    print(f"  Labels saved: {LABELS_PATH}")
    print(f"{'=' * 60}")

    # Summary stats
    all_equipment = []
    for label in labels:
        for eq in label.get("equipment", []):
            all_equipment.append(eq["type"])

    from collections import Counter
    counts = Counter(all_equipment)
    print(f"\nEquipment type distribution:")
    for eq_type, count in counts.most_common(15):
        print(f"  {eq_type}: {count}")


if __name__ == "__main__":
    main()
