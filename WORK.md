# WORK — session handoff

## In progress: none (Manual series done).

## Decisions
- Restore: backup text replaces a stored copy only when it's a pristine sample; photos stay as stored (not in archive).
- Dedupe runs once and only removes sample copies; legacy flag repair runs first.
- Wizard text boxes replace per-row editors; per-row unit picker + name autocomplete dropped deliberately (text is the source of truth). Don't re-add rows.

## Next action
Smell "Large wizard": one `SuggestionChip` view for the 3 chip buttons in NotesStepView. Then Import 3/5.
