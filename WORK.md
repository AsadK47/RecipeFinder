# WORK: Pre-launch punch list

## ▶ Resume here (cold start: read this block first, update it last)
- **Last done (uncommitted, all green — 1653 tests):** two fixes landed this session.
  1. **Grocery unit-drop bug** — `ShoppingListManager.addItem` now threads `unit`; merge
     matches name **+** unit so "200 g flour" and "2 cups flour" stay separate instead of
     collapsing to a unitless sum. `addIngredients(from:)` passes `ingredient.unit`.
     +3 tests in `ShoppingListFromRecipeTests`.
  2. **Build-blocker** — `legal/TERMS_OF_SERVICE.md` + `legal/PRIVACY_POLICY.md` were
     deleted in `a8d807b` but still referenced in `project.pbxproj` as Resources, so `main`
     did NOT build. Removed the 8 dangling references (nothing loads them at runtime).
  3. **Badge/restore parade (item 5, premise re-corrected)** — the "bulk import silently
     unlocks, no feedback" premise is WRONG. Reality: normal import = 1 recipe = 1
     celebration; seed = silent by design; the real wart is **backup restore**
     (`BackupService.restore:53 → mergeRecipes`) looping `saveRecipe → checkAndUnlockBadges`
     non-silently → a PARADE of milestone sheets. Fixed by wrapping `mergeRecipes` in
     `BadgeManager.shared.isBulkImporting` (mirrors the seed + `badges.merge` suppression).
     +2 tests in `BadgeManagerTests`. No "summary toast" built — it was the wrong fix.
- **Uncommitted in working tree:** the three fixes above (ShoppingListManager, pbxproj,
  PersistenceController+RecipeWrites, BadgeManager + 2 test files). Review + commit per the
  3 suggested messages. Run `git status`.
- **Next action:** **meal-time notifications** (slice 3) — needs a product decision + a
  notification-scheduling seam first (see "New ideas" + "Follow-ups"). Then optionally the
  ROADMAP compression (docs, token-heavy, low value — confirm it's still wanted).
- **Open decision (still awaiting "go"):** compress ROADMAP Part I/II/III done-feature
  *prose* → one-liners (keep all why/decisions + open items; ~555→~200 lines) + fold
  `CORE_LOOP_AUDIT.md`'s 2 open items here. Nothing cut yet.
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
- [x] **5. Badges overhaul** — DONE (premise re-corrected 2026-10-01). The "bulk import
      silently unlocks, no feedback" claim was itself WRONG. No user-facing bulk *import*
      exists (import = 1 recipe = 1 celebration); seed is silent by design. The real wart
      was **backup restore** popping a parade of milestone sheets (`mergeRecipes` →
      `saveRecipe` → `checkAndUnlockBadges` non-silent, before `badges.merge` runs). Fixed
      by suppressing celebrations during `mergeRecipes` via `isBulkImporting`. No toast —
      it would have been the wrong fix. (uncommitted; +2 BadgeManagerTests)
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
(none — slices 1+2 complete + verified green, uncommitted)

## Next action
**Meal-time notifications (slice 3).** Before coding, get the product-shape decision
(opt-in vs on-by-default, default times, one-shot vs repeat, editor location) and add a
`MealReminderScheduling` seam over `NotificationManager` so `MealPlanningManager` scheduling
is unit-testable. Then: `MealPlanModel.reminderTime` → schedule on add/update, cancel on
remove/clearOld, reschedule on propagateRecurring (don't miss a mutation path) → editable UI.
