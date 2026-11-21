import SwiftUI

/// Me › Profile: photo, trophy shelf and chef type. The name is edited in place on Me's hero, or in Settings › Profile.
struct ProfileView: View {
    var title = "Profile"
    /// From Today's next-badge row: scroll to the trophy shelf and open that badge's card; cleared once handled.
    var shelfRequest: Binding<TrophyShelfRequest?> = .constant(nil)

    @Environment(\.profile) private var profileManager
    @Environment(\.badges) private var badgeManager
    @Environment(\.recipeStore) private var recipeStore
    @Environment(\.cookingStreak) private var cookingStreak

    @State private var activeSheet: ProfileSheet?
    @State private var profileImage: UIImage?
    @State private var showSuccessFeedback = false
    @State private var badgeMetrics = BadgeMetrics()
    @State private var pagerStart: BadgePagerStart?
    /// The grouped shelf behind See all; opened by a deep link to a badge that's in neither row.
    @State private var showFullShelf = false
    /// Set by a locked badge's "earn it here" button; acted on once the pager has fully closed.
    @State private var pendingEarn: BadgeEarnAction?

    @State private var selectedChefType: ChefType = .homeCook

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                ScreenTitleHeader(title) {}

                ScrollViewReader { scroller in
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

                            ProfileBadgesSection(
                                sections: shelfSections,
                                earned: earnedBadges,
                                nextUp: nextUpBadges,
                                metrics: badgeMetrics,
                                showAll: $showFullShelf,
                                onSelectBadge: { badge, row in
                                    pagerStart = BadgePagerStart(badgeID: badge.id, row: row)
                                },
                                onStartCooking: {
                                    NotificationCenter.default.post(name: BadgeEarnAction.cook.notification, object: nil)
                                }
                            )
                            .id(Self.shelfAnchor)

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
                                .foregroundStyle(AppTheme.onAccent)
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
                    // Covers Profile appearing (fresh push) and a new request while it's already on screen.
                    .task(id: shelfRequest.wrappedValue) { await handleShelfRequest(scroller) }
                }
            }
        }
        .appNavigationTitle("")
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .privacyPolicy:
                PrivacyPolicyView()
            case .imagePicker:
                ImagePicker(image: $profileImage)
            }
        }
        // A sheet, not a full-screen cover, so the card closes with a swipe down as well as the ✕ (owner 2026-11-17).
        .sheet(item: $pagerStart, onDismiss: openPendingEarn) { start in
            BadgePagerView(
                badges: BadgeShelf.pagerOrder(
                    start.row, earned: earnedBadges, nextUp: nextUpBadges, sections: shelfSections
                ),
                startID: start.badgeID,
                metrics: badgeMetrics,
                onEarn: { pendingEarn = $0 }
            )
            .presentationDragIndicator(.visible)
        }
        .animation(.appSpring, value: showSuccessFeedback)
        .onAppear {
            loadCurrentProfile()
            cookingStreak.reload()
            refreshBadgeMetrics()
        }
        // Recipes can load after Me appears, or change under a sheet; keep the rings in step with the shelf.
        .onChange(of: recipeStore.recipes) { _, _ in
            refreshBadgeMetrics()
        }
        .onChange(of: profileImage) { _, newImage in
            profileManager.saveProfileImage(newImage)
        }
    }

    private static let shelfAnchor = "profile.trophyShelf"

    /// Waits for the tab switch / push to settle first: a cover presented mid-transition is silently dropped, and a
    /// scroll before layout does nothing. Cleared last — clearing changes the task id, which cancels this task.
    private func handleShelfRequest(_ scroller: ScrollViewProxy) async {
        guard let request = shelfRequest.wrappedValue else { return }
        do { try await Task.sleep(for: .milliseconds(450)) } catch { return }
        if let id = request.badgeID,
           BadgeShelf.needsFullShelf(for: id, earned: earnedBadges, nextUp: nextUpBadges) {
            showFullShelf = true
        }
        withAnimation(.appSpring) { scroller.scrollTo(Self.shelfAnchor, anchor: .top) }
        if let id = request.badgeID { pagerStart = BadgePagerStart(badgeID: id) }
        shelfRequest.wrappedValue = nil
    }

    private var allBadges: [Badge] {
        badgeManager.getAllBadges(recipeCount: recipeStore.recipes.count)
    }

    private var shelfSections: [BadgeShelfSection] { BadgeShelf.sections(allBadges) }
    private var earnedBadges: [Badge] { BadgeShelf.earned(allBadges) }
    private var nextUpBadges: [Badge] { BadgeShelf.nextUp(allBadges, metrics: badgeMetrics) }

    private func refreshBadgeMetrics() {
        badgeMetrics = BadgeMetrics.from(recipes: recipeStore.recipes, streakWeeks: cookingStreak.streak.currentWeeks)
    }

    private func openPendingEarn() {
        guard let action = pendingEarn else { return }
        pendingEarn = nil
        NotificationCenter.default.post(name: action.notification, object: nil)
    }

    /// Empty with no name, like Me's hero — not "RC" from the "Recipe Chef" stand-in.
    private func getInitials() -> String {
        let firstInitial = profileManager.firstName.first.map(String.init) ?? ""
        let lastInitial = profileManager.lastName.first.map(String.init) ?? ""
        return "\(firstInitial)\(lastInitial)".uppercased()
    }

    private func loadCurrentProfile() {
        selectedChefType = profileManager.chefType

        profileImage = profileManager.loadProfileImage()
    }

    private func saveProfile() {
        // The name is edited on Me's hero or in Settings › Profile; this screen saves the chef type.
        profileManager.updateProfile(
            firstName: profileManager.firstName,
            lastName: profileManager.lastName,
            chefType: selectedChefType
        )

        showSuccessFeedback = true
        HapticManager.shared.success()

        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayFeedback) {
            showSuccessFeedback = false
        }
    }
}
