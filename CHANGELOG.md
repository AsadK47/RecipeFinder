# Changelog

What changed for you, one entry per change that ships in a TestFlight build, newest first. Write the entry when the change lands on `main`
(BACKLOG "How an agent works this file" step 8). The website's "Behind the build" page is generated from this file
by `tools/website-behind-the-build.py`; the team's detailed Log history is in `docs/LOG.md`.

Each entry is exactly three lines; run `python3 tools/website-behind-the-build.py --check` before committing (it rejects
anything else between entries):

```
## YYYY-MM-DD · <BACKLOG item> · <commit>
- For you: one or two plain sentences on what's new or better, written for the cook (copy rule in root CLAUDE.md).
- Behind the build: one sentence on how it was made or checked — tests, reviews, what was tricky.
```

## 2026-11-24 · Inbox search placeholder copy · 57e10d0
- For you: Search fields across the app now share one friendly style, like "Search recipes…" and "Search foods…", so every search reads the same way.
- Behind the build: a challenger checked every search field and found one more ingredient prompt to match.

## 2026-11-24 · Inbox f952384 review: search field name + large text · 1d9a2cc
- For you: With VoiceOver, the search fields now say what they're for, like "Add or search groceries…". At the largest text sizes the prompt wraps onto more lines, so you can read all of it.
- Behind the build: a new VoiceOver test failed on the old field first; a reviewer and a challenger both found the unnamed field and the cut-off prompt at large text sizes.

## 2026-11-24 · Inbox Plan empty-night contrast · 931ade6
- For you: On Plan, a night that has passed without a dinner now reads "No dinner planned" clearly, so your week is easy to read at a glance.
- Behind the build: a new test failed on the old tile first, and before-and-after screenshots confirmed the cause; a challenger's dark-mode check led to the clearer text colour.

## 2026-11-24 · Inbox Toast VoiceOver announcement · 508a17b
- For you: With VoiceOver on, every confirmation message is now read aloud as it appears, such as "Added to groceries" or a note that a meal stayed off your plan.
- Behind the build: a new test failed on the old code first; a reviewer and a challenger both checked no message is read twice.

## 2026-11-24 · Inbox take-off toast count · 4355abd
- For you: When you take several meals off Plan in a row, the message now counts exactly the meals that came off, so a weekly dinner that stays on an earlier night isn't counted.
- Behind the build: a new test failed on the old count first; a challenger found two more miscounts (a repeated tap and a moved meal), both fixed with tests before it shipped.

## 2026-11-24 · Inbox MealPlanningManager restore skipped plans · 45dc4be
- For you: When you undo taking a meal off Plan and another meal has taken its place since, Plan now tells you which meal stayed off, so nothing disappears quietly.
- Behind the build: new tests failed on the old code first; a reviewer and a challenger reworded the message to be accurate, gave it its own calendar note and stopped it covering the Undo message.

## 2026-11-24 · Inbox placeholderCardIsOpaque flake · 2405a30
- For you: Sharing a My Cookbook page always sends the finished card with its dish art; if the picture can't be drawn, the sheet offers Try again.
- Behind the build: CI logs showed a rare empty render; a challenger turned down a first fix that would have sent it as a black card, so the card is now checked and redrawn instead.

## 2026-11-23 · Privacy policy vs public TestFlight · 1854908
- For you: The Privacy Policy now explains beta testing: what TestFlight feedback reaches the Developer, what is posted publicly to help fix it, who handles it, and how to have it removed.
- Behind the build: drafted from the feedback scripts and checked by two independent reviewers (text against code, and against UK GDPR notice needs), who caught the first draft calling the 14-day files private.

## 2026-11-23 · Inbox Toast cancel clears newer toast · ac70a1a
- For you: Taking several meals off Plan in a row now keeps the "meals taken off" message on screen with its Undo, so every meal you took off can come back with one tap.
- Behind the build: a new test failed on the old timer first; a challenger caught the first fix leaving an old Undo to reappear after leaving the screen, fixed before it shipped.

## 2026-11-23 · Inbox CookingResumeMemory host test · 5ec7f83
- For you: Cooking mode keeps picking up where you left off — the step you were on and the ingredients you ticked — now checked by tests that open the real cooking screen.
- Behind the build: the new tests were first run against a deliberately broken screen and failed, proving they notice; a challenger kept them clear of the app's own timers and settings.

## 2026-11-23 · Inbox NotificationManager coverage · 3e1525a
- For you: Reminders work as before — cooking timers, meal and Sunday planning reminders, groceries and use-it-up alerts are now each checked by their own tests, so they keep arriving with the right words at the right time.
- Behind the build: a new test seam lets every reminder be read without scheduling a real one; a reviewer and a challenger led to deleting seven unused helpers and adding a check that taps still open the right tab.

## 2026-11-23 · Inbox Settings nav bar fade · 3959ed6
- For you: Settings screens keep their title and back button clear as you scroll, even with large text — rows now fade softly under the top bar.
- Behind the build: checked on the large-text theme picker screenshot; a reviewer and a challenger went through all thirteen settings screens that share the fix.

## 2026-11-23 · Inbox DietaryInference word lists · 1ed14dc
- For you: Vegetarian and Vegan tags on built-in recipes now recognise more ingredients, from lardons, 'nduja and monkfish to feta, halloumi and crème fraîche, so new recipes are tagged with more care.
- Behind the build: new tests failed on the old lists first; a reviewer and a challenger both caught a test that confused "pomegranate" with grana padano, fixed before it shipped.

## 2026-11-23 · Inbox vegan Chapati and Chai methods · b752fc0
- For you: The built-in Chapati and Homemade Chai Concentrate now finish with plant-based choices — vegan butter or oil to brush, oat or soy milk for your cup — so every step fits their Vegan tag.
- Behind the build: a new test reads the method of every recipe tagged Vegan and failed on the old wording first; a reviewer and a challenger tightened it so a fixed exception can't hide a new dairy step.

## 2026-11-23 · Inbox WeekDinners VoiceOver hint · 533fe1b
- For you: With VoiceOver, each dinner on Plan's week photos now tells you exactly what you can do with it — cook it, move it, or take it off the plan — including weekly dinners.
- Behind the build: a reviewer and a challenger both caught the first version offering a move that weekly dinners don't have; the hint is now built from the same rules as the menu, with tests.

## 2026-11-23 · Inbox Favourites spelling · f34ca95
- For you: The recipe filter and the heart button now say "Favourites", and VoiceOver reads the Favourites switch once, by name.
- Behind the build: a reviewer checked every string and test for the old spelling and caught the switch being read twice, fixed before it shipped.

## 2026-11-22 · Inbox Sunday nudge weekly dinner · af59876
- For you: The Sunday "Plan next week's dinners?" reminder now looks at the nights a weekly dinner actually lands on, so a weekly Sunday roast no longer hides an empty Monday-to-Saturday when your week starts on Sunday.
- Behind the build: a new test failed on the old code first, then passed with the fix; a reviewer caught one test with the wrong expectation and a challenger's question about which nights count went to the owner.

## 2026-11-22 · Inbox WeekDinners past dinners · 4d5c943
- For you: Dinners you've already cooked this week stay put on Plan's week photos as a record of what you made, and VoiceOver describes exactly what you can do with each one.
- Behind the build: a reviewer spotted a rule for moving missed dinners that could never run; it was removed with tests for cooked nights and for moving tonight's dinner late in the evening, checked by a reviewer and a challenger.

## 2026-11-22 · Inbox MealPlanningManager+Series split · 2c5638a
- For you: Weekly repeating meals keep filling each new week exactly as before, including the week the clocks go back.
- Behind the build: the weekly-repeat rules moved into their own tested file, with a new test for the autumn clock change; a reviewer and a challenger found no change in behaviour.

## 2026-11-22 · Inbox CookingResumeMemory seam · cbfba3f
- For you: Cooking mode still picks up where you left off — same step, same ingredients ticked — when you close it mid-cook and come back.
- Behind the build: the resume memory now plugs into cooking mode the same way its timers do, so tests can swap in their own; a reviewer and a challenger found no change in behaviour.

## 2026-11-22 · Inbox HelpView appearance tip · a3df262
- For you: Help and the Appearance & Theme screen now read naturally in British English — colour, favourites, customise — and the appearance tip tells you exactly where to choose System, Light or Dark.
- Behind the build: a reviewer checked every help string against the real settings screens and spotted the Appearance screen still said "Color", fixed before it shipped.

## 2026-11-22 · Inbox seed dietary tags · c4e1ed7
- For you: The Vegetarian and Vegan filters now find recipes in the built-in collection — 184 vegetarian and 59 vegan dishes, worked out from their ingredients.
- Behind the build: tests showed both filters empty first; tagging errs on the side of caution, and a reviewer and a challenger read every tagged recipe's ingredients before it shipped.

## 2026-11-22 · Inbox Privacy aisle-order wording · b52d55d
- For you: The Privacy Policy now describes exactly how your aisle order is remembered — for each shop you pick, and for trips with no shop picked.
- Behind the build: two reviewers checked the new sentence against the code that learns the order, and both found it accurate.

## 2026-11-22 · Inbox plan deck pass decision · 26f4481
- For you: Plan my week works as before — dishes you pass on wait behind fresh ones next time, while Busy night and Leave open keep every dish fresh.
- Behind the build: the rule for what counts as passing a dish moved back into the tested planning model, with its two tests restored, checked by a reviewer and a challenger.

## 2026-11-23 · Search placeholder on one line · f952384
- For you: Search fields keep "What would you like to eat?" neatly on one line beside the cursor, even when Cancel appears.
- Behind the build: one shared search field across the app, so the fix reaches Recipes, Groceries and every recipe picker at once.

## 2026-11-22 · Plan take-off with Undo · fde4a2e
- For you: Take a meal off Plan with one tap on the bin beside it or a swipe — it goes straight away, weekly meals too, and Undo on the toast brings it back just as it was.
- Behind the build: two reviewers made sure Undo is easy to reach with VoiceOver and brings back several meals taken off in a row, and tests check a whole weekly series and its reminders come back.

## 2026-11-22 · Plan meals in time order · e85cf25
- For you: Each day on Plan now lists meals in the order you'll eat them — by the reminder time you set, or the usual time for breakfast, lunch, a snack and dinner — and a meal you add slots straight into place.
- Behind the build: tests showed lunch landing below dinner first; a reviewer and a challenger then made a dragged order stay on its own day and a new reminder time re-order the day.

## 2026-11-22 · Inbox Sunday nudge week · e34cec0
- For you: The Sunday evening planning nudge now follows the first day of the week your phone uses, and a tap opens the same week it asked about.
- Behind the build: tests reproduced the mismatch first, and a reviewer and a challenger both caught that the first fix also counted tonight's dinner — fixed before it shipped.

## 2026-11-22 · Inbox Stop Repeating on a later copy · 88d5ed9
- For you: Stop Repeating from any week of a weekly dinner, and every night already on your plan keeps its own reminder.
- Behind the build: tests reproduced the missing reminder first, then a reviewer and a challenger checked the fix and tightened it before it shipped.

## 2026-11-22 · Inbox restore weekly reminders · 9ab758b
- For you: After restoring a backup, each weekly dinner rings once a week at the reminder time you set on this phone.
- Behind the build: tests reproduced the double reminder first, and a reviewer and a challenger both caught a restored older reminder time that could take over — fixed before it shipped.

## 2026-11-21 · Theme palette slice 2b colour-blind symbols · 408dd08
- For you: Each colour theme now carries its own symbol — a flame for Tomato, a leaf for Herb, a heart for Raspberry and more — so every theme is easy to pick out at a glance, whatever colours you see.
- Behind the build: we checked the palette through colour-blindness simulations, chose symbols to make every theme distinct, and a reviewer swapped two shapes that looked alike at small sizes.

## 2026-11-21 · Inbox Stop Repeating crash · 4d9ef95
- For you: Stop Repeating on a weekly dinner now works smoothly every time, including for meals planned on another of your devices, and this week's dinner stays on your plan.
- Behind the build: a test reproduced the crash first, then a one-line fix made it pass, checked by a reviewer and a challenger.

## 2026-11-21 · Theme palette slice 2a accessibility · b3d81b7
- For you: The app now follows Increase Contrast with stronger colours and crisper buttons in Light and Dark, shows solid cards when Reduce Transparency is on, and the colour picker reads clearly at the largest text sizes and in VoiceOver.
- Behind the build: every contrast level is checked by a test for each theme, and a reviewer and a challenger found twelve buttons that needed to follow the new colours before it shipped.

## 2026-11-21 · Theme palette by colour theory slice 1 · a45fecd
- For you: Eight new colour themes named after food — Tomato, Saffron, Honey, Herb, Teal, Blueberry, Plum and Raspberry — spread round the colour wheel, with buttons that stay easy to read in Light and Dark. Your current theme carries over to its closest new colour.
- Behind the build: every colour was worked out with colour theory and checked by a contrast test for each theme in both modes, and a reviewer and a challenger caught buttons that needed white text before it shipped.

## 2026-11-21 · Today — decide tonight slice 3 one do-this-now nudge · 86d5811
- For you: Today now shows one thing to do next — start tomorrow's marinade tonight, or use up the spinach before it goes off — with the recipe a tap away, so Today stays calm and to the point.
- Behind the build: the choice of what comes first is a small tested model, and a reviewer and a challenger shaped it — late in the evening, tomorrow's prep now comes before food you can no longer cook today.

## 2026-11-21 · Today — decide tonight slice 2 next-meal hero · cd999ad
- For you: Today now follows your day — breakfast ideas in the morning, lunch at midday, dinner in the evening and tomorrow's breakfast once dinner is done — and a new card shows breakfast, lunch and dinner at a glance, so you can plan any of them with a tap.
- Behind the build: the meal-by-clock rules are a small tested model, and a reviewer and a challenger caught two edge cases before it shipped — a late-afternoon dessert no longer counts as dinner.

## 2026-11-21 · Today — decide tonight slice 1 browsing on Recipes · 22a48d0
- For you: Today stays focused on what to cook tonight, and Recipes → Discover is where to browse more — Keep browsing takes you straight there, even on nights with no pick ready.
- Behind the build: about 250 lines came out of Today, and a reviewer and a challenger checked that everything it showed still has a home in Discover.

## 2026-11-21 · Smell Batch E recipe-writes split · 46d6749
- For you: everything works as before — this build tidies how recipes are saved behind the scenes, making room for upcoming features to land smoothly.
- Behind the build: one long file became three focused ones with every line of code carried over unchanged, checked line by line by a reviewer and a challenger.

## 2026-11-21 · Groceries writes itself slice 4 still got the coriander · 3f81c28
- For you: Groceries now checks in on fresh food your plan is counting on — "Still got the coriander?" — so herbs, milk or chicken that have been at home a while make it onto your list when you need them. One tap answers, and the ✕ asks you later.
- Behind the build: a small tested model decides what's worth asking about, and a reviewer and a challenger made sure it asks about fresh coriander, leaves onions, eggs and butter in peace, and never doubles your list.

## 2026-11-21 · Groceries writes itself slice 5 delete duplicates · 39bf095
- For you: To buy and At home now share one tidy aisle header, so folding an aisle looks and works the same on both sides, and shopping for your plan lives in one place — the From your plan card in Groceries.
- Behind the build: two copies of the same screen piece became one, the app got about 150 lines smaller, and a reviewer and a challenger checked nothing a cook uses went missing.

## 2026-11-21 · Inbox 🟡 Reset clears preferences · 216eb49
- For you: Reset App to Default now gives you a true fresh start — your settings and colour theme return to their defaults too, while your iCloud sync choice stays as you set it.
- Behind the build: a new test reads the app's own code and fails if a future setting would be missed by Reset, and a reviewer plus a challenger checked it against the Privacy Policy.

## 2026-11-20 · Inbox 🟡 Shop mode keep-awake re-hold · ac8a211
- For you: I'm in the shop keeps your screen on after you check a message or lock the phone mid-trip, and your Keep Screen Awake setting stays as you set it when you leave.
- Behind the build: cooking and the shop now share one small tested model for holding the screen awake, and a reviewer and a challenger both caught the same edge case before it landed.

## 2026-11-20 · 🐞 Meal planning is buggy · 0acb4fd
- For you: Plan my week is always one tap away — on Plan and from Today — and moves on to next week once this one is planned. Clear Past Plans and a swipe tidy your week, past days show what you cooked, tapping a dinner opens its recipe, and weekly meals now stop cleanly with one friendly reminder a week.
- Behind the build: two separate bug hunts, a deep review and a challenger found fifteen fixes, and every bug got a test that was seen failing before it was fixed.

## 2026-11-20 · Inbox 🟡 Keep screen awake · 7e70ceb
- For you: turn on Keep Screen Awake in Settings › Display and your screen stays on whenever RecipeFinder is open, so a recipe stays readable while your hands are busy — and it stays on after you finish cooking mode too.
- Behind the build: the switch is applied by a small tested model at the app's root, and a reviewer plus a challenger checked it can't fight cooking mode or the shop over the screen.

## 2026-11-20 · Groceries writes itself slice 3 aisle order · 9dda50b
- For you: I'm in the shop now learns the way you walk each shop — after a trip, your list and shop rows come in the order you usually pick things up, so the next shop flows aisle by aisle.
- Behind the build: the learning is a small tested model kept on your device and listed in the Privacy Policy, and two separate reviewers made sure a mis-tap, a quick top-up trip or ticking at the checkout can't scramble it.

## 2026-11-20 · Groceries writes itself slice 2 I'm in the shop · 1505253
- For you: tap I'm in the shop on your groceries list for big, easy-to-tap rows in aisle order, with the screen staying on while you shop. Tap Done at the end and everything you ticked moves to At home.
- Behind the build: the trip is a small tested model, and two separate reviewers made sure Done at one store leaves the other stores' ticks where they are.

## 2026-11-20 · Groceries writes itself slice 1 plan → list · 257c72b
- For you: plan a few dinners and Groceries offers everything they need in one tap — scaled to your servings, skipping what's at home or already on your list. When you're back from the shop, Put Checked Items Away moves what you bought to At home.
- Behind the build: the shopping maths is a small tested model shared by Plan and Groceries, and two separate reviewers caught five things to fix first — like a big week of chicken that could never fit on one line.

## 2026-11-20 · Plan — swipe to match slice 4 30-day memory · 47a3e95
- For you: Plan my week now remembers the dishes you pass on for a month, so next week's cards lead with something fresh — and a passed dish still turns up when it's the best one left.
- Behind the build: the memory is a small tested model kept on your device and listed in the Privacy Policy, and two separate reviewers made it save each pass straight away and tidy up after 30 days.

## 2026-11-20 · Inbox 🐞 Sunday Planning denied · 9a01bb5
- For you: turn on Sunday Planning with notifications off for RecipeFinder and the switch now tells you straight away — it goes back off with a note that takes you to Settings, so it always shows what you'll really get.
- Behind the build: a UI test taps Don't Allow and checks the switch and note; it was seen failing before the fix, and two separate reviewers checked the change.

## 2026-11-20 · Plan — swipe to match slice 6 busy nights · 6f5d2eb
- For you: tap Busy night on a Plan my week card and that night's ideas switch to quick dishes — the shortest cooks come up first, and the rest of your week keeps its usual picks.
- Behind the build: the busy-night ranking is a small seeded model with 13 new tests, and two separate reviewers tightened the ordering and made the card fade rather than look like it was planned.

## 2026-11-20 · Plan — swipe to match slice 5 Sunday nudge · 6954ab2
- For you: turn on Sunday Planning in Settings › Notifications and, when next week's dinners are still open, a Sunday-evening nudge takes you straight to Plan on that week so you can sort it in a minute.
- Behind the build: the when-to-nudge rule is a small tested model, clock change included, and two separate reviewers found four things to tighten — like the tap opening next week rather than the one ending tonight.

## 2026-11-19 · Plan — swipe to match slice 2 week photos · 06094b2
- For you: Plan now shows your week as seven dinner photos — tap one to start cooking it, hold it to move it to another night or swap two nights, and tap an empty night to pick its dinner.
- Behind the build: the move and swap rules are a small tested model, and two separate reviewers caught a swap that could push a dinner into the past before it landed.

## 2026-11-19 · Plan — swipe to match slice 1 deck · 23134c8
- For you: tap Plan my week and swipe through big dinner cards, one for each open night — swipe right to plan it, left for another idea. Quick dishes come up on weeknights, longer cooks at the weekend, and anything using up what's in your kitchen comes first.
- Behind the build: the picking rules are a small seeded model with 29 tests, and two separate reviewers found ten things to tighten, from VoiceOver focus to a quick double tap.

## 2026-11-19 · Cooking flow slice 4 last step → Made it · c1cafb8
- For you: finish the last step in cooking mode and you go straight to your Made it moment — cook number, streak, rating and a photo, one tap from the end.
- Behind the build: a UI test now cooks a recipe from the first step to Finish and checks the celebration opens, then finishes again to check a same-day repeat is handled kindly.

## 2026-11-19 · Cooking flow slice 3b named timers · 4d04ae3
- For you: run several timers at once in cooking mode — each step's timer appears as a named pill like "Rice 12:00" that stays in sight as you move through the steps, with pause, add a minute and stop a tap away.
- Behind the build: the timer rules were built as a small tested model with time passed in, then checked by two separate reviewers who found six things to tighten before it landed.

## 2026-11-19 · Cooking flow slice 3a resume · 7a3d86e
- For you: step away from cooking mode mid-recipe and come back — it opens at the step you left, with your ingredients still ticked.
- Behind the build: a recipe edited in between starts from the top so you never land on the wrong step, checked by unit tests and a UI test that leaves and reopens.

## 2026-11-19 · Cooking flow slice 2 step ingredients · 0e81fd8
- For you: in cooking mode each step now shows the ingredients it uses with their amounts, so you can keep cooking without flipping back to the list.
- Behind the build: the matching was tested on all 332 bundled recipes and tuned so "sesame oil" or "garlic powder" never shows up as plain oil or garlic.

## 2026-11-19 · Smell Batch D screen 3 · 7f4580c
- For you: cooking mode works just as before — ingredient checklist, step timers and the "Nice cooking!" finish — on tidier code that's ready for the next round of cooking improvements.
- Behind the build: the screen was split into small parts with step timers and checklist amounts pinned by tests first, then checked by two separate reviewers.

## 2026-11-19 · Inbox 🟡 quick snack difficulty · 0df3dc4
- For you: quick snacks you add to your plan now show as Basic — one difficulty bar — and turn up when you filter for Basic.
- Behind the build: a new test was seen failing on the old code before the fix, then the snack recipe was built in one tested place.

## 2026-11-19 · Inbox 🟡 active filter chips difficulty order · 9cac1cd
- For you: the filter chips above your recipes now show difficulty easiest first — Basic, Intermediate, Expert — matching the filter sheet.
- Behind the build: the chips read the same shared list as the filter sheet and editor, with tests that every chosen difficulty keeps its chip in order.

## 2026-11-18 · Inbox 🟡 difficulty bars · 532ecc7
- For you: the difficulty bars on recipe cards now match the level — one bar for Basic, two for Intermediate, three for Expert.
- Behind the build: the bars now read the same three levels the editor and filters use, with a test that each level fills one more bar than the last.

## 2026-11-18 · Inbox 🟡 difficulty order · 599cf90
- For you: the Recipes filter now lists difficulty easiest first — Basic, Intermediate, Expert — the same order you pick it in when adding a recipe.
- Behind the build: both screens now share one list, and tests check its order and that every difficulty a recipe can have is one the filter can find.

## 2026-11-18 · iOS 27 SDK warnings · bd96990
- For you: alerts, the photo picker button and Today's "recipe link on your clipboard" card work as before, now on code that's ready for future iOS updates.
- Behind the build: Xcode 27 flagged three spots that later versions will reject; each was rewritten with the same behaviour, pinned by new tests, and the build now finishes with no warnings.

## 2026-11-18 · Build with Xcode 27 / iOS 27 SDK · 6608835
- For you: RecipeFinder is now built with Apple's latest iOS 27 tools, keeping it ready for the App Store while it still runs on iOS 17.5 and later.
- Behind the build: every check now runs on Xcode 27; two spots that its stricter compiler couldn't read quickly were rewritten with the same results, and two reviewers made sure uploads can't use a beta Xcode.

## 2026-11-18 · Smell Batch D screen 2 · eaaccc2
- For you: Recipes works just as before — search, filters, Discover and recipes you share from other apps now have their own tidy code.
- Behind the build: tests pin how shared links and recipes are saved, opened or kept for later, and a reviewer and a challenger compared the move line by line before it built green on Xcode 27.

## 2026-11-18 · Smell Batch D screen 1 · d52b80d
- For you: Plan works just as before — adding the week to Groceries, the day's empty states and moving between weeks now have their own tidy code.
- Behind the build: tests pin every Groceries message and which empty state each day shows, including a clock-change day, and a reviewer and a challenger compared the move line by line.

## 2026-11-18 · Me with character slice 4b · 40253df
- For you: Me now tells "Your cooking story" — your first cook, meal milestones, weeks in a row and the badges you've earned, newest first, with this year's meal count on top; tap a badge to see it on your shelf.
- Behind the build: two reviewers caught an earned badge that could go untold and a busy import day crowding out your cooking; both fixed and tested, and the timeline was checked on a seeded cook's screenshot.

## 2026-11-18 · Inbox 🐞 sweet chilli in a recipe name · d92e13c
- For you: "Your taste" now reads a Sweet Chilli Chicken or Mild Chilli Beef for what it is, so the spicy share reflects dishes that bring real heat.
- Behind the build: a reviewer spotted the name rule missing the sweet-chilli check the ingredients already had; the new test was seen failing first, and a challenger caught hyphenated "Sweet-Chilli" too.

## 2026-11-18 · Me with character slice 4a · 0dd898f
- For you: Me now shows "Your taste" — what you love to cook, as a shape and five rows (spicy, comforting, quick, baking, fresh), built from the meals you've made; tap a row to see the recipes behind it.
- Behind the build: two reviewers ran the rules over all 332 bundled recipes and caught pancakes counting as baking and dried spices as fresh, fixed and tested before it shipped.

## 2026-11-18 · Me with character slice 3 · 82d238c
- For you: your Profile now leads with the medals you've earned, newest first, then "Next up" — the three badges you're closest to, each with a ring and how far along you are; the whole shelf opens with See all.
- Behind the build: a challenger caught Next up filling with three steps of the same badge (hiding your first cook) and a badge from Today vanishing once its card closed — both fixed and tested before it shipped.

## 2026-11-18 · Me with character slice 1b · 1acdedc
- For you: tap your name on Me to change it right there, and your full name and photo form now sits in Settings › Profile, leaving Me's profile for your badges and chef type.
- Behind the build: a reviewer and a challenger both caught a test that could pass with saving broken and a two-word first name like "Mary Ann" being split, fixed before it shipped.

## 2026-11-17 · Kitchen you can find slice 2 · f8960bb
- For you: Today's "Use it up" and "Fits your kitchen" now have a "Your kitchen →" link that opens Groceries on At home, and tapping an "In kitchen" tag on your shopping list takes you to what you already have.
- Behind the build: a reviewer and a challenger both caught the ingredient count including items it didn't show, fixed before it shipped; screenshots follow the link from Today to the spinach waiting at home.

## 2026-11-17 · Kitchen you can find slice 1 · 6f924c9
- For you: Groceries now has a To buy | At home switch at the top, so your kitchen is one tap away — add what you have at home right from the same field, and an expiry reminder opens straight to it.
- Behind the build: a reviewer and a challenger checked that adding an item already in your kitchen keeps it, and an accessibility audit caught the whole app redrawing on a settings change, fixed before it shipped.

## 2026-11-17 · Me with character slice 1 · 57fae8c
- For you: Me now opens with your own hero card — your photo or initials on your chef type's colour, your name, and how many meals you've cooked, your week streak and the cuisines you've tried.
- Behind the build: the numbers come from the same counts as your badges so they always agree, and a reviewer and a challenger reshaped it — "meals" rather than "dinners", since every cook counts.

## 2026-11-17 · Smell Batch C · e39fe71
- For you: filter, grocery-store and status chips look and work just as before, and now share one style so they stay consistent as the app grows.
- Behind the build: four copies of the same chip styling became one, and a challenger checked each swap kept every colour and spacing identical.

## 2026-11-17 · Tester feedback 1 slice 3 · d7bf8f7
- For you: paste or share a recipe in French, Spanish, Italian, German, Portuguese, Japanese or Arabic and it comes in with its ingredients, amounts, steps, servings and times in place — "2 EL Olivenöl", "醤油 大さじ2" and "٢ ملعقة كبيرة" all read as tablespoons.
- Behind the build: nine real-style recipes in seven languages are now import tests, and a reviewer and a challenger hunted for English recipes that might read differently — brand names like "De Cecco" and "El Paso" stay whole.

## 2026-11-17 · 🐞 Inbox: opening a recipe file · 642f8b6
- For you: recipe files someone shares with you open straight from Files and iCloud Drive, and if one is still downloading the app tells you to give it a moment and try again.
- Behind the build: new tests failed on the old code first; two reviewers checked the file handling, and the app now reads shared files in the background with a sensible size limit.

## 2026-11-17 · Tester feedback 1 slice 2 · 7f8e5b1
- For you: on Today, tap the next badge under "Your cooking" to jump to it on your trophy shelf in Me, with its card open showing how close you are and where to earn it.
- Behind the build: a reviewer and a challenger both spotted that the badge card could open too early while Me was still sliding in, so it now waits a moment; a new UI test taps the row twice and checks the right badge opens.

## 2026-11-17 · Smell Batch A slice 4 · 2ce0a78
- For you: recipe pages work just as before — adding to Groceries, Made it, ratings and cook photos now have their own tidy code, which finishes the recipe page tidy-up.
- Behind the build: tests pin the one-cook-a-day rule and every Groceries message, and a reviewer and a challenger compared the move line by line.

## 2026-11-17 · Smell Batch A slice 3 · 2f6ade8
- For you: recipe pages look and work just as before — the facts card (prep, cook, difficulty, category, cuisine) and your notes now have their own tidy code, ready for what's next.
- Behind the build: tests pin every fact's words, icon and colour plus the "View Original" link, and a reviewer and a challenger compared the move line by line.

## 2026-11-17 · Smell Batch A slice 2 · 0a1dfc9
- For you: recipe pages work just as before — the cooking timer and your cook history now have their own tidy code, so the timer updates smoothly without redrawing the whole page.
- Behind the build: tests pin every word on the timer button and cook-history card, and a reviewer and a challenger compared the move line by line; the challenger added tests for how a one-tap timer splits hours and minutes.

## 2026-11-16 · 🟡 Inbox: Keep browsing leaves a recipe open · 877d75a
- For you: "Keep browsing" on Today now takes you straight to Discover, even when you'd left a recipe open on Recipes.
- Behind the build: a new UI test opens a recipe, taps Keep browsing and checks the recipe closes; it failed on the old code first.

## 2026-11-16 · Tester feedback 1 slice 1 · 3ed805c
- For you: a recipe with a cuisine shows a "More Italian recipes" button under its name — tap it to see every Italian recipe you have. Set the cuisine with the times and category, and imported recipes bring a clean cuisine with them.
- Behind the build: two reviewers caught that the button could leave you on the recipe and that "Italian" and "italian" counted twice; both are fixed and a UI test taps the button end to end.

## 2026-11-16 · 🟡 Inbox: nutrition 0 g → 0% RI · 23d2025d
- For you: the Nutrition card reads 0% for anything a recipe doesn't contain, like salt in a salt-free dish, so the label matches what's on the plate.
- Behind the build: new tests failed on the old code first, and a challenger added checks so odd numbers can never crash the label.

## 2026-11-16 · Smell Batch A slice 1 · 9fc278a
- For you: recipe pages work just as before, with tidier code behind the Nutrition card so it's easier to keep improving.
- Behind the build: every line of the nutrition label — value, unit and reference intake — is now checked by tests, and a reviewer and a challenger compared the move line by line.

## 2026-11-16 · My Cookbook slice 3 · 0adbf0b
- For you: share any page of your cookbook — tap the share icon on a dish and send a picture of it, with your photo, when you made it and your stars, to anyone you like.
- Behind the build: a reviewer and a challenger found eight things to fix first, from sharper landscape photos to a darker shade under the name, and new tests check the picture itself.

## 2026-11-16 · My Cookbook slice 2 · dde3797
- For you: Me opens on your cookbook with a row for you underneath — your name, photo, cooks this year and badges earned. Tap it for your profile and trophy shelf; View all badges takes you straight there.
- Behind the build: a reviewer and a challenger found seven things to fix first, including a VoiceOver label that read out a slash.

## 2026-11-15 · My Cookbook slice 1 · 53fb4b1
- For you: Me now opens on My Cookbook — a full page for every dish you've cooked, with your photo (or the recipe's picture), how many times you've made it and your stars. Tap a page to cook it again.
- Behind the build: a reviewer and a challenger found nine things to fix first, and pages grow with your text size.

## 2026-11-15 · Made-it moment · e48fd5c
- For you: finishing a recipe now celebrates properly — the dish pops in with a tick, you see how many times you've made it and your cooks this week, with confetti and a haptic of its own.
- Behind the build: the moment follows Reduce Motion, and VoiceOver hears it as one summary.

## 2026-11-15 · 🐞 Inbox: View-all badge UI test red · 732ec22
- For you: on a new install, Welcome Aboard joins your badges quietly, and View all badges takes you straight to your trophy shelf.
- Behind the build: the cause came from the failing test's accessibility tree, and a new test failed before the fix and passes with it.

## 2026-11-15 · Inbox 🟡 ephemeral link import · 7041540
- For you: recipe sites you import from keep their cookies in memory while the app is open, and Reset clears what the app kept from earlier builds.
- Behind the build: a test now checks cookies in a separate jar so it can tell when they leak.

## 2026-11-15 · Discovery perf budget (main red at 0.565 s) · 19250ff
- For you: Recipes opens and updates faster, especially with a big library.
- Behind the build: a speed test with 300+ recipes keeps it fast; the fix made the code quicker rather than loosening the test.

## 2026-11-15 · Recipes — endless discovery · 2b6847f
- For you: the Recipes tab now keeps going — below your library come chapters like Under 30 minutes, Dinner ideas and New to you, in changing layouts, for as long as you like to scroll.
- Behind the build: tested so each recipe waits its turn before coming back, and screenshotted three screens deep.

## 2026-11-15 · Cooking flow slice 1 (ingredient ticking) · 85bfddf
- For you: tap an ingredient to tick it off — ticked ones settle into "Got it" at the bottom, and when everything's ticked you're asked if you're ready to start cooking. Hold a row to edit its amount.
- Behind the build: a reviewer and a challenger found nine things to polish, from rows moving under your finger to VoiceOver actions.

## 2026-11-15 · 🐞 #16 froze on badge reveal after a web import with sync on · aed7309
- For you: with iCloud sync on, importing a web recipe right after opening the app runs more smoothly while a badge appears.
- Behind the build: the likely cause was fixed, and slow steps now leave a note in the device log so anything left is quicker to find.

## 2026-11-15 · Inbox 🟡 privacy §5.1 recent searches + policy audit · 037a8ea
- For you: the Privacy Policy is dated 15 Nov 2026 and explains in more detail what's kept on your phone and what goes to your own iCloud; the web search screen says your recent searches stay on this device.
- Behind the build: two separate reviewers checked every claim in the policy against the code.

## 2026-11-15 · Inbox 🔴 photo files kept on other devices after a Reset elsewhere · e67da6f
- For you: with iCloud sync on, a Reset on one device also clears your recipe photos from your other devices the next time they open the app.
- Behind the build: a guard keeps any photo that hasn't reached iCloud yet, so everything unsent stays safe.

## 2026-11-15 · Inbox 🔴 store history purged while sync is off · 8be3cb1
- For you: recipes you delete while sync is off stay deleted on your other devices when you turn it back on, even weeks later.
- Behind the build: history is tidied up to the last finished iCloud upload, so every change is sent first.

## 2026-11-14 · 🐞 Inbox: photo removals made while sync is off never reached iCloud · 4b28065
- For you: a photo you remove while sync is off is removed from your other devices once sync is back on.
- Behind the build: two reviewers checked it, and their shared note became the next fix above.

## 2026-11-14 · Inbox 🔴 cook history came back after a Reset elsewhere (sync on) · 29addf7
- For you: with iCloud sync on, a Reset on one device keeps your cooking streak fresh on your other devices too.
- Behind the build: two reviewers agreed on the fix — the on-device copy now follows the synced library every time it loads.

## 2026-11-14 · 🐞 Inbox: Reset left photo files + recent web searches · 3d042a4
- For you: Reset now also clears the photos you added and your recent web searches.
- Behind the build: two reviewers agreed on two fixes, including keeping your existing recent searches through the update.

## 2026-11-14 · 🔴 Privacy text said recipe photos stay on device (they sync since 9a44acb) · 4af4f67
- For you: the Privacy Policy and the iCloud sync switch explain clearly that recipe photos sync to your own iCloud, list everything that syncs and when sync starts and stops.
- Behind the build: two independent reviewers compared the text with the app's behaviour.

## 2026-11-14 · Data safety 2/4 slice 4b-2c (erased elsewhere while closed) · cf12e72
- For you: with iCloud sync on, a shopping list you clear on one device stays clear when you open another.
- Behind the build: a challenge pass caught a threading risk before it reached a build.

## 2026-11-14 · Data safety 2/4 slice 4b-2b (fold same shopping/kitchen item from two devices) · ab755c3
- For you: with iCloud sync on, adding "Eggs" on two devices gives you one line on your shopping list, with the larger amount.
- Behind the build: a two-step merge keeps every amount safe when both devices tidy up at the same moment.

## 2026-11-14 · Data safety 2/4 slice 4b-2a (photo deletes reach iCloud) · 481cd33
- For you: with iCloud sync on, a recipe or photo you delete on one device stays deleted on your others.
- Behind the build: a review caught a clean-up that could have removed photos after a failed download; the design changed so deletes happen at the moment you make them.

## 2026-11-14 · Data safety 2/4 slice 4b-1 (recipe photo sync, RecipeModel 17) · 3c995f9
- For you: with iCloud sync on, recipe photos you add or replace appear on your other devices too.
- Behind the build: the library upgrades in place on launch, with every recipe kept.

## 2026-11-14 · 🐞 Recipe facts card overlap (owner screenshot: "Intermediate" ran into "Main course") · f2cd226
- For you: the facts card on a recipe fits neatly — one row when everything fits, two when it doesn't, with words wrapping cleanly.
- Behind the build: started from a screenshot sent in from a phone; new tests cover each layout.

## 2026-11-14 · Data safety 2/4 slice 3b-2b (opt-in iCloud sync switch + Privacy §7) · a4ee07f
- For you: a new "Sync with iCloud" switch in Me → Settings → Data Management keeps your recipes, plans and lists in step across your devices, using your own iCloud. It takes effect the next time you open the app.
- Behind the build: a challenge pass made sure your choice survives a Reset and that the Privacy Policy matches what syncs.

Earlier builds are in the Log in `BACKLOG.md` (older lines move to `docs/LOG.md`).
