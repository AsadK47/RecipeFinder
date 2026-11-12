# WORK.md — handoff (2026-11-12, builder agent)

## In progress
- `agent/fix-badge-reveal-shot` (69187fa): reveal no auto-close under `-show-badge-reveal` (`BadgeReveal.autoCloseAfter`);
  Build & Test + Screenshots triggered.
- `agent/data-safety-1-store-backup` (80ff624): Data safety 1/4 slice 1 — `StoreBackup` + PersistenceController
  copies store before migration. Build & Test pending.

## Next action
Check both branches' CI; land each when green. Then Data safety 1/4 slice 2: model v16 entities (CloudKit-ready).

## Decisions (why)
- **Data safety 1/4 slice 1 (store backup)**: copy only when opening would migrate (metadata incompatible with
  current model, or unreadable) — not every launch (disk churn). Copy happens before `loadPersistentStores`, store
  not yet open, so plain file copies of sqlite/-wal/-shm are consistent. Folders `store-<15-digit ms>-<8 hex>` in
  Application Support/StoreBackups, newest 3 kept, other files untouched. A failed copy logs and the upgrade proceeds
  (blocking launch locks the cook out; recovery still preserves unopenable stores). Remaining slices: v16 entities
  (CloudKit-ready) + `.xccurrentversion` + CLAUDE.md "RecipeModel N" mentions; per-manager blob→entity migration
  with count check, old blobs kept one release. **Pre-mortem:** (1) upgrade loses recipes and no copy exists →
  `upgradingAnOlderStoreKeepsACopyAndTheRecipes`, `theBackupHoldsTheStoreAsItWasBeforeTheUpgrade`; (2) backups pile
  up / delete the wrong thing → `onlyTheNewestThree…`, `otherFilesInTheBackupFolder…`; (3) copy on every launch or
  on fresh install → `openingACurrentStoreMakesNoBackup`, `aFreshInstallMakesNoBackup`.
- **Pictures 1/4 slice 2 (placeholder art)**: SF Symbols composition (no bundled assets → no app-size cost, adapts to
  Dynamic Type/dark mode). Drink category → drink (iced/cold → cold, chai/latte → hot); Dessert → always sweet
  (challenge pass: "Espresso Cookies"/"No-Bake Bars"/"Apple Crisp with Oat" looked wrong); else first food word in the
  name (whole words, plural-stripped, priority sweet → breakfast → soup → snack → curry → wok → baked → fish → poultry →
  meat → veg; drink words ignored outside Drinks; meat-free words skip meat/poultry/fish; "kebab"/"bake" dropped), else
  category. Colour = cuisine family (from `cuisine` or a cuisine word in the name — bundled
  recipes have no cuisine field) else the old name hash, so lists stay varied. Accents only on tiles ≥90pt.
  Memoised with MemoCache. MealTimeCard only has the name → name keywords still work there.
  **Pre-mortem:** (1) blank tile from a symbol missing on the OS → `symbolsExist` per motif; (2) wrong/odd art
  ("Pancakes" as cake, chicken curry as bird) → `nameBeatsCategory`, `pancakesAreNotCake`; (3) cramped/cluttered on
  small thumbnails or hard to see on a theme → Screenshots of recipe list + Today, looked at.
- **Pictures 1/4 slice 1 (keep web pictures)**: the recipe KEEPS its web URL in `imageName`; a phone copy lives at
  `RecipeImages/web-<sha256(url)>.jpg` (Documents, not purgeable cache) and `RecipeImageView.resolvedSource` prefers it.
  First build swapped `imageName` to a local path (as the backlog wording said) — challenge pass showed that breaks
  refresh-from-source (diff sees a new image every open), `.recipe` export (only exports http) and backups (no image
  files → dead path on restore), plus a fixed `<id>.jpg` + `.withoutOverwriting` got stuck. URL-keyed copy fixes all,
  needs no Core Data change, recipes sharing a URL share a file. Queued from `RecipeStore.save/add` (every import path)
  + after load; one at a time; each URL tried once per launch (dead links don't refetch on every save). Trust
  boundary in `RemoteRecipeImage`: https only (ATS blocks http anyway), no localhost/.local/private/link-local/IPv6
  literal hosts, 10 MB streamed cap, ≤50 MP declared, ImageIO type check, re-encoded JPEG ≤1600px. Fetcher: ephemeral
  session, Safari UA (as page import), skips Low Data Mode. Delete removes the copy unless another recipe uses it.
  **Pre-mortem:** (1) picture still gone offline → `importKeepsPicture`, `launchKeepsExistingImports` (+ display
  path is one function, all screens use it); (2) hostile link fetched/stored → `otherReferencesAreNotDownloadable`,
  `htmlIsNotAnImage`, `oversizedIsRejected`, `hugeCanvasIsRejected`; (3) refetch storms / leaked files →
  `failureIsTriedOncePerLaunch`, `keptPictureIsNotRefetched`, `deleteRemovesUnsharedCopy`.
- **Badges 1/2 slice 2 (reveal + tilt)**: `.fullScreenCover` replaces the 380pt sheet; same wait rule (Made it / "+"
  busy) now pure `BadgeReveal.showing`. Covers don't swipe away, so the reveal has its own drag-down-to-close (keeps
  UI-test helpers that drag the window working), a ✕, `.escape` action and the 8 s auto-close. Close = medallion
  shrinks/drops toward the tab bar (the "settle onto the shelf") then dequeues — guarded so ✕/swipe/timer can't fire
  twice. Reduce Motion: no flip, sweep, confetti or settle; haptic + text stay. Tilt shine is relative to how the
  phone was held when the pager opened (baseline), clamped ±1, NaN → centre; sensors run only while the pager is up.
  Shelf tiles keep `BadgeCard` (60pt, different layout) — `BadgeMedallion` is shared by pager + reveal only.
  Shown-once + order come from existing BadgeManager queue (new tests: 3 earned mid-reveal reveal once in order;
  revoked-then-re-earned never reveals twice). DEBUG `showRevealForUITesting` sets pending without unlocking.
  **Pre-mortem:** (1) reveal can't be closed / covers tabs forever (UI tests stuck) → shot 36 test taps ✕ and waits
  for it to go; screenshot suite's drag helper; (2) a badge reveals twice or out of order → the two new
  BadgeManagerTests; (3) reveal pops over the Made it sheet or motion ignores Reduce Motion → `revealWaits…`,
  `reduceMotionShowsTheBadgeStill`.
  Review + challenge (separate agents): 8 fixed — flick-to-close via predictedEndTranslation + audit helper drags the
  window, confetti `hapticFeedback: false`, `.title.bold()`, ViewThatFits→ScrollView at AX sizes, no auto-close under
  VoiceOver, lazy CMMotionManager, shine moves by `.offset` (animatable), shine nil until a sensor reading. 4 noted
  in docs/CHALLENGES.md (other covers stall the queue, wiring untested, sheet-vs-cover, tilt baseline/settle).

- **Badges 1/2 slice 1**: groups by metric — Cooking = cooks/cuisines/same dish/rated/cook photo; Streaks; Importing =
  library size + first import/photo import + Welcome Aboard; Planning = meal plan + groceries. Earned newest first
  (undated earned after dated), locked in list (earning) order — not "closest", keeps rows stable. Pager = shelf order
  flattened, "3 of 24" instead of 24 page dots. Earn routes reuse ContentView's open* notifications (+ new
  `.openToday` for cook/streak badges); posted in the cover's onDismiss so the tab switches after it closes. Rating /
  cook-photo badges → Recipes. Collapsible "Achievements" header dropped (shelf is the point of Me). Metrics refresh on
  Me appear (badges unlock on other tabs). **Pre-mortem:** (1) a badge missing/duplicated on the shelf or in the
  pager → `everyBadgeSitsOnTheShelfExactlyOnce`, `pagerSwipesThroughTheShelfInShelfOrder`; (2) wrong progress
  ("12 / 10", wrong unit) → `progressNeverOverflowsTheTarget`, `progressReadsCurrentOverTarget…`; (3) earn button does
  nothing / wrong tab, or pager can't swipe → `earnActionOpensItsTab` + UI `testCaptureTrophyShelf` (shots 34, 35).
- **TodayView smell**: behaviour-preserving only. Snapshot takes `plansOn: (Date) -> [MealPlanModel]` (the planner's
  lookup) + an injected calendar; `propagateRecurring` stays in the view (it mutates the store — CQS). Pre-mortem:
  (1) week/feed built with different plans than before → `eachPartMatchesBuildingItAlone`, `theWeekShowsPlans…`;
  (2) tomorrow's prep-ahead lost → `tomorrowsPlansReachPrepAhead`; (3) a card/shelf missing or repeated → shelves tests
  + Today UI tests / shot 16.
- **Today+ 3/3 (progress + something new)**: "Your cooking" card after This week: streak weeks, cooks this week
  (from `CookingStreak`), next badge = locked *cooking* badge (library-size badges stay on Me — Today rewards cooking)
  with the highest share done (integer cross-multiply), then fewest left, then list order; reached-but-unrecorded
  badges skipped (no "0 more"). Tap → existing `CookingSheet`. "Try something new" = never cooked (cookCount 0 and no
  lastCookedAt), own recipes before samples, lowest FNV-1a(weekStart + id) wins (stable all week, across launches and
  list order — Swift `hashValue` is per-launch seeded). Hidden for new users (Starters shelf) and when it's the recipe
  on the Tonight card. Once cooked, next pick appears (no "done" state). Header streak chip kept (small overlap with
  the row) — tidy in Me/polish. TodayView now ~370 lines → Smell (extract refresh/plan helpers).
  **Pre-mortem:** (1) pick changes every launch/refresh or shows a cooked recipe → `pickHoldsAllWeek…`,
  `pickIsNeverCooked`, `aRecipeWithACookDateCountsAsCooked`; (2) next badge silly ("0 more", library badge, far one
  over near one) → `theClosestBadgeWins…`, `aBadgeAlreadyReached…`, `libraryBadgesAreNot…`; (3) row missing/clipped or
  tap does nothing → UI `testCaptureTodayProgress` asserts labels + Cooking sheet (shots 32, 33).
- **Today+ 2/3 slice 2 (week strip)**: own "This week" card after Use it up, before shelves: 7 days from today, filled
  dot = any plan (cooked ones too), ring = nothing. Empty day → `RecipeSelectionSheet` (dinner) for that day; a
  planned day → Plan tab (no per-day deep link into Plan yet). "Plan tomorrow" shows only when tomorrow has no dinner;
  pick = favourite → own → most cooked → name, skipping Tonight's options, this week's planned recipes and anything
  cooked in the past 7 days. "Plan it" plans directly; "Choose" opens the picker for tomorrow. The picker's choice is
  planned in the sheet's onDismiss (mealPlanner badge sheet can't show over a sheet mid-dismissal). Both buttons are
  frosted (Cook this keeps the one accent). Shown for new users too (planning a starter is fine). Challenge pass
  (4 real fixed): Today now runs `propagateRecurring` from today (recurring dinners showed as empty and got planned
  over); refresh on scene active (overnight-background "Plan it" dated today); `planDinner` never replaces an existing
  dinner; date circle `@ScaledMetric` + scale factor; "Choose" button dropped (same as tapping tomorrow's cell);
  VoiceOver day names en_GB like Use it up. Skipped `NSCalendarDayChanged` async loop (Notification isn't Sendable —
  Swift 6 risk); scene-active refresh covers the overnight case. Notes → CHALLENGES.md: planned-day tap opens Plan on
  today (no date deep link); two week-strip visual languages (Plan's per-meal colours vs Today's single dot).
  Deep-review (high): 4 findings — 2 already fixed by the challenge pass (rollover, ScaledMetric); fixed "Plan it"
  Voice Control input label, picker "Clear search" empty-state action (+ empty library → empty day opens "+"); method
  reference → closure (MainActor conversion risk).
  TodayView is now ~340 lines → Smell candidate (extract refresh/plan helpers). **Pre-mortem:** (1) dots on the wrong
  day (time zones / late-night plans) → `lateNightPlanCountsForItsOwnDay`, `plansOutsideTheSevenDaysAreLeftOut`;
  (2) "Plan tomorrow" offers tonight's dish or one just cooked, or shows when tomorrow is planned →
  `pickSkips…`, `tomorrowWithADinnerNeedsNoSuggestion`; (3) tapping a day does nothing / plan doesn't appear →
  UI test `testCaptureTodayWeek` asserts the tapped day reads "dinner:" after picking (shots 30, 31).
- **Today+ 2/3 slice 1 (Use it up)**: reads `kitchen.inventoryItems` (the ones with expiry dates), window 0–3 calendar
  days (matches `isExpiringSoon`), expired items left out (Kitchen's alerts cover them). One row per recipe, max 3
  rows: each item gets its best recipe not already on the row; if all its recipes are taken it joins that row
  ("Spinach and Feta: use by tomorrow"). Best = uses more expiring items → more kitchen coverage → favourite → own
  over sample → name. Same ingredient twice = one entry at its soonest date. Placed after prep-ahead, before shelves;
  one card with photo rows (calm). Kept existing Plan-tab `PantryExpirySuggestions` (recipe-centric, different job)
  — possible Smell (two expiry matchers). **Pre-mortem:** (1) wrong items (expired / 4+ days / no date / used-up)
  → UseSoonTests window cases; (2) same recipe twice or an odd pick (gin→ginger, sample over own) → pairing tests;
  (3) row clipped / unreadable or missing → screenshot 29 + UI assert on "Spinach: use by tomorrow".
- **Today+ 1/3 slice 2**: eat time is a "Dinner at 7 pm" pill (Menu + Picker, 5–10pm on the half hour) beside
  Shuffle, not in Settings and not on the timing line — review found the line vanishes once the time passes (stranding
  the choice) and some lines ("Quick tonight?", morning prep) ignore it. Hidden for a planned lunch/snack
  (`asksEatTime`). Stored minutes not in the choices fall back to 7pm. Quick-ideas evening starts at
  max(6pm, eatAt − 1h). Action row uses ViewThatFits (pills drop below "Cook this" at large text). "Calmer": dropped the
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
