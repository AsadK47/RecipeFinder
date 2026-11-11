import SwiftUI

/// Today tab: greeting + streak, a "Tonight" hero (planned meal, else kitchen match, else a quick recipe) that Shuffle
/// steps through, with a time-aware "Start by" line (tap it to change when dinner is), and shelves of recipes to cook.
/// Kept calm on purpose: one card for tonight, plain photo shelves below, the theme accent on "Cook this" alone.
struct TodayView: View {
    /// Switches the main tab (Recipes, Plan, …).
    let onOpen: (AppTab) -> Void
    /// Opens the "+" add-recipe sheet.
    let onAddRecipe: () -> Void
    /// Imports a recipe from a link pasted on the clipboard card.
    let onImportLink: (URL) -> Void

    @Environment(\.recipeStore) private var recipeStore
    @Environment(\.mealPlanning) private var mealPlanning
    @Environment(\.kitchen) private var kitchen
    @Environment(\.cookingStreak) private var cookingStreak
    @Environment(\.scenePhase) private var scenePhase

    /// Pushes the recipe with cooking mode already up, so finishing lands on its detail (Made it, rating).
    private struct CookRoute: Hashable { let recipeID: UUID }

    @State private var path = NavigationPath()
    // Computed on data change, not in body (matching ingredients across every recipe isn't free).
    @State private var feed: TodayFeed?
    /// The recipe Shuffle is showing (by id, so a refresh never swaps the card by position); nil = the hero.
    @State private var tonightRecipeID: UUID?
    @State private var showsClipboardCard = false
    /// Pasteboard change count when the card was last offered.
    @State private var clipboardChange = 0
    /// The copy already pasted or dismissed, kept across launches so the same link doesn't come back.
    @AppStorage("today.handledClipboardChange") private var handledClipboardChange = -1
    @State private var showNoClipboardLink = false
    /// "Dinner at" from the Tonight card's timing line; read through `TonightTiming.eatAt(stored:)`.
    @AppStorage("today.eatAt") private var storedEatAt = TonightTiming.defaultEatAt

    /// Morning before noon, afternoon until 6pm, evening after.
    nonisolated static func greeting(forHour hour: Int) -> String {
        switch hour {
        case 0..<12: "Good morning"
        case 12..<18: "Good afternoon"
        default: "Good evening"
        }
    }

    /// The clock Today reads. DEBUG `-today-time HH:MM` pins it so Screenshots can show morning/afternoon/evening.
    private static func now() -> Date {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let flag = args.firstIndex(of: "-today-time"), args.indices.contains(flag + 1) {
            let parts = args[flag + 1].split(separator: ":").compactMap { Int($0) }
            if parts.count == 2,
               let pinned = Calendar.current.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: Date()) {
                return pinned
            }
        }
        #endif
        return Date()
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AppBackground()

                VStack(spacing: 0) {
                    ScreenTitleHeader("Today")

                    ScrollView {
                        VStack(alignment: .leading, spacing: AppTheme.spacing20) {
                            header
                            if showsClipboardCard {
                                TodayClipboardCard(onPaste: pasted, onDismiss: dismissClipboardCard)
                            }
                            if let feed { content(feed) }
                        }
                        .padding(.horizontal, AppTheme.spacing20)
                        .padding(.top, AppTheme.spacing16)
                        .padding(.bottom, AppTheme.spacing40)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: UUID.self) { id in
                if let recipe = recipeStore.recipes.first(where: { $0.id == id }) {
                    RecipeDetailView(recipe: recipe)
                }
            }
            .navigationDestination(for: CookRoute.self) { route in
                if let recipe = recipeStore.recipes.first(where: { $0.id == route.recipeID }) {
                    RecipeDetailView(recipe: recipe, startsCooking: true)
                }
            }
        }
        .onAppear(perform: refresh)
        .task { await probeClipboard() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await probeClipboard() } }
        }
        .alert("No link found", isPresented: $showNoClipboardLink) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Copy the recipe's web address, then tap Paste again.")
        }
        .onChange(of: recipeStore.recipes) { _, _ in refresh() }
        .onChange(of: kitchen.items) { _, _ in refresh() }
    }

    private func refresh() {
        let now = Self.now()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        feed = TodayFeed.make(
            recipes: recipeStore.recipes,
            todaysPlans: mealPlanning.mealPlans(for: now),
            kitchenItemNames: kitchen.items.map(\.name),
            tomorrowsPlans: tomorrow == now ? [] : mealPlanning.mealPlans(for: tomorrow),
            now: now
        )
    }

    private func probeClipboard() async {
        let change = ClipboardLinkProbe.changeCount
        let hasLink = await ClipboardLinkProbe.hasWebLink()
        clipboardChange = change
        showsClipboardCard = ClipboardRecipeLink.shouldOffer(
            hasWebLink: hasLink, changeCount: change, handledChangeCount: handledClipboardChange
        )
    }

    private func pasted(_ url: URL?) {
        guard let url else {
            showNoClipboardLink = true
            return
        }
        HapticManager.shared.light()
        dismissClipboardCard()
        onImportLink(url)
    }

    private func dismissClipboardCard() {
        handledClipboardChange = clipboardChange
        showsClipboardCard = false
    }

    private var header: some View {
        HStack(alignment: .center, spacing: AppTheme.spacing12) {
            Text(Self.greeting(forHour: Calendar.current.component(.hour, from: Self.now())))
                .font(.title2.weight(.bold))
                .adaptiveForegroundColor()
            Spacer(minLength: 0)
            if cookingStreak.streak.currentWeeks > 0 {
                StreakChip(streak: cookingStreak.streak)
            } else {
                Label("Start a streak", systemImage: "flame")
                    .font(.footnote.weight(.semibold))
                    .adaptiveSecondaryForeground()
                    .padding(.horizontal, AppTheme.spacing10)
                    .padding(.vertical, AppTheme.spacing6)
                    .appCard(in: Capsule())
                    .accessibilityLabel("Start a streak: cook anything this week")
                    .accessibilityIdentifier("today.startStreak")
            }
        }
    }

    @ViewBuilder
    private func content(_ feed: TodayFeed) -> some View {
        if feed.isNewUser {
            firstRecipeCard
        }

        let shown = feed.tonightPick(showing: tonightRecipeID)
        if let hero = shown {
            TodayHeroCard(
                hero: hero,
                timing: TonightTiming.line(
                    hero: hero, quickCount: feed.quickCount, minuteOfDay: TonightTiming.minuteOfDay(Self.now()),
                    eatAt: TonightTiming.eatAt(stored: storedEatAt)
                ),
                eatAt: Binding(
                    get: { TonightTiming.eatAt(stored: storedEatAt) },
                    set: { storedEatAt = $0 }
                ),
                onShuffle: feed.tonightOptions.count > 1 ? { shuffle(feed, from: hero) } : nil,
                onOpen: { open(hero.recipe) },
                onCook: { cook(hero.recipe) }
            )
        } else if !feed.isNewUser {
            shortcut(.plan, title: "Plan tonight", subtitle: "Pick something for dinner and it shows up here.", color: .blue)
        }

        ForEach(feed.prepAhead, id: \.recipe.id) { nudge in
            TodayPrepAheadRow(nudge: nudge) { open(nudge.recipe) }
        }

        if feed.isNewUser, !feed.starters.isEmpty {
            TodayShelf(title: "Starters to try", id: "starters",
                       items: feed.starters.map { ($0, $0.hasTotalTime ? $0.totalTime : nil) }, onOpen: open)
        }
        // Shelves leave out the pick on the card, so a shuffled-to recipe isn't repeated just below it.
        let shownID = shown?.recipe.id
        let cookAgain = feed.cookAgain.filter { $0.id != shownID }
        let kitchenMatches = feed.fitsYourKitchen.filter { $0.recipe.id != shownID }
        let rediscover = feed.rediscover.filter { $0.id != shownID }
        if !cookAgain.isEmpty {
            TodayShelf(title: "Cook again", id: "cookAgain", items: cookAgain.map { ($0, nil) }, onOpen: open)
        }
        if !kitchenMatches.isEmpty {
            TodayShelf(title: "Fits your kitchen", id: "kitchen",
                       items: kitchenMatches.map { ($0.recipe, "You have \($0.have)/\($0.total)") }, onOpen: open)
        }
        if !rediscover.isEmpty {
            TodayShelf(title: "Rediscover", id: "rediscover", items: rediscover.map { ($0, nil) }, onOpen: open)
        }
    }

    private var firstRecipeCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Bring in your first recipe")
                .font(.headline)
                .adaptiveForegroundColor()
            Text("Add one from a link, a photo, pasted text or your own notes, and Today starts suggesting what to cook.")
                .font(.subheadline)
                .adaptiveSecondaryForeground()
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton("Add a recipe", systemImage: "plus.circle.fill") {
                HapticManager.shared.light()
                onAddRecipe()
            }
            .accessibilityIdentifier("today.addFirstRecipe")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.spacing20)
        .appCard()
    }

    private func shuffle(_ feed: TodayFeed, from current: TodayFeed.Hero) {
        HapticManager.shared.light()
        withAnimation(.easeInOut(duration: 0.25)) {
            tonightRecipeID = feed.nextTonightPick(after: current.recipe.id)?.recipe.id
        }
    }

    private func open(_ recipe: RecipeModel) {
        HapticManager.shared.light()
        path.append(recipe.id)
    }

    private func cook(_ recipe: RecipeModel) {
        HapticManager.shared.light()
        path.append(CookRoute(recipeID: recipe.id))
    }

    private func shortcut(_ tab: AppTab, title: String, subtitle: String, color: Color) -> some View {
        Button {
            HapticManager.shared.light()
            onOpen(tab)
        } label: {
            HStack(spacing: AppTheme.spacing16) {
                IconBadge(systemName: tab.icon, tint: color, diameter: 44, iconSize: AppTheme.fontSize18, style: .tinted)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(AppTheme.spacing20)
            .appCard()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("today.open.\(tab.rawValue)")
    }
}

#Preview {
    TodayView(onOpen: { _ in }, onAddRecipe: {}, onImportLink: { _ in })
}
