# 🍎 Apple Developer Account Setup Guide - RecipeFinder™

Complete guide to setting up your Apple Developer account for RecipeFinder™ Limited.

---

## 📋 Prerequisites Checklist

Before starting, ensure you have:
- ✅ Apple ID registered with your business email
- ✅ Apple Developer Program membership ($99/year paid)
- ✅ Mac with Xcode installed
- ✅ RecipeFinder project ready
- ✅ Business information (RecipeFinder™ Limited, UK)

---

## 🚀 Step-by-Step Setup

### Step 1: Access Apple Developer Portal

1. Go to [developer.apple.com](https://developer.apple.com)
2. Sign in with your Apple ID
3. Verify your membership is active (should show "Account" in top nav)

---

### Step 2: Configure Your Account

#### A. Update Account Information

1. Click **Account** → **Membership**
2. Verify your details:
   - **Entity Type:** Company/Organization (if you registered as business)
   - **Legal Entity Name:** RecipeFinder™ Limited
   - **Country:** United Kingdom
   - **Email:** recipefinderuk@gmail.com

#### B. Add Team Members (Optional)

If you'll have collaborators:
1. Go to **People** → **Invite People**
2. Choose role:
   - **Admin:** Full access
   - **App Manager:** Manage apps and submissions
   - **Developer:** Development only
   - **Marketing:** App Store management only

---

### Step 3: Create App ID (Bundle Identifier)

This is crucial for your app's identity.

#### In Developer Portal:

1. Go to **Certificates, IDs & Profiles**
2. Click **Identifiers** → **+** (plus button)
3. Select **App IDs** → Continue
4. Choose **App** → Continue
5. Configure:
   - **Description:** RecipeFinder
   - **Bundle ID:** `com.recipefinder.RecipeFinder` (or your preference)
   - **Platform:** iOS
   
6. **Capabilities** - Enable what you need:
   - ✅ **Push Notifications** (for cooking timers)
   - ✅ **Sign in with Apple** (if you use authentication)
   - ✅ **iCloud** (for future sync - optional)
   - ✅ **App Groups** (for shared data - optional)
   - ❌ Skip others for now

7. Click **Continue** → **Register**

**Important:** Your Bundle ID in Xcode MUST match this exactly!

---

### Step 4: Create Certificates

Certificates prove your identity when signing apps.

#### A. Development Certificate (for testing)

1. Go to **Certificates** → **+** (plus button)
2. Select **iOS App Development** → Continue
3. Follow instructions to create Certificate Signing Request (CSR):

   **On your Mac:**
   ```
   1. Open Keychain Access (Cmd+Space → "Keychain Access")
   2. Menu: Keychain Access → Certificate Assistant → Request Certificate from Certificate Authority
   3. Fill in:
      - User Email: recipefinderuk@gmail.com
      - Common Name: RecipeFinder Development
      - CA Email: Leave blank
      - Request: Saved to disk
   4. Save as: RecipeFinder_Dev.certSigningRequest
   ```

4. Upload the CSR file
5. Download the certificate
6. Double-click to install in Keychain

#### B. Distribution Certificate (for App Store)

Repeat the same process but:
- Select **Apple Distribution** instead
- Common Name: RecipeFinder Distribution
- Save as: RecipeFinder_Dist.certSigningRequest

---

### Step 5: Register Devices (for Testing)

#### Get Your iPhone UDID:

**Method 1 - Finder (easiest):**
```
1. Connect iPhone to Mac
2. Open Finder
3. Click on your iPhone in sidebar
4. Click on serial number under phone name
5. It will cycle to UDID (long hex string)
6. Right-click → Copy
```

**Method 2 - Xcode:**
```
1. Connect iPhone to Mac
2. Open Xcode
3. Window → Devices and Simulators
4. Select your device
5. Copy Identifier
```

#### Register in Portal:

1. Go to **Devices** → **+** (plus button)
2. Select **iOS, tvOS, watchOS** → Continue
3. Enter:
   - **Device Name:** My iPhone (or any name)
   - **Device ID (UDID):** Paste the UDID
4. Click **Continue** → **Register**

---

### Step 6: Create Provisioning Profiles

Provisioning profiles tie everything together (app ID + certificate + devices).

#### A. Development Provisioning Profile

1. Go to **Profiles** → **+** (plus button)
2. Select **iOS App Development** → Continue
3. Select your App ID (com.recipefinder.RecipeFinder) → Continue
4. Select your Development Certificate → Continue
5. Select devices to include → Continue
6. Profile Name: `RecipeFinder Development`
7. Click **Generate**
8. Download the profile
9. Double-click to install in Xcode

#### B. Distribution Provisioning Profile (for App Store)

1. Click **+** again
2. Select **App Store** → Continue
3. Select your App ID → Continue
4. Select your Distribution Certificate → Continue
5. Profile Name: `RecipeFinder App Store`
6. Click **Generate**
7. Download and install

---

### Step 7: Configure Xcode

#### A. Add Your Apple ID to Xcode

1. Open Xcode
2. **Xcode** → **Settings** (or Preferences)
3. Click **Accounts** tab
4. Click **+** → **Apple ID**
5. Sign in with your Apple Developer account
6. Select your team (RecipeFinder™ Limited or your name)
7. Click **Download Manual Profiles** (bottom right)

#### B. Configure Project Settings

1. Open `RecipeFinder.xcodeproj`
2. Select project in navigator (blue icon at top)
3. Select **RecipeFinder** target
4. Go to **Signing & Capabilities** tab

   **For Development:**
   ```
   ✅ Automatically manage signing (recommended)
   Team: Select your team from dropdown
   Bundle Identifier: com.recipefinder.RecipeFinder
   ```

   **For Release/Distribution:**
   ```
   Switch to "Release" configuration (top dropdown)
   ✅ Automatically manage signing
   Team: Same team
   Bundle Identifier: Same
   ```

5. If you see errors:
   - Click **Try Again**
   - Make sure Bundle ID matches what you created in portal
   - Ensure certificates are installed

---

### Step 8: Test on Device

#### Run on Your iPhone:

1. Connect iPhone to Mac
2. Unlock iPhone
3. In Xcode, select your iPhone from device dropdown (top toolbar)
4. Click **Run** button (▶️) or press **Cmd+R**
5. **First time:** iPhone will ask to trust certificate
   ```
   iPhone: Settings → General → VPN & Device Management
   → Developer App → Trust
   ```
6. App should launch on your iPhone! 🎉

---

### Step 9: Prepare for App Store

#### A. Create App Store Connect Record

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Sign in with your Apple ID
3. Click **My Apps** → **+** (plus icon) → **New App**
4. Fill in details:

   ```
   Platforms: ✅ iOS
   Name: RecipeFinder
   Primary Language: English (UK)
   Bundle ID: Select the one you created
   SKU: recipefinder-001 (unique identifier for your records)
   User Access: Full Access
   ```

5. Click **Create**

#### B. Fill in App Information

**Version Information:**
- Version Number: 1.0
- Copyright: 2025 RecipeFinder™ Limited

**App Information:**
- Category: Food & Drink (Primary)
- Category: Lifestyle (Secondary - optional)
- Content Rights: Check if contains third-party content
- Age Rating: Complete the questionnaire (likely 4+)

**Pricing & Availability:**
- Price: Free (or select price tier)
- Availability: All countries or select specific ones
- Pre-order: Available before launch (optional)

#### C. Prepare App Store Assets

You'll need these for submission:

**Screenshots (Required):**
- iPhone 6.7" (iPhone 14 Pro Max): 1290 × 2796 pixels
- iPhone 6.5" (iPhone 14 Plus): 1284 × 2778 pixels
- iPhone 5.5" (iPhone 8 Plus): 1242 × 2208 pixels

**How to capture:**
```bash
# In Simulator:
1. Open Simulator
2. Run your app
3. Navigate to screen you want
4. Cmd+S to save screenshot
5. Screenshots saved to Desktop
```

**App Icon:**
- 1024 × 1024 pixels (no alpha channel)
- Must match icon in app

**App Preview Video (Optional but recommended):**
- 15-30 seconds
- Show key features
- Portrait orientation

**Promotional Text & Description:**

Create these in a text editor first:

```markdown
Subtitle (30 chars max):
Your Personal Culinary Companion

Description (4000 chars max):
RecipeFinder is your elegant solution for managing recipes, 
planning meals, and organizing your kitchen. Built with beautiful 
design and powerful features, it's the cooking companion you've 
been waiting for.

FEATURES:
• Smart recipe management and import
• Intelligent shopping lists
• Kitchen inventory tracking
• Visual meal planning
• Cook timers with notifications
• 8 beautiful themes
• 100% private and offline

Keywords (100 chars, comma-separated):
recipe,cooking,meal planning,food,kitchen,grocery,shopping list
```

---

### Step 10: Build for App Store

#### A. Archive Your App

1. In Xcode, select **Any iOS Device (arm64)** as destination
2. **Product** → **Archive** (or Cmd+Shift+B won't work, use menu)
3. Wait for build to complete (1-5 minutes)
4. Xcode Organizer window will open automatically

#### B. Validate Archive

1. In Organizer, select your archive
2. Click **Validate App**
3. Choose options:
   - ✅ Upload your app's symbols
   - ✅ Manage Version and Build Number
4. Click **Next**
5. Select distribution certificate and profile
6. Wait for validation (can take 5-10 minutes)
7. Should see "Validation Successful" ✅

#### C. Upload to App Store Connect

1. Click **Distribute App**
2. Select **App Store Connect** → Next
3. Choose **Upload** → Next
4. Select options (same as validation)
5. Click **Upload**
6. Wait 5-15 minutes for processing
7. You'll get email when it's ready

---

### Step 11: Submit for Review

#### In App Store Connect:

1. Go to your app
2. Select version (1.0)
3. Build section → Select the build you uploaded
4. Fill in **What's New in This Version:**
   ```
   Welcome to RecipeFinder 1.0!
   
   • Beautiful recipe management
   • Smart shopping lists
   • Kitchen inventory tracking
   • Meal planning calendar
   • Cook timers
   • 8 stunning themes
   • 100% private & offline
   ```

5. **App Review Information:**
   - Contact: recipefinderuk@gmail.com
   - Phone: Your phone number
   - Demo Account: If needed for testing
   - Notes: Any special instructions for reviewers

6. **Version Release:**
   - Manually release this version (recommended for v1.0)
   - OR Automatically release after approval

7. Click **Add for Review** → **Submit for Review**

---

## ⏱️ Timeline Expectations

- **Certificate Setup:** 10-15 minutes
- **Xcode Configuration:** 5-10 minutes
- **First Device Test:** 5 minutes
- **App Store Connect Setup:** 20-30 minutes
- **Screenshots & Assets:** 1-2 hours
- **Archive & Upload:** 30 minutes
- **App Review:** 24-48 hours (typically)

---

## 🔧 Troubleshooting

### "No signing certificate found"
```
Solution:
1. Download certificates again from portal
2. Double-click to install
3. Restart Xcode
4. Try "Download Manual Profiles" in Xcode Settings
```

### "Provisioning profile doesn't match"
```
Solution:
1. Check Bundle ID matches exactly (case-sensitive)
2. Regenerate provisioning profile in portal
3. Download and install new profile
4. Clean build folder: Product → Clean Build Folder
```

### "Device not registered"
```
Solution:
1. Add device UDID in portal
2. Regenerate development provisioning profile
3. Download new profile
4. Try running again
```

### "Archive not showing in Organizer"
```
Solution:
1. Ensure "Any iOS Device (arm64)" is selected
2. Check scheme is set to "Release"
3. Clean build folder and try again
```

### "App Store Connect build not appearing"
```
Solution:
1. Wait 15-30 minutes (processing time)
2. Check email for any errors
3. Refresh App Store Connect page
4. Check build was uploaded successfully in Xcode Organizer
```

---

## 📝 Quick Command Reference

### Useful Xcode Shortcuts
```
Cmd+R          Run app
Cmd+.          Stop running app
Cmd+Shift+K    Clean build folder
Cmd+B          Build
Cmd+Shift+B    Archive (doesn't work, use menu)
Cmd+0          Show/hide Navigator
Cmd+Alt+0      Show/hide Inspectors
Cmd+Shift+Y    Show/hide Console
```

### Terminal Commands
```bash
# Check connected devices
xcrun xctrace list devices

# Check provisioning profiles
security find-identity -v -p codesigning

# Open simulator
open -a Simulator

# Clear derived data (if builds acting weird)
rm -rf ~/Library/Developer/Xcode/DerivedData
```

---

## 📋 Pre-Launch Checklist

Before submitting to App Store:

### Technical
- [ ] App runs on physical device
- [ ] No crashes or major bugs
- [ ] All features work as expected
- [ ] Proper error handling
- [ ] Good performance (60fps)
- [ ] Battery-efficient
- [ ] Proper memory usage

### Legal & Privacy
- [ ] Privacy Policy included/linked
- [ ] Terms of Service available
- [ ] Copyright notices present
- [ ] Proper attribution for third-party code
- [ ] App Store review guidelines followed

### Assets & Metadata
- [ ] App icon (1024×1024)
- [ ] Screenshots for all required sizes
- [ ] App description written
- [ ] Keywords researched
- [ ] Promotional text ready
- [ ] Support URL active
- [ ] Marketing URL (optional)

### Business
- [ ] RecipeFinder™ Limited properly identified
- [ ] Contact information correct
- [ ] Business email monitored
- [ ] Support system ready
- [ ] Marketing plan prepared

---

## 🎯 Next Steps After Setup

1. **Test Thoroughly**
   - Run on multiple devices/simulators
   - Test all features
   - Get beta testers via TestFlight

2. **Prepare Marketing**
   - Update recipefinder.uk website
   - Create social media accounts
   - Prepare launch announcement
   - Create press kit

3. **Plan Updates**
   - Roadmap for v1.1
   - Bug fix strategy
   - User feedback system
   - Update schedule

---

## 📞 Support Resources

**Apple Developer:**
- Portal: [developer.apple.com](https://developer.apple.com)
- Documentation: [developer.apple.com/documentation](https://developer.apple.com/documentation)
- Forums: [developer.apple.com/forums](https://developer.apple.com/forums)
- Support: [developer.apple.com/contact](https://developer.apple.com/contact)

**App Store Connect:**
- Portal: [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
- Help: [help.apple.com/app-store-connect](https://help.apple.com/app-store-connect)

**Your Resources:**
- Business Email: recipefinderuk@gmail.com
- Website: recipefinder.uk
- Company: RECIPEFINDER LIMITED
- Company Number: 16833243
- Registered: England and Wales

---

## 🎉 You're Ready!

Once you complete these steps, you'll be able to:
- ✅ Run RecipeFinder on your iPhone
- ✅ Test with real devices
- ✅ Upload builds to TestFlight
- ✅ Submit to App Store
- ✅ Release to the world!

**Welcome to the Apple Developer Program!** 🍎🚀

---

**RecipeFinder™ Limited**  
**Registered in United Kingdom**  
**recipefinder.uk | recipefinderuk@gmail.com**

Good luck with your launch! 🍳✨
