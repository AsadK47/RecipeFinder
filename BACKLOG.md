# Backlog — worked by the scheduled agent loop

Ranked, top first. The owner reorders, adds or deletes items at any time; agents only tick items off, append to the
Log, and add review findings under **Inbox**. Each item says what "done" means — an item isn't done until CI is green.

## How an agent works this file (read fully before starting)
1. Read root `CLAUDE.md`, `RecipeFinder/CLAUDE.md`, `RecipeFinderTests/CLAUDE.md`, `RecipeFinder/DesignSystem.md`.
2. Take the **first unticked item under Queue** that isn't marked 🙋 (needs the owner). One item per run (WIP=1).
   If the item is too big for one run, do a coherent first slice, tick nothing, and rewrite the item to say what's
   left. If it's unclear or would break a guardrail, move it to **Needs owner** with a one-line question and stop.
3. Branch `agent/<short-slug>` from latest `main`. Write tests first (Swift Testing) for any logic.
4. No Swift toolchain in the cloud container: CI is the compiler. Push the branch, then check the "Build & Test" run
   for that commit with the GitHub tools; on failure read the job log, fix, push, re-check. Give up after 4 failed
   attempts — log what broke and leave the branch unmerged.
5. When green: rebase on `origin/main`; if that brought in new commits, push and wait for green again. Then
   fast-forward `main` to the branch and push `main` (this ships a TestFlight build). Delete the remote branch.
6. Tick the item, append one line to **Log** (date · item · commit · what to check on device), commit to `main`.

### Guardrails — never do these without the owner saying yes in this file
- Change the Core Data model / `.xccurrentversion`, signing, entitlements, bundle IDs, CI/TestFlight workflows.
- Change legal text (Terms, Privacy, LICENSE), pricing, or anything that sends data off the device.
- Add a third-party dependency, a new Xcode target, or delete user data paths.
- Skip, disable or weaken a test to get green.
- New Swift files: no `XcodeWrite` in the cloud — register them in `project.pbxproj` by mirroring a sibling file's
  four entries (PBXBuildFile, PBXFileReference, group child, Sources phase). Say so in the Log.

## Queue
- [x] **"Made it" moment.** Tapping *Made it* opens one celebratory sheet: "Cook #N", streak flame + weeks, tap-to-rate
  stars, optional photo (reuse `PostCookPhotoSheet` logic), and progress to the next cooking badge ("2 more to
  *Seasoned*"). Replaces the scattered rate/photo flow (CORE_LOOP_AUDIT "Track"). *Done when:* one sheet, rating +
  photo saved from it, badge progress text unit-tested, CI green.
- [ ] **Refresh stale bundled recipes.** Sample recipes are seeded once (`RecipeStore.seedIfNeeded`), so devices keep
  pre-curation copies (e.g. old "鷄肉炒麵" with steps as ingredients). Add a versioned one-time refresh that replaces
  content of `isSampleRecipe` recipes the user hasn't edited with the bundled version, preserving favourite, rating,
  cook history, photos, tags. *Done when:* tested for edited vs unedited, version bump re-runs it, CI green.
- [ ] **Your Cooking Year (Wrapped).** Ship before 1 Dec. Shareable card: dishes cooked, top cuisine, signature dish
  (most cooked), longest streak, best photo. Pure stats function tested; share via `ShareLink` image render.
  Entry: Recipes header streak chip sheet in December. *Done when:* stats tested on empty + full data, CI green.
- [ ] **"What's for dinner?" decider.** Swipeable cards from the user's library, ranked by can-make-now %, favourites,
  not-cooked-recently (reuse `RecipeRediscovery` scoring ideas). Entry on the Recipes home. *Done when:* ranking is a
  tested pure function, swipe right opens the recipe, CI green.
- [ ] **Recently cooked row** on the Recipes home (last 3–5 by `lastCookedAt`), hidden when none. *Done when:* tested
  selection, CI green.
- [ ] **Profile → Cooking diary.** No accounts, so a name-and-photo Profile reads like a sign-in. Replace with a photo
  timeline of cooks + stats + badges; drop last-name field. 🙋 Owner to confirm before starting.
- [ ] **Streak freeze.** One missed week forgiven per calendar month; shown in the Cooking sheet. *Done when:*
  `CookingStreak` tests cover freeze use + monthly reset, CI green.
- [ ] **Zero-waste wins.** When a recipe using a soon-to-expire pantry item is marked cooked, celebrate it; monthly
  "used up N items before they expired" in the Cooking sheet. *Done when:* counting tested, CI green.
- [ ] **Sunday planning nudge.** Opt-in weekly notification → planner with 3 suggested meals → add week to groceries.
  Uses existing `NotificationKind`. *Done when:* scheduling tested, opt-in in Notification settings, CI green.
- [ ] **Cuisine passport.** Stamp grid of cuisines cooked (from `cuisinesCooked` metric) in the Cooking sheet.
- [ ] **Polish batch** (from WORK.md 2026-11-06): forced `.toolbarColorScheme(.dark)` on MealPlanningView /
  ProfileView / SmartCollectionDetailView (white title in Light); "1 active filters" plural; "Don't ask again"
  checkbox a11y state; ingredient delete only via long-press (add swipe).
- [ ] **Scroll fade elsewhere.** Check other screens with a nav bar + scrolling content for text showing through the
  toolbar; apply `NavigationBarScrollFade` (see DesignSystem.md lesson 2026-11-08) where it does.

## Needs owner
- 🙋 Home-screen widget ("Tonight" + streak) — needs a new Widget Extension target; do at a Mac.
- 🙋 Website signup emails — needs a new Web3Forms access key for recipefinderuk@gmail.com.

## Inbox (reviewer findings — owner triages into Queue)

## Log
- 2026-11-08 · loop set up · CI now also runs on `agent/**` branches.
- 2026-11-09 · "Made it" moment · ef1c7f1 · Tap *Made it* (and finish cooking mode → Done): one sheet shows Cook #N (total cooks), streak, stars, Add/Take photo, "N more to <badge>"; rate + add photo, check both saved. Renamed PostCookPhotoSheet.swift→MadeItSheet.swift in pbxproj. Streak toast + cooking-mode "Add a photo" removed. Remote branch not deleted (proxy refused) — delete agent/made-it-sheet by hand.
