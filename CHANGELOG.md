# Changelog

What changed for you, one entry per TestFlight build, newest first. Write the entry when the change lands on `main`
(BACKLOG "How an agent works this file" step 8). The website's "Behind the build" page is generated from this file
by `tools/website-behind-the-build.py`; the team's detailed Log history is in `docs/LOG.md`.

Each entry is exactly three lines (the script checks this — run `python3 tools/website-behind-the-build.py --check`):

```
## YYYY-MM-DD · <BACKLOG item> · <commit>
- For you: one or two plain sentences on what's new or better, written for the cook (copy rule in root CLAUDE.md).
- Behind the build: one sentence on how it was made or checked — tests, reviews, what was tricky.
```

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

## 2026-11-14 · 🐞 Inbox: Reset left photo files + recent web searches · 3d042a4
- For you: Reset now also clears the photos you added and your recent web searches.
- Behind the build: two reviewers agreed on two fixes, including keeping your existing recent searches through the update.

## 2026-11-14 · 🔴 Privacy text said recipe photos stay on device (they sync since 9a44acb) · 4af4f67
- For you: the Privacy Policy and the iCloud sync switch explain clearly that recipe photos sync to your own iCloud, list everything that syncs and when sync starts and stops.
- Behind the build: two independent reviewers compared the text with the app's behaviour.

## 2026-11-14 · Data safety 2/4 slice 4b-2c (erased elsewhere while closed) · cf12e72
- For you: with iCloud sync on, a shopping list you clear on one device stays clear when you open another.
- Behind the build: a challenge pass caught a threading risk before it reached a build.

## 2026-11-14 · 🐞 Recipe facts card overlap (owner screenshot: "Intermediate" ran into "Main course") · f2cd226
- For you: the facts card on a recipe fits neatly — one row when everything fits, two when it doesn't, with words wrapping cleanly.
- Behind the build: started from a screenshot sent in from a phone; new tests cover each layout.

Earlier builds are in the Log in `BACKLOG.md` (older lines move to `docs/LOG.md`).
