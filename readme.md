# RecipeFinder — Find tasty meals from what's in your kitchen

Welcome to RecipeFinder, a cozy SwiftUI app that helps you turn whatever's in your kitchen into delicious meals. Think of it like a friendly kitchen assistant: tell it what ingredients you have, and it suggests tasty recipes you can make right now.

Got leftovers? Want to use up produce before it goes bad? This app is designed to help.

<!-- Badges -->
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](#)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Quick highlights
----------------

- Find recipes by ingredients instantly
- Save favorites and build a small cookbook
- Keep a simple 'Kitchen' inventory (formerly Pantry) of what you have on hand
- Works offline with local persistence

Built with
----------

- Swift & SwiftUI
- Core Data for local persistence
- ConfettiSwiftUI for delightful micro-interactions

Prerequisites
-------------

- macOS with Xcode 14+ installed
- iOS 15.0+ (deployment target)


Screenshots
-----------

Add screenshots to the `docs/screenshots/` folder and they will show up here. Suggested filenames:

- `screenshot-home.png` — Home/Recipes list
- `screenshot-recipe-detail.png` — Recipe detail view
- `screenshot-kitchen.png` — Kitchen (pantry) inventory

![Home screenshot placeholder](docs/screenshots/screenshot-home.png)
![Recipe detail placeholder](docs/screenshots/screenshot-recipe-detail.png)
![Kitchen placeholder](docs/screenshots/screenshot-kitchen.png)

Cool features
-------------

Here are some of the standout features packed into RecipeFinder:

- Quick Recipe Matches — Automatically shows recipes you can already make from the items in your Kitchen.
- Smart Kitchen Inventory — Add, toggle, and categorize ingredients you have on hand.
- Quick Add — Rapidly add commonly used ingredients grouped by category.
- Shopping List Integration — Add missing ingredients straight from a recipe to your shopping list.
- Favorites & Bookmarks — Save recipes you love for fast access.
- Delightful micro-interactions — small touches like confetti on special actions thanks to ConfettiSwiftUI.

These are pulled together with a modern SwiftUI interface and local persistence so everything works offline.

Requirements
------------

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

Quick start
-----------

1. Clone the repository:

```bash
git clone https://github.com/yourusername/RecipeFinder.git
cd RecipeFinder
```

2. Open in Xcode:

```bash
open RecipeFinder.xcodeproj
```

3. Select a simulator or device and press Cmd + R.

How to use
----------

- Add items to your Kitchen inventory using the Kitchen view.
- Use the search bar to find recipes by ingredient.
- Tap a recipe to view details, add to favorites, or add missing ingredients to your shopping list.

Quick usage example
-------------------

1. Open Kitchen and add items you have using the Quick Add or search
2. Visit the Recipes tab to see Quick Recipe Matches
3. Tap a recipe → Add missing ingredients to the Shopping List

Project structure
-----------------

```text
RecipeFinder/
├── RecipeFinder/               # App source
├── Components/                  # Reusable SwiftUI components
├── Models/                      # Data models and CoreData/xcdatamodeld
├── Persistence/                 # Storage and managers (Kitchen, Shopping List)
├── Views/                       # SwiftUI screens grouped by feature
└── docs/screenshots/            # Put screenshots here to show in README
```

Development
-----------

Run unit tests: Press Cmd + U.

Common tips
-----------
- Clean build: Cmd + Shift + K
- Reset simulator: Device → Erase All Content and Settings (in Simulator menu)
- Delete derived data:

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

Contributing
------------

Contributions are welcome. Please fork the repo and open a pull request with your changes. If you add new features, include screenshots in `docs/screenshots/` and update this README.

License
-------

This project is licensed under the terms in the [LICENSE](LICENSE) file.

Roadmap
-------

- Add iCloud sync for cross-device Kitchen & Shopping list
- ML-driven ingredient suggestions
- More localized content and accessibility improvements

Need help?
----------

Open an issue on GitHub for questions, bugs, or feature requests. I'm happy to help you get the most out of RecipeFinder.

Thanks for checking this out — happy cooking! 🍳
