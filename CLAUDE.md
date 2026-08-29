# RecipeFinder — Project Notes

Privacy-first, offline-first iOS recipe manager (SwiftUI, iOS 17.5+, Swift 6).
Proprietary software owned by RecipeFinder Limited.

## Repo
- GitHub: https://github.com/RecipeFinderLimited/RecipeFinder

## Business / Apple Developer account
- Business: RecipeFinder Limited (UK limited company)
- An Apple Account has been created using the business email, but has not yet been signed into Xcode.
- Plan: keep developing under the personal Apple ID (free personal team) for now. Only switch Xcode's signing over to the RecipeFinder Limited Apple Developer account when the app is ready for TestFlight/App Store distribution.
- Enrolling the business account as an Organization on the Apple Developer Program requires a D-U-N-S number.
  - Check first whether RecipeFinder Limited already has one: https://www.dnb.co.uk/duns-number/lookup.html
  - If not, request one for free via Apple's own D-U-N-S tool (avoid D&B's direct signup, which can upsell paid tiers): https://developer.apple.com/enroll/duns-lookup/
  - Company name, address, and registration number used in the application must match Companies House exactly.
  - Lookup is usually instant if a D-U-N-S already exists; a fresh application can take up to ~5 business days (sometimes longer for UK applicants if details don't match Companies House).

## Architecture

Follow **Clean Architecture** — dependencies point inward, outer layers depend on
inner, never the reverse. Reference: https://refactoring.guru/design-patterns and
the SOLID/refactoring catalog on that site.

- **Presentation** (`Views/`, `Components/`, `Theme/`) — SwiftUI views and view
  models. Knows about the Domain; never talks to Core Data / Keychain / URLSession
  directly.
- **Domain** (models, use cases, protocols) — plain Swift business logic and the
  *protocols* that outer layers implement (e.g. `RecipeRepository`,
  `CredentialStore`). No framework imports beyond Foundation. Pure and testable.
- **Data** (`Persistence/`, `Services/`, networking) — Core Data, Keychain,
  URLSession, UserDefaults. Implements the Domain protocols.

**Rules:**
- Views depend on abstractions (protocols / injected view models), not on `.shared`
  singletons reached for globally. See Dependency Injection below.
- Keep files focused and small. A file growing past ~300 lines is a smell — extract
  the view model, subviews, or a use case. Long files are a signal to refactor, not
  a style choice.
- One type, one responsibility. Split "god" views and managers along their seams.

> Current state: the codebase is mid-migration toward this. Several large views mix
> UI + filtering + persistence, and most collaborators are `.shared` singletons.
> When you touch an area, move it toward the target architecture — don't add to the
> debt.

## Swift & SwiftUI conventions
- **Naming:** PascalCase types, camelCase members. Clear over clever.
- **State:** `@State private` for local view state; `let` for constants; prefer value
  types (`struct`/`enum`) over classes unless reference semantics are needed.
- **Concurrency:** use `async`/`await`, not Combine. Annotate UI-facing types
  `@MainActor`. Respect Swift 6 strict concurrency — no data races, mark shared types
  `Sendable` where required.
- **Safety:** no force-unwrap (`!`) or force-`try` in shipping code; use `guard let`,
  `if let`, and typed errors.
- **Helpers:** introduce a helper only when there's real duplication or a genuine
  complexity win — never a speculative abstraction used in one place.
- **New/unfamiliar APIs:** this app targets modern OS versions (Liquid Glass,
  FoundationModels, latest SwiftUI). Verify current API via Apple's docs
  (`DocumentationSearch`) rather than assuming — don't guess at framework surface.
- **Comments:** explain *why*, not *what*. Match the surrounding density.

## Performance (rendering hot path)
- **No non-trivial work in a SwiftUI `body` or the computed properties it reads.**
  `body` runs on every state change, tab switch, and scroll tick. Filtering,
  sorting, grouping, normalization, and image decoding must be computed once when
  the data changes and stored in `@State` — not recomputed inline. Expensive work
  in `body` is invisible to correctness tests and is how tab switching once ground
  to a halt.
- **Memoize pure hot functions with `MemoCache`, never `nonisolated(unsafe) static var`.**
  A mutable static dictionary is a data race under Swift 6; deleting one to "fix"
  the race silently reintroduces the per-call cost. `MemoCache` is the safe,
  lock-guarded replacement — reach for it instead.
- **Guard regressions with a loose perf-budget test** (see `PerformanceBudgetTests`).
  Budgets target order-of-magnitude regressions, not run-to-run noise; if one
  fails, look for a removed cache before touching the number.

## Dependency Injection
- Depend on **protocols**, inject concrete types. This is what makes code testable
  and is the lever for the clean-architecture migration.
- Define a protocol for each external dependency (store, network, credentials),
  inject it through the initializer, and pass a fake in tests.
- Singletons may remain as a *composition-root default* (e.g.
  `init(storage: UserScopedStorage = .shared)`), but code under test must be
  constructible with injected fakes. `ShoppingListManager(storage:)` is the pattern
  to follow.

## Testing

**Framework: Swift Testing** (`import Testing`, `@Test`, `#expect`, `#require`,
`@Suite`) for all new and migrated tests. Do **not** write new `XCTest` code.
XCTest and Swift Testing coexist in the same target, so migrate the existing XCTest
files **opportunistically** — when you touch a file's area, rewrite it — rather than
in one big-bang pass. UI tests continue to use XCUITest (XCTest-based) until Apple
ships a replacement.

**Workflow: test-driven (red → green → refactor).** Write the failing test
*first*, watch it fail for the right reason, then write the minimum code to pass,
then refactor with the test as a safety net. This is the default for new logic
(use cases, parsers, models, filters) and for **extractions during refactors**:
when pulling logic out of a large view, write the tests against the new type first
so the extraction is provably behavior-preserving. Pure value types (e.g.
`RecipeFilterCriteria`) are the ideal TDD target — extract, test, then delegate the
view to them. TDD is not required for pure UI layout or thin glue with no logic.

**Conventions:**
- **Parameterize** data-driven tests: collapse many near-identical
  `input → expected` cases into one `@Test(arguments: [...])`. Failures still report
  the offending input. Ideal for parsers, normalizers, converters, classifiers.
- **Inject fakes** rather than hitting real Keychain / Core Data / network. Use a
  fresh `UserDefaults(suiteName: UUID().uuidString)` for storage-backed tests.
- **Arrange–Act–Assert**, one behavior per test. Name the behavior, not the method.
- Keep the **test pyramid**: many fast unit tests (logic, models, use cases, mappers),
  targeted integration tests (repository + store, importer + parser), and a *small*
  set of UI tests for critical flows only (launch, sign-in, import a recipe). Don't
  chase a coverage percentage or add per-screen UI tests.
- Tests come **first**, not afterward (see workflow above). All new code ships with
  tests, and no logic-bearing change is considered done until it has them.

## Build & CI
- Build with the `BuildProject` MCP tool; use `XcodeRefreshCodeIssuesInFile` for fast
  per-file diagnostics before a full build.
- CI (`.github/workflows/build.yml`) builds on every push to `main` and **runs the
  test suite by default** — a red test suite fails the build.

## Git / auth setup
- SSH key (ed25519) has been generated and added to GitHub as both an Authentication Key and a Signing Key.
- Commit signing is configured via:
  ```
  git config --global gpg.format ssh
  git config --global user.signingkey ~/.ssh/id_ed25519.pub
  git config --global commit.gpgsign true
  ```
