# WORK: reuse-pass refactor campaign

Branch: `refactor/reuse-pass`. Goal: stop reinventing wheels — route every site
through the shared component/utility that already exists. One cluster = one slice
= one commit. Verify line refs against real code BEFORE editing (audit scan refs
may be stale). Per slice: `BuildProject` + affected `RunSomeTests` green before commit.

(Prior WORK.md content — the RecipeStore DI refactor — is complete and committed;
cleared.)

## Rules
- WIP=1. Finish + verify + commit a slice before starting the next.
- Verify each cluster's premise first; if a "duplicate" is actually justified/
  different, note it and SKIP — do not force reuse.
- Keep each change minimal and focused on that one cluster.

## Slices (highest value / lowest risk first)

- [ ] **1. Email validation** — 3 inline regexes → `Validator.isValidEmail()`.
      EmailSignInView.swift, SignUpView.swift. ⚠️ Real bug: view regex `{2,}` vs
      Validator `{2,64}` — behaviour differs.
- [ ] **2. Planner no-photo placeholder** → `RecipePlaceholderView`.
      RecipeSelectionSheet (MealPickerRecipeCard), MealTimeCard (MealThumbnail).
      Per-recipe colours; user-reported.
- [ ] **3. AnimatedHeartButton** — exists but UNUSED. Adopt in RecipeDetailToolbar
      (toggle path) or delete. Static badges (RecipeCard/CompactRecipeCard/RecipeRow)
      are decorative — leave.
- [ ] **4. Password strength** — SignUpView inline → `Validator.validatePassword()`.
- [ ] **5. Card background** — hand-rolled RoundedRectangle fills → `.appCard()`
      (~12 sites; verify each is really the card token's job — some Circles aren't).
- [ ] **6. Inline DateFormatter** — 5 one-off → static cached lets (mirror
      MealPlanningView): RecipeImportBuilder, DataManagementSettingsView,
      PrivacyPolicyView, TermsOfServiceView, MealTimeSelectorSheet.
- [ ] **7. Empty states** — RecipeSelectionSheet + RecipePickerForCollectionSheet → `EmptyStateView`.
- [ ] **8. Photo pickers** — PostCookPhotoSheet + PhotoImportSheet → `.photoSourcePicker()`
      (RecipePhotoManagerSheet is multi-select; may not fit — check).
- [ ] **9. Prep-keyword lists** — merge IngredientNameFormatter.preparationKeywords +
      CategoryClassifier.descriptorWords into one source.
- [ ] **10. Quantity rounding** — 3 strategies → shared QuantityFormatter. CAUTION:
      they may intentionally differ; confirm before merging.
- [ ] **11. `.trimmed` / `.isBlank`** — 0% used, 135+ inline. LOW priority, huge diff;
      do LAST, possibly scoped.
- [ ] **12. Dead code** — remove `RecipeFormatters.formattedImageName(for:)` (0 callers).

## Deferred (convention, not accidental dup — own unit later)
- Sheet gradient scaffold (43) + `.toolbarBackground(.hidden)` (33) → `.sheetScaffold()`.
- Error `.alert` boilerplate (17) → `.errorAlert()`.

## In progress
Slice 1 — email validation.

## Next action
Verify EmailSignInView / SignUpView / Validator line refs, route both views through
`Validator.isValidEmail()`, build + RunSomeTests (ValidatorTests + auth), commit.
