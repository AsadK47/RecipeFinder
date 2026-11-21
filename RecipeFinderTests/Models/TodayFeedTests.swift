import Testing
import Foundation
@testable import RecipeFinder

/// Today tab selection: Tonight hero, Shuffle, what to do now and the new-user state.
@Suite struct TodayFeedTests {

    private let cal = Calendar.current
    /// 6pm today: the next meal is tonight's dinner (Today follows the clock, so a real `Date()` made these tests
    /// depend on when CI ran — AGENT_LESSONS 15).
    private let now = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()

    private func daysAgo(_ n: Int) -> Date {
        cal.date(byAdding: .day, value: -n, to: now) ?? now
    }

    private func recipe(
        _ name: String,
        ingredients: [String] = [],
        isSample: Bool = false,
        cookCount: Int = 0,
        lastCookedAt: Date? = nil,
        isFavorite: Bool = false,
        steps: [String] = ["Cook"],
        prepTime: String = "5 min",
        category: String = "Main"
    ) -> RecipeModel {
        RecipeModel(
            name: name, category: category, difficulty: "Basic", prepTime: prepTime,
            cookingTime: "10 min", baseServings: 2,
            ingredients: ingredients.map { Ingredient(baseQuantity: 1, unit: "", name: $0) },
            prePrepInstructions: [], instructions: steps, notes: "",
            isFavorite: isFavorite, isSampleRecipe: isSample, cookCount: cookCount, lastCookedAt: lastCookedAt
        )
    }

    private func plan(_ recipe: RecipeModel, _ time: MealTime, completed: Bool = false, on date: Date? = nil) -> MealPlanModel {
        MealPlanModel(recipeId: recipe.id, recipeName: recipe.name, date: date ?? now, mealTime: time, isCompleted: completed)
    }

    private func feed(
        _ recipes: [RecipeModel],
        plans: [MealPlanModel] = [],
        kitchen: [String] = []
    ) -> TodayFeed {
        TodayFeed.make(recipes: recipes, todaysPlans: plans, kitchenItemNames: kitchen, now: now, calendar: cal)
    }

    // MARK: Hero

    @Test func plannedDinnerIsTheHero() {
        let lunch = recipe("Salad"), dinner = recipe("Curry")
        let result = feed([lunch, dinner], plans: [plan(lunch, .lunch), plan(dinner, .dinner)])
        #expect(result.hero == TodayFeed.Hero(recipe: dinner, reason: .planned(.dinner)))
    }

    @Test func withoutDinnerTheEarliestOpenPlanIsTheHero() {
        let breakfast = recipe("Porridge"), lunch = recipe("Salad")
        let result = feed([breakfast, lunch], plans: [plan(lunch, .lunch), plan(breakfast, .breakfast, completed: true)])
        #expect(result.hero == TodayFeed.Hero(recipe: lunch, reason: .planned(.lunch)))
    }

    @Test func planForADeletedRecipeIsSkipped() {
        let gone = recipe("Gone")
        let pasta = recipe("Pasta", ingredients: ["pasta", "tomato"])
        let result = feed([pasta], plans: [plan(gone, .dinner)], kitchen: ["pasta", "tomato"])
        #expect(result.hero == TodayFeed.Hero(recipe: pasta, reason: .kitchenMatch(have: 2, total: 2)))
    }

    @Test func unplannedDayUsesTheBestKitchenMatch() {
        let half = recipe("Omelette", ingredients: ["egg", "cheese", "ham", "chive"])
        let most = recipe("Toast", ingredients: ["bread", "butter", "egg"])
        let result = feed([half, most], kitchen: ["Eggs", "Bread", "Butter", "Cheese"])
        #expect(result.hero == TodayFeed.Hero(recipe: most, reason: .kitchenMatch(have: 3, total: 3)))
    }

    @Test func noPlanEmptyKitchenAndNothingQuickHasNoHero() {
        #expect(feed([recipe("Soup", ingredients: ["leek"], prepTime: "1 hr")]).hero == nil)
    }

    @Test func aReturningCookWithOnlySlowRecipesHasNoHero() {
        // Today then shows "Plan tonight" + "Looking for ideas? Keep browsing →" (it used to lean on the shelves).
        let stew = recipe("Stew", cookCount: 1, lastCookedAt: daysAgo(3), prepTime: "2 hr")
        let result = feed([stew, recipe("Roast", prepTime: "3 hr")])
        #expect(result.hero == nil)
        #expect(!result.isNewUser)
    }

    @Test func noPlanAndEmptyKitchenFallsBackToAQuickRecipe() {
        let slow = recipe("Stew", prepTime: "2 hr"), quick = recipe("Omelette")
        #expect(feed([slow, quick]).hero == TodayFeed.Hero(recipe: quick, reason: .quick(minutes: 15)))
    }

    // MARK: Shuffle

    @Test func shuffleGoesPlanThenKitchenThenQuick() {
        let curry = recipe("Curry", prepTime: "1 hr")
        let toast = recipe("Toast", ingredients: ["bread"], prepTime: "1 hr")
        let wrap = recipe("Wrap"), eggs = recipe("Eggs", isFavorite: true), salad = recipe("Salad")
        let result = feed([curry, toast, wrap, eggs, salad], plans: [plan(curry, .dinner)], kitchen: ["bread"])
        let options = result.tonightOptions
        #expect(Array(options.prefix(2)) == [
            .init(recipe: curry, reason: .planned(.dinner)),
            .init(recipe: toast, reason: .kitchenMatch(have: 1, total: 1)),
        ])
        // Quick picks rotate daily, so their order isn't fixed — only that all three follow, quick and distinct.
        let quick = options.dropFirst(2)
        #expect(quick.allSatisfy { $0.reason == .quick(minutes: 15) })
        #expect(quick.count == 3)
        #expect(Set(quick.map(\.recipe.id)) == [wrap.id, eggs.id, salad.id])
    }

    /// Owner 2026-11-17: "Shuffle only shuffles through 4 recipes?" — it was capped at hero + 3.
    @Test func shuffleOffersEverySuitablePickNotJustFour() {
        let library = (1...8).map { recipe("Dish \($0)") }
        let options = feed(library).tonightOptions
        #expect(Set(options.map(\.recipe.id)) == Set(library.map(\.id)))
    }

    @Test func shuffleStepsThroughThePicksAndWrapsRound() {
        let a = recipe("A"), b = recipe("B"), c = recipe("C", prepTime: "2 hr")
        let result = feed([a, b, c])
        let order = result.tonightOptions.map(\.recipe)
        #expect(Set(order.map(\.id)) == [a.id, b.id])
        #expect(result.nextTonightPick(after: nil)?.recipe == order[1])
        #expect(result.nextTonightPick(after: order[0].id)?.recipe == order[1])
        #expect(result.nextTonightPick(after: order[1].id)?.recipe == order[0])
    }

    @Test func theShownPickSurvivesARefreshByRecipeNotPosition() {
        let a = recipe("A"), b = recipe("B"), gone = UUID()
        let result = feed([a, b])
        #expect(result.tonightPick(showing: b.id)?.recipe == b)
        #expect(result.tonightPick(showing: gone)?.recipe == result.hero?.recipe)
        #expect(result.tonightPick(showing: nil)?.recipe == result.hero?.recipe)
    }

    @Test func otherPlansOfTheDayComeBeforeSuggestions() {
        let curry = recipe("Curry"), soup = recipe("Soup")
        let result = feed([curry, soup], plans: [plan(soup, .lunch), plan(curry, .dinner)])
        #expect(result.tonightOptions.map(\.reason) == [.planned(.dinner), .planned(.lunch)])
    }

    @Test func suggestionsNeverRepeatTheLastCooked() {
        let last = recipe("Tacos", ingredients: ["tortilla"], cookCount: 3, lastCookedAt: daysAgo(1))
        let older = recipe("Chilli", cookCount: 1, lastCookedAt: daysAgo(5))
        let result = feed([last, older], kitchen: ["tortilla"])
        #expect(result.tonightOptions.map(\.recipe) == [older])
    }

    @Test func aPlannedLastCookedRecipeStillShows() {
        let last = recipe("Tacos", cookCount: 3, lastCookedAt: daysAgo(1))
        #expect(feed([last], plans: [plan(last, .dinner)]).hero?.recipe == last)
    }

    @Test func aRecipeShowsOnceEvenWhenItIsAMatchAndQuick() {
        let toast = recipe("Toast", ingredients: ["bread"])
        let result = feed([toast], kitchen: ["bread"])
        #expect(result.tonightOptions == [.init(recipe: toast, reason: .kitchenMatch(have: 1, total: 1))])
    }

    // MARK: Meal by time of day, varied by day

    private func at(_ hour: Int, dayOffset: Int = 0) -> Date {
        let day = cal.date(byAdding: .day, value: dayOffset, to: cal.startOfDay(for: now)) ?? now
        return cal.date(byAdding: .hour, value: hour, to: day) ?? day
    }

    private func feed(_ recipes: [RecipeModel], at date: Date) -> TodayFeed {
        TodayFeed.make(recipes: recipes, todaysPlans: [], kitchenItemNames: [], now: date, calendar: cal)
    }

    @Test(arguments: [(8, "Breakfast"), (13, "Main"), (19, "Main")])
    func suggestionFitsTheMealOfTheDay(hour: Int, expected: String) {
        let library = [recipe("Pancakes", category: "Breakfast"), recipe("Stir fry", category: "Main"),
                       recipe("Brownie", category: "Dessert"), recipe("Lassi", category: "Drink"),
                       recipe("Slaw", category: "Side")]
        let options = feed(library, at: at(hour)).tonightOptions
        #expect(options.first?.recipe.category == expected)
        #expect(options.allSatisfy { !["Dessert", "Drink", "Side"].contains($0.recipe.category) })
    }

    /// Lunch once also took breakfasts, so 1pm led with Pancakes or Stir fry depending on random recipe ids.
    @Test func lunchLeadsWithAMainWhateverTheRecipeIDs() {
        for _ in 0..<20 {
            let library = [recipe("Pancakes", category: "Breakfast"), recipe("Stir fry", category: "Main")]
            #expect(feed(library, at: at(13)).hero?.recipe.category == "Main")
        }
    }

    @Test func aLunchWithOnlyBreakfastRecipesStillGetsASuggestion() {
        #expect(feed([recipe("Pancakes", category: "Breakfast")], at: at(13)).hero?.recipe.category == "Breakfast")
    }

    @Test func aMorningWithoutBreakfastRecipesStillSuggestsAMain() {
        let library = [recipe("Stir fry", category: "Main"), recipe("Brownie", category: "Dessert")]
        #expect(feed(library, at: at(8)).hero?.recipe.category == "Main")
    }

    @Test func aLibraryOfOnlyDessertsStillGetsASuggestion() {
        #expect(feed([recipe("Brownie", category: "Dessert")], at: at(19)).hero != nil)
    }

    @Test func theSuggestionChangesFromDayToDay() {
        let library = (1...12).map { recipe("Dish \($0)") }
        let heroes = (0..<10).compactMap { feed(library, at: at(19, dayOffset: $0)).hero?.recipe.id }
        #expect(heroes.count == 10)
        #expect(Set(heroes).count >= 4)
    }

    @Test func theSuggestionHoldsStillWithinAMeal() {
        let library = (1...12).map { recipe("Dish \($0)") }
        #expect(feed(library, at: at(18)).hero?.recipe == feed(library, at: at(20)).hero?.recipe)
    }

    // Late evening and the small hours look ahead to breakfast (slice 2, "late evening → tomorrow's breakfast").
    @Test(arguments: [(4, TodayFeed.MealSlot.breakfast), (5, .breakfast), (10, .breakfast), (11, .lunch), (15, .lunch),
                      (16, .dinner), (20, .dinner), (21, .breakfast), (23, .breakfast)])
    func mealSlotFollowsTheClock(hour: Int, expected: TodayFeed.MealSlot) {
        #expect(TodayFeed.MealSlot(at: at(hour), calendar: cal) == expected)
    }

    @Test func quickPicksPreferYourOwnRecipesOverSamples() {
        let sample = recipe("A sample", isSample: true), mine = recipe("Z mine")
        #expect(feed([sample, mine]).tonightOptions.map(\.recipe) == [mine, sample])
    }

    @Test func newUsersGetStartersNotQuickPicks() {
        let result = feed([recipe("A", isSample: true)])
        #expect(result.hero == nil)
        #expect(result.quickCount == 1)
    }

    @Test func newUserWithAPlanCanShuffleToQuickPicks() {
        let curry = recipe("Curry", isSample: true, prepTime: "1 hr"), eggs = recipe("Eggs", isSample: true)
        let result = feed([curry, eggs], plans: [plan(curry, .dinner)])
        #expect(result.isNewUser)
        #expect(result.tonightOptions.map(\.recipe) == [curry, eggs])
    }

    @Test func quickCountIsRecipesWithAKnownTimeUpToHalfAnHour() {
        let recipes = [recipe("Q"), recipe("Edge", prepTime: "20 min"), recipe("Slow", prepTime: "21 min"), recipe("Unknown", prepTime: "")]
        // "Unknown" still has 10 min cooking, so it counts; "Slow" is 31 min.
        #expect(feed(recipes).quickCount == 3)
    }

    @Test(arguments: [
        (TodayFeed.HeroReason.planned(.dinner), "Planned for tonight"),
        (.planned(.lunch), "Planned for lunch"),
        (.plannedTomorrow(.breakfast), "Planned for tomorrow's breakfast"),
        (.plannedTomorrow(.dinner), "Planned for tomorrow night"),
        (.kitchenMatch(have: 8, total: 10), "You have 8/10 ingredients"),
        (.quick(minutes: 25), "Ready in 25 minutes"),
    ])
    func heroCaptionSaysWhy(reason: TodayFeed.HeroReason, expected: String) {
        #expect(reason.caption == expected)
    }

    // MARK: Kitchen matches

    @Test func kitchenMatchesNeedHalfTheIngredientsBestCoverageFirst() {
        let best = recipe("Toast", ingredients: ["bread", "butter"])
        let half = recipe("Sandwich", ingredients: ["bread", "ham"])
        let tooFew = recipe("Stew", ingredients: ["bread", "beef", "carrot"])
        let matches = TodayFeed.kitchenMatches(recipes: [tooFew, half, best], kitchenItemNames: ["bread", "butter"])
        #expect(matches == [.init(recipe: best, have: 2, total: 2), .init(recipe: half, have: 1, total: 2)])
    }

    // MARK: New user

    @Test func onlyUncookedSamplesMeansNewUserWithStarters() {
        let b = recipe("B", isSample: true), a = recipe("A", isSample: true)
        let result = feed([b, a])
        #expect(result.isNewUser)
        #expect(result.starters == [a, b])
    }

    @Test func noRecipesAtAllIsANewUser() {
        #expect(feed([]).isNewUser)
    }

    @Test(arguments: [false, true])
    func ownRecipeOrACookEndsNewUser(ownRecipe: Bool) {
        let other = ownRecipe ? recipe("Mine") : recipe("Sample", isSample: true, cookCount: 1, lastCookedAt: daysAgo(2))
        let result = feed([recipe("A", isSample: true), other])
        #expect(!result.isNewUser)
        #expect(result.starters.isEmpty)
    }

    // MARK: Prep ahead

    @Test(arguments: [
        ("Marinate the chicken overnight.", "Marinate"),
        ("Cover and marinate for at least 4 hours.", "Marinate"),
        ("Soak the chickpeas overnight in cold water.", "Soak"),
        ("Defrost the pastry.", "Defrost"),
        ("Cover and leave the dough to rise for 2-3 hours.", "Prove"),
        ("Cover and refrigerate for at least 4 hours.", "Chill"),
        ("Chill until set, about 6 hours.", "Chill"),
        ("Leave in the fridge overnight.", "Prep"),
    ])
    func longLeadStepsGetACue(step: String, expected: String) {
        #expect(PrepAhead.cue(forStep: step) == expected)
    }

    @Test(arguments: [
        "Marinate for at least 15 minutes.",
        "Soak the noodles in boiling water for 10 minutes.",
        "No need to thaw the corn.",
        "Add the chillies and simmer for 2 hours.",
        "Chill for 1 hour.",
        "Cook",
    ])
    func shortOrNoWaitHasNoCue(step: String) {
        #expect(PrepAhead.cue(forStep: step) == nil)
    }

    @Test func tomorrowsOpenPlansThatNeedPrepAreNudgedInMealOrder() {
        let tomorrow = cal.date(byAdding: .day, value: 1, to: now) ?? now
        let tikka = recipe("Tikka", steps: ["Marinate the chicken overnight.", "Grill."])
        let oats = recipe("Overnight oats", steps: ["Mix and chill overnight."])
        let salad = recipe("Salad", steps: ["Toss."])
        let done = recipe("Bread", steps: ["Leave to rise overnight."])
        let nudges = PrepAhead.nudges(
            recipes: [tikka, oats, salad, done],
            tomorrowsPlans: [
                plan(tikka, .dinner, on: tomorrow), plan(oats, .breakfast, on: tomorrow),
                plan(salad, .lunch, on: tomorrow), plan(done, .snack, completed: true, on: tomorrow),
            ]
        )
        #expect(nudges == [
            PrepAheadNudge(recipe: oats, mealTime: .breakfast, cue: "Chill"),
            PrepAheadNudge(recipe: tikka, mealTime: .dinner, cue: "Marinate"),
        ])
        #expect(nudges.last?.message == "Marinate tonight for tomorrow's dinner")
    }

    @Test func tomorrowsFirstPrepIsTodaysNudge() {
        let tomorrow = cal.date(byAdding: .day, value: 1, to: now) ?? now
        let tikka = recipe("Tikka", steps: ["Marinate the chicken overnight.", "Grill."])
        let oats = recipe("Overnight oats", steps: ["Mix and chill overnight."])
        let result = TodayFeed.make(
            recipes: [tikka, oats], todaysPlans: [], kitchenItemNames: [],
            tomorrowsPlans: [plan(tikka, .dinner, on: tomorrow), plan(oats, .breakfast, on: tomorrow)],
            now: now, calendar: cal
        )
        #expect(result.nudge == .prepAhead(PrepAheadNudge(recipe: oats, mealTime: .breakfast, cue: "Chill")))
        #expect(result.nudge?.title == "Prep ahead")
        #expect(result.nudge?.linksToKitchen == false)
    }

    @Test func sameRecipeTwiceTomorrowIsNudgedOnce() {
        let beans = recipe("Beans", steps: ["Soak the beans overnight."])
        let nudges = PrepAhead.nudges(recipes: [beans], tomorrowsPlans: [plan(beans, .lunch), plan(beans, .dinner)])
        #expect(nudges == [PrepAheadNudge(recipe: beans, mealTime: .lunch, cue: "Soak")])
    }

    // MARK: Use it up

    @Test func kitchenItemsGoingOffArePairedWithARecipe() {
        let saag = recipe("Saag paneer", ingredients: ["spinach", "paneer"])
        let spinach = KitchenInventoryModel(
            name: "Spinach", category: .produce, quantity: 1, unit: "",
            expiryDate: cal.date(byAdding: .day, value: 1, to: now)
        )
        let result = TodayFeed.make(
            recipes: [saag], todaysPlans: [], kitchenItemNames: [], inventoryItems: [spinach], now: now, calendar: cal
        )
        guard case .useSoon(let pair) = result.nudge else {
            Issue.record("Spinach going off tomorrow should be Today's nudge, got \(String(describing: result.nudge))")
            return
        }
        #expect(pair.recipe == saag)
        #expect(pair.itemNames == ["Spinach"])
        #expect(result.nudge?.message == "Spinach: use by tomorrow")
        #expect(result.nudge?.linksToKitchen == true)
    }

    @Test func nothingToDoMeansNoNudge() {
        #expect(feed([recipe("Curry")]).nudge == nil)
    }

    // MARK: Do this now — one nudge

    private func prep(_ name: String) -> PrepAheadNudge {
        PrepAheadNudge(recipe: recipe(name), mealTime: .dinner, cue: "Marinate")
    }

    private func useSoon(_ item: String, daysLeft: Int) -> UseSoonPair {
        UseSoonPair(itemNames: [item], daysLeft: daysLeft, when: daysLeft == 0 ? "today" : "tomorrow", recipe: recipe(item + " dish"))
    }

    @Test func somethingGoingOffTodayBeatsTomorrowsPrep() {
        let spinach = useSoon("Spinach", daysLeft: 0)
        #expect(TodayNudge.pick(prepAhead: [prep("Tikka")], useSoon: [spinach]) == .useSoon(spinach))
    }

    @Test func tomorrowsPrepBeatsSomethingGoingOffLater() {
        let tikka = prep("Tikka")
        #expect(TodayNudge.pick(prepAhead: [tikka], useSoon: [useSoon("Lemons", daysLeft: 1)]) == .prepAhead(tikka))
    }

    @Test func onlyTheFirstOfEachKindIsShown() {
        let tikka = prep("Tikka"), lamb = prep("Lamb")
        #expect(TodayNudge.pick(prepAhead: [tikka, lamb], useSoon: []) == .prepAhead(tikka))
        let lemons = useSoon("Lemons", daysLeft: 1), feta = useSoon("Feta", daysLeft: 2)
        #expect(TodayNudge.pick(prepAhead: [], useSoon: [lemons, feta]) == .useSoon(lemons))
    }

    @Test func noPrepAndNothingGoingOffMeansNoNudge() {
        #expect(TodayNudge.pick(prepAhead: [], useSoon: []) == nil)
    }
}
