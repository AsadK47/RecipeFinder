# WORK — session handoff

## In progress: Inbox 🔴 release blockers (owner order: 🔴 first, then 🟠/🟡)
1. ✅ Photo file names → UUID (merged).
2. ✅ removeDuplicateCopies samples-only + run-once (merged).
3. Restore: ✅ slice 1 recipe state (5885245); slice 2 = streak dates in archive + photo copy text.
Then 🟠/🟡 Inbox batches: "Add amount" button; Re-import hidden for link imports + nothing pre-ticked + nil empty
sourceText + cap pasted text; RecipeDiff keeps currentServings; stale-sample refresh batched off-main + mark done only on
decode; StarRatingView a11y; BundledRecipeCatalogTests gaps.

## Decisions
- Made it presented by the detail view (c247b57); root presentation dropped sheets inside Collections.

## Next action
Restore slice 2 on agent/fix-backup-streak-dates: BackupArchive.cookDates (decodeIfPresent), BackupService export/merge via CookingStreakManager, copy at DataManagementSettingsView:184.
