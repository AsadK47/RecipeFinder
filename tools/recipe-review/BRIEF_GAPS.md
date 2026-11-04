# Targeted gap review (third pass) — read fully

Input `tools/recipe-review/batches3/batch_N.json`: each entry has `id`, `curated` (recipe as shipped), `rawSource`
and `signal` — e.g. "source has ~23 method-like lines; curated keeps 6 steps". A mechanical counter flagged these
because the shipped method is much shorter than the source's. Earlier reviewers missed real gaps (e.g. Black Sesame
Tangyuan had lost its whole filling method yet was marked "ok"), so do NOT accept a recipe just because it reads well.

For EACH recipe, go through the source's method line by line and account for every instruction: either it is in the
curated steps (possibly merged/reworded), or it is legitimately excluded. Legitimate exclusions ONLY:
blog chatter/tips/FAQ/storage/nutrition/troubleshooting, a different variant or a separate stitched-in recipe that
the curated version deliberately didn't keep, duplicated text, ads/comments. Anything else that the kept recipe
needs to be cooked correctly (a component's preparation, a resting/chilling/proofing time, an assembly or cooking
step, a temperature) is a GAP — add it, in the right order, as clean steps traceable to the source.
Also confirm every curated ingredient gets used, and that the curated version isn't a different recipe from the source.

Output `tools/recipe-review/out3/batch_N.json` (JSON array, same order):
{"id": "...", "status": "ok", "accounted": "one line: what the extra source lines were (e.g. 'variant 2 + blog tips')"}
or {"id": "...", "status": "fix", "reason": "what was missing", "recipe": { FULL corrected recipe, same schema }}.
Same formatting rules as before (units g, kg, ml, l, tsp, tbsp, cup, oz, lb, pinch, clove, can, slice, handful, sprig,
bunch, inch, jar, box or ""; lowercase ingredient names, notes after a comma; clean un-numbered steps; prePrep only for
genuine advance prep). Never invent. Validate the JSON. Reply: counts and the biggest gaps fixed. No code edits.
Do the work yourself — no sub-agents.
