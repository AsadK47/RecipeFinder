# RecipeFinder Test Scripts

This directory contains scripts for running tests in the RecipeFinder project.

## Scripts Overview

### 1. `test.sh` - Run All Tests
Runs all unit tests in the project, regardless of folder structure.

**Usage:**
```bash
./scripts/test.sh
```

**Features:**
- Automatically finds all test files in `RecipeFinderTests/` directory
- Works regardless of how tests are organized (flat or nested folders)
- Displays count of test files found
- Optimized for speed with parallel testing
- Uses derived data for faster builds

---

### 2. `test-single.sh` - Run Single Test File
Runs a specific test file by name. Interactive mode with test file listing.

**Usage:**

**Interactive mode (prompts for test file name):**
```bash
./scripts/test-single.sh
```

**Direct mode (provide test file name as argument):**
```bash
./scripts/test-single.sh RecipeModelTests
```

**Features:**
- Lists all available test files with their paths
- Smart search - finds test file regardless of folder location
- Accepts test name with or without `.swift` extension
- Color-coded output for better readability
- Automatically extracts test class name from file
- Runs only the specified test class

**Examples:**
```bash
# Run RecipeModelTests
./scripts/test-single.sh RecipeModelTests

# Run CategoryClassifierTests
./scripts/test-single.sh CategoryClassifierTests

# Interactive mode
./scripts/test-single.sh
# Then enter: AppThemeTests
```

---

### 3. `lint.sh` - Code Linting
Runs SwiftLint to check code quality and style.

**Usage:**
```bash
./scripts/lint.sh
```

---

## Making Scripts Executable

If you get a "permission denied" error, make the scripts executable:

```bash
chmod +x scripts/test.sh
chmod +x scripts/test-single.sh
chmod +x scripts/lint.sh
```

---

## Test Organization

Tests are organized to mirror the main app structure:

```
RecipeFinderTests/
├── Models/
│   ├── RecipeModelTests.swift
│   ├── IngredientTests.swift
│   └── TimeExtractorTests.swift
├── Persistence/
│   ├── ShoppingListManagerTests.swift
│   ├── KitchenInventoryManagerTests.swift
│   └── PersistenceControllerTests.swift
├── Utilities/
│   ├── CategoryClassifierTests.swift
│   ├── HapticManagerTests.swift
│   ├── RecipeImporterTests.swift
│   ├── RecipeShareUtilityTests.swift
│   └── UnitConversionTests.swift
└── Theme/
    └── AppThemeTests.swift
```

Both scripts work regardless of this structure - they automatically find tests wherever they are located.

---

## Requirements

- Xcode Command Line Tools
- iOS Simulator (iPhone 17 Pro configured)
- macOS with bash or zsh

---

## Troubleshooting

### "iPhone 17 Pro not found"
Update the simulator name in the scripts if you're using a different device:
```bash
-destination 'platform=iOS Simulator,name=YOUR_DEVICE_NAME'
```

### "Build failed"
1. Open the project in Xcode
2. Ensure it builds successfully there first
3. Check for any dependency issues

### "Test class not found"
Make sure:
1. The test file contains a class that inherits from `XCTestCase`
2. The test file is part of the `RecipeFinderTests` target in Xcode
3. The file name matches the class name (convention)

---

## Tips

1. **Fast iteration**: Use `test-single.sh` when working on a specific feature
2. **CI/CD**: Use `test.sh` for comprehensive testing before commits
3. **Clean build**: Delete `DerivedData/` folder if you encounter caching issues
4. **Parallel testing**: Both scripts use parallel testing for faster execution
