#!/usr/bin/env python3
"""Pick this shard's UI tests from Xcode's own test list, balanced by how long each took.

Usage: shard-ui-tests.py tests.json SHARD SHARDS   (prints -only-testing:... arguments)

tests.json is `xcodebuild -enumerate-tests -test-enumeration-format json` output, so every UI test Xcode knows
is dealt to exactly one shard: a new test can't be missed, it just gets DEFAULT seconds until it's added below.
Longest first onto the least-loaded shard (LPT), deterministic, so all shards agree without talking.
"""
import json
import sys

# Seconds per test on a macos-26 runner, Build & Test run 43698466793 (2026-11-15). Refresh when shards drift apart.
SECONDS = {
    "RecipeFinderAccessibilityAuditTests/testAddRecipeSheetPassesAudit": 46,
    "RecipeFinderAccessibilityAuditTests/testGroceriesSearchResultsPassesAudit": 51,
    "RecipeFinderHabitLoopUITests/testCookingShowsRatingAndStreakChip": 47,
    "RecipeFinderHabitLoopUITests/testImportScreenHasNoExampleLinks": 15,
    "RecipeFinderImportUITests/testCreateManuallyOpensWizard": 19,
    "RecipeFinderImportUITests/testDraftPhotoOpensPhotoChoiceNotNameEditor": 17,
    "RecipeFinderImportUITests/testOtherAppsOpensImportScreen": 15,
    "RecipeFinderImportUITests/testPastedTextGoesStraightToReview": 28,
    "RecipeFinderLaunchUITests/testLaunchLandsOnToday": 7,
    "RecipeFinderScreenshotTests/testCaptureAFirstLaunchToday": 15,
    "RecipeFinderScreenshotTests/testCaptureBadgeReveal": 24,
    "RecipeFinderScreenshotTests/testCaptureEstimateAmounts": 25,
    "RecipeFinderScreenshotTests/testCaptureImportFailureFallbacks": 45,
    "RecipeFinderScreenshotTests/testCaptureLowConfidenceImport": 19,
    "RecipeFinderScreenshotTests/testCaptureNewRecipeDraft": 20,
    "RecipeFinderScreenshotTests/testCaptureOtherAppImportSummary": 47,
    "RecipeFinderScreenshotTests/testCaptureRecipeTicks": 59,
    "RecipeFinderScreenshotTests/testCaptureRecipesDiscovery": 26,
    "RecipeFinderScreenshotTests/testCaptureReimportMenu": 25,
    "RecipeFinderScreenshotTests/testCaptureScreenshots": 76,
    "RecipeFinderScreenshotTests/testCaptureTodayPlanned": 21,
    "RecipeFinderScreenshotTests/testCaptureTodayProgress": 27,
    "RecipeFinderScreenshotTests/testCaptureTodayTimes": 61,
    "RecipeFinderScreenshotTests/testCaptureTodayUseSoon": 16,
    "RecipeFinderScreenshotTests/testCaptureTodayWeek": 31,
    "RecipeFinderScreenshotTests/testCaptureTrophyShelf": 41,
    "RecipeFinderScreenshotTests/testCaptureWebSearch": 14,
    "RecipeFinderSheetPresentationUITests/testCookTimeEditorOpensFocusedOnFirstPresent": 17,
    "RecipeFinderSheetPresentationUITests/testRecipeDetailMenuOffersDelete": 22,
}
DEFAULT = 30
TARGET = "RecipeFinderUITests"


def enumerated_tests(node, found):
    if isinstance(node, dict):
        ident = node.get("identifier")
        if isinstance(ident, str) and ident.startswith(TARGET + "/") and ident.count("/") == 2:
            found.add(ident.replace("()", ""))
        for value in node.values():
            enumerated_tests(value, found)
    elif isinstance(node, list):
        for value in node:
            enumerated_tests(value, found)
    return found


def main():
    path, shard, shards = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
    with open(path) as f:
        tests = enumerated_tests(json.load(f), set())
    if not tests:
        sys.exit("No UI tests enumerated. tests.json starts:\n" + open(path).read()[:2000])

    def seconds(test):
        return SECONDS.get(test.split("/", 1)[1], DEFAULT)

    loads = [0] * shards
    picks = [[] for _ in range(shards)]
    for test in sorted(tests, key=lambda t: (-seconds(t), t)):
        lightest = loads.index(min(loads))
        loads[lightest] += seconds(test)
        picks[lightest].append(test)

    mine = sorted(picks[shard - 1])
    print(f"Shard {shard}/{shards}: {len(mine)} of {len(tests)} UI tests, ~{loads[shard - 1]}s "
          f"(shards ~{loads}s)", file=sys.stderr)
    print(" ".join(f"-only-testing:{t}" for t in mine))


if __name__ == "__main__":
    main()
