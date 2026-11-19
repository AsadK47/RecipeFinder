# RecipeFinder architecture

Last checked against code: 2026-11-16. Lists below name what exists today; the grep next to each finds the current set.

A map of how the app is put together, for developers and agents. Rules and conventions live elsewhere — this
doc links to them rather than repeating them:

- [`CLAUDE.md`](../CLAUDE.md) — hard constraints, build/verify order, branch policy, Core Data version guardrail
- [`RecipeFinder/CLAUDE.md`](../RecipeFinder/CLAUDE.md) — Swift/SwiftUI rules, error handling, DI, UX checklist
- [`RecipeFinderTests/CLAUDE.md`](../RecipeFinderTests/CLAUDE.md) — Swift Testing conventions and coverage
- [`docs/PRODUCT.md`](PRODUCT.md) — what each tab is for and the roadmap
- [`RecipeFinder/DesignSystem.md`](../RecipeFinder/DesignSystem.md) — visual tokens

## Where to start reading

| File | Why |
|---|---|
| `RecipeFinder/RecipeFinderApp.swift` | `@main` app: launch order, iCloud reload wiring, history purge; `AppRootView` (onboarding vs. main UI) |
| `RecipeFinder/Views/Main/ContentView.swift` | Root `TabView` (iPhone) / `NavigationSplitView` (iPad), "+" sheet, `.recipefinderrecipe` file opening |
| `RecipeFinder/Views/Main/AppTab.swift` | The five tabs (Today, Recipes, Plan, Groceries, Me) and notification → tab routing |
| `RecipeFinder/Persistence/Core/PersistenceController.swift` | Core Data stack, store options, load/recovery |
| `RecipeFinder/Utilities/Managers/RecipeStore.swift` | The recipe library: load, seed, save, delete |
| `RecipeFinder/Persistence/Core/MirroredSnapshot.swift` | How every non-recipe list (plans, groceries, kitchen…) is stored and synced |
| `RecipeFinder/Utilities/Recipe/RecipeImportPipeline.swift` | Web import core shared with the share extension |

## Layers and DI seams

```
 Presentation   Views/, Components/            SwiftUI only
      │  @Environment(\.recipeStore), \.mealPlanning, …  (protocol seams)
      ▼
 Managers       Utilities/Managers/, Persistence/Managers/ (+ MadeItPresenter)    @Observable, @MainActor
      │  *Storing protocols / PersistenceController
      ▼
 Data           Persistence/Core (Core Data, CloudKit), LocalStore (UserDefaults), Services/ (URLSession, Vision)

 Domain logic   Models/, Utilities/Recipe/   value types and pure enums, used by every layer
```

- **Environment seams.** Each manager is an `@Observable` class behind a protocol with an `EnvironmentKey`
  defaulting to `.shared`: `recipeStore: RecipeStoring`, `badges: BadgeManaging`, `profile: ProfileManaging`,
  `kitchen: KitchenInventoryManaging`, `mealPlanning: MealPlanningManaging`, `collections: CollectionManaging`,
  `shopping: ShoppingListManaging`, `cookingStreak: CookingStreakTracking`, `recipeTimer: RecipeTiming`, `cookingTimers: CookingTiming`,
  `madeItPresenter: MadeItPresenting` (current set: `grep -rn "extension EnvironmentValues" RecipeFinder`). Tests
  and previews override them with `.environment(\.key, fake)`.
- **Store seams.** Managers take a `LocalStore` and a store protocol in `init` (e.g.
  `CollectionManager(storage:collectionStore:)`); production uses `CoreData*Store` (`CoreDataCollectionStore`,
  `CoreDataMealPlanStore`, `CoreDataShoppingListStore`, `CoreDataKitchenStore`, `CoreDataProfileStore`,
  `CoreDataCookDateStore`, `CoreDataEarnedBadgeStore`). Every list-store protocol refines `StoreFileIdentifying` (`RecipeStoring`, the manager seam, does not).
- **Service seams.** `HTMLFetching` (`Services/HTMLFetcher.swift`), `RecipeImageTextRecognizing` (Vision OCR),
  `RecipeTextInterpreting` (on-device model), `RecipeBackupStore` (backup).
- **`LocalStore`** (`Utilities/Managers/LocalStore.swift`) wraps `UserDefaults`; every key is namespaced `rf.<key>`
  so `clearAll()` only removes keys it wrote.
- **Pure logic** sits in value types and enums (`TodayFeed`, `SyncMerge`, `ImportQuality`, `RecipeImportStore`…) so it
  is testable without views. Some Domain files still `import SwiftUI` — list them with
  `grep -l "import SwiftUI" RecipeFinder/Models -r RecipeFinder/Utilities/Recipe`; that list must not grow.

## Launch sequence

`RecipeFinderApp.init` (skipped entirely when hosting unit tests):

1. `SyncPreference.applyAtLaunch(in: .shared)` — before anything touches the database (see iCloud sync).
2. `DiagnosticReporter.shared.start()`, TipKit, UIKit appearance.
3. `reloadOnICloudChanges()` — only when `PersistenceController.shared.isSyncing`.
4. `purgeOldStoreHistory()` — `HistoryPurgeRule.cutoff` decides how much persistent history to drop.

`AppRootView` shows `OnboardingView` until `hasCompletedOnboarding` is set, then `ContentView`, which calls
`RecipeStore.load()` on appear while the library is empty. Launch tab is `AppTab.launchDefault` (`.today`).

## Core Data model and migrations

- Model: `RecipeFinder/Models/RecipeModel.xcdatamodeld`. Current version: whatever `.xccurrentversion` names (root
  `CLAUDE.md` guardrail holds the floor). Versions are `RecipeModel` (v1), `RecipeModel 2`, ….
- Entities (as of v17): `Recipe`, `RecipePhotoEntity` (added in v17), `CollectionEntity`, `MealPlanEntity`,
  `ShoppingItemEntity`, `ShoppingStoreEntity`, `KitchenItemEntity`, `InventoryItemEntity`, `ProfileEntity`,
  `CookDateEntity`, `EarnedBadgeEntity`. `Recipe` attribute names are in `PersistenceController.RecipeKey`.
- Container: `NSPersistentCloudKitContainer(name: "RecipeModel")`, always — the CloudKit mirror is attached or not
  per launch (below).
- **Migration is lightweight only**: `NSMigratePersistentStoresAutomaticallyOption` +
  `NSInferMappingModelAutomaticallyOption` in `PersistenceController.configureStore`. There are no mapping models and
  no staged migration.
- `CoreDataMigrationTests` tests v9 and v12–v16 stores migrating to current with no data loss. The supported floor is
  v6 (all-Binary `ingredients`), but v6–v8, v10 and v11 have no test; v1–v5 (pre-baseline Transformable) are
  documented as not migrating, with no test asserting it.
- `CloudSyncStore.problems(in:)` lists anything CloudKit would reject (unique constraints, required attributes
  without defaults, non-optional / ordered / inverse-less / Deny relationships); `CloudSyncStoreTests.theShippedModelIsOneCloudKitAccepts`
  asserts it is empty for the shipped model.
- **Before a migration**, `StoreBackup` copies the SQLite file and sidecars to
  `Application Support/StoreBackups/store-*` (newest 3 kept, excluded from device backup).
- **On load failure**, `PersistenceController` first retries without the CloudKit mirror (`retryWithoutSync`), then
  moves the unreadable store aside as `<store>.corrupt-<timestamp>` and opens a fresh one — it never deletes it.
- **Guardrail:** root [`CLAUDE.md`](../CLAUDE.md) forbids pointing `.xccurrentversion` below `RecipeModel 17` and
  removing `NSPersistentHistoryTrackingKey`. Adding a model version: add a new `.xcdatamodel`, bump
  `.xccurrentversion`, add a `CoreDataMigrationTests` case, update that CLAUDE.md line and this
  doc's entity list.

### Lists stored beside recipes

Recipes are read/written directly through `PersistenceController+RecipeFetch` / `+RecipeWrites`. Every other list
goes through **`MirroredSnapshot<Value>`**: rows live in Core Data entities, and a JSON "kept copy" of the whole
list stays in `LocalStore` as a fallback. The kept copy is written first; if the store can't be read the manager
runs on the kept copy. `CookingStreakManager` uses the older one-shot `LegacyBlobMigration` instead.

## iCloud sync

- **Switch.** `SyncPreference` (Settings) stores `iCloudSyncWanted`; `applyAtLaunch` copies it to
  `iCloudSyncEnabled`, which this launch runs with. Changing the switch takes effect next launch; `SyncStatus`
  explains this in Settings. `iCloudSyncEverOn` is set once and never cleared.
- **Store.** `CloudSyncStore.configure` always enables persistent history tracking and remote-change notifications,
  and attaches `NSPersistentCloudKitContainerOptions("iCloud.com.asadkhan.recipefinder")` only when sync is on.
  `PersistenceController.isSyncing` reports whether the mirror is actually attached.
- **Spotting other devices' edits.** `PersistenceController+RemoteChanges.takeOutsideChanges()` reads persistent
  history on a background context and reports changes not written by this app. `RemoteChangeReloader` observes the
  coordinator and reloads every manager (recipes, collections, plans, shopping, kitchen, badges, streak, profile).
- **History purge.** `HistoryPurgeRule` keeps 7 days of history, and once sync has ever been on, never purges past
  the start of the last successful CloudKit export (recorded from `eventChangedNotification`).
- **`SyncRules`** (`MirroredSnapshot.SyncRules.iCloudRules`) flip each list from "kept copy wins" to "store wins":
  saves apply this device's edits on top of the store (`SyncMerge.applyEdits`), and a kept copy is only ever added to
  the store (`SyncMerge.addKeptCopy`), never replaces it. Rows with different ids that mean the same thing (e.g. the
  same grocery added on two devices) fold into the lowest-ranked row (`SyncMerge.foldSameThing`).
- **Built-in recipe duplicates.** Bundled recipes have fixed ids on every device; `RecipeCopyMerge` folds the copies,
  keeping the one with the lowest CloudKit record name and merging cooks, favourite, rating and photos.
  `RecipeStore.load()` runs `mergeSyncedRecipeCopies` then `RecipeCopyMerge.oneCopyEach`.
- **`RecipePhotoSync`.** Photos are files under `Documents/RecipeImages/`; CloudKit only syncs the store, so each
  photo is copied into a `RecipePhotoEntity` row (path + JPEG, external storage). Newer wins per path. Rows are deleted
  only for photos an edit/delete on this device stopped showing (`removedPaths`); it never deletes files or recipes.
  Driven from `RecipeStore+RemoteImages.syncPhotosWithICloud()` via `PersistenceController.mirrorRecipePhotos`
  (sync on) or `removeRecipePhotoRows` (sync off, so deletes reach iCloud when sync resumes).
- **`ErasedPhotoCleanup`** removes local photo files after a Reset on another device, only when the remembered store
  file now has zero photo rows and no recipe references a photo.

### Reset / erase rules

- Settings → Reset (`DataManagementSettingsView.resetToDefault`): `PersistenceController.deleteAllRecipes()` batch-
  deletes photo rows then recipes; `LocalStore.clearAll(keeping: SyncPreference.keptThroughReset)`; photo files are
  deleted only if the recipes really went; `RecipeStore.load()` re-seeds; then each manager's `removeAll…` runs.
- `MirroredSnapshot.removeAll()` records `wipePending.<key>`, retried on each `load()` until the store is emptied, so a
  failed delete never brings data back.
- `SyncStatus.resetErasesEveryDevice(everSynced:)` drives the warning copy: a store that is, was or will be mirrored
  can carry the erase to every device.

## Import pipeline

Entry points: the "+" sheet (`Views/Import/ImportView.swift`, a paste box plus `AddRecipeOption`: photo/PDF,
web search, another app, start blank), Today's clipboard card, the share extension, and `.recipefinderrecipe` files.

```
link ──► RecipeImportPipeline.fetchAndParse ──► RecipeParser.parse ──► ExtractedRecipeData
                                                                           │ RecipeImportBuilder
text / OCR / PDF ──► RecipeTextImportRouter ──► interpreter or TextRecipeParser ──► wizard prefill
                                                                           ▼
                                                     RecipeModel ──► RecipeStore.add ──► RecipeImportStore.outcome
```

- **Web.** `RecipeImportPipeline` (Foundation-only, no singletons) fetches through `HTMLFetching`, caps manual redirects (injected
  fetchers only — production URLSession follows its own), and requires a name and ingredients. `RecipeParser.parse` tries structured strategies in order —
  JSON-LD, WP Recipe Maker, Microdata, RDFa, DOM lists — then free-text heuristics. Page text is kept capped at 50 KB.
  `RecipeImporter` is the `ObservableObject` UI wrapper; `AddRecipeImportFlow` is the one-sheet "Reading…" → draft UI.
- **Text, photos, PDFs.** `VisionRecipeImageTextRecognizer` (Vision OCR) and `MultiPageRecipeReader` (≤5 photos or a PDF)
  produce text; `RecipeTextImportRouter` sends it to `FoundationModelsRecipeInterpreter` (iOS 26+, on-device) or falls
  back to `TextRecipeParser`. Results always go through the wizard for review.
- **Other apps.** `OtherAppRecipeImport.swift`: `PaprikaRecipeParser`, `MelaRecipeParser`, `CSVRecipeParser`, then
  `OtherAppImportPlanner` skips duplicates.
- **Review and save.** `ImportQuality.assess` scores what was read and the wizard highlights missing fields;
  `RecipeImportStore.outcome` decides error vs. first-import badge after `RecipeStore.add`. After each library load,
  `RecipeStore` keeps an on-device copy of web pictures (`RecipeImageLocalizer`).

## Share-extension handoff

- Target `RecipeShareExtension/` (`ShareViewController.swift`), App Group `group.com.asadkhan.recipefinder` in both
  entitlements.
- For a URL, the extension runs `RecipeImportPipeline` itself. If `SharedImportInbox.isCompleteRecipe` passes it
  queues the `ExtractedRecipeData`; otherwise it queues the raw URL. Shared text containing a link is handled as that URL; other text is queued as text.
- `SharedImportInbox` (`Utilities/Managers/`, compiled into both targets) keeps a queue in App Group defaults and also
  drains the older single-slot keys.
- The app drains it in `RecipeSearchView.checkSharedImportInbox()` (`RecipeSearchView+Actions.swift`, on appear and on
  `willEnterForeground`), with the routing and save gate in the pure, tested `SharedImportPlan`:
  extracted recipes are built with `RecipeImportBuilder` and saved (duplicates by name and recipes missing ingredients or steps skipped, with a toast); the
  first URL or text opens (URL → import sheet, text → wizard) and the rest are re-queued. It is the Recipes tab's
  view, so with Today as the launch tab a share is picked up once Recipes is opened.

## Today feed

- `Views/Main/TodayView.swift` reads recipes, meal plans, kitchen, cooking streak and badges from the environment and
  rebuilds a `TodaySnapshot` (`Models/Engagement/TodaySnapshot.swift`) on each data change, not in `body`.
- `TodaySnapshot.make` composes pure parts: `TodayFeed` (Tonight hero + Shuffle alternatives, shelves),
  `TodayWeek` (seven-day strip), `TodayProgress`, and the weekly `TrySomethingNew` pick (nil for new users).
- `TodayFeed` picks Tonight in order: today's plans, kitchen matches, then quick recipes. Quick picks use a stable
  per-day/meal rank (`dailyRank`, FNV-1a) and `MealSlot` by clock (breakfast 5–11, lunch 11–16, else dinner).
- Card views live in `Views/Main/Today*.swift` (`TodaySections.swift`, `TodayWeekCard`, `TodayProgressCard`, …).

## Bundled recipes and art (`RecipeFinder/RecipeSeed`)

- `recipes_seed.json` — the bundled collection, decoded by `BundledRecipeCatalog.load()`. It is generated off-device
  by `BundledRecipeCatalogTests` from `recipes_source.json` plus human-reviewed `recipes_curated.json`.
- `recipes_seed_history.json` (from `tools/seed-history.py`) lets the sample refresh tell untouched old copies from
  edited ones; bump `BundledRecipeCatalog.sampleRefreshVersion` when shipped fixes should reach existing installs.
- `SeedRecipeProvider` holds starter recipes with fixed UUIDs. `RecipeStore.seedIfNeeded` seeds starters into an
  empty library and the bundled collection once (flags `seedRecipesLoaded`, `bundledRecipesSeeded_v1`).
- `RecipeArt/<recipe id>.jpg` — illustrations made with `tools/RecipeArt` and compressed by
  `tools/bundle-recipe-art.py`. `BundledRecipeArt` resolves them as a display fallback via the `bundled-art:` prefix:
  never stored on a recipe and never synced; the recipe's own image or photos win.

## CI and TestFlight

All in `.github/` (`ls .github/workflows` for the current set; each YAML's header says what it does). CI is the compiler for cloud sessions (see root `CLAUDE.md`).

| Workflow | Trigger | Does |
|---|---|---|
| `build.yml` "Build & Test" | push to `main` / `agent/**`, PRs (docs/tools paths ignored), nightly 03:00, manual | Unit tests (UI tests skipped); UI tests in 4 shards nightly/manual only (`.github/scripts/shard-ui-tests.py`). On `main`, a `gate` job skips tests when the same commit already passed and only compiles to refresh the build cache. |
| `testflight.yml` | push to `main` touching app/extension/project files (not `*.md`), manual | Archive, upload to App Store Connect (build number = run number), then set "What to Test" (`testflight_notes.py`, `set_whats_new.py`) |
| `coverage.yml` | nightly, manual | Unit tests with coverage; publishes to the `coverage` release on `main` |
| `screenshots.yml` | manual | Captures App Store screenshots to the `screenshots` / `screenshots-preview` releases |
| `testflight-feedback.yml` | hourly, manual | Files TestFlight feedback as GitHub issues (`fetch_testflight_feedback.py`) |
| `testflight-capabilities-check.yml` | manual | Reads the app's capabilities in App Store Connect (`asc_capabilities.py`) |
| `cleanup-agent-branches.yml` | daily, manual | Deletes merged `agent/*` branches |
| `tools-build.yml` | push to `tools/RecipeArt/**`, manual | Builds the RecipeArt tool |

- `.github/actions/prepare` — composite action shared by unit, UI and coverage jobs: quiets the runner, restores
  file dates and the DerivedData cache, boots a (cached) simulator and builds for testing. Only `main` writes caches.
- `.github/actions/select-xcode` — every app job (Build & Test, Coverage, Screenshots, TestFlight) runs on the
  `xcode-27` runner and selects the newest release `Xcode_27*.app` (App Store uploads need the iOS 27 SDK); it fails
  if none is installed. The DerivedData cache key includes the Xcode build, so an Xcode update means one cold build.
- `testflight.yml` does not wait for Build & Test; safety comes from the branch policy in root `CLAUDE.md` (`main` is
  fast-forwarded only to a commit already green on its `agent/` branch).
