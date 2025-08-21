# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

RecipeFinder is an iOS app built with SwiftUI and Core Data that provides a searchable recipe database. The app features recipe browsing, ingredient-based search, shopping list functionality, and dynamic recipe scaling.

## Architecture

### Core Components

- **RecipeFinderApp.swift**: Main app entry point with SwiftData model container setup
- **ContentView.swift**: Root view containing TabView navigation between four main screens
- **PersistenceController.swift**: Core Data management and hardcoded recipe database population
- **Item.swift**: Basic SwiftData model (currently minimal, likely template code)

### Data Layer

- **Core Data**: Primary persistence using NSPersistentContainer with automatic migration
- **SwiftData**: Used for the main app container but Core Data handles actual data operations
- **Database Reset**: App clears and repopulates database on each launch via `PersistenceController.shared.clearDatabase()`

### UI Architecture

**Tab-based Navigation:**
1. **Recipe Search**: Browse and search recipes by name
2. **Ingredient Search**: Browse ingredients alphabetically or search recipes by ingredient
3. **Shopping List**: Manage shopping items with quantities and checkboxes
4. **Settings**: Contains party mode with confetti animation

**Key UI Patterns:**
- SwiftUI views with `@State` and `@Binding` for state management
- Custom reusable components (`SearchBar`, `InfoPairView`, `IngredientRowView`)
- Dynamic serving size adjustment with ingredient quantity recalculation
- NavigationStack for detailed recipe views

### Recipe Data Model

```swift
struct RecipeModel {
    let name, category, difficulty, prepTime, cookingTime: String
    let baseServings, currentServings: Int
    var ingredients: [Ingredient]
    let prePrepInstructions, instructions: [String] 
    let notes: String
    let imageName: String?
}

struct Ingredient {
    var baseQuantity, quantity: Double
    var unit, name: String
}
```

## Development Commands

### Building & Running
```bash
# Open project in Xcode
open RecipeFinder.xcodeproj

# Or if using command line tools
xcodebuild -project RecipeFinder.xcodeproj -scheme RecipeFinder -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Run on device (requires Apple Developer account)
# Select target device in Xcode and press Cmd+R
```

### Testing
```bash
# Run unit tests
xcodebuild test -project RecipeFinder.xcodeproj -scheme RecipeFinder -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run specific test class
xcodebuild test -project RecipeFinder.xcodeproj -scheme RecipeFinder -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:RecipeFinderTests

# Run UI tests  
xcodebuild test -project RecipeFinder.xcodeproj -scheme RecipeFinder -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:RecipeFinderUITests
```

### Dependencies
The project uses Swift Package Manager with one external dependency:
- **ConfettiSwiftUI** (v2.0.2): Confetti animation library for the settings screen

### Database Management

The app uses a unique approach where it clears and repopulates the entire database on each launch:
- Database clearing: `PersistenceController.shared.clearDatabase()`  
- Database population: `PersistenceController.shared.populateDatabase()`
- Recipe fetching: `PersistenceController.shared.fetchRecipes()`

This is likely for development/demo purposes and should be modified for production use.

## Key Features to Understand

### Recipe Scaling
- Recipes have `baseServings` and `currentServings` properties
- Ingredient quantities are dynamically calculated: `ingredient.baseQuantity * (currentServings / baseServings)`
- UI uses Stepper control for serving size adjustment

### Search Functionality
- Recipe search: Text-based filtering by recipe name
- Ingredient search: Alphabetically grouped ingredient browser with search capability  
- Filtering uses `localizedCaseInsensitiveContains()` for user-friendly search

### Shopping List
- Independent of recipes (separate data structure)
- Items have name, quantity, and checked status
- Supports swipe-to-delete and quantity adjustment

### Image Handling
- Recipes reference images by name (`imageName` property)
- Image naming convention: `formattedImageName()` converts recipe names to lowercase with underscores
- Currently all recipes use placeholder "crispy_chilli_beef" image

## Development Notes

### Code Patterns
- Extensive use of SwiftUI's declarative syntax
- State management through `@State`, `@Binding`, and `@Environment`
- Custom view modifiers for consistent styling
- Functional decomposition with focused, single-responsibility views

### Performance Considerations  
- Database is cleared/repopulated on each app launch (not production-ready)
- Large ingredient lists are grouped and lazily loaded with `LazyVStack`
- Image loading relies on bundle resources

### Potential Improvements
- Implement persistent shopping list storage
- Add Core Data relationships between recipes and ingredients
- Implement proper image asset management
- Add recipe creation/editing functionality
- Implement proper onboarding instead of database reset

This codebase demonstrates solid SwiftUI fundamentals with a clean separation of concerns between UI, data persistence, and business logic.
