# WORK: Pre-launch punch list

## ▶ Resume here (cold start: read this block first, update it last)
- **Prior sessions (committed):** grocery-unit manager fix, build-blocker (legal pbxproj
  refs), badge/restore parade fix, meal-time notifications, ROADMAP compression, search
  debounce (#4), hide WIP Apple-ID row (#6), share-with-a-friend (#7), PremiumGate power-
  feature cap (#1, free at launch). History in git.
- **This session — a full state-of-app audit (4 parallel agents) + fixes. Uncommitted, all
  green (1680 tests):**
  1. **Grocery unit/qty loss — the REAL fix.** Earlier "fixed" was only the manager API; the
     high-traffic detail-view paths bypassed it. New pure `RecipeShoppingList.item(from:)`
     (normalized name + qty + unit); `RecipeDetailView.addIngredient/addAll` now use it.
     +5 `RecipeShoppingListTests`. *(Still open: `MealPlanningView.confirmAddWeek` drops unit —
     needs `WeekShoppingSummary` to model units; separate slice.)*
  2. **Orphaned images on delete (disk leak).** `RecipeStore.delete` now cleans hero +
     gallery files via an injected `RecipeImageStore`. +1 `RecipeStoreTests`.
  3. **Rating placement.** Star rating now only shows after `cookCount > 0` (you rate what
     you've cooked); before first cook the card leads with "Mark as Cooked". (Rating/cooked
     were always post-creation; the bug was showing the rating before ever cooking.)
- **Audit verdicts (see summary below / this turn's chat):** email auth sound (PBKDF2 ok);
  **Apple Sign In is BLOCKED — not a code task:** `com.apple.developer.applesignin` is a
  restricted entitlement requiring PAID enrollment; a free team cannot add it (same gate as
  iCloud/push). Code exists but can't run/test locally — DEFER to enrollment; meanwhile
  consider deleting one of the two divergent dead managers. Purchase loop is complete +
  correct (incl. the `Transaction.updates` listener) but has ZERO StoreKit tests + no
  `SubscriptionProviding` fake.
- **Next action (biggest ask: make the core loop habit-forming — "reward cooking, not
  browsing"):** implement a **cooking streak / activity** loop. Needs a persisted **cook-date
  log** (current data only stores `lastCookedAt`+`cookCount`, so true consecutive-period
  streaks aren't computable yet) → pure `CookingActivity`/`CookingStreak` engine (cooks-this-
  week, streak, days-since, rediscovery pick) → a home/planner habit card + a smart
  re-engagement notification ("you haven't made X in a while"). Do engine+tests first, then
  surface. See "Habit loop plan" section.
- **Verify green:** `BuildProject` + `RunAllTests` before committing anything.
- **Boot ritual:** new session → read this block → `git status` → continue. Nothing else needed.

**North star:** *"ReciMe, but private, unlimited, great at the actual cooking — and your
library is safe."* The core loop everything serves: **get a recipe in → find it → cook
from it well → decide what to cook next.** Full direction in [ROADMAP.md](ROADMAP.md);
front door is [HANDBOOK.md](HANDBOOK.md). Every item below must earn its place in that loop.

The canonical "are we there yet" tracker — where we are vs. where ROADMAP says we're going.
Per slice: `BuildProject` + affected `RunSomeTests` green before it's "done". WIP=1 — one
item active at a time. Leave verified work uncommitted for the user to review.

**Before building any item, verify its premise against the code** (audits/status markers
drift — see item 5, where the audit was wrong and the ROADMAP right). This is what keeps
the loop self-correcting, not just a to-do list.

## Status
`[x]` done & verified · `[~]` in progress · `[ ]` not started

## Launch punch list
- [x] **1. Plus gating** — DONE (uncommitted; decision made 2026-10-02: power-feature cap).
      `PremiumGate` (pure, tested) with master flag `isEnabled = false` → **launch free, nothing
      gated**; flip to enforce. Gated entry points route to `PaywallView`: AI paste-text import
      + photo OCR import (`ImportView.gated(_:_:)`), meal reminders (`MealPlanningView.editReminder`).
      URL import, manual wizard, iCloud sync, organisation stay free. +10 `PremiumGateTests`.
      To prove the full purchase→gate→unlock loop locally: flip `PremiumGate.isEnabled` to `true`
      in a dev build and buy via the local `.storekit`. Still TODO before charging: decide the
      remote/remote-config source for `isEnabled`, and the paywall copy for each gated feature.
- [~] **10. Habit loop (make the core loop habit-forming)** — WEEKLY cooking streak (reward
      cooking, not app-opens; decided 2026-10-02). Foundation DONE & green (uncommitted):
      - [x] **(a) Cook-date log** — `CookingStreakManager` persists `[Date]` cook log in
        `UserScopedStorage` (per-user); records from the single cook choke point
        (`RecipeDetailView.recordCook` → `cookingStreak.recordCookToday()`); reloads on
        account switch (`reloadAllManagers`) + data reset (`DataManagementSettingsView`).
      - [x] **(b) Pure `CookingStreak` engine** — weekly streak with a one-week grace,
        cooks-this-week; +7 `CookingStreakTests`, +4 `CookingStreakManagerTests`.
      - [x] **(c) Surface** — REPOSITIONED (Duolingo-style): a compact `StreakChip` (flame + week
        count) lives in the Recipes **header**, always visible, orange when on-track / **yellow when
        at risk** (loss aversion via `CookingStreak.isAtRisk`). Replaced the bulky `CookingStreakCard`
        (deleted). Chip hidden for an empty library / zero streak. +3 `isAtRisk` tests.
      - [x] **(d) Smart re-engagement notification** — DONE. When the streak is **at risk** (live
        streak, no cook yet this week) the manager schedules a one-shot end-of-week nudge ("Keep
        your 🔥 N-week streak") via a new `StreakReminderScheduling` seam + `NotificationManager`;
        cooking clears at-risk → the nudge is cancelled, a new week re-arms it. Pure
        `CookingStreak.lapseReminder(for:now:calendar:hour:)` (last day of week @18:00, future-only).
        Non-intrusive: no new permission prompt — rides existing notification authorization.
        +3 pure tests + 1 manager cancel-on-cook test (fake scheduler).
      - [x] **(e) Rediscovery nudge** — DONE. Pure `RecipeRediscovery.pick` (stale cooked recipe,
        favour favourite/rating, oldest tie-break; +6 tests) + `RediscoveryCard` on the Recipes
        home below the streak card (browse state only); tap opens the recipe via `navigationPath`.
      - [x] **(f) Milestone celebration** — DONE. `recordCook` returns whether it extended the
        streak; `RecipeDetailView.recordCook` fires confetti + `HapticManager.celebrate()` +
        "🔥 N-week streak!" toast on extend. +2 `CookingStreakManagerTests`.
      - [ ] **(g)** Wire the dead `CanMakeNowTip` (defined in `RecipeTips.swift`, never attached).
      - [ ] **(h)** Consider a streak-freeze/"rest day" grace like Duolingo if churn data shows
        week-misses hurt; and decide whether to show the card during active search/filter.
- [ ] **11. Apple Sign In — BLOCKED on paid enrollment, not code.** `com.apple.developer.applesignin`
      is a restricted entitlement; a free team can't add it (confirmed via Apple docs/forums).
      DEFER until Developer Program enrollment. Pre-work that IS doable now: delete/ consolidate
      the two divergent dead managers (`AuthenticationManager+AppleSignIn` [Keychain, correct] vs
      `AppleSignInManager` [UserDefaults, wrong]) down to one, so enabling later is clean.
- [x] **15. Habit-loop UI verification + smoke test** — ran the app on the simulator (found &
      fixed a real bug: the streak chip collided with the centered "RecipeFinder" title in the
      header → moved it to a slim left-aligned row under the title). Added
      `RecipeFinderHabitLoopUITests` (2): cook → rating + streak chip appear; import screen has no
      example links. Added `streak.chip`/`recipe.rating`/`recipe.row` accessibility IDs. Visually
      confirmed chip renders as "🔥 1" cleanly. Note: raw simctl can't drive taps (no idb) →
      XCUITest is the GUI handle here.
- [x] **16. Streak → floating fire badge (not a row)** — moved `StreakChip` from its own header
      row into a top-left `.overlay` on the title bar (title stays centred, menu top-right); takes
      zero vertical space. Verified visually via simctl screenshot (🔥1 top-left) + the habit-loop
      UITest still finds `streak.chip`.
- [x] **17. Import parser misses amounts — FIXED.** Root cause (measured over the 355-entry
      `recipes_seed.json`): WordPress-Recipe-Maker `▢` checkbox glyphs prefix ingredient lines
      (`▢100 g flour`), which `IngredientLineParser` didn't strip → qty 0, unit "", whole string
      became the name. Fix: strip leading list/checkbox markers at the top of
      `IngredientLineParser.parse` (fixes ALL callers) + added the box glyphs to
      `TextRecipeParser.isBulletCharacter`. 60-entry sample → 55 good / 5 marginal / 0 nil; Achari
      Chicken 22/22→2/22 zero-qty. +7 `IngredientLineParserTests`. *Note:* already-seeded recipes in
      an existing account keep their old parse (seed runs once, skips existing names) — only
      re-imports / fresh accounts get the fix.
      **Corpus quality GATE added** (`SeedCorpusParseQualityTests`): parses all 355 seed entries every
      build. TWO checks: (1) `seedCorpusParsesWithRealAmounts` — aggregate floor `parseNil <= 3` +
      `good% >= 88`; (2) `eachSeedRecipeMatchesKnownQuality` — PER-RECIPE gate vs a pinned golden set
      (`RecipeSeed/seed_parse_known_poor.json`, 34 names): fails naming the exact recipe if a non-listed
      one degrades (regression) OR a listed one recovers (shrink the list). Measured now: **355 total, 3
      unparseable, 321 good (90%), 31 poor** (up from 85%) — so "is the seed OK?" is answered by CI,
      not manual checking; any regression fails the build with the specific recipe named.
      **Second fix pass (this session), all +tests green:** (a) name-first embedded amounts
      ("Minced chicken 500g" → 500 g) via `extractEmbeddedAmount`; (b) leading scrape/scale artifacts
      ("750 500 grams"→500 g, "5 1 teaspoon"→1 tsp, "8421052632 2 cups"→2 cups, "4210526316 1/2 tsp"→
      0.5 tsp) — a bare integer immediately followed by another number is dropped (artifact loop +
      1–2-digit cap on the mixed-number rule + glued-number re-split). +6 `dropsLeadingScrapeArtifact`
      cases. Floor raised 84→88 to lock the gain.
      **Remaining residual (31 poor + 3 nil) is NO LONGER a per-line amount bug** — it's dominated by
      METHOD/instruction prose leaking into the ingredient list ("Steps to Make It", "In a large
      bowl…", "Recipe Variations", "YouTube Tutorial") plus genuinely-unitless spice lists and caps
      sub-headers. The real amounts in those recipes DO parse; the junk lines inflate the zero-count.
      **Next (separate, riskier task):** `TextRecipeParser` section-detection — stop the method section
      bleeding into ingredients when no explicit method header is found. Affects the whole import path,
      not just seed data → own slice with its own fixture bed. Do NOT fold into the per-line parser.
- [x] **14. Removed dead import example links** — the 3 hardcoded "Try these examples" URLs in
      `RecipeImportView` (AllRecipes/BBC/Taming Twins) rotted and made import look broken on first
      tap. Deleted them + the `exampleButton` helper; kept the reassurance copy. If examples ever
      return, they must be a CI-verified set (a test that fetches+parses, failing when one rots).
- [ ] **12. confirmAddWeek unit loss** — `WeekShoppingSummary.Item` has no unit; weekly add-to-
      groceries drops units. Needs the summary to model units (merge across recipes by name+unit).
- [ ] **13. Test gaps from the audit** (stop manual retesting): `SubscriptionProviding` fake +
      StoreKitTest `SKTestSession` suite (purchase/restore/**revoke→isSubscribed flips**); auth
      orchestration (signIn/signUp/duplicate-guard/signOut/session-expiry/guest); extract a
      cooking-mode view-model (step count/progress off-by-one + headChef-on-finish); `recordCook`
      review-threshold helper (2→no,3→yes,4→no); import→save→appears flow with a failing-persist fake.
- [ ] **2. YOTI-level simplicity** — north-star principle, applies to every view touched.
- [ ] **3. Trim onboarding** — today: 3 slides + biometric splash. Make it leaner.
- [x] **4. Search debounce** — DONE (uncommitted). `FilterCacheUpdateModifier` now debounces
      criteria changes ~250 ms via `.task(id: filterCriteria)` (cancels the pending sleep on
      each keystroke), so `apply(to:)` runs once on pause instead of per keystroke; library
      changes still reflect immediately. The "loads 300 into memory" half was a non-issue —
      fetch is off-main (`fetchRecipesAsync`) and SwiftUI renders lazily, so no pagination
      needed. Build green; no logic changed (filter logic stays covered by
      `RecipeFilterCriteriaTests`). Also closes the CORE_LOOP_AUDIT search-debounce item.
- [x] **5. Badges overhaul** — DONE (premise re-corrected 2026-10-01). The "bulk import
      silently unlocks, no feedback" claim was itself WRONG. No user-facing bulk *import*
      exists (import = 1 recipe = 1 celebration); seed is silent by design. The real wart
      was **backup restore** popping a parade of milestone sheets (`mergeRecipes` →
      `saveRecipe` → `checkAndUnlockBadges` non-silent, before `badges.merge` runs). Fixed
      by suppressing celebrations during `mergeRecipes` via `isBulkImporting`. No toast —
      it would have been the wrong fix. (uncommitted; +2 BadgeManagerTests)
- [x] **6. Hide deprecated Apple sign-in item** — DONE (uncommitted). `AccountView.swift`
      now passes `showLinkAppleID: false` (component kept intact; comment says flip back when
      the entitlement is live). The "Under Construction" row no longer ships.
- [x] **7. "Share with a friend" → App Store link** — DONE (uncommitted). "Share with a
      Friend" `ShareLink` card added to Settings (Support area). Uses recipefinder.uk until
      the App Store listing exists (comment to swap to apps.apple.com at launch).
- [x] **8. Rate-on-App-Store after a significant moment** — DONE. `RecipeDetailView:270`
      fires `requestReview()` after the 3rd cook of a recipe; never cold.
- [x] **9. Timer notifications fire in the background** — DONE. `RecipeTimerManager`
      schedules the completion alert up front at start/resume, cancels on pause/stop.
      Build + 26 timer tests green. (uncommitted)

## New ideas (backlog)
- ✅ **Meal-time notifications** — SHIPPED (uncommitted). See resume block item 4.

## Core-loop open bugs (single home: CORE_LOOP_AUDIT.md — don't restate here)
The import→find→cook→track loop's ranked open findings live in
[CORE_LOOP_AUDIT.md](CORE_LOOP_AUDIT.md). Still open and worth pulling forward:
- ✅ FIXED (uncommitted) Grocery merge dropped the unit ("flour 6" unitless) — `ShoppingListManager` now stores + merges on name+unit.
- Search debounce (~250ms) — this is the same concern as punch-list item 4; owned there/here, not duplicated into a third place.

## Legal (pre-launch must-fix, not optional)
- In-app `PrivacyPolicyView`/`TermsOfServiceView` text is a fossil of the old
  "purely local, no account" framing — it asserts *no user accounts* and *no personal
  data collected*, which is false now (Apple/email sign-in, Keychain credentials, planned
  iCloud sync). Needs a lawyer-reviewed rewrite before App Store submission. The website
  copy (recipefinder.uk/privacy.html, /terms.html) likely has the same fossil — check both.
  (Stale legal `.md` third copy deleted 2026-10-01; in-app views + website are canonical.)

## Follow-ups / debt
- **Notification seam (partial)** — meal reminders now go through the testable
  `MealReminderScheduling` seam. `RecipeTimerManager` STILL calls `NotificationManager.shared`
  directly (its "schedules up front" path remains unasserted); give it the same seam.

## Decisions
- **Common Crawl / millions-scale validation: PARKED.** Removed `harvest_commoncrawl.py`
  + `commoncrawl_query.sql`. Kept `fetch_and_label.py` + `urls.txt` + the corpus-gated
  `ImportAccuracyHarnessTests` (the live-URL labeller that produced 94% fallback / 100%
  structured). Why: CC denies anonymous S3 LIST; no AWS/bandwidth in the sandbox; marginal
  value is low vs. infra cost. Revive only in CI with real AWS creds if ever needed.
- **Plus = launch free, gate behind a flag, test loop locally.** iCloud sync stays free
  (table stakes). Freemium power-feature cap > curated content for launch (reversible,
  zero new content). What exactly to gate is still the user's open call.
- **Timer notifications scheduled up front**, not sent from the in-app ticker (which is
  suspended in the background).

## Badge overhaul + Cooking sheet (DONE this session, uncommitted, 1776 green)
Approved direction: full cook-centric overhaul + tappable streak chip → Cooking sheet. Shipped:
- **Model** (`BadgeModel.swift`): new `BadgeCriterion`/`BadgeMetric` abstraction + pure `BadgeMetrics.from(recipes:streakWeeks:)`; **12 new badges** — cook volume (Head Chef=first cook, Home Cook 10, Seasoned 25, Kitchen Veteran 50, Iron Chef 100), streak (On a Roll 2, Hot Streak 4, Unstoppable 12, Year of Cooking 52), Globetrotter (5 cuisines), Signature Dish (one recipe ×5), Critic (rate 10), Food Stylist (cook photo). `requiredCount` now derived from criterion.
- **Manager** (`BadgeManager.swift`): added `checkAndUnlockBadges(metrics:)`; the legacy `recipeCount` path is guarded to collection badges only (regression-tested so a big library can't unlock cooking badges).
- **Wiring** (`RecipeDetailView`): `recordCook`/`addCookPhoto`/`updateRating` call `refreshCookingBadges()` → marking as cooked is now the main path to badges.
- **Progress bars** (`BadgeDetailView`): locked threshold badges show current/target, computed from env metrics.
- **Cooking sheet** (`Components/Sheets/CookingSheet.swift`, NEW): streak chip is now a Button → sheet explaining the streak in plain language + cooking-badge progress. Answers "users won't know what the flame means."
- Tests: +new `BadgeModelTests` (metrics aggregation, progress, criteria) + `BadgeManagerTests` (metrics path, breadth/depth/quality, recipe-count regression guard).

**Follow-ups (not done):** (a) "Variety Pack" (3 cuisines in one week) deferred — needs a time-windowed metric; (b) `CookingModeView:337` still unlocks headChef directly — now redundant (recordCook covers it) but harmless, remove when touching that file; (c) one-time migration so already-cooked recipes backfill cook badges on upgrade (currently they unlock on the next cook); (d) visually verify the Cooking sheet + progress bars on-device.

## In progress
(none — badge overhaul complete + verified green at 1776 tests, uncommitted)

## Next action
Visually verify the Cooking sheet / badge progress on the simulator, or pick the next punch-list item.
