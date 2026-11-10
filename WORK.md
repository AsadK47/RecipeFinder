# WORK — session handoff

## In progress: Manual 2/3 (🚧 claimed). Slice 1 merged (parsers). Slice 2 = UI.

## Decisions
- Restore: backup text replaces a stored copy only when it's a pristine sample; photos stay as stored (not in archive).
- Dedupe runs once and only removes sample copies; legacy flag repair runs first.

## Next action
Slice 2 on agent/manual-2-text-ui: IngredientsStepView → TextEditor bound to a text string (seed IngredientTextBlock.text(from: items)), on change set items = IngredientTextBlock.items(from:); show parsed preview rows below (amount · unit · name); same for EditableStepsStepView with StepTextBlock. Keep RecipeWizardView API (ingredientItems / steps bindings) unchanged so builder/tests still pass. Add keyboard toolbar Done + scrollDismissesKeyboard(.interactively). Screenshots after.
