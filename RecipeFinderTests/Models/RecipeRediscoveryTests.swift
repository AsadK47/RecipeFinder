import Testing
import Foundation
@testable import RecipeFinder

/// Pure "cook it again" rediscovery pick.
@Suite struct RecipeRediscoveryTests {

    private let cal = Calendar.current
    private let now = Date()

    private func daysAgo(_ n: Int) -> Date { cal.date(byAdding: .day, value: -n, to: now)! }

    private func recipe(
        _ name: String,
        cookCount: Int = 1,
        lastCookedAt: Date?,
        isFavorite: Bool = false,
        rating: Int = 0
    ) -> RecipeModel {
        RecipeModel(
            name: name, category: "Main", difficulty: "Basic", prepTime: "5 min",
            cookingTime: "10 min", baseServings: 2,
            ingredients: [], prePrepInstructions: [], instructions: ["Cook"], notes: "",
            isFavorite: isFavorite, cookCount: cookCount, lastCookedAt: lastCookedAt, rating: rating
        )
    }

    private func pick(_ recipes: [RecipeModel]) -> RecipeModel? {
        RecipeRediscovery.pick(from: recipes, now: now, calendar: cal, thresholdDays: 21)
    }

    @Test func empty_returnsNil() {
        #expect(pick([]) == nil)
    }

    @Test func recentlyCooked_returnsNil() {
        #expect(pick([recipe("Soup", lastCookedAt: daysAgo(3))]) == nil)
    }

    @Test func neverCooked_isIgnored() {
        #expect(pick([recipe("Soup", cookCount: 0, lastCookedAt: nil)]) == nil)
    }

    @Test func staleRecipe_isReturned() throws {
        let p = try #require(pick([recipe("Lasagne", lastCookedAt: daysAgo(40))]))
        #expect(p.name == "Lasagne")
    }

    @Test func favouriteBeatsNonFavourite_whenBothStale() throws {
        let p = try #require(pick([
            recipe("Plain", lastCookedAt: daysAgo(30), isFavorite: false),
            recipe("Loved", lastCookedAt: daysAgo(25), isFavorite: true)
        ]))
        #expect(p.name == "Loved")
    }

    @Test func tieScore_oldestWins() throws {
        let p = try #require(pick([
            recipe("Newer", lastCookedAt: daysAgo(25)),
            recipe("Older", lastCookedAt: daysAgo(60))
        ]))
        #expect(p.name == "Older")
    }
}

/// The full stale list behind Today's Rediscover shelf.
@Suite struct RecipeRediscoveryRankedTests {

    @Test func ranksLovedFirstThenLongestCold() {
        let now = Date()
        func ago(_ n: Int) -> Date { Calendar.current.date(byAdding: .day, value: -n, to: now) ?? now }
        func recipe(_ name: String, last: Date, favorite: Bool = false) -> RecipeModel {
            RecipeModel(
                name: name, category: "Main", difficulty: "Basic", prepTime: "5 min",
                cookingTime: "10 min", baseServings: 2,
                ingredients: [], prePrepInstructions: [], instructions: ["Cook"], notes: "",
                isFavorite: favorite, cookCount: 1, lastCookedAt: last
            )
        }
        let fresh = recipe("Fresh", last: ago(2))
        let cold = recipe("Cold", last: ago(30))
        let colder = recipe("Colder", last: ago(90))
        let loved = recipe("Loved", last: ago(25), favorite: true)

        let ranked = RecipeRediscovery.ranked(from: [fresh, cold, colder, loved], now: now, thresholdDays: 21)
        #expect(ranked.map(\.name) == ["Loved", "Colder", "Cold"])
        #expect(RecipeRediscovery.pick(from: [fresh, cold, colder, loved], now: now, thresholdDays: 21)?.name == "Loved")
    }
}
