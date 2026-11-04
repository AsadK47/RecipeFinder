# WORK: New-user exploratory QA (2026-11-03) — PAUSED mid-run

## ▶ Resume here
Working tree clean before this file (all prior work committed: 184b2ed). No code changes in progress.

**Status:** Both testers DONE (2026-11-04). Run testers sequentially, never in parallel (shared run destination).

### 🔴 — ALL FIXED 2026-11-04 (uncommitted; full suite 1827/1827 green)
1. Edit dropped isSampleRecipe/rating/dietaryInfo/cook history → `RecipeWizardBuilder.mergeEdit` at the single edit
   save point (RecipeDetailView+Content editRecipeSheet). Test: RecipeWizardBuilderTests.mergeEditPreservesUneditedFields.
   Dev devices that already edited bundled recipes keep the bad flag until Settings → Reset (now works).
2. Grocery redraw → ShoppingListModel uses synthesized ==/hash (lookups already by id). Test updated/added.
3. Guest Reset → nil userId = guest scope in `clearDatabase` (ownerPredicate + merge batch-delete IDs) and
   `clearCurrentUserData` ("no_user_" prefix); reset reloads via `recipeStore.load` (re-seeds starters + bundled) instead
   of legacy `populateDatabase`. **Decision reversed:** 2026-10-30 left clearDatabase refusing nil scope; that made the
   confirmed user reset a silent no-op. Guest predicate can't touch account rows (test asserts it).

### Next action — cheap 🟡 first (one at a time)
a. Ticks stay on row positions after edit (RecipeDetailView onChange resets only on count change) — reset on content change.
b. Notification prompt on every launch (ContentView.onAppear) — remove; contextual asks already exist.
c. Backup/restore feedback off-screen → alert near buttons + spinner during export.
d. "Ingredi-ents" / "Purpl/e" wraps; Filters "Kitchen tab" copy dead-end; Update-from-Source toggle colour.
e. Cooking timer sums all durations in a step. f. Difficulty vocab (Medium vs Basic/Intermediate/Expert).
Watch: Ingredient & RecipeModel also use partial == (possible stale-UI, not yet observed).

## Findings — tester A (iPhone 18 Pro, core loop) — no crashes; edit crash fix confirmed
### 🟡
- Ticks land on wrong items after edit (state keyed by position, reset only on count change).
- Cooking-mode timer sums every duration in a step ("6 hours, up to 48 hours" → 3240 min) — CookingModeView.cookTimerMinutes l.48.
- Difficulty vocab mismatch: bundled "Medium" vs editor Basic/Intermediate/Expert; "Easy Recipes" collection + RecipeSearchView.swift:74 filter never match "Medium".
- Parse quality: section headers/equipment as ingredients ("For Serving:", "Baking Rack"); "Plain whole-milk greek yogurt" → name "Plain"; source notes/nutrition become steps; all bundled category "Main", no cuisine; junk titles (Chapati PREP TIME…, paella "Serves 2.0…", "18.0 bites serving", URLs in titles, garbled Thai).
- Nutrition estimate contradicts source figures shown above it.
- Editor shows "0.333333"; notes Title-Cased ("Such As Grapeseed Oil"); cooking mode ignores Imperial.
- Filters: "Add ingredients in the Kitchen tab first" but no Kitchen tab; What Can I Make toggle dead-ends (FilterSheet.swift:116).
- Update-from-Source toggles render as off while on.
- Lemon juice from recipe → groceries "2", no unit, "Beverages".
### 🟢
Delete only via long-press, no undo; edit cancel no discard prompt; new collection from Add-to-Collection doesn't add the recipe; Timer/Collections sheets no close; sort resets on relaunch; a11y (steps no checked state, photo remove "Close", nested "Drag"); no rating prompt; no onboarding.
### Verified OK
Instant first-launch library w/ images, search, sort, scaling, units, ticking, substitutions, groceries add, favourite, collections incl. smart, View Original, cooking mode + timer, confetti/badges, cook count + Cooked today, persistence across relaunch, delete w/ confirm.

## Findings — tester B (iPhone 17e, fresh install, guest)
### 🔴
1. **Grocery check-off / +− qty don't redraw** — persists but row doesn't update; users re-tap and toggle back.
   Cause: `ShoppingListModel` `==` compares `id` only → SwiftUI skips row diff.
2. **Settings → Data → "Reset to Default" is a no-op for guests but reports success** — `clearAllRecipes` /
   `clearCurrentUserData` / `populateDatabase` early-return on nil userId (log: "No user logged in, skipping database
   clear"); recipe list not reloaded. (Guest scope = userId nil since the 2026-10-30 guest-persistence fix.)
### 🟡
3. Notification permission requested on every launch — `ContentView.onAppear` (~l.57); timer + reminder already ask in context.
4. Groceries drop units/decimals: "1.5 tbsp olive oil" → "Olive Oil 2", "200g" → "200"; qty Int, + disabled at 200 (max 99).
5. "View all badges" no-op — `ContentView.swift:114–121` presents a sheet while another dismisses.
6. Recipe detail "Ingredients" header wraps "Ingredi-ents" (squeezed by edit/cart/Metric buttons).
7. Theme "Purple" wraps "Purpl/e" when selected (checkmark).
8. Backup export/import feedback off-screen at bottom, 2s auto-hide; export 3–5s with no spinner.
9. Paste import invents 15+30 min times and "Intermediate" (seeds use "Medium") — known backlog item.
10. URL import saves with no review step and no jump-to-recipe; only a badge sheet shows.
11. Kitchen: no way to set expiry dates though Help says you can.
12. Meal reminders only via long-press; tapping a planned meal swaps it; can't open the planned recipe.
13. Seed data: "Easy & Simple Apam Balik…" title contains whole description; "American pancakes" shows "585 minutes".
### 🟢
Search ~1s lag + refocuses keyboard on back; tiny tap targets (tip ✕ 9pt, planner trash 14pt); keyboard-dismiss FAB
covers "Add"; "(0/1)" grocery count confusing; raw "unsupported URL" error; manual editor cancel discards without
confirm; "Validation Error" titles; Import inbox icon looks tappable; Kitchen sheet no close; generic category icons;
Account avatar blank vs "RC"; locked badges low contrast/no hint; reminder sheet translucent bleed; menu button a11y
label "Drag"; recipe row a11y reads prep time not total; low-contrast orange-on-blue and grey alert text.
### Verified OK
Paste import (1.5 tbsp survives), garbage/blank paste, BBC URL import + photo, invalid URL error, OCR graceful fail,
manual validation, search, groceries from suggestions/recipe, kitchen add, What Can I Make, meal plan add/reorder/
delete/reminder, badges, dark mode/themes, settings rows, privacy policy, reset confirm dialog. No crashes.
