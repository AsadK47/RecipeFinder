# WORK — session handoff

## In progress: Inbox 🟠/🟡 findings (all 🔴 release blockers merged 2026-11-10)
Order: ✅ Add amount; ✅ Re-import polish; stale-sample refresh batched off-main + mark done only on decode; StarRatingView a11y;
RecipeDiff keeps currentServings; BundledRecipeCatalogTests gaps.

## Decisions
- Restore: backup text replaces a stored copy only when it's a pristine sample; photos stay as stored (not in archive).
- Dedupe runs once and only removes sample copies; legacy flag repair runs first.

## Next action
Stale-sample refresh on agent/fix-sample-refresh-batch: one batched background save (like seedRecipes) + mark version done only when bundle and history decode non-empty; inject LocalStore.
