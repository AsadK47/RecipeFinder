# Bug & Defect Audit — attack plan

A prioritised catalogue of correctness defects found while reviewing the logic-bearing
code. Method: read the heuristic/logic hot spots + grep for dangerous patterns
(force-unwraps, `try!`, number parsing, substring matching). UI/layout and generated
code were not line-audited.

**Severity:** P1 = wrong results users hit often · P2 = wrong results in common edge cases
· P3 = smell / rare / cosmetic.

**Recurring root cause:** *substring matching where whole-word matching is meant* — the
same class as the gin→ginger bug. It recurs in the normalizer, unit converter, and
category classifier. And *iterating a `Dictionary` for “first match”* is order-undefined,
so results can differ between launches.

---

## Confirmed defects

### Import & parsing
- **[P2] ✅ FIXED — Non-UTF-8 pages failed import entirely.** `RecipeImportPipeline` now
  decodes via `decodeHTML(_:response:)`: honours `httpResponse.textEncodingName`, then tries
  UTF-8 / Windows-1252 / ISO-8859-1, and finally a lossy UTF-8 decode that never returns nil.
  Test feeds the fake fetcher ISO-8859-1 bytes ("Crème Brûlée") declared via Content-Type and
  asserts the recipe parses. `.invalidEncoding` is now unreachable (kept as a declared case).
- **[P3] Redirect handler only covers 301/302.** `RecipeImportPipeline.swift:77` — misses
  303/307/308. Moot in production (`URLSession.shared` auto-follows all of them), so this
  only affects the injected-fetcher/test path. **Fix:** comment why, or handle the other
  3xx codes for symmetry.

### Ingredient / unit logic
- **[P1] ✅ FIXED this session — `KitchenRecipeMatcher` substring match** (gin matched
  ginger). Now whole-word; 10/10 tests green.
- **[P2] ✅ FIXED — `IngredientNormalizer` substring fallback was order-undefined.**
  The fallback now iterates a precomputed `sortedNormalizationEntries` (longest-key-first,
  then alphabetical) and matches whole words via `IngredientWordMatcher`. Fixes both the
  `Dictionary`-order nondeterminism (two-key inputs resolve stably) and substring conflation
  (**"hot saucepan" → "Hot Saucepan"**, no longer "Hot Sauce"). Descriptor-prefixed variants
  like "fresh minced garlic" → Garlic still match.
- **[P2] ✅ FIXED — `UnitConversion` solid/density detection used substring match.**
  `isSolidIngredient` and `getDensityConversion` now use `IngredientWordMatcher` (whole-word),
  and the density map is iterated longest-keyword-first for deterministic results. Fixes
  **"salted butter" → salt**. Note **"sugar snap peas" → sugar** is *not* fixed by this —
  "sugar" is a genuine whole word there, so it needs semantic (not lexical) disambiguation;
  left deliberately.
- **[P2] ✅ FIXED — `CategoryClassifier.categorize` matched substring before whole word.**
  The leading `normalized.contains(k)` short-circuited the word-boundary check, so
  **"graham" → Meat** (via "ham"), **"popcorn" → Produce** (via "corn"). Now tokenises the
  item name once and matches whole words via `IngredientWordMatcher`. graham → not Meat,
  popcorn → not Produce; all pre-existing categorisations still green.
- **[P3] `CategoryClassifier.groupSimilarIngredients` precedence bug.**
  `:357-359` — `…components(",").first ?? ingredient.trimmingCharacters(…)` binds so the trim
  only applies to the (never-taken) fallback; `cleaned` is never trimmed. Mostly benign because
  `split(separator:" ")` drops empties. **Fix:** parenthesise, or delete if the method is
  unused (verify callers first).
- **[P3] `CategoryClassifier.isValidIngredient` accepts anything > 15 chars.** `:350` —
  arbitrary; long non-ingredient strings pass. Low impact.

### Groceries screen (this session — needs runtime check, not just build)
- **[P2 verify] One-`List`, two-section rendering.** The merged screen hosts
  `ShoppingSectionsView` / `KitchenSectionsView` (each emitting bare `Section`s) inside one
  `List`. Compiles; confirm at runtime that sections/headers/swipe/collapse render correctly.
- **[P3 note] Kitchen add via search** is per-row (fridge button) only; the return key adds to
  the shopping list. Intended, documented here so it isn't "rediscovered" as a bug.

---

## Not yet reviewed (schedule next, highest risk first)
1. **Parsers** — `RecipeParser` + `+StructuredData/+WPRM/+Microdata/+TextMetadata/+TextContent`,
   `TextRecipeParser`, `WizardIngredientParser`, `RecipeImportBuilder` (rest), `RecipeImporter`,
   `SharedTextImporter`. Densest heuristics; expect more substring/normalisation issues and
   time/servings parsing edge cases.
2. **Persistence & backup** — `PersistenceController`, the four managers, `Backup*`. Low logic
   risk but highest consequence (data loss / merge correctness). Focus on merge & migration.
3. **Views** — mostly layout; scan for work-in-`body`, force-unwraps, `onChange` gaps.

---

## Attack order
1. Land the **P2 correctness fixes** as small TDD commits, one per defect: charset decode,
   normalizer determinism, unit-conversion word-boundary, category-classifier word-boundary.
   Each is isolated and reversible.
2. **Runtime-verify** the Groceries screen on the simulator.
3. Work through the **not-yet-reviewed** batches, appending findings here as they’re found.

> Shared helper worth extracting while fixing the P2s: a single `wholeWordMatch(_,_)` /
> tokeniser reused by the matcher, normalizer, unit converter, and classifier — kills the
> whole substring-conflation bug class in one place instead of four.
> ✅ DONE — extracted as `IngredientWordMatcher` (whole-word, multi-word, plural-aware) and
> adopted by `UnitConversion`, `CategoryClassifier`, and `IngredientNormalizer`. All four
> ingredient-logic P2s in this class are now closed. Optional follow-up: fold
> `KitchenRecipeMatcher`'s own word logic into it (its ≥3-char rule differs, so behaviour-
> preserving only — low priority, already correct and tested).
