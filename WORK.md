# WORK.md — View-level DI refactor (backlog #1)

## Goal
Remove `.shared`-singleton binding from the view layer so Views depend on injected
seams, resolving the root `CLAUDE.md` "Views depend on protocols, not `.shared`
singletons" rule. Approach chosen by user: **full view-level DI, `@Observable`-first,
one manager per slice**, each slice `BuildProject` + `RunAllTests` green + independent
agent verification before the next.

## Why this shape (decisions)
- **`@Observable`-first is required, not optional.** SwiftUI's `@ObservedObject`/
  `@StateObject`/`@EnvironmentObject` bind to *concrete* `ObservableObject` types, not
  protocols, and the managers are `final` (no test-double subclass). So protocol
  injection is impossible while they stay `ObservableObject`. Migrating each manager to
  the `@Observable` macro unlocks `@Environment`-based injection with a protocol
  existential. (This resurrects the `@Observable` migration we earlier deferred as
  "unnecessary" — it is a prerequisite for full DI specifically.)
- **Rejected**: forcing protocol injection onto `ObservableObject` (hacky/type-erasure,
  fights SwiftUI) and docs-only reconcile (user wants the real refactor).
- **Note for honesty**: the project's *stated* DI philosophy (`RecipeFinder/CLAUDE.md:59`)
  is *manager-level* injection (`init(storage: .shared)`), which the managers already do —
  their logic is testable with fakes today. This view-level DI enables view fakes the
  current test strategy doesn't use. Proceeding anyway per user's explicit choice.

## Per-slice recipe (repeat for each manager)
1. Manager: `ObservableObject` → `@Observable final class`; drop `@Published` (plain vars).
   Keep `@MainActor`. Keep `static let shared` as the composition-root default.
2. Add a protocol seam (e.g. `RecipeTiming`) the manager conforms to.
3. Add an `EnvironmentValues` key defaulting to `.shared` (existential of the protocol).
4. Consuming views: `@StateObject/@ObservedObject private var x = X.shared` →
   `@Environment(\.<key>) private var x`. Owner (app root) injects once via
   `.environment(\.<key>, .shared)`.
5. Fix all `#Preview`s that constructed the view (inject the concrete `.shared` or a fake).
6. `XcodeRefreshCodeIssuesInFile` on each touched file → `BuildProject` → `RunAllTests`
   → spawn agent to verify. Only then mark the slice task done.

Gotchas: `@Observable` + `@Bindable` for two-way bindings (was `$manager.x`); a shared
singleton observed in many views is injected once at root and read via `@Environment`
(NOT re-created per view). `SettingsView` already uses `.environmentObject(ShoppingListManager.shared)`
— replace that too.

## Slice order (task IDs)
- [x] #5  slice 1 — RecipeTimerManager (self-contained; RecipeDetailView, CookingModeView, CookTimerView) ✅ DONE — build + 1584/1584 green
- [x] #6  slice 2 — AccountManager (AccountView, SettingsView) ✅ DONE — build + 1584/1584 green
- [x] #7  slice 3 — BadgeManager (AccountView, ContentView, AccountBadgesSection) ✅ DONE — build + 35/35 badge tests green
- [x] #8  slice 4 — CollectionManager (RecipeSearchView, CollectionDetailView, CollectionsInlineView, AddToCollectionSheet, RecipePickerForCollectionSheet, CollectionFormSheets) ✅ DONE — build + 20/20 CollectionManager tests green
- [ ] #9  slice 5 — KitchenInventoryManager (KitchenSectionsView, MealPlanningView, KitchenShoppingView, ShoppingSectionsView, AddIngredientSheet) ← **NEXT**
- [ ] #10 slice 6 — ShoppingListManager (ShoppingSectionsView, KitchenShoppingView, ShoppingQuickAddSheet; SettingsView environmentObject)
- [ ] #11 slice 7 — MealPlanningManager (MealPlanningView)
- [ ] #12 slice 8 — AuthenticationManager + AppleSignInManager (largest) + FINAL SWEEP: direct `PersistenceController.shared.fetchRecipes()`/`getRecipeCount()` in ContentView/RecipeSearchView/AccountBadgesSection, remaining ObservableObject (SubscriptionManager/NetworkMonitor/RecipeImporter as needed), reconcile root CLAUDE.md line with RecipeFinder/CLAUDE.md:59.

## Verification cadence (user directive — keep the loop fast)
Per slice: `XcodeRefreshCodeIssuesInFile` on each touched file → `BuildProject` →
`RunSomeTests <that manager's suite>` ONLY (build catches ~all view-wiring failures; the
suites cover manager-logic regressions). Do ONE `RunAllTests` at the very end, after all DI
slices are done. Do NOT run the full 1584-suite per slice.

## In progress
Slices 1 (#5) + 2 (#6) + 3 (#7) + 4 (#8) COMPLETE in the working tree and verified green.
Uncommitted, awaiting the user's review/commit. Established pattern (repeat per slice):
manager → `@Observable` + `@ObservationIgnored` on non-observed stored props; protocol seam
(`AnyObject, Observable`); private `EnvironmentKey` whose `defaultValue` returns `.shared`
via `MainActor.assumeIsolated`; `extension EnvironmentValues` accessor; consumers swap
`@StateObject … .shared` → `@Environment(\.<key>)`. Child views that received the manager as
`@ObservedObject var x: Concrete` become `let x: any <Protocol>` (slice 3: AccountBadgesSection).
No explicit root injection needed (default covers it). One-off `.shared` method calls that
aren't observed view state are LEFT as-is (composition-root use): `DataManagementSettingsView`
→ AccountManager; `CookingModeView`/`ImportView`/`AccountManager.unlockWelcomeBadge()` →
BadgeManager.

## Next action
Start slice 5 (#9): KitchenInventoryManager → `@Observable` + protocol seam +
`EnvironmentValues` key (default `.shared`); swap consumers (KitchenSectionsView,
MealPlanningView, KitchenShoppingView, ShoppingSectionsView, AddIngredientSheet) to
`@Environment`, converting child `@ObservedObject var x: KitchenInventoryManager` params to
`let x: any <Protocol>`. NOTE: `SettingsView` injects `.environmentObject(KitchenInventoryManager.shared)`
(line ~187) — that `@EnvironmentObject` consumer chain must move to `@Environment(\.<key>)`
too, and the `.environmentObject(...)` call be dropped. Check for `$`-bindings (AddIngredientSheet
may two-way bind quantity/name → `@Bindable`). Verify via cadence (build +
`RunSomeTests KitchenInventoryManagerTests`).

## Session state (uncommitted — user commits as their review step)
Working tree GREEN (build + 1584/1584) as of task #2. Completed & awaiting the user's
commits — do NOT re-do:
- ThemeManager: dropped redundant Combine import + duplicate mid-file imports
- Account/ShoppingList/MealPlanning managers: dropped redundant `import Combine`
- RecipeImageStoreTests: assert against resolved absolute path (test fix)
- SharedImportInboxTests: `encoded` helper now throwing (last force-try gone)
- 11 destructive/error `.red` → `AppTheme.error` (9 view files)
- CookingMode: memory reconciled to "shipped/live" (docs only, outside repo)
CLOSED no-change: oversized-views task — the 4 big views delegate logic to tested types.

---

## Deferred backlog (carried over from prior session — NOT this task)
**`.appCard()` card-migration** (slice 1 committed `3c20e26`). Remaining slices, still TODO:
- slice 2 = wizard `Color(.systemGray6)` tiles (NotesStepView ×6, IngredientsStepView).
- slice 3 = `Color.white.opacity` frost sites (RecipeServingsCard, LegalContactCard,
  RecipeWizardView+Chrome, RecipeNameStepView).
- Eventually route SettingsCard/CardView through `.appCard()` and collapse AppTheme's two
  card tokens (`cardBackground` + `adaptiveCard`) into one.
- Decision on record: canonical card = frosted `.ultraThinMaterial` (user's choice).

**RESOLVED this session** (was flagged here as "investigate"): the
`RecipeImageStoreTests` relative-path failures — fixed by asserting against
`store.absolutePath(for:)` (production was correct; the test was wrong).
