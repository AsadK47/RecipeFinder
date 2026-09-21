# Work in Progress

_Updated at the end of each session. Clear this file when the task is committed and done._
_If this file is empty or says "nothing in flight", start from `git log` and `ROADMAP.md`._

---

## Task
Canonical card/tile style: one `.appCard()` modifier (frosted `.ultraThinMaterial`, the settings
look the user chose), migrate hand-rolled tile backgrounds to it. Slice 1 = the modifier + import flow.

## Completed this session (committed)
- `4bcf684` Core Data 11–13 registration (permanent isSampleRecipe fix).
- `670b79e` aesthetic #2/#3: raw Color.orange/.red → AppTheme.warning/.error; inline RGB → tokens;
  `.large` nav title → `.inline`.
- `94ed369` WIP=1 hard constraint in root CLAUDE.md.
- (committed) SecureCredentialManager logging; encode-on-save `UserScopedStorage.setEncodable` helper
  + 6 manager call sites + Apple-cache site + test.

## In progress (UNCOMMITTED — this slice)
- NEW `RecipeFinder/Theme/View+AppCard.swift` — `.appCard(cornerRadius:)` = `.ultraThinMaterial`
  frosted fill (single source of truth for tile surfaces).
- `RecipeImportView.swift` (URL field) + `PasteTextImportSheet.swift` (TextEditor) migrated
  `Color(.systemGray6)` → `.appCard(...)`. This fixes the "import tiles are black" report.
- pbxproj registers the new file.

## Verified
- BuildProject green. Unit suite 1579/1584 pass.
- Import + sign-in accessibility audits PASS in isolation both WITH and WITHOUT my import edits
  (git-stash baseline) → my change is contrast-safe; the full-suite audit failures are flaky under
  full-suite contention.

## Findings / pre-existing (NOT mine — for the bug sweep)
- `RecipeImageStoreTests.persistsImageToDisk` + `resolvePersistsSelectedImage` FAIL consistently in
  isolation on the committed tree. Cause: `fileExists(atPath: "RecipeImages/…jpg")` uses a RELATIVE
  path (working-directory dependent). Causally independent of this session's changes. Real red — CI
  may or may not hit it depending on CWD. **Investigate as its own task.**

## Decisions
- Canonical card = frosted `.ultraThinMaterial` (user chose it over solid `cardBackground`).
- Root cause of app-wide tile drift: AppTheme has TWO card tokens (`cardBackground` + `adaptiveCard`)
  and ~4 hand-rolled idioms. `.appCard()` is the consolidation point.
- Did NOT fix the remaining tile sites piecemeal — they get migrated to `.appCard()` in later slices.

## Next action
Decide: (a) investigate the pre-existing RecipeImageStore relative-path failure, OR (b) continue the
card migration — slice 2 = wizard `Color(.systemGray6)` tiles (NotesStepView ×6, IngredientsStepView),
slice 3 = the `Color.white.opacity` frost sites (RecipeServingsCard, LegalContactCard,
RecipeWizardView+Chrome, RecipeNameStepView). Eventually route SettingsCard/CardView through `.appCard()`
and collapse the two AppTheme card tokens into one.
