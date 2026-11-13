#!/usr/bin/env python3
"""Compress RecipeArt's generated pictures (tools/RecipeArt/Output/<recipe id>.jpg, 1024px) into the app bundle folder
RecipeFinder/RecipeSeed/RecipeArt/<recipe id>.jpg (960px JPEG — sharp on a full-width 220pt hero at 3x), skipping
files whose id isn't a bundled recipe and ids listed in tools/RecipeArt/rejected.txt (wrong-looking pictures awaiting a
redraw). Rerun after generating more; it rewrites the folder from Output. Needs Pillow."""
import json, os, sys
from PIL import Image

SRC, DST = "tools/RecipeArt/Output", "RecipeFinder/RecipeSeed/RecipeArt"
EDGE, QUALITY = 960, 62
REJECTED = "tools/RecipeArt/rejected.txt"

ids = {r["id"] for r in json.load(open("RecipeFinder/RecipeSeed/recipes_seed.json", encoding="utf-8"))}
rejected = set()
if os.path.exists(REJECTED):
    rejected = {l.split("#")[0].strip() for l in open(REJECTED, encoding="utf-8")} - {""}
os.makedirs(DST, exist_ok=True)
for old in os.listdir(DST):
    os.remove(os.path.join(DST, old))
written, skipped, total = 0, [], 0
for name in sorted(os.listdir(SRC)):
    stem, ext = os.path.splitext(name)
    if ext.lower() != ".jpg":
        continue
    if stem not in ids or stem in rejected:
        skipped.append(name)
        continue
    im = Image.open(os.path.join(SRC, name)).convert("RGB")
    im.thumbnail((EDGE, EDGE), Image.LANCZOS)
    out = os.path.join(DST, name)
    im.save(out, "JPEG", quality=QUALITY, optimize=True, progressive=True)
    total += os.path.getsize(out)
    written += 1
print(f"{written} pictures, {total / 1e6:.1f} MB; {len(ids) - written} recipes without one; skipped {skipped or 'none'}",
      file=sys.stderr)
