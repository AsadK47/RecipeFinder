# WORK — session handoff

## In progress: Queue — Sample recipes stop loading third-party photos (claimed)
Inbox done (only owner 🧹 note). Release blockers ticked.

## Decisions
- Restore: backup text replaces a stored copy only when it's a pristine sample; photos stay as stored (not in archive).
- Dedupe runs once and only removes sample copies; legacy flag repair runs first.

## Next action
Investigate how recipes_seed.json / recipes_source_images.json / history are generated (tools/, BundledRecipeCatalogTests generator) and plan slices.
