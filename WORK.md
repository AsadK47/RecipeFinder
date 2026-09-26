# WORK.md — recipe state consistency (staged)

## This session — DONE + verified (uncommitted, user commits as review step)
Working tree: `BuildProject` green; `RunAllTests` 1609/1611 (the 2 reds are the
known-unrelated sign-in-contrast + groceries-hit-area audit tests — see
[[running-ui-tests]] memory; now failing on retry too, candidate real regression
on those screens, NOT caused by this session's work).

Four logically separate changes (suggest 4 commits):
1. **Full-screen photo viewer** — new `Components/Recipe/FullScreenPhotoViewer.swift`
   (`PhotoViewerSource` + Photos-app-style viewer: paged swipe, pinch/double-tap
   zoom, pan, swipe-down/tap dismiss). Wired into the detail hero gallery
   (`RecipeDetailView+Content.swift`) and photo-manager grid (`RecipePhotoManagerSheet`).
2. **Cook-photo-didn't-show-until-restart fix** — ROOT CAUSE: `RecipeModel.hash(into:)`
   combined only `id`, but `RecipeSearchView.computeFilterHash()` relies on
   `hasher.combine(recipes)` to invalidate `cachedFilteredRecipes` on content change.
   id-only hash → new photo/rating/cookCount left the hash unchanged → stale cards
   until relaunch rebuilt the cache. Fix: `hash(into:)` now mirrors the fields `==`
   compares. (No `Set<RecipeModel>`/dict relies on identity hashing — checked.)
3. **Pull-to-refresh** — `.refreshable` on `RecipeResultsList` → new async
   `refreshRecipesAsync()` in `RecipeSearchView`.
4. **StoreKit scheme fix + guide-adoption config** — both schemes' StoreKit
   `identifier` = `../../../RecipeFinder.storekit`. IMPORTANT: Xcode anchors this
   path at the `.xcscheme`'s OWN directory (`…/xcshareddata/xcschemes/`), so
   `../../../` = repo root where the file lives. This is the value `b582b5a` shipped;
   an earlier mis-fix to a plain `RecipeFinder.storekit` (assuming SRCROOT anchoring)
   BROKE it — do not repeat. The Tests scheme was separately wrong (`../../`), now
   also corrected. Plus `.claude/settings.json` (permission allowlist + `no-combine.sh`
   guard hook); `.gitignore` ignores `settings.local.json`.
5. **Latency: search filtering out of `body`** — `RecipeSearchView` no longer
   hashes the whole library on every body pass. Deleted `computeFilterHash()`,
   `lastFilterHash`, and the `filteredRecipes` computed prop; `recipeContentArea`
   reads the `cachedFilteredRecipes` @State directly. `FilterCacheUpdateModifier`'s
   `onChange(of: filterCriteria/recipes)` (already present) now solely drives
   `updateFilterCache()` → `filterCriteria.apply(to:)`. Seeded the cache in a new
   `init` to avoid a first-frame empty-state flash. NOTE: this supersedes the
   RecipeModel `hash(into:)` enrichment as the stale-card mechanism — staleness now
   clears via `onChange(of: recipes)` (== includes photoNames). The enriched hash is
   kept for Hashable/Equatable consistency but is no longer load-bearing.

## Latency findings NOT yet fixed (backlog, from the sweep)
- **Regex recompiled per call** in import parsers (`RecipeParser(+WPRM/Microdata/
  StructuredData)`, `TextRecipeParser`, `IngredientLineParser`) — hoist each
  `NSRegularExpression` to `static let` (see `IngredientNameFormatter` for the pattern).
- **JPEG encode on main** — `RecipeImageStore.persistGallery` `image.jpegData(...)`
  runs on the calling (main) actor during photo save; offload to a background Task.
- **A few sync Core Data on main** — `getRecipeCount()` in `AccountBadgesSection`,
  `fetchRecipes()` in write-path dedup + App Intents (launch/list path already async).

## RecipeStore — SLICE 1 DONE (uncommitted, verified green)
`RecipeStore` (`@Observable` + `RecipeStoring` protocol + `@Environment(\.recipeStore)`,
`.shared` default) now owns `recipes` + load/seed/refresh/save/add/delete. `ContentView`
delegates to it (removed its `@State recipes`/`isLoadingRecipes`/`loadRecipes`); child
views keep their `@Binding var recipes` API via a store-backed `recipesBinding`. +4
`RecipeStoreTests`. Build + 1615 green.

### SLICE 2 DONE (uncommitted, 1615 green)
Write paths route through the store: RecipeDetailView (addCookPhoto, applyRefresh),
RecipeDetailView+Content (editor onComplete), RecipePhotoManagerSheet.persist,
RecipeSearchView (addRecipe/deleteRecipe + refreshRecipesAsync → store.refresh),
ImportView.store. `recordCook`/`updateRating` still use specialized PersistenceController
ops + onRecipeChange (handle in slice 3).

### SLICE 3 DONE (uncommitted, 1616 green)
`recordCook`/`updateRating` now call `store.sync(recipe)` (new: upsert in-memory, no
re-persist). Every recipe write path goes through the store. `onRecipeChange` still
threaded — its teardown is coupled with Collections (they pass `refreshRecipes` to
`RecipeLink` and hold their own recipe arrays), so do those together.

### SLICE 4 DONE (uncommitted, build green — run full suite before commit)
Deleted all `onRecipeChange`/`onChange` plumbing (RecipeDetailView, RecipeLink,
RecipeResultsList, RecipePhotoManagerSheet, RecipeSearchView, CollectionDetailView,
SmartCollectionDetailView) + their local `refreshRecipes` re-fetches. `toggleFavorite`
now also `store.sync`s (was a missed write path). Edits propagate via the store alone.

### Optional cleanup (low priority — NOT needed for correctness)
Collections/MealPlanning/RecipeSelectionSheet still take `@Binding var recipes`, but it
already points at `store.recipes` (ContentView's `recipesBinding`), so they observe the
store correctly. Swapping them to `@Environment(\.recipeStore)` + dropping `recipesBinding`
is cosmetic — do only if touching those files anyway.

## RecipeStore refactor: COMPLETE (slices 1–4). Store is the single source of truth;
## all writes route through it; no manual refresh callbacks remain.

## (superseded) original plan — reactive `RecipeStore`
User chose STAGED: quick relief now (done above), then replace the fragile pattern.

**Problem:** recipes are the one major entity NOT behind an `@Observable` source of
truth. `ContentView` owns `@State recipes: [RecipeModel]`; every surface holds a
value-type copy and re-syncs only via manual `onRecipeChange` callbacks
(wired in only `RecipeSearchView`, `CollectionDetailView`, `SmartCollectionDetailView`).
Any surface/write path that forgets the callback shows stale data — a whole bug class.

**Plan (follow the existing DI pattern — see the completed slices below):**
1. `@Observable final class RecipeStore` behind a `RecipeStoring` protocol
   (`AnyObject, Observable`), `@MainActor`, `static let shared` as composition-root
   default; private `EnvironmentKey` (`.shared` via `MainActor.assumeIsolated`) +
   `EnvironmentValues` accessor. Same shape as the 8 manager slices already done.
2. Store owns `recipes` + load/save/delete/refresh; writes update the array so all
   observers react. Wrap `PersistenceController` reads/writes.
3. Migrate surfaces off the `$recipes` binding + `onRecipeChange` threading to
   `@Environment(\.recipeStore)`. Delete `onRecipeChange` plumbing
   (`RecipeLink`/`RecipeResultsList`/`RecipeDetailView`) once nothing needs it.
4. `RecipeDetailView` reads/writes through the store instead of its private `@State recipe`.
5. Tests: add a store suite (load/write-propagation/delete); keep `RunAllTests` green.
   Verify: `BuildProject` + `RunAllTests`, then manual — cook a photo, confirm the
   list card updates live WITHOUT the hash band-aid doing the work.

WIP=1: do NOT start the store refactor until the above 4 commits are in.

---
## Reference — completed view-level DI campaign (pattern to reuse for RecipeStore)
All 8 manager slices migrated `ObservableObject` → `@Observable` + protocol seam +
`@Environment` key defaulting to `.shared` (RecipeTimerManager, AccountManager,
BadgeManager, CollectionManager, KitchenInventoryManager, ShoppingListManager,
MealPlanningManager, AuthenticationManager). ThemeManager was dead plumbing → deleted.
`RecipeStore` is the natural next application of this exact pattern.
