# WORK: Pre-launch punch list

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
- [ ] **1. Plus loop works locally** — StoreKit purchase/restore/paywall already built
      and `.storekit` wired to the scheme; the GAP is nothing is gated (`isSubscribed`
      only toggles the Settings card). Decision pending: what Plus gates.
      Plan: launch FREE, build the gate behind a flag, prove the full loop on the local
      `.storekit` config. iCloud sync stays FREE. Recommend a freemium power-feature cap
      (AI/photo import, meal planning) over curated content — no content to gate yet.
- [ ] **2. YOTI-level simplicity** — north-star principle, applies to every view touched.
- [ ] **3. Trim onboarding** — today: 3 slides + biometric splash. Make it leaner.
- [ ] **4. Populated home without loading 300+ at once** — today all recipes load into
      memory on appear (`RecipeStore.load`), no search debounce (re-filters per keystroke).
- [ ] **5. Badges overhaul** — CORRECTED (2026-10-01): the audit's "triggers missing"
      claim was FALSE. All five fire at real call sites (ImportView:127/129,
      MealPlanningManager:78, ShoppingListManager:140, CookingModeView:337);
      shoppingExpert/mealPlanner have integration tests. The one real gap: bulk import
      silently unlocks all count badges with no feedback (wants a single summary toast).
      Smaller than first thought — verify against code before touching.
- [ ] **6. Hide deprecated Apple sign-in item** — `AccountActionsSection.swift:16-55`,
      already `disabled(true)` ("Under Construction"); hide until the entitlement is real
      (needs paid Apple account).
- [ ] **7. "Share with a friend" → App Store link** — missing entirely (only recipe-to-
      recipe ShareLink exists). Add a share entry in Settings.
- [x] **8. Rate-on-App-Store after a significant moment** — DONE. `RecipeDetailView:270`
      fires `requestReview()` after the 3rd cook of a recipe; never cold.
- [x] **9. Timer notifications fire in the background** — DONE. `RecipeTimerManager`
      schedules the completion alert up front at start/resume, cancels on pause/stop.
      Build + 26 timer tests green. (uncommitted)

## New ideas (backlog)
- **Meal-time notifications** — meal-planner slots (breakfast/lunch/dinner/snack) get an
  editable associated time; when that time arrives, notify "Time for Lunch: <recipe>".
  Infra already exists: `NotificationManager.scheduleMealReminder` schedules a
  `UNCalendarNotificationTrigger`. Needs: a per-slot time field on the meal-plan model +
  editable UI (sensible defaults, e.g. 08:00/13:00/19:00) + wire to scheduleMealReminder +
  cancel/reschedule on edit/delete. Natural companion to item 9.

## Core-loop open bugs (single home: CORE_LOOP_AUDIT.md — don't restate here)
The import→find→cook→track loop's ranked open findings live in
[CORE_LOOP_AUDIT.md](CORE_LOOP_AUDIT.md). Still open and worth pulling forward:
- ⚠️ Grocery merge sums by name but **drops the unit** ("flour 6" unitless) — `ShoppingListManager.swift:135`.
- Search debounce (~250ms) — this is the same concern as punch-list item 4; owned there/here, not duplicated into a third place.

## Legal (pre-launch must-fix, not optional)
- In-app `PrivacyPolicyView`/`TermsOfServiceView` text is a fossil of the old
  "purely local, no account" framing — it asserts *no user accounts* and *no personal
  data collected*, which is false now (Apple/email sign-in, Keychain credentials, planned
  iCloud sync). Needs a lawyer-reviewed rewrite before App Store submission. The website
  copy (recipefinder.uk/privacy.html, /terms.html) likely has the same fossil — check both.
  (Stale legal `.md` third copy deleted 2026-10-01; in-app views + website are canonical.)

## Follow-ups / debt
- **Notification seam** — `RecipeTimerManager` calls `NotificationManager.shared` directly,
  so "schedules up front" isn't unit-testable. Inject a protocol to assert it.
- **Bulk-import badge summary** — show one "you earned N achievements" toast instead of
  silently unlocking (ties into item 5).

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
(none — timer fix complete + verified, uncommitted)

## Next action
Pick: **badge overhaul (item 5)** or **meal-time notifications (new idea)**.
