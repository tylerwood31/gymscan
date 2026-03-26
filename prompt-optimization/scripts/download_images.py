#!/usr/bin/env python3
"""
Download hotel gym images using Apify Google Images Scraper.
Falls back to direct URL download if Apify fails.

Usage: python scripts/download_images.py
"""

import json
import os
import sys
import time
import hashlib
import requests
from pathlib import Path
from urllib.parse import urlparse

# Paths
BASE_DIR = Path(__file__).resolve().parent.parent
IMAGES_DIR = BASE_DIR / "dataset" / "images"
MANIFEST_PATH = BASE_DIR / "dataset" / "image_manifest.json"

# Apify config - set APIFY_TOKEN environment variable before running
APIFY_TOKEN = os.environ.get("APIFY_TOKEN", "")
ACTOR_ID = "hooli~google-images-scraper"

# Search queries designed to get diverse hotel gym photos
SEARCH_QUERIES = [
    "hotel gym equipment",
    "hotel fitness center",
    "marriott hotel gym",
    "hilton fitness center",
    "small hotel gym dumbbells",
    "hotel gym treadmill elliptical",
    "apartment gym fitness room",
    "cruise ship gym equipment",
    "hotel gym cable machine",
    "bad hotel gym",
    "luxury hotel gym",
    "hyatt hotel fitness center",
    "residence inn gym",
    "holiday inn express fitness center",
    "boutique hotel gym",
]

# Target images per query
IMAGES_PER_QUERY = 8
TARGET_TOTAL = 80


def run_apify_actor(query: str, max_items: int = 10) -> list[dict]:
    """Run the Apify Google Images Scraper for a single query."""
    run_input = {
        "queries": [query],
        "maxItems": max_items,
        "proxy": {"useApifyProxy": True},
    }

    print(f"  Starting Apify run for: '{query}'")

    # Start the actor run
    resp = requests.post(
        f"https://api.apify.com/v2/acts/{ACTOR_ID}/runs",
        params={"token": APIFY_TOKEN},
        json=run_input,
        timeout=30,
    )
    resp.raise_for_status()
    run_data = resp.json()["data"]
    run_id = run_data["id"]
    dataset_id = run_data["defaultDatasetId"]

    print(f"  Run started: {run_id}, waiting for completion...")

    # Poll for completion
    for attempt in range(60):  # max 5 min
        time.sleep(5)
        status_resp = requests.get(
            f"https://api.apify.com/v2/actor-runs/{run_id}",
            params={"token": APIFY_TOKEN},
            timeout=15,
        )
        status_resp.raise_for_status()
        status = status_resp.json()["data"]["status"]

        if status == "SUCCEEDED":
            print(f"  Run completed successfully")
            break
        elif status in ("FAILED", "ABORTED", "TIMED-OUT"):
            print(f"  Run ended with status: {status}")
            return []
    else:
        print(f"  Run timed out after 5 minutes")
        return []

    # Fetch results from dataset
    results_resp = requests.get(
        f"https://api.apify.com/v2/datasets/{dataset_id}/items",
        params={"token": APIFY_TOKEN, "format": "json"},
        timeout=30,
    )
    results_resp.raise_for_status()
    return results_resp.json()


def download_image(url: str, filepath: Path, timeout: int = 15) -> bool:
    """Download a single image from URL."""
    try:
        headers = {
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
        }
        resp = requests.get(url, headers=headers, timeout=timeout, stream=True)
        resp.raise_for_status()

        content_type = resp.headers.get("content-type", "")
        if not any(t in content_type for t in ["image/", "octet-stream"]):
            return False

        # Check minimum size (skip tiny thumbnails)
        content = resp.content
        if len(content) < 10_000:  # < 10KB likely a thumbnail
            return False

        filepath.write_bytes(content)
        return True
    except Exception as e:
        return False


def collect_via_apify() -> list[dict]:
    """Collect images using Apify Google Images Scraper."""
    manifest = []
    downloaded = 0
    seen_urls = set()

    for query in SEARCH_QUERIES:
        if downloaded >= TARGET_TOTAL:
            break

        print(f"\nQuery: '{query}'")
        try:
            results = run_apify_actor(query, max_items=IMAGES_PER_QUERY)
        except Exception as e:
            print(f"  Error running actor: {e}")
            continue

        for item in results:
            if downloaded >= TARGET_TOTAL:
                break

            # Try original image URL first, then thumbnail
            image_url = item.get("imageUrl") or item.get("originalImageUrl") or item.get("url")
            if not image_url or image_url in seen_urls:
                continue
            seen_urls.add(image_url)

            # Generate filename from hash
            url_hash = hashlib.md5(image_url.encode()).hexdigest()[:10]
            filename = f"gym_{downloaded + 1:03d}_{url_hash}.jpg"
            filepath = IMAGES_DIR / filename

            if download_image(image_url, filepath):
                downloaded += 1
                entry = {
                    "filename": filename,
                    "source_url": image_url,
                    "query": query,
                    "title": item.get("title", ""),
                    "source_page": item.get("sourceUrl") or item.get("link", ""),
                }
                manifest.append(entry)
                print(f"  [{downloaded}/{TARGET_TOTAL}] Downloaded: {filename}")
            else:
                # Try thumbnail as fallback
                thumb_url = item.get("thumbnailUrl") or item.get("thumbnail")
                if thumb_url and thumb_url not in seen_urls:
                    seen_urls.add(thumb_url)
                    if download_image(thumb_url, filepath):
                        downloaded += 1
                        entry = {
                            "filename": filename,
                            "source_url": thumb_url,
                            "query": query,
                            "title": item.get("title", ""),
                            "source_page": item.get("sourceUrl") or item.get("link", ""),
                        }
                        manifest.append(entry)
                        print(f"  [{downloaded}/{TARGET_TOTAL}] Downloaded (thumb): {filename}")

    return manifest


def collect_via_direct_urls() -> list[dict]:
    """Fallback: download from a curated list of known hotel gym image URLs.
    These are from stock photo sites, hotel review sites, etc. with permissive access."""

    # Curated URLs from various sources (Unsplash, Pexels - all free to use)
    curated_urls = [
        # Unsplash hotel/gym images - wide variety
        ("https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800", "unsplash - gym equipment wide"),
        ("https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800", "unsplash - gym interior"),
        ("https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=800", "unsplash - gym machines"),
        ("https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800", "unsplash - dumbbells rack"),
        ("https://images.unsplash.com/photo-1593079831268-3381b0db4a77?w=800", "unsplash - small gym"),
        ("https://images.unsplash.com/photo-1576678927484-cc907957088c?w=800", "unsplash - gym workout area"),
        ("https://images.unsplash.com/photo-1623874514711-0f321325f318?w=800", "unsplash - hotel fitness"),
        ("https://images.unsplash.com/photo-1570829460005-c840387bb1ca?w=800", "unsplash - treadmills row"),
        ("https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800", "unsplash - weight room"),
        ("https://images.unsplash.com/photo-1637666062717-1c6bcfa4a4df?w=800", "unsplash - modern gym"),
        ("https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800", "unsplash - gym bench press"),
        ("https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?w=800", "unsplash - cable machine"),
        ("https://images.unsplash.com/photo-1548690312-e3b507d8c110?w=800", "unsplash - fitness center"),
        ("https://images.unsplash.com/photo-1590487988256-9ed24133863e?w=800", "unsplash - gym equipment close"),
        ("https://images.unsplash.com/photo-1596357395217-80de13130e92?w=800", "unsplash - home gym setup"),
        ("https://images.unsplash.com/photo-1584735935682-2f2b69dff9d2?w=800", "unsplash - gym training area"),
        ("https://images.unsplash.com/photo-1560264280-88b68371db39?w=800", "unsplash - elliptical machines"),
        ("https://images.unsplash.com/photo-1574680178050-55c6a6a96e0a?w=800", "unsplash - gym weights"),
        ("https://images.unsplash.com/photo-1588286840104-8957b019727f?w=800", "unsplash - yoga mats studio"),
        ("https://images.unsplash.com/photo-1595909315417-2edd382a56dc?w=800", "unsplash - kettlebells"),
        # More Unsplash - different gym types and equipment
        ("https://images.unsplash.com/photo-1578762560042-46ad127c95ea?w=800", "unsplash - rowing machines gym"),
        ("https://images.unsplash.com/photo-1591940742878-13aba4b7a34e?w=800", "unsplash - empty gym floor"),
        ("https://images.unsplash.com/photo-1562771242-a02d9090c90c?w=800", "unsplash - gym dumbbell section"),
        ("https://images.unsplash.com/photo-1558017487-06bf9f82613a?w=800", "unsplash - crossfit gym"),
        ("https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=800", "unsplash - gym leg press"),
        ("https://images.unsplash.com/photo-1521804906057-1df8fdb718b7?w=800", "unsplash - gym pullup bar"),
        ("https://images.unsplash.com/photo-1580261450046-d0a30080dc9b?w=800", "unsplash - small fitness room"),
        ("https://images.unsplash.com/photo-1546817372-628669db4655?w=800", "unsplash - gym smith machine"),
        ("https://images.unsplash.com/photo-1597452485669-2c7bb5fef90d?w=800", "unsplash - home dumbbell set"),
        ("https://images.unsplash.com/photo-1549060279-7e168fcee0c2?w=800", "unsplash - gym cardio area"),
        ("https://images.unsplash.com/photo-1518310383802-640c2de311b2?w=800", "unsplash - battle ropes gym"),
        ("https://images.unsplash.com/photo-1517344884509-a0c97ec11bcc?w=800", "unsplash - gym rack weights"),
        ("https://images.unsplash.com/photo-1592632789004-57d4354f2499?w=800", "unsplash - resistance bands"),
        ("https://images.unsplash.com/photo-1599058917765-a780eda07a3e?w=800", "unsplash - gym barbell area"),
        ("https://images.unsplash.com/photo-1605296867424-35fc25c9212a?w=800", "unsplash - gym spin bikes"),
        ("https://images.unsplash.com/photo-1600881333168-2ef49b341f30?w=800", "unsplash - luxury gym space"),
        ("https://images.unsplash.com/photo-1585676623595-7e605e3e0f30?w=800", "unsplash - stability balls"),
        ("https://images.unsplash.com/photo-1594737625992-2f5b5f31dfab?w=800", "unsplash - gym mirror view"),
        ("https://images.unsplash.com/photo-1638536532686-d610adfc8e5c?w=800", "unsplash - apartment gym"),
        ("https://images.unsplash.com/photo-1603287681836-b174ce5074c2?w=800", "unsplash - hotel gym clean"),
        # Pexels free images
        ("https://images.pexels.com/photos/1954524/pexels-photo-1954524.jpeg?w=800", "pexels - gym interior"),
        ("https://images.pexels.com/photos/3076509/pexels-photo-3076509.jpeg?w=800", "pexels - gym machines"),
        ("https://images.pexels.com/photos/260352/pexels-photo-260352.jpeg?w=800", "pexels - weight room"),
        ("https://images.pexels.com/photos/4162451/pexels-photo-4162451.jpeg?w=800", "pexels - small gym"),
        ("https://images.pexels.com/photos/4164761/pexels-photo-4164761.jpeg?w=800", "pexels - dumbbells"),
        ("https://images.pexels.com/photos/3757957/pexels-photo-3757957.jpeg?w=800", "pexels - cable machine"),
        ("https://images.pexels.com/photos/4720236/pexels-photo-4720236.jpeg?w=800", "pexels - gym benches"),
        ("https://images.pexels.com/photos/7031706/pexels-photo-7031706.jpeg?w=800", "pexels - fitness center"),
        ("https://images.pexels.com/photos/4853095/pexels-photo-4853095.jpeg?w=800", "pexels - resistance training"),
        ("https://images.pexels.com/photos/3836831/pexels-photo-3836831.jpeg?w=800", "pexels - treadmill area"),
        # More Pexels
        ("https://images.pexels.com/photos/4720311/pexels-photo-4720311.jpeg?w=800", "pexels - gym wide view"),
        ("https://images.pexels.com/photos/3838937/pexels-photo-3838937.jpeg?w=800", "pexels - dumbbell close"),
        ("https://images.pexels.com/photos/4720309/pexels-photo-4720309.jpeg?w=800", "pexels - gym machines 2"),
        ("https://images.pexels.com/photos/2261482/pexels-photo-2261482.jpeg?w=800", "pexels - gym floor plan"),
        ("https://images.pexels.com/photos/4164766/pexels-photo-4164766.jpeg?w=800", "pexels - weight plates"),
        ("https://images.pexels.com/photos/3836861/pexels-photo-3836861.jpeg?w=800", "pexels - cardio machines"),
        ("https://images.pexels.com/photos/3838389/pexels-photo-3838389.jpeg?w=800", "pexels - bench area"),
        ("https://images.pexels.com/photos/116077/pexels-photo-116077.jpeg?w=800", "pexels - treadmill close"),
        ("https://images.pexels.com/photos/4720312/pexels-photo-4720312.jpeg?w=800", "pexels - gym equipment sets"),
        ("https://images.pexels.com/photos/3289711/pexels-photo-3289711.jpeg?w=800", "pexels - kettlebell set"),
    ]

    manifest = []
    downloaded = 0

    for url, source_desc in curated_urls:
        downloaded += 1
        filename = f"gym_{downloaded:03d}.jpg"
        filepath = IMAGES_DIR / filename

        print(f"  [{downloaded}/{len(curated_urls)}] Downloading: {source_desc}")
        if download_image(url, filepath):
            manifest.append({
                "filename": filename,
                "source_url": url,
                "query": source_desc,
                "title": source_desc,
                "source_page": url,
            })
        else:
            print(f"    Failed to download")
            downloaded -= 1

    return manifest


def main():
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)

    # Check how many images already exist
    existing = list(IMAGES_DIR.glob("*.jpg")) + list(IMAGES_DIR.glob("*.png"))
    if len(existing) >= 50:
        print(f"Already have {len(existing)} images in {IMAGES_DIR}. Skipping download.")
        print("Delete images directory to re-download.")
        return

    print("=" * 60)
    print("GymScan - Hotel Gym Image Collector")
    print("=" * 60)

    manifest = []

    # Phase 1: Try Apify
    print("\n--- Phase 1: Apify Google Images Scraper ---")
    try:
        apify_manifest = collect_via_apify()
        manifest.extend(apify_manifest)
        print(f"\nApify collected {len(apify_manifest)} images")
    except Exception as e:
        print(f"\nApify collection failed: {e}")

    # Phase 2: Fill remaining with curated URLs
    remaining = TARGET_TOTAL - len(manifest)
    if remaining > 0:
        print(f"\n--- Phase 2: Curated URLs (need {remaining} more) ---")
        curated_manifest = collect_via_direct_urls()
        # Only add entries whose filenames don't conflict
        existing_filenames = {m["filename"] for m in manifest}
        for entry in curated_manifest:
            if len(manifest) >= TARGET_TOTAL:
                break
            if entry["filename"] in existing_filenames:
                # Rename to avoid conflict
                idx = len(manifest) + 1
                entry["filename"] = f"gym_{idx:03d}_curated.jpg"
                old_path = IMAGES_DIR / f"gym_{curated_manifest.index(entry) + 1:03d}.jpg"
                new_path = IMAGES_DIR / entry["filename"]
                if old_path.exists():
                    old_path.rename(new_path)
            manifest.append(entry)

    # Save manifest
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2))

    # Count actual downloaded files
    actual_files = list(IMAGES_DIR.glob("*.jpg")) + list(IMAGES_DIR.glob("*.png"))
    print(f"\n{'=' * 60}")
    print(f"Collection complete!")
    print(f"  Manifest entries: {len(manifest)}")
    print(f"  Actual image files: {len(actual_files)}")
    print(f"  Manifest saved: {MANIFEST_PATH}")
    print(f"  Images dir: {IMAGES_DIR}")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
