# WORK.md — handoff (2026-11-19, builder agent)

## In progress
Three parallel lanes (owner 2026-11-15), batch landing via `agent/batch` (BACKLOG step 7):
- Data: `agent/recently-deleted` (6dcdf77) green + 3 review rounds done — lands as soon as the owner deploys the CloudKit Production schema (model 17 photos + model 18 deletedAt).
- Cook: ✅ slice 1 landed (85bfddf). Next slice: cooking mode one step per screen + Next, progress, per-step ingredients, timers, resume, last step → Made it.
- Discover: ✅ endless discovery landed (2b6847f). Polish noted: feature tile leaves a gap between title and time.
- CI (CI lane, owner TOP): landed f343fa5 + d775cf6 (prepare action, cached booted simulator, 4 UI shards, coverage.yml). Jobs 7:40–10; wall time hurt by runner queueing (Needs owner) and unit-job variance. Next: sample the test host during the ~60s XCTest stall (`xcrun simctl spawn $SIM spindump` or `sample` on RecipeFinder) on agent/ci-10min, then 3 consecutive pushes ≤10 → tick.
- Privacy: ✅ landed 037a8ea. Website session: copy §2.1, §4.1–4.4, §5.1–5.3, §7.1 + date 15 Nov 2026 from `PrivacyPolicyView.swift` into `privacy.html`, and Terms §3.1.

- Inbox 🟡 Reset store copies: ⏸ parked in Needs owner (data-loss risk on `.corrupt-*`, 2 reviewers agree); branch `agent/reset-store-copies` (87f5737) unmerged, Decisions on that branch's WORK.md — rework per owner's answer.
- Remember: ✅ **My Cookbook** done — slice 3 (share a page) landed 0adbf0b (builder 2026-11-16); notes / "who it was
  for" → Needs owner (model). Leftover branches agent/my-cookbook-2, agent/cookbook-share (auto-cleanup).
  `testBadgeRevealViewAllClosesAndOpensMe` flaked a 3rd time → Inbox 🟡 (read its "queued reveal" checkpoint).

- Docs: 🚧 **Docs refresh** slice 5a landed (builder 2026-11-16) — CHANGELOG = per-change "For you" + "Behind the
  build" entries, `tools/website-behind-the-build.py` (`--check`), old Log archive → `docs/LOG.md`. Next: slice 7 landed
  (docs-only). Only (5b) left — website session adds `behind-the-build.html` with markers and runs the script weekly
  with whats-new, after `privacy.html` updates; then tick. Leftover branch agent/docs-refresh-5 (auto-cleanup).

- Smells: ✅ Batch A, B (stale, no code), C (e39fe71). 🚧 Batch D: ✅ screen 1 MealPlanningView (d52b80d), ✅ screen 2
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
  ✅ Slice 5 Sunday nudge landed 6954ab2 (builder 2026-11-20). Leftover branch agent/plan-sunday-nudge (auto-cleanup).
  Slice 3 (up = tonight) ⏸ Needs owner — branch `agent/plan-deck-tonight` (e45d1ce: model `planTonight`/`canPlanTonight`,
  view swipe up + "Have it tonight", unit + UI tests, 2 review fixes) unmerged; rework per owner's (a)/(b)/(c).
  Open: `tonight` is fixed at deck open (midnight-open deck plans yesterday) — fix in the rework. Leftover branches agent/plan-deck, agent/plan-week-photos (auto-cleanup).

## Next action
Plan slice 3 waits on the owner (Needs owner "Plan deck: what does swipe up do?"). Next Plan slice that needs no
answer: (6) busy nights / lock / re-roll on a new branch `agent/plan-busy-nights` ((4) 30-day memory needs a Privacy
§4.2 line + two reviewers).

## Decisions (why) — active items only; move an entry to `docs/DECISIONS.md` when its item lands
- **Plan deck up = tonight (slice 3):** built as "plan this dish for tonight while tonight is open" (pre-mortem and
  tests on the branch's WORK.md). Challenger showed tonight's card deals first, so up is reachable only after *Leave
  tonight open* → parked for the owner rather than landed. Rejected: up *replacing* a planned tonight (drops the cook's
  choice) — a swap that moves the old dish keeps it (option a).
- **Plan week photos (slice 2):** photos sit *under* the week strip + day list for now (strip still picks a day for
  breakfast/lunch); trimming the strip waits for *Groceries writes itself* (deletes duplicated views). Hold = context
  menu (Cook / Move to <day> / Swap with <day> (dish) / Take off the plan), not drag-and-drop — a drag across a
  2-column grid inside a ScrollView fights scrolling. Moving onto a planned night swaps, so a night never has two
  dinners; nothing moves into the past. Tap = push into cooking like Today's "Cook this" (needs a NavigationStack on
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
