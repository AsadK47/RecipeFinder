# PDF Design Guide - RecipeFinder

## 🎨 App-Style PDF Design

Your PDFs now match the beautiful design of your app! Here's what makes them special:

## Visual Elements

### 1. **Header (Top of Page)**
```
┌────────────────────────────────────────┐
│  [Purple/Teal Gradient Background]     │ ← Matches app gradient
│                                         │
│           Chicken Biryani              │ ← 32pt Bold, Accent Color
│                                         │
└────────────────────────────────────────┘
```
- **Height**: 150px
- **Colors**: Purple theme (131, 58, 180) → (64, 224, 208)
- **Text**: Centered, bold, your theme's accent color

### 2. **Info Cards (Recipe Details)**
```
┌──────────────┐      ┌──────────────┐
│  ⏱           │      │  📊          │
│              │      │              │
│ Prep: 30m    │      │ Medium       │
│ Cook: 45m    │      │ Indian       │
│              │      │ 4 servings   │
└──────────────┘      └──────────────┘
```
- **Style**: Light gray background (systemGray6)
- **Shape**: Rounded corners (12px radius)
- **Icons**: Large emoji (24pt) with colored accents
- **Layout**: Two columns, 80px height

### 3. **Section Headers**
```
🥘 Ingredients    ← 18pt Bold, Accent Color
───────────
```
- **Font**: System Bold 18pt
- **Color**: Theme accent (purple or teal)
- **Spacing**: 30px above content

### 4. **Ingredients List**
```
• 500g chicken breast    ← Colored bullet
• 2 cups basmati rice
• 1 large onion, diced
```
- **Bullets**: Accent color, 13pt font
- **Text**: Black, 13pt regular
- **Spacing**: 24px line height
- **Indent**: 25px from bullet

### 5. **Instructions (Numbered Steps)**
```
┌─────┐
│  1  │  Heat oil in a large pot over medium heat...
└─────┘

┌─────┐
│  2  │  Add onions and cook until golden brown...
└─────┘
```
- **Numbers**: White text on accent color circles
- **Circle Size**: 32px diameter
- **Text**: 13pt regular, multi-line support
- **Spacing**: 20px between steps

### 6. **Notes Card**
```
┌──────────────────────────────────┐
│                                   │
│  Best served with raita and      │
│  naan bread. Can be made ahead.   │
│                                   │
└──────────────────────────────────┘
```
- **Background**: Light gray (systemGray6)
- **Corners**: Rounded 12px
- **Padding**: 20px inside
- **Width**: Full page minus margins

### 7. **Footer**
```
        Created with RecipeFinder
        ─────────────────────────
```
- **Position**: Bottom center
- **Font**: 10pt gray
- **Text**: Subtle branding

## 📐 Measurements & Spacing

### Page Setup:
- **Size**: 8.5" × 11" (US Letter)
- **Margins**: 40px all sides
- **Line Height**: 24px for body text
- **Section Spacing**: 30px between sections

### Typography:
- **Title**: 32pt Bold (Accent Color)
- **Section Headers**: 18pt Bold (Accent Color)
- **Body Text**: 13pt Regular (Black)
- **Step Numbers**: 16pt Bold (White)
- **Footer**: 10pt Regular (Gray)

## 🎨 Color Schemes

### Purple Theme:
```swift
Primary:   RGB(131, 58, 180)  // Purple
Secondary: RGB(64, 224, 208)  // Teal
Gradient:  10% opacity fade
```

### Teal Theme:
```swift
Primary:   RGB(20, 184, 166)  // Teal
Secondary: RGB(96, 165, 250)  // Blue
Gradient:  10% opacity fade
```

### Neutral Colors:
```swift
Background: UIColor.systemGray6
Text:       UIColor.black
Icons:      Orange (time), Theme color (difficulty)
Bullets:    Theme accent color
```

## 📄 Layout Examples

### Single Page Recipe:
```
┌────────────────────────────────────┐
│ [GRADIENT HEADER]                  │
│ Recipe Name                        │
├────────────────────────────────────┤
│ [INFO CARDS - Time & Details]      │
├────────────────────────────────────┤
│                                    │
│ 🥘 Ingredients                    │
│ • Item 1                           │
│ • Item 2                           │
│ • Item 3                           │
│                                    │
│ 👨‍🍳 Instructions                  │
│ ① Step 1...                        │
│ ② Step 2...                        │
│ ③ Step 3...                        │
│                                    │
│ 📝 Notes                          │
│ [NOTES CARD]                       │
│                                    │
└────────────────────────────────────┘
       Created with RecipeFinder
```

### Multi-Page Recipe:
```
Page 1:
┌────────────────────┐
│ [HEADER + INFO]    │
│ Ingredients        │
│ (continues...)     │
└────────────────────┘

Page 2:
┌────────────────────┐
│ Instructions       │
│ ① Step 1           │
│ ② Step 2           │
│ ③ Step 3           │
│ (continues...)     │
└────────────────────┘

Page 3:
┌────────────────────┐
│ More Steps         │
│ Notes              │
│ [FOOTER]           │
└────────────────────┘
```

## 🔧 Technical Details

### Auto-Pagination:
- Checks remaining space: `pageHeight - yPosition > 100px`
- Starts new page if content doesn't fit
- Continues seamlessly across pages

### Drawing Order:
1. Gradient background (header only)
2. Title text
3. Info cards (with fills and text)
4. Section headers
5. Content (bullets, steps, etc.)
6. Notes card (background then text)
7. Footer

### Performance:
- PDF generation: ~500-1000ms
- Runs on background thread
- No UI blocking
- Progress indicator shown

## 📱 App Style Consistency

### What Makes It "App-Style":

✅ **Same gradient colors** as app background
✅ **Matching accent colors** for theme
✅ **Card-based layout** like your views
✅ **Emoji icons** throughout
✅ **Rounded corners** on cards
✅ **Circular step numbers** like in app
✅ **Professional typography** matching iOS
✅ **Clean spacing** and hierarchy

### Compare to Screenshot:
The PDF literally looks like a screenshot of your recipe detail view, but optimized for printing and sharing!

## 🎯 Use Cases

### Perfect For:
- 📧 Email to friends/family
- 🖨️ Print for kitchen use
- 📱 Share on messaging apps
- 💾 Save to Files app
- 📤 Upload to cloud storage
- 👨‍🍳 Professional recipe collection

### Why It's Better:
- **No emojis in text** = Works everywhere
- **Beautiful design** = Professional look
- **Readable format** = Easy to follow while cooking
- **Branded** = Shows it's from your app
- **Print-ready** = Perfect for physical copies

---

**Your recipes now look amazing in any format!** 🎉
