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

**Identity & accounts decision *(2026-10-14)*.** The app runs **no backend** and
won't get one for private libraries. Identity will be **Sign in with Apple only**
once the paid Developer Program is enrolled — there is deliberately **no
first-party email/password account**. A local email login without a server can't
verify emails, reset passwords, or sync, so it was a facade; it also triggers
Apple's Guideline 4.8 (offer email login → *must also* offer Apple). Until
enrolment the app ships **guest-only**: the sign-up/sign-in UI is hidden behind
`AuthUIGate.showAuthUI` (the `AuthenticationManager` engine is kept intact behind
the flag, not deleted; UI tests force it on via `-force-auth-ui`). Every feature —
badges, streaks, profile/personality, import — works **locally for guests**.
**Login unlocks sync/durability (CloudKit), never features.** First-party email
accounts would only earn their place in a cross-platform (Android/web) future,
which is out of scope.

---

## Feature map — what the app does & how solid

The at-a-glance capability list so nobody has to read the source to know what ships and
what's trustworthy. Coarse by design (feature-level, not per-test) so it ages slowly.
Trust: ✅ logic tested via a named suite · ⚠️ partial (unlock/glue only) · 🧪 view-only, no unit test.
The test **suite + CI** remain the source of truth for *coverage detail*; this is orientation.

| Area | Ships | Trust |
|---|---|---|
| **Recipes** — create/edit/delete, favourite, tags, dietary, notes, servings scaling, cook history + rating, multiple photos, ingredient substitutions, nutrition calc | ✅ | ✅ |
| **Import** — URL/link, paste-text, photo OCR, share-extension, on-device AI free-text, social caption fallback, duplicate detection | ✅ | ✅ |
| **Search & filter** — text, category/difficulty/dietary, available-ingredients ("can make now"), tag, collection, sort orders | ✅ | ✅ |
| **Collections & tags** — user CRUD + membership + batch-add; smart collections (6 rules) | ✅ | ✅ |
| **Meal planning** — slots, overwrite, recurring weekly, pantry-aware suggestions, calendar, add-week-to-shopping | ✅ | ✅ |
| **Shopping list** — add/remove/check, add-from-recipe, aisle categorisation, grouping + text share | ✅ | ✅ |
| **Kitchen / pantry** — inventory CRUD, expiry/low-stock alerts, recipe matching, expiry notifications | ✅ | ✅ |
| **Cooking mode** — step nav, per-step timer, screen-awake; timer fires in background | ✅ | ⚠️ timer ✅, step UI 🧪 |
| **Backup / restore** — `.recipefinderbackup` round-trip, per-store merge, per-user scope | ✅ | ✅ |
| **Badges** — 12 achievements, unlock + celebration queue | ✅ | ⚠️ shopping/meal triggers ✅; import/photo/headChef unlock-tested, trigger at call site |
| **Auth & account** — email + Apple sign-in, guest mode, biometrics, Keychain + PBKDF2, session expiry | ✅ | ⚠️ store/session/model ✅; sign-in *flows* 🧪 (DI seam pending) |
| **App Intents / Siri** — add-to-list, what's-for-dinner, open-recipe, start-cooking | ✅ | ⚠️ thin glue |
| **Recipe source refresh** — "view original" + diff-and-reapply | ✅ | ✅ diff tested, sheet 🧪 |
| **Subscription (Plus)** — StoreKit purchase/restore/paywall built | ✅ built | ⚠️ **nothing gated yet** — loop untested (see WORK.md) |
| **iCloud sync** | 🔴 blocked on paid Apple enrollment | — |

---

## Part I — Hardening

Before adding surface area, a campaign made the existing app trustworthy — each
item its own commit + review checkpoint. All 🟢 done; the *why* is kept, the
blow-by-blow is in git.

- **🟢 Auth & credentials** — `KeychainStore` seam (real vs in-memory fake) + pure
  PBKDF2 `PasswordHasher` + credential/session lifecycle tests, including the
  historical account-overwrite and empty-hash bugs. *Why:* credentials are where a
  privacy-first app cannot afford to be wrong.
- **🟢 Search & filter robustness** — word-boundary `KitchenRecipeMatcher`
  (egg↔eggs without reviving ice↔rice), `TimeExtractor` hours + range→upper-bound,
  and `RecipeFilterCriteria` as one `Hashable` value computing match % once and
  keying the cache. *Why:* "find something to cook" must be correct *and* fast.
- **🟢 Failure-state surfacing** — writes return a result the UI acts on (rollback
  + toast) instead of silently showing "Imported" then losing it. *Deferred
  (clean-arch):* a typed error + a single add-and-persist use case to end the
  duplicated optimistic-insert logic across the two import hubs.
- **🟢 Concurrency (Swift 6 strict)** — audited all eleven managers; `BadgeManager`
  `@MainActor`; `UserScopedStorage` documented `Sendable`; removed a latent `@objc`
  hop-crash. No `nonisolated(unsafe)` left. *Why:* races corrupt libraries invisibly.
- **🟢 Import robustness (the corpus)** — a real-world HTML/text fixture bed, and a
  parser hardened against each: JSON-LD `@graph`/`mainEntity`/array nesting,
  microdata, block-level line reconstruction, a canonical `IngredientLineParser`
  (spelled-out units, glued fractions, ranges, no fabricated quantities), note
  fencing. *Why:* no import → empty library → dead app.
- **🟢 Data durability — backup/export** — a `.recipefinderbackup` round-trip
  (`BackupService` + `BackupArchive`/`BackupCodec`) with a non-destructive,
  date-faithful `merge(_:)` on every store, per-user scoped. *Why:* the safety net
  until iCloud is unblocked. (iCloud sync lives in Part III.)

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

Sharpening the product we already have — removing friction, making existing
features pull their weight. All 🟢 done unless a *Remaining* note says otherwise.

- **🟢 The sign-up moment (timing, not the account)** — brand-new users land
  straight into guest mode (no auth wall on first launch); a soft nudge banner +
  guest-gated Import tab make the value moment "I want to save *this* recipe."
  `hasEverAuthenticated` distinguishes new from signed-out across launches.
- **🟢 Notification prompt off launch** — `requestPermission` fires only from
  `RecipeTimerManager` on first timer use, never at launch.
- **🟢 Kill the empty state** — `SeedRecipeProvider` ships 6 bundled starters with
  stable fixed UUIDs (idempotent); guests see them, new users get them seeded once.
- **🟢 Engagement surfaces** — `BadgeEarnedSheet` on any `pendingCelebration`;
  `RequestReviewAction` after the 3rd cook; TipKit (`CanMakeNowTip`, `CookingModeTip`).
- **🟢 iPad layout** — `ContentView` switches on size class: iPhone `TabView`, iPad
  `NavigationSplitView` (section sidebar + detail). *Optional future:* three-column
  list-beside-recipe (Mail/Paprika style) — polish, not a fix.
- **🟢 Recipe image placeholders** — `RecipePlaceholderView`: name-seeded gradient +
  shimmer during load + cross-fade; also the permanent failure fallback.
- **🟢 Smart search & filtering** — all filters ship (text, category, difficulty,
  time, dietary, tags, collection, available-ingredients); criteria is one tested
  `Hashable` value.
- **🟢 Meal planner** — slots, add-week-to-shopping, calendar, drag-reorder,
  recurring weekly meals, and pantry-expiry suggestions
  (`PantryExpirySuggestions` → `ExpiryRecipeSuggestionsSection`). *Remaining:*
  weekly nutrition summary (ties to Nutrition in Part III).
- **🟢 Library sort order** — `SortOrder` (name, highest rated, most cooked);
  match-% ranking wins under "Can Make Now." Tested in `RecipeFilterCriteriaTests`.
- **🟢 Pantry expiry & restock** — alerts surfaced in `PantryAlertsSectionContent`
  + a 6 PM-evening-before `UNCalendarNotificationTrigger` per item. *Remaining:*
  barcode scanning via Vision.
- **🟢 Cook history & rating** — `lastCookedAt`/`cookCount`/`rating` (v12→v13
  migration), written atomically so history survives content edits; feeds the
  rated/most-cooked sort tiers.
- **🟢 Multiple photos per recipe** — up to 4 gallery images beside the hero
  (`RecipeImageStore.persistGallery`), round-tripped through wizard/detail/edit.
- **🟢 Recipe source link & re-fetch** — "View Original" + "Refresh from Source":
  re-runs the importer, `RecipeDiff`s content fields, and offers per-field accept;
  personal data (notes/tags/servings/ratings/history/gallery) always preserved.
  `RecipeDiffTests` (12).
- **🟢 Recurring / staple shopping items** — `isRecurring` on shopping items;
  staples survive list clears (and reset to unchecked) rather than needing re-adding.

---

## Part III — New Features

Net-new bets, ordered by priority.

### 🟢 Capture — the ReciMe loop *(shipped; this is the wedge)*
Live end-to-end: a **share extension** that fetches+parses *in the extension*
(`RecipeImportPipeline`) when it can so the recipe is just *there*; **social/text
import** via on-device FoundationModels (`RecipeTextInterpreting` seam, gated) with
`TextRecipeParser`/wizard fallback; **photo-to-recipe** via Vision OCR. Every
AI/text/photo import lands in a **review/edit step** — nothing saved silently.
*Marketing: unlimited free imports vs ReciMe's 5/week.*

### 🟢 Collections & Tags
User collections (CRUD, add/remove, batch-add to shopping) and custom tags
(wizard + edit, filter, full round-trip) ship, inline from Recipes and detail.
Smart collections ship too: `SmartCollection` (6 rules) auto-populates at read
time with a sparkle badge + read-only detail. `SmartCollectionTests` (20).
*Remaining:* a dedicated Collections tab if the library grows large enough.

### 🟢 Cuisine tagging
`cuisine: String?` on the entity + `RecipeModel`, populated from JSON-LD
`recipeCuisine` (previously discarded) instead of freetext notes; a first-class
filter (chip multi-select) + wizard field (12 suggestion chips) + edit pre-fill.
Full round-trip tested. *Why:* category is meal position, not origin — "Italian
weeknight mains" needs its own dimension.

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
`KitchenShoppingView` → "Share List" formats the grouped list as plain text
(`ShoppingListGrouping.shareText`) into `UIActivityViewController`. Live share
(CloudKit Sharing) deferred to iCloud.

### 🟢 App Intents & Siri shortcuts
`AddToShoppingListIntent`, `WhatsForDinnerIntent`, `OpenRecipeIntent`,
`StartCookingIntent` — all via `RecipeShortcutsProvider`, all on-device; deep-link
routing through `NSNotification("OpenRecipe")` into the path-based Recipes stack.
*Why:* without `AppIntent`s we're invisible to Spotlight/Shortcuts/Action Button.

### 🟢 Ingredient substitutions
`IngredientSubstituteProvider` — a curated 30+ entry table (dairy, eggs, flour,
leavening, sweeteners, oils, stocks, chocolate); per-row swap icon → `SubstituteSheetView`,
case/whitespace-insensitive fuzzy lookup. FoundationModels long-tail fallback
deferred to Phase 2. *Why:* mid-cook "what can I use instead?" shouldn't send users out of the app.

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

## Onboarding & discoverability *(ALL DONE 2026-09-26)*
`WizardIntroSheet` (one-time first-create), a dismissible ingredient cross-off tip
(`hasSeenIngredientTapHint`), tap-amount→edit on the quantity pill, and a "Gestures"
card in `HelpView`.

## Test coverage
The test **suite + CI are the source of truth** for what's covered — a hand-maintained
table here only drifts (it did: it carried the badge-trigger nuance that sent us chasing
working code). Run `RunAllTests`; the README build badge reflects the CI gate. Per-area
testing conventions live in `RecipeFinderTests/CLAUDE.md`.
