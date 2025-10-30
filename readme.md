# RecipeFinder

📱 Privacy-first recipe management for iOS with intelligent categorization and beautiful design.

![Swift](https://img.shields.io/badge/Swift-5.7+-FA7343?logo=swift&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-15.0+-000000?logo=apple&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-blue?logo=swift&logoColor=white)
![License](https://img.shields.io/badge/License-Proprietary-red)

---

## Overview

RecipeFinder is a native iOS application for recipe discovery, organization, and meal preparation. The application emphasizes privacy-first architecture, storing all data locally on device with zero telemetry or external data transmission.

### Key Capabilities

- 📖 **Recipe Management**: Import recipes from Schema.org-compliant websites, export as PDF or plain text
- 🥘 **Inventory Tracking**: Monitor kitchen ingredients with automatic recipe feasibility detection
- 🛒 **Shopping Lists**: Automatically categorized by ingredient type (Produce, Dairy, Meat, Pantry, etc.)
- 🎨 **Theme System**: Eight color schemes with custom gradients
- 🔒 **Zero Tracking**: No analytics, no user accounts, no cloud dependencies

---

## Technical Architecture

### Technology Stack

```
SwiftUI           → User interface framework
Core Data         → Local persistence layer
XCTest            → Unit testing framework
SwiftLint         → Code quality enforcement
```

### Project Structure

```
RecipeFinder/
├── 📱 Components/        Reusable UI components
├── 📦 Models/            Data models and Core Data entities
├── 💾 Persistence/       Storage controllers and managers
├── 🔌 Services/          External integrations (empty)
├── 🎨 Theme/             Design system and color schemes
├── 🛠️  Utilities/         Helper functions and extensions
├── 📺 Views/             Feature modules
└── 🧪 RecipeFinderTests/ Unit test suite (12 test files)
```

### Core Components

| Component | Function | Test Coverage |
|-----------|----------|---------------|
| `RecipeModel` | Recipe data structure with serving calculations | ✓ |
| `CategoryClassifier` | World-class ingredient categorization (20 shopping + 14 kitchen categories) | ✓ |
| `RecipeImporter` | Schema.org JSON-LD parser | ✓ |
| `ShoppingListManager` | Shopping list CRUD operations | ✓ |
| `KitchenInventoryManager` | Inventory state management | ✓ |
| `AppTheme` | Theme system with 8 color schemes | ✓ |

---

## 🏷️ Intelligent Categorization System

### CategoryClassifier Overview

RecipeFinder features a **world-class food categorization system** with **500+ ingredient keywords** covering international cuisines and professional culinary standards.

#### Categories

**Shopping List (20 categories)**:
- 🍃 Produce
- 🍴 Meat  
- 🐦 **Poultry** (separated from Meat)
- 🐟 Seafood
- 💧 Dairy & Eggs
- 🎂 Bakery
- 🥡 **Grains & Pasta**
- ⊗ **Legumes & Pulses**
- 🌿 **Nuts & Seeds**
- 🍃 **Herbs & Fresh Spices** (separated from dried)
- ✨ **Dried Spices & Seasonings**
- 💧 **Oils & Fats**
- 🍾 **Sauces & Condiments**
- 🥫 **Canned & Jarred**
- ❄️ Frozen
- ☕ Beverages
- ⭐ **Sweeteners**
- ⚖️ **Baking Supplies**
- 📷 Snacks
- 🧺 Other

**Kitchen Inventory (14 categories)**:
- Meat, **Poultry**, Seafood, Vegetables, **Fruits**, **Grains & Pasta**, **Legumes & Pulses**, **Nuts & Seeds**, Dairy & Eggs, **Herbs & Fresh Spices**, **Dried Spices & Seasonings**, **Oils & Fats**, Sauces & Condiments, **Sweeteners**

### International Cuisine Coverage

The system comprehensively supports:

**Asian**: Japanese (miso, dashi, yuzu), Chinese (five spice, bok choy), Korean (gochujang, kimchi), Thai (fish sauce, lemongrass, galangal), Indian (garam masala, curry leaf, paneer)

**Middle Eastern**: Za'atar, sumac, tahini, harissa, pomegranate molasses, baharat, dukkah

**Latin American**: Chipotle, ancho, guajillo, adobo, plantain, yucca, queso fresco

**European**: Italian (parmigiano reggiano, balsamic), French (gruyère, herbes de provence), Spanish (manchego, smoked paprika)

**Mediterranean**: Olive oil, feta, halloumi, oregano, capers, anchovies

### Example Categorizations

```swift
// Proteins
"chicken breast"        → Poultry
"ribeye steak"          → Meat
"salmon fillet"         → Seafood

// Vegetables & Fruits
"cherry tomatoes"       → Produce
"fresh mango"           → Fruits
"baby bok choy"         → Produce

// Grains & Legumes
"basmati rice"          → Grains & Pasta
"black beans"           → Legumes & Pulses
"almond butter"         → Nuts & Seeds

// Seasonings
"fresh basil"           → Herbs & Fresh Spices
"garam masala"          → Dried Spices & Seasonings
"sesame oil"            → Oils & Fats

// International
"gochujang"             → Sauces & Condiments
"za'atar"               → Dried Spices & Seasonings
"ponzu"                 → Sauces & Condiments
```

### Coverage Statistics

- **Total Keywords**: 500+
- **Shopping Categories**: 20
- **Kitchen Categories**: 14
- **Meat Varieties**: 45+ (beef, pork, lamb, veal, venison, bison, wild boar)
- **Poultry Types**: 20+ (chicken, turkey, duck, goose, quail)
- **Seafood Types**: 40+ (salmon, tuna, shrimp, scallop, octopus, caviar)
- **Vegetables**: 70+ (alliums, nightshades, roots, brassicas, greens, squashes, mushrooms)
- **Fruits**: 40+ (citrus, berries, tropical, stone fruits, melons)
- **Grains & Pasta**: 60+ (rice varieties, breads, Italian pasta, Asian noodles)
- **Cheeses**: 30+ (fresh, soft, semi-hard, hard, blue, goat)
- **Spice Blends**: 25+ (Indian, Middle Eastern, Asian, Caribbean)
- **Sauces**: 80+ (Asian, Western, European, fermented, vinegars, stocks)

### Technical Implementation

**Research Sources**: Bon Appétit, Serious Eats, Food Network, USDA Food Categories

**Features**:
- Priority-based categorization (most specific first)
- Comprehensive keyword matching (500+ ingredients)
- Smart descriptor filtering (removes "fresh", "organic", "boneless", etc.)
- SF Symbol icons for all categories
- Semantic color coding
- Legacy support for backward compatibility

For complete details, see [Category Classifier Expansion](docs/CATEGORY_CLASSIFIER_EXPANSION.md) and [Category Quick Reference](docs/CATEGORY_QUICK_REFERENCE.md).

---

## Testing Methodology

### Test Coverage

The project maintains focused unit test coverage on business logic components:

```bash
# Run all tests
./scripts/test.sh

# Run individual test file
./scripts/test-single.sh RecipeModelTests
```

### Testing Philosophy

**✅ Tested**: Models, Utilities, Persistence, Theme (12 test files)  
**⏭️  Not Tested**: UI Components (presentational, no business logic)

#### Component Testing Strategy

SwiftUI components are evaluated on a case-by-case basis:

**✅ Test when components contain:**
- Business logic or data transformations
- Complex state management
- Reusable logic across 3+ views
- Critical functionality (authentication, payment)

**⏭️  Skip testing for:**
- Pure presentational components
- Simple layout wrappers
- Static content displays

**📊 Current assessment**: RecipeFinder components are primarily presentational. Future testing may utilize ViewInspector for structural validation or snapshot testing for visual regression detection.

---

## Design System

### Theme Architecture

The application provides eight distinct color themes, each with a multi-stop gradient:

| Theme | Primary Gradient | Use Case |
|-------|------------------|----------|
| 🩵 Teal | Teal → Blue → Ocean Blue | Default theme |
| 💜 Purple | Purple → Violet → Turquoise | Creative aesthetic |
| 🧡 Orange | Tangerine → Coral → Deep Coral | Warm tones |
| 💗 Pink | Hot Pink → Magenta → Purple-Blue | Vibrant aesthetic |
| ⭐ Gold | Gold → Silver → Bronze → Black | Luxury aesthetic |
| ❤️ Red | Crimson → Burnt Sienna → Orange | Bold palette |
| 💚 Green | Emerald → Teal → Ocean | Fresh palette |
| 💛 Yellow | Sunshine → Amber → Orange | Bright palette |

---

## Development

### Requirements

- 💻 macOS 13.0 or later
- 🔨 Xcode 15.0 or later
- 📱 iOS 15.0+ deployment target
- 🦅 Swift 5.7+

### Setup

```bash
git clone https://github.com/AsadK47/RecipeFinder.git
cd RecipeFinder
open RecipeFinder.xcodeproj
```

Build and run: `⌘R`

##### Quality Assurance

```bash
# Code quality check
./scripts/lint.sh

# Test suite
./scripts/test.sh

# Individual test
./scripts/test-single.sh <TestFileName>
```

---

## 🛠️ Developer Commands

### Linting

```bash
# Run SwiftLint on entire project
./scripts/lint.sh

# Or manually
swiftlint lint --path RecipeFinder/ --config .swiftlint.yml

# Auto-fix issues (where possible)
swiftlint --fix --path RecipeFinder/

# Install SwiftLint (if not installed)
brew install swiftlint
```

### Testing

```bash
# Run all tests
./scripts/test.sh

# Or using xcodebuild
xcodebuild test \
    -scheme RecipeFinder \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest'

# Run specific test
xcodebuild test \
    -scheme RecipeFinder \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    -only-testing:RecipeFinderTests/RecipeModelTests

# In Xcode: ⌘ + U
```

### Building

```bash
# Build for simulator
xcodebuild build \
    -scheme RecipeFinder \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Build for device
xcodebuild build \
    -scheme RecipeFinder \
    -destination 'generic/platform=iOS'

# Clean build
xcodebuild clean -scheme RecipeFinder
# Or in Xcode: ⌘ + Shift + K
```

### Code Quality Checks

```bash
# Count lines of code
find RecipeFinder -name '*.swift' | xargs wc -l

# Find TODO/FIXME comments
grep -rn "TODO\|FIXME" RecipeFinder/

# Check for force unwraps
grep -rn "!" RecipeFinder/ | grep -v "//"
```

### Troubleshooting

```bash
# List available simulators
xcrun simctl list devices

# Boot a simulator
xcrun simctl boot "iPhone 17 Pro"

# Clean Derived Data
rm -rf ~/Library/Developer/Xcode/DerivedData
```

For complete command reference, see [Commands Documentation](docs/COMMANDS.md).

---

## Roadmap

### Current Development (v1.0)

**✅ Completed**:
- Core recipe CRUD operations
- Schema.org import functionality
- PDF/text export
- Kitchen inventory tracking
- Auto-categorized shopping lists
- 8-theme system

**🔄 In Progress**:
- Biometric authentication (Face ID/Touch ID)
- Theme-aware animation colors
- Enhanced error handling
- Loading state UI
- Onboarding flow

### Next Phase: Meal Planning System (v1.1)

**📅 Meal Planning Module** - Complete calendar-based meal scheduling with recipe integration

**Features**:
- 📆 **Interactive Calendar View**: Monthly calendar grid with date selection
- 🍽️ **Meal Time Categorization**: Breakfast, Brunch, Lunch, Snack, Dinner, Late Night
- 🔗 **Recipe Integration**: 
  - Launch Recipe Wizard directly from calendar to create new recipes
  - Select from existing recipe library for quick meal planning
  - Auto-populated recipe list with search functionality
- 💾 **Persistent Meal Plans**: Save meal assignments to specific dates and times
- 🎯 **Smart Navigation**: Seamless flow from date selection → meal time → recipe choice

**Implementation Details**:
- New `MealPlanningView` with calendar grid (6-week display)
- `MealTimeSelectorSheet` for choosing meal periods
- `RecipeSelectionSheet` with dual-path: create new vs. select existing
- Direct Recipe Wizard integration for on-the-fly recipe creation
- Month navigation with previous/next controls
- Visual indicators for today's date and selected dates

**User Flow**:
1. User taps calendar date
2. Sheet appears asking for meal time (Breakfast, Lunch, Dinner, etc.)
3. User selects meal time
4. Second sheet presents two options:
   - "Create New Recipe" → Opens Recipe Wizard
   - "Choose Existing Recipe" → Shows filtered recipe list with search
5. Selected recipe is assigned to that date/time slot

**Tab Order** (Final):
- Tab 1: 📖 Recipes
- Tab 2: 🛒 Shopping
- Tab 3: 🍳 Kitchen
- Tab 4: ⚙️ Settings
- Tab 5: 📅 Meals (NEW)

### Future Releases

**v1.2**: ☁️ iCloud sync (optional), 🌍 localization (ES, FR, DE), 🗣️ Siri integration  
**v2.0**: 🤖 AI-powered recipe suggestions, 📸 ingredient scanning, 🥗 nutrition analysis, 📊 grocery cost tracking

---

## Privacy

🔒 RecipeFinder operates entirely on-device. No data is transmitted to external servers. No user accounts are required. No analytics or telemetry is collected.

**📦 Data Storage**: Core Data (local SQLite)  
**🌐 Network Requests**: Recipe import only (user-initiated)  
**🚫 Third-Party SDKs**: None

[Full Privacy Policy](legal/PRIVACY_POLICY.md)

---

## Contributing

RecipeFinder is proprietary software. Contributions require copyright assignment to the project maintainer.

**Standards**:
- ✅ SwiftLint compliance (zero errors)
- 🧪 Test coverage for business logic
- ♿ Accessibility support (VoiceOver, Dynamic Type)

Contact: 📧 asad.e.khan@outlook.com

---

## Documentation

### Design & Aesthetics
- 📖 [Design Aesthetic](docs/DESIGN_AESTHETIC.md)
- 📄 [PDF Design Specification](docs/PDF_DESIGN_GUIDE.md)
- 🎨 [Theme Colors](docs/THEME_COLORS.md)

### Development & Technical
- 🛠️ [Commands Reference](docs/COMMANDS.md)
- 🏷️ [Category Classifier Expansion](docs/CATEGORY_CLASSIFIER_EXPANSION.md)
- 📋 [Category Quick Reference](docs/CATEGORY_QUICK_REFERENCE.md)

---

## Support

**🐛 Issues**: [GitHub Issues](https://github.com/AsadK47/RecipeFinder/issues)  
**📧 Contact**: asad.e.khan@outlook.com

---

## Legal

© 2024-2025 Asad Khan. All rights reserved.

RecipeFinder is proprietary software.

[Terms of Service](legal/TERMS_OF_SERVICE.md) | [Privacy Policy](legal/PRIVACY_POLICY.md) | [IP Protection](legal/IP_PROTECTION.md)

---
