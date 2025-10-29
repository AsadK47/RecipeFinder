# 🛠️ RecipeFinder - Commands Reference

## 🔍 Linting

### Run SwiftLint on Entire Project

From project root:
```bash
./scripts/lint.sh
```

Or manually:
```bash
swiftlint lint --path RecipeFinder/ --config .swiftlint.yml
```

### Install SwiftLint (if not installed)
```bash
brew install swiftlint
```

### Auto-fix Issues (where possible)
```bash
swiftlint --fix --path RecipeFinder/
```

---

## 🧪 Testing

### Run All Tests

From project root:
```bash
./scripts/test.sh
```

Or using xcodebuild:
```bash
xcodebuild test \
    -scheme RecipeFinder \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest'
```

### Run Tests in Xcode
1. Press `⌘ + U` (Command + U)
2. Or: **Product → Test**

### Run Specific Test
```bash
xcodebuild test \
    -scheme RecipeFinder \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    -only-testing:RecipeFinderTests/RecipeModelTests
```

### View Test Coverage
In Xcode:
1. **Product → Scheme → Edit Scheme**
2. Select **Test** tab
3. Check **Gather Coverage Data**
4. Run tests (`⌘ + U`)
5. View coverage: **Report Navigator** (⌘ + 9) → Coverage tab

---

## 🏗️ Building

### Build for Simulator
```bash
xcodebuild build \
    -scheme RecipeFinder \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### Build for Device
```bash
xcodebuild build \
    -scheme RecipeFinder \
    -destination 'generic/platform=iOS'
```

### Clean Build
```bash
xcodebuild clean -scheme RecipeFinder
```

Or in Xcode: `⌘ + Shift + K`

---

## 📦 Dependencies

### Update Swift Packages
```bash
xcodebuild -resolvePackageDependencies
```

Or in Xcode: **File → Packages → Update to Latest Package Versions**

---

## 🚀 Quick Commands

```bash
# Lint entire project
./scripts/lint.sh

# Run all tests
./scripts/test.sh

# Build + Test + Lint
xcodebuild clean build test \
    -scheme RecipeFinder \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' && \
./scripts/lint.sh
```

---

## 📊 Code Quality Checks

### Count Lines of Code
```bash
find RecipeFinder -name '*.swift' | xargs wc -l
```

### Find TODO/FIXME Comments
```bash
grep -rn "TODO\|FIXME" RecipeFinder/
```

### Check for Force Unwraps
```bash
grep -rn "!" RecipeFinder/ | grep -v "//"
```

---

## 🎯 CI/CD Integration

### GitHub Actions Example
```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install SwiftLint
        run: brew install swiftlint
      - name: Lint
        run: ./scripts/lint.sh
      - name: Test
        run: ./scripts/test.sh
```

---

## 🔧 Troubleshooting

### SwiftLint not found
```bash
brew install swiftlint
# or
brew upgrade swiftlint
```

### Simulator not found
```bash
# List available simulators
xcrun simctl list devices

# Boot a simulator
xcrun simctl boot "iPhone 17 Pro"
```

### Clean Derived Data
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

---

**Quick Reference**: Keep this file handy for daily development! 🚀
