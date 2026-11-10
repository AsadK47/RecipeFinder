# WORK.md — handoff (2026-11-10, end of long interactive session)

## In progress
- **Web search redesign** — branch `agent/web-search-redesign` (27c3bc2), Build & Test run 42838404077 ✅ green; Screenshots dispatched 15:08 on the branch.
  New `Utilities/Recipe/WebSearchBrowsing.swift` (offer rules, site name, recent searches; registered in pbxproj
  mirroring RecipeImportBuilder.swift), tests `WebSearchBrowsingTests` in RecipeImportFixtureTests.swift,
  `Views/Import/RecipeWebSearchView.swift` rewritten (`WebBrowserModel` @Observable + KVO, Safari-style address bar,
  progress line, back/forward/reload bar, green import pill vs "Try importing this page", start-screen chips).
  If red: read failing log, fix. If green: dispatch Screenshots (13-web-search = start screen only; results pages
  need live network), ff main, tick, Log, notify.

## Next action
0. Write a root `README.md` (none exists; owner asked 2026-11-10): what the app is, privacy-first/offline, feature list
   (incl. web search, estimate amounts, other-app/PDF import), TestFlight beta link, project layout, CI + agent loop
   (BACKLOG.md/WORK.md), no company name. Docs-only → straight to main.
Work the BACKLOG "Next (owner order 2026-11-10)" line in order: Bug sweep → Tabs 1/3 → Tabs 2/3 Today →
Plan my week → Groceries + Kitchen → Made-it celebration + Spoons → cooking mode → small sticky features →
Settings tidy-up (inside Me) + polish. Audit with file:line evidence: `docs/AUDIT-2026-11-10.md`.

## Decisions (why)
- **Tabs → Today · Recipes · Plan · Groceries · Me** (owner OK). Import is rare-use → "+" on Recipes; Settings →
  gear in Me. Today is the daily reason to open the app.
- **Groceries + Kitchen merge** with To buy | At home and "Put away"; owner explicitly wants redundant code deleted.
- **Plan my week** must become a proper feature (owner: "beautiful").
- **Spoons**: on-device, cosmetic-only spending, no purchase/cash-out. Real-money/charity pledge = owner decision
  later (Needs owner). Loot boxes/random paid rewards rejected (UK/EU gambling scrutiny).
- Still unanswered by owner: which medium features (fridge photo, taste profile, cook-along Q&A, skill tree,
  heirloom mode) and whether to add a Widget/Live Activity target (guardrail: new target = owner).
- **CI (build.yml)**: 100-repo survey → Linux gate skips re-testing main commits that passed on a branch,
  build-for-testing + test-without-building, simulator boots during compile, DerivedData cache saved only by main,
  runner tune-up (Spotlight/ReportCrash off), no coverage/index/test diagnostics. Measured warm branch run 11m25s
  (restore 2m34, build 4m14, test 3m35) — not yet ≤5 min. Next CI step: try caching only Xcode compilation cache
  (Element X) and find why the build isn't incremental; if no gain, revert to pre-cache setup. A freshly booted
  simulator makes Swift Testing slow (119s vs 45s settled).
- **TestFlight** fixed: owner added CI_DEV_CERT_P12/PASSWORD (cert made in a cloud session; expires 2027-11-10,
  renew by then). Caching the Release archive was judged useless (whole-module, no SPM deps).
- Website lives in AsadK47/RecipeFinderWebsite; a separate session improves it (TestFlight link
  https://testflight.apple.com/join/UJWrMbk2 sent to it; sign-up form untouched by owner request).

## Constraints discovered
- New Swift files must go in the **app** target's Sources phase (first mirror attempt landed in the share extension).
- Auto-mode blocks force-push, remote branch deletes and some rm; ask owner to delete merged `agent/*` branches.
- Screenshot UI tests share simulator data: open seeded recipes by name, not `firstMatch`.
