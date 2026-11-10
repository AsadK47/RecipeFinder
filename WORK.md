# WORK — session handoff

## In progress: Inbox 🟠/🟡 findings (all 🔴 release blockers merged 2026-11-10)
Order: ✅ Add amount; Re-import hidden for link imports + nothing pre-ticked + nil empty
sourceText + cap pasted text; stale-sample refresh batched off-main + mark done only on decode; StarRatingView a11y;
RecipeDiff keeps currentServings; BundledRecipeCatalogTests gaps.

## Decisions
- Restore: backup text replaces a stored copy only when it's a pristine sample; photos stay as stored (not in archive).
- Dedupe runs once and only removes sample copies; legacy flag repair runs first.

## Next action
Re-import batch on agent/fix-reimport-polish: hide Re-import for link imports, open with nothing pre-ticked, nil sourceText when empty, cap pasted text (reuse pageText byte cap).
