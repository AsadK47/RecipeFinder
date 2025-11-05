# 🚀 Cloudflare Pages Deployment Guide

## Prerequisites
✅ Domain registered: `recipefinder.uk` on Cloudflare  
✅ Website files ready in `/website` directory  
✅ GitHub repository: `AsadK47/RecipeFinder`

## Step 1: Commit Website to GitHub

```bash
cd /Users/asad.e.khan/Documents/Personal/app_ideas/RecipeFinder

# Check current git status
git status

# Add website files
git add website/

# Commit
git commit -m "Add production website for recipefinder.uk"

# Push to GitHub
git push origin main
```

## Step 2: Create Cloudflare Pages Project

1. **Go to Cloudflare Dashboard**
   - Navigate to: https://dash.cloudflare.com/
   - Click "Workers & Pages" in left sidebar

2. **Create Pages Project**
   - Click "Create application"
   - Select "Pages" tab
   - Click "Connect to Git"

3. **Connect GitHub Repository**
   - Click "GitHub" → Authorize Cloudflare
   - Select repository: `AsadK47/RecipeFinder`
   - Click "Begin setup"

4. **Configure Build Settings**
   ```
   Project name: recipefinder
   Production branch: main
   Build command: (leave empty - static site)
   Build output directory: website
   Root directory: /
   ```

5. **Environment Variables** (none needed for static site)

6. **Click "Save and Deploy"**

## Step 3: Add Custom Domain

1. **In Cloudflare Pages Project**
   - Go to project → "Custom domains" tab
   - Click "Set up a custom domain"

2. **Add Your Domain**
   - Enter: `recipefinder.uk`
   - Click "Continue"
   - Cloudflare will automatically configure DNS

3. **Add WWW Subdomain** (optional)
   - Click "Set up a custom domain" again
   - Enter: `www.recipefinder.uk`
   - Click "Continue"

## Step 4: Verify DNS Records

Your DNS should now have these records (auto-configured by Cloudflare):

### Root Domain
```
Type: CNAME
Name: @
Content: recipefinder.pages.dev
Proxy: ✅ Proxied (orange cloud)
```

### WWW Subdomain
```
Type: CNAME
Name: www
Content: recipefinder.pages.dev
Proxy: ✅ Proxied (orange cloud)
```

**Check DNS Settings:**
Go to: `recipefinder.uk` → DNS → Records

## Step 5: Configure SSL/TLS

1. **Go to SSL/TLS Settings**
   - Domain: `recipefinder.uk` → SSL/TLS
   
2. **Set Encryption Mode**
   - Select: **Full (strict)** ✅ Recommended
   - This ensures HTTPS between Cloudflare and your Pages site

3. **Enable Always Use HTTPS**
   - Go to SSL/TLS → Edge Certificates
   - Turn on "Always Use HTTPS"
   - Turn on "Automatic HTTPS Rewrites"

## Step 6: Configure Page Rules (Optional)

**Redirect www to root domain** (or vice versa):

1. Go to `recipefinder.uk` → Rules → Page Rules
2. Click "Create Page Rule"

**Option A: WWW → Root**
```
URL pattern: www.recipefinder.uk/*
Setting: Forwarding URL
Status: 301 Permanent Redirect
Destination: https://recipefinder.uk/$1
```

**Option B: Root → WWW**
```
URL pattern: recipefinder.uk/*
Setting: Forwarding URL
Status: 301 Permanent Redirect
Destination: https://www.recipefinder.uk/$1
```

## Step 7: Test Deployment

### Manual Testing
1. Open: https://recipefinder.uk
2. Open: https://www.recipefinder.uk
3. Try HTTP: http://recipefinder.uk (should redirect to HTTPS)
4. Test all pages:
   - Privacy Policy: `/privacy.html`
   - Terms of Service: `/terms.html`
   - Legal Notice: `/legal-notice.html`
   - Cookies: `/cookies.html`

### Check SSL Certificate
```bash
# Should show valid Cloudflare certificate
curl -I https://recipefinder.uk
```

### Check DNS Propagation
```bash
# Should resolve to Cloudflare IPs
dig recipefinder.uk
dig www.recipefinder.uk
```

Online tools:
- https://www.whatsmydns.net/#A/recipefinder.uk
- https://dnschecker.org/#A/recipefinder.uk

## Step 8: Enable Analytics (Optional)

1. **Cloudflare Web Analytics** (privacy-friendly)
   - Go to Analytics → Web Analytics
   - Click "Add a site"
   - Enter: `recipefinder.uk`
   - Get tracking code
   - Add to `index.html` before `</body>`

2. **Pages Analytics** (built-in)
   - Automatically enabled
   - View at: Pages project → Analytics tab

## Automatic Deployments

✅ **Every push to `main` branch automatically deploys!**

To deploy:
```bash
git add .
git commit -m "Update website"
git push origin main
```

Cloudflare Pages will:
1. Detect the push
2. Build your site (if needed)
3. Deploy to production
4. Update `recipefinder.uk` automatically

## Current Deployment Status

### Expected URLs
- **Production:** https://recipefinder.uk
- **Pages URL:** https://recipefinder.pages.dev
- **Preview:** https://[commit-hash].recipefinder.pages.dev

### Build Settings
```yaml
Framework: None (static HTML)
Build command: N/A
Build output: website/
Root directory: /
Node version: N/A
```

## Troubleshooting

### Issue: "DNS CNAME not found"
**Solution:** Wait 5-10 minutes for DNS propagation

### Issue: "Too many redirects"
**Solution:** 
- Check SSL/TLS mode is "Full (strict)"
- Remove conflicting page rules

### Issue: "404 Not Found"
**Solution:**
- Verify build output directory is `website`
- Check files are in correct location

### Issue: "Mixed content warnings"
**Solution:**
- Enable "Automatic HTTPS Rewrites" in SSL/TLS settings

## DNS Records Summary

After setup, your DNS should look like this:

| Type | Name | Content | Proxy | TTL |
|------|------|---------|-------|-----|
| CNAME | @ | recipefinder.pages.dev | ✅ | Auto |
| CNAME | www | recipefinder.pages.dev | ✅ | Auto |

**Note:** Cloudflare automatically manages these when you add custom domain in Pages.

## Security Headers (Optional)

Add in Pages project → Settings → Functions:

Create `website/_headers`:
```
/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff
  X-XSS-Protection: 1; mode=block
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: geolocation=(), microphone=(), camera=()
```

## Performance Optimization

✅ Already optimized:
- Cloudflare CDN (global edge network)
- Automatic Brotli compression
- HTTP/2 & HTTP/3 support
- Image optimization (if enabled)
- Automatic minification (if enabled)

Enable in Pages → Settings → Builds & deployments:
- ✅ Auto minify HTML
- ✅ Auto minify CSS  
- ✅ Auto minify JavaScript

## Monitoring

### Check Deployment Status
- Cloudflare Dashboard → Pages → recipefinder → Deployments

### View Logs
- Click any deployment → View build log

### Analytics
- Cloudflare Dashboard → Analytics
- Pages project → Analytics tab

## Support

### Cloudflare Docs
- https://developers.cloudflare.com/pages/

### Community
- https://community.cloudflare.com/

---

**Last Updated:** 5 November 2025  
**Domain:** recipefinder.uk  
**Registrar:** Cloudflare Registrar  
**Hosting:** Cloudflare Pages  
**Repository:** github.com/AsadK47/RecipeFinder
