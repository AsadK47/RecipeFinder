# RecipeFinder

A SwiftUI-based iOS application for recipe discovery through ingredient-based search and kitchen inventory management.

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](#)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Overview

RecipeFinder implements an ingredient-driven recipe matching system with local persistence, enabling users to identify recipes based on available kitchen inventory. The application employs Core Data for efficient local storage and operates fully offline.

## Technical Stack

- **Language:** Swift 5.7+
- **UI Framework:** SwiftUI
- **Data Persistence:** Core Data
- **Minimum Target:** iOS 15.0+
- **Dependencies:** ConfettiSwiftUI

## Core Features

- **Ingredient-Based Search:** Query recipes by available ingredients
- **Kitchen Inventory System:** Persistent storage of ingredient availability
- **Recipe Import:** URL-based recipe import with Schema.org parsing
- **Shopping List Management:** Track required ingredients
- **Unit Conversion:** Dynamic metric/imperial measurement conversion
- **Favorites System:** Bookmark your favorite recipes with visual indicators
- **Recipe Sharing:** Export recipes as text, PDF, or copy to clipboard

## Screenshots

<img src="docs/screenshots/screenshot-home.png" width="500" alt="Home View"/>
<img src="docs/screenshots/screenshot-recipe-detail.png" width="500" alt="Recipe Detail"/>
<img src="docs/screenshots/screenshot-kitchen.png" width="500" alt="Kitchen Inventory"/>

## System Requirements

- macOS with Xcode 14.0+
- iOS 15.0+ deployment target
- Swift 5.7+

## Installation

```bash
git clone https://github.com/AsadK47/RecipeFinder.git
cd RecipeFinder
open RecipeFinder.xcodeproj
```

Build and run: `⌘R`

## Architecture

```
RecipeFinder/
├── Components/          # Reusable UI components
├── Models/              # Data models and Core Data schema
├── Persistence/         # Storage managers
├── Utilities/           # Helper functions and extensions
├── Views/               # Feature-specific view hierarchy
└── Theme/               # Styling and theming
```

## Testing

Execute unit tests: `⌘U`

## Development Commands

```bash
# Clean build
⌘⇧K

# Clear derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reset simulator
Device → Erase All Content and Settings
```

## Contributing

Submit pull requests with:
- Clear description of changes
- Updated documentation
- Screenshots for UI modifications (300px width)

## License

MIT License - see [LICENSE](LICENSE) file

## Future Development

- iCloud synchronization
- Machine learning ingredient suggestions
- Enhanced accessibility features
- Localization support
