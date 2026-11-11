import Testing
import Foundation
@testable import RecipeFinder

/// Today tab selection: Tonight hero, shelves and the new-user state.
@Suite struct TodayFeedTests {

    private let cal = Calendar.current
    private let now = Date()

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
        prepTime: String = "5 min"
    ) -> RecipeModel {
        RecipeModel(
            name: name, category: "Main", difficulty: "Basic", prepTime: prepTime,
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
        #expect(result.tonightOptions == [
            .init(recipe: curry, reason: .planned(.dinner)),
            .init(recipe: toast, reason: .kitchenMatch(have: 1, total: 1)),
            .init(recipe: eggs, reason: .quick(minutes: 15)),
            .init(recipe: salad, reason: .quick(minutes: 15)),
        ])
        #expect(result.alternatives.count == TodayFeed.alternativesLimit)
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
        (.kitchenMatch(have: 8, total: 10), "You have 8/10 ingredients"),
        (.quick(minutes: 25), "Ready in 25 minutes"),
    ])
    func heroCaptionSaysWhy(reason: TodayFeed.HeroReason, expected: String) {
        #expect(reason.caption == expected)
    }

    // MARK: Shelves

    @Test func kitchenShelfNeedsHalfTheIngredientsAndSkipsTheHero() {
        let best = recipe("Toast", ingredients: ["bread", "butter"])
        let half = recipe("Sandwich", ingredients: ["bread", "ham"])
        let tooFew = recipe("Stew", ingredients: ["bread", "beef", "carrot"])
        let result = feed([best, half, tooFew], kitchen: ["bread", "butter"])
        #expect(result.hero?.recipe == best)
        #expect(result.fitsYourKitchen == [.init(recipe: half, have: 1, total: 2)])
    }

    @Test func cookAgainIsRecentCooksNewestFirst() {
        // Slow recipes, so none becomes a quick Tonight pick (the hero is left off the shelves).
        let older = recipe("Chilli", cookCount: 1, lastCookedAt: daysAgo(10), prepTime: "1 hr")
        let newest = recipe("Tacos", cookCount: 2, lastCookedAt: daysAgo(1), prepTime: "1 hr")
        let cold = recipe("Lasagne", cookCount: 3, lastCookedAt: daysAgo(40), prepTime: "1 hr")
        let result = feed([older, cold, newest])
        #expect(result.cookAgain == [newest, older])
        #expect(result.rediscover == [cold])
    }

    @Test func plannedHeroIsLeftOffTheShelves() {
        let tacos = recipe("Tacos", cookCount: 2, lastCookedAt: daysAgo(1))
        let result = feed([tacos], plans: [plan(tacos, .dinner)])
        #expect(result.hero?.recipe == tacos)
        #expect(result.cookAgain.isEmpty)
    }

    @Test func shelvesAreCapped() {
        let recipes = (0..<15).map { recipe("R\($0)", cookCount: 1, lastCookedAt: daysAgo($0 % 5)) }
        #expect(feed(recipes).cookAgain.count == TodayFeed.shelfLimit)
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
        let result = TodayFeed.make(
            recipes: [tikka, oats, salad, done],
            todaysPlans: [],
            kitchenItemNames: [],
            tomorrowsPlans: [
                plan(tikka, .dinner, on: tomorrow), plan(oats, .breakfast, on: tomorrow),
                plan(salad, .lunch, on: tomorrow), plan(done, .snack, completed: true, on: tomorrow),
            ],
            now: now, calendar: cal
        )
        #expect(result.prepAhead == [
            PrepAheadNudge(recipe: oats, mealTime: .breakfast, cue: "Chill"),
            PrepAheadNudge(recipe: tikka, mealTime: .dinner, cue: "Marinate"),
        ])
        #expect(result.prepAhead.last?.message == "Marinate tonight for tomorrow's dinner")
    }

    @Test func sameRecipeTwiceTomorrowIsNudgedOnce() {
        let beans = recipe("Beans", steps: ["Soak the beans overnight."])
        let nudges = PrepAhead.nudges(recipes: [beans], tomorrowsPlans: [plan(beans, .lunch), plan(beans, .dinner)])
        #expect(nudges == [PrepAheadNudge(recipe: beans, mealTime: .lunch, cue: "Soak")])
    }
}
