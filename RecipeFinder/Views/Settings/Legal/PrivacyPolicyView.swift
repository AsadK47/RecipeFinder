import SwiftUI

// NOTE: Updated 2026-11-04: the app has no accounts or sign-in — a single local user, local-only storage.
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

                BodyText("2.1 The Application is offline-first and private by design. The Developer operates no servers and maintains no backend account for you. Information you enter or generate is stored on your Device and is not collected by, transmitted to, or accessible to the Developer or any third party, except where you explicitly direct the Application to retrieve content from the internet (see Section 5).")

                SectionTitle("3. No Accounts")

                BodyText("3.1 The Application does not have accounts or sign-in. You can use every feature without creating an account or providing any Personal Information. Any name or photo you add to your profile is stored only on your Device.")
            }

            Group {
                SectionTitle("4. Information Stored on Your Device")

                BodyText("4.1 The following is created and held solely on your Device:")
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

                BodyText("6.2 Notifications. The Application may schedule local notifications (such as cooking timers and meal reminders) on your Device, only with your permission. No notifications are sent from the Developer's servers.")

                BodyText("6.3 Ratings. The Application may ask you to rate it using Apple's standard prompt. No information is collected through this prompt.")

                SectionTitle("7. Cloud Synchronisation")

                BodyText("7.1 The Application does not currently synchronise your data to any cloud service; all data remains on your Device. If optional iCloud synchronisation is introduced in a future version, your data would be stored in your own private iCloud account, governed by Apple's terms, and the Developer would not have access to it.")
            }

            Group {
                SectionTitle("8. Data Security")

                BodyText("8.1 As your data remains on your Device and is not transmitted to the Developer, its security depends primarily on your Device's own protections.")

                BodyText("8.2 The Developer recommends that you secure your Device with a strong passcode, and keep device encryption enabled.")

                SectionTitle("9. Your Rights and Control")

                BodyText("9.1 You retain complete control over your data. You may at any time:")
                LegalBulletPoint("Export your data via Settings > Data Management")
                LegalBulletPoint("Delete your data via Settings > Data Management")
                LegalBulletPoint("Remove all data by uninstalling the Application from your Device")
            }

            Group {
                SectionTitle("10. Data Protection Laws")

                BodyText("10.1 The Application is designed to comply with the UK General Data Protection Regulation (UK GDPR) and the Data Protection Act 2018. Because the information you enter remains on your Device and is not collected or received by the Developer, the Developer does not act as a data controller of that information for most purposes. You remain in control of the data held on your Device.")

                SectionTitle("11. Children's Privacy")

                BodyText("11.1 The Application is not directed to children under the age of 13, and you should not use the Application if you are under 13.")

                SectionTitle("12. Changes to This Privacy Policy")

                BodyText("12.1 The Developer may amend this Privacy Policy at any time. The date of the most recent revision is shown at the top of this Privacy Policy.")

                BodyText("12.2 Material changes will be notified through the Application. Continued use of the Application following notification constitutes acceptance of the amended Privacy Policy.")
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
