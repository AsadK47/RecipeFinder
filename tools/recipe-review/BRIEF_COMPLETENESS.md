# Bundled recipe COMPLETENESS review (second pass) — read fully

Input: `tools/recipe-review/batches2/batch_N.json` — each entry: `id`, `curated` (the recipe as the app ships it:
name, category, difficulty, prepMinutes, cookMinutes, servings, ingredients [{quantity, unit, name}], prePrep, steps,
notes) and `rawSource` (the original pasted text it was made from).

A first pass cleaned these up but sometimes LOST content. Example: "Black Sesame Tangyuan" kept the filling ingredients
(butter, sugar, sesame) but dropped the whole filling method (melt butter, stir in sugar + sesame, chill 2 h, roll
balls, freeze 1 h), so the steps start at the dough and those ingredients are never used.

## For every recipe, check against rawSource
1. Method completeness: every component in the kept version (filling, dough, sauce, marinade, frosting, broth,
   assembly, cooking, serving) has its steps. Nothing that the source says to do is missing, in the right order.
2. Every ingredient is actually used (by name or clearly, e.g. "add the spices") in prePrep/steps; every ingredient
   the source lists for the kept version is present. Prefer adding the missing steps over removing ingredients.
3. Amounts/units match the source's original (1x) amounts; servings and times as the source states (else unchanged).
4. Nothing is invented — every step must be traceable to rawSource (light rewording for clarity is fine).
5. If the first pass merged variants, keep its chosen variant; don't re-add the others.
If the recipe is already complete and correct, mark it ok. Be strict but don't churn wording that's fine.

## Output: `tools/recipe-review/out2/batch_N.json` — JSON array, one object per input, same order
{"id": "...", "status": "ok"} or
{"id": "...", "status": "fix", "reason": "what was missing/wrong (short)",
 "recipe": { FULL corrected recipe in the same schema as `curated` }}
Use the same rules as before: units g, kg, ml, l, tsp, tbsp, cup, oz, lb, pinch, clove, can, slice, handful, sprig,
bunch, inch, jar, box or "" for counts; ingredient names lowercase sentence (proper nouns kept), notes after a comma;
steps are clean sentences, no numbering, 3–15 typical; prePrep only for genuine advance prep (marinate, soak, chill
overnight). Keep the same name/category/difficulty unless clearly wrong.
Validate the JSON parses before finishing. Final reply: counts ok/fix and the 5 biggest gaps fixed. No code edits.
