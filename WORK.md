# WORK.md — handoff (2026-11-10, end of long interactive session)

## In progress
- Nothing in progress. Tabs 2/3 slice 1 merged (69c3b21); item stays open in BACKLOG with what's left.

## Next action
Tabs 2/3 slice 2: flip `AppTab.launchDefault` to `.today`; in every UI test `launchApp` (AccessibilityAudit,
HabitLoop, Import, SheetPresentation, Screenshot tests) tap `app.tabBars.buttons["Recipes"]` after launch; rename
`RecipeFinderLaunchUITests` to assert Today; add launch-arg seeds for planned-day / unplanned-day Today screenshots.

## Decisions (why)
- **Tabs 2/3 slice 1**: launch kept on Recipes this slice — flipping it breaks ~6 UI-test helpers that assume Recipes,
  so it gets its own branch. Hero = open dinner plan, else earliest open plan, else best kitchen match (≥ half the
  ingredients). Cook again = cooked ≤21 days; Rediscover = older (no overlap; `RecipeRediscovery.ranked`). New user =
  every recipe is an uncooked sample. "Let's cook" opens the detail (cooking mode lives there). "New imports" skipped:
  recipes have no add-date (Core Data change = guardrail). Today has its own NavigationStack path.
- **Tabs 1/3**: launch stays on Recipes until Today has content (no placeholder landing for TestFlight users).
  "+" sits beside the search field (title row too narrow for + and menu). "+" sheet is presented from the app root
  and closes on save; badge celebrations wait for its onDismiss (`addRecipeBusy`) — a sheet over/mid-dismissal of
  another is dropped. "View all badges" now switches to the Me tab instead of a Profile sheet. Settings still has its
  own Profile row (redundant inside Me) — left for Settings tidy-up. Other-app import is in both "+" and Data Management.
- **Tabs → Today · Recipes · Plan · Groceries · Me** (owner OK). Import is rare-use → "+" on Recipes; Settings →
  gear in Me. Today is the daily reason to open the app.
- **Groceries + Kitchen merge** with To buy | At home and "Put away"; owner explicitly wants redundant code deleted.
- **Plan my week** must become a proper feature (owner: "beautiful").
- **Spoons**: on-device, cosmetic-only spending, no purchase/cash-out. Real-money/charity pledge = owner decision
  later (Needs owner). Loot boxes/random paid rewards rejected (UK/EU gambling scrutiny).
- Owner 2026-11-10: yes to taste profile, skill tree, heirloom mode, cook-along Q&A (only if well implemented);
  widget and/or Live Activity — whichever suits (both already specced in BACKLOG). Fridge photo undecided.
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
- Files in the repo can be bundled app resources (`screenshots/home_page.png` was): before deleting any non-.md file, `grep` it in `project.pbxproj` — a dangling Resources entry breaks the build (main went red 2026-11-10, fixed on `agent/fix-home-png`).
- New Swift files must go in the **app** target's Sources phase (first mirror attempt landed in the share extension).
- Auto-mode blocks force-push (even with owner OK), remote branch deletes and some rm; land branches by merging main into them (no rewrite), and ask owner to delete stale `agent/*` branches.
- Screenshot UI tests share simulator data: open seeded recipes by name, not `firstMatch`.
