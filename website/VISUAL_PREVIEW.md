# 🎨 Visual Preview - RecipeFinder Website

## Preview Your Website Locally

### Option 1: Double-Click (Easiest)
```
1. Open Finder
2. Navigate to: RecipeFinder/website/
3. Double-click: index.html
4. Opens in your default browser
```

### Option 2: Simple HTTP Server
```bash
# Navigate to website folder
cd /Users/asad.e.khan/Documents/Personal/app_ideas/RecipeFinder/website

# Start server (choose one):
python3 -m http.server 8080
# OR
php -S localhost:8080
# OR (if you have Node.js)
npx http-server -p 8080

# Then visit: http://localhost:8080
```

### Option 3: GitHub Codespaces
```bash
# In Codespaces terminal:
cd website
live-server
# Auto-opens in browser!
```

---

## 🎬 What You'll See

### Landing Page Structure

```
┌─────────────────────────────────────────────┐
│   🎗️ COMING SOON TO THE APP STORE 🎗️       │ ← Animated banner (fixed)
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────┐              📱              │
│  │   ✨     │           ╭──────╮           │
│  │  Logo    │           │      │           │
│  │ (Glows)  │           │ 📷   │ ← iPhone  │
│  └──────────┘           │      │   mockup  │
│                         │      │   with     │
│  RecipeFinder           │      │   slides  │
│  Your personal culinary │      │           │
│  companion             ╰──────╯           │
│                          ● ○ ○  ← Dots     │
│  ┌────────┐ ┌────────┐ ┌────────┐         │
│  │  🍳    │ │  📱    │ │  🎨    │         │
│  │ Smart  │ │Beautiful│ │Personal│         │
│  │Recipes │ │ Design │ │  ized  │         │
│  └────────┘ └────────┘ └────────┘         │
│                                             │
│  ──────────────────────────────────────    │
│                                             │
│  Get Notified on Launch                     │
│  ┌─────────────────┐ ┌──────────┐          │
│  │ Enter email...  │ │ Notify Me│          │
│  └─────────────────┘ └──────────┘          │
│                                             │
│  ──────────────────────────────────────    │
│                                             │
│  RecipeFinder    Product    Legal    Connect│
│  Your personal   Features   Privacy  🐦 📷  │
│  culinary        Get         Terms          │
│  companion       Notified    Cookies        │
│                                             │
│  © 2025 RecipeFinder Ltd. All rights reserved│
└─────────────────────────────────────────────┘
```

---

## 🎭 Interactive Elements

### 1. Coming Soon Banner
- Fixed at top
- Gradient background (teal)
- Pulsing dots: ● ● ●
- Always visible when scrolling

### 2. Animated Logo
- Glowing aura effect
- Gradient border ring
- Pulses slowly
- Food icon illustration
- Click to interact (scales)

### 3. iPhone Mockup
- Realistic bezels & notch
- Floating animation (up/down)
- Drop shadow with theme color
- Power button on side

### 4. Screenshot Slideshow
Inside the iPhone:
- HomePage.png
- CreateAccountPage.png
- SplashScreenAfterSigningInPage.png

**Auto-rotates** every 4 seconds with fade effect

**Manual controls**:
- Click dots below iPhone
- Use arrow keys (← →)

### 5. Feature Cards
Three cards that:
- Animate on scroll
- Lift up on hover
- Glow with teal shadow
- Show app features

### 6. Email Form
- Input field for email
- "Notify Me" button
- Success message after submit
- (Currently mock - add backend later)

### 7. Cookie Consent
Appears 2 seconds after page load:
```
┌─────────────────────────────────────────┐
│ 🍪 We use cookies to enhance your       │
│ experience...                           │
│ [Accept] [Learn More]                   │
└─────────────────────────────────────────┘
```

### 8. Footer
Four columns:
- **RecipeFinder**: Brand info
- **Product**: Links to features
- **Legal**: Privacy, Terms, Cookies
- **Connect**: Social media icons

Social icons:
- Twitter (bird icon)
- Instagram (camera icon)
- Email (envelope icon)

---

## 🎨 Color Scheme

### Primary Colors
```css
Teal Start:  #14B8A6 (rgb(20, 184, 166))
Teal Middle: #3B82F6 (rgb(59, 130, 246))
Teal End:    #60A5FA (rgb(96, 165, 250))
```

### Backgrounds
```css
Dark BG:     #0a0a0a (Almost black)
Card BG:     #1a1a1a (Dark gray)
```

### Text
```css
Primary:     #ffffff (White)
Secondary:   #a0a0a0 (Light gray)
```

### Gradients
```css
Main: linear-gradient(135deg, #14B8A6, #3B82F6, #60A5FA)
Subtle: Transparent versions for backgrounds
```

---

## ✨ Animations

### Logo
- Glow pulses (3s cycle)
- Opacity: 0.4 → 0.8 → 0.4
- Scale: 1 → 1.1 → 1
- Always running

### iPhone
- Float animation (6s cycle)
- Moves up 20px and back
- Slight rotation (-5deg)
- Smooth cubic-bezier easing

### Screenshots
- Fade transition (0.8s)
- Opacity: 0 ↔ 1
- Only one visible at a time

### Feature Cards
- Start invisible
- Fade in on scroll
- Lift on hover (-5px)
- Shadow grows on hover

### Buttons
- Lift on hover (-2px)
- Shadow appears
- Color brightens
- Smooth 0.3s transition

### Banner Dots
- Pulse animation (2s cycle)
- Opacity & scale change
- Phase-shifted (not synchronized)

---

## 📐 Layout Breakpoints

### Desktop (> 1024px)
```
Hero section: 2 columns (text | iPhone)
Features: 3 columns
Footer: 4 columns
```

### Tablet (768px - 1024px)
```
Hero section: 1 column (iPhone on top)
Features: 2-3 columns
Footer: 2 columns
```

### Mobile (< 768px)
```
Hero section: 1 column stacked
Features: 1 column
Footer: 1 column (centered)
Cookie consent: Stacked vertically
```

---

## 🖼️ Required Assets (Not Yet Created)

These will show broken image icons until you create them:

```
website/assets/
├── favicon-16x16.png         ❌ (Shows default icon)
├── favicon-32x32.png         ❌ (Shows default icon)
├── apple-touch-icon.png      ❌ (iOS home screen)
├── icon-192x192.png          ❌ (PWA)
├── icon-512x512.png          ❌ (PWA)
└── og-image.png              ❌ (Social sharing)
```

**Don't worry**: The site works without them, but looks more professional with them.

**How to create**: See `website/assets/README.md`

---

## 🎯 Test Interactions

Try these when viewing the site:

1. **Slideshow**
   - Wait 4 seconds - screenshot changes automatically
   - Click dots below iPhone - manual control
   - Press arrow keys - keyboard navigation

2. **Email Form**
   - Type email address
   - Click "Notify Me"
   - See success message

3. **Cookie Banner**
   - Wait 2 seconds - banner appears
   - Click "Accept" - banner disappears
   - Refresh page - banner stays hidden (localStorage)

4. **Navigation**
   - Click footer links
   - Scroll to sections (smooth scroll)
   - Click "Get Notified" in footer

5. **Hover Effects**
   - Hover over feature cards - they lift
   - Hover over buttons - they grow
   - Hover over social icons - they change color

6. **Mobile**
   - Resize browser window
   - Test on phone/tablet
   - Cookie banner stacks vertically

---

## 📱 Mobile Preview

To test on your iPhone:

### Option 1: Local Network
```bash
# Get your IP address
ipconfig getifaddr en0

# Start server
cd website
python3 -m http.server 8080

# On iPhone, visit:
http://YOUR_IP:8080
```

### Option 2: Deploy to GitHub Pages
```bash
# Then visit on any device:
https://recipefinder.uk
```

---

## 🔍 Browser DevTools

Press **F12** to inspect:

### Console Tab
- Should be no errors (0 errors)
- Only logs from slideshow
- Cookie consent logs

### Network Tab
- Screenshots loading
- CSS loading
- JS loading
- All should be 200 OK

### Lighthouse Audit
1. Open DevTools (F12)
2. Go to "Lighthouse" tab
3. Click "Generate report"
4. Should score 90+ on all metrics

### Responsive Design Mode
- Chrome: Device Toolbar (Ctrl+Shift+M)
- Test iPhone, iPad, desktop sizes
- Verify layouts adapt properly

---

## 🎬 Demo Flow

**Perfect first-time experience**:

1. **Page loads** (0.5s)
2. **Hero fades in** with logo glowing
3. **iPhone appears** floating
4. **First screenshot** displays
5. **Features fade in** as you scroll
6. **Cookie banner** appears (2s delay)
7. **Screenshot changes** automatically (4s)
8. **Hover feature card** - it lifts
9. **Submit email** - success message
10. **Accept cookies** - banner hides

**Total impression**: "Wow, this is polished!" 🎉

---

## 📸 Take Screenshots

Want to share your website?

### macOS
```bash
# Full screen
Cmd + Shift + 3

# Selection
Cmd + Shift + 4

# Window
Cmd + Shift + 4 + Space + Click
```

### Browser
```javascript
// Right-click page → Inspect → Device Toolbar
// Click "..." → Capture screenshot
```

---

## 🎨 Customization Preview

Want to see different themes? Edit `styles.css`:

### Purple Theme
```css
:root {
    --teal-start: rgb(131, 58, 180);
    --teal-middle: rgb(88, 86, 214);
    --teal-end: rgb(64, 224, 208);
}
```

### Red Theme
```css
:root {
    --teal-start: rgb(139, 0, 0);
    --teal-middle: rgb(178, 34, 34);
    --teal-end: rgb(230, 81, 0);
}
```

Refresh browser to see changes!

---

## ✅ Visual Checklist

When viewing the site, verify:

- [ ] Coming Soon banner at top
- [ ] Logo glows and pulses
- [ ] iPhone floats up and down
- [ ] Screenshots change every 4 seconds
- [ ] Dots control slideshow
- [ ] Feature cards lift on hover
- [ ] Email form works
- [ ] Cookie banner appears
- [ ] Footer has 4 sections
- [ ] Social icons clickable
- [ ] No broken images (except assets/)
- [ ] No console errors
- [ ] Smooth animations
- [ ] Responsive on mobile

---

## 🚀 Ready to Show Off?

Your website is **visually stunning** and ready to impress!

Share it:
- **Locally**: Friends/family can test
- **Staging**: Push to GitHub Pages preview
- **Production**: Deploy to recipefinder.uk

---

**Enjoy your beautiful new website!** 🎉✨

Made with ❤️ for RecipeFinder
