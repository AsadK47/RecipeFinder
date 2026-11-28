# Agent working lessons

Hard-won lessons from AI-assisted sessions on this repo. Keep short; promote a
recurring one into `CLAUDE.md` (a gate) or the `improve-loop` workflow (a step). New entries end `Check:` or
`No check:` (CLAUDE.md Harness decay); entries whose check has landed move to `docs/archive/` monthly.

## Process
1. **Verify a finding's premise before editing — in *both* directions.** Audits/reviews
   are frequently overstated (e.g. "scaling wipes ingredient check-offs" was false — a
   count-guard prevented it; and 2026-10-01: "5 badges have no unlock trigger" was false —
   all fire at real call sites, ImportView/MealPlanningManager/ShoppingListManager/
   CookingModeView). The status source can *also* be wrong the other way: there the
   ROADMAP table (now `docs/archive/`) was right and the fresh audit wrong. Trust neither marker — read the code.
   The `improve-loop` workflow bakes this in as an adversarial verify step.
2. **Before removing a string/symbol, grep for dependents case-INSENSITIVELY.** A
   case-sensitive grep for "See recipe" missed a test asserting `"See Recipe"` →
   broke the suite. Check tests + code for exact and near-exact matches first.
3. **Fix one thing → verify with a *separate* agent → human commits.** WIP=1. The
   agent that wrote the code shouldn't be the only one that blesses it.
4. **Test cadence:** build + the affected suite per slice; run the full `RunAllTests`
   once before a commit — not per iteration. (Also in `CLAUDE.md`.)

## Judgement
5. **Proportionate fixes.** Prefer a small honest change over a big flow rewrite
   (e.g. imports: stop fabricating placeholders + warn, rather than re-route the
   whole pipeline through the wizard).
6. **Colour is not a readability tool over themed gradients.** Accent text on the
   teal/blue gradient is unreadable on some themes. Use the consistent type scale
   (size/weight + primary colour), not one-off colour pops, for legible values.
7. **Don't over-ask, don't over-talk.** Lead with the result; ask only when the
   answer changes what you build. (Concise-answers gate is in `CLAUDE.md`.)

8. **Green tests ≠ right.** 2026-11-10: the Me gear (a `NavigationLink` wrapping `CircleButton`'s own `Button`)
   built and unit-tested green but never pushed Settings — only the screenshot UI test caught it. Run Screenshots
   for UI work and *look at* the images (BACKLOG step 6b); prefer a plain `Button` + `navigationDestination`.
9. **Argue with yourself, on a schedule.** The daily challenger (`docs/CHALLENGES.md`) and the per-item challenge pass exists because the agent that
   builds also tests and reviews — it can be consistently wrong. Treat a challenge as a real question, not noise.

14. **One agent's confident report is not evidence** (owner, 2026-11-14 — earlier agents' confident nonsense nearly
   boxed the owner into risky positions). Audits, reviews and "facts" about legal, privacy, money, names, accounts or
   deleting anything are verified against the primary source (code, Apple/legal docs, the live site) and agreed by at
   least two independent reviewers before acting; when they disagree, the owner decides. State uncertainty plainly;
   never present a guess as a fact.

## Repo gotchas (see also memory)
- StoreKit scheme `identifier` = `../../RecipeFinder.storekit` (anchored at the
  `xcshareddata` dir, NOT SRCROOT). Cost several wrong guesses — see memory.
- New Swift files via `XcodeWrite`; new tests via Swift Testing (no new XCTest).
10. **Query once, act on the coordinate.** 2026-11-12: `dismissBadgeSheet` waited for the badge sheet, then `swipeDown()` re-queried it after it had closed → Screenshots red on an unrelated branch. In UI-test helpers for transient UI, drag a window coordinate instead of re-querying the element.
11. **Anchored text edits hit the first match.** 2026-11-12: a scripted `replace(..., 1)` on `func replaceCollections(with` landed a helper inside the protocol (same signature prefix) → build red. Anchor on a line unique to the target (e.g. the `{`-ending implementation line) and assert `count == 1`.
12. **No key paths inside `#expect`.** 2026-11-13: `#expect(rows.allSatisfy(\.flag))` failed to compile ("call can throw" in the macro expansion) → write `allSatisfy { $0.flag }`.
13. **Extend a passing UI flow before adding a new test.** 2026-11-14: a new standalone screenshot test (`testCaptureDataManagementSync`, sorts early) never reached Settings ("Me gear should open Settings") → 2 Screenshots cycles. Capturing after the passing import-summary test on the same screen worked first time.
14. **Re-check old expectations after a review fix.** 2026-11-14: tests expected the kept copy deleted (`== nil`); a later write-back made it `[]` → 1 CI cycle. Assert the outcome (`?.isEmpty ?? true`), not the storage shape.
15. **Pin test clocks mid-week.** 2026-11-15: `CookingStreakTests` used `Date()`; CI ran Sunday 01:00 so "3h ago" fell in last week → 1 CI cycle.
16. **Register every new Swift file.** 2026-11-15: `RecipeBrowse.swift` added after the first pbxproj pass → 1 CI cycle. Before pushing, check each new file in project.pbxproj with `grep -c <name> project.pbxproj`.
17. **Swift 6 traps without a compiler.** 2026-11-15 (discovery, 3 CI cycles): a lazy `filter` closure in a `mutating` func can't capture `self` (copy the sets first); every test touching a `@MainActor` type needs `@MainActor @Test`; a long `.map { RecipeModel(…) }` literal times out the type checker (build it in a loop). Grep new code for each before pushing.
18. **Never chain `git rebase` and `git push … HEAD:main`.** 2026-11-15: a rebase stopped on a conflict and the next command pushed the half-rebased HEAD to main. Push main only from a named, fully rebased branch after checking `git status`.
19. **Count pairs before pushing a hot loop.** 2026-11-15: discovery's perf budget failed in CI (debug build) — `ingredientMatches` rebuilt two word sets per recipe-ingredient × pantry pair (~250k). Precompute per term, then loop.
20. **`set -o pipefail` + a `grep` that may match nothing fails the step.** 2026-11-15 (CI lane): a diagnostic `ps | grep | awk` line killed a Build & Test run → 1 CI cycle. Add `|| true` to any best-effort pipeline in CI.
21. **Moving UI between files? Check `private`.** 2026-11-16: moved cuisine chips into `BasicInfoStepView` but `SuggestionChip` was `private` to NotesStepView.swift → 1 CI cycle. Grep `private struct`/`fileprivate` for every type the moved code uses.
22. **No `@AppStorage` at the tab root.** 2026-11-17: ContentView observing `groceries.mode` re-rendered every tab when the a11y audit changed text size → "Dynamic Type partially unsupported" on an unchanged row, 2 CI cycles. Write defaults from the root; observe them in the screen that shows them.
23. **`isHittable` is true at the first peeking pixel.** 2026-11-18: a screenshot loop swiped "until the card is hittable" and stopped with it under the tab bar → 1 Screenshots cycle. Scroll until the element's *last* part clears the tab bar's `frame.minY`.
24. **`#require`/`#expect` wrap their argument in a closure.** 2026-11-19: `try #require(board.start(…))` on a `var` struct didn't compile ("'$0' is immutable") → 1 CI cycle. Call the mutating method first, then expect its result.
25. **UI-test helpers that call `checkpoint` need `@MainActor`.** 2026-11-19: a private `finishCooking(_:)` helper without it didn't compile (actor-isolated call) → 1 CI cycle. Mark new XCUITest helpers `@MainActor` like the tests.
26. **Never `if let b = Binding($optional)` for a view that animates out.** 2026-11-19: the plan deck crashed on Close — the removal transition re-read the unwrapped binding after the state went nil → 1 Screenshots cycle. Use `Binding(get: { state ?? shown }, set: { if state != nil { state = $0 } })`.
27. **A UI test that plans meals runs late in a week full from earlier tests.** 2026-11-19: `testZZZPlanMyWeek` skipped on a Thursday (tonight..Saturday planned) → 1 Screenshots cycle. Superseded 2026-11-22: the button now looks 4 weeks ahead, so the test requires it on the first Plan screen and fails (never skips) when it's missing.
28. **Build expected time labels with `DurationFormatter.label(minutes:)`, never by hand.** 2026-11-20: a busy-night reason test expected "20 min"; the label is "20 minutes" → 1 CI cycle.
29. **Keep `cond ? method : nil` out of a big `@ViewBuilder`.** 2026-11-21: `onOpenKitchen: nudge.linksToKitchen ? openKitchen : nil` in `TodayView.content` → "failed to produce diagnostic" → 1 CI cycle. Pass the closure and let the child view decide.
30. **Put a defaulted test-helper parameter last and labelled; keep key-path closures out of `#expect`.** 2026-11-22: `infer(_ name: String = "x", _ ingredients:)` called as `infer([..])` → compile error, and `allSatisfy(\.x)` inside `#expect` → "call can throw" → 2 CI cycles.
31. **A closure kept in a `let` can't capture a non-escaping closure parameter.** 2026-11-22: `let key = { minuteOfDay($0) }` in `sortedOrderedMealTimes` → Swift 6 error → 1 CI cycle; read the values into a dictionary first.
32. **A test that uses `Date()` with `Calendar.current` must hold on every weekday and first weekday.** 2026-11-22: weekly dinner planned for "today" (a Sunday, US runner) stopped covering Mon–Sat after the Sunday-nudge fix → 1 CI cycle; pick a date the rule covers whatever today is.
33. **Branch pushes run unit tests only; UI tests need "Run workflow".** 2026-11-24: a red UI test pushed to `agent/search-field-a11y` sat behind a push run that skips the UI shards → ~10 min lost; for a UI red/green, dispatch `build.yml` on the branch (or Screenshots for screenshot tests). XCUITest still lists `.accessibilityHidden` SwiftUI text — it can't prove something is hidden from VoiceOver.
34. **Land a fix to a scheduled job before cleaning up what it produced.** 2026-11-25: tester issues #14–16 were deleted
   while the hourly feedback job still ran the old code; it re-filed them (#17–19) with tester text and a new artifact
   an hour later → a second clean-up. Fix first, confirm one run of the new code, then delete.
   No check: an ordering judgement across a live schedule.
35. **"Private" on a public repo means checked, not assumed.** 2026-11-23/25: the policy said screenshots were "kept
   privately", but artifacts on a public repo download for any GitHub user; issue edit history and title changes stay
   public after an edit (only deleting the issue removes them). Two reviewers checking text against code caught both.
   Check: queued — CI step that fails if a workflow uploads feedback artifacts or posts tester fields to issues.
36. **One checkout per agent.** 2026-11-25: a docs agent editing `/home/user/RecipeFinder` while another switched it to a
   feature branch nearly committed onto that branch. Give a second lane its own `git worktree`.
   Check: queued — lane start script creates a worktree per `agent/*` branch.
37. **CloudKit Production needs every record type to exist in Development first.** 2026-11-25: a type appears only once a
   row of it syncs (3 of 11 were missing until a photo, a shop and an inventory item were added); a new field can be
   added by hand (Console → Record Types → +, `CD_<name>`). Simulator iCloud sign-in fails on new iOS betas — use a device.
   No check: a manual Console step (docs/OPERATIONS.md).
38. **A bundled title is input to its tags.** 2026-11-25: dropping "Vegan" from "Apple Jalebi (Gluten-Free, Vegan)" lost its
   Vegan tag (`DietaryInference` trusts a title that says Vegan; "coconut milk" reads as milk) — read what the generator
   derives from a field before editing it. Check: `committedCatalogMatchesGenerator` (caught it, run 45715179594).
39. **The share extension compiles the import parser.** 2026-11-26: `Difficulty.swift` joined only the app target, and
   `RecipeParser+TextMetadata.swift` (also in `RecipeShareExtension`) couldn't find it — a type the parser calls joins both
   Sources phases. Check: Build & Test compiles the extension (caught it, run 45861210860).
40. **A step's note can put its word after the time.** 2026-11-28: the seconds-first timer checked stop words only
   between the two durations, so "Can be made 2 hours ahead." still took over (run 46117645596). Read the rest of the
   later duration's sentence too. Check: `CookingModeTimerTests.secondsFirstKept` ("ahead", "in advance").
41. **Diff a heuristic over the real corpus before landing.** 2026-11-28: the Baking Soda classifier fix passed its tests but
   moved 212 of 2,409 bundled ingredient names; only an old-vs-new run over the corpus plus a reviewer showed spring rolls →
   Bakery and cake tin → Canned (agent/baking-soda-category, red 46147651905, 46150310982 → green 46154576912). Check: queued — Kaizen (b).
42. **A test is not weakened to get green.** Agents edit tests or scoring to pass (METR 2025 reward-hacking report);
   deleting, disabling or `withKnownIssue`-wrapping a test needs the owner's OK in the Log line. Check: queued — Kaizen (g).
43. **Three fixes in one area means the spec is wrong.** ~25 `fix(plan)` commits on take-off/undo (22–27 Nov) and ~22 on the
   step-timer regex (26–28 Nov), each fix exposing the next case: stop, write the cases table and tests, then fix.
   Check: queued — Kaizen (c).
