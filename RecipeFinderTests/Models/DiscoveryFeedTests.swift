import Testing
import Foundation
@testable import RecipeFinder

/// Recipes tab endless discovery: chapter ranking (`DiscoveryPool`) and no-repeat, never-ending paging (`DiscoveryPager`).
@Suite struct DiscoveryFeedTests {

    private let cal = Calendar.current
    private let now = Date()

    private func daysAgo(_ n: Int) -> Date {
        cal.date(byAdding: .day, value: -n, to: now) ?? now
    }

    private func recipe(
        _ name: String,
        ingredients: [String] = [],
        category: String = "Main",
        prepTime: String = "20 min",
        cookingTime: String = "40 min",
        cookCount: Int = 0,
        lastCookedAt: Date? = nil,
        isFavorite: Bool = false,
        rating: Int = 0,
        cuisine: String? = nil
    ) -> RecipeModel {
        RecipeModel(
            name: name, category: category, difficulty: "Basic", prepTime: prepTime,
            cookingTime: cookingTime, baseServings: 2,
            ingredients: ingredients.map { Ingredient(baseQuantity: 1, unit: "", name: $0) },
            prePrepInstructions: [], instructions: ["Cook"], notes: "",
            isFavorite: isFavorite, cookCount: cookCount, lastCookedAt: lastCookedAt, rating: rating, cuisine: cuisine
        )
    }

    /// A letters-only word unique to `n` (`keyWords` splits on non-letters, so "thing1" would collapse to "thing").
    private func word(_ n: Int) -> String {
        let letters = Array("abcdefghijklmnopqrstuvwxyz")
        var n = n, result = "zz"
        repeat { result.append(letters[n % 26]); n /= 26 } while n > 0
        return result + "qq"
    }

    /// `count` plain recipes across a few categories, each with its own ingredients (nothing similar to anything).
    private func library(_ count: Int) -> [RecipeModel] {
        let categories = ["Main", "Dessert", "Side", "Soup"]
        return (0..<count).map { i in
            recipe(String(format: "Recipe %03d", i),
                   ingredients: [word(i * 2), word(i * 2 + 1)],
                   category: categories[i % categories.count])
        }
    }

    private func pool(_ recipes: [RecipeModel], kitchen: [String] = []) -> DiscoveryPool {
        DiscoveryPool.make(recipes: recipes, kitchenItemNames: kitchen, now: now, calendar: cal)
    }

    private func source(_ kind: DiscoveryChapter.Kind, in pool: DiscoveryPool) -> [String]? {
        pool.sources.first { $0.kind == kind }?.candidates.map(\.name)
    }

    // MARK: Ranking

    @Test func becauseYouLovedFindsRecipesSharingIngredients() {
        let loved = recipe("Chicken curry", ingredients: ["chicken thighs", "coconut milk", "garam masala"],
                           isFavorite: true)
        let close = recipe("Chicken korma", ingredients: ["chicken thighs", "coconut milk", "almonds"])
        let closer = recipe("Coconut chicken", ingredients: ["chicken thighs", "coconut milk", "garam masala"])
        let unrelated = recipe("Lemon tart", ingredients: ["lemons", "pastry case"], category: "Dessert")
        let result = pool([loved, close, closer, unrelated])
        #expect(source(.becauseYouLoved("Chicken curry"), in: result) == ["Coconut chicken", "Chicken korma"])
    }

    @Test func staplesAloneDoNotMakeRecipesSimilar() {
        let loved = recipe("Soup", ingredients: ["salt", "black pepper", "olive oil", "leeks"], isFavorite: true)
        let other = recipe("Cake", ingredients: ["salt", "black pepper", "olive oil", "eggs"])
        #expect(source(.becauseYouLoved("Soup"), in: pool([loved, other])) == nil)
    }

    @Test func lovedAnchorsAreFavouritesThenRatedThenCookedOften() {
        let fav = recipe("Fav", isFavorite: true)
        let rated = recipe("Rated", rating: 5)
        let cooked = recipe("Cooked", cookCount: 3, lastCookedAt: daysAgo(2))
        let once = recipe("Once", cookCount: 1, lastCookedAt: daysAgo(2))
        let lowRated = recipe("Low", rating: 3)
        #expect(DiscoveryPool.lovedAnchors([once, cooked, lowRated, rated, fav]).map(\.name) == ["Fav", "Rated", "Cooked"])
    }

    @Test func quickHoldsOnlyRecipesReadyInThirtyMinutes() {
        let fast = recipe("Fast", prepTime: "5 min", cookingTime: "10 min")
        let edge = recipe("Edge", prepTime: "10 min", cookingTime: "20 min")
        let slow = recipe("Slow", prepTime: "10 min", cookingTime: "25 min")
        let untimed = recipe("Untimed", prepTime: "", cookingTime: "")
        #expect(Set(source(.quick, in: pool([fast, edge, slow, untimed])) ?? []) == ["Fast", "Edge"])
    }

    @Test func usesWhatYouHaveFollowsTheKitchen() {
        let match = recipe("Omelette", ingredients: ["eggs", "cheese"])
        let miss = recipe("Stew", ingredients: ["beef", "carrots", "stock"])
        #expect(source(.usesWhatYouHave, in: pool([match, miss], kitchen: ["eggs", "cheese"])) == ["Omelette"])
        #expect(source(.usesWhatYouHave, in: pool([match, miss])) == nil)
    }

    @Test func cookAgainPutsRecentCooksFirstThenOldLoves() {
        let recent = recipe("Recent", cookCount: 1, lastCookedAt: daysAgo(1))
        let lastWeek = recipe("Last week", cookCount: 1, lastCookedAt: daysAgo(7))
        let oldLove = recipe("Old love", cookCount: 4, lastCookedAt: daysAgo(60), isFavorite: true)
        let never = recipe("Never")
        #expect(source(.cookAgain, in: pool([oldLove, never, lastWeek, recent])) == ["Recent", "Last week", "Old love"])
    }

    @Test func newToYouHoldsOnlyUncookedRecipes() {
        let cooked = recipe("Cooked", cookCount: 1, lastCookedAt: daysAgo(3))
        let fresh = recipe("Fresh")
        #expect(source(.newToYou, in: pool([cooked, fresh])) == ["Fresh"])
    }

    @Test func cuisineAndCategoryChaptersNeedTwoRecipes() {
        let recipes = [
            recipe("Pasta", cuisine: "Italian"), recipe("Risotto", cuisine: "italian"),
            recipe("Tacos", cuisine: "Mexican"),
            recipe("Brownie", category: "Dessert"), recipe("Tart", category: "Dessert"),
            recipe("Lemonade", category: "Drink")
        ]
        let result = pool(recipes)
        #expect(Set(source(.cuisine("Italian"), in: result) ?? []) == ["Pasta", "Risotto"])
        #expect(source(.cuisine("Mexican"), in: result) == nil)
        #expect(Set(source(.category("Dessert"), in: result) ?? []) == ["Brownie", "Tart"])
        #expect(source(.category("Drink"), in: result) == nil)
    }

    @Test(arguments: [("Italian", "A trip to Italy"), ("thai", "A trip to Thailand"), ("Fusion", "A taste of Fusion")])
    func cuisineChaptersAreTitledAsATrip(cuisine: String, title: String) {
        #expect(DiscoveryChapter.tripTitle(cuisine) == title)
    }

    @Test func aCookWithFavouritesOpensOnBecauseYouLoved() {
        var recipes = library(20)
        recipes.append(recipe("Loved", ingredients: [word(2), word(3)], isFavorite: true))
        #expect(pool(recipes).sources.first?.kind == .becauseYouLoved("Loved"))
    }

    @Test func aNewCookOpensOnQuickRecipes() {
        let recipes = (0..<6).map { recipe("Quick \($0)", prepTime: "5 min", cookingTime: "5 min") }
        #expect(pool(recipes).sources.first?.kind == .quick)
    }

    @Test func recentlyCookedIsNewestFirstAndCapped() {
        let recipes = (0..<8).map { recipe("R\($0)", cookCount: 1, lastCookedAt: daysAgo($0)) } + [recipe("Never")]
        #expect(DiscoveryPool.recentlyCooked(recipes).map(\.name) == ["R0", "R1", "R2", "R3", "R4"])
        #expect(DiscoveryPool.recentlyCooked([recipe("Never")]).isEmpty)
    }

    // MARK: Paging

    @Test func noRecipeRepeatsUntilThePoolIsSpent() {
        var pager = DiscoveryPager(pool: pool(library(60)), seed: 7)
        var seen = Set<UUID>()
        while pager.cycle == 0 {
            let chapters = pager.next(1)
            guard let chapter = chapters.first else { Issue.record("Feed ended"); return }
            if pager.cycle > 0 { break }
            for recipe in chapter.recipes {
                #expect(seen.insert(recipe.id).inserted, "\(recipe.name) repeated before the pool was spent")
            }
        }
        // A chapter needs two fresh recipes, so at most one can be left for the next cycle.
        #expect(seen.count >= 59, "Every recipe should be dealt before the reshuffle")
    }

    @Test func theScrollNeverEnds() {
        var pager = DiscoveryPager(pool: pool(library(30)), seed: 1)
        let chapters = pager.next(200)
        #expect(chapters.count == 200)
        #expect(pager.cycle > 1)
        #expect(Set(chapters.map(\.id)).count == 200, "Chapter ids must stay unique across reshuffles")
    }

    @Test func noRecipeShowsInTwoChaptersInARow() {
        var pager = DiscoveryPager(pool: pool(library(12)), seed: 3)
        let chapters = pager.next(100)
        for (previous, next) in zip(chapters, chapters.dropFirst()) {
            #expect(Set(previous.recipes.map(\.id)).isDisjoint(with: next.recipes.map(\.id)))
        }
    }

    @Test func layoutsRotate() {
        var pager = DiscoveryPager(pool: pool(library(200)), seed: 5)
        let layouts = pager.next(6).map(\.layout)
        #expect(layouts == [.feature, .wall, .row, .feature, .wall, .row])
    }

    @Test func aReshuffleChangesTheChapterOrder() {
        var pager = DiscoveryPager(pool: pool(library(40)), seed: 11)
        var byCycle: [Int: [DiscoveryChapter.Kind]] = [:]
        for _ in 0..<120 {
            guard let chapter = pager.next(1).first else { break }
            byCycle[pager.cycle, default: []].append(chapter.kind)
        }
        // Compare kinds, not recipes: recipe order reshuffles every cycle anyway, so only kinds prove the chapter
        // order itself changed.
        let orders = (0..<4).compactMap { byCycle[$0] }
        #expect(orders.count == 4)
        #expect(Set(orders.map { $0.map(\.hashValue) }).count > 1)
    }

    @Test func recipesAlreadyOnScreenWaitForTheNextCycle() {
        let recipes = library(40)
        let shown = Set(recipes.prefix(10).map(\.id))
        var pager = DiscoveryPager(pool: pool(recipes), seed: 4, alreadyShown: shown)
        var dealt: [UUID] = []
        while pager.cycle == 0, let chapter = pager.next(1).first, pager.cycle == 0 {
            dealt += chapter.recipes.map(\.id)
        }
        #expect(Set(dealt).isDisjoint(with: shown))
        #expect(Set(dealt).count >= 29)
    }

    @MainActor @Test func cookAgainDoesNotRepeatTheRecentlyCookedRow() {
        var recipes = library(30)
        for i in 0..<5 {
            recipes[i].cookCount = 1
            recipes[i].lastCookedAt = daysAgo(i + 1)
        }
        let row = DiscoveryPool.recentlyCooked(recipes)
        let feed = DiscoveryFeedModel(seed: 8, now: { now })
        feed.update(recipes: recipes, kitchenItemNames: [], alreadyShown: Set(row.map(\.id)))
        let firstPage = feed.chapters.flatMap(\.recipes).map(\.id)
        #expect(Set(firstPage).isDisjoint(with: row.map(\.id)))
    }

    @Test func theSameSeedDealsTheSameFeed() {
        let shared = pool(library(50))
        var a = DiscoveryPager(pool: shared, seed: 42), b = DiscoveryPager(pool: shared, seed: 42)
        var c = DiscoveryPager(pool: shared, seed: 43)
        let first = a.next(10)
        #expect(first == b.next(10))
        #expect(first.map(\.recipes) != c.next(10).map(\.recipes))
    }

    @Test func unrelatedRecipesAreNotSimilar() {
        var recipes = library(20)
        recipes.append(recipe("Loved", ingredients: [word(900), word(901)], isFavorite: true))
        #expect(source(.becauseYouLoved("Loved"), in: pool(recipes)) == nil)
    }

    @Test(arguments: [2, 3, 7])
    func aLibraryOneChapterCanHoldStillNeverEnds(count: Int) {
        var pager = DiscoveryPager(pool: pool(library(count)), seed: 1)
        #expect(pager.next(20).count == 20)
    }

    @Test func aTwoRecipeChapterIsASwipeRow() {
        var pager = DiscoveryPager(pool: pool(library(2)), seed: 1)
        #expect(pager.next(1).first?.layout == .row)
    }

    @Test func anEditedRecipeIsDealtWithItsNewName() {
        var recipes = library(40)
        var pager = DiscoveryPager(pool: pool(recipes), seed: 6)
        let target = recipes[39]
        recipes[39] = RecipeModel(
            id: target.id, name: "Renamed", category: target.category, difficulty: "Basic", prepTime: "20 min",
            cookingTime: "40 min", baseServings: 2, ingredients: target.ingredients, prePrepInstructions: [],
            instructions: ["Cook"], notes: ""
        )
        pager.replacePool(pool(recipes))
        let names = pager.next(60).flatMap(\.recipes).filter { $0.id == target.id }.map(\.name)
        #expect(!names.isEmpty)
        #expect(names.allSatisfy { $0 == "Renamed" })
    }

    @Test(arguments: [0, 1])
    func aLibraryTooSmallForAChapterShowsNone(count: Int) {
        var pager = DiscoveryPager(pool: pool(library(count)), seed: 1)
        #expect(pager.next(5).isEmpty)
    }

    @Test func aLibraryChangeCarriesOnWithoutRepeats() {
        var recipes = library(40)
        var pager = DiscoveryPager(pool: pool(recipes), seed: 9)
        let before = pager.next(3).flatMap(\.recipes).map(\.id)
        recipes.append(recipe("Brand new"))
        pager.replacePool(pool(recipes))
        let after = pager.next(3).flatMap(\.recipes).map(\.id)
        #expect(pager.cycle == 0)
        #expect(Set(before).isDisjoint(with: after))
    }

    @Test func aRefreshedChapterDropsDeletedRecipesAndKeepsEdits() {
        let a = recipe("A"), b = recipe("B")
        let chapter = DiscoveryChapter(id: 0, kind: .newToYou, layout: .row, recipes: [a, b])
        var edited = a
        edited.isFavorite = true
        #expect(chapter.refreshed(with: [a.id: edited])?.recipes == [edited])
        #expect(chapter.refreshed(with: [:]) == nil)
    }

    // MARK: Browsing the Recipes home

    @Test func browsingIsNothingTypedFilteredOrResorted() {
        #expect(RecipeBrowse.isBrowsing(RecipeFilterCriteria()))
        var typed = RecipeFilterCriteria(); typed.searchText = "soup"
        var spaces = RecipeFilterCriteria(); spaces.searchText = "  "
        var filtered = RecipeFilterCriteria(); filtered.showFavoritesOnly = true
        var sorted = RecipeFilterCriteria(); sorted.sortOrder = .mostCooked
        #expect(!RecipeBrowse.isBrowsing(typed))
        #expect(RecipeBrowse.isBrowsing(spaces))
        #expect(!RecipeBrowse.isBrowsing(filtered))
        #expect(!RecipeBrowse.isBrowsing(sorted))
    }

    @Test func thePreviewLeadsWithTheCooksOwnRecipesAndFavourites() {
        var samples = library(10).map { r -> RecipeModel in var r = r; r.isSampleRecipe = true; return r }
        samples[7].isFavorite = true
        let own = recipe("Zebra cake")
        let preview = RecipeBrowse.preview(samples + [own])
        #expect(preview.count == RecipeBrowse.previewLimit)
        #expect(preview.prefix(2).map(\.name) == [samples[7].name, "Zebra cake"])
        #expect(preview.dropFirst(2).map(\.name) == samples.prefix(4).map(\.name))
    }

    @Test func aSmallLibraryShowsNoChapters() {
        #expect(!RecipeBrowse.showsDiscovery(libraryCount: RecipeBrowse.previewLimit))
        #expect(RecipeBrowse.showsDiscovery(libraryCount: RecipeBrowse.previewLimit + 1))
    }

    // MARK: Feed model

    @MainActor @Test func theFeedDealsAFirstPageThenMoreNearTheEnd() {
        let feed = DiscoveryFeedModel(seed: 2, now: { now })
        feed.update(recipes: library(80), kitchenItemNames: [])
        #expect(feed.chapters.count == DiscoveryFeedModel.firstPage)
        if let first = feed.chapters.first { feed.chapterAppeared(first) }
        #expect(feed.chapters.count == DiscoveryFeedModel.firstPage, "Early chapters shouldn't page")
        if let last = feed.chapters.last { feed.chapterAppeared(last) }
        #expect(feed.chapters.count == DiscoveryFeedModel.firstPage + DiscoveryFeedModel.pageSize)
    }

    @MainActor @Test func aLibraryChangeKeepsTheChaptersOnScreen() {
        var recipes = library(80)
        let feed = DiscoveryFeedModel(seed: 2, now: { now })
        feed.update(recipes: recipes, kitchenItemNames: [])
        let before = feed.chapters.map(\.id)
        guard let shown = feed.chapters.first?.recipes.first else { Issue.record("No chapters"); return }
        recipes.removeAll { $0.id == shown.id }
        feed.update(recipes: recipes, kitchenItemNames: [])
        #expect(feed.chapters.map(\.id) == before)
        #expect(!feed.chapters.flatMap(\.recipes).contains { $0.id == shown.id })
    }
}
