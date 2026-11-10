import SwiftUI

// NOTE: Updated 2026-11-10 (owner request): describes today's data flows without promising they can never change,
// so opt-in features (iCloud sync/sharing, accounts) can be added by updating this policy first.
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

                BodyText("2.1 The Application is designed to be private by default. In the current version, information you enter or generate is stored on your Device and is not collected by, or accessible to, the Developer, except where you direct the Application to retrieve content from the internet (see Section 5).")

                BodyText("2.2 We will only collect or share Personal Information in the ways described in this Privacy Policy. If we introduce a feature that would handle your information differently, we will update this Privacy Policy before that feature is made available, and any such feature will be optional.")

                SectionTitle("3. Accounts")

                BodyText("3.1 The current version of the Application does not require an account or sign-in. You can use its features without providing any Personal Information. Any name or photo you add to your profile is stored on your Device.")
            }

            Group {
                SectionTitle("4. Information Stored on Your Device")

                BodyText("4.1 The following is created and held on your Device (and in your own iCloud account only where you enable a feature that uses it — see Section 7):")
                LegalBulletPoint("Recipes you create or import, including ingredients, instructions, notes, tags, cuisine and dietary information")
                LegalBulletPoint("Meal plans, shopping lists and kitchen inventory")
                LegalBulletPoint("Collections, cooking history, ratings and achievements")
                LegalBulletPoint("Photos you add to recipes, together with your profile name and any profile photo")
                LegalBulletPoint("Your app preferences and settings")
            }

            Group {
                SectionTitle("5. Network Activity")

                BodyText("5.1 Recipe import. When you import a recipe by supplying a URL (directly or via the share sheet), the Application retrieves content directly from the website you specify. The Developer does not intermediate, store copies of, or monitor those requests. Web searches and the pages you open from them load directly from the search engine or website you choose; browsing data from them is not kept.")

                BodyText("5.2 Images. The Application may load recipe images directly from image addresses contained within recipes you import. No information about you is sent to those sources beyond what is required to request the image.")

                BodyText("5.3 On-device processing. Where supported, recipe text interpretation (using Apple's on-device foundation models) and photo text recognition (using Apple's Vision framework) run entirely on your Device. The text and photos you process are not sent to the Developer or any third party.")

                BodyText("5.4 The Application does not integrate with any third-party analytics services, advertising networks, or tracking technologies, and does not use advertising identifiers.")
            }

            Group {
                SectionTitle("6. Apple Services")

                BodyText("6.1 In-app purchases. If the Application offers optional paid features, purchases are processed by Apple under Apple's terms and privacy policy. The Developer does not receive or store your payment card details.")

                BodyText("6.2 Notifications. The Application may schedule local notifications (such as cooking timers and meal reminders) on your Device, only with your permission.")

                BodyText("6.3 Ratings. The Application may ask you to rate it using Apple's standard prompt. No information is collected through this prompt.")

                SectionTitle("7. Optional Sync and Sharing")

                BodyText("7.1 The current version does not synchronise your data to any cloud service. Future versions may offer optional features such as iCloud synchronisation, or sharing recipes and collections with people you choose. Where such a feature uses Apple's iCloud, your data is stored in your own iCloud account under Apple's terms, and content you choose to share is visible to the people you share it with.")

                BodyText("7.2 Any such feature will be off until you turn it on, and Sections 4 and 5 will be updated to describe what it does before it is released.")
            }

            Group {
                SectionTitle("8. Data Security")

                BodyText("8.1 Data held on your Device is protected by your Device's own security, and data held in iCloud by Apple's. The Developer does not hold copies of it.")

                BodyText("8.2 The Developer recommends that you secure your Device with a strong passcode, and keep device encryption enabled.")

                SectionTitle("9. Your Rights and Control")

                BodyText("9.1 You retain complete control over your data. You may at any time:")
                LegalBulletPoint("Export your data via Settings > Data Management")
                LegalBulletPoint("Delete your data via Settings > Data Management")
                LegalBulletPoint("Remove all data by uninstalling the Application from your Device")
            }

            Group {
                SectionTitle("10. Data Protection Laws")

                BodyText("10.1 The Application is designed to comply with the UK General Data Protection Regulation (UK GDPR) and the Data Protection Act 2018. While the information you enter is not collected or received by the Developer, the Developer does not act as a data controller of that information for most purposes. If that changes for any feature, this Privacy Policy will set out the lawful basis, retention period and your rights for that feature.")

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
