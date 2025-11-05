# 🚀 Quick Start Guide - RecipeFinder Website

Get your website running locally in 2 minutes!

## 🎯 Fastest Way: GitHub Codespaces

1. Go to your GitHub repository
2. Click **Code** → **Codespaces** → **Create codespace on main**
3. Wait ~2 minutes for setup
4. In terminal, run:
   ```bash
   cd website
   python3 -m http.server 8080
   ```
5. Click "Open in Browser" when prompted
6. **Done!** 🎉

## 💻 Local Development

### Prerequisites
- Any web browser
- Terminal access

### Method 1: Simple (No Installation)
```bash
cd website
# Just double-click index.html
# Or drag it into your browser
```

### Method 2: Live Server (Recommended)

**With Python:**
```bash
cd website
python3 -m http.server 8080
# Visit: http://localhost:8080
```

**With Node.js:**
```bash
# Install once
npm install -g live-server

# Run anytime
cd website
live-server
```

**With PHP:**
```bash
cd website
php -S localhost:8080
```

## 📝 Before Going Live

### 1. Generate Assets (15 minutes)
```bash
cd website/assets
# See assets/README.md for instructions
# Need: favicons, OG image, PWA icons
```

### 2. Update Google Analytics (2 minutes)
```javascript
// In website/index.html, replace:
gtag('config', 'G-XXXXXXXXXX');
// With your actual GA4 ID
```

### 3. Test Everything (5 minutes)
- [ ] Email signup works
- [ ] Screenshots slideshow rotates
- [ ] Cookie banner appears
- [ ] All footer links work
- [ ] Mobile responsive
- [ ] Legal pages load

### 4. Deploy to recipefinder.uk (30 minutes)
See `DEPLOYMENT.md` for complete guide.

Quick steps:
```bash
# 1. Push to GitHub
git add .
git commit -m "Production ready"
git push origin main

# 2. Enable GitHub Pages
# Go to Settings → Pages
# Source: main branch, /website folder

# 3. Configure DNS
# See DEPLOYMENT.md section on DNS
```

## 🎨 Customization

### Change Theme Colors
Edit `styles.css`:
```css
:root {
    --teal-start: rgb(20, 184, 166);  /* Your color */
    --teal-middle: rgb(59, 130, 246); /* Your color */
    --teal-end: rgb(96, 165, 250);    /* Your color */
}
```

### Add More Screenshots
1. Add image to `docs/screenshots/`
2. Update `index.html`:
```html
<img src="../docs/screenshots/NewScreen.png" alt="Description" class="screenshot">
```
3. Add dot control:
```html
<span class="dot" data-slide="3"></span>
```

### Update Business Info
Edit footer in `index.html`:
```html
<p class="business-info">Your Company Name</p>
```

## 🐛 Troubleshooting

### Screenshots not showing?
```bash
# Check file paths
ls docs/screenshots/
# Should see: HomePage.png, CreateAccountPage.png, etc.
```

### Port already in use?
```bash
# Try different port
python3 -m http.server 8081
```

### Slideshow not working?
- Check browser console (F12)
- Ensure script.js is loaded
- Verify screenshots have class="screenshot"

## 📚 Full Documentation

- `DEPLOYMENT.md` - Complete deployment guide
- `README.md` - Website features and details
- `.devcontainer/README.md` - Codespaces setup
- `assets/README.md` - Asset generation guide

## 🆘 Need Help?

1. Check browser console (F12)
2. Review documentation
3. Open GitHub issue
4. Email: hello@recipefinder.uk

## ✅ Production Checklist

Before announcing your site:

- [ ] All assets generated
- [ ] Google Analytics configured
- [ ] DNS pointing to recipefinder.uk
- [ ] SSL certificate active (https)
- [ ] Legal pages reviewed
- [ ] Email form tested
- [ ] Mobile tested
- [ ] All browsers tested
- [ ] SEO tags verified
- [ ] Social sharing tested

## 🎉 You're Ready!

Your website is now ready to showcase RecipeFinder to the world!

**Next Steps:**
1. Generate assets (see `assets/README.md`)
2. Deploy to recipefinder.uk (see `DEPLOYMENT.md`)
3. Set up Google Analytics
4. Test everything
5. Share with the world! 🚀

---

**Live Site**: https://recipefinder.uk  
**Repository**: https://github.com/AsadK47/RecipeFinder  
**Business**: RecipeFinder Ltd (UK)
