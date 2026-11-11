# WORK.md — handoff (2026-11-11, builder agent)

## In progress
- `agent/today-eat-time` — Today+ 1/3 slice 2: eat-time menu on the Tonight timing line (`today.eatAt` AppStorage,
  `TonightTiming.eatTimeChoices` / `eatAt(stored:)`), calmer layout (groceries shortcut card dropped, shelf tiles
  without cards and bigger photos, tinted badges). Waiting on Build & Test.

## Next action
Check Build & Test on `agent/today-eat-time`; then Screenshots on the branch (16/18/24–28), deep-review (high) +
challenge pass in separate agents, merge, tick Today+ 1/3.

## Decisions (why)
- **Today+ 1/3 slice 2**: eat time is picked by tapping the timing line (Menu + Picker, 5–10pm on the half hour), not
  in Settings — it's where the number shows, and Settings tidy-up comes later. Stored minutes not in the choices fall
  back to 7pm. The Menu sits outside the hero's open button (nested buttons don't fire). "Calmer": dropped the
  bottom "Check your groceries" card (Groceries is a tab), shelf tiles are bare photos (no card each), Plan-tonight
  and prep-ahead badges tinted so "Cook this" is the one accent. **Pre-mortem:** (1) picked time ignored / not saved
  → `aLaterEatTimeMovesTheStartTime` + UI step asserting "eat at 8" (shot 28); (2) garbage stored value shows odd
  times → `storedEatTimeFallsBackToSeven…`; (3) shelf text unreadable without a card on light gradients → look at
  shots 16/18 (and Light if available).
- **Today+ 1/3 slice 1**: Shuffle cycles `[hero] + alternatives` (≤3): today's open plans (dinner first), kitchen
  matches, quick recipes (≤30 min known time; favourites, own over samples, most cooked, name). Suggestions skip the
  single most recently cooked recipe; plans never skipped. With nothing planned and no kitchen match, a quick recipe is
  now the hero (was the "Plan tonight" shortcut) — `noPlanAndEmptyKitchenHasNoHero` became "…and nothing quick"
  (spec change, not a weakened test); `cookAgainIsRecentCooksNewestFirst` fixtures made slow so no quick hero drains
  the shelf. New users: a quick pick can follow a plan/match but never lead (Starters lead). Time line is pure
  `TonightTiming.line(minuteOfDay:)`; planned lunch/snack never counted back from 7pm; evening falls back to "Quick
  tonight?" if the planned dinner can't be timed any more. Times read "5:40"/"7" (spoken 12-h, per spec).
  Shuffle tracks the shown recipe id (`TodayFeed.tonightPick/nextTonightPick`), not an index; shelves drop the shown
  pick. Evening quick line 6–10pm; morning prep cue 5am–noon. Challenge pass: 3 real fixed, 3 notes → CHALLENGES.md.
  **Pre-mortem:** (1) shuffle shows the same dish twice or the one cooked last night → `aRecipeShowsOnce…`,
  `suggestionsNeverRepeatTheLastCooked`; (2) "Start by" wrong for odd times (no time, 20-hour recipes, lunch plans,
  after 7pm) → TonightTimingTests nil cases; (3) hero card crowded/clipped on small screens or new users see a random
  quick hero → Screenshots 20/24–27 looked at + `newUsersGetStartersNotQuickPicks`.
- **Add flow 3/3 slice 2 (groups)**: a group is `Ingredient.section: String?` — a label on each row, not a header row,
  so groceries/scaling/"Add amount"/missing-amount checks never see it. Lives in the ingredients JSON blob → no Core
  Data change; old data decodes nil. In all text (editor box, import prefill, edit prefill) a group is a header line
  "Title:" (`IngredientSections`); header = ≤6 words, no digits, ends ":" or "For/To make the X". Bare vocab words
  ("GARNISH", "Sauce") are headers only in `TextRecipeParser` (in the editor "Sauce" alone stays an ingredient).
  Shown as a headline on recipe detail + draft screen. Not done: cooking mode / print / share text don't show groups;
  HTML (JSON-LD/DOM) paths still drop headers; HTML text path not run through `RecipeTextCleanup`.
  `WizardIngredientParser` now unused by app code (tests only) — Smell candidate.
- **Add flow 3/3 slice 1**: fixtures are self-written in the formats of real sources (WPRM blog card, recipe-card site
  with ratings, BBC-style STEP n, Instagram keycap caption, TikTok "You'll need", cookbook OCR with FOR THE X groups,
  family message) — not copied page text. Junk is dropped at line level (`RecipeTextCleanup.isBoilerplate`); Notes /
  Variations / How to store go to the recipe's notes, Nutrition panels are dropped. With no method header, the first
  full sentence or numbered step ends the ingredient list. "N.N M unit" treats the first number as a scale artifact
  (was integers only). **Not done → slice 2:** keep ingredient section headers ("For the sauce") — the model has no
  ingredient groups; storing them as ingredient rows would hit groceries/scaling/"Add amount", so it needs a
  representation decision. Also HTML text path doesn't use RecipeTextCleanup yet.
- **Add flow 2/3 slice 2**: one `AddRecipeImportFlow` sheet (reading → `RecipeWizardView` draft swapped in place) for
  link + text from "+", Today clipboard, share-extension links and web search. Incomplete link imports now open the
  draft (its orange highlights replace the old "Recipe looks incomplete" alert); duplicates still ask first
  (`AddRecipeLinkResult`). Fake staged progress (sleeps) dropped — just a spinner + site name. Photo keeps its picker
  sheet (picking photos needs it).
- **Add flow 2/3 slice 1**: link vs text = a web link with ≤8 words total is a link; longer text (captions with a
  recipe and a link) is read as text. Paste goes through `PasteButton` (no Allow-Paste prompt) and submits at once, so
  "+" → Paste → importer = 2 taps; typed input = "+" → type → Continue. `.link`/`.paste` options removed (box covers
  them); "Create manually" → "Start blank". Kept the existing sheets this slice so failure fallbacks keep working.
- **Add flow 1/3 slice 2**: removed all step headers rather than shrinking them — each editor now opens in a sheet
  whose nav title is the section name, and placeholders already say "one per line". Ingredients' "e.g. 200 g flour"
  hint lives in the TextEditor placeholder. Stale "Step N of the Recipe Wizard" doc comments left for the Large-wizard smell.
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
