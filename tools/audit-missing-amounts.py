#!/usr/bin/env python3
"""Audit bundled recipes for gaps: core ingredients with no amount, and recipes with no prep + cook time.

Run from the repo root. Exits 1 if anything is missing (usable as a check). "To taste", "to serve", garnish,
optional and similar ingredients are allowed to have no amount. Add --list for every gap, one per line.
"""
import json
import re
import sys

SEED = "RecipeFinder/RecipeSeed/recipes_seed.json"
# Ingredients a cook doesn't need an amount for: seasoning to taste, garnish, frying/greasing oil, ice, water for soaking.
ALLOWED_BLANK = re.compile(
    r"to taste|to serve|to garnish|for garnish|to decorate|to dust|to top|optional|as needed|pinch|splash|"
    r"for (?:deep |shallow |pan[- ])?frying|for (?:dusting|greasing|brushing|sprinkling|rolling|proving|coating|cooking|"
    r"drizzling|soaking|dipping|pan-frying)|cooking spray|oil spray|toppings of your choice|"
    r"^(?:fine sea )?salt and (?:freshly ground )?(?:black )?pepper$|^ice(?: cubes)?$|^(?:freshly ground )?black pepper$|"
    r"^black pepper, freshly ground$", re.I)


def minutes(text: str) -> int:
    match = re.match(r"\d+", text or "")
    return int(match.group()) if match else 0


def main() -> int:
    recipes = json.load(open(SEED))
    no_time = [r for r in recipes if minutes(r["prepTime"]) + minutes(r["cookingTime"]) == 0]
    gaps = [(r, i) for r in recipes for i in r["ingredients"]
            if not i["baseQuantity"] and not ALLOWED_BLANK.search(i["name"])]
    print(f"{len(recipes)} recipes · {len(no_time)} with no prep+cook time · "
          f"{len(gaps)} core ingredients without an amount in {len({r['id'] for r, _ in gaps})} recipes")
    if "--list" in sys.argv:
        for r in no_time:
            print(f"TIME\t{r['id']}\t{r['name']}")
        for r, i in gaps:
            print(f"AMOUNT\t{r['id']}\t{r['name']}\t{i['name']}")
    return 1 if no_time or gaps else 0


if __name__ == "__main__":
    sys.exit(main())
