# Play — making cooking a habit people love

Design for the **Play** series in `BACKLOG.md` (owner 2026-11-13: "more exciting and addicting like Duolingo …
better than those ideas plus more"). Agents working a Play item read this first. Internal doc — in-app copy follows
the root CLAUDE.md copy rule (positive, warm, never guilt).

## 1. What actually makes Duolingo work — and what changes for cooking

| Duolingo mechanism | Why it works | Cooking translation |
|---|---|---|
| A 2–5 min lesson is the daily unit | Keeping the streak is cheap, so it survives busy days | A cook is 30–60 min, 3–4× a week — it **can't** be the daily unit. Two loops: a **1-minute daily loop** carries the streak; the **weekly cook goal** carries the meaning |
| Streak + freeze + repair | Loss aversion; freezes measurably raised retention | Daily streak with earned freezes, free monthly repair, and **holiday mode** (Duolingo has none) |
| The path: next step always obvious | Zero decisions before starting | "What do I cook?" is *the* pain of home cooking → **Cooking Path** + Tonight pick decide for you |
| Juicy lesson-complete screen | Instant, felt reward | Made-it moment: count-ups, ring, flame, real-world impact |
| XP + leagues | Social comparison, weekly reset | Spoons + chef levels; leagues only via Game Center if owner OKs (§9); "you vs last month" otherwise |
| Gems → buy freezes | Earn → protect loop | Spoons buy freezes + cosmetics |
| Reminders with personality, adaptive timing | Brings you back at the right moment | Local, learned time, rotating mascot voice, backs off |
| Onboarding commitment (why + daily goal) | Identity + consistency | "What brings you here?" + weekly goal + first win in < 2 min |
| Hearts (lives) | Monetisation via frustration | **Not copied.** Wrong answers just come back later |

**Where we do better than Duolingo:** rewards tied to real outcomes (money saved, food not wasted, meals shared,
dishes mastered — you can taste the progress); spaced repetition that actually teaches; holiday mode + a "quiet mode"
switch that hides game layers for people who don't want them; no anxiety copy; nothing to buy.

## 2. Three loops

- **Daily (≈1 min) → streak.** Any one counts: *Tonight check-in* (one tap on Today's Tonight card: "Cooking this" /
  "Leftovers" / "Eating out"), a *Kitchen Bite* (§3), or a *Made it*. Honest answers keep the ritual of opening the app
  and deciding dinner; real cooking earns far more Spoons.
- **Weekly → goal ring.** Cooks this week vs the chosen goal (Easy 2 · Regular 3 · Keen 5), 3 quests, Sunday recap.
- **Long (months) → identity.** Cooking Path units, recipe mastery crowns, chef level, cuisine passport, collection
  book, impact totals, Wrapped.

## 3. Kitchen Bites — the daily lesson

60-second sets of 3 questions. Types: pick one (with picture where possible), true/false, put the steps in order,
match (ingredient → substitute), "which pan/heat". Every answer shows a one-line *why* ("Salted pasta water seasons
the pasta from inside"). Spaced repetition (Leitner boxes): a right answer moves the card up a box and it returns after
1 / 3 / 7 / 21 days; a wrong one returns tomorrow. No lives, no fail state — a Bite always completes.
**Content:** bundled JSON per Path unit, written in our own words. Food-safety questions carry a `source` (UK FSA / NHS
guidance) and every batch is checked by a separate agent before it ships; no medical or allergy advice beyond "check
the label". v1 = units 1–3 × 8 Bites × 3 questions (~72); one more unit per release.

## 4. Cooking Path (the skill tree, owner OK 2026-11-10)

A winding vertical map (own screen, "Next on your path" card on Today). Units: 1 Kitchen basics (knife, heat,
seasoning) · 2 Eggs · 3 Pasta · 4 Rice & grains · 5 Soups · 6 Roasting · 7 Pan sauces · 8 Curry & spice · 9 Baking
basics · 10 Bread · 11 Fish · 12 Desserts · then World tours (Italy, India, Mexico, Japan, Middle East …).
Each unit = 4–6 nodes: Bites (learn) → Cook nodes (cook one of 3 suggested recipes matching the unit's technique and
difficulty; any of the cook's own recipes with that technique also counts) → finale ("Cook it for someone" or "Cook it
from memory" — cooking mode with amounts hidden until tapped). Unit done → unit badge + skill level (feeds Me 2/3's
Skills row).
Needs technique tags on the 332 bundled recipes: curated `recipe_techniques.json` + drift test (same process as the
catalog). **Recipe mastery:** cooked 1× bronze, 3× silver, 5× + rated + photo gold crown; a gold recipe can be the
cook's *Signature dish*. **Collection book:** per unit/cuisine grid — cooked dishes show their photo/art, the rest a
silhouette (completion pull). **Cuisine passport:** stamp book with a stamp-press animation.

## 5. Spoons, levels, shop

One soft currency (lifetime total = level, balance = spend). Deterministic earn table:

| Action | Spoons |
|---|---|
| Tonight check-in | 2 |
| Kitchen Bite (+3 if all right) | 5 |
| Made it · first time for this recipe · planned-then-cooked · perfect cook (every step ticked) · cooked for others | 10 · +15 · +5 · +5 · +5 |
| Kitchen item used before expiry (max 3 per cook) | +10 each |
| Weekly goal met · each quest (easy/med/stretch) · all 3 quests | 25 · 10/20/30 · +25 |
| Streak milestone 7 / 30 / 100 / 365 days | 50 / 100 / 250 / 500 |

Anti-farming: a recipe's Made it earns once per 4 h, max 3 earning cooks a day; undo removes what it earned.
**Chef levels** (lifetime): Kitchen Porter 0 · Commis 250 · Chef de Partie 1,000 · Sous Chef 3,000 · Head Chef 8,000 ·
Executive Chef 20,000, each with I–III sub-ranks so level-ups land every week or two early on. An active cook
(daily check-in, 5 Bites, 3 cooks, goal, quests) earns ≈200/week → Commis in week 1, Chef de Partie ~week 5, Sous
Chef ~week 15, Head Chef ~week 40.
**Shop:** streak freeze 50 (hold 2), streak repair 100 (one free a month), app icons, themes, badge frames, share-card
styles, mascot outfits, celebration effects. Nothing costs money; Spoons never convert to anything outside the app.

## 6. Streak rules

- A day is the local calendar day rolling at **03:00** (a late dinner still counts for "today").
- First qualifying action extends it; Today's flame animates. Missed day → a held freeze is used automatically (shown
  as ice on the streak calendar). Broken → for 48 h, *Repair*: free once a month, else 100 Spoons.
- **Holiday mode:** up to 14 days a year, set ahead in Me; the streak pauses.
- Milestones 3, 7, 14, 30, 50, 100, 200, 365 → celebrations; 365 = Streak Club frame.
- **Migration:** today's weekly cooking streak is kept as *Cook weeks* (the weekly-goal streak) with its number and
  badges unchanged. The daily streak starts on the update with 2 welcome freezes — nobody loses a number.

## 7. Moments

`CelebrationQueue`: at most **one** full-screen moment per action, by priority level-up > streak milestone > badge >
unit complete; the rest become chips on the summary. Made-it summary (the "lesson complete" screen): dish image,
Spoons count-up, flame, weekly ring, quest ticks, impact line ("≈ £8 saved vs a takeaway" — the cook sets their
typical takeaway price in Me; default £12). Four named Core Haptics patterns (tap · success · milestone · level-up);
short optional sounds (setting; silent switch respected). Reduce Motion → crossfades. VoiceOver announces every reward.

## 8. Notifications (local, opt-in, kind)

Max one a day, never in quiet hours (22:00–08:00 default). *Tonight prompt* at a learned time (median of the last 14
check-in/cook times − 60 min; default 17:00). *Streak saver* at 20:30 only when the streak is ≥ 3 and nothing happened
today. *Sunday* recap + plan. ~30 rotating copy variants in the mascot's voice, never guilt. Back-off: 3 ignored in a
row → every other day; 7 → stop and ask on next open "Keep evening reminders?". Extends `NotificationManager` /
`NotificationKind`; replaces today's `cooking-streak-lapse` reminder.

## 9. Social without our own server

Share cards (streak, level, unit done, Wrapped) everywhere a milestone lands. **Leagues — owner decision:** Game Center
recurring weekly leaderboards among Game Center friends + friend challenges would be a real Duolingo league with no
server of ours, but it sends a score + Game Center alias to Apple and needs the Game Center capability (both
guardrails). Family quests ("5 dinners together this week") ride on Shared family cookbooks (still undecided).

## 10. Onboarding commitment

New install: "What brings you here?" (learn to cook · eat better · save money · cook for family · get organised →
sets Path start + impact line) → weekly goal → reminder time → first Kitchen Bite → streak day 1, first Spoons, mascot
cheers. First win in under 2 minutes. Existing users: a one-time "Your cooking path" intro card on Today.

## 11. Architecture

- **Domain (pure):** `PlayEvent { id: UUID, date, kind }` with kinds `checkIn(choice)`, `bite(unit, lesson, right,
  total)`, `cooked(recipeID, perfect, planned, forOthers, expiringUsed)`, `questClaimed`, `freezeUsed`, `purchase`,
  `holiday(range)`, `undo(eventID)`. `PlayEngine.state(events, calendar, now) -> PlayState` (streak, freezes, Spoons
  balance/lifetime, level, week ring, quests, unlocks). Rewards = diff of state before/after an event → feeds
  `CelebrationQueue`. Pure and deterministic → exhaustive tests (week boundaries, 03:00 roll, DST, time-zone travel,
  undo, anti-farming).
- **Why an event log:** no double counting, undo is just another event, state can be recomputed after a rule change,
  and iCloud merge is a union by id — no conflicts (fits Data safety 2/4's `SyncMerge`).
- **Persistence:** `PlayEventEntity` (id, date, kind, payload JSON) in RecipeModel 18 (17 = recipe photos) — **needs owner OK** (Core Data
  guardrail). Weekly checkpoints keep derivation fast; `PerformanceBudgetTests` with 5 years (~10k events).
- **Content:** bundled `PlayContent/` JSON (bites, path, quests, notification copy) with validation tests (one right
  answer, an explanation, a unit, every path recipe id exists).
- Views read `PlayState` through an `@Environment(\.play)` `PlayManaging` seam, like the other managers.

## 12. Guardrails

Rewards only for real cooking and learning. **Chance is welcome when it's free** (owner 2026-11-13: "fun for the
sake of being fun"): never a stake (no money, no Spoons spent to play), odds printed on the machine, every spin wins a
dinner, prizes are Spoons multipliers and cosmetics; nothing is ever for sale. No paid currency; no lives;
no guilt copy; holiday mode; Settings → "Quiet mode" hides streaks, Spoons and celebrations for people who prefer a
plain recipe app. App is 4+ — no dark patterns (UK Children's Code spirit). No analytics: the owner judges feel on
TestFlight, so every Play item ships with screenshots of new-user and active-cook states.

## 13. Order

Play 1/7 foundation → 2/7 daily streak + weekly ring → 3/7 Made-it moment → Badges 2/2 → 4/7 Kitchen Bites → 5/7
Cooking Path + levels → 6/7 quests, events, notifications → 7/7 mascot, onboarding, shop. Wrapped ships by 24 Nov
independently.

## 14. Today feed + Dinner Jackpot (owner 2026-11-13)

Prototype the owner saw: https://claude.ai/artifact/GSnMHTughHYQ1LM5neVgwd (rebuild in SwiftUI, don't port the HTML).
- **Today = an endless cookbook.** Full-width Tonight hero (picture, bold name, a reason, Cook tonight · Another idea),
  then chapters forever, each with a reason line and a rotating layout (2-column picture wall · swipe row · wide
  feature): Because you loved X · Under 30 minutes · Uses what you have · Cook it again · New to you · Something sweet
  · A trip to <cuisine>. Play cards (Kitchen Bite, passport, quests) slot in between chapters. Ranked from the cook's
  library + all bundled recipes; no recipe repeats until the pool is spent, then it reshuffles. Double-tap saves.
- **Dinner Jackpot.** A slot machine card under Tonight: 3 reels of dish pictures, chunky SPIN button, reels stop
  one by one with haptic ticks. Outcome is chosen first, then animated: three of a kind (1 in 12) = JACKPOT, confetti,
  that dish for tonight at ×3 Spoons; pair (1 in 3) = ×2; no match = "tap the one you fancy" (still picks dinner).
  3 free spins a day, +1 per cook. Odds shown on the machine. Multipliers apply when the cook marks Made it that day.
