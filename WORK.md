# WORK.md — handoff (2026-11-11, builder agent)

## In progress
- Nothing in progress. Add flow 1/3 done (slices 29850eb + 910a7f6).

## Next action
Add flow 2/3 (one paste box on "+"). First check the nightly UI run (03:00 UTC 2026-11-12) incl.
`testCaptureNewRecipeDraft` (22 now waits on `wizard.recipeName`), `testCaptureAFirstLaunchToday`, `testCreateManuallyOpensWizard`.

## Decisions (why)
- **Add flow 1/3 slice 2**: removed all step headers rather than shrinking them — each editor now opens in a sheet
  whose nav title is the section name, and placeholders already say "one per line". Ingredients' "e.g. 200 g flour"
  hint lives in the TextEditor placeholder. Stale "Step N of the Recipe Wizard" doc comments left for the Large-wizard smell.
- **Add flow 1/3 slice 1**: kept the existing section editors (one canonical editor) and show them one at a time in a
  sheet from the draft screen rather than editing inline. Photo pickers attach to the top-most sheet.
- Older decisions: see git history of this file (2026-11-11 builder handoff) and BACKLOG Log.
