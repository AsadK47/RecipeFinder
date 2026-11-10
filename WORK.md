# WORK — session handoff

## In progress: Manual 3/3 (🚧 claimed). Slice 1 merged (4157d72: times, servings).

## Decisions
- Restore: backup text replaces a stored copy only when it's a pristine sample; photos stay as stored (not in archive).
- Dedupe runs once and only removes sample copies; legacy flag repair runs first.
- Wizard text boxes replace per-row editors; per-row unit picker + name autocomplete dropped deliberately (text is the source of truth). Don't re-add rows.

## Next action
Manual 3/3 slice 2 on agent/manual-3-a11y: RecipeNameStepView photo remove buttons → ≥44pt + accessibilityLabel("Remove photo N"); gallery ForEach keyed by stable id not offset. Then Screenshots.
