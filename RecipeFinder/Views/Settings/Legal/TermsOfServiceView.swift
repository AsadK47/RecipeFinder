import SwiftUI

// NOTE: Updated 2026-11-10 alongside the Privacy Policy: current behaviour described without ruling out opt-in
// sync, sharing or accounts later.
// Minimum age stated as 13 (UK age of digital consent). Have a solicitor review before App Store submission.
struct TermsOfServiceView: View {
    var body: some View {
        LegalDocumentScaffold(title: "Terms of Service", subtitle: "Last Updated: \(LegalDocument.lastUpdated)") {
            Group {
                SectionTitle("1. Interpretation and General")
                
                BodyText("1.1 Definitions. In these Terms:")
                LegalBulletPoint("\"Developer\" means Asad Khan, an individual based in England and Wales.")
                LegalBulletPoint("\"Application\" means the RecipeFinder mobile application and associated website located at recipefinder.uk.")
                LegalBulletPoint("\"User\" or \"you\" means any person who accesses, downloads, installs or uses the Application.")
                LegalBulletPoint("\"Terms\" means these Terms of Service, as amended from time to time.")
                
                BodyText("1.2 Acceptance. By accessing or using the Application, you agree to be bound by these Terms. If you do not agree to these Terms, you must not use the Application.")
                
                SectionTitle("2. Scope of Service")
                
                BodyText("2.1 The Application provides recipe discovery, import, organization and related recipe management features. The Developer may modify, suspend or discontinue the Application (or any part thereof) at any time.")

                BodyText("2.2 The Application may offer optional paid features. Where it does, these are sold and processed by Apple through your App Store account under Apple's terms, and are subject to Apple's billing, renewal and refund policies.")

                SectionTitle("3. Access")

                BodyText("3.1 The current version of the Application does not require an account or sign-in, and your profile and data are stored on your device (see the Privacy Policy). If optional accounts or online features are introduced, additional terms for those features will be shown before you use them.")

                BodyText("3.2 You are responsible for keeping your device secure. You must be at least 13 years old to use the Application.")
                
                SectionTitle("4. Acceptable Use")
                
                BodyText("4.1 You shall not:")
                LegalBulletPoint("use the Application in violation of applicable law;")
                LegalBulletPoint("infringe the intellectual property or other rights of third parties;")
                LegalBulletPoint("attempt to gain unauthorised access to any systems or data;")
                LegalBulletPoint("introduce viruses, malware, or other harmful code; or")
                LegalBulletPoint("use the Application for any unlawful or abusive purpose.")
            }
            
            Group {
                SectionTitle("5. Intellectual Property")
                
                BodyText("5.1 All intellectual property rights in and to the Application and its content (including software, logos and trademarks) are owned by the Developer or its licensors. Nothing in these Terms grants you any rights to the Developer's intellectual property except as expressly set out in these Terms.")
                
                SectionTitle("6. User Content")
                
                BodyText("6.1 You retain ownership of all content you create or import within the Application. The Developer does not claim ownership of your content.")
                
                BodyText("6.2 When importing recipes from third-party websites, you are responsible for ensuring compliance with applicable copyright laws and terms of use of such websites.")
                
                BodyText("6.3 If you use a feature to share content with other people, you grant those people, and the Developer only as needed to operate that feature, a non-exclusive licence to store, display and copy that content for the purpose of the sharing you chose. You can stop sharing at any time.")
                
                SectionTitle("7. Warranty Disclaimer")
                
                BodyText("7.1 The Application is provided \"as is\" and the Developer expressly disclaims all warranties, whether express or implied, including warranties of merchantability, fitness for a particular purpose and non-infringement.")
                
                BodyText("7.2 The Developer does not warrant the accuracy, completeness or safety of any recipes or cooking instructions displayed in the Application. You are solely responsible for verifying recipe information and food safety.")
            }
            
            Group {
                SectionTitle("8. Limitation of Liability")
                
                BodyText("8.1 To the maximum extent permitted by applicable law, the Developer's total liability arising out of or in connection with these Terms shall be limited to the greater of £50 or the amount you have paid to the Developer in the 12 months preceding the claim.")
                
                BodyText("8.2 The Developer shall not be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation loss of data, loss of profits or damage arising from food preparation.")
                
                SectionTitle("9. Third-Party Content and Links")
                
                BodyText("9.1 The Application may contain links to third-party websites or services. The Developer is not responsible for the content or policies of such third parties, and your use of third-party services is at your own risk.")
                
                SectionTitle("10. Recipe Import and Data Handling")
                
                BodyText("10.1 When you elect to import a recipe by providing a URL, the Application retrieves the content directly from the URL you supply. The Developer does not intermediate or store copies of the source webpages. Imported recipe data is stored with your other data as described in the Privacy Policy.")
                
                SectionTitle("11. Termination")
                
                BodyText("11.1 The Developer may suspend or terminate your access to the Application immediately if you breach these Terms or where required by law.")
            }
            
            Group {
                SectionTitle("12. Governing Law and Jurisdiction")
                
                BodyText("12.1 These Terms shall be governed by and construed in accordance with the laws of England and Wales. The courts of England and Wales shall have exclusive jurisdiction to settle any dispute arising out of or in connection with these Terms.")
                
                SectionTitle("13. Amendments")
                
                BodyText("13.1 The Developer may amend these Terms from time to time. Material changes will be notified through the Application or on the Developer's website. Continued use of the Application following notice of changes constitutes acceptance of the updated Terms.")
                
                SectionTitle("14. Severability")
                
                BodyText("14.1 If any provision of these Terms is held to be invalid or unenforceable, the remaining provisions shall continue in full force and effect.")
                
                SectionTitle("15. Contact")
                
                BodyText("For enquiries regarding these Terms, you may contact:")
                BodyText("Asad Khan")
                BodyText("Email: recipefinderuk@gmail.com")
                BodyText("Website: recipefinder.uk")
            }
        }
    }
}
