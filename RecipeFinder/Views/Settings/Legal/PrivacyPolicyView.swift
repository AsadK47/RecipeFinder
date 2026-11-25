import SwiftUI

// NOTE: Updated 2026-11-10 (owner request): describes today's data flows without promising they can never change,
// so opt-in features (iCloud sync/sharing, accounts) can be added by updating this policy first.
// Updated 2026-11-14 (owner OK in BACKLOG, Data safety 2/4): Section 7 describes the opt-in iCloud sync.
// Updated 2026-11-15 (BACKLOG Inbox): 4.2 lists what stays on the Device (recent searches, update safety copies);
// 5.1/5.2 describe the web search session and kept copies of web pictures.
// Updated 2026-11-20 (owner OK in BACKLOG, Plan slice 4): 4.2/4.3 list the dishes passed on in Plan my week (30 days).
// Updated 2026-11-20 (owner OK in BACKLOG, Groceries slice 3): 4.2/4.3 list the aisle order learned in shop mode.
// Updated 2026-11-22 (BACKLOG Inbox): 4.2 aisle order is per shop, or for trips with no shop chosen (matches AisleOrder).
// Updated 2026-11-23 (owner OK in chat, BACKLOG Needs owner "Privacy policy vs public TestFlight"): 6.4–6.6 and
// 10.1–10.2 describe TestFlight beta feedback (fetch_testflight_feedback.py: public issues + 14-day public artifact).
// Updated 2026-11-24 (BACKLOG Inbox, reviewer): 6.5 names crash reports as public; 7.3 describes share-sheet sharing
// (RecipeDetailToolbar recipe file/text, KitchenShoppingView list text, CookbookShareSheet picture + caption).
// Updated 2026-11-25 (owner OK in chat): 6.5–6.6 — feedback stays in App Store Connect; public issues are content-free
// notices (fetch_testflight_feedback.py `issue_for`), no artifacts.
// (The 2026-11-23 public-issue/artifact design above is superseded by 2026-11-25.) Open legal questions: the US transfer
// safeguard per provider, and a short written legitimate-interests assessment for beta feedback.
// Flagged for legal review: minimum age is stated as 13 (UK age of digital consent under UK GDPR).
// This copy is drafted from the code's real data flows; have a solicitor review before App Store submission.
struct PrivacyPolicyView: View {
    var body: some View {
        LegalDocumentScaffold(title: "Privacy Policy", subtitle: "Last Updated: \(LegalDocument.lastUpdated)") {
            Group {
                SectionTitle("1. Interpretation and Definitions")

                BodyText("1.1 In this Privacy Policy:")
                LegalBulletPoint("\"Developer\", \"we\", \"us\" or \"our\" means Asad Khan, an individual based in England and Wales.")
                LegalBulletPoint("\"Application\" means the RecipeFinder mobile application software.")
                LegalBulletPoint("\"User\", \"you\" or \"your\" means the individual accessing or using the Application.")
                LegalBulletPoint("\"Personal Information\" means any information relating to an identified or identifiable natural person.")
                LegalBulletPoint("\"Device\" means any device that can access the Application, such as an iPhone or iPad.")
            }

            Group {
                SectionTitle("2. Our Approach to Privacy")

                BodyText("2.1 The Application is designed to be private by default. In the current version, information you enter or generate is stored on your Device (and, if you turn on iCloud sync, in your own iCloud account) and is not collected by, or accessible to, the Developer, except where the Application retrieves content from the internet for features you use (see Section 5) and feedback you choose to send while testing a beta version (see Sections 6.4 to 6.6).")

                BodyText("2.2 We will only collect or share Personal Information in the ways described in this Privacy Policy. If we introduce a feature that would handle your information differently, we will update this Privacy Policy before that feature is made available, and any such feature will be optional.")

                SectionTitle("3. Accounts")

                BodyText("3.1 The current version of the Application does not require an account or sign-in. You can use its features without providing any Personal Information. Any name or photo you add to your profile is stored on your Device (and in your own iCloud account if you turn on iCloud sync — see Section 7).")
            }

            Group {
                SectionTitle("4. Information Stored on Your Device")

                BodyText("4.1 The following is created and held on your Device (and, if you turn on iCloud sync, in your own iCloud account — see Section 7):")
                LegalBulletPoint("Recipes you create or import, including ingredients, instructions, notes, tags, cuisine, dietary information, favourites and the original text a recipe was imported from")
                LegalBulletPoint("Meal plans, shopping lists (including shop names) and kitchen inventory")
                LegalBulletPoint("Collections, cooking history, ratings and achievements")
                LegalBulletPoint("Photos you add to recipes, together with your profile name, chef type and any profile photo")

                BodyText("4.2 The following is held on your Device:")
                LegalBulletPoint("Your app preferences and settings")
                LegalBulletPoint("Your recent web searches, so you can repeat them")
                LegalBulletPoint("The dishes you passed on in Plan my week, kept for 30 days so your next week's cards lead with something fresh")
                LegalBulletPoint("The order you usually shop the aisles in, for each shop you choose, and for trips with no shop chosen, learned from your ticks in I'm in the shop, so your list follows your route")
                LegalBulletPoint("Copies of pictures from recipe websites, so imported recipes show their picture offline")
                LegalBulletPoint("Up to three safety copies of your recipe database, made before an app update changes how it is stored, to help recover your recipes if an update goes wrong. Newer copies replace older ones after later updates, and they are kept out of device backups.")
                LegalBulletPoint("If your recipe database can't be opened, a copy of it set aside so it can be recovered")

                BodyText("4.3 Reset (Settings > Data Management) clears the information in Section 4.1, your recent web searches, the dishes you passed on in Plan my week, the aisle order learned in I'm in the shop, the copies of website pictures and your preferences (your iCloud sync choice is kept), and restores the sample recipes. The safety copies and set-aside database copies stay until you uninstall the Application.")

                BodyText("4.4 Your Device's own backups (iCloud Backup or a computer) include this information, except the safety copies, and are managed by Apple or your computer.")
            }

            Group {
                SectionTitle("5. Network Activity")

                BodyText("5.1 Recipe import. When you import a recipe by supplying a URL (directly or via the share sheet), the Application retrieves content directly from the website you specify. The Developer does not intermediate, store copies of, or monitor those requests. What you type in a web search is sent to the search engine you choose (change it in Settings > Recipe Search) and is handled under that engine's privacy policy. Web searches and the pages you open from them load directly from the search engine or website you choose, in a private browsing session that is cleared when you close the search. Your recent searches are kept on your Device so you can repeat them; Reset clears them.")

                BodyText("5.2 Images. When a recipe you import has a picture from a website, the Application downloads it directly from that address in the background (on each of your devices, if iCloud sync is on) and keeps a copy on your Device so the picture shows offline. No information about you is sent to those sources beyond what is required to request the image.")

                BodyText("5.3 On-device processing. Where supported, recipe text interpretation (using Apple's on-device foundation models) and photo text recognition (using Apple's Vision framework) run entirely on your Device. The text and photos you process are not sent to the Developer or any third party. To offer to import a copied recipe link, the Application asks iOS whether your clipboard holds a web link, which does not reveal its contents; it reads the clipboard when you tap Paste.")

                BodyText("5.4 The Application does not integrate with any third-party analytics services, advertising networks, or tracking technologies, and does not use advertising identifiers.")
            }

            Group {
                SectionTitle("6. Apple Services")

                BodyText("6.1 In-app purchases. If the Application offers optional paid features, purchases are processed by Apple under Apple's terms and privacy policy. The Developer does not receive or store your payment card details.")

                BodyText("6.2 Notifications. The Application may schedule local notifications (such as cooking timers and meal reminders) on your Device, only with your permission.")

                BodyText("6.3 Ratings. The Application may ask you to rate it using Apple's standard prompt. No information is collected through this prompt.")

                BodyText("6.4 Beta testing. If you test a beta version through Apple's TestFlight, feedback you choose to send (your comment, any screenshots and any crash report) reaches the Developer through Apple, under Apple's TestFlight terms and privacy policy. Apple includes the time you sent it, your email address where Apple shares it, and technical details about your device such as its model, iOS version, language, time zone, network type, battery level and free storage. The Developer uses this to fix and improve the Application.")

                BodyText("6.5 So the Developer knows it has arrived, a short notice with the kind of feedback, its date and Apple's reference number (which only the Developer can link back to you) is posted in the Application's public GitHub project. Your comment, screenshots, crash report and device details stay in App Store Connect, where the Developer reads them, under Apple's retention.")

                BodyText("6.6 To fix a problem you report, the Developer writes what needs doing in the Developer's own words on that notice, leaving out anything that identifies you, and may work on it with AI coding tools (currently Anthropic's Claude). Your feedback is held by Apple, the notice and the Developer's notes by GitHub, and the Developer's notes may be shared with Anthropic; these companies may process them in the United States under the safeguards in their own terms. To have your feedback deleted, contact the Developer (Section 13); deleting it includes removing the notice.")

                SectionTitle("7. Optional Sync and Sharing")

                BodyText("7.1 iCloud sync. You can turn on iCloud sync in Settings > Data Management. It is off until you turn it on. Turning it on or off takes effect the next time you open the Application. While it is on, everything described in Section 4.1, including photos you add to recipes, is stored in the private database of your own iCloud account, using Apple's CloudKit service under Apple's terms and privacy policy, and kept up to date on each device signed in to that account. Each device fetches its own copy of pictures from recipe websites (Section 5.2). The Developer cannot access your iCloud account or the data in it.")

                BodyText("7.2 You can turn iCloud sync off at any time in the same place; sync stops the next time you open the Application, and your data stays on your Device. Data already stored in iCloud stays in your iCloud account until you remove it, which you can do in your device's iCloud settings. While sync is on, deleting data in the Application, including through Reset, removes it from your iCloud account and from every device signed in to it. Reset keeps your iCloud sync choice. If you turn sync off, make changes (including deletions) and later turn it back on, the Application then sends those changes to your iCloud account and to every device signed in to it.")

                BodyText("7.3 Sharing. Through the iOS share sheet you can share a recipe (as a recipe file or as text), your shopping list (as text) and a My Cookbook page (as a picture with a caption naming the dish, how many times you've made it and when). You can also save a backup file of your data wherever you choose (Section 9.1). What you share goes to the people and apps you choose, who can see and keep it, and is handled from then on under their terms; the Application does not send the Developer a copy. Any future feature that shares content in a new way will be off until you turn it on, and this Privacy Policy will be updated to describe it before it is released.")
            }

            Group {
                SectionTitle("8. Data Security")

                BodyText("8.1 Data held on your Device is protected by your Device's own security, and data held in iCloud by Apple's. The Developer does not hold copies of it; beta feedback you choose to send is handled as described in Sections 6.4 to 6.6.")

                BodyText("8.2 The Developer recommends that you secure your Device with a strong passcode, and keep device encryption enabled.")

                SectionTitle("9. Your Rights and Control")

                BodyText("9.1 You stay in control of your data. You may at any time:")
                LegalBulletPoint("Export your recipes and other data via Settings > Data Management (photos are not included in the export)")
                LegalBulletPoint("Delete your data via Settings > Data Management")
                LegalBulletPoint("Remove all data from your Device by uninstalling the Application (data in your iCloud account is removed as described in Section 7.2)")
            }

            Group {
                SectionTitle("10. Data Protection Laws")

                BodyText("10.1 The Application is designed to comply with the UK General Data Protection Regulation (UK GDPR) and the Data Protection Act 2018. Because the Developer does not collect or receive the information you enter, the Developer does not act as a data controller of that information for most purposes. For beta feedback you choose to send (Sections 6.4 to 6.6), the Developer is the data controller and relies on legitimate interests (fixing and improving the Application); your feedback stays in App Store Connect under Apple's retention, and the notice stays in the public project, each until you ask for it to be deleted. If another feature changes this, this Privacy Policy will set out the lawful basis, retention period and your rights for that feature.")

                BodyText("10.2 For beta feedback, you can ask the Developer for a copy of it, to correct or delete it, or to stop using it, by contacting the Developer (Section 13). You can also complain to the Information Commissioner's Office (ico.org.uk). The Developer acts on the copy it controls; Apple's copy is handled under Apple's privacy policy.")

                SectionTitle("11. Children's Privacy")

                BodyText("11.1 The Application is not directed to children under the age of 13, and you should not use the Application if you are under 13.")

                SectionTitle("12. Changes to This Privacy Policy")

                BodyText("12.1 The Developer may amend this Privacy Policy at any time. The date of the most recent revision is shown at the top of this Privacy Policy.")

                BodyText("12.2 Material changes will be notified through the Application before they take effect. Where a change relies on your consent, we will ask for it rather than treat continued use as consent.")
            }

            Group {
                SectionTitle("13. Contact Information")

                BodyText("13.1 For enquiries regarding this Privacy Policy, you may contact:")
                BodyText("Asad Khan")
                BodyText("Email: recipefinderuk@gmail.com")
                BodyText("Website: recipefinder.uk")
            }
        }
    }
}
