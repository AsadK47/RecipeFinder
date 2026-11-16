# WORK.md — handoff (2026-11-16, builder agent)

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

- Smells: 🚧 **Batch A** (builder 2026-11-16) slice 1 landed 9fc278a (Content 794→486). Next slice: extract
  `timerControl`+`startCookTimer`+`timerRowLabel` and `cookHistoryCard` from `RecipeDetailView+Content.swift` into own
  views; then ingredients/pre-prep; then `RecipeDetailView.swift` 475→≤300. Leftover branch agent/detail-split-a.

- Tester feedback 1: ✅ slice 1 cuisine chip landed 3ed805c (builder 2026-11-16). Next: slice (2) Badges from Today (slice 4 toggle
  landed via Discover lane; slice 5 is Cook lane's). Leftover branch agent/cuisine-chip (auto-cleanup).

## Next action
When lanes report green + reviewed: batch them into `agent/batch`, one green run, ff main, Log lines, tick.

## Decisions (why) — active items only; move an entry to `docs/DECISIONS.md` when its item lands
- **Smell Batch A** (builder 2026-11-16): took it over the top Smell (recipe times → Int minutes) because that needs a
  new Core Data model on a synced entity, which must stack on unmerged model 18 (Recently deleted, waiting on the
  CloudKit Production deploy) → noted in Needs owner. Nutrition numbers moved to a pure enum so they're tested, not
  just moved; the label is built from `NutritionLabelFormat.rows` so wiring (value/unit/RI per line) is tested too
  (challenger: no screenshot covers Nutrition). 0 g → "1%" pinned as-is, not fixed in a refactor (Inbox 🟡).
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
