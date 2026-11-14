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
2. **New ideas go to BACKLOG.md → Parking lot** with one line: *which loop step does it serve?* None → it stays parked.
3. **Each item states its loop step and how we'll know it worked.**
4. **Monthly 10-minute Parking-lot review with the owner.**
5. **The daily challenger also asks: does this change serve the loop, or is it creep?**
