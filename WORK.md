# WORK — session handoff

## In progress: Inbox 🔴 release blockers (owner order: 🔴 first, then 🟠/🟡)
1. ✅ Photo file names → UUID (merged).
2. removeDuplicateCopies: run-once flag + samples only.
3. Restore merges user state onto re-seeded samples (+ streak dates, photo copy text).
Then 🟠/🟡 Inbox batches: "Add amount" button; Re-import hidden for link imports + nothing pre-ticked + nil empty
sourceText + cap pasted text; RecipeDiff keeps currentServings; stale-sample refresh batched off-main + mark done only on
decode; StarRatingView a11y; BundledRecipeCatalogTests gaps.

## Decisions
- Made it presented by the detail view (c247b57); root presentation dropped sheets inside Collections.

## Next action
removeDuplicateCopies: samples-only + run-once, test-first on agent/fix-dedupe-samples-only.
