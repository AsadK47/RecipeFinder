# WORK — session handoff

## In progress: Manual 2/3 (🚧 claimed). Slices 1–2 merged (parsers, text-box UI cd2352f).

## Decisions
- Restore: backup text replaces a stored copy only when it's a pristine sample; photos stay as stored (not in archive).
- Dedupe runs once and only removes sample copies; legacy flag repair runs first.
- Wizard text boxes replace per-row editors; per-row unit picker + name autocomplete dropped deliberately (text is the source of truth). Don't re-add rows.

## Next action
Slice 3 on agent/manual-2-size: extract subviews/helpers so `RecipeWizardView` ≤300 lines (ticks Smell "Large Class: RecipeWizardView"); remove now-unused `focusedIngredientID` / `cookingUnitGroups` params from the step views.
