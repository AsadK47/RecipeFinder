# Challenges — the devil's advocate

Written by the **daily challenger** scheduled task (owner 2026-11-11: "challenge aggressively and frequently"),
which assumes every change and rule is wrong until the evidence says otherwise, and by the per-item challenge pass
(BACKLOG step 6d). Its job is to argue *against* how this
project works, not to review code line by line: CLAUDE.md rules, BACKLOG priorities and guardrails, WORK.md
Decisions, architecture, CI, test quality ("would this test fail if the feature broke?"), UX assumptions and
anything that looks outdated. Every run it asks, of what changed and of the wider app:
- **Break it** — what if I did this? (hostile/odd input, offline, killed mid-save, huge data, accessibility extremes)
- **Attack it** — does this guard against injection? (web pages, pasted/OCR text, shared files and zips, deep links,
  WKWebView, prompt injection into the on-device model)
- **Simplify it** — what is the simplest version? Are we making it too complex? Why can't it be simpler?
- **Delete it** — what happens if we simply remove this entirely? Who would notice?
- **Tests** — would this test fail if the feature broke?

Each challenge must carry evidence (file:line, a run, a screenshot, a measured number,
or a current Apple/Swift doc) — opinion alone isn't a challenge.

The owner answers each one: **Accept** (it becomes a BACKLOG item or a rule change), **Reject** (with one line why —
the challenger must not raise it again unless the evidence changes) or **Later**.

Format, newest first:

```
## YYYY-MM-DD
- ⚔️ [Break|Attack|Simplify|Delete|Tests|…] <what we assume> — <why it may be wrong, with evidence> — <alternative> — cost if we're wrong: <…>
  → Owner: Accept / Reject (<why>) / Later
```

## Playbook — established methods, not ad-hoc questions

Pick the methods that fit what's being challenged; every run covers at least **1, 2, one of 3–5, 6 and 7**.

1. **Key Assumptions Check** (CIA *Tradecraft Primer*; Red Team Handbook). List the assumptions the change or rule
   rests on; rate each *solid / caveated / unsupported*; challenge the unsupported ones with evidence.
2. **Premortem** (Gary Klein; Red Team Handbook). "It's three months later and this failed for a real cook — why?"
   Write the top causes and whether any test, screenshot or check would have caught them.
3. **Threat model — Shostack's four questions** (What are we working on? What can go wrong? What are we going to do
   about it? Did we do a good job?) with **STRIDE** at each trust boundary: Spoofing, Tampering, Repudiation,
   Information disclosure, Denial of service, Elevation of privilege. Boundaries here: web pages/JSON-LD, pasted and
   OCR text, shared files and zips, deep links, share extension + App Group, WKWebView, backups, on-device model.
4. **OWASP MASVS v2.1** (with the MASTG test guide) — the mobile app checklist, by category: STORAGE, CRYPTO, AUTH,
   NETWORK, PLATFORM, CODE, RESILIENCE, PRIVACY. Ask which controls a change touches and whether they still hold.
5. **OWASP Top 10 for LLM Applications** (2026 edition; prompt injection is #1) for anything using the on-device
   model. Assume instructions can be bypassed: model output is untrusted data, never an action; check what a
   hostile recipe page or caption could make it produce.
6. **Break it — Heuristic Test Strategy Model, SFDIPOT** (James Bach): vary **S**tructure, **F**unction, **D**ata
   (empty, huge, odd units, emoji/RTL, duplicates), **I**nterfaces (share sheet, files, clipboard, deep links),
   **P**latform (iOS versions, Apple Intelligence on/off, low storage), **O**perations (how cooks really use it —
   offline, interrupted, VoiceOver, largest text) and **T**ime (timezones, midnight, killed mid-save, two at once).
7. **Simplify it / Delete it** — YAGNI and KISS, checked against **Chesterton's fence**: before recommending removal,
   say why the thing exists (git log/blame); then ask what problem it solves, for whom, how often, what the smallest
   design is, and what is lost if it's deleted outright.
8. **Would the tests notice?** — a mutation-testing mindset: name a one-line bug in the code under test and say
   whether any test would fail. If none would, that's a finding.

<!-- challenger appends below this line -->

## 2026-11-11 (item pass: Today+ 1/3 slice 1 — fixed: ambiguous `quickMinutes`, shuffled pick repeated on shelves, shuffle index drifting on refresh, night-time copy, unused eat-time storage)
- ⚔️ [Time] The Tonight line is computed when Today re-renders — TodayView.swift `content(_:)` reads `Self.now()` in body; left open, "Start by 5:40" still shows at 5:55 — `TimelineView(.everyMinute)` around the line — cost if wrong: stale advice until the next state change.
  → Owner:
- ⚔️ [Break] "Cook this" + "Shuffle" share one HStack (TodaySections.swift hero card) with no large-text fallback — `ViewThatFits` → VStack, plus an AX-size screenshot — cost if wrong: squeezed buttons at AX3–AX5 on SE width.
  → Owner:
- ⚔️ [UX] "Quick tonight? 12 under 30 min" counts every quick recipe but Shuffle reaches 3 and the line isn't tappable — make it open a filtered list (Today+ later slice) — cost if wrong: a number that promises more than it shows.
  → Owner:

## 2026-11-11 (item pass: Today+ 1/3 slice 2 — fixed: eat-time picker vanished once the time passed / for untimed recipes and sat on lines it didn't change (now a separate "Dinner at" pill), late dinners lost their start line at 6pm, VoiceOver read the timing twice, three pills with no large-text fallback)
- ⚔️ [Tests] TodayView passing the stored `eatAt` into `TonightTiming.line` is only checked by the Screenshots UI test (not in push CI) — a view-model seam would let a unit test catch it — cost if wrong: picked time silently ignored until the nightly run.
  → Owner:
- ⚔️ [Locale] "8 pm" / "Start by 5:40" are spoken 12-hour by spec; 24-hour locales still see them — `Date.FormatStyle` if owner wants locale times — cost if wrong: reads oddly outside UK/US.
  → Owner:

## 2026-11-12 (item pass: Today+ 2/3 slice 1 — fixed: two ranking tests passed with their rule deleted, item skipped once rows were full though a shown recipe used it, device-locale list/weekday mixed into English copy, seeded UI-test items kept stale dates on a reused simulator)
- ⚔️ [Matching] "Use it up" reuses the shared-word matcher, so expiring "Milk" can pair with "coconut milk" and "Chicken stock" with "chicken breast" — exact-term match for expiring items if owner sees odd pairs — cost if wrong: a pairing that doesn't use the item.
  → Owner:
- ⚔️ [Smell] `UseSoon` re-derives days-to-expiry (with injected now/calendar) beside `KitchenInventoryModel.daysUntilExpiry` (Date()/Calendar.current), and the Plan tab's `PantryExpirySuggestions` is a second expiry→recipe matcher — consolidate in a Smell pass — cost if wrong: Kitchen and Today disagree on "soon".
  → Owner:
- ⚔️ [Time] Today left open past midnight keeps "tomorrow" until the next refresh (same as the Tonight line) — refresh on `.NSCalendarDayChanged` — cost if wrong: one stale day word.
  → Owner:

## 2026-11-12 (item pass: Today+ 2/3 slice 2 — fixed: recurring dinners showed as empty and could be planned over, overnight-backgrounded "Plan it" dated today, "Plan it" could replace an existing dinner, date circles clipped at AX sizes; review: Voice Control label, picker empty-state action)
- ⚔️ [Flow] Tapping a planned day opens Plan on today, not the tapped day (no date deep link) — pass the date through `onOpen(.plan)` — cost if wrong: tap Saturday, land on Thursday.
  → Owner:
- ⚔️ [Structure] Two week-strip looks: Plan's per-meal coloured dots on calendar weeks vs Today's single dot on a rolling 7 days — shared `DayCell` in a Smell pass — cost if wrong: "planned" reads two ways.
  → Owner:
- ⚔️ [Tests] Which day "Plan it" uses and the Tonight exclusions are wired in TodayView (only the nightly UI test covers the view) — view-model seam — cost if wrong: plans tonight instead of tomorrow, caught late.
  → Owner:

## 2026-11-12 (item pass: Today+ 3/3 — fixed: UI test missing @MainActor (Swift 6 compile), "cooks this week" stale after a new week (streak only recomputed on a cook — now reloaded on appear/return), weekly pick repeated on shelves, Signature Dish copy implied any cook counts, duplicated cooking-badge set)
- ⚔️ [Flow] When the weekly pick is tonight's card, "Try something new" hides rather than showing the next-lowest pick — cost if wrong: one less suggestion that evening.
  → Owner:
- ⚔️ [Time] Today left open across Sunday→Monday keeps last week's streak/pick until the next appear/return (same as other Today cards) — cost if wrong: stale numbers until reopened.
  → Owner:

## 2026-11-12 (item pass: Badges 1/2 slice 1 — fixed: ProfileSheetTests still used the removed `.badge` case (compile), pager ids not unique per page, ring metrics stale until Me reappears, Domain→View `tab` dependency, button copy promised "Add a recipe"/"Plan a meal" but only switches tab, catch-all group, VoiceOver "slash", header trait, 44pt close, year on dates, same-date tie-break test, UI test asserts pager closed; screenshots: clipped/grey locked titles)
- ⚔️ [Flow] "Go to Recipes and tap +" switches tab but doesn't open the "+" sheet — post a notification ContentView turns into `showAddRecipe` — cost if wrong: one extra tap.
  → Owner:
- ⚔️ [Operations] VoiceOver pages the badge pager with a three-finger swipe only; "3 of 24" is the one cue — add next/previous accessibility actions — cost if wrong: VoiceOver users see one card.
  → Owner:
- ⚔️ [Structure] Pager medallion + progress ring hand-build `ZStack { Circle(); Image }` with literal 156/170 sizes instead of extending `IconBadge` — fold into slice 2's reveal medallion — cost if wrong: drift between shelf, pager and reveal.
  → Owner:
- ⚔️ [Structure] `.onReceive(NotificationCenter.publisher)` in ContentView is Combine (repo bans it); `.openToday` copied the existing four lines — move all five to an async `notifications(named:)` loop in a Smell pass.
  → Owner:

## 2026-11-12 (item pass: Badges 1/2 slice 2 — fixed: quick flick didn't close the full-screen reveal (UI audit helper swiped the label), confetti haptic on top of the reveal pattern, fixed-28pt title ignored Dynamic Type, no scroll at AX sizes, 8 s auto-close under VoiceOver, a CMMotionManager per view init, shine sweep animated gradient points (may not interpolate) → offset, resting shine washed the pager icon in the Simulator)
- ⚔️ [Flow] The reveal waits only for Made it and "+"; it can try to present over another cover (cooking mode when the cook was already recorded today, onboarding) and stall the queue with `pendingCelebration` set — one "is anything else up?" signal or present from the top-most screen — cost if wrong: badges silently stop revealing until relaunch.
  → Owner:
- ⚔️ [Tests] View wiring is untested: deleting `guard !closing`, hard-coding full motion, or passing `isAnotherSheetUp: false` stays green (pure rules are tested, not their use) — cost if wrong: a double dismiss swallows the next badge.
  → Owner:
- ⚔️ [Structure] Chesterton: a `.large` sheet would give native flick-to-close for free; chose a cover for the "full-screen" spec + custom drag — cost if wrong: a gesture to maintain.
  → Owner:
- ⚔️ [Time] Tilt baseline is set on the first reading and never reset (posture change / return from background leaves the shine at an edge until the pager reopens); "settle toward the Me tab" drops straight down (no tab bar under a cover, none on iPad).
  → Owner:
- ⚔️ [Data] Placeholder art (Pictures 1/4 slice 2) is keyword-based: "Radish Cake" [Starter] gets cake art, "Scallion Pancakes" [Side] breakfast art, "Pad See Ew"/"Char Kway Teow" fall back to fork & knife; soup glyph (`humidity`) is weak; hashed colours can coincide with a cuisine colour — cost if wrong: a few odd-looking tiles until Pictures 3/4 gives bundled recipes real pictures.
  → Owner:

## 2026-11-12 (item pass: Data safety 1/4 slice 1 — fixed: store copies went into the iCloud/device backup (now excluded), pruned after copying (now makes room first, so a new copy is never pruned and the upgrade keeps disk headroom), prune failure logged as backup failure, bare `try?` cleanup, tests defaulting to the real Application Support)
- ⚔️ [Structure] The file copy is consistent only while nothing else opens the store at launch (share extension doesn't today); if a widget/extension ever shares it, switch to `replacePersistentStore` (SQLite backup API).
  → Owner:
- ⚔️ [Flow] Nothing restores from `StoreBackups/` yet (no user/support path), and `.corrupt-*` files from recovery are never pruned — a "Restore earlier copy" in Settings → Data could come with Data safety 3/4.
  → Owner:
- ⚔️ [Time] Before first unlock, store reads fail and `attemptStoreRecovery` moves a healthy store aside (pre-existing, not this change) — check `isProtectedDataAvailable` before "recovering".
  → Owner:
- ⚔️ [Tests] `olderModel()` pins the model before current (now `RecipeModel 15.mom`); bump it whenever `.xccurrentversion` moves.
  → Owner:

## 2026-11-12 (item pass: Data safety 1/4 slice 2 — fixed: Swift `Int` stored as Integer 32, servings default 1 vs struct 4, four entities without an `id` (CloudKit duplicates can't be deduped), test only checked entities exist (now every attribute + type), Recipe v15==v16 not pinned)
- ⚔️ [Docs] Root CLAUDE.md's `valueForUndefinedKey: isSampleRecipe` hint now names 16, but reverting to 15 would show as missing `*Entity` errors instead — reword when slice 3 starts reading the entities.
  → Owner:
- ⚔️ [Format] `recipeIDs` / `stores` are plain Binary; slice 3 must JSON-encode them (WORK.md Decisions).
  → Owner:
