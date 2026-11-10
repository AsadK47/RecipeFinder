# WORK.md — handoff (2026-11-10, end of long interactive session)

## In progress
- **Web search redesign** — rebased onto main as `agent/web-search-redesign-2` (37f1b5f; force-push to the old branch is blocked). Old branch 27c3bc2 was ✅ green (run 42838404077); Screenshots run 42841225002 on the old branch. Wait for Build & Test on -2.
  New `Utilities/Recipe/WebSearchBrowsing.swift` (offer rules, site name, recent searches; registered in pbxproj
  mirroring RecipeImportBuilder.swift), tests `WebSearchBrowsingTests` in RecipeImportFixtureTests.swift,
  `Views/Import/RecipeWebSearchView.swift` rewritten (`WebBrowserModel` @Observable + KVO, Safari-style address bar,
  progress line, back/forward/reload bar, green import pill vs "Try importing this page", start-screen chips).
  If red: read failing log, fix. If green: dispatch Screenshots (13-web-search = start screen only; results pages
  need live network), ff main, tick, Log, notify.

- **Bug sweep** — branch `agent/bug-sweep-1` (f9a9190), Build & Test run 42843360332 pending. Fixes audit §0
  bugs 2–8: collection remove → contextMenu + a11y action; ½× servings `RecipeModel.servings(scaledBy:)`; week
  groceries scale by `meal.servings/baseServings`; `NotificationManager.syncGroceriesReminder` + new
  `RecipeFinderTests/Utilities/Notes/NotificationManagerTests.swift` (pbxproj ids A1B2C3D4E5F6…01/02); share inbox
  is now a queue (`consumePayloads`, drains legacy single keys); extension says "Sent" and only hands over complete
  recipes; ContentView alerts on file-import save failure after the sheet dismisses. Existing flour test now plans
  `servings: 1` (recipes have base 1). Bug 1 (pantry expiry/quantity UI) deferred to Groceries + Kitchen batch.
  If red: read log, fix. If green: rebase/ff main, tick, Log.

- **Legal future-proofing** (owner request 2026-11-10: remove wording that pigeonholes us) — branch
  `agent/legal-futureproof`: in-app Privacy Policy + Terms (+ lastUpdated 10 Nov 2026) and README describe *current*
  behaviour ("current version", "private by default") and promise opt-in + policy update before any sync/sharing/
  accounts feature, instead of "no servers / no accounts / never". Website privacy.html + terms.html updated to match
  (RecipeFinderWebsite 41ffbdf, live). When CI green: ff main, Log line noting owner OK for the legal-text guardrail.

## Next action
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
