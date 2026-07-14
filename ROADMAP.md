# RecipeFinder Roadmap

## Legend
- 🔴 Not Started
- 🟡 In Progress
- 🟢 Done

---

## Phase 1: Visual & Media Foundations

### 🔴 Recipe Images via Unsplash API
*(Status corrected July 2026: no Unsplash code exists yet. Note: URL import already extracts recipe images from JSON-LD / Open Graph tags, so imported recipes get images for free — Unsplash is only needed for manually created recipes.)*
- Integrate Unsplash search-by-recipe-name to auto-assign images
- Cache images locally (NSCache + disk) so API is called once per recipe
- Add `imageURL` field to Core Data model
- Update `RecipeImageView` to support remote URLs with placeholder fallback
- Store API key securely via `.xcconfig` (excluded from git)
- **Scaling concern:** Free tier = 50 req/hr. For multi-user growth, consider a server-side proxy that caches URLs centrally so the same "Chicken Curry" image URL is reused across users without redundant API calls

### 🟢 User Photo for Recipes *(completed July 2026)*
- ~~Allow users to pick a photo from their library~~ — PhotosPicker in RecipeWizardView
- ~~Store as compressed JPEG in app sandbox (not Core Data blob)~~ — saved to Documents with cleanup of replaced images
- ~~User photo takes priority over remote image when both exist~~ — RecipeImageView supports local references
- Remaining: "take a photo" via camera (requires re-adding NSCameraUsageDescription build setting)

---

## Phase 2: Smart Recipe Import

### 🔴 Instagram & TikTok Recipe Import
- Paste a URL → extract recipe content
- Options to explore:
  - **Server-side scraping** (most reliable) — extract structured data from page HTML / Open Graph tags
  - **On-device LLM** (iOS 18+ Foundation Models) — paste caption text → parse into structured recipe
  - **Share Sheet extension** — user shares directly from Instagram/TikTok into RecipeFinder
- Parse into: name, ingredients, instructions, prep/cook time, servings
- Let user review/edit before saving

### 🔴 Photo-to-Recipe Conversion
- Point camera at a cookbook page, handwritten recipe, or screenshot
- Use Vision framework (OCR) to extract text
- Parse extracted text into structured recipe fields using on-device NLP or LLM
- User reviews and confirms before saving

---

## Phase 3: Nutrition

### 🔴 Nutritional Information
- Display calories, protein, carbs, fat, fibre per serving
- **Data source options:**
  - Open Food Facts API (free, open-source)
  - USDA FoodData Central API (free, US government)
  - Edamam Nutrition API (free tier available)
- **UX approach:** Toggle per recipe (not a global setting) — some users care about nutrition for weeknight meals but not for baking
- Show as a collapsible section on recipe detail view
- Consider a "Nutrition Summary" on the meal plan weekly view
- Recalculate when servings are adjusted

---

## Phase 4: Meal Planning Enhancements

### 🟡 Expanded Meal Planner
- Drag-and-drop to rearrange meals between days
- ~~Meal type slots: Breakfast, Lunch, Dinner, Snack~~ 🟢 — `MealTime` enum with icons/ordering in MealPlanModel
- Weekly overview with nutritional summary (ties into Phase 3)
- "Suggest a meal" — recommend recipes from saved collection based on: unused ingredients, variety, dietary preferences
- Recurring meals (e.g., "Meal Prep Sunday")
- Auto-generate shopping list from the week's meal plan

---

## Phase 5: Shopping Integration

### 🔴 Supermarket Connection
- Link shopping list to supermarket suppliers (Tesco, Sainsbury's, Ocado, etc.)
- Match ingredient names to supermarket product catalogue
- Auto-build a basket on the retailer's site/app
- **Implementation options:**
  - Deep link into retailer apps (if supported)
  - Retailer affiliate APIs (Tesco API, Ocado partner programme)
  - Web scraping (fragile, last resort)
- Price comparison across retailers
- Smart substitution suggestions (e.g., "Tesco doesn't have X — here's a similar product")

---

## Phase 6: Quality of Life & Engagement

### 🟡 Smart Search & Filtering
- ~~Search by ingredient ("what can I make with chicken and rice?")~~ 🟢 — "available ingredients only" toggle with ≥80% match scoring in RecipeSearchView
- Filter by dietary restriction, cook time, difficulty (partially present — verify coverage)
- Recently viewed / frequently cooked

### 🔴 Cooking Mode
- Step-by-step instruction view with large text
- Voice control ("next step", "repeat")
- Built-in timers per step (existing timer feature could integrate here)

### 🔴 Recipe Sharing
- Share recipes as rich links or formatted cards
- Import shared recipes from other RecipeFinder users
- Export as PDF for printing

### 🔴 Collections & Tags
- User-created collections beyond favourites ("Weeknight Dinners", "Party Food")
- Custom tags with colour coding
- Smart collections (auto-populated based on rules)

### 🔴 Widget Support
- Today's meal plan on home screen
- Random recipe suggestion widget
- Shopping list quick-view widget

---

## Completed

### 🟢 Health Check & Release Prep (July 2026)
- Fixed `signUp()` overwriting existing accounts' credentials (account-takeover bug)
- Aligned `signUpWithoutLogin()` password validation with the real policy (Validator)
- Fixed PBKDF2 failure producing an empty-string hash instead of nil
- `UIRequiredDeviceCapabilities` armv7 → arm64; removed unused camera/photo permission strings
- Consolidated Info.plist keys into `INFOPLIST_KEY_*` build settings; resolved duplicate Face ID usage strings
- Removed dead `SwiftData` imports; readme accuracy pass (iOS 17.5+, real dependencies, PBKDF2)

### 🟢 Bug Fixes (March 2026)
- Fixed `clearAllData()` using global `UserDefaults` instead of `UserScopedStorage`
- Fixed `unlockWelcomeBadge()` storing `accountCreationDate` globally
- Fixed `hasPopulatedDatabase` flag not scoped per user
- Moved User PII from plain `UserDefaults` to Keychain storage
- Fixed `deleteAccount()` not cleaning up all persisted keys
- Fixed `signUpWithoutLogin()` leaking PII to unscoped storage
- Preserved `createdAt` across sign-in cycles
- Removed redundant `updateStats()` call
- Converted nested if/else chains to guard clauses

---

## Notes

- **API Keys:** All API keys stored in `.xcconfig` files excluded from version control
- **Privacy First:** Minimal data collection, all user data scoped per account
- **Offline First:** Core features work without internet; network features degrade gracefully
