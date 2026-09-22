# RecipeFinder

Privacy-first, offline-first iOS recipe manager (SwiftUI, iOS 17.5+, Swift 6).
Proprietary — RecipeFinder Limited. GitHub: https://github.com/RecipeFinderLimited/RecipeFinder

## Hard constraints
These are non-negotiable. Violations are bugs, not style choices.

- **MUST** run `BuildProject` + `RunAllTests` before committing.
- **MUST NOT** commit partial or unverified work — write `WORK.md` instead.
- **MUST** keep one task active at a time (WIP=1): finish it (`BuildProject` + `RunAllTests` green — "looks fine" is not done) before starting the next, and never "also refactor" B while doing A — record B as the next `WORK.md` action. *(verify before any batch edit; a wrong premise × N files is the expensive failure)*
- **MUST** use `XcodeWrite` (not `Write`) when creating new Swift files. *(source: Xcode requires explicit project file registration; retire if Claude Code auto-registers)*
- **MUST NOT** point `.xccurrentversion` at anything older than `RecipeModel 13`. If the app crashes with `valueForUndefinedKey: isSampleRecipe`, this file was clobbered — restore it to `RecipeModel 13.xcdatamodel`. *(update this number whenever the Core Data model version increments)*

## Topic docs (loaded automatically by directory)
- `RecipeFinder/CLAUDE.md` — Swift/SwiftUI rules, design principles, security, DI, UX checklist. Read when editing any app source file.
- `RecipeFinderTests/CLAUDE.md` — Testing framework, conventions, coverage. Read when editing tests.

## Apple Developer
- Develop under personal Apple ID (free team) until ready for TestFlight. *(free team lacks CloudKit/push entitlements; retire once paid enrollment is active)*
- Switch signing to RecipeFinder Limited account only at distribution time.

## Architecture
Clean Architecture — dependencies point inward:
- **Presentation** (`Views/`, `Components/`) — SwiftUI only. No direct Core Data / Keychain / URLSession.
- **Domain** (models, use cases, protocols) — pure Swift, Foundation only. Testable.
- **Data** (`Persistence/`, `Services/`) — Core Data, Keychain, URLSession. Implements Domain protocols.

Views observe managers through `@Environment` protocol seams (e.g. `@Environment(\.auth)`), not
`.shared` singletons directly — each manager is an `@Observable` conforming to a `*ing`/`*Managing`
protocol with an `EnvironmentKey` defaulting to `.shared`. Data-layer reads (`PersistenceController.shared`)
and view-*owned* instances (`@StateObject … = RecipeImporter()`) are exempt. Files > ~300 lines are a
smell — extract.

## Build & CI
Run verification fastest-first; stop and fix at the first failure before proceeding.
1. `XcodeRefreshCodeIssuesInFile` — type-check a single file (seconds); run after every edit
2. `RunSomeTests <SuiteName>` — run the directly affected test suite after adding/changing logic
3. `BuildProject` — full compile; run before marking any task done
4. `RunAllTests` — full suite; run for refactors or changes touching >1 file

**Full check:** `BuildProject` then `RunAllTests` — both must be green before a task is considered done.

CI runs the full test suite on every push to `main` — red tests fail the build.

**When the AI agent produces a wrong result, don't conclude "the LLM isn't capable enough" — attribute the failure to a layer first.** Work through these five in order: (1) task not clearly defined, (2) insufficient context, (3) misconfigured environment, (4) missing verification, (5) loss of state between sessions.

| Failure | Layer | Likely cause |
|---|---|---|
| Force-unwrap or `try?` in new code | Task definition | Swift 6 / no-force rules not stated |
| Combine creeping back in | Task definition | `async/await` only rule not stated |
| Test hits real `UserDefaults` or Keychain | Task definition | DI requirement not stated |
| Agent re-implements existing utility | Insufficient context | Skipped `XcodeGrep` for prior art |
| New file not found by Xcode | Misconfigured env | Used `Write` instead of `XcodeWrite` |
| Core Data crash `valueForUndefinedKey: isSampleRecipe` | Misconfigured env | `.xccurrentversion` reverted off RecipeModel 13 |
| SwiftUI view crashes on empty data | Missing verification | Empty-state path not covered by a test |
| Verification skipped or simpler fix chosen near session end | Context pressure | Agent sensed low context → rushed finish; write WORK.md Decisions before this happens |

## Session start checklist
1. Read `WORK.md` — if it has content, resume from "Next action" without repeating completed work.
2. If `WORK.md` is empty, orient via `git log --oneline -10` and `ROADMAP.md` before starting work.
3. `git status` — no unexpected staged/unstaged changes from a prior partial run.
4. Check `.xccurrentversion` points at `RecipeModel 13` if Core Data was recently touched.

## Session end checklist
1. Update `WORK.md` Decisions — options rejected, tradeoffs accepted, constraints discovered.
2. Update In Progress with exact file / function / state (specific enough to resume cold).
3. Set Next action to a single concrete step.
4. `git status` — commit completed work or leave a clean working tree.

If the task looks like it will exceed ~60% of the context window, run this checklist now — not when context is nearly full.

## Session handoff
Write **`WORK.md`** (repo root) **before context pressure builds** — not after. The Decisions section captures *why* key choices were made (options rejected, tradeoffs); compaction preserves code but silently drops this reasoning, and the next session will "fix" deliberate decisions without it. Clear the file once the task is committed and done.

## Harness decay
When a new failure class appears or a convention changes, update the relevant section in the same commit — stale documentation is worse than none.

**Replace or refine, don't append.** When a failure tempts you to "add a new rule," first ask whether an existing rule should be sharpened instead. Each CLAUDE.md file has a line budget: root ≤100, RecipeFinder/ ≤100, RecipeFinderTests/ ≤50. Exceeding budget is a signal to consolidate, not to keep adding.

## Commit messages
Only commit once the full check passes (`BuildProject` + `RunAllTests` green). A partial or unverified state must not be committed — update `WORK.md` instead and resume next session.

End every code-changing response with one conventional-commit line. No body, no Co-Authored-By, no preamble.
`fix(import): fix grey text in ImportView header`

## Git / auth
SSH key (ed25519) added to GitHub as Auth + Signing Key. Commit signing via:
```
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
```
