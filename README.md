<div align="center">

# RecipeFinder 🍳

**Save any recipe, plan your week, shop smarter and cook with confidence.**

[![Build & Test](https://github.com/AsadK47/RecipeFinder/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/AsadK47/RecipeFinder/actions/workflows/build.yml)
[![TestFlight](https://github.com/AsadK47/RecipeFinder/actions/workflows/testflight.yml/badge.svg?branch=main)](https://github.com/AsadK47/RecipeFinder/actions/workflows/testflight.yml)
[![UI tests (nightly)](https://github.com/AsadK47/RecipeFinder/actions/workflows/screenshots.yml/badge.svg?branch=main)](https://github.com/AsadK47/RecipeFinder/actions/workflows/screenshots.yml)
[![Platform](https://img.shields.io/badge/platform-iOS%2017.5%2B-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org/)
[![Xcode](https://img.shields.io/badge/Xcode-16.0%2B-blue.svg)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/license-AGPL--3.0-blue.svg)](LICENSE)

**[Join the TestFlight beta](https://testflight.apple.com/join/UJWrMbk2)** · **[recipefinder.uk](https://recipefinder.uk)**

<img src="https://github.com/AsadK47/RecipeFinder/releases/download/screenshots/16-today-web.jpg" alt="Today" width="160"/>
<img src="https://github.com/AsadK47/RecipeFinder/releases/download/screenshots/01-recipes-web.jpg" alt="Recipes" width="160"/>
<img src="https://github.com/AsadK47/RecipeFinder/releases/download/screenshots/02-recipe-web.jpg" alt="Recipe" width="160"/>
<img src="https://github.com/AsadK47/RecipeFinder/releases/download/screenshots/06-cooking-mode-web.jpg" alt="Cooking mode" width="160"/>
<img src="https://github.com/AsadK47/RecipeFinder/releases/download/screenshots/05-import-web.jpg" alt="Add a recipe" width="160"/>
<img src="https://github.com/AsadK47/RecipeFinder/releases/download/screenshots/04-meal-plan-web.jpg" alt="Meal plan" width="160"/>
<img src="https://github.com/AsadK47/RecipeFinder/releases/download/screenshots/03-groceries-web.jpg" alt="Groceries" width="160"/>
<img src="https://github.com/AsadK47/RecipeFinder/releases/download/screenshots/17-me-web.jpg" alt="Me" width="160"/>

<sub>Screenshots refresh nightly from the UI tests.</sub>

</div>

## What it is

RecipeFinder is an iPhone and iPad app for dinner, sorted: find something you'll love, plan it, shop for it, cook it
well and remember it. Smart features like reading photos, tidying messy text and estimating amounts run privately on
your device, and when you turn on iCloud sync your kitchen follows you to every device signed in to your iCloud
account.

It ships with 332 starter recipes, so there's something good to cook from the first launch.

## Features

Five tabs: **Today** · **Recipes** · **Plan** · **Groceries** · **Me**.

**Today — decide tonight**
- Tonight's pick from your plan, what's in your kitchen or something quick, with one tap to start cooking
- Your week at a glance, plus your streak, this week's cooks and your next badge
- Copied a recipe link? Today offers to bring it in

**Recipes — discover**
- Your library plus an endless feed of chapters: "Because you loved…", "Under 30 minutes", "Uses what you have",
  "Cook it again", "New to you" and trips through cuisines
- Big pictures throughout: your own photos, pictures from the recipe's website, or illustrations for the starter
  recipes
- Collections and smart collections, favourites, ratings, tags and filters

**Add a recipe from anywhere — tap "+"**
- Paste a link or any text into one box — recipe data is read straight from the page, with automatic ingredient parsing
- Search the web without leaving the app and import any recipe you find in one tap
- Share a link or text from Safari or any other app via the share sheet
- Scan up to five photos of cookbook pages, or open a PDF
- Bring your library over from Paprika, Mela or a CSV export
- Start blank with a step-by-step wizard
- Missing amounts? "Estimate amounts" suggests them on-device (Apple Intelligence) for you to review

**Cook**
- Cooking mode: one step at a time, screen stays on
- Step timers with background alerts
- Scale servings (½× to 3×) and switch metric / imperial
- Ingredient substitutes and nutrition estimates
- "Made it" — rate it, add a photo, keep your cooking streak and earn badges
- Siri & Shortcuts: "What's for dinner", "Start cooking", "Next step", "Add to my list"

**Plan & shop**
- Weekly meal planner with reminders
- Groceries list that sorts itself by aisle; add a recipe or a whole week in one tap
- Kitchen inventory with "what can I make?" matching and use-it-up suggestions

**Me — remember**
- My Cookbook: a book of every dish you've made, built as you cook — tap a page to cook it again
- Your profile, streak and badges

**Your data, everywhere you cook**
- iCloud sync (Settings › Data Management, from the next time you open the app): your recipes, photos,
  collections, plans, lists, kitchen, cooking history and profile follow you to every device signed in to your
  iCloud account; each device fetches its own copy of pictures from recipe websites
- Back up and restore your recipes and lists to a file you keep
- Eight colour themes, light and dark

**Accessible by default** — VoiceOver, Dynamic Type, WCAG 2.1 AA contrast and 44pt tap targets throughout.

## Privacy

- Private by design: open it and start cooking straight away; your recipes live on your device, and in your own
  iCloud account when you turn on iCloud sync — it stays yours
- Text recognition and Apple Intelligence run privately on your device; pages you search or import load straight from
  the web
- In-app browsing is private: every session starts fresh
- Details: [Privacy Policy](https://recipefinder.uk/privacy.html)

## Built with

| | |
|---|---|
| UI | SwiftUI, Swift 6 strict concurrency, `async`/`await` |
| Architecture | Clean Architecture — Presentation → Domain → Data; views reach managers through `@Environment` protocol seams |
| Storage | Core Data with opt-in CloudKit sync (`NSPersistentCloudKitContainer`, the private CloudKit database of the user's own iCloud account); kept JSON copies of each list in `UserDefaults`; App Group hand-off for the share extension — see [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) |
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
├── Views/               Screens (Main = tab shell, Today and Me; Recipes, Import, MealPlanning, Shopping,
│                        Kitchen, Profile = profile, badges and My Cookbook; Settings…)
├── Components/          Reusable UI
├── Models/              Domain models
├── Utilities/Recipe/    Parsing, import pipeline, scaling, nutrition, matching (pure, tested)
├── Persistence/         Core Data stack, iCloud sync, managers, backup
├── Services/            Networking, OCR, PDF, cooking session
├── Intents/             Siri & Shortcuts
├── Theme/               Design tokens (see RecipeFinder/DesignSystem.md)
└── RecipeSeed/          Bundled starter recipes and their illustrations
RecipeShareExtension/    Share sheet extension
RecipeFinderTests/       Unit + fixture tests
RecipeFinderUITests/     UI, screenshot and accessibility tests
```

### How it's built

- **CI** — `build.yml` builds and tests every `agent/*` branch and `main`; UI screenshots run nightly.
- **TestFlight** — every app-code push to `main` uploads a beta build; each tester report opens a GitHub issue for follow-up.
- **Agent loop** — work is planned in [`BACKLOG.md`](BACKLOG.md) and built by scheduled Claude Code agents on
  `agent/<slug>` branches; `main` advances when a branch is green. Start at [`HANDBOOK.md`](HANDBOOK.md): product
  strategy in [`docs/PRODUCT.md`](docs/PRODUCT.md), code map in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md),
  project rules in `CLAUDE.md`, session handoff in `WORK.md`.

## Contact

- 🐛 Bugs: [GitHub Issues](https://github.com/AsadK47/RecipeFinder/issues) or TestFlight feedback
- 📧 recipefinderuk@gmail.com
- 🌐 [recipefinder.uk](https://recipefinder.uk)

> Open source — bug reports and ideas are welcome via Issues or TestFlight feedback.

## Licence

**© 2024–2026 Asad Khan.** The source code is licensed under the
[GNU Affero General Public License v3.0](LICENSE). The RecipeFinder name and app icon are not covered by the
licence, and the bundled recipe text (`RecipeFinder/RecipeSeed/`) is not offered under it. See also the
[Privacy Policy](https://recipefinder.uk/privacy.html) and [Terms of Service](https://recipefinder.uk/terms.html).

<div align="center">

Made in the UK · [recipefinder.uk](https://recipefinder.uk)

</div>
