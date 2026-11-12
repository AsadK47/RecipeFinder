import SwiftUI

struct ProfileView: View {
    var title = "Profile"
    /// The Me tab root shows a gear into Settings; pushed copies (from Settings, badge sheet) don't.
    var showsSettingsLink = false

    @Environment(\.profile) private var profileManager
    @Environment(\.badges) private var badgeManager
    @Environment(\.recipeStore) private var recipeStore
    @Environment(\.cookingStreak) private var cookingStreak

    @State private var activeSheet: ProfileSheet?
    @State private var showSettings = false
    @State private var profileImage: UIImage?
    @State private var editingName = false
    @State private var tempName = ""
    @State private var showSuccessFeedback = false
    @State private var badgeMetrics = BadgeMetrics()
    @State private var pagerStart: BadgePagerStart?
    /// Set by a locked badge's "earn it here" button; acted on once the pager has fully closed.
    @State private var pendingEarn: BadgeEarnAction?

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var selectedChefType: ChefType = .homeCook

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                ScreenTitleHeader(title) {
                    if showsSettingsLink {
                        // A plain button + navigationDestination: a NavigationLink wrapping CircleButton's own
                        // Button never pushed in UI tests.
                        CircleButton(icon: "gearshape.fill") { showSettings = true }
                            .accessibilityLabel("Settings")
                            .accessibilityIdentifier("me.settings")
                    }
                }

                ScrollView {
                    VStack(spacing: AppTheme.spacing24) {
                        ProfileAvatar(
                            image: profileImage,
                            initials: getInitials(),
                            chefType: selectedChefType,
                            onTap: {
                                activeSheet = .imagePicker
                                HapticManager.shared.light()
                            }
                        )

                        ProfilePersonalInfoSection(
                            firstName: $firstName,
                            lastName: $lastName
                        )

                        ProfileBadgesSection(
                            sections: shelf,
                            metrics: badgeMetrics,
                            onSelectBadge: { badge in
                                pagerStart = BadgePagerStart(badgeID: badge.id)
                            }
                        )

                        ProfileChefTypeSection(
                            selectedChefType: $selectedChefType,
                        )

                        Button(action: saveProfile) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Profile")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.accentColor)
                            .adaptiveForegroundColor()
                            .cornerRadius(AppTheme.cornerRadius12)
                        }
                        .opacity(showSuccessFeedback ? 0.6 : 1)
                        .disabled(showSuccessFeedback)
                        .padding(.top, AppTheme.spacing8)

                        if showSuccessFeedback {
                            HStack(spacing: AppTheme.spacing8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Profile saved successfully!")
                                    .fontWeight(.medium)
                            }
                            .padding()
                            .background(AppTheme.success.opacity(0.1))
                            .cornerRadius(AppTheme.cornerRadius12)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.top, AppTheme.spacing16)
                    .padding(.horizontal, AppTheme.cardHorizontalPadding)
                    .padding(.bottom, AppTheme.spacing100)
                }
            }
        }
        .appNavigationTitle("")
        // Me's root draws its own title header; an empty bar above it would only waste space.
        .toolbar(showsSettingsLink ? .hidden : .automatic, for: .navigationBar)
        .navigationDestination(isPresented: $showSettings) { SettingsTabView() }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .privacyPolicy:
                PrivacyPolicyView()
            case .imagePicker:
                ImagePicker(image: $profileImage)
            }
        }
        .fullScreenCover(item: $pagerStart, onDismiss: openPendingEarn) { start in
            BadgePagerView(
                badges: BadgeShelf.pagerOrder(shelf),
                startID: start.badgeID,
                metrics: badgeMetrics,
                onEarn: { pendingEarn = $0 }
            )
        }
        .animation(.appSpring, value: editingName)
        .animation(.appSpring, value: showSuccessFeedback)
        .onAppear {
            loadCurrentProfile()
            cookingStreak.reload()
            badgeMetrics = BadgeMetrics.from(recipes: recipeStore.recipes, streakWeeks: cookingStreak.streak.currentWeeks)
        }
        .onChange(of: profileImage) { _, newImage in
            profileManager.saveProfileImage(newImage)
        }
    }

    private var shelf: [BadgeShelfSection] {
        BadgeShelf.sections(badgeManager.getAllBadges(recipeCount: recipeStore.recipes.count))
    }

    private func openPendingEarn() {
        guard let action = pendingEarn else { return }
        pendingEarn = nil
        NotificationCenter.default.post(name: action.notification, object: nil)
    }

    private func getInitials() -> String {
        let firstInitial = firstName.first.map(String.init) ?? ""
        let lastInitial = lastName.first.map(String.init) ?? ""
        return "\(firstInitial)\(lastInitial)".uppercased()
    }

    private func loadCurrentProfile() {
        firstName = profileManager.firstName
        lastName = profileManager.lastName
        selectedChefType = profileManager.chefType

        profileImage = profileManager.loadProfileImage()
    }

    private func saveProfile() {
        profileManager.updateProfile(
            firstName: firstName,
            lastName: lastName,
            chefType: selectedChefType
        )

        showSuccessFeedback = true
        HapticManager.shared.success()

        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayFeedback) {
            showSuccessFeedback = false
        }
    }
}
