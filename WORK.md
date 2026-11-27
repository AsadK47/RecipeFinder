# WORK.md — handoff (2026-11-26, builder agent)

## In progress
Three parallel lanes (owner 2026-11-15), batch landing via `agent/batch` (BACKLOG step 7):
- Data: `agent/recently-deleted` (6dcdf77) green + 3 review rounds done — CloudKit Production schema has model 17 + model 18 `CD_Recipe.CD_deletedAt` (owner 2026-11-25) — unblocked; branch is from 15 Nov, rebase on main before landing. If model 18's field differs from `deletedAt` Date on `Recipe`, deploy again.
- Cook: ✅ slice 1 landed (85bfddf). Next slice: cooking mode one step per screen + Next, progress, per-step ingredients, timers, resume, last step → Made it.
- Discover: ✅ endless discovery landed (2b6847f). Polish noted: feature tile leaves a gap between title and time.
- CI (CI lane, owner TOP): landed f343fa5 + d775cf6 (prepare action, cached booted simulator, 4 UI shards, coverage.yml). Jobs 7:40–10; wall time hurt by runner queueing (Needs owner) and unit-job variance. Next: sample the test host during the ~60s XCTest stall (`xcrun simctl spawn $SIM spindump` or `sample` on RecipeFinder) on agent/ci-10min, then 3 consecutive pushes ≤10 → tick.
- Privacy: ✅ landed 037a8ea. Website: ✅ privacy.html mirrors the app's 24 Nov policy, and §12/cookies.html describe the site's own data (Web3Forms, Gmail, GitHub Pages + Cloudflare, localStorage) — recipefinderwebsite 1130b83, 4 reviewers.

- Inbox 🟡 Reset store copies: ⏸ parked in Needs owner (data-loss risk on `.corrupt-*`, 2 reviewers agree); branch `agent/reset-store-copies` (87f5737) unmerged, Decisions on that branch's WORK.md — rework per owner's answer.
- Remember: ✅ **My Cookbook** done — slice 3 (share a page) landed 0adbf0b (builder 2026-11-16); notes / "who it was
  for" → Needs owner (model). Leftover branches agent/my-cookbook-2, agent/cookbook-share (auto-cleanup).
  `testBadgeRevealViewAllClosesAndOpensMe` flaked a 3rd time → Inbox 🟡 (read its "queued reveal" checkpoint).

- Docs: 🚧 **Docs refresh** slice 5a landed (builder 2026-11-16) — CHANGELOG = per-change "For you" + "Behind the
  build" entries, `tools/website-behind-the-build.py` (`--check`), old Log archive → `docs/LOG.md`. Next: slice 7 landed
  (docs-only). Only (5b) left — website session adds `behind-the-build.html` with markers and runs the script weekly
  with whats-new, after `privacy.html` updates; then tick. Leftover branch agent/docs-refresh-5 (auto-cleanup).

- Smells: ✅ Batch E recipe-writes split (46d6749, builder 2026-11-21; leftover branch agent/recipe-writes-split, auto-cleanup). ✅ Batch A, B (stale, no code), C (e39fe71). 🚧 Batch D: ✅ screen 1 MealPlanningView (d52b80d), ✅ screen 2
  RecipeSearchView (eaaccc2), ✅ screen 3 CookingModeView (7f4580c, builder 2026-11-19) — Batch D done. Leftover branches
  agent/meal-planning-split, agent/recipe-search-split, agent/cooking-mode-split (auto-cleanup). Top Smell (times → Int minutes) waits on Needs owner.

- Tester feedback 1: ✅ slices 1 (3ed805c), 2 Badges from Today (7f8e5b1, builder 2026-11-17), 4. ✅ 3 foreign recipes
  (d7bf8f7, builder 2026-11-17). Left: slice 5 (Cook lane's). Leftover branch agent/foreign-recipes (auto-cleanup). Leftover branches agent/cuisine-chip,
  agent/today-badges-link (auto-cleanup).

- Me with character: ✅ done — slice 4b cooking story landed 40253df (builder 2026-11-18). Leftover branches agent/me-hero,
  agent/me-name-inline, agent/me-badges-next-up, agent/me-taste-story, agent/me-cooking-story, agent/sweet-chilli-name,
  agent/batch (auto-cleanup).

- Kitchen you can find: ✅ done — slice 2 landed f8960bb (Today "Your kitchen →" links + "In kitchen" tag → At home,
  builder 2026-11-17). Leftover branches agent/kitchen-at-home, -2, agent/kitchen-today-links (auto-cleanup).

- Cook: ✅ **Cooking flow** done — slice 4 last step → Made it landed c1cafb8 (builder 2026-11-19). Leftover branches
  agent/cooking-resume, agent/cooking-timers, agent/cooking-made-it (auto-cleanup).

- Plan: 🚧 **Plan — swipe to match** — slices 1 (23134c8) and 2 week photos (06094b2, builder 2026-11-19) landed.
  ✅ Slice 5 Sunday nudge landed 6954ab2, ✅ slice 6 busy nights landed 6f5d2eb, ✅ slice 4 30-day memory landed 47a3e95 (builder 2026-11-20). Leftover branch agent/plan-deck-memory (auto-cleanup). Leftover branches
  agent/plan-sunday-nudge, agent/plan-busy-nights (auto-cleanup).
  Slice 3 (up = tonight) ⏸ Needs owner — branch `agent/plan-deck-tonight` (e45d1ce: model `planTonight`/`canPlanTonight`,
  view swipe up + "Have it tonight", unit + UI tests, 2 review fixes) unmerged; rework per owner's (a)/(b)/(c).
  Open: `tonight` is fixed at deck open (midnight-open deck plans yesterday) — fix in the rework. Leftover branches agent/plan-deck, agent/plan-week-photos (auto-cleanup).

- Inbox 🐞: ✅ Sunday Planning denied landed 9a01bb5, ✅ testZZZPlanMyWeek busy query landed 89fb7a4 (builder 2026-11-20).
  Leftover branches agent/sunday-nudge-denied, agent/plan-busy-test (auto-cleanup).

- Get: 🚧 **Groceries writes itself** — ✅ slice 1 plan → list landed 257c72b (builder 2026-11-20). Leftover branch
  agent/groceries-from-plan (auto-cleanup).
  ✅ Slice 2 shop mode landed 1505253 (builder 2026-11-20). Leftover branch agent/groceries-shop-mode (auto-cleanup).
  ✅ Slice 3 aisle order landed 9dda50b (builder 2026-11-20). Leftover branch agent/groceries-aisle-order (auto-cleanup).
  ✅ Slice 5 delete duplicates landed 39bf095 (builder 2026-11-21). Leftover branches agent/groceries-delete-dupes, -2
  (auto-cleanup). ✅ Slice 4 "Still got the coriander?" landed 3f81c28 (builder 2026-11-21) — **item done** ✅.
  Leftover branch agent/groceries-still-got (auto-cleanup).

- Inbox 🟡 **Keep screen awake**: ✅ landed 7e70ceb (builder 2026-11-20). Leftover branch agent/keep-screen-awake (auto-cleanup).
- 🐞 **Meal planning is buggy**: ✅ landed 0acb4fd (interactive session 2026-11-20). Skip-one-week → Needs owner.
  Leftover branches agent/plan-bugs, agent/plan-bugs-ui-red, agent/plan-bugs-2 (auto-cleanup).

- Today: ✅ **Today — decide tonight** done — slice 3 one "do this now" nudge landed 86d5811 (builder 2026-11-21).
  Leftover branches agent/today-trim-shelves, agent/today-next-meal, -2, agent/today-nudge (auto-cleanup).
  Plan-vs-suggestion ordering → Needs owner.

- Theme: ✅ **Theme palette by colour theory** — ✅ slice 1 landed a45fecd (builder 2026-11-21; leftover branch
  agent/theme-palette, auto-cleanup). ✅ Slice 2a landed b3d81b7 (builder 2026-11-21; leftover branch agent/theme-a11y,
  auto-cleanup). ✅ Slice 2b symbols landed 408dd08 — **item done**
  (leftover branch agent/theme-symbols, auto-cleanup).

## Next action
✅ Inbox 🐞 timer normalisation landed 89f41e3..93c1f1b (builder 2026-11-27; leftover branches agent/timer-normalise auto-cleanup, agent/timer-normalise-red unmerged — delete). Next: Inbox 🐞 `RecipeStore.swift:337` `seedIfNeeded` gates vs a recovered store (data — two reviewers), then 🐞 `TimeExtractor` dash/fraction normalisation.
✅ Inbox 🐞 nightly `testCaptureTodayPlanned` clock dependence landed 03690b9..1eb0dd7 (builder 2026-11-27; also TodayTimes afternoon 15:00 → 17:00; leftover branch agent/today-planned-clock auto-cleanup). Next: Inbox 🐞 timer normalisation (`CookingPlan.swift:89` U+2044 / U+2011 / "1-½") — red tests first.
✅ Inbox 🐞 "1-1/2 hours" step timers landed aad6ef5..13693da (builder 2026-11-27; leftover branches agent/dash-fraction-timers auto-cleanup, agent/dash-fraction-timers-red unmerged — delete). Next: Inbox 🐞 nightly `testCaptureTodayPlanned` clock dependence (RecipeFinderScreenshotTests.swift:539 — pin "now" via a DEBUG launch argument), then 🐞 timer normalisation (U+2044 / U+2011 / "1-½").
✅ Inbox 🐞 "and a half" step timers landed d233e9f..f976eaa (builder 2026-11-27; leftover branches agent/half-timers auto-cleanup, agent/half-timers-red unmerged — delete). agent/refresh-sync-guard-red red run confirmed and relabelled. Next: Inbox 🐞 `CookingPlan.swift` "1-1/2 hours" (dash as range only when the second amount is larger), then the new 🐞 nightly `testCaptureTodayPlanned` clock dependence.
✅ Inbox 🔴 sample refresh overwrites synced edits landed 5b18b43..addaf9b (builder 2026-11-27; leftover branches agent/refresh-sync-guard auto-cleanup, agent/refresh-sync-guard-red unmerged — delete; confirm its red run 45929470612 and relabel the Log line). Next: Inbox 🐞 `CookingPlan.swift:88` "and a half" timers (fixture-first), then 🐞 "1-1/2 hours".
✅ Inbox 🐞 store opened after unlock landed f1b15a8..5c3ef30 (builder 2026-11-27; leftover branches agent/store-late-open auto-cleanup, agent/store-late-open-red unmerged — delete). Next: Inbox 🔴 `RecipeStore.swift:146` `refreshStaleSamples` overwrites synced edits (first open 🔴/🐞 needing no owner), then 🐞 `CookingPlan.swift:88` "and a half" timers.
⏸ Inbox 🐞 shared recipe file read receipt → Needs owner (builder 2026-11-26): image-only fix on `agent/shared-file-image` (4601ae9) + red tests `agent/shared-file-image-red` (8ca86a9), both unmerged — rework per the owner's (a)/(b)/(c); the fix alone makes the refresh sheet offer "Hero Image" on every open, so don't land it as is. Next: first open Inbox 🔴/🐞 needing no owner, else Launch lane (a) *Recipes in our own words*.
✅ Inbox 🐞 copy merge losing hero landed 6543b14..9f45133 (builder 2026-11-26; leftover branches agent/merge-hero-photo auto-cleanup, agent/merge-hero-photo-red unmerged — delete). Next: Inbox 🐞 shared recipe file import — drop the remote `imageURL` on file import (CHALLENGES 498; read receipt to the sender).
✅ Inbox 🐞 step timer phrases landed ff80a1c..33ab63f (builder 2026-11-26; leftover branches agent/timer-phrases red unmerged — delete, agent/timer-phrases-fix auto-cleanup). Next: Inbox 🐞 `mergeSyncedRecipeCopies` losing hero `imageName` → move it into `photoNames` (iCloud sync, two reviewers).
✅ Inbox 🐞 difficulty parser landed 3d1c5d1..c07ac7a (builder 2026-11-26; leftover branches agent/difficulty-parser auto-cleanup, agent/difficulty-parser-red unmerged — delete). Next: Inbox 🐞 `CookingPlan.swift` `timerRegex` ("an hour", "1½ hours", ranges → lower bound) — fixture-first.
✅ Inbox 🔴 Mary Berry Fish Pie rename (+ Pret cookies) landed d5e9de6..513679a (builder 2026-11-26; leftover branches agent/fish-pie-rename, agent/fish-pie-rename-red unmerged — delete; agent/fish-pie-rename-2 auto-cleanup). Next: Inbox 🐞 `RecipeWizardBuilder.swift:72-80` difficulty substring → one tested `Difficulty` parser.
✅ Inbox 🐞 expiry reminder past 18:00 landed df62ded..0c0bf9a (builder 2026-11-26; leftover branches agent/expiry-past-trigger remote pre-rebase, agent/expiry-past-trigger-red unmerged — delete both). Next: Inbox 🐞 `RecipeWizardBuilder.swift:72-80` difficulty substring → one tested `Difficulty` parser (first open Inbox 🐞 needing no owner; 🔴 Mary Berry Fish Pie rename is above it — take it first if the own-words lane is free).
✅ Inbox 🐞 Import resource limits done — slice 2 landed 719e3ef..9f86aa7 (builder 2026-11-26; leftover branches agent/import-file-coordinator auto-cleanup, agent/import-file-coordinator-red unmerged — delete). Next: Inbox 🐞 `NotificationManager.swift` `scheduleExpiryNotification` 18:00 past trigger (first open Inbox 🐞).
✅ Inbox 🐞 Import resource limits slice 1 landed 6fe121d..78686c7 (builder 2026-11-26). Next: slice 2 — `RecipeFileExporter.read(from:)` coordinated read via `NSFileCoordinator` (red test first), then tick the item.
✅ Inbox 🐞 CI hardening (3) script tests landed c3f1011..e74e395 (builder 2026-11-26; leftover branch agent/script-tests auto-cleanup). Next: Inbox 🐞 Import resource limits (`HTMLFetcher.swift:33` streamed ~5 MB cap + total timeout, `NSFileCoordinator` on file open).
✅ Inbox 🐞 CI hardening (2) landed 757fa39..4318d7c (builder 2026-11-26; leftover branch agent/ci-hardening auto-cleanup). Next: Inbox 🐞 CI hardening (3) — one ubuntu job runs `.github/scripts/test_*.py` + `tools/website-behind-the-build.py --check` on script changes; then Inbox 🐞 Import resource limits.
✅ Inbox 🔴 store recovery waits for unlock landed cc506b3..f869bee (builder 2026-11-26; leftover branches agent/store-recovery-unlock auto-cleanup, agent/store-recovery-unlock-red unmerged — delete). Next: Inbox 🐞 CI hardening (2) — commit `Package.resolved`, pin `uses:` to SHAs, `dependabot.yml` + `SECURITY.md` (first open Inbox item after it).
✅ Inbox 🔴 Reset clears Kingfisher's picture cache landed 40a86b8..262c952 (builder 2026-11-26; leftover branches agent/reset-picture-cache auto-cleanup, agent/reset-picture-cache-red unmerged — delete). Next: Inbox 🔴 `PersistenceController.swift:154` `attemptStoreRecovery` — check `isProtectedDataAvailable` before moving a store aside (data loss; two reviewers).
✅ Inbox 🟡 Apple Jalebi title/tag landed 6c4cf6b..82b2213 (builder 2026-11-25; also Tangzhong + lasagne titles, history pin test; leftover branches agent/jalebi-title auto-cleanup, agent/jalebi-title-red unmerged — delete). Next: Inbox 🔴 `DataManagementSettingsView.swift` `resetToDefault` clears Kingfisher's disk cache (Privacy 4.3; two reviewers).
✅ Inbox 🟡 refreshStaleSamples wiring test landed 1380e01 (builder 2026-11-25; leftover branches agent/sample-refresh-wiring auto-cleanup, agent/sample-refresh-wiring-red unmerged — delete). Next: Inbox 🟡 Apple Jalebi title/tag (recipes_seed.json).
✅ Inbox 🐞 starter Avocado Toast vegan claim landed c2afa17..a6a7aab (builder 2026-11-25; leftover branches agent/avocado-vegan auto-cleanup, agent/avocado-vegan-red unmerged — delete). Next: Inbox 🟡 `RecipeStore.swift:150` refreshStaleSamples wiring test, then 🟡 Apple Jalebi title/tag.
✅ Inbox 🐞 starter Greek salad gluten-free landed bd8decf..4fd63f9 (builder 2026-11-25; leftover branches agent/greek-salad-gluten auto-cleanup, agent/greek-salad-gluten-red unmerged — delete). Next: Inbox 🐞 Avocado Toast vegan claim (SeedRecipeProvider.swift:121) — add its old copy to `shippedVersions`, bump `sampleRefreshVersion` to 8.
✅ Inbox 🐞 hide five diet chips landed c3bd711 (builder 2026-11-25; leftover branches agent/hide-diet-chips, -2, auto-cleanup). Next: Inbox 🐞 Greek salad `isGlutenFree` (SeedRecipeProvider.swift:208) — dangerous allergen claim, fix first.
✅ Inbox 🟡 FilterSheet/NotesStepView placeholder copy landed 8eaf4af (builder 2026-11-25; leftover branch agent/placeholder-case, auto-cleanup). Next: top Inbox 🐞 — hide the five unmatched diet chips (RecipeDietaryInfo.swift:34 / FilterSheet, owner 2026-11-25).
✅ Inbox 🟡 CHANGELOG wording (both reviewer lines) fixed on main (builder 2026-11-25, docs only). Next: Inbox 🟡 FilterSheet.swift:117 "e.g. chicken, tomato…" + NotesStepView.swift:41 ellipsis (reviewer 2026-11-24).
✅ Inbox 🟡 dead `NotificationKind.dailyReminder` landed 5de2fad (builder 2026-11-25; leftover branch agent/drop-daily-reminder, auto-cleanup); Batch G gained MealPlanningManager + MealPlanningView+Actions. Next: Inbox 🟡 CHANGELOG.md:29/:76 wording (reviewer 2026-11-23), then CHANGELOG.md:17/:41/:29/:37 (reviewer 2026-11-24) — docs only.
✅ Inbox 🟡 NotificationManagerTests exemption + `try #require` defaults landed d9dc06e (builder 2026-11-25; leftover branch agent/test-require-defaults, auto-cleanup). Next: Inbox 🐞 RecipeDietaryInfo chips duplicates Needs owner (wait for owner), so take Inbox 🟡 NotificationManager.swift:12 dead `dailyReminder` case.
✅ Inbox 🐞 take-off deletes by slot landed 7df56e5 (builder 2026-11-25; leftover branch agent/plan-takeoff-by-id, auto-cleanup). Next: Inbox 🟡 `NotificationManagerTests.swift:236` shared instance / force-unwraps.
✅ Inbox 🐞 undoNote Task landed 061585b (builder 2026-11-25; leftover branch agent/plan-undo-note-cancel, auto-cleanup). Next: Inbox 🐞 MealPlanningView+Actions.swift:249 take-off slot-vs-id deletion, then `NotificationManagerTests.swift:236`.
✅ Inbox 🐞 take-off count (later-week copies) landed 5476015 (builder 2026-11-25; count per tap; leftover branch agent/plan-takeoff-series, remote pre-rebase — delete by hand). Next: Inbox 🐞 MealPlanningView+Actions.swift:274 undoNote Task (cancel + clear in `takeOff`), then the new 🐞 take-off slot-vs-id deletion (:249), then `NotificationManagerTests.swift:236`.
✅ Inbox 🔴 Privacy 6.5 crash reports + 7.3 sharing landed d4f516e (builder 2026-11-24; leftover branch agent/privacy-share-wording, auto-cleanup). Website session: copy 6.5/7.3 + date 24 Nov 2026 into `privacy.html`. Next: Inbox 🐞 MealPlanTakeOff.swift:25 `gone` counts later-week copies, then 🐞 MealPlanningView+Actions.swift:274 undoNote Task, then `NotificationManagerTests.swift:236`.
✅ Inbox 🟡 search placeholder copy landed 57e10d0 (builder 2026-11-24; leftover branch agent/search-placeholder-copy, auto-cleanup). Next: Inbox 🟡 `NotificationManagerTests.swift:236` shared instance / force-unwraps.
✅ f952384 review fixes landed 1d9a2cc..694569c (builder 2026-11-24): search field VoiceOver name + AX-size wrap; At-home UI test scrolls to its tag. Leftover branch agent/search-field-a11y (remote is pre-rebase 615c035 — delete by hand). Next: Inbox 🟡 search placeholder copy (now unblocked), then `NotificationManagerTests.swift:236`.
✅ Inbox 🟡 seen-red labels + f952384 review done (builder 2026-11-24, docs only). Next: first open Inbox 🟡 that needs no device or owner — `NotificationManagerTests.swift:236` shared instance / force-unwraps (reviewer 2026-11-23). New Inbox 🟡 search placeholder copy: take it after agent/search-field-a11y lands (same component).
✅ Inbox 🟡 Plan empty-night contrast landed 931ade6 (builder 2026-11-24; leftover branch agent/plan-past-night-contrast, auto-cleanup); Screenshots on main triggered to refresh the `screenshots` release. Next: Inbox 🟡 c496d06/b4e4ec6/e85cf25 seen-red/unconfirmed labels + reviewer/challenger on f952384 — first open Inbox 🟡 that needs no device or owner.
✅ Inbox 🟡 Toast VoiceOver landed 508a17b (builder 2026-11-24; leftover branches agent/toast-announce auto-cleanup, agent/toast-announce-red unmerged — delete). Next: Inbox 🟡 Screenshots on main + 04-meal-plan empty-night text contrast (reviewer 2026-11-21) — first open Inbox 🟡 that needs no device or owner.
✅ Inbox 🟡 take-off count landed 4355abd (builder 2026-11-24; leftover branches agent/plan-takeoff-count auto-cleanup, agent/plan-takeoff-count-red unmerged — delete). Next: Inbox 🟡 Toast.swift:56 — announce every toast to VoiceOver (challenger 2026-11-24).
✅ Inbox 🟡 MealPlanningManager `restore` skipped plans landed 45dc4be (builder 2026-11-24; leftover branches agent/plan-undo-skipped auto-cleanup, agent/plan-undo-skipped-red unmerged — delete). Next: Inbox 🟡 MealPlanningView+Actions.swift:260 "N meals taken off" count → pure function (file now 306 lines — extract the take-off merge + toast text first).
✅ Inbox 🔴 TestFlight feedback injection slice 1 (agent gate, `owner-ok` label) landed on main (builder 2026-11-24, docs only); rest (script drops tester text + Privacy 6.5/6.6) waits with Inbox (d), which the owner must land (scripts/workflows to main refused to the agent). Next: owner fast-forwards (a)/(b); meanwhile the first Inbox 🟡 not touching `.github/` — MealPlanningManager `restore` skipped plans (MealPlanningManager.swift:218).
⏸ Inbox 🐞 (a) cleanup GH013: done on `agent/cleanup-skip-refused` (8648522, reviewed, workflow-only so no Build & Test) — the agent may not push it to main; owner fast-forwards `main` to it. If its first run warns "no branch could be deleted", the ruleset blocks all agent/* deletes → lift it for agent/* or retire the job (CHALLENGES:79). ⏸ Inbox 🐞 (b) asc_promote state check: done on `agent/asc-promote-state` (ca981bf, reviewer + challenger, scripts only so no Build & Test) — agent push to main refused again → owner fast-forwards `main` to it (after or with (a); both branch from main and touch different files). Next: Inbox 🐞 (c) `testflight-promote.yml` → `workflow_dispatch` only — likely refused on main too, so ask the owner to land (a)/(b) first.
✅ 🐞 SundayPlanNudge weekly dinner landed af59876 (builder 2026-11-22; leftover branch agent/sunday-nudge-recurring, auto-cleanup); checked-days question → CHALLENGES 22 Nov. asc_promote 🐞 → Needs owner. Next: Inbox 🟡 testflight_notes / Log reviewer lines.
✅ 🐞 owner: Plan meals in time order (e85cf25) + take-off with Undo, no pop-ups (fde4a2e) landed (interactive session
2026-11-22; leftover branches agent/meal-time-order, -2, agent/plan-delete-popups, auto-cleanup). Next: Today orders a day
by time too — `TodayFeed.swift:146`, `TodayWeek.swift:45`, `PrepAhead.swift:52` sort by `mealTime.sortOrder`; switch to
`MealPlanModel.eatenBefore` (Today's "next meal" `TodayMealDay.swift:130` needs a pre-mortem: snack at 15:00 now comes before dinner).
✅ 🐞 Seed dietary tags landed c4e1ed7 (builder 2026-11-22; leftover branches agent/seed-dietary-tags, -2, auto-cleanup). 🔴 public promotion + allergen chips → Needs owner.
Inbox: ✅ plan deck pass decision landed 26f4481 (builder 2026-11-22; leftover branch agent/plan-deck-passes, auto-cleanup).
✅ 🐞 Stop-on-a-later-copy reminders landed 88d5ed9 (interactive session 2026-11-22; leftover branches
agent/stop-series-reminders, -2, auto-cleanup). ✅ 🐞 SundayPlanNudge week landed e34cec0 (leftover branches
agent/sunday-nudge-week, -2, auto-cleanup). ✅ 🟡 CHANGELOG Reset wording fixed. ✅ 🟡 Privacy aisle-order wording landed b52d55d (builder 2026-11-22; leftover branch
agent/privacy-aisle-wording, auto-cleanup). ✅ 🟡 HelpView appearance tip + British spelling landed a3df262 (builder 2026-11-22; leftover branch agent/help-copy,
auto-cleanup). ✅ 🟡 seen-red runs recorded (run 45013327147; leftover unmerged branch agent/seen-red, delete it). ✅ 🟡 CookingResumeMemory seam landed cbfba3f (builder 2026-11-22; leftover branch agent/cooking-resume-seam, auto-cleanup); Reset seam half stays in Inbox until *Reset store copies* is answered. Leftover branch agent/seen-red still to delete. ✅ 🟡 MealPlanningManager+Series split landed 2c5638a (builder 2026-11-22; leftover branch agent/meal-plan-series-split, auto-cleanup; rest → Smell Batch G). ✅ 🟡 testZZZPlanMyWeek skip → fail landed 32c0ec2 (builder 2026-11-22; leftover branch agent/plan-week-test-fail, auto-cleanup). ✅ 🟡 WeekDinners past dinners landed 4d5c943 (builder 2026-11-22; leftover branch agent/week-dinners-past, auto-cleanup). ✅ 🟡 missing reviewer on quick snack / chip order diffs: 0 defects (builder 2026-11-23, docs only). ✅ 🟡 Favourites spelling landed f34ca95 (builder 2026-11-23; leftover branch agent/favourites-spelling, auto-cleanup). ✅ 🟡 WeekDinners VoiceOver hint landed 533fe1b (builder 2026-11-23; leftover branch agent/week-dinners-hint, auto-cleanup). ✅ 🟡 vegan Chapati / Chai methods landed b752fc0 (builder 2026-11-23; leftover branches agent/seed-vegan-fixes, -2, auto-cleanup). ✅ 🟡 DietaryInference word lists landed 1ed14dc (builder 2026-11-23; leftover branch agent/dietary-words, auto-cleanup). ✅ 🟡 Screenshot 63-theme-picker-ax landed 3959ed6 (builder 2026-11-23; `NavigationBarScrollFade` in `SettingsScreen`; leftover branch agent/theme-picker-navbar, auto-cleanup). ✅ 🐞 cleanup-agent-branches GH013 → Needs owner (builder 2026-11-23). ✅ 🔴 Privacy vs public TestFlight → Needs owner (builder 2026-11-23). ✅ 🟡 NotificationManager coverage landed 3e1525a (builder 2026-11-23; leftover branch agent/notification-seam, auto-cleanup). ✅ 🟡 seen-red/unconfirmed labels done (builder 2026-11-23, docs only). ✅ 🟡 CookingResumeMemory host test landed 5ec7f83 (builder 2026-11-23; leftover branches agent/cooking-resume-host auto-cleanup, agent/cooking-resume-host-red unmerged — delete). ✅ 🐞 Toast cancel clears newer toast landed ac70a1a (builder 2026-11-23; leftover branches agent/toast-cancel auto-cleanup, agent/toast-cancel-red unmerged — delete). ✅ 🟡 placeholderCardIsOpaque flake landed 2405a30 (builder 2026-11-24; leftover branch agent/share-card-opaque, auto-cleanup). Next: Inbox 🐞 *Workflow items unblocked* (a) cleanup-agent-branches GH013; testflight_notes / promote + BACKLOG Inbox 🐞 *Workflow items unblocked* (owner OK 2026-11-23). Website session: add the §4.2 aisle-order bullet (new wording: "for each shop you choose, and for trips with
no shop chosen") + §4.3 clause and date 22 Nov 2026 from `PrivacyPolicyView.swift` to `privacy.html`.

## Decisions (why) — active items only; move an entry to `docs/DECISIONS.md` when its item lands

- **Plan deck up = tonight (slice 3):** built as "plan this dish for tonight while tonight is open" (pre-mortem and
  tests on the branch's WORK.md). Challenger showed tonight's card deals first, so up is reachable only after *Leave
  tonight open* → parked for the owner rather than landed. Rejected: up *replacing* a planned tonight (drops the cook's
  choice) — a swap that moves the old dish keeps it (option a).
- **Plan week photos (slice 2):** photos sit *under* the week strip + day list for now (strip still picks a day for
  breakfast/lunch); trimming the strip waits for *Groceries writes itself* (deletes duplicated views). Hold = context
  menu (Cook / Move to <day> / Swap with <day> (dish) / Take off the plan), not drag-and-drop — a drag across a
  2-column grid inside a ScrollView fights scrolling. Moving onto a planned night swaps, so a night never has two
  dinners; nothing moves into the past. Tap = open the recipe (owner 2026-11-20; was push into cooking), hold menu Cook = cooking like Today's "Cook this" (needs a NavigationStack on
  Plan, same pattern as Today). **Pre-mortem:** (1) swap leaves two dinners on one night → `moveOntoAPlannedNight…`;
  (2) a move across the October clock change lands on the wrong day → `moveKeepsTheTimeAcrossAClockChange`;
  (3) tap does nothing / doesn't reach cooking → UI test asserts `cooking.stepPosition`.
- **Docs refresh (5) CHANGELOG** : entries are per shipped *change*, not per build number — batch landing puts several
  items in one build and the number isn't known at landing. Item name + commit stay in the heading for the team but
  off the page. Parser is strict (stray line = error) so a typo can't silently drop an entry. Log archive moved to
  `docs/LOG.md` so CHANGELOG stays readable. No CI job for `--check` (workflow change → owner, CHALLENGES 16 Nov).
- **CI under 10 min** (`agent/ci-10min`): measured, not guessed. (1) The simulator was the cost, not Xcode: a first
  boot does ~70s data migration then widgets/Health/News/Siri/push peg all 3 CPUs ~5 min (sim+host diagnosticd ~50–90%).
  Booting it in the background starved everything else (cache download 0.3–5 MB/s vs 120, actool 11s→71s, build
  0:43→6 min, 80s stalls inside trivial XCTests). Fix: boot alone after the cache restore, `launchctl disable`+`bootout`
  ~27 services in parallel (bootout, not kill: killed ones respawn), then build. (2) main caches a booted, emptied
  device (0.7 GB, key = Xcode build + UDID): settled in ~130s vs ~260s. (3) UI tests: 3 matrix shards, each builds
  for itself (~1 min from cache) — no artifact hand-off; tests dealt round-robin from `-enumerate-tests`, so new
  tests can't be missed; localization screenshots off (were 235s of ~600s UI time). (4) Coverage moved to
  `coverage.yml` (nightly, unit tests): a coverage build can't reuse the cache (6:51 full rebuild). Rejected: host-
  log level (no effect), iOS 26.2 runtime (same storm), shrinking DerivedData (restore is 0:08–0:12 when the sim is
  idle). Unit-test host skips app launch work (`RecipeFinderApp.isHostingUnitTests`, DEBUG only). **Pre-mortem:**
  (1) a disabled service is needed by a test → UI shards + unit run green; (2) shard misses a test → union is Xcode's
  own list, fail if empty; (3) stale cached device after an image update → key has Xcode build + UDID.

