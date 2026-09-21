# RecipeFinder

Privacy-first, offline-first iOS recipe manager (SwiftUI, iOS 17.5+, Swift 6).
Proprietary — RecipeFinder Limited. GitHub: https://github.com/RecipeFinderLimited/RecipeFinder

## Hard constraints
These are non-negotiable. Violations are bugs, not style choices.

- **MUST** run `BuildProject` + `RunAllTests` before committing.
- **MUST NOT** commit partial or unverified work — write `WORK.md` instead.
- **MUST** use `XcodeWrite` (not `Write`) when creating new Swift files.
- **MUST NOT** point `.xccurrentversion` at anything older than `RecipeModel 13`.

## Core Data model version
Current version: **RecipeModel 13** (`RecipeModel.xcdatamodeld/.xccurrentversion`).
If the app crashes with `valueForUndefinedKey: isSampleRecipe`, `.xccurrentversion` has been reverted — set it back to `RecipeModel 13.xcdatamodel`. This file is occasionally clobbered by Xcode's model editor or a bad git merge resolution; never commit it pointing at anything older than 13.

## Apple Developer
- Develop under personal Apple ID (free team) until ready for TestFlight.
- Switch signing to RecipeFinder Limited account only at distribution time.

## Architecture
Clean Architecture — dependencies point inward:
- **Presentation** (`Views/`, `Components/`) — SwiftUI only. No direct Core Data / Keychain / URLSession.
- **Domain** (models, use cases, protocols) — pure Swift, Foundation only. Testable.
- **Data** (`Persistence/`, `Services/`) — Core Data, Keychain, URLSession. Implements Domain protocols.

Views depend on protocols, not `.shared` singletons. Files > ~300 lines are a smell — extract.

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

## Session start checklist
1. Read `WORK.md` — if it has content, resume from "Next action" without repeating completed work.
2. If `WORK.md` is empty, orient via `git log --oneline -10` and `ROADMAP.md` before starting work.
3. `git status` — no unexpected staged/unstaged changes from a prior partial run.
4. Check `.xccurrentversion` points at `RecipeModel 13` if Core Data was recently touched.

## Session handoff
When a task spans multiple sessions or is left incomplete, write the current state into **`WORK.md`** (repo root) using the template in that file. Clear it once the task is committed and done.

## Harness decay
When a new failure class appears or a convention changes, update the relevant section in the same commit — stale documentation is worse than none.

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
