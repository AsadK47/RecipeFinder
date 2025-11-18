<div align="center">

# RecipeFinder™ 🍳

**Sophisticated recipe management with stunning design**  
*All your culinary treasures, beautifully organized. Completely private.*

[![Platform](https://img.shields.io/badge/platform-iOS%2015.0%2B-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org/)
[![Xcode](https://img.shields.io/badge/Xcode-16.0%2B-blue.svg)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/license-Proprietary-red.svg)](LICENSE)

**[Visit recipefinder.uk →](https://recipefinder.uk)**

</div>

## 📸 Demo

<div align="center">

<img src="screenshots/create_account.png" alt="Create Account" width="250"/>
<img src="screenshots/home_page.png" alt="Home Page" width="250"/>
<img src="screenshots/splash_1.png" alt="Welcome Splash" width="250"/>

*Beautiful recipe management from sign-up to cooking*

</div>

## ✨ Why RecipeFinder?

- **Privacy First** - All data stays on your device. No accounts required, no tracking, no analytics
- **Beautiful Design** - Six elegant color themes with seamless light/dark mode
- **Complete Toolkit** - Recipes, shopping lists, meal planning, kitchen inventory, and timers in one app
- **Smart Import** - Grab recipes from any website with automatic ingredient parsing
- **Offline Ready** - Full functionality without internet connection

## 🚀 Installation

### For Users
*Coming soon to the App Store*

### For Developers

```bash
git clone https://github.com/AsadK47/RecipeFinder.git
cd RecipeFinder
open RecipeFinder.xcodeproj  # Press ⌘+R to run
```

**Requirements**: iOS 15.0+ • Xcode 16.0+ • Swift 6.0 • macOS 15.0+

## 📱 Features

### Core Features
- **� Recipe Management** - Curated collection, URL import, custom creation, favorites, and sharing
- **🛒 Smart Shopping Lists** - Auto-categorized ingredients, add from recipes, track inventory
- **🍽 Meal Planning** - Weekly calendar, schedule meals, get automatic notifications
- **🏠 Kitchen Inventory** - Track ingredients, expiry dates, find recipes you can make now
- **⏲ Multi-Timers** - Run multiple named timers with background alerts and haptic feedback

### Security & Privacy
- **🔐 Local Authentication** - Face ID/Touch ID support with SHA-256 password hashing
- **🔒 Secure Storage** - iOS Keychain integration with Secure Enclave
- **🚫 Zero Tracking** - No analytics, no data collection, GDPR/CCPA compliant

### Design & Accessibility
- **🎨 Six Color Themes** - Beautiful palettes that work in light and dark modes
- **♿️ Accessible** - VoiceOver support, Dynamic Type, WCAG 2.1 AA contrast, 44pt tap targets
- **⚡️ Smooth Performance** - Hardware-accelerated rendering, optimized Core Data

## 🏗 Technical Stack

**Architecture**: SwiftUI with MVVM pattern • Core Data persistence • Combine for reactive programming  
**Dependencies**: Zero external dependencies - 100% native Swift and Apple frameworks  
**Performance**: Hardware-accelerated rendering • Async image loading • Optimized Core Data fetches  
**Security**: Local-first storage • SHA-256 password hashing • iOS Keychain • Secure Enclave biometrics  
**Privacy**: No analytics • No tracking • GDPR/CCPA compliant • All data stays on device  
**Accessibility**: VoiceOver support • Dynamic Type • WCAG 2.1 AA contrast • 44pt tap targets

## 🛠 For Developers

### Build Commands

```bash
# Run tests
./scripts/test.sh

# Lint code  
./scripts/lint.sh

# Build for simulator
xcodebuild -scheme RecipeFinder \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  clean build

# Build for device  
xcodebuild -scheme RecipeFinder \
  -destination 'generic/platform=iOS' \
  -configuration Release \
  clean build
```

### Project Structure

```
RecipeFinder/
├── Components/      # Reusable UI components
├── Views/          # Screen views
├── Models/         # Data models
├── Persistence/    # Core Data & managers
├── Theme/          # Design system
├── Utilities/      # Helpers & extensions
└── Services/       # Business logic
```

### Key Files
- `AppTheme.swift` - Complete design system
- `NotificationManager.swift` - Local notifications
- `PersistenceController.swift` - Core Data stack
- `RecipeImporter.swift` - Web recipe parsing

##  Documentation

- **[Design Language](docs/DESIGN_AESTHETIC.md)** - Visual design principles
- **[Theme Colors](docs/THEME_COLORS.md)** - Complete color palette
- **[PDF Export Guide](docs/PDF_DESIGN_GUIDE.md)** - Beautiful recipe PDFs
- **[Notifications Guide](docs/NOTIFICATIONS_GUIDE.md)** - How notifications work
- **[SF Symbols Guide](docs/SF_SYMBOLS_GUIDE.md)** - Icon usage
- **[Commands](docs/COMMANDS.md)** - Development commands

## 💬 Support & Contact

- 🐛 **Report Bugs**: [GitHub Issues](https://github.com/AsadK47/RecipeFinder/issues)
- 💡 **Feature Requests**: [GitHub Discussions](https://github.com/AsadK47/RecipeFinder/discussions)
- 📧 **Email**: recipefinderlimited@icloud.com
- 🌐 **Website**: [recipefinder.uk](https://recipefinder.uk)

> **Note**: This is proprietary software. Pull requests are not accepted.

## ⚖️ License & Legal

**Copyright © 2024-2025 RECIPEFINDER LIMITED. All Rights Reserved.**

This software is proprietary. Company No. 16833243 (England and Wales).

For complete terms, see:
- 📄 [Full License Agreement](./LICENSE)
- 🔒 [Privacy Policy](https://recipefinder.uk/privacy.html)
- 📋 [Terms of Service](https://recipefinder.uk/terms.html)

For licensing inquiries: recipefinderlimited@icloud.com

<div align="center">

---

**© 2024-2025 RECIPEFINDER LIMITED • All Rights Reserved**

Made with ❤️ in the UK • [recipefinder.uk](https://recipefinder.uk)

</div>
