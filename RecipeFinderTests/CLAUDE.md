# Testing conventions

Applies to everything under `RecipeFinderTests/`.

## Hard constraints
These are non-negotiable. Violations are bugs, not style choices.

- **MUST** use Swift Testing (`@Suite`, `@Test`, `#expect`) for all new tests — no new XCTest.
- **MUST NOT** use shared `UserDefaults`, real Core Data, or network in unit tests — inject fakes.

## Framework
Swift Testing (`@Suite`, `@Test`, `#expect`) for all new/migrated tests. No new XCTest — migrate XCTest files opportunistically. UI tests stay XCUITest.

## Workflow
Red → green → refactor. Write the failing test first. TDD required for all logic; not required for pure UI layout or thin glue.

## Conventions
- Parameterise data-driven cases with `@Test(arguments: [...])`.
- Inject fakes — no shared `UserDefaults` / real Core Data / network in unit tests.
- One behaviour per test. Arrange–Act–Assert. Name the behaviour, not the method.
- Pyramid: many unit tests, targeted integration tests, small set of UI tests for critical flows.

## Coverage
**100% of logic-bearing code.** Accepted exemptions (note with a comment in the test file):
- Apple framework internals (Vision inference, URLSession, CoreData) — test your code against them via protocol seams.
- Pure UI layout (`body` with no logic).
- Thin glue (one-liner with no branches or transformation).
