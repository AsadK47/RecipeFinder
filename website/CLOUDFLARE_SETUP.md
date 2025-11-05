# 🌐 Cloudflare DNS Setup for GitHub Pages

Complete guide to connecting your `recipefinder.uk` domain to GitHub Pages using Cloudflare DNS.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Step-by-Step Setup](#step-by-step-setup)
4. [DNS Records Configuration](#dns-records-configuration)
5. [GitHub Repository Settings](#github-repository-settings)
6. [SSL/HTTPS Setup](#sslhttps-setup)
7. [Verification & Testing](#verification--testing)
8. [Troubleshooting](#troubleshooting)

---

## Overview

**What you're connecting:**
- **Domain**: `recipefinder.uk` (managed by Cloudflare)
- **Hosting**: GitHub Pages (static HTML website)
- **Repository**: `AsadK47/RecipeFinder`
- **Website Folder**: `website/`
- **SSL**: Cloudflare + GitHub Pages (automatic HTTPS)

**How it works:**
```
User visits recipefinder.uk
    ↓
Cloudflare DNS resolves to GitHub Pages IPs
    ↓
Cloudflare proxies request (orange cloud ☁️)
    ↓
GitHub Pages serves your website/index.html
    ↓
Cloudflare adds SSL/caching/security
    ↓
User sees beautiful website! 🎉
```

---

## Prerequisites

✅ **Domain**: `recipefinder.uk` registered and transferred to Cloudflare  
✅ **GitHub Account**: Access to `AsadK47/RecipeFinder` repository  
✅ **Website Files**: HTML files in `website/` folder committed to `main` branch  
✅ **CNAME File**: `website/CNAME` contains `recipefinder.uk`

---

## Step-by-Step Setup

### Step 1: Add DNS Records in Cloudflare

1. **Go to Cloudflare Dashboard**
   - Navigate to: https://dash.cloudflare.com/
   - Select your domain: `recipefinder.uk`
   - Click on **DNS** in the left sidebar

2. **Click "Add record"** button (top right)

3. **Add 4 A Records for Apex Domain** (recipefinder.uk)

   Add these records one by one:

   **Record 1:**
   ```
   Type: A
   Name: @
   IPv4 address: 185.199.108.153
   Proxy status: Proxied (orange cloud ☁️)
   TTL: Auto
   ```

   **Record 2:**
   ```
   Type: A
   Name: @
   IPv4 address: 185.199.109.153
   Proxy status: Proxied (orange cloud ☁️)
   TTL: Auto
   ```

   **Record 3:**
   ```
   Type: A
   Name: @
   IPv4 address: 185.199.110.153
   Proxy status: Proxied (orange cloud ☁️)
   TTL: Auto
   ```

   **Record 4:**
   ```
   Type: A
   Name: @
   IPv4 address: 185.199.111.153
   Proxy status: Proxied (orange cloud ☁️)
   TTL: Auto
   ```

4. **Add CNAME Record for www subdomain**

   ```
   Type: CNAME
   Name: www
   Target: asadk47.github.io
   Proxy status: Proxied (orange cloud ☁️)
   TTL: Auto
   ```

### Step 2: Enable GitHub Pages

1. **Go to GitHub Repository**
   - Navigate to: https://github.com/AsadK47/RecipeFinder

2. **Open Settings**
   - Click **Settings** tab
   - Scroll down to **Pages** section (left sidebar under "Code and automation")

3. **Configure Source**
   ```
   Source: Deploy from a branch
   Branch: main
   Folder: /website
   ```
   - Click **Save**

4. **Add Custom Domain**
   ```
   Custom domain: recipefinder.uk
   ```
   - Click **Save**
   - Wait for DNS check (may take a few minutes)

5. **Enable HTTPS**
   - Check the box: ✅ **Enforce HTTPS**
   - This ensures all traffic uses SSL

### Step 3: Verify CNAME File

1. **Check your repository has the CNAME file**:
   ```
   /website/CNAME
   ```

2. **File should contain ONLY**:
   ```
   recipefinder.uk
   ```

3. **If missing, create it**:
   ```bash
   cd /Users/asad.e.khan/Documents/Personal/app_ideas/RecipeFinder/website
   echo "recipefinder.uk" > CNAME
   git add CNAME
   git commit -m "Add CNAME file for custom domain"
   git push origin main
   ```

---

## DNS Records Configuration

### Complete DNS Setup (Summary)

| Type  | Name | Content/Target        | Proxy Status | TTL  |
|-------|------|-----------------------|--------------|------|
| A     | @    | 185.199.108.153      | Proxied ☁️   | Auto |
| A     | @    | 185.199.109.153      | Proxied ☁️   | Auto |
| A     | @    | 185.199.110.153      | Proxied ☁️   | Auto |
| A     | @    | 185.199.111.153      | Proxied ☁️   | Auto |
| CNAME | www  | asadk47.github.io    | Proxied ☁️   | Auto |

### Why These IPs?

These are GitHub Pages' official IP addresses:
- Globally distributed for fast loading
- Redundant for high availability
- All four should be added for best performance

### Proxy Status (Orange Cloud ☁️)

**Proxied (Recommended)**:
- ✅ Free SSL certificate from Cloudflare
- ✅ DDoS protection
- ✅ Content caching for faster loading
- ✅ Analytics and security features
- ✅ Hide GitHub Pages origin IP

**DNS Only (Gray Cloud)**:
- Direct connection to GitHub Pages
- No Cloudflare benefits
- Slower and less secure

**Always use Proxied (orange cloud) for best results!**

---

## GitHub Repository Settings

### Pages Configuration

**Navigation**: Settings → Pages

```yaml
Source:
  Branch: main
  Folder: /website
  
Custom domain: recipefinder.uk

Enforce HTTPS: ✅ Enabled

Build and deployment:
  - GitHub Actions workflow (automatic)
  - Deploys on every push to main branch
```

### Important Files

**1. CNAME** (`website/CNAME`)
```
recipefinder.uk
```

**2. Index Page** (`website/index.html`)
- Your main landing page
- Must exist for GitHub Pages to work

**3. 404 Page** (`website/404.html`) - Optional
- Custom 404 error page
- Improves user experience

---

## SSL/HTTPS Setup

### Cloudflare SSL Settings

1. **Go to SSL/TLS Settings**
   - Dashboard → SSL/TLS tab

2. **Set SSL Mode**
   ```
   Mode: Full (strict)
   ```
   - This ensures end-to-end encryption
   - GitHub Pages has valid SSL certificate
   - Cloudflare validates it

3. **Edge Certificates**
   - ✅ Always Use HTTPS (ON)
   - ✅ Automatic HTTPS Rewrites (ON)
   - ✅ Certificate Status: Active

4. **Minimum TLS Version**
   ```
   TLS 1.2 or higher (recommended)
   ```

### HTTPS Enforcement

**Both Cloudflare AND GitHub Pages should enforce HTTPS:**

**Cloudflare** (Dashboard → SSL/TLS → Edge Certificates):
- ✅ Always Use HTTPS: **ON**

**GitHub Pages** (Settings → Pages):
- ✅ Enforce HTTPS: **Checked**

This ensures:
- All `http://` requests → `https://`
- Secure connection end-to-end
- Green padlock in browser

---

## Verification & Testing

### Step 1: DNS Propagation Check

**Wait for DNS to propagate (15 minutes - 48 hours)**

Check propagation status:
```bash
# Check A records
dig recipefinder.uk +short

# Should show Cloudflare IPs (starting with 104.x or 172.x)

# Check CNAME
dig www.recipefinder.uk +short

# Should show Cloudflare IP (proxied)
```

Or use online tools:
- https://www.whatsmydns.net/ (search for `recipefinder.uk`)
- https://dnschecker.org/ (global DNS check)

### Step 2: Test Website Access

1. **Open browser (incognito mode)**
2. **Visit URLs**:
   - https://recipefinder.uk ✅
   - https://www.recipefinder.uk ✅
   - http://recipefinder.uk → should redirect to https:// ✅
   - http://www.recipefinder.uk → should redirect to https:// ✅

3. **Check for**:
   - ✅ Green padlock (SSL working)
   - ✅ Correct website loads
   - ✅ No certificate warnings
   - ✅ Fast loading (Cloudflare caching)

### Step 3: GitHub Pages Status

**Check deployment status**:
1. Go to: https://github.com/AsadK47/RecipeFinder/deployments
2. Look for latest deployment
3. Status should be: ✅ **Active**

**Check domain verification**:
1. Settings → Pages
2. Custom domain should show: ✅ **DNS check successful**

### Step 4: SSL Certificate Verification

```bash
# Check SSL certificate
openssl s_client -connect recipefinder.uk:443 -servername recipefinder.uk

# Should show:
# - Cloudflare certificate
# - Verify return code: 0 (ok)
```

---

## Troubleshooting

### Problem: "DNS check unsuccessful"

**Cause**: DNS records not propagated or incorrect

**Solutions**:
1. Wait 15-30 minutes for DNS propagation
2. Verify all 4 A records are added correctly
3. Ensure proxy status is **Proxied** (orange cloud)
4. Check CNAME file exists in `website/` folder
5. Try removing and re-adding custom domain in GitHub

**Commands to debug**:
```bash
# Check what DNS is returning
dig recipefinder.uk A +short
nslookup recipefinder.uk

# Should eventually return Cloudflare IPs
```

### Problem: "404 - File not found"

**Cause**: GitHub Pages looking in wrong folder or file missing

**Solutions**:
1. Ensure `website/index.html` exists
2. Verify branch is set to `main` in GitHub Pages settings
3. Confirm folder is set to `/website`
4. Check file names are lowercase (case-sensitive)
5. Wait 5-10 minutes after changing settings

### Problem: "Certificate error" or "Not secure"

**Cause**: SSL not fully configured or propagated

**Solutions**:
1. Wait 10-15 minutes for SSL certificate to provision
2. In Cloudflare: SSL/TLS → Set to **Full (strict)**
3. In GitHub: Enable **Enforce HTTPS**
4. Clear browser cache and try incognito mode
5. Check Edge Certificate status in Cloudflare

### Problem: Website loads but looks broken

**Cause**: Relative paths in HTML broken

**Solutions**:
1. Check CSS/JS file paths in `index.html`
2. Ensure paths are relative: `./styles.css` or `/styles.css`
3. Verify all asset files are committed to git
4. Check browser console for 404 errors
5. Test locally first: `open website/index.html`

### Problem: "www not working"

**Cause**: CNAME record missing or incorrect

**Solutions**:
1. Add CNAME record: `www` → `asadk47.github.io`
2. Ensure proxy status is **Proxied**
3. Wait for DNS propagation
4. GitHub Pages should handle www automatically

### Problem: Slow loading or not updating

**Cause**: Cloudflare caching old version

**Solutions**:
1. Purge Cloudflare cache:
   - Dashboard → Caching → Purge Everything
2. Wait 5 minutes
3. Hard refresh browser: `Cmd + Shift + R` (Mac)
4. Try incognito mode to bypass browser cache

---

## Advanced Configuration

### Page Rules (Optional)

**Cloudflare Page Rules** for better performance:

1. **Always Use HTTPS**:
   ```
   URL: http://*recipefinder.uk/*
   Setting: Automatic HTTPS Rewrites - On
   ```

2. **Cache Everything**:
   ```
   URL: recipefinder.uk/*
   Settings:
     - Cache Level: Cache Everything
     - Edge Cache TTL: 1 day
   ```

### Analytics Setup

**Enable Cloudflare Analytics**:
1. Dashboard → Analytics & Logs
2. View real-time traffic
3. See visitor locations
4. Monitor threats blocked

---

## Command Reference

### Quick Setup Commands

```bash
# Navigate to website folder
cd /Users/asad.e.khan/Documents/Personal/app_ideas/RecipeFinder/website

# Create/update CNAME file
echo "recipefinder.uk" > CNAME

# Commit and push
git add CNAME
git commit -m "Update CNAME for custom domain"
git push origin main

# Wait 5-10 minutes, then test
curl -I https://recipefinder.uk
```

### DNS Testing Commands

```bash
# Check A records
dig recipefinder.uk A +short

# Check CNAME records
dig www.recipefinder.uk CNAME +short

# Full DNS query
dig recipefinder.uk ANY

# Check from different DNS servers
dig @8.8.8.8 recipefinder.uk  # Google DNS
dig @1.1.1.1 recipefinder.uk  # Cloudflare DNS
```

### SSL Testing Commands

```bash
# Check SSL certificate
curl -vI https://recipefinder.uk 2>&1 | grep -i ssl

# Full SSL check
openssl s_client -connect recipefinder.uk:443 -servername recipefinder.uk

# Check SSL grade
# Visit: https://www.ssllabs.com/ssltest/analyze.html?d=recipefinder.uk
```

---

## Timeline

**Expected setup time**: 30 minutes - 2 hours

| Step | Time |
|------|------|
| Add DNS records in Cloudflare | 5 min |
| Configure GitHub Pages | 5 min |
| DNS propagation | 15 min - 24 hrs |
| SSL certificate provisioning | 5-15 min |
| Verification & testing | 10 min |

**Typical experience**: Working in 30-60 minutes ✅

---

## Support Resources

### Official Documentation

- **Cloudflare DNS**: https://developers.cloudflare.com/dns/
- **GitHub Pages**: https://docs.github.com/en/pages
- **Custom Domain Setup**: https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site

### Useful Tools

- **DNS Checker**: https://www.whatsmydns.net/
- **SSL Test**: https://www.ssllabs.com/ssltest/
- **Cloudflare Status**: https://www.cloudflarestatus.com/
- **GitHub Status**: https://www.githubstatus.com/

---

## ✅ Completion Checklist

Use this to verify everything is set up correctly:

- [ ] All 4 A records added to Cloudflare DNS
- [ ] CNAME record for www added
- [ ] All records set to **Proxied** (orange cloud)
- [ ] `website/CNAME` file contains `recipefinder.uk`
- [ ] GitHub Pages source: `main` branch, `/website` folder
- [ ] Custom domain set in GitHub Pages: `recipefinder.uk`
- [ ] GitHub Pages shows "DNS check successful"
- [ ] "Enforce HTTPS" enabled in GitHub Pages
- [ ] Cloudflare SSL mode: Full (strict)
- [ ] "Always Use HTTPS" enabled in Cloudflare
- [ ] `https://recipefinder.uk` loads correctly
- [ ] `https://www.recipefinder.uk` loads correctly
- [ ] Green padlock showing (SSL working)
- [ ] Both http URLs redirect to https
- [ ] DNS propagation complete (check whatsmydns.net)
- [ ] GitHub deployment status: Active
- [ ] Cloudflare analytics showing traffic

**When all checked**: Your website is live! 🎉

---

**Last Updated**: November 5, 2025  
**Author**: Asad Khan  
**Domain**: recipefinder.uk  
**Repository**: github.com/AsadK47/RecipeFinder
