import SwiftUI

/// Me tab: who you are as a cook (hero + stats), then your cookbook. Profile, badges and chef type are one tap deeper;
/// Settings is behind the gear.
struct MeView: View {
    /// Set by "View all badges": Me opens Profile (the trophy shelf) and clears it.
    var openProfile: Binding<Bool> = .constant(false)
    /// Set by Today's next-badge row alongside `openProfile`; Profile scrolls to the shelf, opens the badge, clears it.
    var trophyShelfRequest: Binding<TrophyShelfRequest?> = .constant(nil)

    @Environment(\.recipeStore) private var recipeStore
    @Environment(\.profile) private var profileManager
    @Environment(\.badges) private var badgeManager
    @Environment(\.cookingStreak) private var cookingStreak
    @Environment(\.scenePhase) private var scenePhase

    @State private var showSettings = false
    @State private var showProfile = false
    /// My Cookbook's pages, rebuilt when recipes change rather than in `body`.
    @State private var cookbookPages: [CookbookPage] = []
    @State private var profileImage: UIImage?
    /// The hero's dinners · streak · cuisines, refreshed with the cookbook rather than in `body`.
    @State private var stats: [MeStat] = []
    /// "5 / 24" badges earned, refreshed with the cookbook rather than in `body`.
    @State private var badgeCount = ""
    /// "5 of 24 badges earned" for VoiceOver, which reads "/" as "slash".
    @State private var spokenBadgeCount = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 0) {
                    ScreenTitleHeader("Me") {
                        // A plain button + navigationDestination: a NavigationLink wrapping CircleButton's own
                        // Button never pushed in UI tests.
                        CircleButton(icon: "gearshape.fill") { showSettings = true }
                            .accessibilityLabel("Settings")
                            .accessibilityIdentifier("me.settings")
                    }

                    ScrollView {
                        VStack(spacing: AppTheme.spacing24) {
                            MeHeroCard(
                                image: profileImage,
                                // No name yet → a person symbol, as on Profile, not "RC" from the "Recipe Chef" stand-in.
                                initials: profileManager.firstName.isEmpty && profileManager.lastName.isEmpty
                                    ? "" : profileManager.initials,
                                name: profileManager.fullName,
                                chefType: profileManager.chefType,
                                stats: stats,
                                badgeCount: badgeCount,
                                spokenBadgeCount: spokenBadgeCount
                            ) {
                                showProfile = true
                            }
                            MyCookbookSection(pages: cookbookPages)
                        }
                        .padding(.top, AppTheme.spacing16)
                        .padding(.horizontal, AppTheme.cardHorizontalPadding)
                        .padding(.bottom, AppTheme.spacing100)
                    }
                }
            }
            .appNavigationTitle("")
            // Me draws its own title header; an empty bar above it would only waste space.
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showSettings) { SettingsTabView() }
            .navigationDestination(isPresented: $showProfile) { ProfileView(shelfRequest: trophyShelfRequest) }
            // A cookbook page opens its recipe, to cook it again.
            .navigationDestination(for: UUID.self) { id in
                if let recipe = recipeStore.recipes.first(where: { $0.id == id }) {
                    RecipeDetailView(recipe: recipe)
                }
            }
            .onAppear {
                cookingStreak.reload()
                refreshCookbook()
                profileImage = profileManager.loadProfileImage()
                openProfileIfAsked()
            }
            .onChange(of: openProfile.wrappedValue) { _, _ in openProfileIfAsked() }
            // Coming back from Profile: the photo may have changed.
            .onChange(of: showProfile) { _, showing in
                guard !showing else { return }
                profileImage = profileManager.loadProfileImage()
                refreshCookbook()
            }
            .onChange(of: recipeStore.recipes) { _, _ in refreshCookbook() }
            // "today" / "yesterday" on the pages move on overnight.
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                // "this year" and the pages' "today" move on overnight.
                cookingStreak.reload()
                refreshCookbook()
            }
        }
    }

    private func refreshCookbook() {
        cookbookPages = MyCookbook.pages(from: recipeStore.recipes)
        stats = MeStats.strip(recipes: recipeStore.recipes, streakWeeks: cookingStreak.streak.currentWeeks)
        let shelf = BadgeShelf.sections(badgeManager.getAllBadges(recipeCount: recipeStore.recipes.count))
        badgeCount = BadgeShelf.countText(shelf)
        spokenBadgeCount = BadgeShelf.spokenCount(shelf)
    }

    private func openProfileIfAsked() {
        guard openProfile.wrappedValue else { return }
        openProfile.wrappedValue = false
        showSettings = false
        showProfile = true
    }
}

#Preview {
    MeView()
}
