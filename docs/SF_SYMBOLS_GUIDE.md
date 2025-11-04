# 🎨 SF Symbols Guide - Premium Icons for RecipeFinder

## What are SF Symbols?

SF Symbols are Apple's **free, professional icon system** with 5,000+ symbols that:
- ✅ Automatically adapt to different weights and sizes
- ✅ Match your app's font style
- ✅ Support all accessibility features
- ✅ Look professional and polished (Starling-quality!)
- ✅ Are completely FREE to use in your app

They're the same icons used in Apple's own apps like Music, Health, and Messages!

---

## 📱 How to Browse SF Symbols

### Download SF Symbols App (FREE)
1. Go to: https://developer.apple.com/sf-symbols/
2. Download **SF Symbols 6** app (macOS app)
3. Browse 5,000+ professional icons
4. Copy symbol names directly

### Features:
- Search by category (Food, Navigation, Health, etc.)
- Preview in different weights (Ultralight → Black)
- See multicolor variants
- Copy Swift code directly

---

## 🍳 Best SF Symbols for RecipeFinder

### Recipe & Cooking
```swift
"fork.knife"              // Eating
"fork.knife.circle.fill"  // Recipe icon
"carrot.fill"             // Ingredients
"flame.fill"              // Cooking
"trophy.fill"             // Featured recipes
"wineglass.fill"          // Beverages
"cup.and.saucer.fill"     // Coffee/Tea
"birthday.cake.fill"      // Desserts
"takeoutbag.and.cup.and.straw.fill" // Takeout
```

### Time & Planning
```swift
"clock.fill"              // Duration
"timer"                   // Cooking timer
"calendar.circle.fill"    // Meal planning
"checklist"               // Shopping list
"bell.badge.fill"         // Notifications
```

### Difficulty & Info
```swift
"chart.bar.fill"          // Difficulty
"star.fill"               // Rating
"thermometer.medium"      // Temperature
"gauge.with.needle.fill"  // Progress
"info.circle.fill"        // Information
```

### Categories
```swift
"flame.fill"              // Spicy/Hot
"snowflake"               // Cold/Frozen
"leaf.fill"               // Vegetarian/Healthy
"drop.fill"               // Liquid/Soup
"heart.fill"              // Favorites
```

### Actions
```swift
"plus.circle.fill"        // Add
"trash.fill"              // Delete
"square.and.pencil"       // Edit
"square.and.arrow.up"     // Share
"bookmark.fill"           // Save
"magnifyingglass"         // Search
```

### Navigation
```swift
"house.fill"              // Home
"list.bullet"             // List view
"square.grid.2x2.fill"    // Grid view
"slider.horizontal.3"     // Filters
"gear"                    // Settings
```

---

## 💎 Using SF Symbols in Your Code

### Basic Usage
```swift
Image(systemName: "fork.knife.circle.fill")
    .font(.title)
    .foregroundColor(.blue)
```

### With Dynamic Sizing
```swift
Image(systemName: "star.fill")
    .font(.system(size: 24, weight: .semibold))
    .foregroundColor(.yellow)
```

### Multicolor Symbols (Premium Look!)
```swift
Image(systemName: "birthday.cake.fill")
    .font(.largeTitle)
    .symbolRenderingMode(.multicolor) // 🎉 Automatic colors!
```

### Hierarchical Rendering (Depth)
```swift
Image(systemName: "fork.knife.circle.fill")
    .font(.title)
    .symbolRenderingMode(.hierarchical)
    .foregroundColor(.purple)
```

### Palette Rendering (Custom Colors)
```swift
Image(systemName: "gauge.with.needle.fill")
    .font(.title2)
    .symbolRenderingMode(.palette)
    .foregroundStyle(.blue, .green, .red) // Up to 3 colors!
```

---

## 🎨 Symbol Variants (iOS 15+)

SF Symbols automatically adapt! Add variants to symbols:

```swift
// Filled variants
Image(systemName: "heart.fill")        // Solid heart
Image(systemName: "heart")             // Outline heart

// Circle variants
Image(systemName: "plus.circle")       // Outline
Image(systemName: "plus.circle.fill")  // Filled

// Badge variants
Image(systemName: "bell.badge.fill")   // With notification dot

// Slash variants
Image(systemName: "bell.slash.fill")   // Disabled/off state
```

---

## ✨ Variable Symbols (Animated!)

Some symbols support variable values (progress, volume, signal strength):

```swift
// Timer that fills (0.0 to 1.0)
Image(systemName: "timer", variableValue: 0.75)
    .font(.largeTitle)

// Signal strength
Image(systemName: "wifi", variableValue: 0.5)

// Volume level
Image(systemName: "speaker.wave.3.fill", variableValue: 0.8)
```

---

## 🎭 Symbol Effects (iOS 17+)

Make symbols come alive!

```swift
// Bounce effect
Image(systemName: "heart.fill")
    .symbolEffect(.bounce, value: isFavorited)

// Pulse effect
Image(systemName: "bell.fill")
    .symbolEffect(.pulse)

// Scale effect
Image(systemName: "checkmark.circle.fill")
    .symbolEffect(.scale.up)

// Variable color (breathing)
Image(systemName: "timer")
    .symbolEffect(.variableColor)
```

---

## 🌟 Starling-Style Icon Usage

### 1. Consistent Sizing
```swift
// Define your icon sizes
enum IconSize {
    static let small: CGFloat = 16
    static let medium: CGFloat = 20
    static let large: CGFloat = 24
    static let xlarge: CGFloat = 32
}

Image(systemName: "fork.knife.fill")
    .font(.system(size: IconSize.medium))
```

### 2. Subtle Colors (Eye-Friendly)
```swift
Image(systemName: "star.fill")
    .font(.system(size: 20, weight: .medium))
    .foregroundColor(.secondary.opacity(0.8)) // Softer!
```

### 3. Use Weight Variations
```swift
// Light weight for large icons
Image(systemName: "fork.knife")
    .font(.system(size: 48, weight: .light))

// Bold weight for small icons
Image(systemName: "info.circle.fill")
    .font(.system(size: 16, weight: .bold))
```

### 4. Consistent Rendering Mode
```swift
// Pick one style and stick with it across the app
Image(systemName: "heart.fill")
    .symbolRenderingMode(.hierarchical) // Unified look
    .foregroundColor(AppTheme.accentColor)
```

---

## 🎨 Color Recommendations (Starling-Inspired)

### Light Mode
- Primary icons: `.primary` (black)
- Secondary icons: `.secondary` (gray)
- Accent icons: `AppTheme.accentColor`
- Destructive: `.red`

### Dark Mode (Eye-Friendly)
- Primary icons: `.primary` (white, but softened)
- Secondary icons: `Color(white: 0.6)` // Softer gray
- Accent icons: `AppTheme.accentColor.opacity(0.9)` // Slightly dimmed
- Destructive: `.red.opacity(0.9)`

---

## 📋 Common Mistakes to Avoid

### ❌ Don't Do This
```swift
// Hard-coded colors
Image(systemName: "star.fill")
    .foregroundColor(.yellow) // Won't adapt to dark mode!

// Mixing rendering modes
.symbolRenderingMode(.multicolor) // In one place
.symbolRenderingMode(.hierarchical) // In another = inconsistent
```

### ✅ Do This Instead
```swift
// Use semantic colors
Image(systemName: "star.fill")
    .foregroundColor(.primary) // Adapts automatically!

// Consistent rendering
Image(systemName: "star.fill")
    .symbolRenderingMode(.hierarchical)
    .foregroundColor(AppTheme.accentColor)
```

---

## 🚀 Pro Tips

### 1. Create Symbol Extensions
```swift
extension Image {
    static func recipeIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 20, weight: .medium))
            .symbolRenderingMode(.hierarchical)
    }
}

// Usage
Image.recipeIcon("fork.knife.fill")
    .foregroundColor(.blue)
```

### 2. Use Symbol Variants for States
```swift
// Empty vs filled states
Image(systemName: isFavorited ? "heart.fill" : "heart")
    .foregroundColor(isFavorited ? .red : .secondary)
```

### 3. Accessibility
```swift
Image(systemName: "trash.fill")
    .accessibilityLabel("Delete recipe")
    .accessibilityHint("Removes this recipe from your collection")
```

### 4. Custom Symbols (Advanced)
You can create custom SF Symbols that match Apple's style:
1. Download SF Symbols template
2. Design in Sketch/Figma
3. Export as .svg
4. Import to Xcode

---

## 🎯 RecipeFinder Symbol Recommendations

### Replace Current Icons
- **Tab Bar**: Use `.fill` variants for selected state
- **Buttons**: Use circle variants (`.circle.fill`)
- **Cards**: Use hierarchical rendering
- **Lists**: Use medium weight icons

### Example: Recipe Card
```swift
HStack {
    Image(systemName: "clock.fill")
        .font(.system(size: 16, weight: .medium))
        .symbolRenderingMode(.hierarchical)
        .foregroundColor(.secondary)
    
    Text("\(prepTime) min")
        .font(.subheadline)
        .foregroundColor(.secondary)
}
```

---

## 📱 Testing Your Icons

### Preview in Light & Dark Mode
```swift
#Preview {
    VStack {
        Image(systemName: "fork.knife.circle.fill")
            .font(.largeTitle)
            .symbolRenderingMode(.multicolor)
    }
    .preferredColorScheme(.light) // Test light mode
    
    VStack {
        Image(systemName: "fork.knife.circle.fill")
            .font(.largeTitle)
            .symbolRenderingMode(.multicolor)
    }
    .preferredColorScheme(.dark) // Test dark mode
}
```

---

## 🌟 Summary

**SF Symbols = Starling-Quality Icons for FREE!**

✅ 5,000+ professional icons  
✅ Automatic dark mode support  
✅ Accessibility built-in  
✅ Multicolor variants  
✅ Animated effects  
✅ Perfect for iOS apps  

**Download SF Symbols app and start exploring!**  
🔗 https://developer.apple.com/sf-symbols/

---

*Last updated: November 2025*  
*SF Symbols 6 compatible*
