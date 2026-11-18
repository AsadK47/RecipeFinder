# Challenges — the devil's advocate

Written by the **daily challenger** scheduled task (owner 2026-11-11: "challenge aggressively and frequently"),
which assumes every change and rule is wrong until the evidence says otherwise, and by the per-item challenge pass
(BACKLOG step 6d). Its job is to argue *against* how this
project works, not to review code line by line: CLAUDE.md rules, BACKLOG priorities and guardrails, WORK.md +
`docs/DECISIONS.md` Decisions, architecture, CI, test quality ("would this test fail if the feature broke?"), UX assumptions and
anything that looks outdated. Every run it asks, of what changed and of the wider app:
- **Break it** — what if I did this? (hostile/odd input, offline, killed mid-save, huge data, accessibility extremes)
- **Attack it** — does this guard against injection? (web pages, pasted/OCR text, shared files and zips, deep links,
  WKWebView, prompt injection into the on-device model)
- **Simplify it** — what is the simplest version? Are we making it too complex? Why can't it be simpler?
- **Delete it** — what happens if we simply remove this entirely? Who would notice?
- **Tests** — would this test fail if the feature broke?

Each challenge must carry evidence (file:line, a run, a screenshot, a measured number,
or a current Apple/Swift doc) — opinion alone isn't a challenge.

The owner answers each one: **Accept** (it becomes a BACKLOG item or a rule change), **Reject** (with one line why —
the challenger must not raise it again unless the evidence changes) or **Later**.

Format, newest first:

```
## YYYY-MM-DD
- ⚔️ [Break|Attack|Simplify|Delete|Tests|…] <what we assume> — <why it may be wrong, with evidence> — <alternative> — cost if we're wrong: <…>
  → Owner: Accept / Reject (<why>) / Later
```

## Playbook — established methods, not ad-hoc questions

Pick the methods that fit what's being challenged; every run covers at least **1, 2, one of 3–5, 6 and 7**.

1. **Key Assumptions Check** (CIA *Tradecraft Primer*; Red Team Handbook). List the assumptions the change or rule
   rests on; rate each *solid / caveated / unsupported*; challenge the unsupported ones with evidence.
2. **Premortem** (Gary Klein; Red Team Handbook). "It's three months later and this failed for a real cook — why?"
   Write the top causes and whether any test, screenshot or check would have caught them.
3. **Threat model — Shostack's four questions** (What are we working on? What can go wrong? What are we going to do
   about it? Did we do a good job?) with **STRIDE** at each trust boundary: Spoofing, Tampering, Repudiation,
   Information disclosure, Denial of service, Elevation of privilege. Boundaries here: web pages/JSON-LD, pasted and
   OCR text, shared files and zips, deep links, share extension + App Group, WKWebView, backups, on-device model.
4. **OWASP MASVS v2.1** (with the MASTG test guide) — the mobile app checklist, by category: STORAGE, CRYPTO, AUTH,
   NETWORK, PLATFORM, CODE, RESILIENCE, PRIVACY. Ask which controls a change touches and whether they still hold.
5. **OWASP Top 10 for LLM Applications** (2026 edition; prompt injection is #1) for anything using the on-device
   model. Assume instructions can be bypassed: model output is untrusted data, never an action; check what a
   hostile recipe page or caption could make it produce.
6. **Break it — Heuristic Test Strategy Model, SFDIPOT** (James Bach): vary **S**tructure, **F**unction, **D**ata
   (empty, huge, odd units, emoji/RTL, duplicates), **I**nterfaces (share sheet, files, clipboard, deep links),
   **P**latform (iOS versions, Apple Intelligence on/off, low storage), **O**perations (how cooks really use it —
   offline, interrupted, VoiceOver, largest text) and **T**ime (timezones, midnight, killed mid-save, two at once).
7. **Simplify it / Delete it** — YAGNI and KISS, checked against **Chesterton's fence**: before recommending removal,
   say why the thing exists (git log/blame); then ask what problem it solves, for whom, how often, what the smallest
   design is, and what is lost if it's deleted outright.
8. **Would the tests notice?** — a mutation-testing mindset: name a one-line bug in the code under test and say
   whether any test would fail. If none would, that's a finding.

<!-- challenger adds new entries at the top, right below this line -->

## 2026-11-18 (item pass: Me with character slice 4b — fixed: cook badges hidden when the log never reached the rung, same-day badges flooding the preview, future cooks, "Where it all started" above older rows, January-flaky year assertion; sweet chilli: hyphenated names)
- ⚔️ [Break] Story counts the cook log while the hero and badges sum `cookCount` — after deleting a cooked recipe the hero can say 8 meals while the story says "10 meals cooked" (`CookingStory.swift` vs `MeStats`) — one source for both (log), or label the story "cooks" — cost if wrong: two numbers on one screen. Accepted for now: the log is the history of what happened; the hero matches the badges by design (DECISIONS slice 1).
  → Owner: Accept / Reject / Later
- ⚔️ [Break] Story refreshes on `streak`/`recipes` changes only — an iCloud merge of past-year cooks that moves neither stays stale until Me reappears (`MeView.swift` onChange) — observe the log itself (it's `@ObservationIgnored`) — cost if wrong: an old moment shows up a tab-switch late.
  → Owner: Accept / Reject / Later
- ⚔️ [Tests] Only badge lines open anything (spec: "tap to open the moment"), and badge line → shelf has no UI test — first cook / milestone lines could open that week's cookbook page once cooks link to recipes — cost if wrong: a dead-looking row; low.
  → Owner: Accept / Reject / Later

## 2026-11-18 (daily challenger)
- ⚔️ [Strategy] "Taste fingerprint" is on the roadmap because the owner unparked Me — but `docs/PRODUCT.md:53-54` still lists *taste fingerprint* under **Parked**, Me appears in neither the loop table nor the phases, and `origin/agent/me-taste-story` (f72de15 + 3a9b77a, 652 + 127 lines, 5 axes, ~100 hand-written English keywords) is built anyway. Last 2 days on main (`git log --since=2.days`, scopes): me 7, groceries 7, import 7, **cooking 0, plan 0**; WORK.md still lists "Cook: next slice" as not started (In progress, line 6). The Parking-lot exit test (PRODUCT Discipline 2, "how would we notice?") has no answer for a fingerprint — alternative: update PRODUCT.md to say what Me is for in the loop (Remember) and cap it at the hero + cookbook, park fingerprint/story again, and make the next lane item Cooking flow step 2 — cost if wrong: Phase 1's one screen that decides "did I cook tonight?" stays half-finished while the profile gets a radar chart.
  → Owner: Accept / Reject (why) / Later
- ⚔️ [Break] "Rules are visible and simple, so a trait never appears for a reason the cook couldn't guess" (`TasteFingerprint.swift` doc comment, branch `agent/me-taste-story`) — the name rule has no exclusion: `spicyNameWords` contains "chilli" (line 179) and line 141 ORs it in with no `notHotLineWords` check (that list, line 177, guards ingredient lines only), so "Sweet Chilli Chicken" is **Spicy** while the same text as an ingredient is excluded (tests cover only the ingredient line, `TasteFingerprintTests.swift:42`). Likewise "fish"/"rice"/"radish" in `steamedNameWords` silently remove Baking from any name containing them, and every list is English-only while the library now holds FR/ES/IT/DE/PT/JA imports (Tester 1 slice 3) — those recipes score nothing, so a non-English cook sees "You lean towards quick cooking — 9 of 15" from the only trait that is numeric. The headline is a claim about the person, shown on their profile and shareable — alternative: derive traits from fields the app already trusts (time ≤ 30 min → Quick, `cuisine`, `category`, tags) and drop name/ingredient keyword guessing, or hide the card below ~10 cooks — cost if wrong: a confident, wrong sentence about someone's taste, which is exactly what an Instagram-feel app can't afford.
  → Owner: Accept / Reject (why) / Later
- ⚔️ [Premortem] "Cook it well" is the north star's step 4 and its screen hasn't moved: `screenshots-preview/06-cooking-mode-web.jpg` (2026-11-18 05:25Z) shows the same design as the 2026-11-13 main image — "Gather your ingredients", 4 of 5 rows with no amount ("Ripe bananas", "Plain flour", "Light brown sugar", "Butter, melted"), no per-step ingredient, Next in blue-on-blue. Plan (Phase 2) is `04-meal-plan-web.jpg`: a *Meal Planner* month calendar whose day-one state is "No Meals Planned for This Day" (principle 4: an empty state), not the week-of-photos PRODUCT.md promises. Three months out the likeliest reason cooks didn't cook more: the polished screens (Me, Groceries tabs) sat around a cooking mode that makes you read a list you can't act on. `CookingModeView.swift` is 4 % covered (`coverage.txt`, main @ 613677b) so a change there is unprotected too — alternative: freeze Me/Groceries polish until Cooking flow slice 2 (per-step ingredients with amounts, timers) lands, and add one UI test "open recipe → Cook → reach last step → Made it" to push CI — cost if wrong: the dogfood gate ("used it on the phone for a week") passes on the profile and fails on dinner.
  → Owner: Accept / Reject (why) / Later
- ⚔️ [CI] Yesterday's staleness point is unchanged and now worse: the `screenshots` (main) release is still from 2026-11-13T09:28Z — five days, 36 images — while `screenshots-preview` has 56 (adds Made it, Cookbook, Discovery 0–3, At home, Me next-up, taste). Anyone following BACKLOG step 6b/this routine's own instructions to "look at main's screenshots" sees no Cookbook, no Discover feed, no Kitchen, and the old Me — alternative: `screenshots.yml` also runs on main pushes touching `Views/**` (it already produces the images on every branch), or the preview run publishes to `screenshots` when its branch lands — cost if wrong: reviewers and the owner judge main from a five-day-old picture. (Raised 2026-11-17, unanswered; not repeating the rest.)
  → Owner: Accept / Reject (why) / Later
- ⚔️ [Tests] The Me rebuild shipped with logic tested and wiring not: `MeHeroCard.swift`, `ProfileBadgesSection.swift`, `ProfileView.swift`, `MeView.swift`, `ProfileSettingsView.swift` and `KitchenAtHomeView.swift` are all 0 % in the nightly unit coverage (main @ 613677b: app 27.16 %, 15 880/58 471 — down from 27.18 % on 11-17 while the test target grew to 98.48 %). Mutation: delete the `updateProfile` call in `ProfileSettingsView`'s Save, or make `MeHeroCard`'s rename commit a no-op on focus loss → no push-CI test fails; only UI tests that push CI doesn't run per commit (CHALLENGES 11-17 entries already concede this for three different screens). The count of "accepted, not fixed — needs a view-model seam" notes keeps growing and nothing has been scheduled — alternative: one batch item "view-model seams for Me/Groceries/Today" and a rule that a new screen's primary action gets one push-CI UI smoke test — cost if wrong: TestFlight builds go out on every app push (`testflight.yml`) with unchecked buttons.
  → Owner: Accept / Reject (why) / Later
- ⚔️ [Threat] Still open from 2026-11-17, not acted on and not answered: `HTMLFetcher.swift:36` buffers the whole response with `session.data(for:)` (no size cap, only the 30 s timeout) in both the app and the Share extension, whose jetsam limit is far lower; images already have a 10 MB cap (`RemoteImageFetcher.swift:49`). Foreign-recipe import (slice 3) just widened the set of pages people will paste — alternative: `session.bytes(for:)` with a 5 MB cap — cost if wrong: Share-extension import silently dies on a heavy page and reads as "import is broken".
  → Owner: Accept / Reject (why) / Later

## 2026-11-18 (item pass: Me with character slice 4a — fixed: baking powder/steamed buns as baking, dried herbs as fresh, optional/mild chilli as spicy, ties to spicy, five empty bars, buffalo mozzarella, VoiceOver row wrapper, UI test not proving the trait)
- ⚔️ [UX] Shares overlap (one butter chicken can be Spicy, Comforting and Quick at 100% each) — TasteFingerprint.swift `from(recipes:)`; rows read as a breakdown that doesn't add up — alternative: label rows "of your meals" or normalise — cost if wrong: a cook wonders why it's 160%.
  → Owner:
- ⚔️ [UX] One dominant trait draws a thin sliver, not a blob (48-me-taste: Quick 60%, others ≤27%) — TasteFingerprintCard.swift `TasteShape` floor 0.06 — alternative: floor ~0.15 or sqrt scaling — cost if wrong: the shape looks broken rather than characterful.
  → Owner:
- ⚔️ [Break] `TasteTraitRecipesView` has no empty state if every recipe behind a trait is deleted while the list is open — rare; Back still works — cost if wrong: a blank screen with a title.
  → Owner:

## 2026-11-18 (item pass: Me with character slice 3 — fixed: ladder rungs crowded Next up, Today's badge hidden after its card closed, pager ignored the tapped row, unreachable empty state, VoiceOver "slash")
- [Function] Captions under badges use fixed 11pt and titles cut at 88pt at accessibility sizes — pre-existing `BadgeCard` sizing; revisit with a Dynamic Type pass.
- [Performance] Profile recomputes shelf/earned/next-up (24 badges) in `body` — trivial cost and kept live with badge unlocks; move to state if Profile grows.
- [Function] See all collapses each time Profile is pushed — on purpose (the shelf is behind it); remember the choice if testers ask.

## 2026-11-18 (item pass: Me with character slice 1b — fixed: UI test passed with saving broken, cursor left text behind, "Mary Ann" re-split, draft lost on leaving the tab, disabled PrimaryButton, test name in screenshots)
- [Function] Settings › Profile's name needs Save; Back with an edited name discards it while the hero's field saves on tap-away — explicit Save kept on purpose (a form), revisit if testers lose edits.
- [Function] If `.onAppear { fieldFocused = true }` doesn't take, the field shows without a keyboard and only Done/tap-in closes it — not seen in the Screenshots run; a keyboard assertion would be flaky with CI's hardware keyboard.
- [Tests] Settings › Profile Save has no test (thin glue onto `updateProfile`, which `ProfileManager` tests cover).

## 2026-11-17 (item pass: Kitchen you can find slice 2 — fixed: "N ingredients" counted unlisted use-by items, tag hit area reached the minus button)
- [Function] Today's link and the expiry reminder land on Groceries' search suggestions if text was left in the field — shared with the reminder path; clear the field on a side change if a cook trips on it.
- [Data] Use-by items with no alert (fresh, not low) aren't listed on At home and an "In kitchen" tag on one can land on the empty state — pre-existing, such items arrive only via restore/sync.
- [Tests] `testGroceriesReachesAtHomeInOneTap` taps the first "In kitchen" tag, not Saffron's; the Spinach assertion passes on a simulator that already has plain items. UI tests run per-push shards + nightly.

## 2026-11-17 (item pass: Me with character slice 1 — fixed: "dinners" → "meals", streak-only hidden, streak stale after iCloud merge, UI assertion that couldn't fail)
- [Function] "Cuisines tried" counts a category when cuisine is missing — pre-existing badge rule with its own test → Needs owner.
- [Simplify] `CookingStreak.cooksThisYear` now has no reader — kept for slice 4 ("your cooking story"); delete if that slice doesn't use it.
- Not fixed on purpose: >9,999 meals (unrealistic), long names wrap, contrast of white on the six chef colours measured 4.6–6.7:1.

## 2026-11-17 (daily challenger)
- ⚔️ [Strategy] The lanes are on the roadmap — PRODUCT.md says "Now: data you can trust", then Phase 1 Cook, then Phase 2 Plan; the Queue's top item is **Me with character** (BACKLOG Queue line 1) and 13 of the last 19 app-code commits are the RecipeDetailView split (`git log --since=2.days`: e3ba711..2ce0a78, Batch A, 4 slices of pure refactor + pinning tests). *Cooking flow* has been 🚧 since 2026-11-15 with one landed slice, Plan (Phase 2) has no commit, and Recently deleted (4/4 of "Now") sits unmerged waiting on an owner-only CloudKit schema deploy (WORK.md). Me isn't a loop step, and nothing says how it moves dinners cooked/week — the Parking-lot exit test (PRODUCT Discipline 2) fails on "how would we notice" — alternative: next slice is Cooking flow step 2 (per-step ingredients + timers), Smell batches only when a lane is blocked, and the CloudKit deploy goes to the top of Needs owner as a single 🙋 with the exact click path — cost if wrong: a month of polish on a profile page while the one screen that decides "cooked tonight?" (cooking mode) ships half-done to testers.
  → Owner: Accept / Reject (why) / Later
- ⚔️ [Strategy] Today is "one pick, what to do now" (PRODUCT table, principle 1) — `16-today-web.jpg` (main) shows **six** tappable things above the fold on day one: *Start a streak*, *Cook this →*, *7 pm*, *Shuffle*, *Plan it*, and the stats card chevron, plus a "Your cooking · 0 week streak · 0 cooks this week" card (principle 4: an empty-state number, and a streak chip offering a streak the cook hasn't earned). The card also says "Start by 6:30 to eat at 7" at "Good morning" — the pick is a 30-min soup under a morning greeting — alternative: one button on the pick ("Cook this"), time and Shuffle behind a long-press/ellipsis menu, hide the stats card and streak chip until the first cook — cost if wrong: Today (the tab testers land on) trains "browse around" instead of "start cooking".
  → Owner: Accept / Reject (why) / Later
- ⚔️ [CI] "Run Screenshots and LOOK at the images" (AGENT_LESSONS 8, BACKLOG step 6b) rests on images that are current — the `screenshots` release asset `01-recipes.png` was last updated 2026-11-13T09:28Z (`gh api repos/AsadK47/RecipeFinder/releases/tags/screenshots`), four days and 40+ commits ago (Recipes toggle, Keep browsing, cuisine chip, My Cookbook, cooking-mode rework). `06-cooking-mode-web.jpg` still shows the old "Gather your ingredients" list with 4 of 5 rows missing amounts ("Ripe bananas", "Plain flour"…); there is no Recipes Discover/My-recipes, Cookbook or Made-it image at all in the 20 assets — alternative: screenshots job runs on every main push touching `Views/**` (or nightly with a freshness line in the Log), and a "stale > 48 h" check in the reviewer routine — cost if wrong: reviewers and this challenger sign off on screens nobody has seen rendered.
  → Owner: Accept / Reject (why) / Later
- ⚔️ [MASVS-PLATFORM] Opening a shared `.recipefinderrecipe` is safe because the file read just works — `ContentView.swift:62-67` does `Data(contentsOf: url)` inside `.onOpenURL` with no `startAccessingSecurityScopedResource()`, though the target sets `LSSupportsOpeningDocumentsInPlace = YES` (`project.pbxproj:3318`, so Files/iCloud Drive hand over a security-scoped URL); the other three file entry points all call it (`DataManagementSettingsView.swift:257`, `OtherAppImportSection.swift:70`, `PhotoImportSheet.swift:136`). Likely result: a recipe opened from Files/iCloud/Mail-in-place shows "couldn't be opened" (the alert at :73 masks it as "damaged"). Same line reads the whole file synchronously on the main actor with no size cap before `JSONDecoder` — alternative: scope-access + `defer stop`, size check (e.g. ≤5 MB) and decode off-main — cost if wrong: the one share-a-recipe path between two cooks fails silently-ish, and a multi-GB file hangs the UI. (Traced, not run on device — Inbox 🐞.)
  → Owner: Accept / Reject (why) / Later
- ⚔️ [Threat] STRIDE-DoS on the web-import boundary: images are size-capped (`RemoteRecipeImage.maxBytes` = 10 MB, `RemoteImageFetcher.swift:49-54`), but the HTML fetch is not — `URLSessionHTMLFetcher.fetch` (`HTMLFetcher.swift:36`) uses `session.data(for:)`, buffering the whole body, with only a 30 s timeout (`RecipeImportPipeline.swift:68`); `RecipeParser.parse(html:)` then runs regexes/JSON-LD over all of it. A hostile or just huge page (the import URL is user- or clipboard-supplied, `ClipboardRecipeLink`) can stream hundreds of MB in 30 s; the same pipeline runs in the Share extension, which iOS jetsam-kills at a far lower memory ceiling than the app — alternative: `session.bytes(for:)` with a 5 MB cap (same pattern already written for images) and a Content-Type check — cost if wrong: import from a bloated page kills the extension with no error, which testers read as "import is broken".
  → Owner: Accept / Reject (why) / Later
- ⚔️ [Tests] Coverage says the tests check logic, not screens: app target 27.18 % (15 596/57 379) vs test target 98.46 % (`coverage.txt`, main @ cb87467). The Phase-3 headline, `DiscoveryChapterView.swift` (199 lines), `TodaySections.swift` (662), `TodayIntroCards.swift`, `NotesStepView.swift` (646) and `ImportView.swift` are all 0 %; one-line mutation "swap the two branches in the Discover|My recipes toggle / drop `Shuffle`'s action" → no unit test fails, only nightly UI tests (which skip-when-already-cooked, see the slice-4 entry). With the Recipes feed now the product's Instagram-feel promise, a wiring bug there ships to TestFlight on the next main push (testflight.yml uploads on every app-code push) — alternative: one UI smoke test per tab on push CI (launch → tab → primary control exists/acts), counted against the ≤10 min budget — cost if wrong: broken primary buttons found by the owner on a phone.
  → Owner: Accept / Reject (why) / Later
- ⚔️ [Delete] 147 `origin/agent/*` branches exist, 11 already merged into main (`git branch -r | grep -c agent/`; `--merged origin/main`). The Inbox 🧹 "delete by hand — proxy refuses" line is from 2026-11-09, eight days unanswered, while CLAUDE.md says every `agent/<slug>` push triggers CI; leftover branches are noted per-item as "auto-cleanup" in WORK.md but nothing does it. Chesterton: they were safety nets for unlanded work — but 136 unmerged ones (many named for landed items: `my-cookbook-2`, `detail-split-b/-c/-d`, `cuisine-chip`, `keep-browsing-pop`) are noise that makes "open `origin/agent/*` branches" (this routine's own input) unreadable and invites resurrecting superseded code — alternative: a scheduled workflow that deletes `agent/*` branches merged or untouched for 14 days (workflow change → owner) — cost if wrong: a reviewer or agent picks up a stale branch (e.g. `reset-store-copies`) as if current.
  → Owner: Accept / Reject (why) / Later

## 2026-11-17 (item pass: Tester 1 slice 3 — foreign recipes; fixed: 1h05 times, portions dropped as servings, brand names, header-less steps dropped, JA counters/ranges, hour words, unanchored servings regex)
- ⚔️ [Assumption] The units listed cover what foreign pages write — French "CS"/"CC" capitals, Japanese "時間" hours, German "Becher" and Japanese "杯" (bowl) aren't mapped, so those lines keep their amount in the name — alternative: add them when a tester's paste shows them — not done: ambiguous ("CS" vs a name, 杯 isn't a fixed measure) — cost if wrong: a few lines need a manual amount.
  → Owner: Accept / Reject (why) / Later

## 2026-11-17 (item pass: 🐞 opening a recipe file; fixed: fallback copy, real 5 MB bound, two-tap race, extension case, test temp files)
- ⚔️ [Assumption] Files hands `onOpenURL` an already-downloaded file — `RecipeFileExporter.read(from:)` reads with a plain `FileHandle`, no `NSFileCoordinator.coordinate(readingItemAt:)` (Apple's pattern for in-place documents, which also triggers an iCloud download) — alternative: wrap the read in a coordinated read — not done: unconfirmed on device, the error now tells the cook to let it download — cost if wrong: an iCloud-only file fails the first tap.
  → Owner: Accept / Reject (why) / Later
- ⚔️ [Attack] A shared file's `imageURL` (any http URL, `RecipeFileExporter.decode`) is fetched when the recipe shows, so the sender can learn when it was opened (Information disclosure) — alternative: drop or ask before loading a shared file's remote image — not done: existed before this change, out of scope — cost if wrong: a read receipt the cook didn't agree to.
  → Owner: Accept / Reject (why) / Later

## 2026-11-17 (item pass: Tester 1 slice 2 — Badges from Today; fixed: mid-transition cover, untestable scroll, badge row kept after all earned)
- ⚔️ [Strategy] "Your cooking" now has two chevron buttons that both lead to badges (stats → Cooking sheet with every cooking badge; next-badge row → the shelf) — alternative: whole card → shelf on the next badge, streak explanation moved to the shelf — not done: the Cooking sheet is the streak's only explainer and the tester asked for the badge link, not for the sheet to go — cost if wrong: Today keeps one more tap target (ties to the daily challenger's "six tappables" point above).
  → Owner: Accept / Reject / Later
- Not fixed: the 450 ms settle delay in `ProfileView.handleShelfRequest` is a timing guess; a request left by backing out of Profile within it fires on the next Profile visit.

## 2026-11-17 (item pass: Smell Batch A slice 4 — detail actions split; challenger 0 defects)
- ⚔️ Tests — `RecipeDetailView+Actions.recordCook` wiring (assign `recordingCook()`'s result, then sync/persist/Made it) has no push-CI test; dropping `recipe = cooked` only fails nightly `RecipeFinderHabitLoopUITests`, which skips when already cooked today — a view-model seam would let a unit test catch it — cost if wrong: Made it/review prompt read a stale cook count.
  → Owner: Accept / Reject / Later
- Not fixed (pre-existing): the one-cook-a-day rule lives only in `RecipeModel.recordingCook`; `PersistenceController.recordCook` (`PersistenceController+RecipeWrites.swift:372`) increments unconditionally with its own `Date()`, so any future caller that skips the model rule double-counts in the store.

## 2026-11-17 (item pass: Smell Batch A slice 3 — fixed: tints + notes link untested, factRows test home; reviewer 0 defects)
- ⚔️ Simplify — `RecipeDetailCopy.shortTime` replaces " hours"/" hour", but its only inputs (`prepTimeDisplay`/`cookTimeDisplay` via `DurationFormatter.label`, `RecipeFormatters.swift:80`) already say "hr" at 60+ min, so those two replacements are dead (pinned as-is in a refactor) — drop them with the recipe-times Smell — cost if wrong: none.
  → Owner: Accept / Reject / Later
- ⚔️ Break — `RecipeDetailCopy.facts(for:)` hides an empty cuisine but shows an empty difficulty/category as a blank value over its caption (unchanged from before the move) — hide empty facts the same way? — cost if wrong: a bare "Category" caption on imports with no category.
  → Owner: Accept / Reject / Later

## 2026-11-17 (item pass: Smell Batch A slice 2 — fixed: one-tap timer start untested, pass-through test of TimeExtractor)
- Not fixed (speculative, no `.xcstrings` yet): `RecipeCookHistoryCard` builds its Label from a `String`
  (`RecipeDetailCopy.cookCount`), not a `LocalizedStringKey` literal — revisit when localisation lands.

## 2026-11-16 (item pass: 🟡 Keep browsing pop — fixed: open recipe stayed on screen; 0 defects in the fix)
- Not fixed (speculative): the `.openRecipe` deep link (`openPendingRecipeIfAvailable`) resets the path but doesn't
  close Filters/Collections sheets or rebuild the stack — untested whether a row-pushed recipe stays underneath.
- Not fixed (refactor, own commit): `dismissBadgeSheet` now exists in 3 UI test files → move to a shared XCTestCase
  extension next time a UI test file is touched.

## 2026-11-16 (item pass: tester feedback 1 slice 1 cuisine chip — fixed: stack pop, spellings, sheets, import parsing)
- ⚔️ Tests — the cuisine request applied from `onAppear` (chip tapped on a recipe opened from Today or Me, Recipes
  never opened) has no test; the UI test starts in Recipes (`RecipeFinderSheetPresentationUITests`) — add a Today-path
  UI case when Today's shelves are stable — cost if wrong: chip switches tab but shows the unfiltered list.
- ⚔️ Tests — the UI test saves "American" onto the first seed recipe on the simulator (no store reset under
  `-ui-testing`), so later tests on that sim see a 5-fact card and the chip — cost: a position-based test drifts.
- ⚔️ Simplify — the chip repeats the facts card's Cuisine and shows even when only this recipe has that cuisine; a
  lowercase value reads "More italian recipes" — consider hiding below 2 matches / title-casing — cost: small.
- ⚔️ Structure — `RecipeBrowseRequest` sits in `Views/Main/AppTab.swift` (no new file without Xcode) and
  `RecipeSearchView.swift` is ~490 lines → Smell Batch D already lists it.

## 2026-11-16 (item pass: Recipes toggle + Today "Keep browsing →" — fixed: Keep browsing landed on an old detail or search results, My-recipes default rested on a moot test reason, toggle shown when it did nothing, scroll carried between sides, feed built while hidden, UI test asserted nothing)
- ⚔️ [Copy] "Not feeling it?" frames tonight's pick slightly negatively — the owner's own wording (PRODUCT.md, option D).
  → Accepted.
- ⚔️ [Data] *My recipes* is the whole library A–Z, so the cook's own recipes sit among 332 bundled ones (the deleted preview put own + favourites first).
  → Later: own + favourites first on My recipes.
- ⚔️ [Discoverability] "Keep browsing →" shows only under a tonight pick, so a brand-new cook (no pick) doesn't see it; the toggle still does.
  → Accepted.
- ⚔️ [Structure] `RecipeSearchView` is ~470 lines (smell threshold ~300).
  → Smells list: Extract the filter state into a value + the header/mode picker into views.

## 2026-11-16 (item pass: 🟡 Inbox nutrition 0 g → 0% — fixed: NaN/negative unpinned, infinity trapped in `Int(_:)`)
- ⚔️ [Break] A trace that prints as 0 g still shows 1% RI — `NutritionLabelFormat.percent` rounds any positive value up
  to 1% while `macro`/`salt` print 0.04 g fat as "0.0" and 0.004 g salt as "0.00" (NutritionLabelFormat.swift:20) — show
  "<1%" (common on UK packs; challenger from memory, unchecked) or take the % from the shown amount — cost if we're
  wrong: a label line that contradicts itself on near-zero nutrients. Not changed: it's a copy/product call, not the bug.
  → Owner: Accept / Reject / Later

## 2026-11-16 (item pass: My Cookbook slice 3 — fixed: name on the clear end of the card's shade, landscape photos upscaled ~1.33×, "today"/"yesterday" baked into a kept picture, see-through placeholder card, system PNG instead of a 1080×1350 JPEG, dead-end render error, tautological pixel test → real render tests, CGSize in a Domain file)
- ⚔️ [Privacy] The recipe *file* share strips rating/cook count/photos (`RecipeFileExporter.swift:10`), while the cookbook card shares exactly those; the policy never describes outbound sharing (§7.3 promises a description before "sharing" ships). The app sends nothing itself — the user picks the destination — so no text was changed (legal text = owner guardrail); question in Needs owner.
  → Owner: Accept / Reject / Later
- ⚔️ [Tests] The share step lives in `testZZCaptureCookbook`, which push CI skips (UI tests run nightly/Screenshots only); unit tests now cover the render, but the button→sheet path is checked once a day.
  → Owner: Accept / Reject / Later

## 2026-11-16 (item pass: Docs refresh slice 5 — fixed: 10 overclaims in CHANGELOG entries (Reset photo clear-up sounded like single deletes, onboarding, #16 cause unproven, share-extension cookies, fallback picture, "only"), 5 missing 14 Nov sync entries, parser silently dropped malformed lines / typo'd headings / unclosed fences / empty file, `fill` duplicated the page with END before START, tests missed week rounding, order, Behind-line escaping)
- ⚔️ [Verify] CI never runs `tools/test_website_behind_the_build.py` or `--check` (build.yml ignores `tools/**` and `*.md`); a malformed CHANGELOG reaches main unless the lander runs `--check` (step 8 says to; the website run fails loudly). Adding a small ubuntu job is a workflow change → owner.
  → Owner: Accept / Reject / Later
- ⚔️ [Simplify] whats-new (`whats-new-copy.json`) and Behind the build (CHANGELOG "For you") are two per-item user lines; whats-new could read the CHANGELOG instead of the JSON.
  → Owner: Accept / Reject / Later
- ⚔️ [Copy] The renderer curls `'` but leaves straight `"…"`, so quotes mix on the page; inline Markdown would show literally (none today).
  → Owner: Accept / Reject / Later
- ⚔️ [Publish] Sync entries (14–15 Nov) describe photo sync and the new policy while the website `privacy.html` is still stale and the CloudKit Production schema isn't deployed — the website session should publish Behind the build after privacy.html updates.
  → Owner: Accept / Reject / Later

## 2026-11-15 (item pass: My Cookbook slice 2 — fixed: View all badges landed on a Me with no badges (both reviewers), VoiceOver read "5 slash 24", a UI assertion that couldn't fail, seeded cookbook disagreed with "N cooks this year", line stale over New Year, row squeezed at accessibility sizes, "?" avatar)
- ⚔️ [Data] The cookbook counts `recipe.cookCount`, the line counts the cook-date log — older libraries whose counts predate the log can show more cooks on the pages than "this year" suggests — alternative: one per-cook record (slice 3, model change → owner) — cost if wrong: two numbers that don't match.
  → Owner: Accept / Reject / Later
- ⚔️ [Simplify] Me → profile row and Me → ⚙︎ → Settings → Profile now open the same screen — drop the Settings row in Me 3/3.
  → Owner: Accept / Reject / Later
- ⚔️ [Break] "Earn it here" from the pushed badge pager switches tab but leaves Me on Profile, so the next visit to Me opens on Profile, not the cookbook — minor; pop on earn if testers notice.
  → Owner: Accept / Reject / Later
- ⚔️ [Loop] The one line uses the self-picked chef type ("Home Cook"), not an earned title ("Spice Explorer"); `rawValue` as display text is a localisation smell.
  → Owner: Accept / Reject / Later

## 2026-11-15 (item pass: My Cookbook slice 1 — fixed: name on the clear end of the shade, page height clipped large text, lines rebuilt per render and stale over midnight, nothing showed more pages exist, headline squeezed at large text, cookbook keyed off the gear's flag, no same-date order test, seed trap on duplicate ids)
- ⚔️ [Break] Page picture = last-added own photo without checking the file exists — a synced row whose file isn't on this device shows the art instead of the web picture (same as `heroImageName` today) — alternative: pick the last photo that resolves — cost if wrong: art instead of a picture on some pages.
  → Owner: Accept / Reject / Later
- ⚔️ [Break] `RecipeModel ==` ignores `lastCookedAt`/`name`, so a sync merge that only moves a cook date reorders the cookbook on the next visit to Me, not live — accepted: changing `==` touches every list diff.
  → Owner: Accept / Reject / Later
- ⚔️ [Loop] Me still has two primary actions (cookbook + profile form/Save) — next slice moves profile, badges and chef type one tap deeper.
  → Owner: Accept / Reject / Later
- ⚔️ [Tests] No unit test fails if Me's `navigationDestination` or `refreshCookbook()` is removed — caught only by `testZZCaptureCookbook` in the Screenshots run; `42-cookbook-one` depends on `testZCaptureMadeIt` running first. `RecipeStore.swift` now 347 lines (DEBUG seeds) — extract them in the Smells batch.
  → Owner: Accept / Reject / Later

## 2026-11-15 (item pass: ephemeral link import — fixed: test wiped the real shared cookie jar and never checked cookies, comment said nothing else used the shared cache, this run's site cookies survived Reset)
- ⚔️ [Break] Reset clears older builds' recipe-site cookies/cache — the share extension ran imports in its own process (`ShareViewController.swift:130`), so its container's legacy jar/cache isn't cleared by the app — alternative: clear them on next extension launch — cost if wrong: stale cookies stay on disk in the extension container until reinstall (no new ones are written).
  → Owner: Accept / Reject / Later
- ⚔️ [Break] Reset clears "copies of website pictures" (policy §4.3) — Kingfisher's own disk cache of network pictures is not cleared by Reset (predates this change) — alternative: clear `ImageCache.default` in Reset — cost if wrong: policy overstates Reset.
  → Owner: Accept / Reject / Later
- ⚔️ [Tests] No test fails if the Reset call to `clearSharedSessionData()` is removed (`DataManagementSettingsView.swift:310`, view code) — accepted: needs a Reset use case extracted from the view first (Smells batch).
  → Owner: Accept / Reject / Later

## 2026-11-15 (bug pass: 🐞 nightly UI tests cancelled at 30 min — fixed: 75 min for nightly/dispatch; nightly in its own concurrency group so it never queues main pushes)
- ⚔️ [Break] "Publish coverage" runs on a cancelled run's incomplete xcresult and fails in `xccov` — noise on a run that already failed.
  → Later (guard with an `xccov view` probe if it recurs once runs finish).
- ⚔️ [Break] No per-step timeout: a hung UI test burns the full 75 min of runner time, nightly only.
  → Accept (pushes stay at 30).

## 2026-11-15 (item pass: Recipes — endless discovery — fixed: preview of six A–Z air-fryer samples (now own + favourites first), a chosen sort still counted as browsing, Cook it again re-dealt the Recently cooked row and preview, untested browse/search switch (now `RecipeBrowse`), reshuffle test passed without the shuffle, 2–7 recipe libraries ended the "endless" feed, a renamed recipe dealt stale (pool `==` ignores names), loose similarity words, fixtures that made everything similar)
- ⚔️ [Loop] Tiles only open the recipe; PRODUCT "Feel" wants one tap to plan or cook from the scroll. Serves the loop via the detail page.
  → Later (next slice: double-tap/plan action on tiles).
- ⚔️ [Measure] Nothing records that a cook came from a discovery tile, so "recipes opened from discovery that get cooked" can't be counted on device yet.
  → Later; owner's week of use until then.
- ⚔️ [Data] Fresh install: "New to you" is the whole library, so the deal is effectively random and the end of a ~70-chapter cycle alternates "Dinner ideas" / "New to you".
  → Accepted.
- ⚔️ [Structure] A new favourite inserts a source at the front, shifting the round robin; two chapters of one kind can then sit together once.
  → Accepted (cosmetic).
- ⚔️ [Operations] `chapters` grows for the session (lazy stacks keep views).
  → Accepted until a long-scroll memory check shows a problem.
- ⚔️ [Cost] `DiscoveryPool.make` runs on the main thread per Recipes appear / library change; `kitchenMatches` re-normalises the pantry per recipe (older code). Budget in `PerformanceBudgetTests.discoveryFeedBudget`.
  → Accepted; move off-main if the budget or a device trace says so. Budget failed in CI (0.96 s / 0.5 s): match words now built once per term (`KitchenRecipeMatcher.MatchTerm`), pager skips spent deck heads → green.

## 2026-11-15 (bug pass: 🐞 #16 froze on the badge reveal after a web import with sync just on — history read + recipe-copy merge moved off the main thread)
- ⚔️ [Assumption] The freeze was main-thread Core Data work after each iCloud import burst; not proven (no device log). Fix may be incomplete, follow-up = MirroredSnapshot loads off main, or skip reloads until the CloudKit import Event ends, if timing/MetricKit shows them (the other 7 list reloads and viewContext's automatic merges still run on main; slow steps now log under "Diagnostics").
- ⚔️ [Data] Optimistic locking (`NSMergePolicy.error`) did not fire in CI: an edit saved mid-merge to a field the merge writes (cook count, last cooked, favourite, rating, photos) can still be overwritten — only duplicated built-in recipes, only during the first sync, a few ms. Follow-up: write only differing merge fields after re-reading the row just before save. → Resolved 2026-11-15 (70dbaaf): premise wrong — that test's edit landed before the merge fired its faults; `anEditSavedAfterTheMergeReadTheRowsIsKept` edits after the read and locking fires.
  → Accepted for now (coordinator 2026-11-15); Inbox follow-up.
- ⚔️ [Would the tests notice] `mergeSyncedRecipeCopies`' own wrapper (sync guard, one pass at a time, background context) is untested: it needs a store mirrored to iCloud. Tests drive `mergeRecipeCopies` on a background context instead, including an edit saved mid-merge.
- ⚔️ [Time] `RecipeStore.load` now awaits the merge, so a recipe saved while a load runs can drop out of the list until the next load (the store keeps it). Not fixed: needs a "saved since this load's fetch" merge.

## 2026-11-15 (item pass: 🔴 photo files kept on other devices after a Reset elsewhere — fixed: legacy full-path photos read as unused; a sign-out purge looked like a Reset and could delete never-sent photos → now only files written before the last finished export − 10 min go)
- ⚔️ [Assumption] An iCloud sign-out purges the store file like a Reset; photos iCloud already had are cleared and come back as rows on sign-in — cost if wrong: they don't come back. Unverified on device.
  → Owner: device check (sync on, photo, wait a minute, sign out/in of iCloud, photo returns).
- ⚔️ [Gap] Photo rows that never exported survive a Reset elsewhere (row count > 0), so those files stay and may resurrect rows in iCloud later; a downloaded file stamped with a clock-ahead device's date can outlive the clear. Leftovers, not losses.
  → Accepted.
- ⚔️ [Cost] Each synced load does one extra whole-recipe fetch for references (the shared fetch swallows errors).
  → Accepted; revisit if PerformanceBudgetTests or 300+ libraries show it.

## 2026-11-15 (item pass: 🔴 history purged while sync is off — fixed: first cut counted a week of syncing launches, but an attached mirror may not export (signed out, iCloud full, offline); now purges only before the start of the last finished, successful CloudKit export)
- ⚔️ [Assumption] Purging history before the last export's start may also remove CloudKit's own checkpoint transaction; if the mirror treats that as an expired token it resets and re-sends survivors, so deletes made since could come back — same risk as Apple's 7-day sample purge while idle; unverifiable in unit CI — cost if wrong: off-period deletes undone.
  → Owner: device check (sync off, delete a recipe, wait >7 days or fake clock, sync on, confirm it stays deleted elsewhere).
- ⚔️ [Assumption] One `.export` success event covers all history before its start; if a large backlog is split across events, the first success moves the mark early — cost if wrong: part of a bulk off-period delete lost.
  → Owner: same device check with many deletes.
- ⚔️ [Tests] The `eventChangedNotification` wiring in `RecipeFinderApp.recordICloudExports` has no test (needs CloudKit); the rule and mark helpers do.
  → Accepted.

## 2026-11-14 (item pass: 🔴 photo removals while sync is off — rows now deleted locally so CloudKit sends the delete on re-attach)
- ⚔️ [Time] A removal made with sync off reaches iCloud only if store history survives until sync is back on — `RecipeFinderApp.swift:37-42` purges history older than 7 days at every launch, sync on or off — fix lands with the Inbox 🔴 "store history purged while off" — cost if wrong: after > 7 days off the photo row stays in iCloud forever (as before this fix). Both reviewers raised it.
  → Owner:
- ⚔️ [Tests] Nothing checks CloudKit actually exports a delete made while the store was opened without the mirror (unit CI has no iCloud) — device check: sync off, remove a photo, sync on, confirm it's gone on the other device — cost if wrong: the fix is a no-op.
  → Owner:

## 2026-11-14 (item pass: Data safety 2/4 slice 4b-2b — fixed: two devices folding the same item at once each wrote their own fold of the kept row and deleted their other copy, so the last write lost the other device's quantity/stores; now a copy is deleted only once the stored kept row already holds it)
- ⚔️ [Data] A rename (or tick) on a copy another device is folding away at that moment is lost — the kept row is re-checked by key next load, but a concurrent rename races the delete — cost if wrong: one list line vanishes.
- ⚔️ [Data] Inventory, meal plans, collections not folded (expiry reminders keyed by id; slot day differs by time zone; same names allowed) — later slice if duplicates show up.
- ⚔️ [Data] Same-name copies made by backup restore or renaming show until the next load; with sync off they're never folded.
- ⚔️ [Time] A fold arriving from a remote change shifts list indices under index-based APIs (`toggleItem(at:)`), as remote deletes already do.
- ⚔️ [Platform] Changing the `canonicalUnit` synonym table between versions makes two builds group copies differently.
- ⚔️ [Tests] `aSaveAfterTheFoldDoesNotBringTheOtherRowBack` would pass with a pre-fold `lastKnown`; kept-copy add + fold in one load is unpinned.

## 2026-11-14 (item pass: Data safety 2/4 slice 4b-2a — fixed: pruning inferred deletes from a library diff, so a failed fetch then one save, or a stale load overwriting a newer one, would delete every synced photo in iCloud; now removed only where an edit/delete happens on this device)
- ⚔️ [Break] Copy merge keeps one hero — `RecipeCopyMerge.merging` (SyncMerge.swift:110) unions `photoNames` but keeps only the kept copy's `imageName`, so a custom hero on the losing copy leaves the recipe (pre-existing) — alternative: move the losing hero into `photoNames` — cost if we're wrong: a photo only one device had disappears from that recipe.
  → Owner:
- ⚔️ [Break] Orphan photo rows are never collected — a delete whose pass never ran (app killed, sync off at the time) leaves its row in iCloud forever (bytes only; never shown, download needs a referencing recipe) — alternative: a sweep of rows no recipe references, run only after a full import is known complete — cost if we're wrong: iCloud quota slowly used by dead photos.
  → Owner:

## 2026-11-14 · Data safety 2/4 slice 3b-1 (reload on iCloud changes) — fixed: a list cleared on another device was re-added from the kept copy on reload (empty-store refill now only on the first load of a session); recipes reloaded via `refresh()` skipped dedupe (now `load()`); captured-var mutation in a test closure. Noted, not fixed:
- **Cleared elsewhere while this app was closed** still comes back at launch (empty store at launch = recovery/unfinished import is the safer guess). Needs a store-level "erased" marker — slice 4 (dedupe) or Data safety 4/4.
- **`ProfileManager.loadProfile` on an emptied store** saves a fresh profile and syncs it back; clears the cached photo on each reload (re-read lazily).
- **No test for CloudKit bookkeeping transactions** (author set, only NSCK* entities): can't be produced in a unit test; the app-entity filter is the guard.
- **Reload list in `RecipeFinderApp.reloadOnICloudChanges` untested** (thin glue): a manager left out won't refresh until relaunch.
- **History read on the main thread, never purged** — fine at current sizes; purge with the sync toggle slice.

## 2026-11-14 · Data safety 2/4 slice 3b-2a (merge same-id recipe copies) — fixed: edits/deletes hit one arbitrary copy before the merge (now every row with the id); merge faulted the whole library on main every load (now only ids the fetch held twice, batch `recordIDs(for:)`). Noted, not fixed:
- **Unuploaded copies wait** for the next import or launch (an export finishing changes only CloudKit bookkeeping, so no reload). Could listen to `eventChangedNotification` — later slice.
- **3+ devices with partial views** can both merge into the same kept copy at once; CloudKit keeps the last write, so one device's cook marks can be lost.
- **`populate` round-trip** turns a nil `imageName` into "" and writes back `mapToRecipeModel`'s defaults for missing fields on the kept copy.
- **`mergeSyncedRecipeCopies` untested** beyond its sync-off guard: CloudKit record ids can't be produced in a unit test; the pure plan is tested.
- **Record names assumed stable** across a zone reset / account change — not checked.

## 2026-11-14 · Data safety 2/4 slice 3b-2b (opt-in sync switch) — fixed: Reset after sync was turned off warned "this device only" though CloudKit would send its deletes once sync is back on (now an "ever synced" flag, kept through Reset); policy claimed recipe photos sync (they don't yet) and §3.1/§9.1 ignored iCloud copies; Reset could lose the sync choice if killed mid-way (now `clearAll(keeping:)`). Noted, not fixed:
- **Launch wiring untested**: nothing fails if `applyAtLaunch` moves after the database opens or the switch writes `key` instead of `wantedKey`; both are one-liners in `App.init` / `ICloudSyncSection`.
- **Changes made while sync was off** (incl. "kept copy wins" deletes) will be sent to iCloud when it's turned back on; the off→on copy doesn't say so.
- **No live sync status** (syncing / iCloud full) — needs `eventChangedNotification`; later slice. History purge also still pending (slice 4).

## 2026-11-14 · Data safety 2/4 slice 4a (store-history purge) — fixed: comment claimed the tracking checkpoint is never purged (it can be after ≥7 idle days), purge test passed via the expired-token branch whatever the author filter did (split into a kept-checkpoint test + an expired-checkpoint test). Noted, not fixed:
- After ≥7 idle days with sync on, the first launch reloads every list once (expired checkpoint).
- Sync on but history not uploaded within 7 days (offline, iCloud full, off→on, clock jump) relies on CloudKit's expired-history recovery (full re-sync) — Apple's sample does the same; untestable in CI.
- Launch wiring (`purgeOldStoreHistory` call, order vs tracking) untested; purge also runs in the unit-test host.

## 2026-11-14 · Data safety 2/4 slice 4b-1 (recipe photo sync) — fixed: `recipes = recipes` self-assignment (compile error); every stored photo was written to disk, so a removed photo came back on every pass (now only photos a recipe here shows); a hero saved mid-pass could be overwritten by the older iCloud copy (re-checked just before writing); Reset deleted recipes before photo rows (now photos first); 20 MB cap untested (test). Noted, not fixed:
- Newer-wins compares this device's file dates with other devices' clocks: a row dated in the future (clock set ahead) beats later local edits of that photo. Rejected for now: content hash + per-device "last synced" record (bigger); revisit if seen.
- Removed photos/recipes keep their rows in iCloud (storage, privacy) and duplicate rows for one path aren't merged → 4b-2 pruning. Reset racing an in-flight pass can re-add rows (unreferenced, never written to disk; 4b-2 prunes them). Reset leaves `RecipeImages/` files (pre-existing).
- A received photo shows once its view redraws (library re-published; SwiftUI may skip an unchanged `RecipeImageView` until it reappears).
- Wiring (`syncPhotosWithICloud` after load/save, sync-on `mirrorRecipePhotos`) untested — CloudKit can't run in unit tests. Test photos are tiny, so external (CKAsset) storage isn't exercised.
- TestFlight uses the Production CloudKit environment: `CD_RecipePhotoEntity` (and the v16 record types) need the schema deployed there before testers' sync works — owner step.

## 2026-11-14 · Data safety 2/4 slice 4b-2c (erased elsewhere while closed) — fixed: `iCloudRules` read a main-actor property from a nonisolated closure (now `@MainActor`); added a test that reopening the same file keeps its name (the premise). Noted, not fixed:
- **Same-file purges are followed at launch**: iCloud sign-out/account change, deleting the app's iCloud data, or a CloudKit zone reset empty the same file; if that lands before `load()`, the kept copy becomes `[]` and offline edits that never uploaded are lost (mid-session purges were already followed). Could keep the old copy one extra launch.
- **Device restore / new phone** copies the store file and UserDefaults together; a CloudKit reset purging the restored store before first load is followed instead of refilled. Speculative.

## 2026-11-14 · 🐞 Reset leaves photo files + recent searches — fixed: photo folder was deleted even when erasing recipes failed (now only after `deleteAllRecipes()` returns true); renaming the searches key would have dropped every cook's recent searches (kept the global key, Reset clears it). Noted, not fixed:
- **In-flight writers**: a web-picture download (`imageLocalization`) or photo-sync pass running at Reset can recreate `RecipeImages/` and write an orphan file (or, narrowly, re-save one photo row) after the delete. Fix: cancel/await both tasks before deleting.
- **No test drives `resetToDefault`** (private view code): removing the photo-delete call fails no test. Fix with a testable Reset use case when Reset is next touched.
- **Failed photo delete is only logged**; Reset still shows success. Main-thread delete may stall on a huge library.
- **Other devices keep their files** after a Reset that erased every device (photo sync never deletes files) — still in Inbox.
- `attemptedPictures` isn't cleared: a re-import of the same recipe in the same launch gets no offline picture copy until relaunch.

## 2026-11-13 · Data safety 1/4 slice 3c (meal plans → MealPlanEntity) — fixed: Reset left weekly reminders firing (now cancelled); added sub-second relaunch test. Noted, not fixed:
- **Reset wiring untested:** reverting the view to `.reload()` would bring plans back (rows outlive `clearAll`); a
  `DataResetter` seam the view calls would make it testable — same gap for collections/cook dates.
- **Shared `viewContext`** save/rollback (same as 3a/3b).
- **Recurring copies grow forever** (`clearOldMealPlans` keeps every recurring copy); each save now diffs all rows.
  Pre-existing; cap/purge later.
- **Rows missing id/recipeId/date are skipped silently** — safe while the kept copy exists (it replaces them); log
  or count them before the blob is dropped.

## 2026-11-13 · Data safety 1/4 slice 3d (shopping list + grocery stores → Core Data) — fixed: an unreadable stores blob left the store list empty (now rebuilt from item tags, test added); item rows get a name tie-breaker. Noted, not fixed:
- **Reset wiring untested** (same as 3c): reverting the view to `.reload()` would bring rows back.
- **Rows can come back** if the app is killed between `LocalStore.clearAll()` and `removeAllShoppingData()`, or after
  Reset on an older blob-only build then upgrading (unmarked key + no blob keeps rows) — `MirroredSnapshot` rule.
- **Store rename = delete + insert** with a fresh UUID (stores match by name); sync (2/4) must dedupe by name.
- **Shared `viewContext`** save/rollback and whole-list rewrite per edit (same as 3a–3c).

## 2026-11-13 · Data safety 1/4 slice 3e (kitchen items + inventory → Core Data) — fixed: Reset only `reload()`ed (would have kept the whole kitchen once in Core Data; now `removeAllKitchenData()` + cancels expiry reminders); an old item blob without `dateAdded` decoded a new `Date()` each launch → rows rewritten every launch (now a fixed fallback, test added). Noted, not fixed:
- **Reset wiring + expiry-reminder cancel untested** (same as 3c/3d): `DataManagementSettingsView` and `NotificationManager.shared` have no seam; a later `ResetService` item should own this.
- **Duplicate-id cleanup** keeps the first row in sort order (a nameless sync duplicate may win and be overwritten) — no data lost, same as 3d.
- **Shared `viewContext`** save/rollback and whole-list rewrite per edit (same as 3a–3d).

## 2026-11-13 · Data safety 1/4 slice 3f (badges → EarnedBadgeEntity) — fixed: a corrupt badges blob dropped the old shown list (celebration could pop again; now unioned in on load); a single quiet unlock never saved its shown flag (pre-existing; now marked before the unlock's save); relaunch tests now share one store; Reset drops queued celebrations (test). Noted, not fixed:
- **Downgrade + Reset on an older build, then re-upgrade** brings old badge rows back (no kept copy, flag unset) — `MirroredSnapshot` rule, same as 3d.
- **Unreadable store on a fresh install**: badges earned that launch stay in memory only (same as siblings).
- **Shared `viewContext`** save/rollback; rollback path untested (same as 3a–3e).
- **Backups don't carry shown-celebration ids** (pre-existing); **unknown badge ids** keep only id + date (title/icon rebuilt bare; UI lists `BadgeType.allCases` only).
- **Backup badge with `isUnlocked: false`** now loads as earned (presence already decided unlock checks).
- **A non-silent unlock writes the store twice** (unlock, then shown) — fine at ~30 rows.

## 2026-11-13 · Data safety 1/4 slice 3g (profile → ProfileEntity) — fixed: Me's `onChange(of: profileImage)` saved back the photo it had just loaded on every visit (pre-existing re-encode; would now rewrite the external Core Data file + kept copy each time) — the manager now keeps the decoded image and ignores saving that same image (test). Noted, not fixed:
- **Photo stored full size** (pre-existing: 12–48 MP camera JPEG, now held in memory and compared at launch) — downscale to ~512 px on save; a polish item, changes what's stored.
- **Unreadable store on a fresh install / after Reset**: profile edits stay in memory that launch, success haptic still plays (same as siblings; `MirroredSnapshot.save` doesn't report).
- **Sync (2/4)**: the store keeps one row and deletes other-uuid rows, so two devices would delete each other's profile — 2/4 must merge/pick by date.
- **Tests**: the external-storage path (>100 KB) isn't exercised by the in-memory store; `setIfChanged` and `unlockWelcomeBadge` (shared init only) are unpinned; Reset wiring in `DataManagementSettingsView` untested (same as 3c–3f, `ResetService` item).
- **Reset kill window** between `clearAll()` and `removeProfile()` can bring the name back (same rule as 3d; running the `remove*()` calls before `clearAll()` would close it for every manager).

## 2026-11-13 · Data safety 2/4 slice 1 (sync-safe `MirroredSnapshot`) — fixed: a save brought back rows deleted on another device (unchanged-here + gone-from-store now dropped); an empty shared store overwrote the kept copy (now refilled from it). Noted, not fixed:
- **Kept-copy-ahead / first move is add-only and the copy wins on shared ids**: rows deleted meanwhile come back and other devices' newer edits to those ids roll back. Accepted (nothing lost); a persisted base would fix it.
- **Empty-store refill** also undoes a real "everything deleted on another device" for this device's rows.
- **Sync on→off** must stop CloudKit mirroring before the 1/4 rule replaces the store (slice 3).
- **Reset while syncing** wipes every device; rows not yet imported come back (slice 3 UI must say so).
- **`copyIn` re-read during an import** can fail the check → session runs on the kept copy (then add-only next launch).
- **Merged rows not shown until next `load()`**; `syncActive` is per-load — slice 2 reloads on remote change.
- **Duplicate ids**: first wins, no log.

## 2026-11-13 · Data safety 2/4 slice 2a (sync rules wired into managers) — fixed: the badge store lists rows by id, so adding the kept copy always failed its re-read check and badges stayed on the kept copy for good (now checked by id, any order; test). Noted, not fixed:
- **Duplicates by meaning**: "Eggs" added to the kitchen/shopping list, or the same meal slot filled, on two devices gets two UUIDs → both kept; managers' name/slot dedupe only runs on add (slice 4 dedupe should cover these too).
- **Store names as ids**: "Tesco" vs "tesco" from two devices both survive; a rename on one device leaves the other's item tags pointing at the old name.
- **Category fix-up on load** (Kitchen/Shopping) saves straight away — two app versions normalising differently would flip values between devices.
- **Tests** don't run a manager save under sync (`applyEdits` covered only in `SyncMergeTests`) and don't distinguish a wrong id closure.

## 2026-11-13 · Data safety 2/4 slice 2b (one shared profile) — fixed: filling a missing photo from another device's row brought a removed photo back (fill dropped); added a test that fails if the constant sync id is replaced by the uuid
- **Stale in-memory profile** until remote-change reload (slice 3): a device still holding its own profile overwrites the iCloud one on its next save — last writer wins.
- **"Oldest" uses each device's clock** (`createdDate`): a wrong clock picks the wrong profile, but every device picks the same one.
- **New device names itself before iCloud's profile arrives** → that edit loses to the older named profile.
- **Reset under sync** can be undone by an offline device pushing its old named row (named beats empty); slice 3's Reset copy must warn, and Reset should turn sync rules into "erase everywhere".
- **Every write deletes other rows**: a concurrent edit on another device can be dropped by CloudKit's merge.

## 2026-11-13 · Data safety 2/4 slice 3a (CloudKit container, sync off) — fixed: history tracking can't be dropped without the store going read-only → root CLAUDE.md hard constraint; relationship rules of the model check now tested. Noted, not fixed:
- **CI builds unsigned** (`CODE_SIGNING_ALLOWED=NO`): a bad iCloud profile only shows in the TestFlight run after merge — check it.
- **No test drives `retryWithoutSync` or `.shared`'s launch flag**: a CloudKit load failure can't be produced reliably in an unsigned simulator; the fallback mirrors `attemptStoreRecovery`'s reload pattern.
- **The model check is ours, not Apple's**: a rule it misses fails at load with sync on → falls back to local (no data moved).
- **History never purged** while sync is off, and turning history on isn't a model change so no `StoreBackup` copy is taken — small (one transaction per save); purge in a later slice.
- **After a fallback `SyncPreference` still says on** — slice 3b's status must show "off on this device".

## 2026-11-12 (item pass: Today+ 2/3 slice 1 — fixed: two ranking tests passed with their rule deleted, item skipped once rows were full though a shown recipe used it, device-locale list/weekday mixed into English copy, seeded UI-test items kept stale dates on a reused simulator)
- ⚔️ [Matching] "Use it up" reuses the shared-word matcher, so expiring "Milk" can pair with "coconut milk" and "Chicken stock" with "chicken breast" — exact-term match for expiring items if owner sees odd pairs — cost if wrong: a pairing that doesn't use the item.
  → Owner:
- ⚔️ [Smell] `UseSoon` re-derives days-to-expiry (with injected now/calendar) beside `KitchenInventoryModel.daysUntilExpiry` (Date()/Calendar.current), and the Plan tab's `PantryExpirySuggestions` is a second expiry→recipe matcher — consolidate in a Smell pass — cost if wrong: Kitchen and Today disagree on "soon".
  → Owner:
- ⚔️ [Time] Today left open past midnight keeps "tomorrow" until the next refresh (same as the Tonight line) — refresh on `.NSCalendarDayChanged` — cost if wrong: one stale day word.
  → Owner:

## 2026-11-12 (item pass: Today+ 2/3 slice 2 — fixed: recurring dinners showed as empty and could be planned over, overnight-backgrounded "Plan it" dated today, "Plan it" could replace an existing dinner, date circles clipped at AX sizes; review: Voice Control label, picker empty-state action)
- ⚔️ [Flow] Tapping a planned day opens Plan on today, not the tapped day (no date deep link) — pass the date through `onOpen(.plan)` — cost if wrong: tap Saturday, land on Thursday.
  → Owner:
- ⚔️ [Structure] Two week-strip looks: Plan's per-meal coloured dots on calendar weeks vs Today's single dot on a rolling 7 days — shared `DayCell` in a Smell pass — cost if wrong: "planned" reads two ways.
  → Owner:
- ⚔️ [Tests] Which day "Plan it" uses and the Tonight exclusions are wired in TodayView (only the nightly UI test covers the view) — view-model seam — cost if wrong: plans tonight instead of tomorrow, caught late.
  → Owner:

## 2026-11-12 (item pass: Today+ 3/3 — fixed: UI test missing @MainActor (Swift 6 compile), "cooks this week" stale after a new week (streak only recomputed on a cook — now reloaded on appear/return), weekly pick repeated on shelves, Signature Dish copy implied any cook counts, duplicated cooking-badge set)
- ⚔️ [Flow] When the weekly pick is tonight's card, "Try something new" hides rather than showing the next-lowest pick — cost if wrong: one less suggestion that evening.
  → Owner:
- ⚔️ [Time] Today left open across Sunday→Monday keeps last week's streak/pick until the next appear/return (same as other Today cards) — cost if wrong: stale numbers until reopened.
  → Owner:

## 2026-11-12 (item pass: Badges 1/2 slice 1 — fixed: ProfileSheetTests still used the removed `.badge` case (compile), pager ids not unique per page, ring metrics stale until Me reappears, Domain→View `tab` dependency, button copy promised "Add a recipe"/"Plan a meal" but only switches tab, catch-all group, VoiceOver "slash", header trait, 44pt close, year on dates, same-date tie-break test, UI test asserts pager closed; screenshots: clipped/grey locked titles)
- ⚔️ [Flow] "Go to Recipes and tap +" switches tab but doesn't open the "+" sheet — post a notification ContentView turns into `showAddRecipe` — cost if wrong: one extra tap.
  → Owner:
- ⚔️ [Operations] VoiceOver pages the badge pager with a three-finger swipe only; "3 of 24" is the one cue — add next/previous accessibility actions — cost if wrong: VoiceOver users see one card.
  → Owner:
- ⚔️ [Structure] Pager medallion + progress ring hand-build `ZStack { Circle(); Image }` with literal 156/170 sizes instead of extending `IconBadge` — fold into slice 2's reveal medallion — cost if wrong: drift between shelf, pager and reveal.
  → Owner:
- ⚔️ [Structure] `.onReceive(NotificationCenter.publisher)` in ContentView is Combine (repo bans it); `.openToday` copied the existing four lines — move all five to an async `notifications(named:)` loop in a Smell pass.
  → Owner:

## 2026-11-12 (item pass: Badges 1/2 slice 2 — fixed: quick flick didn't close the full-screen reveal (UI audit helper swiped the label), confetti haptic on top of the reveal pattern, fixed-28pt title ignored Dynamic Type, no scroll at AX sizes, 8 s auto-close under VoiceOver, a CMMotionManager per view init, shine sweep animated gradient points (may not interpolate) → offset, resting shine washed the pager icon in the Simulator)
- ⚔️ [Flow] The reveal waits only for Made it and "+"; it can try to present over another cover (cooking mode when the cook was already recorded today, onboarding) and stall the queue with `pendingCelebration` set — one "is anything else up?" signal or present from the top-most screen — cost if wrong: badges silently stop revealing until relaunch.
  → Owner:
- ⚔️ [Tests] View wiring is untested: deleting `guard !closing`, hard-coding full motion, or passing `isAnotherSheetUp: false` stays green (pure rules are tested, not their use) — cost if wrong: a double dismiss swallows the next badge.
  → Owner:
- ⚔️ [Structure] Chesterton: a `.large` sheet would give native flick-to-close for free; chose a cover for the "full-screen" spec + custom drag — cost if wrong: a gesture to maintain.
  → Owner:
- ⚔️ [Time] Tilt baseline is set on the first reading and never reset (posture change / return from background leaves the shine at an edge until the pager reopens); "settle toward the Me tab" drops straight down (no tab bar under a cover, none on iPad).
  → Owner:
- ⚔️ [Data] Placeholder art (Pictures 1/4 slice 2) is keyword-based: "Radish Cake" [Starter] gets cake art, "Scallion Pancakes" [Side] breakfast art, "Pad See Ew"/"Char Kway Teow" fall back to fork & knife; soup glyph (`humidity`) is weak; hashed colours can coincide with a cuisine colour — cost if wrong: a few odd-looking tiles until Pictures 3/4 gives bundled recipes real pictures.
  → Owner:

## 2026-11-12 (item pass: Data safety 1/4 slice 1 — fixed: store copies went into the iCloud/device backup (now excluded), pruned after copying (now makes room first, so a new copy is never pruned and the upgrade keeps disk headroom), prune failure logged as backup failure, bare `try?` cleanup, tests defaulting to the real Application Support)
- ⚔️ [Structure] The file copy is consistent only while nothing else opens the store at launch (share extension doesn't today); if a widget/extension ever shares it, switch to `replacePersistentStore` (SQLite backup API).
  → Owner:
- ⚔️ [Flow] Nothing restores from `StoreBackups/` yet (no user/support path), and `.corrupt-*` files from recovery are never pruned — a "Restore earlier copy" in Settings → Data could come with Data safety 3/4.
  → Owner:
- ⚔️ [Time] Before first unlock, store reads fail and `attemptStoreRecovery` moves a healthy store aside (pre-existing, not this change) — check `isProtectedDataAvailable` before "recovering".
  → Owner:
- ⚔️ [Tests] `olderModel()` pins the model before current (now `RecipeModel 15.mom`); bump it whenever `.xccurrentversion` moves.
  → Owner:

## 2026-11-12 (item pass: Data safety 1/4 slice 2 — fixed: Swift `Int` stored as Integer 32, servings default 1 vs struct 4, four entities without an `id` (CloudKit duplicates can't be deduped), test only checked entities exist (now every attribute + type), Recipe v15==v16 not pinned)
- ⚔️ [Docs] Root CLAUDE.md's `valueForUndefinedKey: isSampleRecipe` hint now names 16, but reverting to 15 would show as missing `*Entity` errors instead — reword when slice 3 starts reading the entities.
  → Owner:
- ⚔️ [Format] `recipeIDs` / `stores` are plain Binary; slice 3 must JSON-encode them (`docs/DECISIONS.md`).
  → Owner:

## 2026-11-12 (item pass: Data safety 1/4 slice 3a cook dates — fixed: kept blob was a dead fallback (now kept current + refills an empty store), failed save/read lost cooks (now unmarks → next launch moves them), failed Reset delete resurrected history (now a pending wipe retried each launch), relaunch test reused one container)
- ⚔️ [Data] `merge` (backup restore) uses set semantics, so two cooks at the same instant in a backup collapse to one, unlike the migration's multiset rule. Pre-existing; practically unreachable (`Date()` per cook).
  → Owner:
- ⚔️ [Data] `CoreDataCookDateStore.save` rolls back the shared `viewContext` on failure, which would drop any other unsaved change there; other writers save immediately, so none today. Revisit when more managers write to viewContext (slice 3b+).
  → Owner:
- ⚔️ [Tests] Reset wiring (`resetToDefault` → `removeAllCookDates`) is untested; the view calls `.shared` directly (pre-existing).
  → Owner:

## 2026-11-12 · Data safety 1/4 slice 3b (collections → CollectionEntity) — noted, not fixed
- **Sync (2/4) breaks "the kept blob is never behind the store".** Once CloudKit adds rows this device's blob lacks,
  `MirroredSnapshot`'s blob-wins rule (differs → replace, fallback → replace next launch) would delete synced rows
  everywhere. 2/4 must drop the blob path (or make it add-only) before turning sync on. Cook dates' refill has a milder
  version (re-adds dates deleted elsewhere).
- **Shared `viewContext`:** store saves also commit/rollback other pending viewContext edits (same as CookDateStore).
  A private context per store would isolate it — revisit with 2/4.
- **Integrity check re-reads the same context**, so it checks memory, not disk (same as LegacyBlobMigration).
- **Whole-list rewrite per edit** on the main thread; fine for realistic sizes (rows untouched unless changed). A
  crafted backup with repeated ids makes rows churn but stay consistent (pre-existing BackupMerge gap).
- **Two migration helpers** (`LegacyBlobMigration` add-only for cook dates, `MirroredSnapshot` whole-list); flags now
  in separate namespaces. Port cook dates only if it shrinks code.

## 2026-11-11 (item pass: Today+ 1/3 slice 1 — fixed: ambiguous `quickMinutes`, shuffled pick repeated on shelves, shuffle index drifting on refresh, night-time copy, unused eat-time storage)
- ⚔️ [Time] The Tonight line is computed when Today re-renders — TodayView.swift `content(_:)` reads `Self.now()` in body; left open, "Start by 5:40" still shows at 5:55 — `TimelineView(.everyMinute)` around the line — cost if wrong: stale advice until the next state change.
  → Owner:
- ⚔️ [Break] "Cook this" + "Shuffle" share one HStack (TodaySections.swift hero card) with no large-text fallback — `ViewThatFits` → VStack, plus an AX-size screenshot — cost if wrong: squeezed buttons at AX3–AX5 on SE width.
  → Owner:
- ⚔️ [UX] "Quick tonight? 12 under 30 min" counts every quick recipe but Shuffle reaches 3 and the line isn't tappable — make it open a filtered list (Today+ later slice) — cost if wrong: a number that promises more than it shows.
  → Owner:

## 2026-11-11 (item pass: Today+ 1/3 slice 2 — fixed: eat-time picker vanished once the time passed / for untimed recipes and sat on lines it didn't change (now a separate "Dinner at" pill), late dinners lost their start line at 6pm, VoiceOver read the timing twice, three pills with no large-text fallback)
- ⚔️ [Tests] TodayView passing the stored `eatAt` into `TonightTiming.line` is only checked by the Screenshots UI test (not in push CI) — a view-model seam would let a unit test catch it — cost if wrong: picked time silently ignored until the nightly run.
  → Owner:
- ⚔️ [Locale] "8 pm" / "Start by 5:40" are spoken 12-hour by spec; 24-hour locales still see them — `Date.FormatStyle` if owner wants locale times — cost if wrong: reads oddly outside UK/US.
  → Owner:
