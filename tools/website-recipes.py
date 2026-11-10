#!/usr/bin/env python3
"""Write the website's "Recipe of the day" list from the bundled recipes.

Only name, total time, cuisine (when the name states it), category and ingredient count are exported — no method
text. Order is shuffled with a fixed seed so consecutive days differ; the site picks entry (days since epoch % n).
Usage (from the repo root): python3 tools/website-recipes.py ../RecipeFinderWebsite/assets/recipes-of-the-day.json
"""
import json, random, re, sys

SEED = "RecipeFinder/RecipeSeed/recipes_seed.json"
CUISINES = ["American", "British", "Caribbean", "Chinese", "French", "Greek", "Indian", "Italian", "Japanese",
            "Korean", "Lebanese", "Malaysian", "Mexican", "Middle Eastern", "Moroccan", "Pakistani", "Persian",
            "Spanish", "Thai", "Turkish", "Vietnamese"]

def minutes(text):
    if not text:
        return 0
    t = text.lower()
    hours = sum(float(h) for h in re.findall(r"(\d+(?:\.\d+)?)\s*(?:h|hr|hrs|hour|hours)\b", t))
    mins = sum(int(m) for m in re.findall(r"(\d+)\s*(?:m|min|mins|minute|minutes)\b", t))
    return int(round(hours * 60)) + mins

def cuisine(name):
    for c in CUISINES:
        if re.search(r"\b" + re.escape(c) + r"\b", name, re.I):
            return c
    return None

def export(recipes):
    out = []
    for r in recipes:
        total = minutes(r.get("prepTime")) + minutes(r.get("cookingTime"))
        count = len(r.get("ingredients") or [])
        if not r.get("name") or total <= 0 or count == 0:
            continue
        item = {"name": r["name"].strip(), "minutes": total, "category": r.get("category"), "ingredients": count}
        c = cuisine(r["name"])
        if c:
            item["cuisine"] = c
        out.append(item)
    out.sort(key=lambda x: x["name"])
    random.Random(20261110).shuffle(out)
    return out

if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    data = export(json.load(open(SEED)))
    with open(sys.argv[1], "w") as f:
        json.dump(data, f, ensure_ascii=False, separators=(",", ":"))
        f.write("\n")
    print(f"wrote {len(data)} recipes to {sys.argv[1]}")
