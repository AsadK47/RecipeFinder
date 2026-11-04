# Bundled recipe review — brief (read fully)

> Done 2026-11-04 for all 340 source recipes → `RecipeFinder/RecipeSeed/recipes_curated.json` (keyed by stable id;
> applied by `BundledRecipeCatalogTests`). To review NEW source recipes: dump them in the input shape below, run this
> brief, merge the output objects into recipes_curated.json. `everyRecipeIsCurated` fails until every recipe is reviewed.

You are curating RecipeFinder's bundled recipes. Input: `tools/recipe-review/batches/batch_N.json` — each entry is a recipe
as the app currently shows it (`name`, `category`, `difficulty`, `prepTime`, `cookingTime`, `servings`, `ingredients` as
"qty unit | name", `prePrep`, `steps`, `notes`, `hasPhoto`) plus `rawSource` = the original pasted text it was parsed from.
Problems are mostly parse artefacts from that paste: section headings as ingredients, "1x 2x 3x" scaler rows, duplicated
or calculator-scaled amounts (e.g. 7.083700441 tbsp, "Eggs 4 2"), merged ingredient lines, unit stuck in the name,
prep words duplicated ("onion diced, diced"), steps fused into one block or split mid-sentence, Notes/Nutrition/Video/
"Pin"/"Print"/ads leaking in, junk titles, invented times (10/30 min placeholders), several recipes stitched into one.

## Your job
For EVERY recipe in your batch decide `keep` (already reads well — rare), `fix`, or `drop`, and write
`tools/recipe-review/out/batch_N.json` (a JSON array, one object per input recipe, same order). For `fix`, write the
complete corrected recipe. Validate the file parses (`python3 -c "import json;json.load(open('...'))"`) before finishing.

## Hard rules
- Source of truth is `rawSource`. NEVER invent ingredients, amounts, times or steps that aren't in it. You may reword
  steps lightly for clarity/grammar and split/merge them sensibly; you may drop junk.
- Amounts: the ORIGINAL (1x) amount from the source. Use decimals for fractions (0.5, 0.33, 1.5). No amount in source → 0.
- Units (short, lowercase): g, kg, ml, l, tsp, tbsp, cup, oz, lb, pinch, clove, can, slice, handful, sprig, bunch,
  "" for counts. Never leave a unit word inside the name.
- Ingredient `name`: lowercase except proper nouns ("plain flour", "Kashmiri chilli powder"); prep/notes after a comma
  ("onion, finely diced"); no duplicated words; no amounts in the name. Drop section headings, equipment, scaler rows,
  "optional:" labels (keep the ingredient, append ", optional").
- Steps: clean sentences, one action or tightly related actions per step, no numbering/"Step 1", no notes/nutrition/
  video/ads/blog chatter. Typical 3–12 steps. `prePrep` only for genuine advance prep (marinate overnight, soak beans).
- Several recipes stitched together → keep the main/first complete one; you may mention variants in one short note.
- `prepMinutes` / `cookMinutes`: only if the source states them (convert hours); otherwise 0. `servings`: from source,
  else 4.
- `category`: one of Breakfast, Starter, Main, Side, Soup, Dessert, Drink (cakes/bakes/sweets → Dessert; breads,
  dips, sauces, rice → Side). `difficulty`: Basic, Intermediate or Expert (your judgement of effort).
- `name`: clean human title in Title Case; keep the dish identity, drop SEO fluff ("Recipe", "Easy & Simple",
  "(Smoky, Tender, Super Flavorful!)", "Quick & Easy", "15-min."), keep useful qualifiers ("Slow Cooker", "Air Fryer",
  "Vegan"). Non-English names: keep a clean English title; drop garbled script.
- `notes`: optional, ≤3 short useful tips from the source; no URLs (the app adds the source link itself).
- `drop` only if it isn't a usable recipe (no method or no ingredients even in rawSource) — give a reason.

## Output object
{"id": "<input id>", "action": "keep"|"fix"|"drop", "issues": ["short list of what was wrong"],
 "recipe": {"name": "", "category": "", "difficulty": "", "prepMinutes": 0, "cookMinutes": 0, "servings": 4,
            "ingredients": [{"quantity": 0.5, "unit": "cup", "name": "plain flour"}],
            "prePrep": [], "steps": [""], "notes": ""}}
(`recipe` required for `fix`; omit for keep/drop.)

Final reply: counts of keep/fix/drop, the 5 worst recipes and why, and confirmation the JSON validated. No code edits.
