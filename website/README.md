# RecipeFinder Website# RecipeFinder Website



Official landing page for the RecipeFinder iOS app - **recipefinder.uk**A modern, iOS-inspired landing page for the RecipeFinder app featuring an iPhone mockup with screenshot slideshow and "Coming Soon" banner.



## Overview## Features



A modern, professional website showcasing the RecipeFinder app with:- 🎨 **Gradient Design** - Uses the app's teal theme colors

- Clean gradient design matching the app's theme- 📱 **iPhone Mockup** - Realistic device frame with automatic screenshot rotation

- iPhone mockup with rotating screenshots- ✨ **Animated Logo** - Glowing, greyed-out effect with smooth animations

- Email notification signup- 🎯 **Coming Soon Banner** - Fixed banner with pulsing indicators

- Comprehensive legal pages- 📧 **Email Signup** - Notify users when the app launches

- Full GDPR compliance- 🎭 **Smooth Animations** - Fade-ins, floating iPhone, scroll-triggered effects

- 📱 **Fully Responsive** - Works beautifully on all devices

## Structure

## File Structure

```

Website/```

├── index.html              # Landing pagewebsite/

├── cookies.html           # Cookie policy├── index.html      # Main HTML structure

├── privacy.html           # Privacy policy├── styles.css      # All styling and animations

├── terms.html             # Terms of service├── script.js       # Slideshow and interactions

├── legal-notice.html      # Legal notice & IP rights└── README.md       # This file

├── styles.css             # All styles```

├── script.js              # Interactivity

└── assets/                # Images & icons## How to Use

```

### Local Testing

## Key Features

1. Open `index.html` in any modern browser

### Landing Page2. Screenshots will auto-rotate every 4 seconds

- iPhone 15 Pro mockup with screenshot slideshow3. Click dots to manually switch screenshots

- "Coming Soon" banner with theme toggle4. Use arrow keys for keyboard navigation

- Email notification signup form

- Feature highlights### Customization

- Responsive design

#### Change Colors

### Legal Pages

- Clean, professional layoutEdit CSS variables in `styles.css`:

- No unnecessary boxes or clutter

- GDPR-compliant cookie consent```css

- Accept/Reject cookie options:root {

- Company information in footer    --teal-start: rgb(20, 184, 166);

    --teal-middle: rgb(59, 130, 246);

### Cookie Compliance    --teal-end: rgb(96, 165, 250);

- Banner with Accept/Reject options}

- Respects user choice```

- Only stores theme preference if accepted

- No analytics trackingYou can use any of the 8 theme colors from `THEME_COLORS.md`.



## Technologies#### Add More Screenshots



- **HTML5** - Semantic markup1. Add your screenshot to `docs/screenshots/`

- **CSS3** - Custom properties, animations, responsive design2. Update `index.html`:

- **Vanilla JavaScript** - No frameworks, pure JS

- **LocalStorage** - Theme and consent preferences```html

<img src="../docs/screenshots/YourNewScreen.png" alt="Description" class="screenshot">

## Deployment```



Currently hosted at: **https://recipefinder.uk**3. Add a dot control:



### Update Live Site```html

```bash<span class="dot" data-slide="3"></span>

# Make changes locally```

git add Website/

git commit -m "Update website"#### Email Integration

git push origin main

```Replace the mock submission in `script.js` with your API:



Site updates automatically via hosting provider.```javascript

// In initNotifyForm() function

## Cookie Policyconst response = await fetch('YOUR_API_ENDPOINT', {

    method: 'POST',

The website uses minimal cookies:    headers: { 'Content-Type': 'application/json' },

- **Essential**: Session management (if needed)    body: JSON.stringify({ email })

- **Preferences**: Theme choice (light/dark mode)});

```

Users can reject all non-essential cookies. If rejected:

- Theme changes work but don't persist## Deployment Options

- No localStorage writes occur

### GitHub Pages

## Legal Compliance

1. Push to GitHub

### UK GDPR2. Settings → Pages → Source: main branch

- ✅ Cookie consent banner with reject option3. Choose root or `/website` folder

- ✅ Privacy policy explaining data collection4. Your site will be live at `username.github.io/RecipeFinder`

- ✅ Clear company information

- ✅ User rights documented### Netlify



### Company Information1. Drag and drop the `website` folder to Netlify

- **Name**: RECIPEFINDER LIMITED2. Custom domain support available

- **Number**: 168332433. Automatic HTTPS

- **Registered**: England and Wales

- **Director**: Asad Khan### Vercel

- **Contact**: recipefinderlimited@icloud.com

1. Install Vercel CLI: `npm i -g vercel`

## Customization2. Run `vercel` in the website directory

3. Follow prompts

### Change Theme Colors

Edit CSS custom properties in `styles.css`:## Features Breakdown

```css

:root {### iPhone Mockup

    --teal-start: rgb(20, 184, 166);- Realistic bezels and notch

    --teal-middle: rgb(59, 130, 246);- Floating animation

    --teal-end: rgb(96, 165, 250);- Drop shadow with app theme color

}- Power button detail

```

### Slideshow

### Update Screenshots- Auto-advance every 4 seconds

1. Add images to `assets/screenshots/`- Manual control via dots

2. Update slideshow in `index.html`- Keyboard navigation (arrow keys)

3. Optimize images for web- Smooth fade transitions



### Connect Email Form### Coming Soon Banner

Replace mock submission in `script.js`:- Fixed position at top

```javascript- Pulsing dot indicators

// Update this function- Gradient background matching app theme

async function submitEmail(email) {- Always visible while scrolling

    const response = await fetch('YOUR_API_ENDPOINT', {

        method: 'POST',### Logo Effect

        headers: { 'Content-Type': 'application/json' },- Animated glow pulse

        body: JSON.stringify({ email })- Greyed out with subtle opacity

    });- Gradient border

    return response.ok;- Click interaction

}

```### Animations

- Hero section fade-in

## Browser Support- iPhone float effect

- Feature cards on scroll

- Chrome/Edge 90+- Hover effects on interactive elements

- Firefox 88+

- Safari 14+## Browser Support

- Mobile browsers (iOS Safari, Chrome Mobile)

- ✅ Chrome/Edge (latest)

## Performance- ✅ Firefox (latest)

- ✅ Safari (latest)

- ⚡ No external dependencies- ✅ Mobile browsers

- ⚡ Optimized images

- ⚡ Minimal JavaScript## Performance

- ⚡ Fast load times

- ⚡ Mobile-first design- Optimized animations using CSS transforms

- Lazy image preloading

## Maintenance- Minimal JavaScript

- No external dependencies

### Regular Updates- Fast load time

- Review legal pages quarterly

- Update screenshots when app changes## Future Enhancements

- Check browser compatibility

- Monitor cookie compliance requirements- [ ] Add theme switcher to showcase all 8 app themes

- [ ] Video demo integration

### Testing- [ ] App Store countdown timer

```bash- [ ] Social media links

# Test locally- [ ] Testimonials section

open index.html- [ ] Feature comparison table

- [ ] FAQ section

# Check mobile responsiveness- [ ] App Store badge (when live)

# Use browser dev tools (Cmd+Opt+I)

```## Tips



## Future Enhancements- Replace placeholder screenshots with actual app screens

- Update email form to connect to your backend

- [ ] Add App Store badge when published- Add Google Analytics for visitor tracking

- [ ] Create video demo section- Consider adding Open Graph tags for social sharing

- [ ] Add testimonials/reviews- Test on various devices and browsers

- [ ] Implement i18n (multiple languages)

- [ ] Add FAQ section## License

- [ ] Create press kit page

See parent project LICENSE file.

## Contact

---

For website issues or suggestions:

- **Email**: recipefinderlimited@icloud.com**Need help?** Check the main RecipeFinder documentation or open an issue.

- **GitHub**: Issues on main repository

---

© 2025 RECIPEFINDER LIMITED. All rights reserved.
