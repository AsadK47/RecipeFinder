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

- 🟡 Backup/restore success message renders at the bottom of Data Management (below the fold, timed) — user
  sees no feedback after Export/Import. Move to an alert/toast near the buttons.
- 🟢 Guests upgrading from a pre-fix build get no starter recipes (seeding requires an empty library). Dev devices only.
- 🟢 Recipe row VoiceOver reads prep time while the row shows the total time.

### Verified by hand (simulator, 2026-10-30)
Guest recipe + cook count survive relaunch; backup JSON contains guest recipes; restore is non-duplicating;
"Cooked today" lock works; full badge titles; no Link Master on paste. SHIP_BAR checklist: all items pass.

### Decisions (2026-11-03)
- **App is free; RecipeFinder+ scrapped** (ROADMAP.md "Business model" updated). Bundled recipes go to everyone.
- `recipes_seed.json` (355, personal collection, ~242 with source URLs) stays bundled — user accepted the copyright
  risk for a free app; don't relitigate. Source URLs kept (useful for crediting + hotlinked photos).
- Recipe photos: hotlink the source page's image at runtime with credit — never bundle third-party photos.

### Done 2026-11-03 (UNCOMMITTED — full unit suite 1822/1822 + UI launch/habit/import/a11y 9/9 green)
1. **Fresh install shows all recipes.** `recipes_source.json` (raw, test-only, NOT bundled) → generator
   `BundledRecipeCatalogTests` → committed `recipes_seed.json` (341 structured recipes, stable SHA-derived ids,
   `isSampleRecipe`). `RecipeStore.seedIfNeeded` seeds starters (empty library) + bundled once per scope
   (`bundledRecipesSeeded_v1`, skips existing ids → existing installs get them too). Drift test rewrites the
   JSON + fails when source/parser changes — re-run after. Removed `PersonalRecipeSeedService` (sign-in +
   Settings → Data "Import My Recipes" paths) — superseded.
   - **Parser bug fixed:** `TextRecipeParser` stripped "1." from decimals ("1.75 tbsp" → 75 tbsp) as a list
     marker. Affected all paste/OCR imports. 6 recipes left `seed_parse_known_poor.json` as a result.
2. **Source photos:** `tools/seed-images/fetch_seed_images.py` → `recipes_source_images.json` (source URL →
   image URL, 170/239 resolved; rest are bot-blocked sites → placeholder). Generator sets `imageName` to the
   https URL — hotlinked via Kingfisher, never bundled. 168 bundled recipes have photos.
3. **Paywall deleted:** SubscriptionManager, PaywallView, PremiumGate(+tests), Settings upgrade card, import +
   meal-reminder gates, `.storekit` + scheme refs.
4. **PrivacyInfo.xcprivacy** for app (UserDefaults CA92.1 + 1C8F.1, FileTimestamp C617.1) and share extension
   (1C8F.1); `ITSAppUsesNonExemptEncryption = NO`. Verified both land in the built bundles.

### Known / backlog
- 🟢 "Chocolate mousse" source has `51.72 Cup of granulated sugar` (bad source data, not parser).
- 🟢 Scheme files edited (StoreKit ref removed) — quit + reopen Xcode so it reloads them.

### Next action
User reviews + commits, then TestFlight (paid enrolment + switch signing to RecipeFinder Limited).
