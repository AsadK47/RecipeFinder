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
        isFavorite: Bool = false
    ) -> RecipeModel {
        RecipeModel(
            name: name, category: "Main", difficulty: "Basic", prepTime: "5 min",
            cookingTime: "10 min", baseServings: 2,
            ingredients: ingredients.map { Ingredient(baseQuantity: 1, unit: "", name: $0) },
            prePrepInstructions: [], instructions: ["Cook"], notes: "",
            isFavorite: isFavorite, isSampleRecipe: isSample, cookCount: cookCount, lastCookedAt: lastCookedAt
        )
    }

    private func plan(_ recipe: RecipeModel, _ time: MealTime, completed: Bool = false) -> MealPlanModel {
        MealPlanModel(recipeId: recipe.id, recipeName: recipe.name, date: now, mealTime: time, isCompleted: completed)
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

    @Test func noPlanAndEmptyKitchenHasNoHero() {
        #expect(feed([recipe("Soup", ingredients: ["leek"])]).hero == nil)
    }

    @Test(arguments: [
        (TodayFeed.HeroReason.planned(.dinner), "Planned for tonight"),
        (.planned(.lunch), "Planned for lunch"),
        (.kitchenMatch(have: 8, total: 10), "You have 8/10 ingredients"),
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
        let older = recipe("Chilli", cookCount: 1, lastCookedAt: daysAgo(10))
        let newest = recipe("Tacos", cookCount: 2, lastCookedAt: daysAgo(1))
        let cold = recipe("Lasagne", cookCount: 3, lastCookedAt: daysAgo(40))
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
}
