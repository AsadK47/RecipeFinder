# WORK — session handoff

## In progress: BACKLOG "Import 2/5 — Low-confidence warning" (branch agent/import-quality)
Slice A: `RecipeFinder/Utilities/Recipe/ImportQuality.swift` (new, pbxproj-registered): `ImportQuality.assess(prefill)
-> Assessment(score, missing: Set<Field>)`, Field = name/ingredients/steps/amounts/times; score = prefill.sourceConfidence
when set (URL parser confidence; on-device AI = 1.0) else field-weighted (name .2, ingredients .3, steps .3, amounts .1,
times .1); `isLow` = score < 0.6. `PrefilledRecipeData.sourceConfidence: Double?` set in init(interpreted:) = 1.0 and by
the URL review path from `importer.parseConfidence`. Tests: `RecipeFinderTests/Utilities/Recipe/ImportQualityTests.swift`.
Slice B: wizard banner "We couldn't read this one well — check the highlighted parts" + orange outline on sections
(basics←name, details←times, ingredients←ingredients/amounts, instructions←steps), only for new imports; screenshot via
paste-import UI path in RecipeFinderScreenshotTests.

## Decisions
- Missing fields always computed from content; the confidence only decides whether to warn.
- Split into slices (WIP=1, CI per slice).

Slice A green on 71e3522, rebased to d23f2e4 (main moved). Slice B added on same branch: ImportQualityBanner.swift
(registered), wizard highlights, DEBUG `-show-low-confidence-import` in ImportView, screenshot test 09-low-confidence-import.
After 2/5: owner rule — work the BACKLOG Inbox findings (several are about today's Made it / re-import code) before 3/5.

## Next action
CI on branch + Screenshots workflow for 09; merge; tick 2/5 (remove 🚧).
