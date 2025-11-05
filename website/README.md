# RecipeFinder Website

A modern, iOS-inspired landing page for the RecipeFinder app featuring an iPhone mockup with screenshot slideshow and "Coming Soon" banner.

## Features

- 🎨 **Gradient Design** - Uses the app's teal theme colors
- 📱 **iPhone Mockup** - Realistic device frame with automatic screenshot rotation
- ✨ **Animated Logo** - Glowing, greyed-out effect with smooth animations
- 🎯 **Coming Soon Banner** - Fixed banner with pulsing indicators
- 📧 **Email Signup** - Notify users when the app launches
- 🎭 **Smooth Animations** - Fade-ins, floating iPhone, scroll-triggered effects
- 📱 **Fully Responsive** - Works beautifully on all devices

## File Structure

```
website/
├── index.html      # Main HTML structure
├── styles.css      # All styling and animations
├── script.js       # Slideshow and interactions
└── README.md       # This file
```

## How to Use

### Local Testing

1. Open `index.html` in any modern browser
2. Screenshots will auto-rotate every 4 seconds
3. Click dots to manually switch screenshots
4. Use arrow keys for keyboard navigation

### Customization

#### Change Colors

Edit CSS variables in `styles.css`:

```css
:root {
    --teal-start: rgb(20, 184, 166);
    --teal-middle: rgb(59, 130, 246);
    --teal-end: rgb(96, 165, 250);
}
```

You can use any of the 8 theme colors from `THEME_COLORS.md`.

#### Add More Screenshots

1. Add your screenshot to `docs/screenshots/`
2. Update `index.html`:

```html
<img src="../docs/screenshots/YourNewScreen.png" alt="Description" class="screenshot">
```

3. Add a dot control:

```html
<span class="dot" data-slide="3"></span>
```

#### Email Integration

Replace the mock submission in `script.js` with your API:

```javascript
// In initNotifyForm() function
const response = await fetch('YOUR_API_ENDPOINT', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email })
});
```

## Deployment Options

### GitHub Pages

1. Push to GitHub
2. Settings → Pages → Source: main branch
3. Choose root or `/website` folder
4. Your site will be live at `username.github.io/RecipeFinder`

### Netlify

1. Drag and drop the `website` folder to Netlify
2. Custom domain support available
3. Automatic HTTPS

### Vercel

1. Install Vercel CLI: `npm i -g vercel`
2. Run `vercel` in the website directory
3. Follow prompts

## Features Breakdown

### iPhone Mockup
- Realistic bezels and notch
- Floating animation
- Drop shadow with app theme color
- Power button detail

### Slideshow
- Auto-advance every 4 seconds
- Manual control via dots
- Keyboard navigation (arrow keys)
- Smooth fade transitions

### Coming Soon Banner
- Fixed position at top
- Pulsing dot indicators
- Gradient background matching app theme
- Always visible while scrolling

### Logo Effect
- Animated glow pulse
- Greyed out with subtle opacity
- Gradient border
- Click interaction

### Animations
- Hero section fade-in
- iPhone float effect
- Feature cards on scroll
- Hover effects on interactive elements

## Browser Support

- ✅ Chrome/Edge (latest)
- ✅ Firefox (latest)
- ✅ Safari (latest)
- ✅ Mobile browsers

## Performance

- Optimized animations using CSS transforms
- Lazy image preloading
- Minimal JavaScript
- No external dependencies
- Fast load time

## Future Enhancements

- [ ] Add theme switcher to showcase all 8 app themes
- [ ] Video demo integration
- [ ] App Store countdown timer
- [ ] Social media links
- [ ] Testimonials section
- [ ] Feature comparison table
- [ ] FAQ section
- [ ] App Store badge (when live)

## Tips

- Replace placeholder screenshots with actual app screens
- Update email form to connect to your backend
- Add Google Analytics for visitor tracking
- Consider adding Open Graph tags for social sharing
- Test on various devices and browsers

## License

See parent project LICENSE file.

---

**Need help?** Check the main RecipeFinder documentation or open an issue.
