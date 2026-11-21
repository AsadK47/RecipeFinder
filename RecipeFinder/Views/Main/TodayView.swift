import SwiftUI

/// Today tab: greeting + streak, a hero for the next meal by the clock (planned meal, else kitchen match, else a quick
/// recipe; late evening → tomorrow's breakfast) that Shuffle steps through, with a time-aware "Start by" line for
/// dinner (tap it to change when dinner is), a one-line day strip (Breakfast ✓ · Lunch: Soup · Dinner: plan it), a "This week" strip with a
/// one-tap "Plan tomorrow" and your cooking progress (streak, cooks this week, next badge). Browsing lives on Recipes →
/// Discover ("Keep browsing →"), so Today stays short: one card for tonight, the theme accent on "Cook this" alone.
struct TodayView: View {
    /// Switches the main tab (Recipes, Plan, …).
    let onOpen: (AppTab) -> Void
    /// Opens Me's trophy shelf (from the cooking card's next-badge row).
    let onOpenBadges: (TrophyShelfRequest) -> Void
    /// Opens the "+" add-recipe sheet.
    let onAddRecipe: () -> Void
    /// Imports a recipe from a link pasted on the clipboard card.
    let onImportLink: (URL) -> Void
    /// Opens Plan with Plan my week's deck dealing.
    var onPlanWeek: () -> Void = {}

    @Environment(\.recipeStore) private var recipeStore
    @Environment(\.mealPlanning) private var mealPlanning
    @Environment(\.kitchen) private var kitchen
    @Environment(\.cookingStreak) private var cookingStreak
    @Environment(\.badges) private var badges
    @Environment(\.scenePhase) private var scenePhase

    /// Pushes the recipe with cooking mode already up, so finishing lands on its detail (Made it, rating).
    private struct CookRoute: Hashable { let recipeID: UUID }
    /// A day whose dinner is being picked from the week strip.
    /// A meal being picked from the day strip or the week strip.
    private struct PlanningDay: Identifiable {
        let date: Date
        var mealTime: MealTime = .dinner
        var id: String { "\(date.timeIntervalSinceReferenceDate)-\(mealTime.rawValue)" }
    }

    @State private var path = NavigationPath()
    // Computed on data change, not in body (matching ingredients across every recipe isn't free).
    @State private var snapshot: TodaySnapshot?
    @State private var showsCookingSheet = false
    @State private var planningDay: PlanningDay?
    /// Picked in the sheet, planned once it has closed (a badge sheet can't show over one mid-dismissal).
    @State private var pendingPlan: (recipe: RecipeModel, date: Date, mealTime: MealTime)?
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
    /// Recipes' Discover | My recipes toggle; "Keep browsing →" flips it to Discover before switching tab.
    @AppStorage(RecipeBrowse.modeKey) private var recipesMode: RecipeBrowse.Mode = RecipeBrowse.defaultMode
    @AppStorage(RecipeBrowse.discoverRequestKey) private var discoverRequests = 0

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
        .task { await refreshOnMealBoundaries() }
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
            RecipeSelectionSheet(mealTime: day.mealTime) { recipe in
                pendingPlan = (recipe, day.date, day.mealTime)
                planningDay = nil
            }
        }
        .sheet(isPresented: $showsCookingSheet) { CookingSheet(streak: cookingStreak.streak) }
        .onChange(of: recipeStore.recipes) { _, _ in refresh() }
        .onChange(of: cookingStreak.streak) { _, _ in refresh() }
        .onChange(of: kitchen.items) { _, _ in refresh() }
        .onChange(of: kitchen.inventoryItems) { _, _ in refresh() }
        .onChange(of: storedEatAt) { _, _ in refresh() }
    }

    /// The next meal moves with the clock (11am, 4pm, late evening, midnight), so an app left open rebuilds when it
    /// does — otherwise the strip could plan "today" for yesterday after midnight.
    private func refreshOnMealBoundaries() async {
        let phase = { TodayFeed.NextMeal.clockPhase(
            at: Self.now(), eatAt: TonightTiming.eatAt(stored: storedEatAt), calendar: .current
        ) }
        var last = phase()
        while !Task.isCancelled {
            do { try await Task.sleep(for: .seconds(60)) } catch { return }
            let current = phase()
            if current != last {
                last = current
                refresh()
            }
        }
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
            eatAt: TonightTiming.eatAt(stored: storedEatAt),
            now: now
        )
    }

    /// Plans the meal unless one appeared since the strip was built (another path, a recurring copy) — never replaces it.
    private func planMeal(_ recipe: RecipeModel, on date: Date, mealTime: MealTime = .dinner) {
        guard mealPlanning.mealPlan(for: date, mealTime: mealTime) == nil else {
            refresh()
            return
        }
        mealPlanning.addMealPlan(MealPlanModel(
            recipeId: recipe.id, recipeName: recipe.name, date: date, mealTime: mealTime, servings: recipe.currentServings
        ))
        HapticManager.shared.success()
        refresh()
    }

    private func planPicked() {
        guard let pendingPlan else { return }
        self.pendingPlan = nil
        planMeal(pendingPlan.recipe, on: pendingPlan.date, mealTime: pendingPlan.mealTime)
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
        let forDinner = feed.nextMeal.isTonight
        if let hero = shown {
            TodayHeroCard(
                hero: hero,
                title: feed.title(for: hero),
                caption: feed.caption(for: hero),
                timing: TonightTiming.line(
                    hero: hero, minuteOfDay: TonightTiming.minuteOfDay(Self.now()),
                    eatAt: TonightTiming.eatAt(stored: storedEatAt), forDinner: forDinner
                ),
                asksEatTime: TonightTiming.asksEatTime(for: hero, forDinner: forDinner),
                eatAt: Binding(
                    get: { TonightTiming.eatAt(stored: storedEatAt) },
                    set: { storedEatAt = $0 }
                ),
                onShuffle: feed.tonightOptions.count > 1 ? { shuffle(feed, from: hero) } : nil,
                onOpen: { open(hero.recipe) },
                onCook: { cook(hero.recipe) }
            )
            TodayKeepBrowsingRow(onBrowse: browse)
            if snapshot.week.hasOpenDinner, !recipeStore.recipes.isEmpty {
                TodayPlanWeekRow(onPlan: onPlanWeek)
            }
        } else if !feed.isNewUser {
            TodayShortcutCard(
                tab: .plan, title: "Plan tonight", subtitle: "Pick something for dinner and it shows up here.",
                color: .blue, onOpen: onOpen
            )
            // No pick tonight (slow or untimed recipes, nothing planned): Discover is where the recipes are.
            TodayKeepBrowsingRow(lead: "Looking for ideas?", onBrowse: browse)
        }

        // A new user's Today stays on adding a first recipe + Starters; the strip arrives with their own recipes or a plan.
        if !feed.isNewUser || snapshot.day.meals.contains(where: { $0.recipeID != nil }) {
            TodayDayStripCard(
                strip: snapshot.day,
                onPlan: { time in planningDay = PlanningDay(date: snapshot.day.date, mealTime: time) },
                onOpen: openRecipe
            )
        }

        ForEach(feed.prepAhead, id: \.recipe.id) { nudge in
            TodayPrepAheadRow(nudge: nudge) { open(nudge.recipe) }
        }

        if !feed.useSoon.isEmpty {
            TodayUseSoonCard(pairs: feed.useSoon, onOpen: open, onOpenKitchen: openKitchen)
        }

        let week = snapshot.week
        TodayWeekCard(
            week: week,
            // With no recipes yet there's nothing to pick, so an empty day leads to adding one.
            onPlanDay: { date in
                if recipeStore.recipes.isEmpty { onAddRecipe() } else { planningDay = PlanningDay(date: date) }
            },
            onPlanTomorrow: { recipe in
                if let tomorrow = week.tomorrow { planMeal(recipe, on: tomorrow) }
            },
            onOpenPlan: { onOpen(.plan) }
        )

        TodayProgressCard(progress: snapshot.progress, onOpen: { showsCookingSheet = true }, onOpenBadges: onOpenBadges)

        if feed.isNewUser, !feed.starters.isEmpty {
            TodayShelf(title: "Starters to try", id: "starters",
                       items: feed.starters.map { ($0, $0.hasTotalTime ? $0.totalTime : nil) }, onOpen: open)
        }
    }

    private func shuffle(_ feed: TodayFeed, from current: TodayFeed.Hero) {
        HapticManager.shared.light()
        withAnimation(.easeInOut(duration: 0.25)) {
            tonightRecipeID = feed.nextTonightPick(after: current.recipe.id)?.recipe.id
        }
    }

    private func browse() {
        recipesMode = .discover
        discoverRequests &+= 1
        onOpen(.recipes)
    }

    private func open(_ recipe: RecipeModel) { openRecipe(recipe.id) }

    private func openRecipe(_ id: UUID) {
        HapticManager.shared.light()
        path.append(id)
    }

    /// The tab root stores the side and switches tab, as it does for an expiry reminder.
    private func openKitchen() {
        HapticManager.shared.light()
        NotificationCenter.default.post(name: .openGroceries, object: nil, userInfo: GroceriesMode.openRequest(for: .atHome))
    }

    private func cook(_ recipe: RecipeModel) {
        HapticManager.shared.light()
        path.append(CookRoute(recipeID: recipe.id))
    }
}

#Preview {
    TodayView(onOpen: { _ in }, onOpenBadges: { _ in }, onAddRecipe: {}, onImportLink: { _ in })
}
