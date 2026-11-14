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

## 2026-11-14 (item pass: Data safety 2/4 slice 4b-2b — fixed: two devices folding the same item at once each wrote their own fold of the kept row and deleted their other copy, so the last write lost the other device's quantity/stores; now a copy is deleted only once the stored kept row already holds it)
- ⚔️ [Data] A rename (or tick) on a copy another device is folding away at that moment is lost — the kept row is re-checked by key next load, but a concurrent rename races the delete — cost if wrong: one list line vanishes.
- ⚔️ [Data] Inventory, meal plans, collections not folded (expiry reminders keyed by id; slot day differs by time zone; same names allowed) — later slice if duplicates show up.
- ⚔️ [Data] Same-name copies made by backup restore or renaming show until the next load; with sync off they're never folded.
- ⚔️ [Time] A fold arriving from a remote change shifts list indices under index-based APIs (`toggleItem(at:)`), as remote deletes already do.
- ⚔️ [Platform] Changing the `canonicalUnit` synonym table between versions makes two builds group copies differently.
- ⚔️ [Tests] `aSaveAfterTheFoldDoesNotBringTheOtherRowBack` would pass with a pre-fold `lastKnown`; kept-copy add + fold in one load is unpinned.

## 2026-11-14 (item pass: Data safety 2/4 slice 4b-2a — fixed: pruning inferred deletes from a library diff, so a failed fetch then one save, or a stale load overwriting a newer one, would delete every synced photo in iCloud; now removed only where an edit/delete happens on this device)
- ⚔️ [Break] Copy merge keeps one hero — `RecipeCopyMerge.merging` (SyncMerge.swift:110) unions `photoNames` but keeps only the kept copy's `imageName`, so a custom hero on the losing copy leaves the recipe (pre-existing) — alternative: move the losing hero into `photoNames` — cost if we're wrong: a photo only one device had disappears from that recipe.
  → Owner:
- ⚔️ [Break] Orphan photo rows are never collected — a delete whose pass never ran (app killed, sync off at the time) leaves its row in iCloud forever (bytes only; never shown, download needs a referencing recipe) — alternative: a sweep of rows no recipe references, run only after a full import is known complete — cost if we're wrong: iCloud quota slowly used by dead photos.
  → Owner:

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

## 2026-11-12 (item pass: Data safety 1/4 slice 3a cook dates — fixed: kept blob was a dead fallback (now kept current + refills an empty store), failed save/read lost cooks (now unmarks → next launch moves them), failed Reset delete resurrected history (now a pending wipe retried each launch), relaunch test reused one container)
- ⚔️ [Data] `merge` (backup restore) uses set semantics, so two cooks at the same instant in a backup collapse to one, unlike the migration's multiset rule. Pre-existing; practically unreachable (`Date()` per cook).
  → Owner:
- ⚔️ [Data] `CoreDataCookDateStore.save` rolls back the shared `viewContext` on failure, which would drop any other unsaved change there; other writers save immediately, so none today. Revisit when more managers write to viewContext (slice 3b+).
  → Owner:
- ⚔️ [Tests] Reset wiring (`resetToDefault` → `removeAllCookDates`) is untested; the view calls `.shared` directly (pre-existing).
  → Owner:

### 2026-11-12 · Data safety 1/4 slice 3b (collections → CollectionEntity) — noted, not fixed
- **Sync (2/4) breaks "the kept blob is never behind the store".** Once CloudKit adds rows this device's blob lacks,
  `MirroredSnapshot`'s blob-wins rule (differs → replace, fallback → replace next launch) would delete synced rows
  everywhere. 2/4 must drop the blob path (or make it add-only) before turning sync on. Cook dates' refill has a milder
  version (re-adds dates deleted elsewhere).
- **Shared `viewContext`:** store saves also commit/rollback other pending viewContext edits (same as CookDateStore).
  A private context per store would isolate it — revisit with 2/4.
- **Integrity check re-reads the same context**, so it checks memory, not disk (same as LegacyBlobMigration).
- **Whole-list rewrite per edit** on the main thread; fine for realistic sizes (rows untouched unless changed). A
  crafted backup with repeated ids makes rows churn but stay consistent (pre-existing BackupMerge gap).
- **Two migration helpers** (`LegacyBlobMigration` add-only for cook dates, `MirroredSnapshot` whole-list); flags now
  in separate namespaces. Port cook dates only if it shrinks code.

### 2026-11-13 · Data safety 1/4 slice 3c (meal plans → MealPlanEntity) — fixed: Reset left weekly reminders firing (now cancelled); added sub-second relaunch test. Noted, not fixed:
- **Reset wiring untested:** reverting the view to `.reload()` would bring plans back (rows outlive `clearAll`); a
  `DataResetter` seam the view calls would make it testable — same gap for collections/cook dates.
- **Shared `viewContext`** save/rollback (same as 3a/3b).
- **Recurring copies grow forever** (`clearOldMealPlans` keeps every recurring copy); each save now diffs all rows.
  Pre-existing; cap/purge later.
- **Rows missing id/recipeId/date are skipped silently** — safe while the kept copy exists (it replaces them); log
  or count them before the blob is dropped.

### 2026-11-13 · Data safety 1/4 slice 3d (shopping list + grocery stores → Core Data) — fixed: an unreadable stores blob left the store list empty (now rebuilt from item tags, test added); item rows get a name tie-breaker. Noted, not fixed:
- **Reset wiring untested** (same as 3c): reverting the view to `.reload()` would bring rows back.
- **Rows can come back** if the app is killed between `LocalStore.clearAll()` and `removeAllShoppingData()`, or after
  Reset on an older blob-only build then upgrading (unmarked key + no blob keeps rows) — `MirroredSnapshot` rule.
- **Store rename = delete + insert** with a fresh UUID (stores match by name); sync (2/4) must dedupe by name.
- **Shared `viewContext`** save/rollback and whole-list rewrite per edit (same as 3a–3c).

### 2026-11-13 · Data safety 1/4 slice 3e (kitchen items + inventory → Core Data) — fixed: Reset only `reload()`ed (would have kept the whole kitchen once in Core Data; now `removeAllKitchenData()` + cancels expiry reminders); an old item blob without `dateAdded` decoded a new `Date()` each launch → rows rewritten every launch (now a fixed fallback, test added). Noted, not fixed:
- **Reset wiring + expiry-reminder cancel untested** (same as 3c/3d): `DataManagementSettingsView` and `NotificationManager.shared` have no seam; a later `ResetService` item should own this.
- **Duplicate-id cleanup** keeps the first row in sort order (a nameless sync duplicate may win and be overwritten) — no data lost, same as 3d.
- **Shared `viewContext`** save/rollback and whole-list rewrite per edit (same as 3a–3d).

### 2026-11-13 · Data safety 1/4 slice 3f (badges → EarnedBadgeEntity) — fixed: a corrupt badges blob dropped the old shown list (celebration could pop again; now unioned in on load); a single quiet unlock never saved its shown flag (pre-existing; now marked before the unlock's save); relaunch tests now share one store; Reset drops queued celebrations (test). Noted, not fixed:
- **Downgrade + Reset on an older build, then re-upgrade** brings old badge rows back (no kept copy, flag unset) — `MirroredSnapshot` rule, same as 3d.
- **Unreadable store on a fresh install**: badges earned that launch stay in memory only (same as siblings).
- **Shared `viewContext`** save/rollback; rollback path untested (same as 3a–3e).
- **Backups don't carry shown-celebration ids** (pre-existing); **unknown badge ids** keep only id + date (title/icon rebuilt bare; UI lists `BadgeType.allCases` only).
- **Backup badge with `isUnlocked: false`** now loads as earned (presence already decided unlock checks).
- **A non-silent unlock writes the store twice** (unlock, then shown) — fine at ~30 rows.

### 2026-11-13 · Data safety 1/4 slice 3g (profile → ProfileEntity) — fixed: Me's `onChange(of: profileImage)` saved back the photo it had just loaded on every visit (pre-existing re-encode; would now rewrite the external Core Data file + kept copy each time) — the manager now keeps the decoded image and ignores saving that same image (test). Noted, not fixed:
- **Photo stored full size** (pre-existing: 12–48 MP camera JPEG, now held in memory and compared at launch) — downscale to ~512 px on save; a polish item, changes what's stored.
- **Unreadable store on a fresh install / after Reset**: profile edits stay in memory that launch, success haptic still plays (same as siblings; `MirroredSnapshot.save` doesn't report).
- **Sync (2/4)**: the store keeps one row and deletes other-uuid rows, so two devices would delete each other's profile — 2/4 must merge/pick by date.
- **Tests**: the external-storage path (>100 KB) isn't exercised by the in-memory store; `setIfChanged` and `unlockWelcomeBadge` (shared init only) are unpinned; Reset wiring in `DataManagementSettingsView` untested (same as 3c–3f, `ResetService` item).
- **Reset kill window** between `clearAll()` and `removeProfile()` can bring the name back (same rule as 3d; running the `remove*()` calls before `clearAll()` would close it for every manager).

### 2026-11-13 · Data safety 2/4 slice 1 (sync-safe `MirroredSnapshot`) — fixed: a save brought back rows deleted on another device (unchanged-here + gone-from-store now dropped); an empty shared store overwrote the kept copy (now refilled from it). Noted, not fixed:
- **Kept-copy-ahead / first move is add-only and the copy wins on shared ids**: rows deleted meanwhile come back and other devices' newer edits to those ids roll back. Accepted (nothing lost); a persisted base would fix it.
- **Empty-store refill** also undoes a real "everything deleted on another device" for this device's rows.
- **Sync on→off** must stop CloudKit mirroring before the 1/4 rule replaces the store (slice 3).
- **Reset while syncing** wipes every device; rows not yet imported come back (slice 3 UI must say so).
- **`copyIn` re-read during an import** can fail the check → session runs on the kept copy (then add-only next launch).
- **Merged rows not shown until next `load()`**; `syncActive` is per-load — slice 2 reloads on remote change.
- **Duplicate ids**: first wins, no log.

### 2026-11-13 · Data safety 2/4 slice 2a (sync rules wired into managers) — fixed: the badge store lists rows by id, so adding the kept copy always failed its re-read check and badges stayed on the kept copy for good (now checked by id, any order; test). Noted, not fixed:
- **Duplicates by meaning**: "Eggs" added to the kitchen/shopping list, or the same meal slot filled, on two devices gets two UUIDs → both kept; managers' name/slot dedupe only runs on add (slice 4 dedupe should cover these too).
- **Store names as ids**: "Tesco" vs "tesco" from two devices both survive; a rename on one device leaves the other's item tags pointing at the old name.
- **Category fix-up on load** (Kitchen/Shopping) saves straight away — two app versions normalising differently would flip values between devices.
- **Tests** don't run a manager save under sync (`applyEdits` covered only in `SyncMergeTests`) and don't distinguish a wrong id closure.

### 2026-11-13 · Data safety 2/4 slice 2b (one shared profile) — fixed: filling a missing photo from another device's row brought a removed photo back (fill dropped); added a test that fails if the constant sync id is replaced by the uuid
- **Stale in-memory profile** until remote-change reload (slice 3): a device still holding its own profile overwrites the iCloud one on its next save — last writer wins.
- **"Oldest" uses each device's clock** (`createdDate`): a wrong clock picks the wrong profile, but every device picks the same one.
- **New device names itself before iCloud's profile arrives** → that edit loses to the older named profile.
- **Reset under sync** can be undone by an offline device pushing its old named row (named beats empty); slice 3's Reset copy must warn, and Reset should turn sync rules into "erase everywhere".
- **Every write deletes other rows**: a concurrent edit on another device can be dropped by CloudKit's merge.

### 2026-11-13 · Data safety 2/4 slice 3a (CloudKit container, sync off) — fixed: history tracking can't be dropped without the store going read-only → root CLAUDE.md hard constraint; relationship rules of the model check now tested. Noted, not fixed:
- **CI builds unsigned** (`CODE_SIGNING_ALLOWED=NO`): a bad iCloud profile only shows in the TestFlight run after merge — check it.
- **No test drives `retryWithoutSync` or `.shared`'s launch flag**: a CloudKit load failure can't be produced reliably in an unsigned simulator; the fallback mirrors `attemptStoreRecovery`'s reload pattern.
- **The model check is ours, not Apple's**: a rule it misses fails at load with sync on → falls back to local (no data moved).
- **History never purged** while sync is off, and turning history on isn't a model change so no `StoreBackup` copy is taken — small (one transaction per save); purge in a later slice.
- **After a fallback `SyncPreference` still says on** — slice 3b's status must show "off on this device".

### 2026-11-14 · Data safety 2/4 slice 3b-1 (reload on iCloud changes) — fixed: a list cleared on another device was re-added from the kept copy on reload (empty-store refill now only on the first load of a session); recipes reloaded via `refresh()` skipped dedupe (now `load()`); captured-var mutation in a test closure. Noted, not fixed:
- **Cleared elsewhere while this app was closed** still comes back at launch (empty store at launch = recovery/unfinished import is the safer guess). Needs a store-level "erased" marker — slice 4 (dedupe) or Data safety 4/4.
- **`ProfileManager.loadProfile` on an emptied store** saves a fresh profile and syncs it back; clears the cached photo on each reload (re-read lazily).
- **No test for CloudKit bookkeeping transactions** (author set, only NSCK* entities): can't be produced in a unit test; the app-entity filter is the guard.
- **Reload list in `RecipeFinderApp.reloadOnICloudChanges` untested** (thin glue): a manager left out won't refresh until relaunch.
- **History read on the main thread, never purged** — fine at current sizes; purge with the sync toggle slice.

### 2026-11-14 · Data safety 2/4 slice 3b-2a (merge same-id recipe copies) — fixed: edits/deletes hit one arbitrary copy before the merge (now every row with the id); merge faulted the whole library on main every load (now only ids the fetch held twice, batch `recordIDs(for:)`). Noted, not fixed:
- **Unuploaded copies wait** for the next import or launch (an export finishing changes only CloudKit bookkeeping, so no reload). Could listen to `eventChangedNotification` — later slice.
- **3+ devices with partial views** can both merge into the same kept copy at once; CloudKit keeps the last write, so one device's cook marks can be lost.
- **`populate` round-trip** turns a nil `imageName` into "" and writes back `mapToRecipeModel`'s defaults for missing fields on the kept copy.
- **`mergeSyncedRecipeCopies` untested** beyond its sync-off guard: CloudKit record ids can't be produced in a unit test; the pure plan is tested.
- **Record names assumed stable** across a zone reset / account change — not checked.

### 2026-11-14 · Data safety 2/4 slice 3b-2b (opt-in sync switch) — fixed: Reset after sync was turned off warned "this device only" though CloudKit would send its deletes once sync is back on (now an "ever synced" flag, kept through Reset); policy claimed recipe photos sync (they don't yet) and §3.1/§9.1 ignored iCloud copies; Reset could lose the sync choice if killed mid-way (now `clearAll(keeping:)`). Noted, not fixed:
- **Launch wiring untested**: nothing fails if `applyAtLaunch` moves after the database opens or the switch writes `key` instead of `wantedKey`; both are one-liners in `App.init` / `ICloudSyncSection`.
- **Changes made while sync was off** (incl. "kept copy wins" deletes) will be sent to iCloud when it's turned back on; the off→on copy doesn't say so.
- **No live sync status** (syncing / iCloud full) — needs `eventChangedNotification`; later slice. History purge also still pending (slice 4).

### 2026-11-14 · Data safety 2/4 slice 4a (store-history purge) — fixed: comment claimed the tracking checkpoint is never purged (it can be after ≥7 idle days), purge test passed via the expired-token branch whatever the author filter did (split into a kept-checkpoint test + an expired-checkpoint test). Noted, not fixed:
- After ≥7 idle days with sync on, the first launch reloads every list once (expired checkpoint).
- Sync on but history not uploaded within 7 days (offline, iCloud full, off→on, clock jump) relies on CloudKit's expired-history recovery (full re-sync) — Apple's sample does the same; untestable in CI.
- Launch wiring (`purgeOldStoreHistory` call, order vs tracking) untested; purge also runs in the unit-test host.

### 2026-11-14 · Data safety 2/4 slice 4b-1 (recipe photo sync) — fixed: `recipes = recipes` self-assignment (compile error); every stored photo was written to disk, so a removed photo came back on every pass (now only photos a recipe here shows); a hero saved mid-pass could be overwritten by the older iCloud copy (re-checked just before writing); Reset deleted recipes before photo rows (now photos first); 20 MB cap untested (test). Noted, not fixed:
- Newer-wins compares this device's file dates with other devices' clocks: a row dated in the future (clock set ahead) beats later local edits of that photo. Rejected for now: content hash + per-device "last synced" record (bigger); revisit if seen.
- Removed photos/recipes keep their rows in iCloud (storage, privacy) and duplicate rows for one path aren't merged → 4b-2 pruning. Reset racing an in-flight pass can re-add rows (unreferenced, never written to disk; 4b-2 prunes them). Reset leaves `RecipeImages/` files (pre-existing).
- A received photo shows once its view redraws (library re-published; SwiftUI may skip an unchanged `RecipeImageView` until it reappears).
- Wiring (`syncPhotosWithICloud` after load/save, sync-on `mirrorRecipePhotos`) untested — CloudKit can't run in unit tests. Test photos are tiny, so external (CKAsset) storage isn't exercised.
- TestFlight uses the Production CloudKit environment: `CD_RecipePhotoEntity` (and the v16 record types) need the schema deployed there before testers' sync works — owner step.

### 2026-11-14 · Data safety 2/4 slice 4b-2c (erased elsewhere while closed) — fixed: `iCloudRules` read a main-actor property from a nonisolated closure (now `@MainActor`); added a test that reopening the same file keeps its name (the premise). Noted, not fixed:
- **Same-file purges are followed at launch**: iCloud sign-out/account change, deleting the app's iCloud data, or a CloudKit zone reset empty the same file; if that lands before `load()`, the kept copy becomes `[]` and offline edits that never uploaded are lost (mid-session purges were already followed). Could keep the old copy one extra launch.
- **Device restore / new phone** copies the store file and UserDefaults together; a CloudKit reset purging the restored store before first load is followed instead of refilled. Speculative.

### 2026-11-14 · 🐞 Reset leaves photo files + recent searches — fixed: photo folder was deleted even when erasing recipes failed (now only after `deleteAllRecipes()` returns true); renaming the searches key would have dropped every cook's recent searches (kept the global key, Reset clears it). Noted, not fixed:
- **In-flight writers**: a web-picture download (`imageLocalization`) or photo-sync pass running at Reset can recreate `RecipeImages/` and write an orphan file (or, narrowly, re-save one photo row) after the delete. Fix: cancel/await both tasks before deleting.
- **No test drives `resetToDefault`** (private view code): removing the photo-delete call fails no test. Fix with a testable Reset use case when Reset is next touched.
- **Failed photo delete is only logged**; Reset still shows success. Main-thread delete may stall on a huge library.
- **Other devices keep their files** after a Reset that erased every device (photo sync never deletes files) — still in Inbox.
- `attemptedPictures` isn't cleared: a re-import of the same recipe in the same launch gets no offline picture copy until relaunch.
