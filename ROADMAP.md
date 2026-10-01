# RecipeFinder Roadmap

This is the product's story and its direction — *why* things are the way they are
and where they're going — not a changelog. Implementation history lives in git.

**How to read it.** Three parts, in the order the app earns its keep:
**Part I — Hardening** (make what exists trustworthy), **Part II — Improvements**
(sharpen the existing product), **Part III — New Features** (net-new bets). Each
item is framed as *problem → what we did / will do → why it matters*.

**How to maintain it.** Update a status marker in place as work lands. Keep the
prose current, but resist turning it into a dated "done in month X" log — that
rots, and git already has it. Phases are intentionally coarse so they stay valid
as details shift.

- 🔴 Not started 🟡 In progress 🟢 Done

---

## Where we stand *(September 2026, updated)*

RecipeFinder is a privacy-first, offline-first recipe manager. The one-line pitch:

> **"ReciMe, but private, unlimited, great at the actual cooking — and your
> library is safe."**

That last clause is deliberate and was a correction to an earlier framing. "No
account, purely local" is *not* a virtue — it's a data-loss liability: Core Data
lives in the app sandbox, so deleting the app wipes the library and device
backups are opt-in and stale. "Lost my recipes on a phone upgrade" is the
category's #1 review-killer. So **durability — accounts, iCloud sync, real
backup/export — is a first-class pillar, not something to strip or paywall.**
Sync ships in the **free tier**: it rides the user's own iCloud (CloudKit private
DB) and costs us nothing, so charging for data safety would be indefensible. "Private"
means the user's *own* iCloud and Apple ID, not the absence of an account:
private and synced are compatible.

**The competitive read.** ReciMe won 10M+ users on a single loop: see a recipe
on social → share into the app → AI turns it into a clean card → grocery list.
Their import is server-side AI, paywalled at 5/week.

- **Our structural edge:** import is **on-device** (FoundationModels + Vision
  OCR), which costs us nothing per import — so **unlimited imports are free**,
  and that's a marketing line ReciMe can't match. Freemium must therefore be
  genuine *added* value (curated library, seasonal drops, supermarket, advanced
  planning), never locked basics and never things that cost us nothing (imports,
  iCloud sync).
- **Where we already beat them:** we merge duplicate ingredients in the grocery
  list (they don't); our meal plan and shopping list are linked (theirs aren't).
- **At parity, no work needed:** aisle-grouped shopping list, serving scaling,
  metric/imperial conversion, cookbook-style organisation, offline-first.

**Subscription model (RecipeFinder+).**
Free-tier-first with a single premium **subscription** tier, gated on genuine
*ongoing* value — never crippled basics, and never things that cost us nothing.
**Subscription-only (no lifetime/one-time tier):** higher LTV per payer, with the
deliberate trade-off that the recurring pitch must rest on continuously-delivered
value (seasonal drops, live/collaborative features, supermarket) — not one-time
content and not free infrastructure.

*Free tier (permanent):*
- 50 hand-curated recipes from day 1 so the app is never empty
- Unlimited personal imports (URL, photo, OCR, text, share extension) — on-device,
  so they cost us nothing and stay free forever (the line ReciMe can't match)
- **iCloud sync + backup/export** — the user's library safe across their devices,
  private. CloudKit's private DB rides the user's *own* iCloud, so sync costs us
  nothing to provide; paywalling data safety would contradict both the privacy-
  first durability pillar and our own "never monetise things that cost us nothing"
  rule. Free is also a differentiator: *unlimited imports **and** private sync, free.*
- All organisational features: search, filter, collections, tags, meal planning,
  shopping list, pantry

*RecipeFinder+ (subscription — £2.49/month, or £24.99/year (~16% off 12× monthly £29.88, ≈£2.08/mo). New annual subscribers get a **£19.99 first-year intro** (StoreKit introductory offer, ~33% off; renews at £24.99)):*
Recurring value is deliberately things that are ongoing or cost real money to
produce — not sync, not a one-time content dump:
- **Curated library** — 100 recipes unlocked on subscribe; a further 150 in drops
  over ~2 months (~50/month). Original, tested recipes with photography (real
  production cost). Finite by design — 300 total, then complete.
- **Seasonal recipe drops** — new packs quarterly after the initial 300; the
  primary *ongoing* reason the subscription keeps earning once the library is done.
- **Supermarket integration** — match the shopping list to a retailer basket
  (affiliate / deep-link); genuine added value we can legitimately charge for.
- **Family sharing** (up to 5) + **collaborative shopping list** — real-time,
  shared households via CloudKit Sharing.
- **Auto meal plan** — "plan my week from my pantry" using kitchen inventory +
  preferences; infrastructure exists (`KitchenRecipeMatcher` +
  `PantryExpirySuggestions`), needs a generation layer.
- **Nutritional goals + HealthKit** — daily targets, per-meal tracking, opt-in
  write to Apple Health.

*Caveat we accept (decision recorded, not forgotten):* the curated library is
finite, so once all 300 ship the recurring charge is carried by drops +
supermarket + collaboration + planning/HealthKit. If churn shows those don't
sustain a monthly sub, revisit adding a lifetime unlock or repricing.

*Not gated (ever):* imports, **iCloud sync, backup/export**, cooking mode, timers,
basic meal planning, shopping list, pantry, App Intents, Siri.

*Implementation order:* StoreKit 2 paywall (gates content + features) → iCloud
sync (free to users, but the CloudKit capability still needs paid Developer
Program enrollment) → curated library image pass (Unsplash) → supermarket → auto
meal plan → HealthKit.

**The core loop everything serves:** *get a recipe in → find it → cook from it
well → decide what to cook next.* Anything not serving that loop is secondary.

**One hard constraint.** iCloud sync is **blocked until paid Apple Developer
Program enrollment** — CloudKit needs the iCloud capability and a container,
unavailable on a free personal team (dev stays on the free team until
TestFlight/App Store; enrolling RecipeFinder Limited still needs a D-U-N-S).
Durability therefore splits: the **backup/export round-trip is pure local file
I/O and is done**; **iCloud sync is deferred**, but the Core Data model is kept
CloudKit-ready (no unique constraints, optional relationships, defaults) so
turning it on later isn't a rewrite.

---

## Part I — Hardening

Before adding surface area, we spent a campaign making the existing app
trustworthy. Each item below was its own commit + review checkpoint. This is the
foundation the rest of the roadmap stands on.

### 🟢 Auth & credentials
*Problem:* the highest-stakes code had zero tests, and a real account-takeover
bug once let `signUp()` overwrite an existing account's credentials.
*What we did:* put a `KeychainStore` protocol seam in front of the system
Keychain (real vs in-memory fake), extracted a pure PBKDF2 `PasswordHasher`, and
covered the credential/session lifecycle — including the historical empty-hash
bug and stable-user-id-on-resave — with Swift Testing cases.
*Why:* credentials are where a privacy-first app cannot afford to be wrong.

### 🟢 Search & filter robustness
*Problem:* "what can I make?" quietly returned wrong results — ingredient
matching hit substrings (ice ↔ rice), time parsing mishandled hours and ranges
("20-30 min" → −10), and filtering recomputed on every keystroke.
*What we did:* unified matching on a word-boundary `KitchenRecipeMatcher` (with
conservative singularisation so egg↔eggs matches without reviving ice↔rice),
taught `TimeExtractor` to parse hours and range→upper-bound, and made
`RecipeFilterCriteria` a single `Hashable` value that computes match % once and
keys the filter cache — so a new filter field can't silently be forgotten.
*Why:* the headline "find something to cook" feature has to be correct *and* fast.

### 🟢 Failure-state surfacing
*Problem:* recipe writes swallowed every failure into a log and returned — a
failed save still showed "Imported" and then vanished on relaunch (silent data
loss).
*What we did:* writes now return a result the UI acts on; create/import/edit
sites roll back the optimistic change and tell the user (toast/alert) instead of
lying. *Deferred, tied to clean-arch:* a typed error (disk-full vs encode vs
not-ready) and a single add-and-persist use case to end the duplicated
optimistic-insert logic across the two import hubs.
*Why:* losing a user's recipe silently is the worst thing this app can do.

### 🟢 Concurrency (Swift 6 strict)
*Problem:* the shared singleton managers leaned on `nonisolated(unsafe)` escape
hatches, and one (`BadgeManager`) held genuinely unsynchronised mutable state.
*What we did:* audited all eleven managers; made `BadgeManager` `@MainActor`,
expressed `UserScopedStorage`'s real thread-safety as a documented
`Sendable` conformance, and removed a fragile `@objc` NotificationCenter observer
that was a latent hop-crash. No `nonisolated(unsafe)` left in the managers.
*Why:* data races are invisible until they corrupt a user's library.

### 🟢 Import robustness (the corpus)
*Problem:* real recipe pages are messier than clean synthetic markup — minified
HTML, microdata, fully-qualified schema URLs, `HowToSection` nesting, Recipes
buried under `mainEntity`, OCR quirks from photographed pages.
*What we did:* built a durable fixture bed of real-world full-page HTML and
plain-text recipes, then hardened the parser against each: JSON-LD
`@graph`/`mainEntity`/array nesting, microdata, block-level line reconstruction,
a single canonical `IngredientLineParser` (spelled-out units, glued fractions,
ranges, no fabricated quantities), and note/footnote fencing in the text parser.
*Why:* no import → empty library → dead app. Import must feel like it *always*
works.

### 🟢 Data durability — backup/export
*Problem:* local-only storage is wiped on app delete, and the old importer was
removed as broken.
*What we did:* a real `.recipefinderbackup` round-trip (`BackupService` +
`BackupArchive`/`BackupCodec`) with a non-destructive, date-faithful `merge(_:)`
seam on every store, wired into Data Management settings — covering recipes,
meal plans, shopping list, inventory, and badges, per-user scoped.
*Why:* until iCloud is unblocked, this is the user's safety net against losing
everything. (iCloud sync itself lives in Part III.)

### Engineering foundation
The durable rules that keep the above from regressing:
- **CI gates on tests** — `xcodebuild test` runs on every push to `main`
  (GitHub Actions, `macos-26`/Xcode 26); a red suite blocks. Badge in the README.
- **Testing** — Swift Testing for new/migrated tests (XCTest migrated
  opportunistically when an area is touched); parameterize data-driven cases;
  inject fakes rather than reaching for singletons.
- **Dependency injection** — external dependencies behind protocols (e.g.
  `HTMLFetching`, `KeychainStore`) so logic is testable offline.
- **Clean Architecture** — Presentation / Domain / Data with dependencies
  pointing inward; a large view file is a refactor signal, not a style choice.
- **Performance** — no non-trivial work in a SwiftUI `body`; memoize hot pure
  functions with the lock-guarded `MemoCache`; a loose perf-budget test guards
  against order-of-magnitude regressions.

---

## Part II — Improvements

Sharpening the product we already have. These aren't new pillars — they remove
friction and make existing features pull their weight.

### ✅ The sign-up moment — fix the timing, not the account
*Problem:* a brand-new user hits four gates before any value — notification
prompt at launch → sign-in wall → Face ID splash → onboarding → an *empty* app.
*What we did:* brand-new users (no prior sign-in history) now land straight in
`ContentView` in guest mode — the auth wall is gone on first launch. Returning
signed-out users still see the auth screen. A soft nudge banner sits above the
tab bar ("Sign in to save your own recipes") and opens the sign-up sheet. The
Import tab is gated for guests: any import action redirects to sign-up instead
of the importer, so the value moment is "I want to save this recipe" rather
than "I want to use the app." `hasEverAuthenticated` (`@AppStorage`) persists
the distinction between a new user and a signed-out one across launches.

### 🟢 Move the notification prompt off launch
`requestPermission` is called only from `RecipeTimerManager` the first time a
timer fires — never at app launch. Already in-context.

### 🟢 Kill the empty state — seed recipes
`SeedRecipeProvider` ships 6 bundled starter recipes (spaghetti bolognese,
chicken tikka masala, avocado toast, etc.) with stable fixed UUIDs (idempotent).
Guest users see them before sign-up; newly signed-in users get them seeded
once into their store.

### 🟢 Engagement surfaces
- **Badges** ✅ `BadgeEarnedSheet` is wired in `ContentView` — fires on any
  `pendingCelebration`; confetti + sheet on unlock.
- **StoreKit `RequestReviewAction`** ✅ triggered after 3rd cook of any recipe
  (`RecipeDetailView.recordCook`); Apple's SDK throttles to respect the yearly cap.
- **TipKit** ✅ `CanMakeNowTip` on the filter button (pantry filter discovery) and
  `CookingModeTip` on the frying-pan toolbar button; configured at app launch with
  `.displayFrequency(.daily)`.

### 🟢 iPad-optimized layout
*Problem:* RecipeFinder ran on iPad via iPhone scaling — it worked, but wasted the
screen. Every serious recipe app (Paprika, Mela, Crouton) uses `NavigationSplitView`
on iPad. Cooking on a counter-propped iPad is a primary use case.
*What we did:* `ContentView` switches on `horizontalSizeClass` — iPhone keeps the
`TabView`; iPad uses a `NavigationSplitView` with a section sidebar
(Recipes/Groceries/Import/Planning/Settings) and a detail column
(`sidebarDetailView`). `AdaptiveSpacing` is already `horizontalSizeClass`-aware.
*Optional future:* a three-column, selection-driven **recipe list beside the open
recipe** (Mail/Paprika style) would deepen it further — the current two-column
split already removes the scaled-up-iPhone feel, so this is polish, not a fix.

### 🟢 Recipe image placeholders
`RecipePlaceholderView` ships: name-seeded gradient palette (stable Unicode-scalar
hash), fork-knife glyph, shimmer overlay during Kingfisher load, cross-fade on
success. Used as Kingfisher's loading placeholder *and* the permanent failure
fallback in `RecipeImageView`. All recipe cards pass `recipeName` for varied
palettes.

### 🟢 Smart search & filtering coverage
All filters ship: text search, category, difficulty, cook time, dietary flags,
tags, collection membership, "available ingredients only" with pantry-ranked
results. Filter criteria is a single pure `Hashable` value fully covered by
integration tests.

### 🟢 Meal planner enhancements
Meal-type slots (breakfast/lunch/dinner/snack), "add the week to the shopping
list," weekly/calendar views, drag-to-reorder within a day, and **recurring
weekly meals** ("Meal Prep Sunday") all ship. Recurring: `isRecurring` flag on
`MealPlanModel`, `toggleRecurring`/`propagateRecurring` in the manager,
materialises to the visible week on navigation; long-press card → "Repeat
Weekly" / "Stop Repeating"; ↻ badge on the recipe name row.
Pantry-aware meal suggestions now ship: `PantryExpirySuggestions.matches` (pure
helper) surfaces up to 3 recipes that use expiring inventory items; the
`ExpiryRecipeSuggestionsSection` appears in the meal planner whenever items are
expiring within 3 days; tapping "Plan" reuses the meal-time picker and saves
the recipe directly without going via the recipe selector.
Remaining: weekly nutrition summary (tied to the Nutrition item in Part III).

### 🟢 Recipe library sort order
*Problem:* the recipe list has no sort control — recipes appear in insertion
order. Every comparable app lets users sort by name, date added, cook time, or
favourites count.
*What we did:* added `SortOrder` enum (name A–Z/Z–A, highest rated, most cooked)
to `RecipeFilterCriteria`; wired through `FilterSheet` sort picker and
`RecipeSearchView`. Ingredient-match ranking takes precedence when "Can Make Now"
is active. Fully unit-tested in `RecipeFilterCriteriaTests`.

### 🟢 Pantry expiry & restock — surface what's already tracked
*Problem:* `KitchenInventoryModel` already tracks `expiryDate` / `isExpired` /
`isExpiringSoon` / `needsRestock`, and the manager exposes `expiredItems()` /
`expiringSoonItems()` / `lowStockItems()` — but none of it is surfaced, so it may
as well not exist.
*What we did:* `PantryAlertsSectionContent` surfaces expired / expiring-soon /
low-stock items at the top of the kitchen list with colour-coded icons and
swipe-to-remove; wired into `KitchenSectionsView`. `NotificationManager` schedules
a `UNCalendarNotificationTrigger` at 6 PM the evening before each item's expiry
(identifier `expiry-<UUID>`); wired into `KitchenInventoryManager` on add/update/
remove. Permission requested at first app launch via `ContentView.onAppear`; tapping
the notification deep-links to the Groceries tab via `NSNotificationCenter`.
*Remaining:* barcode scanning via Vision (`VNDetectBarcodesRequest`).

### 🟢 Cook history & recipe rating
*Problem:* the two most useful signals for "should I cook this again?" — when did
I last make it, and did we like it? — are not tracked at all. Paprika, Mela, and
Whisk all surface this. Without it, favourites is the only signal and it's binary.
*What we did:* added `lastCookedAt`, `cookCount`, and `rating` to the Core Data
entity (v12→v13 lightweight migration); `recordCook`/`updateRating` write atomically
(separate from content edits so history survives recipe edits); `cookHistoryCard`
on recipe detail shows a `StarRatingView` (tap-to-rate, tap-again to clear) and
a "Mark as Cooked" button with optimistic update + persist. Rating feeds into the
"highest rated" and "most cooked" sort tiers added to `SortOrder`.

### ✅ Multiple photos per recipe
*Problem:* a single hero image can't capture step shots, plating variants, or
"my result" photos that help the next cook. Paprika lets you add several.
*What was done:* `RecipeImageStore.persistGallery` persists up to 4 additional
images (named `<UUID>_g0.jpg` etc.) alongside the hero. The wizard's name step
now shows an "Additional Photos" gallery strip (horizontal thumbnails, remove and
add buttons). The detail view renders a horizontal scroll of gallery thumbnails
below the hero. Edit flow round-trips `photoNames` through `PrefilledRecipeData`.
Data layer was already complete — `RecipeModel.photoNames` and Core Data v13 both
existed; the gap was purely UI and image-store plumbing.

### 🟢 Recipe source link & re-fetch
*Problem:* the source URL is stored on import (in `RecipeImportBuilder`) but never
surfaced in the UI. Users can't get back to the original page, and if the source
recipe is corrected, there's no way to pick up the fix without re-importing and
losing edits.
*What we did:* "View Original" link surfaces on recipe detail for any URL-imported
recipe (`importedFromURL` parsed from the notes footer; import metadata stripped
from displayed notes via `notesForDisplay`). "Refresh from Source" button runs the
existing `RecipeImporter` against the same URL, builds a fresh `RecipeModel`, and
computes a `RecipeDiff` comparing only content fields (name, ingredients,
instructions, times, difficulty, category, cuisine, image). If changes exist,
`RecipeRefreshSheet` lists each changed field with old→new values and per-field
toggles; the user selects what to accept and taps "Apply". Personal data (notes,
tags, servings, ratings, cook history, gallery) is always preserved. "Recipe Up to
Date" alert surfaces when no diff is found. Covered by `RecipeDiffTests` (12 tests).

### 🟢 Recurring / staple shopping items
*Problem:* eggs, milk, bread — the same items go on every shop. Manually
re-adding them after each clear is friction that every mature shopping-list app
(AnyList, OurGroceries) solves.
*What to do:* add an `isRecurring` flag to `ShoppingListItem`; recurring items
are auto-restored when the list is cleared, or surfaced in a "Staples" quick-add
section at the top of the list.

---

## Part III — New Features

Net-new bets, ordered by priority.

### 🟢 Capture — the ReciMe loop *(shipped; this is the wedge)*
The loop that defines the release is live end-to-end:
- **Share extension** captures URLs and text and, when it can, does the full
  fetch+parse *in the extension* (`RecipeImportPipeline`) so the recipe is simply
  *there* on next open; otherwise it hands the raw URL/text to the app.
- **Social & text import** runs captions through on-device FoundationModels
  (`RecipeTextInterpreting` seam, availability-gated), falling back to
  `TextRecipeParser`/manual wizard — private, free, offline.
- **Photo-to-recipe** turns a cookbook page or screenshot into a recipe via
  Vision OCR, same on-device parser.
- Every AI/text/photo import lands in a **review/edit step** before saving;
  nothing is saved silently. *Marketing: unlimited free imports vs ReciMe's 5/week.*

### 🟢 Collections & Tags
User-created collections (create / rename / recolour / delete, add/remove
recipes, batch-add to shopping list) and custom tags on recipes (add in wizard
and edit flow, filter by tag, tags survive the full wizard→persistence round-
trip) all ship. Collections are accessible inline from the Recipes tab and from
recipe detail. Filter criteria supports both tag and collection filtering.
Smart collections now ship: `SmartCollection` enum (6 rules — Quick Meals ≤30 min,
Easy Recipes, Vegetarian, Highly Rated ≥4★, Recently Cooked ≤30 days, 5 Ingredients
or Less) auto-populates at read time; `CollectionsInlineView` shows them above
user-created collections with a sparkle badge; tapping opens `SmartCollectionDetailView`
(read-only, same recipe-row layout). Covered by `SmartCollectionTests` (20 tests).
*Remaining:* a dedicated Collections tab if the library grows large enough.

### 🟢 Cuisine tagging
*Problem:* category (e.g. "Main", "Dessert") describes meal position, not
origin. Filtering "show me Italian weeknight mains" requires a separate cuisine
dimension — Italian, Mexican, Asian, Middle Eastern, etc. — that Category
doesn't cover. Most recipe imports include cuisine in JSON-LD (`recipeCuisine`),
which we currently discard.
*What we did:* added `cuisine: String?` to the Core Data entity and `RecipeModel`;
`RecipeImportBuilder` now populates the structured field from `recipeCuisine`
instead of embedding it as freetext in notes; cuisine is a first-class filter in
`RecipeFilterCriteria` (chip multi-select in `FilterSheet`, `ActiveFiltersBar`);
wizard step 6 has a cuisine text field with 12 tap-to-select suggestion chips;
edit sheet pre-populates cuisine. Full round-trip tested.

### 🟢 Cooking Experience
`CookingModeView` ships: step navigation, mark complete, `RecipeTimerManager`
per-step timer (tap ingredient/instruction to start), `isIdleTimerDisabled`
keeps the screen awake, and 56 pt minimum-height tap targets for greasy hands.
- **Timer Live Activity + Widgets** *(needs a Widget Extension target)* —
  running timer on Lock Screen / Dynamic Island; today's-meal-plan, shopping
  -list quick-view, and random-recipe widgets. Consider AlarmKit for cook timers
  with custom UI.
- **Apple Watch companion** *(needs a WatchKit Extension target)* — current
  cooking step and active timer on wrist. Crouton's strongest card; greasy hands
  never need to touch the phone. Step navigation + timer display is the whole
  scope — no need to replicate the full recipe library on watch.
- **Voice/hands-free step navigation** — "Hey Siri, next step" via an
  `AppIntent` exposed cooking-mode action. Zero new UI; just an intent that
  calls the same step-advance logic. Crouton markets this; it's a natural
  follow-on once App Intents land.
- **Text-to-speech step reading** — read the current step aloud as the user navigates, so the phone never needs to be touched. `AVSpeechSynthesizer` on-device (free, no API). Toggle in cooking mode UI. Pairs naturally with the Watch companion and greasy-hands use case.

### 🟢 Shopping list sharing
`KitchenShoppingView` overflow menu → "Share List" formats the grouped list as
plain text via `ShoppingListGrouping.shareText` and hands it to
`UIActivityViewController`. Live share (CloudKit Sharing) deferred to iCloud.

### 🟢 App Intents & Siri shortcuts
*Problem:* RecipeFinder is invisible to the OS. Competitors that register
`AppIntent`s surface in Spotlight, Shortcuts, the Siri suggestion row, and the
Action Button — we appear in none of them.
*What we did:* `AddToShoppingListIntent`, `WhatsForDinnerIntent`,
`OpenRecipeIntent` ("Open recipe in RecipeFinder" → Siri asks for name →
navigates to `RecipeDetailView` via `NavigationPath`), and `StartCookingIntent`
("Start cooking in RecipeFinder") — all wired via `RecipeShortcutsProvider`,
all on-device. Deep-link routing uses `NSNotification("OpenRecipe")`: `ContentView`
switches to the Recipes tab; `RecipeSearchView` (now path-based `NavigationStack`)
pushes the matching recipe by UUID onto `navigationPath`.

### 🟢 Ingredient substitutions
*Problem:* mid-cook "I don't have X, what can I use?" is one of the most
searched cooking queries. Currently users have to leave the app.
*What we did:* `IngredientSubstituteProvider` ships a curated 30+ entry lookup table
covering dairy, eggs, flour, leavening, sweeteners, oils, stocks, and chocolate.
A swap icon appears per ingredient row (only when substitutes exist); tapping opens
`SubstituteSheetView`. Lookup is case/whitespace insensitive with partial-name
fuzzy matching. FoundationModels long-tail fallback deferred to Phase 2.

### 🔴 iCloud Sync *(free-tier feature; blocked on paid enrollment — keep the model ready)*
Note: this is a **free** feature, not a RecipeFinder+ hook — it costs us nothing
(rides the user's own iCloud) and is the data-safety pillar. It's gated only by
the CloudKit *capability*, which needs paid Developer Program enrollment.
`NSPersistentCloudKitContainer` over the existing Core Data stack, using the
user's own iCloud so the privacy story holds. Design work to reconcile
`UserScopedStorage` per-account scoping with iCloud identity, and a sync strategy
for the JSON-backed stores (meal plans, shopping list, inventory). Deferred until
the Developer Program is enrolled; until then the model stays CloudKit-compatible
so enabling it is a switch, not a rewrite.

**Storage-architecture decision — CloudKit private DB, *not* our own backend.**
The question "should we store to S3 or equivalent?" resolves to *no* for personal
libraries. CloudKit's **private database is the S3 equivalent**, hosted in the
*user's own* iCloud: we never see the data, it costs us nothing per user, and
recipe images ride along as `CKAsset`s. Running our own S3/backend would make us
the data controller (GDPR liability for a UK Ltd), add per-user cost for zero
revenue, and contradict the privacy wedge. A real backend earns its place **only
if** we later build *public/social* sharing (see Recipe Sharing) — and even then
CloudKit's **public** database or CloudKit Sharing likely covers it server-lessly.
Revisit S3 only for that public layer, never for private libraries.

**Sync visibility.** There's no separate "cloud browser" to build — synced
recipes simply appear on every device, and that transparency *is* the feature
(iOS already shows usage in Settings → Apple ID → iCloud → Manage Storage). What
we should add is a small **Sync status view in Settings**: on/off toggle,
last-synced time, and a syncing/error indicator, so people trust it's working.
(The CloudKit Dashboard is a *developer* tool for schema and the public DB only —
it can never expose users' private data, by design.)

### 🟢 Nutrition UI surface
*The calculator already exists* (`NutritionCalculator`, tested) and the model
stores nutrition data. What's missing is the UI: a collapsible section on the
recipe detail view showing calories/protein/carbs/fat/fibre per serving,
recalculating on serving changes (the `scaleFactor` already updates quantities
— nutrition just needs to follow). Weekly plan summary is a natural follow-on.
No external API needed for phase 1 — the on-device calculator covers it.
**HealthKit follow-on:** once the UI ships, write per-meal nutrition to Apple
Health via `HKHealthStore` as an opt-in toggle in Settings — expected by
health-conscious users and straightforward to add once the data surface exists.

### 🔴 Supermarket integration *(a genuine premium candidate)*
Match shopping-list items to a retailer's catalogue (Tesco, Sainsbury's, Ocado)
and auto-build a basket via deep links or affiliate APIs (scraping last resort),
with price comparison and smart substitutions. This is added value we can
legitimately charge for.

### 🟡 Recipe sharing
Share recipes as rich links or formatted cards; import shared recipes from other
RecipeFinder users; export as PDF (basic text/PDF share already exists).
**Print action** shipped: `RecipePrintFormatter.html(for:)` generates an HTML
layout (title, meta, two-column ingredients, numbered instructions, notes) and
`present(for:)` bridges to `UIPrintInteractionController` with iPad popover
support. "Print" appears in the detail view overflow menu alongside Edit and Share.
Covered by `RecipePrintFormatterTests` (15 tests — structure, escaping, sections).
*Remaining:* rich link sharing, import from other RecipeFinder users.

### 🔴 Auto recipe images (Unsplash)
Auto-assign images by recipe name. **High priority for the curated library** —
the 300 curated recipes ship with no photography and need images before
RecipeFinder+ launches. URL imports already extract JSON-LD/OG images; user
photos already work. Unsplash covers the gap for manually created and curated
recipes only. Cache locally; API key in `.xcconfig`. Free tier 50 req/hr is fine
for the curated batch; revisit rate limits at multi-user scale.

---

## Operating principles

- **Privacy first** — minimal data collection; all user data scoped per account.
- **Offline first** — core features work without internet; network features
  degrade gracefully.
- **Freemium** — the free tier must be genuinely useful; monetise added value
  (curated content + drops, supermarket integration, advanced planning), never
  basics or things that cost us nothing (imports, iCloud sync).
- **API keys** live in `.xcconfig` files excluded from version control.
- **Clean as we go** — delete stale docs, dead code, and cruft alongside feature
  work, not just app code.

---

## Onboarding & discoverability *(captured 2026-09-26 — ALL DONE 2026-09-26)*
1. ✅ **Wizard intro** — `WizardIntroSheet`, one-time on first create flow (`hasSeenWizardIntro`).
2. ✅ **Make cross-off obvious** — one-time dismissible tip in the ingredients card
   (`hasSeenIngredientTapHint`), auto-hides once anything's checked.
3. ✅ **Tap amount → edit** — was already shipped: `IngredientRowView` quantity pill →
   `onTapQuantity` → wizard ingredients section; name → cross-off.
4. ✅ **Settings tutorial** — added a "Gestures" card to the existing `HelpView`
   (Settings → Help & Support), reusing `HelpItem` rather than a new page.

## Test coverage
The test **suite + CI are the source of truth** for what's covered — a hand-maintained
table here only drifts (it did: it carried the badge-trigger nuance that sent us chasing
working code). Run `RunAllTests`; the README build badge reflects the CI gate. Per-area
testing conventions live in `RecipeFinderTests/CLAUDE.md`.
