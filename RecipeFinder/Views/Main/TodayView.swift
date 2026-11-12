import SwiftUI

/// Today tab: greeting + streak, a "Tonight" hero (planned meal, else kitchen match, else a quick recipe) that Shuffle
/// steps through, with a time-aware "Start by" line (tap it to change when dinner is), a "This week" strip with a
/// one-tap "Plan tomorrow", your cooking progress (streak, cooks this week, next badge), a weekly never-cooked pick,
/// and shelves of recipes to cook.
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
    @Environment(\.badges) private var badges
    @Environment(\.scenePhase) private var scenePhase

    /// Pushes the recipe with cooking mode already up, so finishing lands on its detail (Made it, rating).
    private struct CookRoute: Hashable { let recipeID: UUID }
    /// A day whose dinner is being picked from the week strip.
    private struct PlanningDay: Identifiable { let date: Date; var id: Date { date } }

    @State private var path = NavigationPath()
    // Computed on data change, not in body (matching ingredients across every recipe isn't free).
    @State private var snapshot: TodaySnapshot?
    @State private var showsCookingSheet = false
    @State private var planningDay: PlanningDay?
    /// Picked in the sheet, planned once it has closed (a badge sheet can't show over one mid-dismissal).
    @State private var pendingPlan: (recipe: RecipeModel, date: Date)?
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
                            TodayGreetingHeader(
                                greeting: Self.greeting(forHour: Calendar.current.component(.hour, from: Self.now())),
                                streak: cookingStreak.streak
                            )
                            if showsClipboardCard {
                                TodayClipboardCard(onPaste: pasted, onDismiss: dismissClipboardCard)
                            }
                            if let snapshot { content(snapshot) }
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
        .onAppear {
            // The streak is only recomputed on a cook; a new week since then must reset "cooks this week".
            cookingStreak.reload()
            refresh()
        }
        .task { await probeClipboard() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            // Back after midnight: "today" and "tomorrow" move on, so Plan it never dates a plan from yesterday's view.
            cookingStreak.reload()
            refresh()
            Task { await probeClipboard() }
        }
        .alert("No link found", isPresented: $showNoClipboardLink) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Copy the recipe's web address, then tap Paste again.")
        }
        .sheet(item: $planningDay, onDismiss: planPicked) { day in
            RecipeSelectionSheet(mealTime: .dinner) { recipe in
                pendingPlan = (recipe, day.date)
                planningDay = nil
            }
        }
        .sheet(isPresented: $showsCookingSheet) { CookingSheet(streak: cookingStreak.streak) }
        .onChange(of: recipeStore.recipes) { _, _ in refresh() }
        .onChange(of: cookingStreak.streak) { _, _ in refresh() }
        .onChange(of: kitchen.items) { _, _ in refresh() }
        .onChange(of: kitchen.inventoryItems) { _, _ in refresh() }
    }

    private func refresh() {
        let now = Self.now()
        // Recurring meals are copied in when Plan opens a week; do it here too so Tonight and the strip show them.
        mealPlanning.propagateRecurring(toWeekStarting: Calendar.current.startOfDay(for: now))
        snapshot = TodaySnapshot.make(
            recipes: recipeStore.recipes,
            plansOn: { mealPlanning.mealPlans(for: $0) },
            kitchenItemNames: kitchen.items.map(\.name),
            inventoryItems: kitchen.inventoryItems,
            streak: cookingStreak.streak,
            unlockedBadgeIDs: Set(badges.getAllBadges(recipeCount: 0).filter(\.isUnlocked).map(\.id)),
            now: now
        )
    }

    /// Plans dinner unless one appeared since the strip was built (another path, a recurring copy) — never replaces it.
    private func planDinner(_ recipe: RecipeModel, on date: Date) {
        guard mealPlanning.mealPlan(for: date, mealTime: .dinner) == nil else {
            refresh()
            return
        }
        mealPlanning.addMealPlan(MealPlanModel(
            recipeId: recipe.id, recipeName: recipe.name, date: date, mealTime: .dinner, servings: recipe.currentServings
        ))
        HapticManager.shared.success()
        refresh()
    }

    private func planPicked() {
        guard let pendingPlan else { return }
        self.pendingPlan = nil
        planDinner(pendingPlan.recipe, on: pendingPlan.date)
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

    @ViewBuilder
    private func content(_ snapshot: TodaySnapshot) -> some View {
        let feed = snapshot.feed
        if feed.isNewUser {
            TodayFirstRecipeCard(onAddRecipe: onAddRecipe)
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
            TodayShortcutCard(
                tab: .plan, title: "Plan tonight", subtitle: "Pick something for dinner and it shows up here.",
                color: .blue, onOpen: onOpen
            )
        }

        ForEach(feed.prepAhead, id: \.recipe.id) { nudge in
            TodayPrepAheadRow(nudge: nudge) { open(nudge.recipe) }
        }

        if !feed.useSoon.isEmpty {
            TodayUseSoonCard(pairs: feed.useSoon, onOpen: open)
        }

        let week = snapshot.week
        TodayWeekCard(
            week: week,
            // With no recipes yet there's nothing to pick, so an empty day leads to adding one.
            onPlanDay: { date in
                if recipeStore.recipes.isEmpty { onAddRecipe() } else { planningDay = PlanningDay(date: date) }
            },
            onPlanTomorrow: { recipe in
                if let tomorrow = week.tomorrow { planDinner(recipe, on: tomorrow) }
            },
            onOpenPlan: { onOpen(.plan) }
        )

        TodayProgressCard(progress: snapshot.progress) { showsCookingSheet = true }

        // Shelves and the weekly pick leave out the recipe on the card, so a shuffled-to dish isn't repeated below it.
        let shownID = shown?.recipe.id
        if let tryNew = snapshot.tryNew, tryNew.id != shownID {
            TodayTryNewCard(recipe: tryNew, onOpen: open)
        }

        if feed.isNewUser, !feed.starters.isEmpty {
            TodayShelf(title: "Starters to try", id: "starters",
                       items: feed.starters.map { ($0, $0.hasTotalTime ? $0.totalTime : nil) }, onOpen: open)
        }
        let shelves = feed.shelves(excluding: [shownID, snapshot.tryNew?.id])
        if !shelves.cookAgain.isEmpty {
            TodayShelf(title: "Cook again", id: "cookAgain", items: shelves.cookAgain.map { ($0, nil) }, onOpen: open)
        }
        if !shelves.kitchenMatches.isEmpty {
            TodayShelf(title: "Fits your kitchen", id: "kitchen",
                       items: shelves.kitchenMatches.map { ($0.recipe, "You have \($0.have)/\($0.total)") }, onOpen: open)
        }
        if !shelves.rediscover.isEmpty {
            TodayShelf(title: "Rediscover", id: "rediscover", items: shelves.rediscover.map { ($0, nil) }, onOpen: open)
        }
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
}

#Preview {
    TodayView(onOpen: { _ in }, onAddRecipe: {}, onImportLink: { _ in })
}
