# WORK — session handoff

## In progress: Import 3/5 (🚧 claimed).

## Decisions
- Restore: backup text replaces a stored copy only when it's a pristine sample; photos stay as stored (not in archive).
- Dedupe runs once and only removes sample copies; legacy flag repair runs first.
- Wizard text boxes replace per-row editors; per-row unit picker + name autocomplete dropped deliberately (text is the source of truth). Don't re-add rows.

## Next action
Slice 1 on agent/import-3-start-from-text: `PrefilledRecipeData.startingFrom(unparsedText:)` tested; PasteTextImportSheet failure → "Start from this text". Slice 2: link import failure → "Paste the recipe text instead"; UI-test launch arg to force failure + screenshots.
