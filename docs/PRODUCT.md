# RecipeFinder — product strategy (owner OK 2026-11-14)

The north star every agent, review and challenge checks work against. Short on purpose; change it only with the owner.

## North star
**Dinner, sorted.** RecipeFinder helps people decide what to eat, get what they need, cook it well and remember it.
Measure of success: **dinners cooked per week per active cook.** Every item says how it moves that number, or it waits.

## The loop — every tab has one job
🔁 **Discover → Decide → Get → Cook → Remember → Discover**

| Where | Job |
|---|---|
| **Recipes** | Discover — your library, plus endless "Because you loved…" chapters to browse |
| **Today** | Decide tonight — one pick, what to do now. Short and calm; nothing to scroll forever |
| **Plan** | Decide the week — swipe to match dinners; the week is seven photos; one minute on a Sunday |
| **Groceries** | Get — the list writes itself from the plan; a shop mode to tick in the aisle; "at home" is inferred |
| **Cooking mode → Me** | Cook it well (one step per screen), then remember it in **My Cookbook** |

What's cooked feeds "Because you loved X" back in Recipes — the loop closes.

## Principles (every screen)
1. **One primary action per screen**, obvious within a second.
2. **Every action has a visible control; gestures are bonuses** (e.g. ♥ / ✕ buttons beside swipe, a Next button beside tap-right).
3. **No setup, no data entry** — infer; ask only when it matters.
4. **Never empty** — every screen has something good to do, even on day one.
5. **Fast, and works everywhere — great signal or none.** Uses the internet freely, never depends on it for the core job.
6. **Big pictures, few words** — food sells itself.
7. **One gesture means done; the app does the bookkeeping.**

## Roadmap — one phase at a time
- **Now — data you can trust:** iCloud sync (Data safety 2/4) → backups with photos (3/4) → Recently deleted (4/4).
- **Phase 1 — Cook it well:** Cooking flow → Made-it moment → My Cookbook.
- **Phase 2 — Decide & get:** Plan (swipe to match + week of photos + fill my week) → Groceries writes itself.
- **Phase 3 — Discover:** Recipes as endless discovery → Today trimmed to deciding tonight.
- **Fixed date:** Your Cooking Year (Wrapped) ships by 1 Dec, built from cook history / My Cookbook.
- **Between phases:** quality — screenshots, Settings tidy-up, smells, polish. Bug fixes (🐞, TestFlight, Inbox) any time.

## Parked (not deleted — revisit when the loop feels effortless)
Play extras (Kitchen Bites, Cooking Path, quests, mascot, Spoons + shop, daily-streak rework), badge tiers, taste
fingerprint, video import, "Make a picture", guided tour, Widget + Live Activity. **Dropped:** Dinner Jackpot
(gambling mechanics; pulls against calm and useful).

## Discipline
1. **One phase at a time.** Nothing from a later phase starts early (bug fixes excepted).
2. **New ideas go to BACKLOG.md → Parking lot** with one line: *which loop step does it serve?* The test to leave the
   Parking lot: **"Would this make someone cook one more dinner this week — and how would we notice?"** No answer to
   the second half → it stays parked.
3. **How we notice** (the app sends nothing to us): App Store Connect App Analytics (Apple's opt-in sessions and
   retention), TestFlight feedback (filed automatically as GitHub issues), the owner's own week of use, and on-device
   numbers the cook sees themselves ("4 dinners this week").
4. **Dogfood gate:** a phase isn't done until the owner has used it on their phone for a week and said it feels right.
5. **Subtract as you go:** each phase removes something — a screen, a setting, a duplicated view — so the app stays calm.
6. **The daily challenger also asks: does this change serve the loop, or is it creep?**

## Decision rights (owner = CEO; owner 2026-11-14: "I want to be the CEO making strategic decisions")
**The owner decides** — and only these: changes to this document (north star, loop, phase order, parking-lot
promotions); money (pricing, paid services, spending); legal sign-off on Privacy/Terms before public launch; launch
timing and App Store listing; brand and names; repo visibility; anything irreversible or outward-facing (deleting user
data paths, public posts, accounts, entitlements/capabilities). Plus device-only steps (TestFlight on their phone,
Mac-only tools).
**Agents decide everything else** within this document and BACKLOG guardrails — UX details, code, tests, CI, docs,
process improvements, wording that matches agreed behaviour — and record why in WORK.md Decisions. Don't ask the owner
about these; do them well and report.
**Batch, don't interrupt:** owner questions go to BACKLOG → Needs owner as a multiple-choice line with a recommended
default. The weekly CEO digest (Monday) collects them. **Reversible decisions proceed on the recommended default after
72 hours without an answer** (say so in the Log); irreversible / money / legal ones wait.

## Review effort scales with risk
- **Two independent reviewers + a check against the code/source:** anything touching data (storage, sync, deletion,
  migration), privacy/legal text, money, security trust boundaries (imports, shared files, web view), or user-facing
  claims.
- **One reviewer + the daily challenger:** ordinary UI, copy matching agreed behaviour, tests, docs, tooling.
