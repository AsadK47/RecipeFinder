# RecipeFinder

Personal recipe manager with smart categorization and local-only storage. Built with SwiftUI and Core Data.

[![Build](https://github.com/AsadK47/RecipeFinder/actions/workflows/build.yml/badge.svg)](https://github.com/AsadK47/RecipeFinder/actions/workflows/build.yml)

## Table of Contents

- [RecipeFinder](#recipefinder)
  - [Table of Contents](#table-of-contents)
  - [Features](#features)
  - [Quick Start](#quick-start)
  - [Core Subsystems](#core-subsystems)
    - [Recipe Management](#recipe-management)
    - [Shopping \& Kitchen](#shopping--kitchen)
    - [Meal Planning](#meal-planning)
  - [Development](#development)
  - [Performance \& Security](#performance--security)
    - [Performance Metrics](#performance-metrics)
    - [Security \& Privacy](#security--privacy)
    - [Accessibility](#accessibility)
  - [Roadmap](#roadmap)
    - [Current (v1.0)](#current-v10)
    - [Next (v1.1 - Meal Planning System)](#next-v11---meal-planning-system)
    - [Future (v2.0+)](#future-v20)
  - [Documentation](#documentation)
  - [Support](#support)
  - [Legal \& Contact](#legal--contact)
    - [License](#license)
    - [Legal Documentation](#legal-documentation)
    - [Contact](#contact)
    - [Trademark Notice](#trademark-notice)

---

## Features

Recipe management • Shopping lists • Kitchen inventory • Meal planning • PDF export

## Quick Start

```bash
git clone https://github.com/AsadK47/RecipeFinder.git
cd RecipeFinder
open RecipeFinder.xcodeproj
```

**Requirements:** iOS 15.0+ • Xcode 14.0+ • Swift 5.7+

---

## Core Subsystems

### Recipe Management
The recipe subsystem provides full CRUD (Create, Read, Update, Delete) operations with Core Data as the persistence layer. Recipes can be imported via web URLs using Schema.org JSON-LD parsing for automatic metadata extraction. The system supports PDF and text export with dynamic ingredient scaling based on serving size calculations. All recipe data is stored in a normalized relational schema optimized for query performance.

### Shopping & Kitchen
The shopping subsystem implements automatic categorization using a keyword-based classification algorithm with a 500+ term database mapping ingredients to 20 predefined categories (e.g., Dairy, Produce, Meat & Seafood). The kitchen inventory module tracks ingredient quantities with expiration date monitoring and provides real-time availability checking against recipe requirements. Both systems share a common ingredient normalization layer to handle unit conversions and naming variations.

### Meal Planning
The meal planning subsystem features an interactive calendar interface with Core Data persistence for meal schedules. Users can assign recipes to specific dates and meal times (Breakfast, Brunch, Lunch, Snack, Dinner, Late Night) through either recipe selection from the existing library or in-line creation via the Recipe Wizard. The system maintains referential integrity between meal plans and recipes through Core Data relationships, supporting cascading updates and deletions.

---

## Development

```bash
# Run tests and linter
./scripts/test.sh && ./scripts/lint.sh

# Build and run
xcodebuild -scheme RecipeFinder -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Tech Stack:**
- Swift 5.7+ with SwiftUI for declarative UI and zero external dependencies
- Core Data for local persistence with MVVM architecture
- Combine for reactive state management with `@Published` properties

---

## Performance & Security

### Performance Metrics
- App launch time <1s, UI frame rate 60fps, memory footprint ~70MB
- LazyVStack for list virtualization and background contexts for Core Data writes
- O(1) dictionary lookups for category classification with pre-computed gradients

### Security & Privacy
- All data stored locally with iOS Data Protection API (Class C encryption)
- No analytics, tracking, or third-party SDKs - GDPR/CCPA compliant by design
- No user accounts required with TLS 1.3 for HTTPS connections only

### Accessibility
- VoiceOver support with semantic labels and Dynamic Type (50%-200% font scaling)
- WCAG AA contrast ratios (4.5:1 minimum) and reduced motion support
- Haptic feedback for non-visual confirmation

---

## Roadmap

### Current (v1.0)
- Core recipe CRUD operations with Schema.org import
- Auto-categorized shopping lists and kitchen inventory management
- PDF/text export system

### Next (v1.1 - Meal Planning System)
- Interactive calendar view with meal time categorization
- Recipe Wizard integration for on-the-fly creation
- Persistent meal plans with Core Data

### Future (v2.0+)
- iCloud sync (optional), internationalization, and Siri Shortcuts
- AI-powered recipe suggestions with GPT-4 integration
- Camera-based ingredient scanning using Vision + ML

---

## Documentation

**Design & UX:**
- [Design Aesthetic](docs/DESIGN_AESTHETIC.md) - Visual design language
- [PDF Design Guide](docs/PDF_DESIGN_GUIDE.md) - Export format standards

**Development:**
- [Commands Reference](docs/COMMANDS.md) - Complete CLI command list
- [Category Classifier](docs/CATEGORY_CLASSIFIER_EXPANSION.md) - Taxonomy extension guide

---

## Support

**Bug Reports:** [GitHub Issues](https://github.com/AsadK47/RecipeFinder/issues)  
**Feature Requests:** [GitHub Discussions](https://github.com/AsadK47/RecipeFinder/discussions)

---

## Legal & Contact

### License

**Proprietary Software** - © 2024-2025 Asad Khan. All Rights Reserved.

This software is NOT open-source. Unauthorized copying, distribution, modification, or use is strictly prohibited.

| Permission | Allowed |
|------------|---------|
| View source code | ✅ Yes |
| Use/modify/distribute | ❌ No (without permission) |

**Full License:** [LICENSE](./LICENSE)

### Legal Documentation

- [Intellectual Property Protection](./legal/IP_PROTECTION.md)
- [Terms of Service](./legal/TERMS_OF_SERVICE.md)
- [Privacy Policy](./legal/PRIVACY_POLICY.md)

### Contact

**All Inquiries:** asadkhanruby@gmail.com  
**Response Time:** 48-72 hours (business days)

### Trademark Notice

"RecipeFinder" and associated logos are trademarks of Asad Khan.

---

**Document Version:** 1.0  
**Last Updated:** 2025
