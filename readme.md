# RecipeFinder

A SwiftUI-based iOS application that helps you discover and manage recipes based on the ingredients you have on hand.

## Features

- **Ingredient-Based Recipe Search**: Find recipes based on available ingredients
- **Recipe Management**: Save and organize your favorite recipes
- **Core Data Integration**: Persistent local storage for recipes and ingredients
- **SwiftUI Interface**: Modern, native iOS user experience

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/RecipeFinder.git
   cd RecipeFinder
   ```

2. Open the project in Xcode:
   ```bash
   open RecipeFinder.xcodeproj
   ```

3. Build and run the project:
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

## How to Use

### Getting Started

1. **Launch the App**: Open RecipeFinder on your iOS device
2. **Browse Recipes**: View the main recipe list on launch

### Adding Recipes

1. Tap the "+" button to add a new recipe
2. Enter recipe details (name, ingredients, instructions)
3. Save to store in your local database

### Searching Recipes

1. Use the search bar to filter recipes
2. Enter ingredient names to find matching recipes
3. Tap on a recipe to view full details

### Managing Your Recipes

- **Edit**: Tap on a recipe and select edit to modify details
- **Delete**: Swipe left on a recipe in the list to delete
- **Favorite**: Mark recipes as favorites for quick access

## Project Structure

```
RecipeFinder/
├── RecipeFinder/
│   ├── RecipeFinderApp.swift       # App entry point
│   ├── ContentView.swift            # Main UI views
│   ├── Item.swift                   # SwiftData model
│   ├── PersistenceController.swift  # Core Data management
│   └── RecipeModel.xcdatamodeld     # Core Data schema
├── RecipeFinderTests/               # Unit tests
├── RecipeFinderUITests/             # UI tests
└── Assets.xcassets                  # App assets and images
```

## Core Data Model

The app uses Core Data to persist recipe information locally:

- **Recipe Entity**: Stores recipe details (name, ingredients, instructions, etc.)
- **Ingredient Entity**: Manages ingredient data
- **Relationships**: Connects recipes with their ingredients

## Development

### Running Tests

**Unit Tests:**
```bash
Cmd + U
```

**UI Tests:**
- Select the UI test target
- Run specific test files in `RecipeFinderUITests/`

### Building for Release

1. Select "Any iOS Device" as the target
2. Product → Archive
3. Follow Xcode's distribution workflow

## Troubleshooting

### Common Issues

**Build Failures:**
- Clean build folder: `Cmd + Shift + K`
- Delete derived data: `~/Library/Developer/Xcode/DerivedData`

**Core Data Issues:**
- Reset simulator: Device → Erase All Content and Settings
- Check `PersistenceController.swift` for schema migrations

**App Crashes:**
- Check Console logs in Xcode
- Review stack traces in the debug area

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the terms in the [LICENSE](LICENSE) file.

## Contact

For questions or support, please open an issue in the GitHub repository.

## Acknowledgments

- Built with SwiftUI and Core Data
- Inspired by the need to reduce food waste and discover new recipes

---

**Note**: This app is currently in development. Features and functionality may change.
