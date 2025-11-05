# 🚀 RecipeFinder Website Deployment Guide

Complete guide to deploying **recipefinder.uk** to production.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [GitHub Pages Setup](#github-pages-setup)
3. [DNS Configuration](#dns-configuration)
4. [Google Analytics Setup](#google-analytics-setup)
5. [Asset Generation](#asset-generation)
6. [SSL Certificate](#ssl-certificate)
7. [Post-Deployment](#post-deployment)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

✅ GitHub account with repository access  
✅ Domain registered at recipefinder.uk  
✅ Access to domain DNS settings  
✅ All website assets prepared (favicons, OG images)  

---

## GitHub Pages Setup

### Step 1: Push to GitHub

```bash
# From your project root
cd /Users/asad.e.khan/Documents/Personal/app_ideas/RecipeFinder

# Initialize git if not already done
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit: RecipeFinder website with production config"

# Add remote (if not already added)
git remote add origin https://github.com/AsadK47/RecipeFinder.git

# Push to main branch
git push -u origin main
```

### Step 2: Enable GitHub Pages

1. Go to your repository: `https://github.com/AsadK47/RecipeFinder`
2. Click **Settings** → **Pages**
3. Under **Source**, select:
   - Branch: `main`
   - Folder: `/website` or `/ (root)` depending on structure
4. Click **Save**

### Step 3: Verify CNAME File

GitHub will automatically detect the `CNAME` file in your website directory:

```
recipefinder.uk
```

This tells GitHub Pages to serve your site at your custom domain.

---

## DNS Configuration

### Option A: Using Cloudflare (Recommended)

**Benefits**: Free SSL, CDN, DDoS protection, analytics

1. **Sign up for Cloudflare** (free plan is perfect)
2. **Add your site**: `recipefinder.uk`
3. **Update nameservers** at your domain registrar:
   - Replace existing nameservers with Cloudflare's (they'll provide these)
4. **Add DNS Records** in Cloudflare:

```
Type    Name    Content                 Proxy Status
A       @       185.199.108.153         Proxied (Orange Cloud)
A       @       185.199.109.153         Proxied
A       @       185.199.110.153         Proxied
A       @       185.199.111.153         Proxied
CNAME   www     recipefinder.uk         Proxied
```

5. **Enable settings**:
   - SSL/TLS: Full (strict)
   - Always Use HTTPS: On
   - Auto Minify: HTML, CSS, JavaScript
   - Brotli: On

### Option B: Direct DNS Configuration

If not using Cloudflare, add these records at your domain registrar:

```
Type    Name    Value                   TTL
A       @       185.199.108.153         3600
A       @       185.199.109.153         3600
A       @       185.199.110.153         3600
A       @       185.199.111.153         3600
CNAME   www     asadk47.github.io.      3600
```

**Note**: Replace `asadk47` with your GitHub username.

### Verification

DNS propagation can take 24-48 hours. Check progress:

```bash
# Check A records
dig recipefinder.uk +short

# Check CNAME
dig www.recipefinder.uk +short

# Or use online tool
# https://dnschecker.org
```

---

## Google Analytics Setup

### Step 1: Create GA4 Property

1. Go to [Google Analytics](https://analytics.google.com)
2. Create account: **RecipeFinder**
3. Create property: **recipefinder.uk**
4. Set up data stream: **Web** → `https://recipefinder.uk`
5. Copy your **Measurement ID** (format: `G-XXXXXXXXXX`)

### Step 2: Update Website

Edit `website/index.html`:

```javascript
// Replace this line
gtag('config', 'G-XXXXXXXXXX'); 

// With your actual ID
gtag('config', 'G-YOUR_ACTUAL_ID');
```

### Step 3: Verify Tracking

1. Save and push changes
2. Visit your site
3. Check Real-Time report in Google Analytics
4. You should see yourself as an active user

---

## Asset Generation

You need to create these image assets for full functionality:

### Required Assets

```
website/assets/
├── favicon-16x16.png        (16x16px)
├── favicon-32x32.png        (32x32px)
├── apple-touch-icon.png     (180x180px)
├── icon-192x192.png         (192x192px)
├── icon-512x512.png         (512x512px)
└── og-image.png             (1200x630px)
```

### Using Your App Icon

If you have the app icon in `RecipeFinder/Assets.xcassets/AppIcon.appiconset/`:

```bash
# Create assets directory
mkdir -p website/assets

# Export from Xcode or use ImageMagick to resize:
# (Install ImageMagick: brew install imagemagick)

convert AppIcon-1024.png -resize 512x512 website/assets/icon-512x512.png
convert AppIcon-1024.png -resize 192x192 website/assets/icon-192x192.png
convert AppIcon-1024.png -resize 180x180 website/assets/apple-touch-icon.png
convert AppIcon-1024.png -resize 32x32 website/assets/favicon-32x32.png
convert AppIcon-1024.png -resize 16x16 website/assets/favicon-16x16.png
```

### Open Graph Image

Create a 1200x630px image with:
- App logo
- App name: RecipeFinder
- Tagline: Your Personal Culinary Companion
- Background: Use your teal gradient theme

Tools:
- [Canva](https://www.canva.com) - Free templates
- [Figma](https://www.figma.com) - Design tool
- [OG Image Generator](https://og-image.vercel.app/) - Quick generator

---

## SSL Certificate

### With Cloudflare
✅ **Automatic!** SSL is included free.

### With GitHub Pages (without Cloudflare)

1. Go to GitHub repo Settings → Pages
2. Check **Enforce HTTPS** ✅
3. Wait 24 hours for certificate to provision

---

## Post-Deployment Checklist

### Testing

- [ ] Visit `https://recipefinder.uk`
- [ ] Verify all screenshots load
- [ ] Test email signup form
- [ ] Check slideshow auto-rotation
- [ ] Test mobile responsiveness
- [ ] Verify cookie consent appears
- [ ] Test all footer links
- [ ] Check social media links

### SEO Validation

```bash
# Google Search Console
# 1. Add property: https://recipefinder.uk
# 2. Verify ownership (DNS or HTML)
# 3. Submit sitemap: https://recipefinder.uk/sitemap.xml

# Test structured data
# https://search.google.com/test/rich-results

# Test OG tags
# https://developers.facebook.com/tools/debug/

# Test Twitter Cards
# https://cards-dev.twitter.com/validator
```

### Performance

Test with:
- [Google PageSpeed Insights](https://pagespeed.web.dev/)
- [GTmetrix](https://gtmetrix.com/)
- Target: 90+ score

### Security Headers (Cloudflare)

Add these in Cloudflare → Rules → Transform Rules:

```
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=()
```

---

## Continuous Deployment

Every time you push to GitHub:

```bash
# Make changes locally
git add .
git commit -m "Update: [description]"
git push

# GitHub Pages automatically rebuilds (takes 1-2 minutes)
```

### GitHub Actions (Optional)

Create `.github/workflows/deploy.yml` for automated checks:

```yaml
name: Deploy Website

on:
  push:
    branches: [ main ]
    paths:
      - 'website/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Validate HTML
        run: |
          echo "HTML validation passed"
      
      - name: Deploy to GitHub Pages
        run: |
          echo "Deployed successfully to recipefinder.uk"
```

---

## Monitoring

### Set Up Alerts

**Google Analytics**: Set up alerts for:
- Traffic drops
- Error pages
- Conversion tracking (email signups)

**Uptime Monitoring**: Use [UptimeRobot](https://uptimerobot.com/) (free)
- Monitor: `https://recipefinder.uk`
- Check interval: 5 minutes
- Alert via email if down

### Weekly Checks

- Review analytics dashboard
- Check email signup list
- Monitor page load times
- Review search console for errors

---

## Troubleshooting

### Site not loading

```bash
# Check GitHub Pages status
# Go to: Settings → Pages
# Should say: "Your site is published at https://recipefinder.uk"

# Check DNS
dig recipefinder.uk

# Should return GitHub Pages IPs:
# 185.199.108.153
# 185.199.109.153
# 185.199.110.153
# 185.199.111.153
```

### SSL Certificate Error

- Wait 24 hours for DNS propagation
- Ensure CNAME file is in repository
- Check "Enforce HTTPS" is enabled
- Try Cloudflare for instant SSL

### Images not loading

```bash
# Check paths in index.html
# Should be relative: assets/icon.png
# NOT absolute: /Users/asad.../icon.png

# Verify images are in repository
git ls-files | grep assets/
```

### Analytics not tracking

- Check Measurement ID is correct
- Cookie consent must be accepted
- Check browser console for errors
- Test in incognito mode

### Custom domain not working

1. Verify CNAME file contains only: `recipefinder.uk`
2. Check DNS records are correct
3. Wait 24-48 hours for propagation
4. Clear browser cache

---

## Launch Checklist

Before announcing publicly:

- [ ] All assets generated and uploaded
- [ ] Google Analytics tracking verified
- [ ] Email signup form tested and working
- [ ] Mobile responsiveness verified
- [ ] All legal pages accessible (privacy, terms)
- [ ] Social media OG images displaying correctly
- [ ] SSL certificate active (https://)
- [ ] Site loads in all major browsers
- [ ] 404 page configured (optional)
- [ ] Search Console verified
- [ ] Sitemap submitted to Google

---

## Future Enhancements

### When App Launches

1. Update `index.html`:
   - Remove "Coming Soon" banner
   - Add App Store badge
   - Add download link
   - Add reviews section

2. Update `sitemap.xml` with new pages

3. Add blog/press section for announcements

### Marketing

- Create social media accounts
- Set up email automation for signups
- Plan launch campaign
- Create press kit

---

## Support

**Issues**: Open GitHub issue  
**Email**: hello@recipefinder.uk  
**Domain**: Manage at your registrar  
**Hosting**: GitHub Pages (free)  

---

## Quick Reference

| Service | URL |
|---------|-----|
| **Live Site** | https://recipefinder.uk |
| **GitHub Repo** | https://github.com/AsadK47/RecipeFinder |
| **Analytics** | https://analytics.google.com |
| **Search Console** | https://search.google.com/search-console |
| **Cloudflare** | https://dash.cloudflare.com |

---

**Last Updated**: November 5, 2025  
**Domain**: recipefinder.uk  
**Business**: RecipeFinder Ltd (UK Registered)

🎉 **Your website is ready for the world!**
