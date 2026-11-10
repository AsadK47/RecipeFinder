# WORK — session handoff

## Local uncommitted (Mac, 2026-11-06) — reapplied on top of origin/main 2026-11-10
BACKLOG + FOLLOW-UPS FIXED (1852 green pre-pull, sim-checked): clear-search, search-only no-results button
 (RecipeFilterCriteria.clearActionTitle), AddToCollection frosted rows, Legal nav chrome, AppTheme.destructiveFill, Microdata
 shared header vocab; no .toolbarColorScheme(.dark) left; filter label inflects; checkbox a11y On/Off; Delete Recipe in detail
 menu via shared .recipeDeleteFlow (RecipeDeleteConfirmationSheet.swift) + UI test. Merged with upstream Re-import menu item.
 Next 🟡: "Don't ask again" tap target ~17pt (<44); checkbox unchecked colour invisible in Light / checked teal-on-teal;
 Profile shows "John"/"Doe" placeholders + blank avatar while Settings says "Recipe Chef" (unconfirmed — investigate).
 Needs: BuildProject + RunAllTests after merge, then user reviews + commits.

## In progress: none.

## Decisions
- Restore: backup text replaces a stored copy only when it's a pristine sample; photos stay as stored (not in archive).
- Dedupe runs once and only removes sample copies; legacy flag repair runs first.
- Wizard text boxes replace per-row editors; per-row unit picker + name autocomplete dropped deliberately (text is the source of truth). Don't re-add rows.

## Next action
Batches section in BACKLOG.md: refactor Batch A (RecipeDetailView+Content split) interleaves now; then Import 5/5 first slice.
