# RecipeFinder

Smart recipe management. All your data, stored locally.

[![Build](https://github.com/AsadK47/RecipeFinder/actions/workflows/build.yml/badge.svg)](https://github.com/AsadK47/RecipeFinder/actions/workflows/build.yml)

---

## Overview

RecipeFinder helps you organize recipes, plan meals, and manage your kitchen—all without sending your data anywhere.

**Built with SwiftUI and Core Data.** Zero external dependencies.

---

## At a Glance

Import recipes from the web • Create shopping lists • Track kitchen inventory • Plan your week • Export to PDF

---

## Get Started

```bash
git clone https://github.com/AsadK47/RecipeFinder.git
cd RecipeFinder
open RecipeFinder.xcodeproj
```

**Requires** iOS 15.0+ • Xcode 14.0+ • Swift 5.7+

---

## What's Inside

### Recipes
Store, edit, and scale recipes. Import from any website using Schema.org parsing. Export with one tap.

### Shopping & Kitchen
Automatically categorized shopping lists. Track what's in your pantry. See what you can make right now.

### Meal Planning
Drag recipes onto a calendar. Plan weeks ahead. Create new recipes on the fly.

---

## Under the Hood

**Architecture**
- SwiftUI with MVVM
- Core Data for persistence
- Combine for reactive updates

**Performance**
- <1s launch time
- 60fps UI
- ~70MB memory footprint

**Privacy**
- Everything stays on your device
- No tracking or analytics
- Class C encryption via iOS Data Protection

**Accessibility**
- VoiceOver support
- Dynamic Type scaling
- WCAG AA contrast ratios
- Haptic feedback

---

## Build & Test

```bash
./scripts/test.sh && ./scripts/lint.sh
xcodebuild -scheme RecipeFinder -destination 'platform=iOS Simulator,name=iPhone 15'
```

---

## What's Next

**v1.0** (Current)
Recipe management • Shopping lists • Kitchen inventory

**v1.1** (In Progress)
Meal planning calendar • Recipe Wizard • Persistent schedules

**v2.0** (Future)
iCloud sync • AI suggestions • Camera scanning • Siri Shortcuts

---

## Learn More

[Design Language](docs/DESIGN_AESTHETIC.md) • [PDF Export](docs/PDF_DESIGN_GUIDE.md) • [Commands](docs/COMMANDS.md)

---

## Support

Found a bug? [Open an issue](https://github.com/AsadK47/RecipeFinder/issues)  
Have an idea? [Start a discussion](https://github.com/AsadK47/RecipeFinder/discussions)

---

## Legal

**Proprietary Software** © 2024-2025 Asad Khan. All rights reserved.

You can view the code. You cannot use, modify, or distribute it without permission.

[License](./LICENSE) • [Privacy Policy](./legal/PRIVACY_POLICY.md) • [Terms](./legal/TERMS_OF_SERVICE.md)

**Contact:** asadkhanruby@gmail.com

---

*Built with SwiftUI • Uses SF Pro Display & SF Pro Text system fonts*
