import Testing
import Foundation
@testable import RecipeFinder

/// Plan — swipe to match: the "Plan my week" deck's fill rules (quick weeknights, weekend cooks, variety, expiring
/// items), no-repeat dealing and the ♥ / ✕ / skip-night paths. Seeded, fixed calendar.
@Suite struct PlanDeckTests {

    private let cal: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current
        return cal
    }()

    /// Monday 16 Nov 2026 + `offset` days (Sat = 5, Sun = 6).
    private func day(_ offset: Int) -> Date {
        let monday = cal.date(from: DateComponents(year: 2026, month: 11, day: 16)) ?? Date()
        return cal.date(byAdding: .day, value: offset, to: monday) ?? monday
    }

    private func recipe(
        _ name: String,
        minutes: Int = 25,
        category: String = "Main",
        ingredients: [String] = [],
        isFavorite: Bool = false,
        rating: Int = 0,
        cuisine: String? = nil
    ) -> RecipeModel {
        RecipeModel(
            name: name, category: category, difficulty: "Basic", prepTime: "0 min",
            cookingTime: "\(minutes) min", baseServings: 2,
            ingredients: ingredients.map { Ingredient(baseQuantity: 1, unit: "", name: $0) },
            prePrepInstructions: [], instructions: ["Cook"], notes: "",
            isFavorite: isFavorite, rating: rating, cuisine: cuisine
        )
    }

    private func plan(_ recipe: RecipeModel, on date: Date, _ mealTime: MealTime = .dinner) -> MealPlanModel {
        MealPlanModel(recipeId: recipe.id, recipeName: recipe.name, date: date, mealTime: mealTime)
    }

    private func makeDeck(
        days: [Date], recipes: [RecipeModel], planned: [MealPlanModel] = [], expiring: [String] = [], seed: UInt64 = 7,
        today: Date? = nil
    ) -> PlanDeck {
        PlanDeck(days: days, recipes: recipes, plannedThisWeek: planned, expiringItemNames: expiring,
                 seed: seed, today: today ?? day(0), calendar: cal)
    }

    // MARK: - Empty dinners

    @Test func emptyDinnerDaysStartTodayAndSkipPlannedDinners() {
        let week = (0..<7).map(day)
        let pasta = recipe("Pasta")
        let plans = [plan(pasta, on: day(3)), plan(pasta, on: day(4), .lunch)]
        let empty = PlanDeck.emptyDinnerDays(week: week, plans: plans, today: day(2), calendar: cal)
        #expect(empty == [day(2), day(4), day(5), day(6)])
    }

    @Test func pastWeekHasNoEmptyDinners() {
        let week = (0..<7).map(day)
        #expect(PlanDeck.emptyDinnerDays(week: week, plans: [], today: day(9), calendar: cal).isEmpty)
    }

    // MARK: - Fill rules

    @Test func weeknightDealsTheQuickDish() {
        let slow = recipe("Slow braise", minutes: 180)
        let quick = recipe("Stir fry", minutes: 20)
        #expect(makeDeck(days: [day(1)], recipes: [slow, quick]).current?.recipe.name == "Stir fry")
    }

    @Test func weekendDealsTheLongerCook() {
        let slow = recipe("Slow braise", minutes: 180)
        let quick = recipe("Stir fry", minutes: 20)
        #expect(makeDeck(days: [day(5)], recipes: [slow, quick]).current?.recipe.name == "Slow braise")
    }

    @Test func expiringItemsComeFirstAndSayWhy() {
        let plain = recipe("Stir fry", minutes: 20)
        let useUp = recipe("Spinach curry", minutes: 25, ingredients: ["spinach", "rice"])
        let card = makeDeck(days: [day(1)], recipes: [plain, useUp], expiring: ["Spinach"]).current
        #expect(card?.recipe.name == "Spinach curry")
        #expect(card?.reason == "Uses your spinach while it's fresh")
    }

    @Test func noCuisineTwoNightsRunning() {
        let monday = recipe("Lasagne", cuisine: "Italian")
        let risotto = recipe("Risotto", isFavorite: true, cuisine: "Italian")
        let tacos = recipe("Tacos", cuisine: "Mexican")
        let card = makeDeck(days: [day(1)], recipes: [monday, risotto, tacos], planned: [plan(monday, on: day(0))]).current
        #expect(card?.recipe.name == "Tacos")
    }

    @Test func varietyAlsoCountsTheNightJustPicked() {
        let risotto = recipe("Risotto", isFavorite: true, cuisine: "Italian")
        let pizza = recipe("Pizza", isFavorite: true, cuisine: "Italian")
        let tacos = recipe("Tacos", cuisine: "Mexican")
        var deck = makeDeck(days: [day(1), day(2)], recipes: [risotto, pizza, tacos])
        let first = deck.current?.recipe.cuisine
        deck.plan()
        #expect(first == "Italian")
        #expect(deck.current?.recipe.name == "Tacos")
    }

    @Test func favouritesAndRatingsBreakTies() {
        let plain = recipe("Plain")
        let loved = recipe("Loved", rating: 5)
        #expect(makeDeck(days: [day(1)], recipes: [plain, loved]).current?.recipe.name == "Loved")
    }

    @Test func dinnersAreMainsAndSoups() {
        let cake = recipe("Cake", minutes: 20, category: "Dessert", isFavorite: true)
        let soup = recipe("Soup", minutes: 60, category: "Soup")
        #expect(makeDeck(days: [day(1)], recipes: [cake, soup]).current?.recipe.name == "Soup")
    }

    @Test func libraryWithNoMainsStillDeals() {
        let cake = recipe("Cake", category: "Dessert")
        #expect(makeDeck(days: [day(1)], recipes: [cake]).current?.recipe.name == "Cake")
    }

    @Test func longCooksWaitBehindUntimedOnesOnWeeknights() {
        let slow = recipe("Slow braise", minutes: 180, rating: 5)
        let untimed = recipe("Untimed", minutes: 0)
        #expect(makeDeck(days: [day(1)], recipes: [slow, untimed]).current?.recipe.name == "Untimed")
    }

    @Test(arguments: [UInt64(1), 2, 3, 4, 5])
    func weekendsPreferTheLongerCookWhateverTheSeed(seed: UInt64) {
        let dishes = [recipe("Slow braise", minutes: 180), recipe("Stir fry", minutes: 20)]
        #expect(makeDeck(days: [day(5)], recipes: dishes, seed: seed).current?.recipe.name == "Slow braise")
    }

    @Test func varietyLooksAtTheNightAfterToo() {
        let tuesday = recipe("Lasagne", cuisine: "Italian")
        let risotto = recipe("Risotto", isFavorite: true, cuisine: "Italian")
        let tacos = recipe("Tacos", cuisine: "Mexican")
        let card = makeDeck(days: [day(0)], recipes: [tuesday, risotto, tacos],
                            planned: [plan(tuesday, on: day(1))]).current
        #expect(card?.recipe.name == "Tacos")
    }

    @Test func expiringItemsCountUpToTwo() {
        let three = recipe("Three", ingredients: ["spinach", "leeks", "mushrooms"])
        let two = recipe("Two", ingredients: ["spinach", "leeks"], isFavorite: true)
        let card = makeDeck(days: [day(1)], recipes: [three, two], expiring: ["Spinach", "Leeks", "Mushrooms"]).current
        #expect(card?.recipe.name == "Two")
    }

    @Test func favouritesComeFirst() {
        let plain = recipe("Plain")
        let loved = recipe("Loved", isFavorite: true)
        let card = makeDeck(days: [day(1)], recipes: [plain, loved]).current
        #expect(card?.recipe.name == "Loved")
    }

    @Test func untimedFavouriteSaysWhy() {
        let card = makeDeck(days: [day(1)], recipes: [recipe("Loved", minutes: 0, isFavorite: true)]).current
        #expect(card?.reason == "One of your favourites")
    }

    @Test func untimedDishOfACuisineSaysWhy() {
        let card = makeDeck(days: [day(1)], recipes: [recipe("Tacos", minutes: 0, cuisine: "Mexican")]).current
        #expect(card?.reason == "A night of Mexican food")
    }

    @Test(arguments: [
        (1, 20, "Quick for a weeknight · "),
        (5, 90, "A weekend cook · ")
    ])
    func reasonNamesTheRule(offset: Int, minutes: Int, prefix: String) {
        let card = makeDeck(days: [day(offset)], recipes: [recipe("Dish", minutes: minutes)]).current
        #expect(card?.reason == prefix + DurationFormatter.label(minutes: minutes))
    }

    // MARK: - Dealing

    @Test func planMovesToTheNextNightAndRecordsThePick() {
        let dishes = (0..<4).map { recipe("Dish \($0)") }
        var deck = makeDeck(days: [day(1), day(2)], recipes: dishes)
        let first = deck.current
        deck.plan()
        #expect(deck.picks == [PlanDeck.Pick(day: day(1), recipe: first?.recipe ?? dishes[0])])
        #expect(deck.current?.day == day(2))
        #expect(deck.position.night == 2)
        deck.plan()
        #expect(deck.isFinished)
        #expect(deck.picks.count == 2)
    }

    @Test func skipDealsAnotherDishForTheSameNight() {
        let dishes = (0..<3).map { recipe("Dish \($0)") }
        var deck = makeDeck(days: [day(1)], recipes: dishes)
        let first = deck.current?.recipe.id
        deck.skip()
        #expect(deck.current?.day == day(1))
        #expect(deck.current?.recipe.id != first)
        #expect(deck.picks.isEmpty)
    }

    @Test func noDishShowsTwiceInANightAndPicksNeverReturn() {
        let dishes = (0..<5).map { recipe("Dish \($0)") }
        var deck = makeDeck(days: (1...4).map(day), recipes: dishes)
        var shownByNight: [Date: [UUID]] = [:]
        var turns = 0
        while let card = deck.current, turns < 100 {
            shownByNight[card.day, default: []].append(card.recipe.id)
            turns += 1
            if turns.isMultiple(of: 2) { deck.plan() } else { deck.skip() }
        }
        #expect(deck.isFinished)
        #expect(shownByNight.values.allSatisfy { Set($0).count == $0.count })
        let picked = deck.picks.map(\.recipe.id)
        #expect(Set(picked).count == picked.count)
        #expect(picked.count == 4)
    }

    @Test func aPassedDishWaitsBehindFreshOnes() {
        let star = recipe("Star", rating: 5)
        var deck = makeDeck(days: [day(1), day(2)], recipes: [star, recipe("Plain A"), recipe("Plain B")])
        #expect(deck.current?.recipe.name == "Star")
        deck.skip()
        deck.plan()
        #expect(deck.current?.recipe.name.hasPrefix("Plain") == true)
    }

    @Test func dishesAlreadyPlannedThisWeekAreNotDealt() {
        let planned = recipe("Planned", rating: 5)
        let other = recipe("Other")
        let card = makeDeck(days: [day(3)], recipes: [planned, other], planned: [plan(planned, on: day(0))]).current
        #expect(card?.recipe.name == "Other")
    }

    @Test func aPassedDishComesBackOnALaterNightWhenNothingElseIsLeft() {
        var deck = makeDeck(days: [day(1), day(2)], recipes: [recipe("Only")])
        deck.skip()
        #expect(deck.current?.day == day(2))
        #expect(deck.current?.recipe.name == "Only")
        deck.skip()
        #expect(deck.isFinished)
        #expect(deck.picks.isEmpty)
    }

    @Test func skipNightKeepsItsDishForTheNextNight() {
        var deck = makeDeck(days: [day(1), day(2)], recipes: [recipe("Only")])
        deck.skipNight()
        #expect(deck.current?.day == day(2))
        #expect(deck.current?.recipe.name == "Only")
        deck.plan()
        #expect(deck.picks.map(\.day) == [day(2)])
    }

    @Test func emptyLibraryOrWeekIsFinishedAtOnce() {
        #expect(makeDeck(days: [day(1)], recipes: []).isFinished)
        #expect(makeDeck(days: [], recipes: [recipe("Dish")]).isFinished)
    }

    @Test func sameSeedDealsTheSameDeck() {
        let dishes = (0..<20).map { recipe("Dish \($0)") }
        let order = { (seed: UInt64) -> [UUID] in
            var deck = makeDeck(days: (0..<7).map(day), recipes: dishes, seed: seed)
            var ids: [UUID] = []
            while let card = deck.current { ids.append(card.recipe.id); deck.plan() }
            return ids
        }
        #expect(order(42) == order(42))
        #expect(order(42).count == 7)
        #expect(order(1) != order(2))
    }

    // MARK: - Closing card

    @Test func finishedCopyCountsThePlannedDinners() {
        var deck = makeDeck(days: [day(1), day(2)], recipes: (0..<3).map { recipe("Dish \($0)") })
        deck.plan()
        deck.skipNight()
        #expect(deck.finishedCopy.title == "1 dinner planned")
        deck = makeDeck(days: [day(1), day(2)], recipes: (0..<3).map { recipe("Dish \($0)") })
        deck.plan()
        deck.plan()
        #expect(deck.finishedCopy.title == "2 dinners planned")
    }

    @Test func finishedCopyForAFullWeekAndForNoPicks() {
        #expect(makeDeck(days: [], recipes: [recipe("Dish")]).finishedCopy.title == "Your week is planned")
        #expect(makeDeck(days: [day(1)], recipes: []).finishedCopy.title == "That's every dish for now")
    }

    // MARK: - Up = tonight

    @Test func upOnALaterNightPlansTheDishForTonightAndDealsAgainForThatNight() {
        let dishes = (0..<4).map { recipe("Dish \($0)") }
        var deck = makeDeck(days: [day(0), day(2)], recipes: dishes, today: day(0))
        deck.skipNight()
        let card = deck.current
        #expect(deck.canPlanTonight)
        deck.planTonight()
        #expect(deck.picks == [PlanDeck.Pick(day: day(0), recipe: card?.recipe ?? dishes[0])])
        #expect(deck.current?.day == day(2))
        #expect(deck.current?.recipe.id != card?.recipe.id)
        #expect(!deck.canPlanTonight)
    }

    @Test func upOnTonightsCardPlansItLikePlanIt() {
        let dishes = (0..<3).map { recipe("Dish \($0)") }
        var deck = makeDeck(days: [day(0), day(1)], recipes: dishes, today: day(0))
        let card = deck.current
        #expect(!deck.canPlanTonight, "Plan it already plans tonight's card — no second control.")
        deck.planTonight()
        #expect(deck.picks == [PlanDeck.Pick(day: day(0), recipe: card?.recipe ?? dishes[0])])
        #expect(deck.current?.day == day(1))
    }

    @Test func upDoesNothingWhenTonightIsAlreadyPlanned() {
        let dishes = (0..<3).map { recipe("Dish \($0)") }
        let planned = plan(dishes[0], on: day(0))
        var deck = makeDeck(days: [day(1), day(2)], recipes: dishes, planned: [planned], today: day(0))
        let card = deck.current
        #expect(!deck.canPlanTonight)
        deck.planTonight()
        #expect(deck.picks.isEmpty)
        #expect(deck.current == card)
    }

    @Test func upDoesNothingOnceTonightIsPickedInTheDeck() {
        let dishes = (0..<4).map { recipe("Dish \($0)") }
        var deck = makeDeck(days: [day(0), day(1), day(2)], recipes: dishes, today: day(0))
        deck.plan()
        #expect(!deck.canPlanTonight)
        let card = deck.current
        deck.planTonight()
        #expect(deck.picks.count == 1)
        #expect(deck.current == card)
    }

    @Test func upWhenTheLastDishGoesToTonightFinishesTheDeck() {
        var deck = makeDeck(days: [day(0), day(3)], recipes: [recipe("Only")], today: day(0))
        deck.skipNight()
        deck.planTonight()
        #expect(deck.picks.map(\.day) == [day(0)])
        #expect(deck.isFinished)
        #expect(deck.finishedCopy.title == "1 dinner planned")
    }

    @Test func aTonightPickLeadsTodaysFeed() {
        let dishes = (0..<3).map { recipe("Dish \($0)") }
        var deck = makeDeck(days: [day(0), day(2)], recipes: dishes, today: day(0))
        deck.skipNight()
        deck.planTonight()
        let pick = deck.picks.first
        let plans = deck.picks.map { plan($0.recipe, on: $0.day) }
        let evening = cal.date(byAdding: .hour, value: 18, to: day(0)) ?? day(0)
        let feed = TodayFeed.make(recipes: dishes, todaysPlans: plans, kitchenItemNames: [], now: evening, calendar: cal)
        #expect(feed.hero?.recipe.id == pick?.recipe.id)
        #expect(feed.hero?.reason == .planned(.dinner))
    }
}
