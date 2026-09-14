# Feature Audit — Test Coverage

Last updated: 2026-09-14 (updated after integration test pass).  
Legend: ✅ integration tested · ⚠️ unit/model only · ❌ no test

---

## Recipe management

| Feature | Status | Test file(s) | Gap |
|---|---|---|---|
| Create recipe (wizard) | ✅ | RecipeWizardPersistenceTests | — |
| Edit recipe (save + rollback) | ✅ | RecipeSaveResultTests, RecipePersistenceRoundTripTests | — |
| Delete recipe | ✅ | RecipePersistenceRoundTripTests | — |
| Favorites toggle + persistence | ✅ | RecipePersistenceRoundTripTests | — |
| Tags — add to recipe | ✅ | RecipeWizardBuilderTests, RecipeWizardPersistenceTests | — |
| Dietary info (veg/vegan/GF) | ✅ | RecipeDietaryInfoPersistenceTests | — |
| Nutrition auto-calc per serving | ✅ | NutritionCalculatorTests | — |
| Recipe notes | ✅ | RecipeNotesFormatterTests, RecipePersistenceRoundTripTests | — |
| Seed/sample recipes | ✅ | SeedRecipeProviderTests | — |
| Servings scaling | ✅ | RecipeModelTests, RecipePersistenceRoundTripTests | — |

---

## Import

| Feature | Status | Test file(s) | Gap |
|---|---|---|---|
| URL / link import | ✅ | RecipeImporterTests, RecipeImportFixtureTests, RecipeImportPersistenceTests | — |
| Paste text import | ✅ | TextRecipeParserTests, SharedTextImporterTests, TextRecipeFixtureTests | — |
| Photo OCR import | ✅ | RecipeImageTextRecognizerTests, PhotoOCRImportPersistenceTests | — |
| Share extension inbox | ✅ | SharedImportInboxTests | — |
| AI free-text import (FoundationModels) | ✅ | OnDeviceRecipeImportStatusTests, AIImportPersistenceTests | — |
| Import duplicate detection | ✅ | BackupMergeTests, RecipeImportPersistenceTests | — |

---

## Search & filtering

| Feature | Status | Test file(s) | Gap |
|---|---|---|---|
| Text search | ✅ | RecipeFilterIntegrationTests | — |
| Filter by category | ✅ | RecipeFilterCriteriaTests, RecipeFilterIntegrationTests | — |
| Filter by difficulty | ✅ | RecipeFilterCriteriaTests | — |
| Filter by dietary info | ✅ | RecipeFilterCriteriaTests | — |
| Filter by available ingredients | ✅ | KitchenRecipeMatcherTests | — |
| **Filter by tag** | ✅ | RecipeFilterCriteriaTests, RecipeFilterIntegrationTests | — |
| **Filter by collection** | ✅ | RecipeFilterCriteriaTests | selectedCollectionRecipeIDs added to criteria; UI wiring pending |
| Sort order | ❌ | — | No test |

---

## Collections

| Feature | Status | Test file(s) | Gap |
|---|---|---|---|
| Create / rename / recolour / delete | ✅ | CollectionManagerTests | — |
| Add / remove recipe | ✅ | CollectionManagerTests | — |
| Toggle membership | ✅ | CollectionManagerTests | — |
| Purge recipe from all collections | ✅ | CollectionManagerTests | — |
| Backup merge | ✅ | ManagerMergeTests | — |
| **Add all collection ingredients to shopping list** | ✅ | ShoppingListFromRecipeTests (batch add) | — |
| **Filter recipes by collection** | ✅ | RecipeFilterCriteriaTests | criteria logic tested; FilterSheet UI wiring pending |

---

## Meal planning

| Feature | Status | Test file(s) | Gap |
|---|---|---|---|
| Add / update / delete plan | ✅ | MealPlanningManagerTests | — |
| Same-slot overwrite behaviour | ✅ | MealPlanningManagerTests | — |
| Calendar model | ✅ | MealPlanCalendarTests | — |
| Backup merge | ✅ | ManagerMergeTests | — |

---

## Shopping list

| Feature | Status | Test file(s) | Gap |
|---|---|---|---|
| Add / remove / check off items | ✅ | ShoppingListManagerTests | — |
| Add from recipe | ✅ | ShoppingListFromRecipeTests | — |
| Category classification | ✅ | CategoryClassifierTests | — |
| Grouping | ✅ | ShoppingListGroupingTests | — |
| Backup merge | ✅ | ManagerMergeTests | — |

---

## Kitchen / Pantry

| Feature | Status | Test file(s) | Gap |
|---|---|---|---|
| Inventory CRUD | ✅ | KitchenInventoryManagerTests | — |
| Pantry alerts (low stock / expiring) | ✅ | PantryAlertsCategorisationTests | — |
| Match recipes to pantry | ✅ | KitchenRecipeMatcherTests | — |

---

## Badges

| Feature | Status | Test file(s) | Gap |
|---|---|---|---|
| Unlock + celebration queue | ✅ | BadgeManagerTests | — |
| shoppingExpert / mealPlanner triggers | ✅ | BadgeTriggerIntegrationTests | — |
| firstImport / firstPhotoImport / headChef | ⚠️ | BadgeManagerTests | Unlock + celebration tested; call sites are in views, no extractable logic |
| Shown-celebration persistence | ✅ | BadgeManagerTests | — |
| Backup merge (no re-celebration) | ✅ | BadgeManagerTests | — |

---

## Auth & account

| Feature | Status | Test file(s) | Gap |
|---|---|---|---|
| Credential store CRUD | ✅ | SecureCredentialManagerTests | — |
| Session expiry policy | ✅ | SessionExpiryPolicyTests | — |
| User model / display name | ✅ | AuthenticationUserModelTests | — |
| **Email sign-in flow** | ❌ | — | AuthenticationManager still singleton-bound (H1 leftover) |
| **Email sign-up flow** | ❌ | — | Same |
| **Apple Sign In** | ❌ | — | No test |
| **Biometric auth** | ❌ | — | No test |
| **Guest mode** | ❌ | — | No test |
| Account name formatting | ✅ | AccountNameFormatterTests | — |

---

## Backup / restore

| Feature | Status | Test file(s) | Gap |
|---|---|---|---|
| Export archive | ✅ | BackupArchiveTests | — |
| Import / restore | ✅ | BackupArchiveTests, BackupMergeTests | — |
| Manager merge (recipes/collections/badges/meals/shopping) | ✅ | ManagerMergeTests | — |
| Full BackupService round-trip | ✅ | BackupServiceTests | — |
| Per-user scope isolation | ✅ | ManagerScopePersistenceTests | — |

---

## Cooking mode

| Feature | Status | Test file(s) | Gap |
|---|---|---|---|
| Timer (start/pause/reset) | ✅ | RecipeTimerManagerTests | — |
| Step navigation / finish | ❌ | — | Pure view, headChef badge trigger untested end-to-end |

---

## Settings & notifications

| Feature | Status | Test file(s) | Gap |
|---|---|---|---|
| Notification settings | ✅ | NotificationSettingsTests | — |
| Theme / appearance | ❌ | — | View-only, no logic to test |

---

## Priority gaps

1. **Collection filter UI** — wire `selectedCollectionRecipeIDs` into `FilterSheet` so users can filter by collection (criteria logic + tests already done; UI wiring pending)
2. **Sort order** — no sort feature implemented yet; nothing to test until built
3. **Auth flows** — sign-in / sign-up / Apple Sign In / biometric / guest all blocked on `AuthenticationManager` DI seam; tracked in hardening backlog
4. **headChef / firstImport / firstPhotoImport call sites** — badge unlock is tested; triggers live in views with no extractable logic to unit-test
