import SwiftUI

/// App tour, usage guides, contact options, and FAQs.
struct HelpView: View {
    @State private var showOnboarding = false

    var body: some View {
        SettingsScreen("Help & Support") {
            SettingsCard {
                Button(action: {
                    showOnboarding = true
                    HapticManager.shared.light()
                }) {
                    SettingsRow(icon: "play.circle.fill", iconColor: .purple, title: "Take the App Tour", subtitle: "Learn how to use RecipeFinder")
                        .padding(AppTheme.spacing20)
                }
                .buttonStyle(PlainButtonStyle())
            }

            VStack(spacing: AppTheme.spacing8) {
                SettingsSectionHeader(title: "Getting Started")

                SettingsCard {
                    VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                        HelpItem(
                            icon: "magnifyingglass",
                            title: "Finding Recipes",
                            description: "Search by name, ingredients, or browse categories. Use the burger menu to access filters and sorting options."
                        )

                        HelpItem(
                            icon: "heart.fill",
                            title: "Saving Favorites",
                            description: "Tap the heart icon on any recipe to add it to your favorites for quick access later."
                        )

                        HelpItem(
                            icon: "calendar",
                            title: "Meal Planning",
                            description: "Plan your weekly meals by tapping dates and assigning recipes to breakfast, lunch, or dinner."
                        )

                        HelpItem(
                            icon: "refrigerator",
                            title: "Managing Your Kitchen",
                            description: "Track ingredients you have on hand, set expiration dates, and manage storage locations."
                        )

                        HelpItem(
                            icon: "cart",
                            title: "Groceries",
                            description: "Build your groceries from recipes or add items manually. Check them off as you shop!"
                        )

                        HelpItem(
                            icon: "timer",
                            title: "Cooking Timers",
                            description: "Start a recipe timer from the toolbar and control it with pause, resume, or stop."
                        )

                        HelpItem(
                            icon: "note.text",
                            title: "Recipe Notes",
                            description: "Add personal notes, modifications, and ratings to any recipe to remember what worked."
                        )
                    }
                    .padding(AppTheme.spacing20)
                }
            }

            VStack(spacing: AppTheme.spacing8) {
                SettingsSectionHeader(title: "Gestures")

                SettingsCard {
                    VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                        HelpItem(
                            icon: "checkmark.circle",
                            title: "Check off ingredients",
                            description: "While cooking, tap an ingredient's name to cross it off. Tap its amount to jump straight into the editor for that ingredient."
                        )

                        HelpItem(
                            icon: "frying.pan",
                            title: "Cook mode",
                            description: "Open a recipe and tap the pan icon in the toolbar for a big, glanceable step-by-step layout."
                        )

                        HelpItem(
                            icon: "photo.on.rectangle",
                            title: "Dish photos",
                            description: "Add a photo after cooking, then tap any recipe photo to view it full-screen — swipe between photos and pinch to zoom."
                        )
                    }
                    .padding(AppTheme.spacing20)
                }
            }

            VStack(spacing: AppTheme.spacing8) {
                SettingsSectionHeader(title: "Tips & Tricks")

                SettingsCard {
                    VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                        HelpItem(
                            icon: "square.and.arrow.up",
                            title: "Sharing Recipes",
                            description: "Tap the share button on any recipe to send as text or beautiful PDF."
                        )

                        HelpItem(
                            icon: "paintpalette",
                            title: "Customize Appearance",
                            description: "Choose from 8 beautiful themes and frosted or solid card styles in Settings > Appearance."
                        )

                        HelpItem(
                            icon: "star",
                            title: "Smart Filters",
                            description: "Use the burger menu in Recipes to filter by difficulty, prep time, or category."
                        )

                        HelpItem(
                            icon: "link",
                            title: "Import Recipes",
                            description: "Paste any recipe URL in the burger menu to automatically import it into your collection."
                        )
                    }
                    .padding(AppTheme.spacing20)
                }
            }

            SettingsSection(title: "Contact Support", items: [
                .init(
                    row: SettingsRow(icon: "envelope.fill", iconColor: .teal, title: "Email Support", subtitle: "recipefinderuk@gmail.com", accessory: .externalLink),
                    action: {
                        if let url = URL(string: "mailto:recipefinderuk@gmail.com?subject=RecipeFinder%20Support") {
                            UIApplication.shared.open(url)
                        }
                    }
                ),
                .init(
                    row: SettingsRow(icon: "globe", iconColor: .blue, title: "Visit Website", subtitle: "recipefinder.uk", accessory: .externalLink),
                    action: {
                        if let url = URL(string: "https://recipefinder.uk") {
                            UIApplication.shared.open(url)
                        }
                    }
                )
            ])

            VStack(spacing: AppTheme.spacing8) {
                SettingsSectionHeader(title: "Frequently Asked Questions")

                SettingsCard {
                    VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                        FAQItem(
                            question: "Is RecipeFinder free to use?",
                            answer: "Yes! RecipeFinder is free with optional premium features coming soon."
                        )

                        FAQItem(
                            question: "Does the app work offline?",
                            answer: "Yes. Your saved recipes and data are accessible offline."
                        )

                        FAQItem(
                            question: "Can I import my own recipes?",
                            answer: "Absolutely! Use the recipe import feature in the burger menu to paste any recipe URL, or create recipes manually."
                        )

                        FAQItem(
                            question: "How do I backup my data?",
                            answer: "Your data is automatically saved. You can also export a backup from Settings > Data Management."
                        )

                        FAQItem(
                            question: "Can I share recipes with friends?",
                            answer: "Yes! Use the share button on any recipe to export as text or PDF that you can send via any app."
                        )

                        FAQItem(
                            question: "How do I change the app theme?",
                            answer: "Go to Settings > Appearance & Theme to choose from 8 beautiful color themes and card styles."
                        )

                        FAQItem(
                            question: "Is my data private and secure?",
                            answer: "Yes. See our Privacy Policy for full details on how we handle your information."
                        )

                        FAQItem(
                            question: "How do I delete my data?",
                            answer: "Go to Settings > Data Management > Reset App to Default. Note that this will remove all your data permanently."
                        )
                    }
                    .padding(AppTheme.spacing20)
                }
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
    }
}

struct HelpItem: View {
    let icon: String
    let title: String
    let description: String


    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacing16) {
            Image(systemName: icon)
                .font(.title3)
                .adaptiveForegroundColor()
                .frame(width: AppTheme.width30)

            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .adaptiveForegroundColor()

                Text(description)
                    .font(.caption)
                    .adaptiveSecondaryForeground()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct FAQItem: View {
    let question: String
    let answer: String

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Button(action: {
                withAnimation(.appSpring) {
                    isExpanded.toggle()
                }
                HapticManager.shared.light()
            }) {
                HStack(alignment: .top, spacing: AppTheme.spacing12) {
                    Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.accentColor)
                        .frame(width: AppTheme.width30)

                    Text(question)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .adaptiveForegroundColor()
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                Text(answer)
                    .font(.caption)
                    .adaptiveSecondaryForeground()
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, AppTheme.spacing42)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

#Preview {
    NavigationStack {
        HelpView()
    }
}
