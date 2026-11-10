# WORK — session handoff

## In progress: Import 3/5 (🚧 claimed).

## Decisions
- Restore: backup text replaces a stored copy only when it's a pristine sample; photos stay as stored (not in archive).
- Dedupe runs once and only removes sample copies; legacy flag repair runs first.
- Wizard text boxes replace per-row editors; per-row unit picker + name autocomplete dropped deliberately (text is the source of truth). Don't re-add rows.

## Next action
Inbox 🐞 flaky streak-chip UI test first (testCookingShowsRatingAndStreakChip). Then Import 3/5 slice 2: photo failure "Start from this text" + link failure "Paste the recipe text instead".
