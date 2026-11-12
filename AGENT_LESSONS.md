# Agent working lessons

Hard-won lessons from AI-assisted sessions on this repo. Keep short; promote a
recurring one into `CLAUDE.md` (a gate) or the `improve-loop` workflow (a step).

## Process
1. **Verify a finding's premise before editing — in *both* directions.** Audits/reviews
   are frequently overstated (e.g. "scaling wipes ingredient check-offs" was false — a
   count-guard prevented it; and 2026-10-01: "5 badges have no unlock trigger" was false —
   all fire at real call sites, ImportView/MealPlanningManager/ShoppingListManager/
   CookingModeView). The status source can *also* be wrong the other way: there the
   ROADMAP table was right and the fresh audit wrong. Trust neither marker — read the code.
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

## Repo gotchas (see also memory)
- StoreKit scheme `identifier` = `../../RecipeFinder.storekit` (anchored at the
  `xcshareddata` dir, NOT SRCROOT). Cost several wrong guesses — see memory.
- New Swift files via `XcodeWrite`; new tests via Swift Testing (no new XCTest).
10. **Query once, act on the coordinate.** 2026-11-12: `dismissBadgeSheet` waited for the badge sheet, then `swipeDown()` re-queried it after it had closed → Screenshots red on an unrelated branch. In UI-test helpers for transient UI, drag a window coordinate instead of re-querying the element.
11. **Anchored text edits hit the first match.** 2026-11-12: a scripted `replace(..., 1)` on `func replaceCollections(with` landed a helper inside the protocol (same signature prefix) → build red. Anchor on a line unique to the target (e.g. the `{`-ending implementation line) and assert `count == 1`.
