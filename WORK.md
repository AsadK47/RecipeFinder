# WORK.md — handoff (2026-11-18, builder agent)

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

- Smells: ✅ Batch A, B (stale, no code), C (e39fe71). 🚧 Batch D: ✅ screen 1 MealPlanningView landed d52b80d
  (builder 2026-11-18). Left: RecipeSearchView (515), CookingModeView (392), one branch each. Leftover branch
  agent/meal-planning-split (auto-cleanup). Top Smell (times → Int minutes) waits on Needs owner.

- Tester feedback 1: ✅ slices 1 (3ed805c), 2 Badges from Today (7f8e5b1, builder 2026-11-17), 4. ✅ 3 foreign recipes
  (d7bf8f7, builder 2026-11-17). Left: slice 5 (Cook lane's). Leftover branch agent/foreign-recipes (auto-cleanup). Leftover branches agent/cuisine-chip,
  agent/today-badges-link (auto-cleanup).

- Me with character: ✅ done — slice 4b cooking story landed 40253df (builder 2026-11-18). Leftover branches agent/me-hero,
  agent/me-name-inline, agent/me-badges-next-up, agent/me-taste-story, agent/me-cooking-story, agent/sweet-chilli-name,
  agent/batch (auto-cleanup).

- Kitchen you can find: ✅ done — slice 2 landed f8960bb (Today "Your kitchen →" links + "In kitchen" tag → At home,
  builder 2026-11-17). Leftover branches agent/kitchen-at-home, -2, agent/kitchen-today-links (auto-cleanup).

## Next action
Xcode 27 (`agent/xcode-27`, builder 2026-11-18): wait for Build & Test green, then UI run + Screenshots on the branch,
land, and confirm the first TestFlight upload has no ITMS-90725.

## Decisions (why) — active items only; move an entry to `docs/DECISIONS.md` when its item lands
- **Xcode 27** (`agent/xcode-27`): `macos-26` stops at Xcode 26.6; Xcode 27 is only on the `xcode-27` runner label
  (macOS 27 base, standard size = free). All app jobs moved there; `tools-build.yml` stays on macos-26 (Mac tool, no
  upload). `.github/actions/select-xcode` picks the newest non-beta `Xcode_27*.app` and fails loudly if missing, so
  an image change can't silently ship an old SDK. DerivedData cache key now includes the Xcode build (a 26.x cache
  restored under 27 would just be rebuilt or confuse it). Xcode 27's type checker times out on long inferred chains
  and inline arithmetic `@Test(arguments:)` tuples → split/typed, values unchanged. Rejected: `setup-xcode` action
  (third-party dep, and the app isn't on the image anyway). **Pre-mortem:** (1) TestFlight still uses 26.x → the
  select step runs first in testflight.yml and fails if 27 is missing; (2) iOS 27 SDK changes runtime behaviour on
  device → UI shards + Screenshots on the branch; (3) cache miss makes runs slow for one main push → expected, once.
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
