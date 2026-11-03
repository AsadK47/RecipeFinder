#!/usr/bin/env python3
"""
Resolve a hero-image URL for every bundled recipe that has a source URL.

Reads  RecipeFinder/RecipeSeed/recipes_source.json
Writes RecipeFinder/RecipeSeed/recipes_source_images.json   {source URL: image URL}

The app never bundles these photos: BundledRecipeCatalogTests merges the map into recipes_seed.json as
`imageName` (an https URL), so the image is hotlinked from the source site and credited via the source link.
Existing entries are kept, so re-runs only fetch new/missing URLs. Pass --refresh to re-resolve everything.

Usage:  python3 tools/seed-images/fetch_seed_images.py [--refresh]
Then re-run BundledRecipeCatalogTests to regenerate recipes_seed.json.
"""
import sys, os, re, json, html, urllib.request
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SEED = os.path.join(ROOT, "RecipeFinder", "RecipeSeed")
SOURCE = os.path.join(SEED, "recipes_source.json")
OUTPUT = os.path.join(SEED, "recipes_source_images.json")

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 "
      "(KHTML, like Gecko) Version/17.0 Safari/605.1.15")
URL_RE = re.compile(r"https?://[^\s]+")
JSONLD_RE = re.compile(r'<script[^>]*type=["\']application/ld\+json["\'][^>]*>(.*?)</script>', re.I | re.S)
OG_RE = re.compile(r'<meta[^>]+(?:property|name)=["\'](?:og:image|twitter:image)["\'][^>]*content=["\']([^"\']+)', re.I)
OG_REV_RE = re.compile(r'<meta[^>]+content=["\']([^"\']+)["\'][^>]*(?:property|name)=["\'](?:og:image|twitter:image)["\']', re.I)


def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept-Language": "en"})
    with urllib.request.urlopen(req, timeout=20) as r:
        return r.read().decode("utf-8", errors="replace")


def image_from_value(value):
    if isinstance(value, str):
        return value
    if isinstance(value, list) and value:
        return image_from_value(value[0])
    if isinstance(value, dict):
        return value.get("url") or value.get("contentUrl")
    return None


def find_recipe_image(node):
    """Depth-first search of JSON-LD for a Recipe node's image."""
    if isinstance(node, list):
        for item in node:
            found = find_recipe_image(item)
            if found:
                return found
    elif isinstance(node, dict):
        types = node.get("@type")
        types = types if isinstance(types, list) else [types]
        if "Recipe" in types and node.get("image"):
            return image_from_value(node["image"])
        for key in ("@graph", "mainEntity"):
            if key in node:
                found = find_recipe_image(node[key])
                if found:
                    return found
    return None


def resolve(url):
    try:
        page = fetch(url)
    except Exception as error:
        return url, None, str(error)
    for block in JSONLD_RE.findall(page):
        try:
            image = find_recipe_image(json.loads(block.strip()))
        except ValueError:
            continue
        if image and image.startswith("http"):
            return url, html.unescape(image), None
    match = OG_RE.search(page) or OG_REV_RE.search(page)
    if match and match.group(1).startswith("http"):
        return url, html.unescape(match.group(1)), None
    return url, None, "no image found"


def main():
    refresh = "--refresh" in sys.argv
    entries = json.load(open(SOURCE, encoding="utf-8"))
    urls = sorted({m.group(0) for e in entries for m in [URL_RE.search(e["rawText"])] if m})
    existing = {} if refresh or not os.path.exists(OUTPUT) else json.load(open(OUTPUT, encoding="utf-8"))
    todo = [u for u in urls if u not in existing]
    print(f"{len(urls)} source URLs, {len(existing)} cached, fetching {len(todo)}")

    failures = []
    with ThreadPoolExecutor(max_workers=12) as pool:
        for url, image, error in pool.map(resolve, todo):
            if image:
                existing[url] = image
            else:
                failures.append(f"{url}  ({error})")

    result = {u: existing[u] for u in sorted(existing) if u in urls}
    with open(OUTPUT, "w", encoding="utf-8") as f:
        json.dump(result, f, indent=2, ensure_ascii=False, sort_keys=True)
        f.write("\n")
    print(f"resolved {len(result)}/{len(urls)}; {len(failures)} without an image")
    for line in failures:
        print("  -", line)


if __name__ == "__main__":
    main()
