# WORK: De-duplication campaign batch 2 (2026-11-04) — #1 sheet scaffold DONE (uncommitted, build + 31 affected tests green, 10 sheets checked on sim)
Order (user-approved): 1 sheet scaffold → 2 card styles → 3 adaptive colours → 4 search fields → 5 ingredient normalisers → 6 duration code.
1. [x] `Components/Sheets/SheetScaffold.swift`: `.sheetScaffold(title)` (NavigationStack + AppBackground + appNavigationChrome) and
   `.sheetDismissButton(_:placement:)` applied to 17 sheets. Decisions: modifier not container (toolbars must sit inside the stack, and
   it avoids re-nesting); apply it LAST after .toolbar/.sheet. Dismiss buttons now plain system tint (dropped ad-hoc
   adaptiveForegroundColor/accent/semibold) — intentional consistency. Not converted: buttons with side effects (wizard Cancel haptic,
   cooking-mode Done→finish, Save/Apply), Settings screens without AppBackground (NotificationSettings/MealReminder time pickers), tab roots.
**Next action:** user commits #1; then #2 card styles (15 hand-written cardStyle branches + GlassCard vs .appCard()).

# WORK: De-duplication campaign (2026-11-04) — low-risk batch 1–6 DONE (1798 green, uncommitted)
User: "search for duplication and remove it — works once, easier to maintain". Sweep (Explore agent) ranked 15; doing
lowest-risk first, one at a time (build + affected tests each, full suite at end). Order / status:
1. [x] ContentView draws AppBackground behind TabView, but every tab root draws its own (NavigationStack is opaque) → drop ContentView's (iPhone layout). Roots MUST keep theirs (iPad detail has none).
2. [x] 68 raw `.trimmingCharacters(in: .whitespacesAndNewlines)` while `.trimmed`/`.isBlank` exist unused (Utilities/Helpers/Extensions.swift) — only exact `AndNewlines` calls.
3. [x] Fraction parsing twice: AppErrors.swift:124/138 vs IngredientLineParser.parseQuantity (AppErrors rejects "½" — bug).
4. [x] 22 hard-coded `.spring(...)` vs unused Constants.Animation → `Animation.appSpring`.
5. [x] Nav chrome (dismiss buttons deferred to sheet scaffold) `.navigationBarTitleDisplayMode(.inline)` + `.toolbarBackground(.hidden…)` ×26 → one modifier; dismiss-only Done/Cancel ×18.
6. [x] Legal pages: 3 copied layouts; "Last Updated" = Date() at render (bug).
Later / higher risk (confirm with user first): sheet scaffold (#2), cardStyle branches ×15 + GlassCard vs appCard, colorScheme helpers → adaptive colours (60 calls), SearchBar vs AppSearchField, 6 ingredient normalisers (behaviour change), duration formatters/parsers, empty-state copies, DateFormatters, share/top-VC walks.

# WORK: Bundled recipe curation (2026-11-04) — DONE, uncommitted (1774/1774 green)
All 340 source recipes reviewed against their raw paste (6 reviewer batches, brief in tools/recipe-review/BRIEF.md) →
`RecipeFinder/RecipeSeed/recipes_curated.json` (keyed by stable id; 332 fix, 8 drop). Generator
(BundledRecipeCatalogTests.apply) builds shipped recipes from it; `everyRecipeIsCurated` blocks unreviewed additions.
Display fixes: ingredient names sentence case (`displayName` from stored name); spoons <10 g stay spoons in Metric.
Spot-check (reviewer judgement calls): un-scaled amounts in Aloo Gosht, Beef in Black Bean, Butter Chicken, Beef
Stroganoff, Biang Biang, Pakistani Chana Dal (weakest), Dan Dan, Kofta, Dal Gosht, Nihari, Shami Kebab, Paella, Lamb
Pulao, Green Curry, mooncakes; Pistachio Sponge final step written by reviewer; matcha rice cake gelatin→yeast; some
method-only ingredients added with qty 0; Chicken Corn Soup / Clay Pot Rice cook time = total − prep.
ON-SCREEN CHECK (3 rounds, iPhone 18 Pro): content passes; fixed display layer — recipe rows show names as written
(`Ingredient.displayParts`, bracket-aware), spoons never convert, cups convert only for known liquids / known-density
non-herb solids, tidy rounding (ml 5/10, oz ½, ≥16 oz → lb, ≥4 tbsp → cups), thirds kept (⅓ not ⅜), "Not set" for
unknown times, "L", plural cups, starter categories → filter list. Full suite 1789/1789. Last two fixes (thirds, 1 lb)
verified by tests only. Open 🟢: Miso source link truncated "watch?"; near-duplicate pairs kept (distinct sources).
RENDER AUDIT: `BundledRecipeRenderAuditTests` renders all bundled + starter recipes through the real display code
(`IngredientRowView.amount` — now shared with cooking mode — and `Ingredient.displayParts`) in Metric + Imperial and
lints titles, times, servings, amounts, units, names, brackets, duplicates, steps. 0 findings; 22 duplicate rows
labelled "for the …" from source. Full suite 1790/1790.
COMPLETENESS PASS (3 rounds: full review, step-count cross-check, targeted gap review; briefs BRIEF_COMPLETENESS.md /
BRIEF_GAPS.md): 25 recipes fixed for missing method steps / unused ingredients (incl. Black Sesame Tangyuan filling);
77 other flags accounted for as variants or blog text. Bhindi Masala final step INFERRED (source truncated) — re-source.
Full suite 1790/1790, audit 0 findings.
Next: user commits; then Kitchen surfacing / 🟡 backlog.

# WORK: Account removal (2026-11-04) — STAGES 1–3 DONE (uncommitted; build + full suite 1769/1769 green)
- S1: auth engine/UI, Keychain/PasswordHasher/SessionExpiry, sign-in UI tests and launch args deleted; legal/help copy de-accounted.
- S2: per-user scoping → `LocalStore` (unscoped "rf." keys, no migration); Core Data `userId` dropped in RecipeModel 14.
- S3: Account→Profile rename (ProfileManager/ProfileManaging/`\.profile`, Views/Profile, Models/Profile, ProfileSheet etc.;
  storage keys profile*/`profileCreatedDate`, no migration); UI "Account"→"Profile"; docs (ROADMAP "No accounts", SHIP_BAR,
  CLAUDE.md x3, readme, HANDBOOK) cleaned; create_account.png removed; SheetAndScope UI test → SheetPresentationUITests.
**Next action:** user commits; then next steps.

# (previous) New-user exploratory QA (2026-11-03)

## ▶ Resume here
Working tree clean before this file (all prior work committed: 184b2ed). No code changes in progress.

**Status:** Both testers DONE (2026-11-04). Run testers sequentially, never in parallel (shared run destination).

### 🔴 — ALL FIXED 2026-11-04 (uncommitted; full suite 1827/1827 green)
1. Edit dropped isSampleRecipe/rating/dietaryInfo/cook history → `RecipeWizardBuilder.mergeEdit` at the single edit
   save point (RecipeDetailView+Content editRecipeSheet). Test: RecipeWizardBuilderTests.mergeEditPreservesUneditedFields.
   Dev devices that already edited bundled recipes keep the bad flag until Settings → Reset (now works).
2. Grocery redraw → ShoppingListModel uses synthesized ==/hash (lookups already by id). Test updated/added.
3. Guest Reset → nil userId = guest scope in `clearDatabase` (ownerPredicate + merge batch-delete IDs) and
   `clearCurrentUserData` ("no_user_" prefix); reset reloads via `recipeStore.load` (re-seeds starters + bundled) instead
   of legacy `populateDatabase`. **Decision reversed:** 2026-10-30 left clearDatabase refusing nil scope; that made the
   confirmed user reset a silent no-op. Guest predicate can't touch account rows (test asserts it).

### Plan (user, 2026-11-04): 1) all 🟡 bugs from this session, 2) THEN remove accounts entirely
Accounts decision: single-user local app, no sign-in (none needed — no backend; iCloud sync uses the user's iCloud).
Do NOT start account removal until the 🟡 list below is done.

### 🟡 progress (uncommitted, each slice build + suite green)
DONE: ticks follow items after edit (`ChecklistState.remap`); no launch notification prompt (asks in context via
`NotificationManager.addAskingPermissionFirst` for streak/expiry); backup/restore result in an alert + export spinner;
Ingredients/Purple wraps; Filter "Kitchen" copy; Update-from-Source toggle tint; View-all-badges (opens Account after
badge sheet dismisses); cooking timer uses first (compound) duration; difficulty vocab normalised (sources + filter +
Easy collection via `RecipeWizardBuilder.normalizeDifficulty`); editor fractions (save parses "1/2"/"⅓" — was saving 1;
prefill uses FractionFormatter); grocery row shows unit + cap 999; lemon/lime juice → Produce.
NOT A BUG (code check): cooking mode shares the same measurementSystem AppStorage. DEFERRED 🟢: ingredient names
Title-Cased by `Ingredient.name` getter (global; risky).
ALSO DONE: long times "9 hr 45 min"; bundled titles cleaned (`cleanTitle`), section headers/equipment dropped from
ingredients, Notes/Video/Nutrition cut from steps (generator: BundledRecipeCatalogTests; Tandoori 19→8 steps; 340
recipes); imports no longer invent 15+30 min (unknown = 0, cards hide clock via `hasTotalTime`); URL import opens the
review editor (shared `PrefilledRecipeData(recipe:)`); today's XCTest additions moved to Swift Testing suites.
Full suite 1855/1855 green (2026-11-04).
DEFERRED 🟢: jump-to-recipe after URL import; header/equipment cleanup inside TextRecipeParser for user pastes (only
done in the bundled generator); kitchen expiry UI; meal-reminder discoverability; nutrition estimate vs source figures.
VISUAL CHECK 2026-11-04 (iPhone 17e): all 8 targeted fixes PASS. Follow-ups fixed after: detail Prep/Cook time
now "x hr y min" (`RecipeModel.formatMinutes`); card VoiceOver reads total time; badge sheet auto-dismiss 4s→8s.
New 🟡 backlog: 4 bundled recipes with ≤2 ingredients (e.g. American pancakes — bad source, on known-poor list;
575-min cook time / 11 servings); every bundled recipe category "Main" (source has none → consider CategoryClassifier
on name); groceries "Kashmiri Chili Powder"→"Chili Powder", cornflour→Other; typed "200 g flour" in Groceries not
parsed into qty/unit. 🟢: ticks lost on leaving recipe; editor shows "0" for unquantified; odd metric grams (3½ g);
low-contrast checked grocery rows; white Paste box; Reset gives no confirmation; yogurt row named "Plain".
NEXT: user commits these follow-ups; then task 16 — remove accounts entirely (plan in memory identity-and-accounts;
staged, each stage build + tests green; start with a grep inventory of AuthenticationManager/AuthUIGate/
UserScopedStorage/userId). Kitchen discoverability question raised by user 2026-11-04 (see chat).

## Findings — tester A (iPhone 18 Pro, core loop) — no crashes; edit crash fix confirmed
### 🟡
- Ticks land on wrong items after edit (state keyed by position, reset only on count change).
- Cooking-mode timer sums every duration in a step ("6 hours, up to 48 hours" → 3240 min) — CookingModeView.cookTimerMinutes l.48.
- Difficulty vocab mismatch: bundled "Medium" vs editor Basic/Intermediate/Expert; "Easy Recipes" collection + RecipeSearchView.swift:74 filter never match "Medium".
- Parse quality: section headers/equipment as ingredients ("For Serving:", "Baking Rack"); "Plain whole-milk greek yogurt" → name "Plain"; source notes/nutrition become steps; all bundled category "Main", no cuisine; junk titles (Chapati PREP TIME…, paella "Serves 2.0…", "18.0 bites serving", URLs in titles, garbled Thai).
- Nutrition estimate contradicts source figures shown above it.
- Editor shows "0.333333"; notes Title-Cased ("Such As Grapeseed Oil"); cooking mode ignores Imperial.
- Filters: "Add ingredients in the Kitchen tab first" but no Kitchen tab; What Can I Make toggle dead-ends (FilterSheet.swift:116).
- Update-from-Source toggles render as off while on.
- Lemon juice from recipe → groceries "2", no unit, "Beverages".
### 🟢
Delete only via long-press, no undo; edit cancel no discard prompt; new collection from Add-to-Collection doesn't add the recipe; Timer/Collections sheets no close; sort resets on relaunch; a11y (steps no checked state, photo remove "Close", nested "Drag"); no rating prompt; no onboarding.
### Verified OK
Instant first-launch library w/ images, search, sort, scaling, units, ticking, substitutions, groceries add, favourite, collections incl. smart, View Original, cooking mode + timer, confetti/badges, cook count + Cooked today, persistence across relaunch, delete w/ confirm.

## Findings — tester B (iPhone 17e, fresh install, guest)
### 🔴
1. **Grocery check-off / +− qty don't redraw** — persists but row doesn't update; users re-tap and toggle back.
   Cause: `ShoppingListModel` `==` compares `id` only → SwiftUI skips row diff.
2. **Settings → Data → "Reset to Default" is a no-op for guests but reports success** — `clearAllRecipes` /
   `clearCurrentUserData` / `populateDatabase` early-return on nil userId (log: "No user logged in, skipping database
   clear"); recipe list not reloaded. (Guest scope = userId nil since the 2026-10-30 guest-persistence fix.)
### 🟡
3. Notification permission requested on every launch — `ContentView.onAppear` (~l.57); timer + reminder already ask in context.
4. Groceries drop units/decimals: "1.5 tbsp olive oil" → "Olive Oil 2", "200g" → "200"; qty Int, + disabled at 200 (max 99).
5. "View all badges" no-op — `ContentView.swift:114–121` presents a sheet while another dismisses.
6. Recipe detail "Ingredients" header wraps "Ingredi-ents" (squeezed by edit/cart/Metric buttons).
7. Theme "Purple" wraps "Purpl/e" when selected (checkmark).
8. Backup export/import feedback off-screen at bottom, 2s auto-hide; export 3–5s with no spinner.
9. Paste import invents 15+30 min times and "Intermediate" (seeds use "Medium") — known backlog item.
10. URL import saves with no review step and no jump-to-recipe; only a badge sheet shows.
11. Kitchen: no way to set expiry dates though Help says you can.
12. Meal reminders only via long-press; tapping a planned meal swaps it; can't open the planned recipe.
13. Seed data: "Easy & Simple Apam Balik…" title contains whole description; "American pancakes" shows "585 minutes".
### 🟢
Search ~1s lag + refocuses keyboard on back; tiny tap targets (tip ✕ 9pt, planner trash 14pt); keyboard-dismiss FAB
covers "Add"; "(0/1)" grocery count confusing; raw "unsupported URL" error; manual editor cancel discards without
confirm; "Validation Error" titles; Import inbox icon looks tappable; Kitchen sheet no close; generic category icons;
Account avatar blank vs "RC"; locked badges low contrast/no hint; reminder sheet translucent bleed; menu button a11y
label "Drag"; recipe row a11y reads prep time not total; low-contrast orange-on-blue and grey alert text.
### Verified OK
Paste import (1.5 tbsp survives), garbage/blank paste, BBC URL import + photo, invalid URL error, OCR graceful fail,
manual validation, search, groceries from suggestions/recipe, kitchen add, What Can I Make, meal plan add/reorder/
delete/reminder, badges, dark mode/themes, settings rows, privacy policy, reset confirm dialog. No crashes.
