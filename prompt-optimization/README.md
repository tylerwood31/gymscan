# GymScan Prompt Optimization Pipeline

Automated system to tune the equipment detection prompt to 90%+ accuracy using the Karpathy method (eval, analyze failures, refine, repeat).

## Setup

```bash
cd /Users/tylerwood/gymscan/prompt-optimization
pip install -r requirements.txt
export ANTHROPIC_API_KEY="your-key-here"
```

## Pipeline Steps

### 1. Download images

Collects 50-100 hotel gym images via Apify Google Images Scraper + curated Unsplash/Pexels URLs.

```bash
python scripts/download_images.py
```

Images saved to `dataset/images/`, manifest to `dataset/image_manifest.json`.

### 2. Label images

Uses Claude Vision to generate initial equipment labels for each image.

```bash
python scripts/label_images.py
```

Labels saved to `dataset/labels.json`. Review and correct labels manually for better ground truth.

### 3. Run optimization

Evaluates the current prompt, analyzes failures, generates improved prompts, and repeats.

```bash
# Full run (5 rounds, all images)
python scripts/optimize.py

# Quick test (20 images per round, 3 rounds)
python scripts/optimize.py --quick --rounds 3

# Start from a specific version
python scripts/optimize.py --start-from v3

# Custom target
python scripts/optimize.py --target-f1 0.95
```

### Individual evaluation

Run eval on a specific prompt without optimization:

```bash
python scripts/eval_loop.py
python scripts/eval_loop.py --prompt prompts/v3.txt --verbose
python scripts/eval_loop.py --max-images 10  # quick test
```

## End-to-end run

```bash
python scripts/download_images.py && python scripts/label_images.py && python scripts/optimize.py
```

## Directory Structure

```
prompt-optimization/
  dataset/
    images/          # Downloaded gym photos
    labels.json      # Ground truth equipment labels
    image_manifest.json  # Image source metadata
  prompts/
    v1.txt           # Baseline prompt
    v2.txt, v3.txt   # Auto-generated improvements
  results/
    eval_v1_*.json   # Per-version evaluation results
    optimization_history.json  # Full optimization trajectory
  scripts/
    download_images.py   # Image collection
    label_images.py      # Claude Vision labeling
    eval_loop.py         # Evaluation harness
    optimize.py          # Auto-refinement loop
```

## Scoring

- **Precision**: What % of detected equipment types actually exist in the image
- **Recall**: What % of actual equipment types were detected
- **F1**: Harmonic mean of precision and recall
- **Count accuracy**: How close predicted counts are to actual counts
- **Partial credit**: Same-category matches (e.g., bench_flat vs bench_adjustable) get 0.5 credit

## Cost

Rough estimates per run:
- Labeling 50 images: ~$0.50
- One eval round (50 images): ~$0.50
- Full optimization (5 rounds): ~$3-5
- Prompt generation: ~$0.05 per round
