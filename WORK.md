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

- Smells: ✅ Batch A, B (stale, no code), C (e39fe71, builder 2026-11-17). Next Smell: Batch D (big screens, one branch
  per screen) — top Smell (times → Int minutes) waits on Needs owner. Leftover branch agent/chip-style (auto-cleanup).

- Tester feedback 1: ✅ slices 1 (3ed805c), 2 Badges from Today (7f8e5b1, builder 2026-11-17), 4. ✅ 3 foreign recipes
  (d7bf8f7, builder 2026-11-17). Left: slice 5 (Cook lane's). Leftover branch agent/foreign-recipes (auto-cleanup). Leftover branches agent/cuisine-chip,
  agent/today-badges-link (auto-cleanup).

- Me with character (Queue): ✅ slice 1 landed 57fae8c (hero + stats); ✅ slice 1b landed 1acdedc (name inline +
  Settings › Profile form, builder 2026-11-18); ✅ slice 3 landed 82d238c (earned first + Next up + See all, builder
  2026-11-18); ✅ slice 4a landed 0dd898f (taste fingerprint, builder 2026-11-18). Next: (4b) cooking story. Leftover
  branches agent/me-hero, agent/me-name-inline, agent/me-badges-next-up, agent/me-taste-story (auto-cleanup).

- Kitchen you can find: ✅ done — slice 2 landed f8960bb (Today "Your kitchen →" links + "In kitchen" tag → At home,
  builder 2026-11-17). Leftover branches agent/kitchen-at-home, -2, agent/kitchen-today-links (auto-cleanup).

## Next action
Me with character slice (4b) on a new `agent/me-cooking-story` branch: "Your cooking story" timeline (first save,
first cook, streak milestones, badges, photos, first cuisine; spec *Me 2/3*; `CookingStreak.cooksThisYear` is waiting
for it) — tests first. Last slice → tick the item.
Lanes: when green + reviewed, batch them into `agent/batch`, one green run, ff main, Log lines, tick.

## Decisions (why) — active items only; move an entry to `docs/DECISIONS.md` when its item lands
- **Me with character (4b) cooking story** (`agent/me-cooking-story`): `CookingStory.moments` = first cook + meal
  rungs (10/25/50/100) + streak rungs (2/4/12/52, each told once, first time reached) **from the cook log**, plus every
  other earned badge on its `dateEarned`; cook/streak badges are skipped so nothing shows twice (rungs = the badges').
  Rejected: "first save" / "first cuisine" / photo moments with their own dates — recipes have no created-at and cooks
  aren't linked to recipes, so those would need a model change (guardrail); the First Recipe / First Cook Photo
  badges already date them. Hidden until the first cook (new cook: hero + cookbook invite). Newest 5, "Show all" in
  place; a badge row opens that badge on the shelf (`TrophyShelfRequest`). `CookingStreak.cooksThisYear` → "14 meals
  cooked in 2026" under the title. `recordedCookDates` added to `CookingStreakTracking` (no fakes to update).
  Pre-mortem: (1) streak rung on the wrong cook / told twice → `streakRungDate`, `streakRungsOnce`, `gapRestarts`;
  (2) duplicate "first cook" + "Head Chef" lines → `cookLogBadgesSkipped`; (3) timeline line/clipping or first cook
  hidden behind Show all → UI test taps Show all, asserts `story.row.first-cook`, shot 49-me-story looked at.
- **Me with character (1b)**: the name is its own button *above* the profile button, not inside it — nested buttons in
  one label are unreliable and VoiceOver can't reach them. One field, split by `ProfileNameFormatter.rename` (first
  word / rest; unchanged → nil; a stored multi-word first name is kept when the text still starts with it; 60-char
  cap). Commits on Done, return, focus loss and disappear (`editing` guard → once). Form + photo → new
  `ProfileSettingsView` (Settings row "Name & photo"); Me › Profile keeps photo/badges/chef type and saves the chef type
  with the manager's current name, so nothing stale clobbers an inline rename. Rejected: two inline fields (first/last)
  — heavier for a hero. UI test renames to a name ≠ the stored one (shared simulator keeps the profile). Pre-mortem: (1)
  edit not saved → UI label assert with a fresh name; (2) "Mary Ann" re-split → `renameKeepsAMultiWordFirstName`; (3)
  field leaves stale text → cursor-to-end + clear in the UI test.
- **Me with character (1)**: stats reuse `BadgeMetrics` (cuisine falls back to category, like the Cuisine badge) so
  the strip and badge rings never disagree — cuisine-only count → Needs owner (both places or neither). Label "meals",
  not the spec's "dinners": the count is every cook (cookCount sum, all time). Strip shows if any stat > 0. Hero above the cookbook per spec order. Zero cooks → one warm line instead of three zeros; the
  cookbook's empty state below carries the action. Pre-mortem: (1) counts disagree with badges → `matchesBadgeMetrics`
  test; (2) hero squeezes at accessibility sizes → vertical layouts + screenshot; (3) seeded UI value lacks stats →
  `testZZCaptureCookbook` asserts "[1-9]… meals cooked".
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
