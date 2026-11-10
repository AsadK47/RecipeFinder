<div align="center">

# RecipeFinder 🍳

**Your recipes, your groceries, your week of cooking — all on your phone, nothing in the cloud.**

[![Build & Test](https://github.com/AsadK47/RecipeFinder/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/AsadK47/RecipeFinder/actions/workflows/build.yml)
[![TestFlight](https://github.com/AsadK47/RecipeFinder/actions/workflows/testflight.yml/badge.svg?branch=main)](https://github.com/AsadK47/RecipeFinder/actions/workflows/testflight.yml)
[![UI tests (nightly)](https://github.com/AsadK47/RecipeFinder/actions/workflows/screenshots.yml/badge.svg?branch=main)](https://github.com/AsadK47/RecipeFinder/actions/workflows/screenshots.yml)
[![Platform](https://img.shields.io/badge/platform-iOS%2017.5%2B-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org/)
[![Xcode](https://img.shields.io/badge/Xcode-16.0%2B-blue.svg)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/license-Proprietary-red.svg)](LICENSE)

**[Join the TestFlight beta](https://testflight.apple.com/join/UJWrMbk2)** · **[recipefinder.uk](https://recipefinder.uk)**

<img src="https://github.com/AsadK47/RecipeFinder/releases/download/screenshots/01-recipes-web.jpg" alt="Recipes" width="160"/>
<img src="https://github.com/AsadK47/RecipeFinder/releases/download/screenshots/02-recipe-web.jpg" alt="Recipe" width="160"/>
<img src="https://github.com/AsadK47/RecipeFinder/releases/download/screenshots/05-import-web.jpg" alt="Import" width="160"/>
<img src="https://github.com/AsadK47/RecipeFinder/releases/download/screenshots/03-groceries-web.jpg" alt="Groceries" width="160"/>
<img src="https://github.com/AsadK47/RecipeFinder/releases/download/screenshots/04-meal-plan-web.jpg" alt="Meal plan" width="160"/>

<sub>Screenshots refresh nightly from the UI tests.</sub>

</div>

## What it is

RecipeFinder is an iPhone and iPad recipe manager built around one loop: **get a recipe in → shop for it → cook it**.
There are no accounts, no servers and no subscriptions. Your library lives on your device, and the smart parts
(reading photos, tidying messy text, estimating amounts) run on-device too.

It ships with 332 starter recipes so it's useful from the first launch.

## Features

**Get recipes in**
- Paste a link — recipe data is read straight from the page, with automatic ingredient parsing
- Search the web without leaving the app; an import button appears only on pages that contain a recipe
- Share a link or text from Safari or any other app via the share sheet
- Scan up to five photos of cookbook pages, or open a PDF
- Paste any text and it's turned into a recipe
- Bring your library over from Paprika, Mela or a CSV export
- Write your own with a step-by-step wizard
- Missing amounts? "Estimate amounts" suggests them on-device (Apple Intelligence) for you to review

**Cook**
- Cooking mode: one step at a time, screen stays on
- Step timers with background alerts
- Scale servings (½× to 3×) and switch metric / imperial
- Ingredient substitutes and nutrition estimates
- "Made it" — rate, add a photo, keep your cooking streak and earn badges
- Siri & Shortcuts: "What's for dinner", "Start cooking", "Next step", "Add to my list"

**Plan & shop**
- Weekly meal planner with reminders
- Groceries list that sorts itself by aisle; add a recipe or a whole week in one tap
- Kitchen inventory with "what can I make?" matching and use-it-up suggestions

**Organise**
- Collections and smart collections, favourites, ratings, tags and filters
- Six colour themes, light and dark
- Full backup and restore to a file you keep

**Accessible by default** — VoiceOver, Dynamic Type, WCAG 2.1 AA contrast and 44pt tap targets throughout.

## Privacy

- No sign-in, no backend, no analytics — RecipeFinder never sends your recipes anywhere
- On-device text recognition and Apple Intelligence; network access only to fetch a page you asked to import or search
- In-app web browsing keeps nothing (non-persistent web store)
- Details: [Privacy Policy](https://recipefinder.uk/privacy.html)

## Built with

| | |
|---|---|
| UI | SwiftUI, Swift 6 strict concurrency, `async`/`await` (no Combine) |
| Architecture | Clean Architecture — Presentation → Domain → Data; views reach managers through `@Environment` protocol seams |
| Storage | Core Data, App Group `UserDefaults` (share extension hand-off) |
| On-device AI | Vision (OCR), PDFKit, FoundationModels (iOS 26 + Apple Intelligence) |
| System | App Intents (Siri/Shortcuts), Share Extension, local notifications |
| Packages | [Kingfisher](https://github.com/onevcat/Kingfisher) (images), [ConfettiSwiftUI](https://github.com/simibac/ConfettiSwiftUI) (celebrations), [ViewInspector](https://github.com/nalexn/ViewInspector) (tests only) |
| Tests | Swift Testing unit tests, import-regression fixtures, XCUITest UI + screenshot + accessibility audits |

## Getting started (developers)

```bash
git clone https://github.com/AsadK47/RecipeFinder.git
cd RecipeFinder
open RecipeFinder.xcodeproj   # ⌘R to run, ⌘U to test
```

Requires Xcode 16+, macOS 15+, iOS 17.5+ simulator or device.

```bash
# Tests from the command line on any available iPhone simulator
SIM=$(xcrun simctl list devices available --json \
  | jq -r 'first(.devices | to_entries[] | select(.key | test("iOS")) | .value[] | select(.name | test("iPhone")) | .udid)')
xcodebuild test -scheme RecipeFinder -destination "platform=iOS Simulator,id=$SIM"
```

### Layout

```
RecipeFinder/            App target
├── Views/               Screens (Recipes, Import, Kitchen, Shopping, MealPlanning, Profile, Settings…)
├── Components/          Reusable UI
├── Models/              Domain models
├── Utilities/Recipe/    Parsing, import pipeline, scaling, nutrition, matching (pure, tested)
├── Persistence/         Core Data stack, managers, backup
├── Services/            Networking, OCR, PDF, cooking session
├── Intents/             Siri & Shortcuts
├── Theme/               Design tokens (see DesignSystem.md)
└── RecipeSeed/          Bundled starter recipes
RecipeShareExtension/    Share sheet extension
RecipeFinderTests/       Unit + fixture tests
RecipeFinderUITests/     UI, screenshot and accessibility tests
```

### How it's built

- **CI** — `build.yml` builds and tests every `agent/*` branch and `main`; UI screenshots run nightly.
- **TestFlight** — every app-code push to `main` uploads a beta build; tester feedback is filed as GitHub issues.
- **Agent loop** — work is planned in [`BACKLOG.md`](BACKLOG.md) and built by scheduled Claude Code agents on
  `agent/<slug>` branches; `main` only moves once a branch is green. Session handoff lives in `WORK.md`; project rules
  in `CLAUDE.md`.

## Contact

- 🐛 Bugs: [GitHub Issues](https://github.com/AsadK47/RecipeFinder/issues) or TestFlight feedback
- 📧 recipefinderuk@gmail.com
- 🌐 [recipefinder.uk](https://recipefinder.uk)

> Proprietary software — pull requests are not accepted.

## Licence

**© 2024–2026 Asad Khan. All rights reserved.** See [LICENSE](LICENSE), the
[Privacy Policy](https://recipefinder.uk/privacy.html) and [Terms of Service](https://recipefinder.uk/terms.html).

<div align="center">

Made in the UK · [recipefinder.uk](https://recipefinder.uk)

</div>
