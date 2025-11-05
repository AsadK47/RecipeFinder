# 🚀 Quick Setup: GitHub Pages + Cloudflare DNS

**Goal**: Connect `recipefinder.uk` to your GitHub Pages website

---

## 📦 What You Have

- **Website**: HTML files in `website/` folder
- **Domain**: `recipefinder.uk` (managed by Cloudflare)
- **Hosting**: GitHub Pages (free static hosting)
- **Repository**: `AsadK47/RecipeFinder`

---

## ⚡️ Quick Setup (15 minutes)

### Step 1: Cloudflare DNS Records

**Go to**: [Cloudflare Dashboard](https://dash.cloudflare.com/) → Select domain → DNS

**Add these 5 records**:

```
1. Type: A,    Name: @,   Content: 185.199.108.153,  Proxy: ON (🟠)
2. Type: A,    Name: @,   Content: 185.199.109.153,  Proxy: ON (🟠)
3. Type: A,    Name: @,   Content: 185.199.110.153,  Proxy: ON (🟠)
4. Type: A,    Name: @,   Content: 185.199.111.153,  Proxy: ON (🟠)
5. Type: CNAME, Name: www, Content: asadk47.github.io, Proxy: ON (🟠)
```

### Step 2: GitHub Pages Setup

**Go to**: GitHub → Settings → Pages

```yaml
Source:
  Branch: main
  Folder: /website

Custom domain: recipefinder.uk

Enforce HTTPS: ✅ ON
```

### Step 3: CNAME File

**Ensure this file exists**: `website/CNAME`

**Contents**:
```
recipefinder.uk
```

### Step 4: Wait & Test

⏰ **Wait**: 15-30 minutes for DNS propagation

🧪 **Test**: Visit https://recipefinder.uk

✅ **Success**: Green padlock + website loads!

---

## 🎯 That's It!

Your website is now live at:
- https://recipefinder.uk
- https://www.recipefinder.uk

---

## 📖 Need More Details?

See complete guide: [`website/CLOUDFLARE_SETUP.md`](website/CLOUDFLARE_SETUP.md)

---

## ❓ Common Issues

**"DNS check unsuccessful"**
- Wait 30 minutes
- Verify all 5 DNS records added
- Check CNAME file exists

**"404 Not Found"**
- Ensure `website/index.html` exists
- Check branch/folder settings
- Wait 10 minutes

**"Not Secure"**
- Enable "Enforce HTTPS" in GitHub
- Set Cloudflare SSL to "Full (strict)"
- Wait 15 minutes

---

**Ready to go live?** Follow the steps above! 🚀
