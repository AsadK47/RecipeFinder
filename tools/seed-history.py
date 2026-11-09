#!/usr/bin/env python3
"""Regenerate RecipeFinder/RecipeSeed/recipes_seed_history.json from git history.

Every committed version of recipes_seed.json is a version some install may have seeded. For each recipe id still
in today's bundle, keep each earlier version whose editable content differs from today's. The app matches a stored
sample against these to tell an untouched old copy (refresh it) from one the user edited (leave it).
Run from the repo root with full history (`git fetch --unshallow`), then bump
BundledRecipeCatalog.sampleRefreshVersion.
"""
import json, subprocess

SEED = "RecipeFinder/RecipeSeed/recipes_seed.json"
OUT = "RecipeFinder/RecipeSeed/recipes_seed_history.json"
CONTENT = ["name", "category", "difficulty", "prepTime", "cookingTime", "baseServings", "ingredients",
           "prePrepInstructions", "instructions", "notes", "cuisine", "dietaryInfo"]
KEEP = ["id", "name", "category", "difficulty", "prepTime", "cookingTime", "baseServings", "currentServings",
        "ingredients", "prePrepInstructions", "instructions", "notes", "imageName", "isFavorite", "dietaryInfo",
        "cuisine"]

def key(r):
    return json.dumps({f: r.get(f) for f in CONTENT}, sort_keys=True, ensure_ascii=False)

current = {r["id"]: r for r in json.load(open(SEED))}
commits = subprocess.run(["git", "log", "--format=%H", "--", SEED], capture_output=True, text=True,
                         check=True).stdout.split()
out, seen = [], set()
for commit in reversed(commits):
    shown = subprocess.run(["git", "show", f"{commit}:{SEED}"], capture_output=True, text=True)
    if shown.returncode != 0 or not shown.stdout.strip():
        continue
    versions = json.loads(shown.stdout)
    if not isinstance(versions, list) or not versions or "id" not in versions[0]:
        continue  # early raw-text corpus, never seeded as recipes
    for r in versions:
        rid = r.get("id")
        if rid not in current or key(r) == key(current[rid]) or (rid, key(r)) in seen:
            continue
        seen.add((rid, key(r)))
        out.append({f: r[f] for f in KEEP if f in r})

json.dump(out, open(OUT, "w"), ensure_ascii=False, separators=(",", ":"))
print(f"{len(out)} historical versions written to {OUT}")
