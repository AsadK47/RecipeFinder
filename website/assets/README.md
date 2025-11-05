# Website Assets

This folder contains all image assets for the RecipeFinder website.

## Required Assets

Generate these files from your app icon or design assets:

### Favicons
- `favicon-16x16.png` - 16×16px browser tab icon
- `favicon-32x32.png` - 32×32px browser tab icon
- `apple-touch-icon.png` - 180×180px iOS home screen icon

### PWA Icons
- `icon-192x192.png` - 192×192px Android icon
- `icon-512x512.png` - 512×512px Android icon

### Social Media
- `og-image.png` - 1200×630px Open Graph image for social sharing

## Quick Generation

### From App Icon (1024×1024)

If you have your app icon at 1024×1024, use ImageMagick:

```bash
# Install ImageMagick
brew install imagemagick

# Navigate to this directory
cd website/assets

# Resize app icon to all sizes
convert /path/to/AppIcon-1024.png -resize 512x512 icon-512x512.png
convert /path/to/AppIcon-1024.png -resize 192x192 icon-192x192.png
convert /path/to/AppIcon-1024.png -resize 180x180 apple-touch-icon.png
convert /path/to/AppIcon-1024.png -resize 32x32 favicon-32x32.png
convert /path/to/AppIcon-1024.png -resize 16x16 favicon-16x16.png
```

### From Xcode Assets

Export from Xcode:
1. Open `RecipeFinder.xcodeproj`
2. Select `Assets.xcassets` → `AppIcon`
3. Right-click → "Export Selected"
4. Resize using Preview or ImageMagick

### Create OG Image

Use online tools:
- **Canva**: Search "Open Graph Template" (1200×630)
- **Figma**: Create 1200×630 canvas
- **OG Image Generator**: https://og-image.vercel.app/

Design should include:
- RecipeFinder logo
- App name: "RecipeFinder"
- Tagline: "Your Personal Culinary Companion"
- Teal gradient background (#14B8A6 to #60A5FA)
- iPhone mockup with screenshot (optional)

## Placeholder Assets

Until you generate real assets, you can use placeholder services:

```html
<!-- Temporary placeholders -->
<link rel="icon" href="https://via.placeholder.com/32">
<meta property="og:image" content="https://via.placeholder.com/1200x630">
```

But replace these ASAP for professional appearance!

## Verification

After adding assets, verify:

1. **Favicons**: Check browser tab
2. **Apple Touch Icon**: Add to iOS home screen
3. **OG Image**: Test at https://developers.facebook.com/tools/debug/
4. **PWA Icons**: Test manifest at https://manifest-validator.appspot.com/

## Current Status

- [ ] favicon-16x16.png
- [ ] favicon-32x32.png
- [ ] apple-touch-icon.png
- [ ] icon-192x192.png
- [ ] icon-512x512.png
- [ ] og-image.png

**Note**: These assets are referenced in `index.html` and `site.webmanifest`. Site will work without them but won't look professional.
