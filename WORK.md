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

## Next action
Check CI for slice 2, merge, then slice 3.
