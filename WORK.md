# WORK: Pre-TestFlight fixes (from SHIP_BAR checklist pass, 2026-10-30)

## ▶ Resume here
All below is UNCOMMITTED (user reviews + commits). Last full suite: 1829/1829 green.

### Done this session
1. **test(ui) a11y audit fix** — grocery search targeted by `groceries.search` id (`AppSearchField.accessibilityID`);
   `launchAuthenticated()` swipes away a launch "BADGE EARNED!" sheet (matched case-insensitively — title is uppercased).
2. **🔴 Guest recipes lost on relaunch + missing from backup** — guest-only build: every user is a guest
   (`userID()` nil). `RecipeStore` guest path showed in-memory `SeedRecipeProvider` only; `fetchRecipes*` returned []
   for nil scope. Fix: nil userId = guest scope (`PersistenceController.ownerPredicate` → `userId == nil`), used by all
   fetch/count/id predicates + `seedRecipes`; `RecipeStore` guests use the same fetch/seed path (`isGuestLibrary`
   tracks guest↔account switch). Tests: RecipeStoreTests (relaunch, scope isolation, guest backup),
   PersistenceControllerTests (2 tests rewritten to new contract).

### Decisions
- Guest scope = rows with `userId == nil` (mirrors UserScopedStorage "no_user"), NOT a generated guest UUID —
  smaller change, keeps existing tester data, no scope migration. Guest→account migration on future sign-in is OUT of
  scope (sign-in UI hidden until enrolment).
- Guest id predicates now `id AND userId == nil` (was id-only) — seed UUIDs are shared, id-only let a guest write land
  on an account's row.
- `clearDatabase()` still refuses nil scope (destructive — left deliberately).

3. **🟡 fixes (all done, full suite 1835/1835 green):**
   a. `BadgeCard` shows full title (2 lines) — was first word only.
   b. `RecipeModel.wasCookedToday()` → "Mark as Cooked" becomes disabled "Cooked today" (id `recipe.markCooked`);
      HabitLoop UI test taps only if enabled (sim state isn't reset between runs).
   c. Last-cooked uses `.relative(presentation: .named)` ("2 minutes ago").
   d. `RecipeImportStore`: `.paste` awards no badge (Link Master is web-only).
   e. Collection badges exclude starters: `BadgeMetrics.recipesCollected` filters `isSampleRecipe`;
      `saveRecipe` uses new `fetchCollectedRecipeCount()`. (Needed now that guest seeds persist.)

### Backlog (not cheap)
- Paste import shows wizard defaults (Intermediate/4 servings/15+30 min) — wizard fields are non-optional Ints;
  making them "unset" touches wizard + builder + persistence.
- Stacked sheets in paste import; VoiceOver labels; misc layout (chat report 2026-10-30).

### Next action
Hand-verify on simulator: guest adds recipe → relaunch → still there; export backup contains it; restore.
