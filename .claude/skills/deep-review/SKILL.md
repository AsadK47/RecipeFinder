---
name: deep-review
description: >
  Rigorous, senior-grade code review of the current diff for a Swift 6 / SwiftUI
  iOS codebase. Combines Google eng-practices review standards, Swift 6 strict-
  concurrency rules, and this repo's CLAUDE.md gates. Multi-angle finder →
  recall-biased verify. Use when reviewing a commit, PR, branch, or working-tree
  changes and you want the highest-confidence catch of real defects, not style
  nits. Invoke as /deep-review [low|medium|high|max] [<target>].
---

# Deep Review

A code review held to an elite engineering bar. The purpose is not to find
fault — it is to **provably improve the code health of the system** while
catching every real defect a careful senior reviewer would catch in one sitting.

## Guiding principles (non-negotiable)

1. **Correctness outranks everything.** A real bug — a crash, data loss, data
   leak, race, wrong output on a reachable input — always outranks any number of
   style, naming, or structure findings. When the output cap forces a cut, cut
   cleanup before correctness.
2. **Every finding names a concrete failing input or scenario.** "This looks
   fragile" is not a finding. "With `currentUserId == nil`, `clearCurrentUserData`
   deletes the `no_user_`-prefixed keys of the signed-out scope" is. If you can't
   state the input/state → wrong-output, you don't have a finding.
3. **Read every line, then read the enclosing scope.** Bugs in unchanged lines of
   a touched function are in scope — the change re-exposes or fails to fix them.
   Never scan over a human-written block and assume it's fine.
4. **Improve code health, don't demand perfection.** Approve once the change
   definitely improves the system, even if imperfect. Distinguish "must fix"
   from "consider". There is no perfect code, only better code.
5. **Style is settled by the style guide, design by principle.** Whitespace/
   naming that the style guide doesn't cover is preference — flag as Nit at most.
   Design is weighed on engineering principle, not opinion; if the author shows
   two approaches are equally valid, defer to the author.
6. **Explain _why_, and credit good work.** Each finding states the underlying
   principle and the fix. Note genuinely good choices — review is mentoring.
7. **Escalate expert domains.** Security, privacy, cryptography, concurrency,
   accessibility, and internationalization deserve extra scrutiny; if a change
   turns on one and you're unsure, say so explicitly rather than wave it through.

## Phase 0 — Gather the diff

Run `git diff @{upstream}...HEAD`; fall back to `git diff main...HEAD` or
`git diff HEAD~1`. If there are uncommitted changes or the range is empty, also
run `git diff HEAD` and include the working tree — reviews often run pre-commit.
If a PR number, branch, or path is passed as an argument, review that instead.
Read the full enclosing file for each hunk. That diff is the review scope.

## Phase 1 — Review dimensions

Cover **all** of these. For each, ask "what input/state/timing makes this wrong?"

### Correctness (highest priority)
- Inverted/wrong conditions, off-by-one, wrong-variable copy-paste.
- `nil`/optional deref on a reachable path (error handler, cold cache, missing
  optional field); **falsy-zero / empty treated as missing**.
- Swallowed errors; dropped or narrowed validation vs. the code being replaced.
- Broken caller/callee contracts: new precondition, changed return shape, new
  thrown error, new ordering/timing dependency (Grep the symbol's call sites).
- **Force-unwrap (`!`) / force-`try` in shipping code** → Blocker unless
  provably safe (per CLAUDE.md: use `guard let`/`if let`/typed errors).

### Swift 6 strict concurrency (expert gate — scrutinize hard)
- **Data-race freedom**: shared mutable state must be actor- or `@MainActor`-
  isolated, or guarded by a lock behind `@unchecked Sendable`. A `nonisolated(unsafe)
  static var` mutable dictionary is a data race — flag it (CLAUDE.md: use `MemoCache`).
- **`Sendable`**: types crossing isolation boundaries (task/actor params &
  returns, stored closures) must be `Sendable`; classes need explicit conformance;
  `@Sendable` on escaping closures passed between tasks.
- **`@MainActor`**: UI-facing types / view models are `@MainActor`; `@Published`/
  `@Observable` mutated only on the main actor; no "publishing from background".
- **Bridging**: async work bridged via `Task`; `await` on actor-isolated members,
  never synchronous cross-actor access.
- **No Combine** — this repo uses async/await (CLAUDE.md). Flag new Combine.
- Recognize Swift 6.2 defaults: don't demand redundant `@MainActor` where default
  main-actor isolation already applies; flag legacy defensive over-annotation.

### SwiftUI performance hot path (CLAUDE.md gate)
- **No non-trivial work in a `body` or a computed property `body` reads** —
  filtering, sorting, grouping, normalization, image decoding must be computed
  once on data change and stored in `@State`, not recomputed inline.
- Memoize pure hot functions with `MemoCache`, never a mutable static.
- A perf-sensitive change without a `PerformanceBudgetTests` guard is a finding.

### Architecture & design (CLAUDE.md clean-architecture)
- Dependencies point inward; Presentation never touches Core Data / Keychain /
  URLSession directly. New `.shared` singleton reached for globally instead of an
  injected protocol is a finding — DI is what makes it testable.
- One type, one responsibility. A file pushed past ~300 lines, or a change that
  bolts a special case onto shared infrastructure instead of generalizing the
  mechanism (**altitude**: bandaid vs. deep fix), is a finding.

### Tests (CLAUDE.md testing bar)
- Logic-bearing change ships with tests, written **test-first** (red→green).
  New/migrated tests use **Swift Testing** (`@Test`/`#expect`/`#require`/`@Suite`),
  not new XCTest.
- Tests inject fakes — no real Keychain / Core Data / network; storage-backed
  tests use a fresh `UserDefaults(suiteName: UUID().uuidString)`.
- Data-driven cases are **parameterized**; one behaviour per test; the name
  states the behaviour. A test that can't fail (asserts a tautology) is a finding.

### Cleanup (lower priority than correctness)
- **Reuse**: new code re-implementing an existing helper — name the helper to call.
- **Simplification**: redundant/derivable state, copy-paste variation, dead code.
- **Efficiency**: repeated I/O, sequential independent work, blocking work on
  startup/hot paths; long-lived closures capturing large scopes (prefer a struct
  copying only needed fields).

### Naming, comments, docs
- Clear names (PascalCase types, camelCase members). Comments explain **why**,
  not what, at the surrounding density.

## Method — finder → recall-biased verify

Scale effort to the argument (default `high`):
- **low/medium** — one careful pass over the dimensions above; few, high-confidence findings.
- **high** — sweep each dimension as an independent angle, gathering every candidate with a nameable failing scenario; then **verify each** candidate against the code before reporting. Bias verification toward keeping realistic-state bugs (races, rare-path nil, falsy-zero, boundary off-by-one). Refute only when constructibly wrong: quote the contradicting line, cite the guard already present, or show it's impossible by type/constant/invariant.
- **max** — as high, plus trace every changed symbol's call sites and re-derive each deleted line's invariant to confirm it's re-established.

Deduplicate (same defect + location + reason → one). Keep CONFIRMED and
PLAUSIBLE; drop REFUTED.

Match the effort to the diff: a small test-or-config-only diff does **not**
warrant fanning out subagents — review it inline. Reserve heavy fan-out for
large, logic-bearing diffs.

## Severity taxonomy

- **Blocker** — crash, data loss/leak, security/privacy hole, data race, wrong
  output on a reachable input, force-unwrap in shipping code. Must fix before merge.
- **Major** — real bug on an uncommon-but-reachable path; missing tests on
  logic-bearing code; architecture violation that will compound.
- **Minor** — narrow-impact bug, unnecessary complexity, efficiency waste.
- **Nit** — style/naming/comment preference. Prefix "Nit:"; never blocks merge.

## Output

Lead with a one-line verdict: **Approve**, **Approve with nits**, or
**Request changes**. Then findings, most-severe first, each as:

- **[Severity] file:line — one-sentence defect.**
  _Failing scenario:_ concrete inputs/state → wrong output/crash.
  _Fix:_ the specific change (name the helper / guard / isolation to add).

If nothing survives verification, say so plainly and approve. Close by crediting
one or two genuinely good choices in the change.

## Sources
- Google eng-practices — The Standard of Code Review; What to look for:
  https://google.github.io/eng-practices/review/reviewer/standard.html ,
  https://google.github.io/eng-practices/review/reviewer/looking-for.html
- Swift 6 strict concurrency (Sendable / actors / @MainActor) and Swift 6.2
  default-isolation shifts (SE-0461, SE-0466) — current migration guidance.
- This repo's `CLAUDE.md` (architecture, concurrency, safety, performance,
  dependency injection, testing) is the local authority and overrides the above
  where they conflict.
