# WORK — session handoff

## In progress: Manual 2/3 (🚧 claimed). Slices 1–3 merged (parsers, text-box UI cd2352f, view split 14b1f63).

## Decisions
- Restore: backup text replaces a stored copy only when it's a pristine sample; photos stay as stored (not in archive).
- Dedupe runs once and only removes sample copies; legacy flag repair runs first.
- Wizard text boxes replace per-row editors; per-row unit picker + name autocomplete dropped deliberately (text is the source of truth). Don't re-add rows.

## Next action
Pick next BACKLOG item (alternate: Queue after this Smell). Manual 2/3 remaining (editable preview rows / fraction bar, wizard ≤1,000 lines) can be a later slice.
