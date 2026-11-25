# January launch plan

Owner OK 2026-11-22. Target: **App Store release Monday 4 January 2027** (New Year = peak season for meal planning).
This file sets the order of work until launch; `BACKLOG.md` → Roadmap points here. What blocks a release is defined
in `SHIP_BAR.md`.

## Dates
| When | What |
|---|---|
| Now → 13 Dec | Build the must-ship list below, one item at a time per lane |
| 14 Dec | **Feature freeze** — after this only bugs, copy and App Store assets |
| 14–17 Dec | Full test pass: UI tests, fresh-install check, testers on the latest build |
| **18 Dec** | **Submit to App Review**, release set to *manual* (Apple's review slows over Christmas) |
| 4 Jan 2027 | Press release in App Store Connect; launch posts (see Marketing) |

## Must ship (in order; bugs and Inbox 🔴/🐞 always go first)
1. **Cooking flow** — one step per screen, timers, resume, "Get ready" step 0, calmer motion (Phase 1 finish).
2. **Recipes in our own words** — rewrite every built-in recipe's method (legal blocker). Runs as its own lane.
3. **Recently deleted** — built and green; lands once the owner deploys the CloudKit schema.
4. **Settings tidy-up** (Me 3/3) — audit, then the new layout with search and row values.
5. **Your diet, everywhere** — "How you eat" profile, allergens inferred from ingredients, applied to picks.
6. **Share a recipe as a card** + App Store rating prompt after Made it (Growth loops slices 1 and 5).
7. **Discover polish** — "Pick one for tonight" cards, scroll-to-top, keep position.
8. **Kitchen you can find** — To buy | At home on Groceries.
9. **Supply-chain + CI hardening** — locked package versions, pinned actions, SECURITY.md.
10. **Launch kit** — App Store screenshots, description, keywords, privacy label, press kit page.

## After launch (in rough order)
Smart search → Ask the kitchen · Theme palette + accessibility · Import torture tests · Groceries by recipe and
"Use soon" · Plan skip-a-week · Growth loops 2–4 (shared recipe web page, Made-it share, invite) · Friends' kitchen
(owner call) · Xcode 27 / iOS 27 SDK (**hard deadline March 2027**).

## Owner tasks
- ✅ 2026-11-25: CloudKit schema deployed to Production for RecipeModel 17 (all 11 `CD_` record types). Unblocks item 3.
- **Before `agent/recently-deleted` lands:** run that branch from Xcode with sync on (model 18 adds `deletedAt`), take a
  recipe off so the field reaches Development, then CloudKit Console → Deploy Schema Changes again.
- **By 1 Dec:** recruit 10–20 testers (friends who cook, LinkedIn, r/TestFlight); the public link now always has a
  fresh build.
- **By 14 Dec:** approve the App Store text and screenshots agents prepare; confirm price (free).
- **4 Jan:** post on LinkedIn, Product Hunt, Hacker News (Show HN), r/iosapps; email the website waitlist.

## Marketing
Lead with the magic moment: paste a messy link → clean recipe with a picture, then the endless Discover scroll.
Short screen recordings (15 s) for TikTok/Reels/LinkedIn; story: "private by design, open source, made for home
cooks". Keywords: recipe keeper, meal planner, grocery list, recipe organiser.
