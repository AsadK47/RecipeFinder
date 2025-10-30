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
| `CategoryClassifier` | ML-based ingredient categorization | ✓ |
| `RecipeImporter` | Schema.org JSON-LD parser | ✓ |
| `ShoppingListManager` | Shopping list CRUD operations | ✓ |
| `KitchenInventoryManager` | Inventory state management | ✓ |
| `AppTheme` | Theme system with 8 color schemes | ✓ |

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

### Quality Assurance

```bash
# Code quality check
./scripts/lint.sh

# Test suite
./scripts/test.sh

# Individual test
./scripts/test-single.sh <TestFileName>
```

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
- Weekly meal planning interface
- Theme-aware animation colors
- Enhanced error handling
- Loading state UI
- Onboarding flow

### Future Releases

**v1.1**: ☁️ iCloud sync (optional), 🌍 localization (ES, FR, DE), 🗣️ Siri integration  
**v2.0**: 🤖 AI-powered recipe suggestions, 📸 ingredient scanning, 🥗 nutrition analysis

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

- 📖 [Design Aesthetic](docs/DESIGN_AESTHETIC.md)
- 📄 [PDF Design Specification](docs/PDF_DESIGN_GUIDE.md)
- 🎨 [Theme Colors](docs/THEME_COLORS.md)

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
