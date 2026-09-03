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
- [x] **A4. "Already in your kitchen" nudge** — `ShoppingListView.nudgeIfInKitchen`
      via `KitchenInventoryManager.hasItem/hasInventoryItem`; banner on add.
- [x] **A5. Build + full suite green.**

### Phase A follow-ups noted while building
- Confirm tab label ("Groceries" vs "Kitchen & Shopping"); revisit Import icon.
- Import tab: add paste-text→AI (SharedTextImporter) + recent imports later.
- Broader header/theme consistency pass still worthwhile (see cohesion principles).

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
