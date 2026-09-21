# Work in Progress

_Updated at the end of each session. Clear this file when the task is committed and done._
_If this file is empty or says "nothing in flight", start from `git log` and `ROADMAP.md`._

---

## Task
Bug/consistency sweep campaign. Agreed order: SecureCredential → encode-on-save → aesthetic
consistency sweep → broad bug sweep → @Observable migration.

## Completed this session
- **Core Data version** (user committed): pbxproj `currentVersion` was pinned to RecipeModel 10 and
  versions 11/12/13 were unregistered — Xcode kept reverting `.xccurrentversion` → `isSampleRecipe`
  crash. User registered 11/12/13 to the app target + set Current=13 in Xcode. Permanent fix.
- **SecureCredentialManager**: added logging at the two `try?` sites; split `retrieveCredentials`
  guard so "not found" (normal) is separate from "corrupt data" (logged). No API change. ✅ type-checks.
- **encode-on-save**: added `UserScopedStorage.setEncodable<T: Encodable>(_:forKey:)` (logs on failure
  instead of silent drop); routed Badge/Collection/ShoppingList/KitchenInventory(×2)/MealPlanning
  managers through it; fixed Apple-user-cache site inline in `AuthenticationManager+AppleSignIn`.
  Left `AuthenticationManager+UserStore` (already throws). Added test
  `UserScopedStorageTests.setEncodable_encodesScopesAndRoundTrips`. ✅ BuildProject green, 141 tests green.

## In progress
Aesthetic-consistency sweep — NOT STARTED.

## Decisions
- Combine imports are all `ObservableObject`/`@Published`, not stray → correct fix is `@Observable`
  migration (iOS 17.5+), a scoped task with tests, deliberately deferred to LAST.
- encode-on-save done via one shared DRY helper, not 8 ad-hoc do/catch blocks.
- Recipe-save `try?` in PersistenceController+RecipeWrites VERIFIED not-a-bug (guarded + logged +
  `return false`); only optional dietaryInfo skip is minor — left alone (avoided a false positive).

## Failing test (if any)
None.

## Blocked by
Nothing.

## Next action
Start aesthetic sweep: read AppTheme + shared background/card components, then grep Views for one-off
`Color` / `.background` / `cornerRadius` usages that diverge from the shared language. Report findings
read-only before any edits.
