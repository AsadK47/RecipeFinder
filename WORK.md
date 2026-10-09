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
- [ ] **17. Import parser misses amounts on some recipes** — e.g. "Sourdough Bread" imports with no
      quantities, everything dumped into description/notes (ingredient section not detected). NEEDS
      the failing input (URL or pasted text) to reproduce → add to the fixture bed, write a failing
      test, then fix `TextRecipeParser`/`IngredientLineParser`/`RecipeParser`. Don't guess.
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

## In progress
(none — slices 1–3 complete + verified green at 1664 tests, uncommitted)

## Next action
Optional: ROADMAP prose compression (confirm still wanted) or the next punch-list item.
