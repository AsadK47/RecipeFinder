# Core loop audit — import → find → cook → track

Captured 2026-09-26. Goal: make the core loop *flawless* before adding breadth.
Findings from a 4-stage code audit. Ranked; each has file:line + a one-line fix.
⚠️ = likely real bug (verify then fix). ✎ = UX/polish judgement.

## Top cross-cutting priorities (fix these first)
*Done items trimmed 2026-10-01 — history is in git. Still open:*
- ✎ **Search filters on every keystroke, no debounce** — list flickers while typing
  (`RecipeFilterCriteria.swift:65`, `RecipeSearchModifiers.swift:58`). Fix: debounce ~250ms.
  (Same concern as WORK.md punch-list item 4 — owned there, not duplicated.)
- ↓ Low-pri residue: index-based cook/check state can misalign on a mid-list insert
  (`RecipeDetailView.swift:156` guard only resets on ingredient count change). Revisit if it bites.

## Import / add
- ⚠️ No parse-confidence surfaced — 20%-confidence and 95% save identically (`RecipeImporter.swift:49`). Show a confidence badge + warn <60%.
- ✎ Paste-text failure loses the text and shows a generic error with no retry/edit-in-place (`PasteTextImportSheet.swift:86`). Keep text; show what parsed; add Retry.
- ✎ Fake staged progress % (33→66→100) feels stuck on slow fetch (`RecipeImportView.swift:40`). Use stage labels / indeterminate.
- ✎ Duplicate detection is name-only (`RecipeImportView.swift:348`). Compare content or show existing-vs-new before saving.
- ✎ Wizard Cancel after prefill discards edits with no confirm (`RecipeWizardView.swift:134`). Add unsaved-changes guard.

## Find / browse
- ✎ Ingredient search + "What can I make?" are buried in FilterSheet and clash with the main name-search field (`FilterSheet.swift:100`). Split/clarify the two intents.
- ✎ Sort is hidden in the filter sheet with no on-screen affordance (`FilterSheet.swift:42`). Surface "Sorted by …".
- ✎ "Can Make Now" silently overrides the chosen sort with match-% ranking, unexplained (`RecipeFilterCriteria.swift:122`).
- ✎ "Can Make Now" disables with only a caption when pantry is empty; no deep-link to Kitchen (`FilterSheet.swift:110`).
- ✎ Empty state doesn't distinguish "no matches" vs "keep typing" vs "filters too tight" (`RecipeEmptyStateView.swift:19`).
- ✎ Difficulty filter is hardcoded `["Basic","Expert","Intermediate"]` — may not match data (`RecipeSearchView.swift`). Derive from recipes.

## Cook
- ⚠️ Quantity tap-to-edit is live in cook mode too — accidental edit taps instead of check-off (`IngredientRowView` used by `CookingModeView:189`). Pass `onTapQuantity: nil` in cook mode.
- ✎ Timer step-button only appears when a number is found; no "set custom time" fallback (`CookingModeView.swift:232`).
- ✎ Idle-timer stays disabled for the whole cook-mode session, not just while a timer runs (`CookingModeView.swift:100`).
- ✎ Progress bar counts the ingredient-list screen as "step 1", so counts feel off-by-one (`CookingModeView.swift:41`).

## Track / after cooking
- ✎ No "Marked as cooked" confirmation when the photo sheet is skipped (`PostCookPhotoSheet.swift:103`).
- ✎ Rating + photo are disjointed — no post-cook rate prompt; must scroll to the history card (`RecipeDetailView.swift:273`). Consider a compact cook→rate→photo flow.
- ✅ FIXED (uncommitted) Grocery merge dropped the unit ("flour 6" unitless). `ShoppingListManager.addItem` now threads `unit` and merges on name+unit (`ShoppingListFromRecipeTests` +3).
- ✎ Meal-plan → groceries loses unit context and is binary vs kitchen stock (has-any skips the item even if you need more) (`MealPlanningManager.swift:255`, `MealPlanningView.swift:305`).
- ✎ No visible link that groceries came from a meal plan (`MealPlanningView.swift:244`).

## Suggested order
1. id-based cook/check state (correctness).  2. timer guards + inline pill + time parse.
3. import-review-instead-of-silent-save + confidence.  4. grocery unit carry-through.
5. search debounce + sort/ingredient-search clarity.  6. post-cook rate/photo/confirm polish.

*Note: line numbers are from the audit pass; confirm before editing. Some ✎ items are
judgement calls — decide the interaction, don't just patch.*
