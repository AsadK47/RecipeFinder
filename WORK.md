# WORK — session handoff

## In progress: Inbox 🟠/🟡 findings (all 🔴 release blockers merged 2026-11-10)
Order: "Add amount" button (IngredientRowView:25); Re-import hidden for link imports + nothing pre-ticked + nil empty
sourceText + cap pasted text; stale-sample refresh batched off-main + mark done only on decode; StarRatingView a11y;
RecipeDiff keeps currentServings; BundledRecipeCatalogTests gaps.

## Decisions
- Restore: backup text replaces a stored copy only when it's a pristine sample; photos stay as stored (not in archive).
- Dedupe runs once and only removes sample copies; legacy flag repair runs first.

## Next action
"Add amount" button on amount-less ingredient rows, test-first, on agent/fix-add-amount-button.
