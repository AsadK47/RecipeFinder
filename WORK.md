# WORK.md — ACTIVE: Recipe Wizard rework

> Newest task on top. The DI-refactor section below is prior, mostly-committed history — keep it.

## Status
NOT STARTED. This session already shipped + verified (BuildProject + RunAllTests
green, 1596 tests): the sign-in freeze fix, cook-photo-on-card (`heroImageName`),
detail re-read on appear, loading skeleton, StoreKit paywall (scheme wiring +
`ProductLoadState` retry UI), timer one-tap start, and recipe photo editing
(`RecipePhotoManagerSheet`). All uncommitted — user commits as their review step.

## The problem (user's words)
"recipe wizard clearly needs to be modularised because you need to keep clicking
Next to save anything, and clicking prep time / cook time etc doesn't take you to
that section."

Two sub-problems:
1. **Save-anytime**: `RecipeWizardView` is a linear 6-step stepper (`currentStep`
   0–5, Back/Next `navigationButtons`, save only in `createRecipe()` at the last
   step). User wants to save with just what they've filled in.
2. **Deep-link to section**: tapping the prep/cook/details info cards on
   `RecipeDetailView` (`editableCard` → `beginEdit` → `showEditSheet`) opens the
   editor at the top, not scrolled to the tapped field.

## Key files
- `Views/Recipes/RecipeWizardView.swift` (360 lines) — linear CREATE flow;
  `stepContent` switch on `currentStep` 0..5; `createRecipe()` builds+saves via
  `RecipeWizardBuilder`. Preserve `applyPrefilledData` + `RecipeWizardBuilder.build`.
- `Views/Recipes/RecipeDetailView+Content.swift` — `editableCard` on time/details
  cards → `beginEdit()` → `showEditSheet`. Check what `editRecipeSheet` opens
  (wizard vs a separate single-form editor) BEFORE choosing an approach.

## Design fork (decide first)
- **Option A (recommended): single scrollable sectioned form** with a persistent
  Save (validates required fields: name + ≥1 ingredient + ≥1 step). Deep-link via
  `ScrollViewReader` to a section id. Solves both sub-problems; modularise each
  step into its own section View. Keep `RecipeWizardBuilder` as the save path.
- **Option B: keep the stepper, make it non-linear** (tappable progress steps +
  always-enabled Save). Smaller, but deep-linking stays clunky.

## Suggested plan (Option A)
1. Extract each step body into its own small section View (the "modularise" ask).
2. Compose in one `ScrollViewReader { ScrollView { section(id:)… } }`.
3. Replace Back/Next with an always-visible primary Save (reuse `createRecipe`
   validation). Keep Cancel.
4. Add an optional open-at-section anchor so `RecipeDetailView` info-card taps map
   to a section id.
5. Tests: `RecipeWizardBuilderTests` / `RecipeWizardPersistenceTests` already cover
   build/save; add a "save with only required fields" validation-gating test. UI
   layout is test-exempt. Verify: BuildProject + RunAllTests; manually save a
   minimal recipe and confirm a prep-time card tap opens focused on Time & Servings.

---

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
- [x] #9  slice 5 — KitchenInventoryManager (KitchenSectionsView, MealPlanningView, KitchenShoppingView, ShoppingSectionsView, KitchenQuickAddSheet, PantryAlertsSectionContent) ✅ DONE — build + 31/31 kitchen tests green
- [x] #10 slice 6 — ShoppingListManager (ShoppingSectionsView, KitchenShoppingView, ShoppingQuickAddSheet) ✅ DONE — build + 33/33 shopping tests green; last `.environmentObject` (dead) dropped from SettingsView preview
- [x] #11 slice 7 — MealPlanningManager (MealPlanningView) ✅ DONE — build + 21/21 meal-planning tests green
- [x] #12 slice 8 — AuthenticationManager + AppleSignInManager + final sweep ✅ DONE — build + FULL 1584/1584 green + FINAL SWEEP: direct `PersistenceController.shared.fetchRecipes()`/`getRecipeCount()` in ContentView/RecipeSearchView/AccountBadgesSection, remaining ObservableObject (SubscriptionManager/NetworkMonitor/RecipeImporter as needed), reconcile root CLAUDE.md line with RecipeFinder/CLAUDE.md:59.

## Verification cadence (user directive — keep the loop fast)
Per slice: `XcodeRefreshCodeIssuesInFile` on each touched file → `BuildProject` →
`RunSomeTests <that manager's suite>` ONLY (build catches ~all view-wiring failures; the
suites cover manager-logic regressions). Do ONE `RunAllTests` at the very end, after all DI
slices are done. Do NOT run the full 1584-suite per slice.

## STATUS: view-level DI campaign COMPLETE (all 8 slices). Slices 1–7 committed by user;
slice 8 (auth + sweep) uncommitted, awaiting user's review/commit. Full 1584/1584 green.

## Follow-ups discovered
- **ThemeManager DI** — ✅ RESOLVED (not a migration): it turned out to be entirely DEAD plumbing.
  Nothing consumed it (`@EnvironmentObject`/`@Environment(\.themeManager)`/member access all zero;
  `withThemeManager()` unused; its `.themeDidChange`-family notifications had no observers). Theming
  actually runs through `@AppStorage("appTheme"/"cardStyle"/"appearanceMode")` + is inherently
  reactive. DELETED the `ThemeManager` class, its `EnvironmentKey`/`\.themeManager` value,
  `withThemeManager()`, the dead `Color.adaptiveText` extension, the 3 dead `Notification.Name`s,
  and `AppRootView`'s `@StateObject` + 3 `.environmentObject(themeManager)` sites. KEPT the widely
  used `CardStyle` (49 files) + `AppearanceMode` enums in Theme/ThemeManager.swift. Build + 1584 green.
- Left as composition-root/data-layer (intentional, documented in CLAUDE.md): direct
  `PersistenceController.shared.fetchRecipes()/getRecipeCount()` in ContentView/RecipeSearchView/
  AccountBadgesSection; `RecipeImporter()` is view-OWNED (`@StateObject` fresh instance, not a
  singleton). SubscriptionManager/NetworkMonitor are not observed by any view → no migration needed.

## In progress
Slices 1 (#5) + 2 (#6) + 3 (#7) + 4 (#8) + 5 (#9) + 6 (#10) + 7 (#11) + 8 (#12) COMPLETE in the working tree and verified green.
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
View-level DI campaign + ThemeManager cleanup all COMPLETE and green. Nothing in progress —
commit this ThemeManager-deletion change, then pick up a different backlog item (see the
`.appCard()` card-migration deferred backlog below, or ROADMAP).

Optional tidy (not done): `Theme/ThemeManager.swift` now only holds `CardStyle`/`AppearanceMode`
enums — the filename is a misnomer; rename to `ThemeEnums.swift` via `XcodeMV` if desired.

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

## Deferred backlog (carried over from prior session)
**`.appCard()` card-migration** (slice 1 committed `3c20e26`) — REASSESSED & LARGELY CLOSED.
Verified the remaining "slices" against the actual code; the premise was a misread:
- slice 2 `systemGray6` sites (NotesStepView 109/187/252, IngredientsStepView 89/131) are
  input-field / picker CHROME (TextFields; a stroked Picker), NOT card tiles → `.appCard()`
  (frosted `.ultraThinMaterial`) would regress them. LEFT as-is.
- slice 3 `white.opacity` sites: `RecipeServingsCard` is already a `GlassCard` (its sites are a
  Divider tint + a segment-button fill); `RecipeNameStepView` sites are field chrome. LEFT as-is.
- `cardBackground` vs `adaptiveCard` are NOT redundant: solid/near-opaque (0.95 / `#1C1C1E`) vs
  translucent (low opacity), plus `adaptiveCardMedium/High`, `elevatedCard`. Collapsing them
  flattens a deliberate solid-vs-translucent distinction → needs a design call, not a merge.
- ONLY arguable real target left: `LegalContactCard` inner button-rows (51, 82) → could be
  `.appCard(cornerRadius: 12)`, but it's a marginal faint-tint→material change. Not done.
- Net: genuine card surfaces already route through `GlassCard`/`.appCard()`/settings tiles.
  Treat this backlog as DONE unless a specific screen looks visibly off. Optional future work:
  an `.appInputField()` token to unify the `systemGray6` form-field chrome (separate concern
  from cards).

**RESOLVED this session** (was flagged here as "investigate"): the
`RecipeImageStoreTests` relative-path failures — fixed by asserting against
`store.absolutePath(for:)` (production was correct; the test was wrong).
