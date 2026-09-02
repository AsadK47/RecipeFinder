# RecipeFinder Roadmap

## Legend
- 🔴 Not Started
- 🟡 In Progress
- 🟢 Done

> **Maintaining this doc:** it captures product *direction and priorities*, not a
> changelog — implementation history lives in git. Update a phase's status marker
> in place as work lands; avoid appending dated "done in month X" entries, which
> rot. Phases are intentionally coarse so they stay valid as details shift.

## Strategy (July 2026)

Competitive analysis vs ReciMe / Crouton / Mela / Paprika: RecipeFinder's position is
**"ReciMe, but private, unlimited, and better at the actual cooking."**

- ReciMe won 10M+ users on one loop: see recipe on social → share into app → AI recipe card → grocery list. Their import is server-side AI, paywalled at 5 imports/week.
- Our edge: on-device parsing (FoundationModels) costs nothing per import → **unlimited imports can be free**. Freemium must be genuine added value, never locked basics.
- ReciMe's known weaknesses we already beat or can beat: grocery list doesn't merge duplicates (we normalize + merge), meal plan and shopping list unlinked (ours now linked), weak cooking mode (Crouton sets the bar).
- Already at parity, no work needed: aisle-grouped shopping list, serving scaling, metric/imperial conversion, cookbook-style organization, offline-first.

Priorities are ordered below. Phases 1–3 are the release-defining work.

---

## Phase 1: Capture — the ReciMe loop *(highest priority)*

### 🟢 Share Sheet Extension
*The delivery vehicle for everything else in this phase.*
- ~~Share Extension target accepting URLs and plain text~~ 🟢 — `RecipeShareExtension` (`ShareViewController`) captures shared URLs and text
- ~~Hand off to main app via App Group~~ 🟢 — `SharedImportInbox` over App Group defaults; consumed on foreground in `RecipeSearchView`
- ~~In-extension full import (fetch + parse in the extension so the recipe is simply there next open)~~ 🟢 — `RecipeImportPipeline` (Foundation-only, shared with the app) runs headless in the extension; success stores parsed `ExtractedRecipeData` which the app materialises silently on next launch, failure falls back to the raw URL/text for interactive import

### 🟡 Instagram & TikTok Recipe Import
- ~~Share caption text → extract recipe content~~ 🟢 — shared plain text runs through `SharedTextImporter`
- ~~On-device FoundationModels (iOS 26+, availability-gated) — parse caption/text into structured recipe via @Generable~~ 🟢 — `FoundationModelsRecipeInterpreter` (`RecipeTextInterpreting` seam); private, free, offline. Falls back to `TextRecipeParser`/manual wizard when unavailable or low-confidence
- 🔴 Dedicated "paste a URL or text" import entry point (currently only the share-sheet text path is wired)
- 🔴 Explicit review/edit step for AI results before save (today a confident parse saves silently via the dedupe `ingest`)
- **Marketing angle: unlimited free imports vs ReciMe's 5/week**

### 🔴 Photo-to-Recipe Conversion
- Cookbook page, handwritten recipe, or screenshot → Vision OCR → same on-device parser as above
- User reviews and confirms before saving

---

## Phase 2: Sync & Trust

### 🔴 iCloud Sync *(new — competitive gap: every rival syncs; "lost my recipes on phone upgrade" is the category's review-killer)*
- `NSPersistentCloudKitContainer` over the existing Core Data stack
- User's own iCloud — no server, keeps the privacy-first story intact
- Reconcile with UserScopedStorage per-account scoping (design needed: local accounts vs iCloud identity)
- JSON-backed stores (meal plans, shopping list, inventory) need a sync strategy too (move to Core Data or CloudKit key-value/records)
- ~~Build a real backup/export + import as the manual fallback.~~ 🟢 — `BackupService` + `BackupArchive`/`BackupCodec` (`.recipefinderbackup`) with a non-destructive, date-faithful `merge(_:)` seam on every store; Export/Import UI in `DataManagementSettingsView`. Full round-trip incl. recipes, correct model shapes, per-user scope.

---

## Phase 3: Cooking Experience

### 🔴 Cooking Mode *(Crouton sets the bar)*
- Step-by-step instruction view with large text, one step at a time
- Tap an ingredient mentioned in a step to see its quantity
- Auto-detect times in step text → tap to start a timer (integrates existing timer feature)
- Keep-screen-awake already exists (Display settings); apply automatically in cooking mode
- Voice control ("next step", "repeat") — stretch goal

### 🔴 Timer Live Activity + Widgets *(requires a Widget Extension target — create in Xcode UI)*
- Running timer as a Live Activity on Lock Screen / Dynamic Island (RecipeTimerManager exists)
- Today's meal plan widget
- Shopping list quick-view widget
- Random recipe suggestion widget

---

## Phase 4: Meal Planning Enhancements

### 🟡 Expanded Meal Planner
- ~~Meal type slots: Breakfast, Lunch, Dinner, Snack~~ 🟢 — `MealTime` enum with icons/ordering in MealPlanModel
- ~~Auto-generate shopping list from the week's meal plan~~ 🟢 *(July 2026)* — "Add Week to Shopping List" in weekly view; merges duplicates via IngredientNormalizer, skips completed meals, falls back to name-matching when a recipe was re-imported (`weekShoppingSummary` in MealPlanningManager). ReciMe's most-cited missing feature.
- Drag-and-drop to rearrange meals between days
- Weekly overview with nutritional summary (ties into Phase 5)
- "Suggest a meal" — recommend recipes from saved collection based on: unused ingredients, variety, dietary preferences
- Recurring meals (e.g., "Meal Prep Sunday")

---

## Phase 5: Nutrition

### 🔴 Nutritional Information
- Display calories, protein, carbs, fat, fibre per serving
- **Data source options:** Open Food Facts API (free, open-source), USDA FoodData Central (free), Edamam (free tier)
- **UX approach:** Toggle per recipe (not a global setting) — some users care for weeknight meals but not for baking
- Show as a collapsible section on recipe detail view
- Nutrition summary on the meal plan weekly view
- Recalculate when servings are adjusted

---

## Phase 6: Shopping Integration

### 🔴 Supermarket Connection
- Link shopping list to supermarket suppliers (Tesco, Sainsbury's, Ocado, etc.)
- Match ingredient names to supermarket product catalogue
- Auto-build a basket on the retailer's site/app
- **Implementation options:** deep links into retailer apps, retailer affiliate APIs, web scraping (last resort)
- Price comparison across retailers
- Smart substitution suggestions

---

## Phase 7: Quality of Life & Engagement

### 🟡 Smart Search & Filtering
- ~~Search by ingredient ("what can I make with chicken and rice?")~~ 🟢 — "available ingredients only" toggle with ≥80% match scoring in RecipeSearchView
- Filter by dietary restriction, cook time, difficulty (partially present — verify coverage)
- Recently viewed / frequently cooked

### 🔴 Collections & Tags
- User-created collections beyond favourites ("Weeknight Dinners", "Party Food")
- Custom tags with colour coding
- Smart collections (auto-populated based on rules)

### 🔴 Recipe Sharing
- Share recipes as rich links or formatted cards
- Import shared recipes from other RecipeFinder users
- Export as PDF for printing *(basic text/PDF share exists)*

### 🔴 Recipe Images via Unsplash API *(demoted from Phase 1: URL import already extracts images from JSON-LD/OG, and user photos are done — this only benefits manually created recipes)*
- Integrate Unsplash search-by-recipe-name to auto-assign images
- Cache images locally (NSCache + disk); `imageURL` field in Core Data; API key via `.xcconfig`
- **Scaling concern:** free tier = 50 req/hr; consider server-side URL cache if multi-user growth

### 🟢 User Photo for Recipes *(completed July 2026)*
- PhotosPicker in RecipeWizardView; compressed JPEG in app sandbox; user photo takes priority over remote image
- Remaining: "take a photo" via camera (requires re-adding NSCameraUsageDescription build setting)

---

## Engineering foundation

Durable health of the codebase (specifics live in git history):
- **CI gates on tests** — `xcodebuild test` runs on every push to `main` via GitHub Actions on `macos-26` / Xcode 26 (matching the Swift 6.3 dev toolchain); failing tests block. Status badge in the README.
- **Testing** — Swift Testing for new and migrated tests (XCTest migrated opportunistically when an area is touched); parameterize data-driven cases; inject fakes rather than reaching for singletons.
- **Dependency injection** — external dependencies sit behind protocols (e.g. `HTMLFetching` for the importer) so logic is testable offline.
- **Concurrency** — Swift 6 strict concurrency; no unsynchronized shared mutable state (watch especially for `nonisolated(unsafe)` static caches).
- **Clean Architecture** — Presentation / Domain / Data separation with dependencies pointing inward; keep files focused — a large view file is a refactor signal.

## Completed

### 🟢 Settings Revamp (July 2026)
- Phase A: design system in Components/Settings/SettingsComponents.swift (icon tiles, rows, sections, cards)
- Phase B: 12 sub-screens split into Views/Settings/Screens/, restyled; SettingsScreen scaffold, toggle/choice rows; visual walkthrough signed off

### 🟢 Health Check & Release Prep (July 2026)
- Fixed `signUp()` overwriting existing accounts' credentials (account-takeover bug)
- Aligned `signUpWithoutLogin()` password validation with the real policy (Validator)
- Fixed PBKDF2 failure producing an empty-string hash instead of nil
- `UIRequiredDeviceCapabilities` armv7 → arm64; removed unused camera/photo permission strings
- Consolidated Info.plist keys into `INFOPLIST_KEY_*` build settings; resolved duplicate Face ID usage strings
- Removed dead `SwiftData` imports; readme accuracy pass (iOS 17.5+, real dependencies, PBKDF2)

### 🟢 Bug Fixes (March 2026)
- Fixed `clearAllData()` using global `UserDefaults` instead of `UserScopedStorage`
- Fixed `unlockWelcomeBadge()` storing `accountCreationDate` globally
- Fixed `hasPopulatedDatabase` flag not scoped per user
- Moved User PII from plain `UserDefaults` to Keychain storage
- Fixed `deleteAccount()` not cleaning up all persisted keys
- Fixed `signUpWithoutLogin()` leaking PII to unscoped storage
- Preserved `createdAt` across sign-in cycles
- Removed redundant `updateStats()` call
- Converted nested if/else chains to guard clauses

---

## Notes

- **API Keys:** All API keys stored in `.xcconfig` files excluded from version control
- **Privacy First:** Minimal data collection, all user data scoped per account
- **Offline First:** Core features work without internet; network features degrade gracefully
- **Freemium principle:** free tier must be genuinely useful; monetize added value (e.g., supermarket integration, advanced planning), never basics or things that cost us nothing (imports)
