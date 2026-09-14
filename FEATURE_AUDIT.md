# Feature Audit — Test Coverage

Last updated: 2026-09-14.  
Legend: ✅ integration tested · ⚠️ unit/model only · ❌ no test

---

## Recipe management

| Feature | Status | Test file(s) | Gap |
|---|---|---|---|
| Create recipe (wizard) | ✅ | RecipeWizardPersistenceTests | — |
| Edit recipe (save + rollback) | ⚠️ | RecipeSaveResultTests | Edit-path rollback not tested |
| Delete recipe | ⚠️ | PersistenceControllerTests | No explicit round-trip |
| Favorites toggle + persistence | ❌ | — | No round-trip test |
| Tags — add to recipe | ✅ | RecipeWizardBuilderTests | Tags step in wizard, edit round-trip, filter already wired |
| Dietary info (veg/vegan/GF) | ✅ | RecipeDietaryInfoPersistenceTests | — |
| Nutrition auto-calc per serving | ✅ | NutritionCalculatorTests | — |
| Recipe notes | ⚠️ | RecipeNotesFormatterTests | Formatter only, no persistence test |
| Seed/sample recipes | ✅ | SeedRecipeProviderTests | — |
| Servings scaling | ⚠️ | RecipeModelTests | No persistence round-trip |

---

## Import

| Feature | Status | Test file(s) | Gap |
|---|---|---|---|
| URL / link import | ✅ | RecipeImporterTests, RecipeImportFixtureTests, RecipeImportPersistenceTests | — |
| Paste text import | ✅ | TextRecipeParserTests, SharedTextImporterTests, TextRecipeFixtureTests | — |
| Photo OCR import | ✅ | RecipeImageTextRecognizerTests | Service layer only; full save flow untested |
| Share extension inbox | ✅ | SharedImportInboxTests | — |
| AI free-text import (FoundationModels) | ⚠️ | OnDeviceRecipeImportStatusTests | Adapter only; no round-trip |
| Import duplicate detection | ⚠️ | BackupMergeTests | Covered indirectly |

---

## Search & filtering

| Feature | Status | Test file(s) | Gap |
|---|---|---|---|
| Text search | ❌ | — | No test for search predicate |
| Filter by category | ✅ | RecipeFilterCriteriaTests, RecipeFilterIntegrationTests | — |
| Filter by difficulty | ✅ | RecipeFilterCriteriaTests | — |
| Filter by dietary info | ✅ | RecipeFilterCriteriaTests | — |
| Filter by available ingredients | ✅ | KitchenRecipeMatcherTests | — |
| **Filter by tag** | ✅ | RecipeFilterCriteriaTests, RecipeFilterIntegrationTests | — |
| **Filter by collection** | ❌ | — | Collections not in RecipeFilterCriteria |
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
| **Add all collection ingredients to shopping list** | ❌ | — | View-level, no test |
| **Filter recipes by collection** | ❌ | — | Not wired into RecipeFilterCriteria |

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
| firstImport / firstPhotoImport / headChef | ⚠️ | BadgeManagerTests (unlock only) | View-level triggers untested |
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

## Priority gaps (start here)

1. **Filter by collection** — add `collectionID: UUID?` to `RecipeFilterCriteria`, wire into filter UI
3. **Favorites persistence** — quick round-trip test
4. **Text search test** — cover the search predicate logic
5. **Auth flows** — blocked on DI seam; tracked in hardening backlog
