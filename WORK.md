# WORK — session handoff

## In progress: Inbox 🟠/🟡 findings (all 🔴 release blockers merged 2026-11-10)
Order: ✅ Add amount; ✅ Re-import polish; ✅ sample refresh; StarRatingView a11y;
RecipeDiff keeps currentServings; BundledRecipeCatalogTests gaps.

## Decisions
- Restore: backup text replaces a stored copy only when it's a pristine sample; photos stay as stored (not in archive).
- Dedupe runs once and only removes sample copies; legacy flag repair runs first.

## Next action
StarRatingView a11y on agent/fix-star-rating-a11y: accessibilityAdjustableAction + value, scalable font, 44pt targets.
