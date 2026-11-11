# WORK.md — handoff (2026-11-11, builder agent)

## In progress
- **Add flow 1/3 slice 1** on `agent/add-flow-1-draft-screen` (29850eb): create + import review show `RecipeDraftView`
  (recipe as it'll look; tap photo/name/chips/cards → that section's editor in a sheet via `sectionEditor(_:)`), Save
  pinned at bottom, `WizardIntroSheet` deleted. Pure `RecipeDraftPreview` + tests. UI tests → `draft.name`; new
  screenshot test `testCaptureNewRecipeDraft` (21/22). Waiting on Build & Test.

## Next action
Check Build & Test for 29850eb; fix; ff-merge main. Then slice 2: run Screenshots workflow on the branch/main to eyeball
21-new-recipe, 09-low-confidence, 11-start-from-text; trim step views now unused by the draft screen (WizardStepHeader
subtitles, `WizardRecipeSummary` in NotesStepView?) for net lines down; then tick the item.

## Decisions (why)
- **Add flow 1/3 slice 1**: kept the existing section editors (one canonical editor) and show them one at a time in a
  sheet from the draft screen rather than editing inline — inline TextEditors inside a scroll of cards fight the
  keyboard and would duplicate the step views. Photo pickers attach to the top-most sheet (section sheet on the draft
  screen, root for focused edits) — a sheet can't present from the view beneath another sheet. Focused edits from
  detail unchanged (toolbar Save). Full "Edit" (focus nil, editing id) also gets the draft screen, Save says "Update".
- **Tabs 2/3 slice 4b (clipboard card)**: detection via `UIPasteboard.detectPatterns(.probableWebURL)` (no paste
  prompt); the read happens only through SwiftUI `PasteButton` (user tap = consent). First http(s) link in the paste
  → `RecipeImportView(initialURL:)` presented from ContentView (`addRecipeBusy` holds badge sheets). Pasted/dismissed
  copy remembered by pasteboard `changeCount` in @AppStorage. Re-probed on scene active (no Combine notification).
  New-user shot = UI test named to sort first; that made Estimate-amounts run 2nd, where its seeded recipe unlocks
  "First Bite" → shared `dismissBadgeSheet` helper. In CI the Paste button renders greyed (clipboard really empty).
  "New imports" shelf → Needs owner (Core Data guardrail); Spoons-on-Today folded into Spoons 1/2.
- **Tabs 2/3 slice 4a (prep-ahead)**: nudge = tomorrow's open plans whose steps say "overnight", defrost/thaw, or a
  long-lead verb (marinate/soak/prove/rise/chill/refrigerate) with a 2+ hour wait. Short waits ("marinate 15 minutes")
  and "no need to thaw" excluded; "chilli" isn't "chill". Uses `String.range(of:options:.regularExpression)` (no
  `try?`, no non-Sendable static Regex). Shown all day, under the hero. Clipboard card deferred to its own slice
  (reading the pasteboard shows iOS's paste prompt — needs `detectPatterns` care).
- **Tabs 2/3 slice 3**: "Let's cook" pushes the recipe detail with `startsCooking: true` (one-shot onAppear) instead of
  presenting CookingModeView from Today, so finishing reuses detail's Made-it / streak / badge path. Card split into
  two sibling buttons (open vs cook). `RecipeRediscovery.pick` now only used by its tests — kept (tested, tiny); drop
  in a Smells pass if wanted. Verified by Screenshots run on the branch (UI tests aren't in push CI).
- **Tabs 2/3 slice 2**: UI tests tap Recipes after launch (not a launch-arg override) so CI exercises the real default.
  Planned-day shot is its own test sorting after `testCaptureScreenshots`, so 16-today stays unplanned despite
  shared simulator data. Seed plans the first recipe by name; leaves an existing dinner plan alone.
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
