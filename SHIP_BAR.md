# Ship Bar

The line for "done enough to ship" (TestFlight beta → App Store). Its job is to make "done" **finite**:
decide once what blocks a release, and send everything else to the backlog instead of fixing forever.

**Rule of thumb:** a bug only blocks ship if it's a **crash, data loss, broken core loop, or privacy/auth failure**.
Everything else is backlog. When in doubt, it does **not** block.

## Blocks ship (must-fix) 🔴
A release cannot go out while any of these are open:
1. **Crash** on a normal path (launch, browse, open recipe, import, cook, sign in/out, settings).
2. **Data loss / corruption** — a user's recipes, cook history, collections, groceries, or meal plans
   disappear, get overwritten, or leak between accounts.
3. **Core loop broken** — can't: browse recipes → open one → cook it → have it count. Import (at least one of
   URL / paste / photo) must produce a saved, usable recipe.
4. **Auth / privacy failure** — sign in/out doesn't work, a user sees another account's data, or credentials
   land anywhere but the Keychain.
5. **Dead end with no recovery** — a state the user can't get out of without reinstalling (stuck screen,
   unrecoverable error, blank library that never reloads).
6. **Build/CI red**, or a visibly broken first-run (fresh install can't reach the recipe list).

## Fix only if cheap, else backlog 🟡
Real but not release-blocking. Fix now **only** if it's a small, low-risk change; otherwise log and move on:
- Edge-case import parsing (unusual sites, malformed OCR, rare schema variants).
- Cosmetic/polish: spacing, animation feel, cold-cache image pop-in, minor copy.
- Rare-path behaviour (iPad split-view sync, account-switch mid-action, offline image load).
- Accessibility nits that aren't a hard blocker.

## Does not block ship (post-ship backlog) 🟢
- "Nice to have" features and refinements — these live in `ROADMAP.md`, not here.
- Performance micro-optimisation without a measured problem.
- Architecture/refactor wishes (modularisation, ViewInspector coverage expansion, etc.).
- Exotic inputs no real user will hit.

## Pre-TestFlight checklist
Run once before pushing a build; if all pass and no 🔴 is open, **ship it**.
- [ ] `BuildProject` + `RunAllTests` green (UI flakes re-run once, not treated as blockers).
- [ ] Fresh install → lands on recipe list with seed recipes (no blank screen).
- [ ] Core loop by hand: open a recipe → cook → it counts (streak/badge/cook count).
- [ ] One import path works end-to-end (URL or paste), saves a usable recipe.
- [ ] Sign in → data appears; sign out → no previous-account data lingers; browse still works.
- [ ] No crash across: launch, each tab, open recipe, import, settings, sign in/out.
- [ ] Settings → Data: backup/export produces a file; restore reads it back.

## How to use this
- Found a bug? Classify it 🔴 / 🟡 / 🟢 **before** fixing. Only 🔴 (and cheap 🟡) get worked now.
- Stop auditing for more once no 🔴 remain and the checklist passes. More hunting = more 🟡/🟢 = never shipping.
- This bar is the definition of done. If something isn't on it, it isn't blocking the release.
