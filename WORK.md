# WORK — session handoff

## In progress: BACKLOG "Import 1/5 — Keep the original import text" (agent loop, branch agent/import-source-text)
Slice 1 (this run): Core Data `RecipeModel 15` (v14 + optional String `sourceText`), `.xccurrentversion` → 15, pbxproj
version-group entry, `RecipeModel.sourceText` (Codable decodeIfPresent → backups carry it), persistence write/fetch,
RecipeDiff/mergeEdit preserve it, tests: v14→15 migration, RecipeKey contains sourceText, Codable + in-memory store
round-trip. CLAUDE.md "RecipeModel 14" → 15.
Left for later slices: set sourceText on every import path (link ≤50 KB cleaned page text, paste, photo OCR, share
extension); detail ⋯ "Re-import from original" → RecipeTextImportRouter → RecipeRefreshSheet/RecipeDiff; screenshot.

## Decisions
- Split into slices per BACKLOG step 2 (item too big for one run); tick nothing until all slices merge.
- No mapping model: adding an optional attribute is a lightweight migration (same as v12→v13).

Slice 1 MERGED 9a6c119. Slice 2 (branch agent/import-source-text-2): PrefilledRecipeData.sourceText, router sets it
(paste/photo/share), wizard assemble + edit prefill carry it. Slice 3: link import page text (≤50 KB; ExtractedRecipeData
has no page text today — rawText is ingredients). Slice 4: detail ⋯ "Re-import from original" → router → RecipeRefreshSheet.

Slice 2 MERGED cad2d44. Slice 3 (branch agent/import-source-text-3): ExtractedRecipeData.pageText via
RecipeImportPipeline.pageText(fromHTML:) (reuses RecipeParser.cleanHTML, 50 KB cap), builder → sourceText.

Slice 4 plan (not started): pure `RecipeDiff.reimport(stored:prefill:)` in RecipeDiff.swift — upstream = stored with
each field replaced only when the prefill has it (name, ingredients via RecipeImportBuilder().parseIngredient,
instructions, prep/cook "N minutes", difficulty via RecipeWizardBuilder.normalizeDifficulty, category, cuisine);
image kept. RecipeRefreshSheet.sourceURL → URL? (header "from the original text" when nil); detail sheet no longer
gated on importedFromURL. Toolbar `onReimport: (() -> Void)?` shown when recipe.sourceText != nil ("Re-import from
original", arrow.triangle.2.circlepath). Detail: router.prefill(for: sourceText) → diff → pendingRefreshDiff, or toast
"Already up to date" / "Couldn't read a recipe from the original". Tests in RecipeDiffTests (+ router→diff with stub).
Slice 5: UI screenshot of the menu (needs a recipe with sourceText — paste-import in UI test or launch arg).

Slice 3 MERGED 449dff9. Slice 4 implemented on agent/import-reimport (RecipeDiff.reimport, toolbar menu, sheet URL optional).

## Next action
Check slice 4 CI, merge; then slice 5 = menu screenshot (UI test needs a recipe with sourceText).
