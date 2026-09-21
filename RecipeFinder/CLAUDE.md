# App code conventions

Applies to everything under `RecipeFinder/` (Views, Components, Models, Persistence, Services, Utilities).

## Swift & SwiftUI
- PascalCase types, camelCase members.
- `@State private` for local state; prefer value types; `@MainActor` on UI-facing types.
- `async`/`await` only — no Combine. Swift 6 strict concurrency; no force-unwrap or force-try.
- Verify unfamiliar/new APIs via `DocumentationSearch` (Liquid Glass, FoundationModels, etc.) — don't guess.
- Comments explain *why*, not *what*.

## Design principles

**SOLID:** SRP (one type, one reason to change), OCP (extend via new types, not modifying working code), LSP (subtypes must be substitutable), ISP (small focused protocols), DIP (depend on protocols not concrete types).

**Foundational:** YAGNI (build what's needed now), DRY (one home for every piece of logic), KISS (simplest solution for actual cases), SoC (separate UI from logic from persistence), Boy Scout (leave files better than found).

**Design:** Composition over inheritance. CQS — a function either returns a value or changes state, not both. Law of Demeter — talk to direct collaborators only. Fail fast — surface invalid state immediately.

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

## UX checklist (every view touched)
- **Empty states** are actionable — always include a button, never dead-end copy.
- **Primary actions** are visible — overflow menu is for rare/secondary actions only.
- **Toolbar:** apply `.toolbarBackground(.hidden, for: .navigationBar)` with `backgroundGradient`.
- **Sheets:** wrap content in `ZStack { gradient.ignoresSafeArea(); content }`. Forms also need `.scrollContentBackground(.hidden)`.
- **Nav title:** `.inline` everywhere — `.large` breaks visual rhythm.
- **`NavigationView` is banned** — use `NavigationStack`.
- **New files** via `XcodeWrite` (not `Write`) so Xcode registers them.
