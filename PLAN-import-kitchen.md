# Plan of attack — Import-first IA + Kitchen/Shopping merge

Working plan for the current push. Keep this open and tick items as they land.
North star: **cohesive, consistent, clean** (Yoti-level); protect the loop
capture → organise → cook → shop. Import is a primary function → give it the centre.

## Target tab bar
`Recipes · Kitchen & Shopping · ＋ Import (centre) · Planning · Settings`
- Merging Kitchen + Shopping frees the centre slot for Import with nothing dropped.

## Phase A — DONE (UI + cross-talk, NO data-model rewrite) — 769 tests green
- [x] **A1. Merged "Kitchen & Shopping" tab** — `KitchenShoppingView` owns one
      NavigationStack + segmented control; children switched to a passthrough
      `Group` (their nav modifiers apply to the shared stack). Tab labelled **Groceries**.
- [x] **A2. Tab restructure** — Recipes / Groceries / **＋ Import (centre)** /
      Planning / Settings (`ContentView`).
- [x] **A3. Import screen** — `ImportView` centre tab: "Paste a link" →
      `RecipeImportView` sheet; "Create manually" → `RecipeWizardView`; share hint.
      (Reuses existing flows for consistency. Paste-text→AI + recents deferred.)
- [x] **A4. "Already in your kitchen"** — now a persistent inline **"In kitchen"**
      pill on each matching shopping row (replaced the transient banner), via
      `KitchenInventoryManager.hasItem/hasInventoryItem`.
- [x] **A5. Build + full suite green.**

### Phase A polish — DONE
- [x] Kitchen "Recipe Ideas" card: replaced the misleading match progress bar with
      a plain "N of M" count (`QuickMatchRecipeCard`).
- [x] "In kitchen" pill moved inline beside the item name (compact, no icon).
- [x] Import header centred with a lead tray-download icon.
- [x] Tests run on a single simulator (scheme `parallelizable = NO`).

### Next up (Phase A follow-ups)
1. [ ] **Cohesion pass** — one shared header/background treatment across the main
       screens (the Yoti-clean north star). Biggest consistency win.
2. [ ] **Import tab depth** — paste *text* → AI (`SharedTextImporter`) and a
       recent-imports list (currently link + manual only).
3. [ ] Confirm tab label ("Groceries" vs "Kitchen & Shopping") and whether the
       Import *tab* icon changes (header icon already added).

## Phase B — later (only if it earns it): unified item model
- One food-item model with state `toBuy` / `haveIt`. Checking off a bought item
  moves it Shopping → Kitchen; using a kitchen item can re-add to Shopping.
- Migrate the three current stores (shopping list, kitchen items, kitchen
  inventory) → one. Deferred; needs a migration + tests.

## Cohesion principles (apply on every screen we touch)
- App background/theme + one consistent header treatment.
- One clear primary action per screen; no grab-bags.

## Checkpoints / decisions
- After each Ax: build green + one-line commit message.
- Open Q: Import as centre (chosen for now) vs first tab — revisit after A lands.
- Cooking Mode: parked (reset out); revisit later, themed and simpler.
