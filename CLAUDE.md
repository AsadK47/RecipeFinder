# RecipeFinder — Project Notes

Privacy-first, offline-first iOS recipe manager (SwiftUI, iOS 17.5+, Swift 6).
Proprietary — RecipeFinder Limited.

## Core Data model version
Current version: **RecipeModel 13** (`RecipeModel.xcdatamodeld/.xccurrentversion`).
If the app crashes with `valueForUndefinedKey: isSampleRecipe` (or any newer attribute), `.xccurrentversion` has been reverted — set it back to `RecipeModel 13.xcdatamodel`. This file is occasionally clobbered by Xcode's model editor or a bad git merge resolution; never commit it pointing at anything older than 13.

## Repo
GitHub: https://github.com/RecipeFinderLimited/RecipeFinder

## Apple Developer
- Develop under personal Apple ID (free team) until ready for TestFlight.
- Switch signing to RecipeFinder Limited account only at distribution time.
- D-U-N-S lookup: https://www.dnb.co.uk/duns-number/lookup.html — details must match Companies House exactly.

## Architecture
Clean Architecture — dependencies point inward. Three layers:
- **Presentation** (`Views/`, `Components/`) — SwiftUI only. No direct Core Data / Keychain / URLSession.
- **Domain** (models, use cases, protocols) — pure Swift, Foundation only. Testable.
- **Data** (`Persistence/`, `Services/`) — Core Data, Keychain, URLSession. Implements Domain protocols.

Views depend on protocols, not `.shared` singletons. Files > ~300 lines are a smell — extract. Codebase is mid-migration; move touched areas toward this target, don't add debt.

## Swift & SwiftUI
- PascalCase types, camelCase members.
- `@State private` for local state; prefer value types; `@MainActor` on UI-facing types.
- `async`/`await` only — no Combine. Swift 6 strict concurrency; no force-unwrap or force-try.
- Verify unfamiliar/new APIs via `DocumentationSearch` (Liquid Glass, FoundationModels, etc.) — don't guess.
- Comments explain *why*, not *what*.

## Design principles

**SOLID**
- **SRP** — one type, one reason to change. Split god views/managers along their seams.
- **OCP** — extend via new types (protocols + implementations), not by modifying working code.
- **LSP** — subtypes/protocol conformances must be substitutable without surprising callers.
- **ISP** — small, focused protocols over fat ones. Callers shouldn't depend on methods they don't use.
- **DIP** — depend on protocols, not concrete types. (Enforced via DI section below.)

**Foundational**
- **YAGNI** — build what's needed now. One call site = no abstraction needed.
- **DRY** — one home for every piece of logic. Extract on second real duplication, not first.
- **KISS** — simplest solution that handles the actual cases. Complexity is a liability.
- **SoC** — separate concerns at every layer: UI from logic, logic from persistence, fetching from parsing.
- **Boy Scout** — leave every file you touch better than you found it.

**Design**
- **Composition over inheritance** — prefer combining small protocols and value types over deep class hierarchies.
- **CQS** — a function either returns a value (query) or changes state (command), not both. `toggle() -> Bool` violates this; `toggle()` + `contains() -> Bool` doesn't.
- **Law of Demeter** — talk to direct collaborators only. `manager.user.profile.name` is a smell; `manager.userName` is the fix.
- **Fail fast** — surface invalid state immediately at the point it's detected, not silently later.

## Security
- Keychain only for credentials/secrets. Never `UserDefaults`, Core Data, or unencrypted filesystem.
- Debug-only constants inside `#if DEBUG`.
- Validate at trust boundaries only (user input, URL imports, OCR output).
- No network calls that send recipe data or identifiers without explicit consent.
- Pin new Swift Package dependencies to a specific version.

## Error handling
- Failures must be visible to the user — no silent `catch {}` or bare `try?` in user-triggerable paths.
- Typed errors (`enum` conforming to `LocalizedError`).
- Optimistic UI with rollback: append first, persist async, roll back and alert on failure.
- `throws` / `async throws` — don't mix throwing and non-throwing paths for the same operation.

## Observability
- `AppLogger.logger(category:)` only — no `print()` in shipping code.
- `debug` for dev noise, `info` for user-visible events, `error` for failures to investigate.
- Log once at the failure site.

## Technical debt
- Refactors require a test proving behaviour-preservation — write the test first.
- When touching a manager or view, add the protocol seam or extract the pure function. Don't add to the debt.

## Performance
- No non-trivial work in `body` or properties it reads — compute once on data change, store in `@State`.
- Memoize hot pure functions with `MemoCache`, not `nonisolated(unsafe) static var`.
- Guard regressions with `PerformanceBudgetTests`.

## Dependency Injection
- Depend on protocols, inject concrete types through initialisers.
- Singletons OK as composition-root defaults (`init(storage: .shared)`), but code under test must accept injected fakes.

## Testing
**Framework:** Swift Testing (`@Suite`, `@Test`, `#expect`) for all new/migrated tests. No new XCTest. Migrate XCTest files opportunistically. UI tests stay XCUITest.

**Workflow:** Red → green → refactor. Write the failing test first. TDD required for all logic; not required for pure UI layout or thin glue.

**Conventions:**
- Parameterise data-driven cases with `@Test(arguments: [...])`.
- Inject fakes — no real Keychain / Core Data / network in unit tests.
- One behaviour per test. Arrange–Act–Assert. Name the behaviour, not the method.
- Pyramid: many unit tests, targeted integration tests, small set of UI tests for critical flows.

**Coverage: 100% of logic-bearing code.** Accepted exemptions (must be noted with a comment in the test file):
- Apple framework internals (Vision inference, URLSession, CoreData) — test your code against them via protocol seams.
- Pure UI layout (`body` with no logic).
- Thin glue (one-liner with no branches or transformation).

## UX checklist (every view touched)
- **Empty states** are actionable — always include a button, never dead-end copy.
- **Primary actions** are visible — overflow menu is for rare/secondary actions only.
- **Toolbar:** apply `.toolbarBackground(.hidden, for: .navigationBar)` with `backgroundGradient`.
- **Sheets:** wrap content in `ZStack { gradient.ignoresSafeArea(); content }`. Forms also need `.scrollContentBackground(.hidden)`.
- **Nav title:** `.inline` everywhere — `.large` breaks visual rhythm.
- **`NavigationView` is banned** — use `NavigationStack`.
- **New files** via `XcodeWrite` (not `Write`) so Xcode registers them.

## Build & CI
Run verification fastest-first; stop and fix at the first failure before proceeding.
1. `XcodeRefreshCodeIssuesInFile` — after editing any `.swift` file (seconds)
2. `RunSomeTests` (name the suite) — after adding/changing logic
3. `BuildProject` — before marking a task done
4. `RunAllTests` — for refactors or changes touching >1 file

CI runs the full test suite on every push to `main` — red tests fail the build.

**Common failure patterns:**

| Failure | Likely cause |
|---|---|
| Force-unwrap or `try?` in new code | Task didn't state Swift 6 / no-force rules |
| New file not found by Xcode | Used `Write` instead of `XcodeWrite` |
| Test hits real `UserDefaults` or Keychain | DI requirement not stated |
| SwiftUI view crashes on empty data | Empty-state path not in DoD or test |
| Core Data crash `valueForUndefinedKey: isSampleRecipe` | `.xccurrentversion` reverted off RecipeModel 13 |
| Agent re-implements existing utility | Skipped `XcodeGrep` for prior art |
| Combine creeping back in | Task didn't say `async/await` only |

## Commit messages
End every code-changing response with one conventional-commit line. No body, no Co-Authored-By, no preamble.
`fix(import): fix grey text in ImportView header`

## Git / auth
SSH key (ed25519) added to GitHub as Auth + Signing Key. Commit signing via:
```
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
```
