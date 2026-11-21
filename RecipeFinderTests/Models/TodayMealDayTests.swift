import Testing
import Foundation
@testable import RecipeFinder

/// Today follows the clock: which meal the hero is for (late evening → tomorrow's breakfast), how plans order around
/// it, and the one-line day strip.
@Suite struct TodayMealDayTests {

    private let cal: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_GB")
        cal.timeZone = TimeZone(identifier: "Europe/London") ?? .current
        return cal
    }()

    /// Wednesday 18 Nov 2026 (mid-week, no clock change nearby), at `hour`.
    private func at(_ hour: Int, _ minute: Int = 0, dayOffset: Int = 0) -> Date {
        let day = cal.date(from: DateComponents(year: 2026, month: 11, day: 18 + dayOffset)) ?? Date()
        return cal.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    private func recipe(
        _ name: String, category: String = "Main", prepTime: String = "5 min", lastCookedAt: Date? = nil
    ) -> RecipeModel {
        RecipeModel(
            name: name, category: category, difficulty: "Basic", prepTime: prepTime, cookingTime: "10 min",
            baseServings: 2, ingredients: [], prePrepInstructions: [], instructions: ["Cook"], notes: "",
            cookCount: lastCookedAt == nil ? 0 : 1, lastCookedAt: lastCookedAt
        )
    }

    private func plan(_ recipe: RecipeModel, _ time: MealTime, dayOffset: Int = 0, done: Bool = false) -> MealPlanModel {
        MealPlanModel(
            recipeId: recipe.id, recipeName: recipe.name, date: at(12, dayOffset: dayOffset), mealTime: time,
            isCompleted: done
        )
    }

    private func feed(
        _ recipes: [RecipeModel], today: [MealPlanModel] = [], tomorrow: [MealPlanModel] = [], at now: Date
    ) -> TodayFeed {
        TodayFeed.make(
            recipes: recipes, todaysPlans: today, kitchenItemNames: [], tomorrowsPlans: tomorrow, now: now, calendar: cal
        )
    }

    private func next(
        _ date: Date, _ plans: [MealPlanModel] = [], recipes: [RecipeModel] = [], eatAt: Int = TonightTiming.defaultEatAt
    ) -> TodayFeed.NextMeal {
        .at(date, todaysPlans: plans, recipes: recipes, eatAt: eatAt, calendar: cal)
    }

    // MARK: Next meal

    static let clock: [(Int, TodayFeed.MealSlot, Bool)] = [
        (1, .breakfast, false), (8, .breakfast, false), (12, .lunch, false), (17, .dinner, false),
        (20, .dinner, false), (21, .breakfast, true), (23, .breakfast, true),
    ]

    @Test(arguments: clock)
    func theNextMealFollowsTheClock(hour: Int, slot: TodayFeed.MealSlot, isTomorrow: Bool) {
        #expect(next(at(hour)) == TodayFeed.NextMeal(slot: slot, isTomorrow: isTomorrow))
    }

    @Test func anOpenPlannedDinnerKeepsTheEveningOnTonight() {
        let curry = recipe("Curry")
        #expect(next(at(22, 30), [plan(curry, .dinner)]) == .tonight)
    }

    @Test func aCookedDinnerMovesTheEveningOnToTomorrow() {
        let curry = recipe("Curry")
        let tomorrow = TodayFeed.NextMeal(slot: .breakfast, isTomorrow: true)
        #expect(next(at(19), [plan(curry, .dinner, done: true)]) == tomorrow)
        #expect(next(at(22), [plan(curry, .dinner, done: true)]) == tomorrow)
        // Before dinner time a cooked dinner (an early one) doesn't skip lunch.
        #expect(next(at(12), [plan(curry, .dinner, done: true)]) == TodayFeed.NextMeal(slot: .lunch, isTomorrow: false))
    }

    @Test func aLaterDinnerTimeKeepsTheEveningOnTonight() {
        // Dinner at 10pm (the latest choice): tonight until 10:30, then tomorrow.
        #expect(next(at(21, 45), eatAt: 22 * 60) == .tonight)
        #expect(next(at(22, 30), eatAt: 22 * 60) == TodayFeed.NextMeal(slot: .breakfast, isTomorrow: true))
    }

    @Test func aDinnerCookedWithoutMadeItCountsAsDone() {
        // The planned recipe's last cook was today, but the plan was never ticked.
        let curry = recipe("Curry", lastCookedAt: at(19))
        #expect(next(at(21, 30), [plan(curry, .dinner)], recipes: [curry]).isTomorrow)
    }

    @Test func theClockPhaseMovesAtMealBoundariesOnly() {
        let phase = { (date: Date) in TodayFeed.NextMeal.clockPhase(at: date, eatAt: TonightTiming.defaultEatAt, calendar: cal) }
        #expect(phase(at(12)) == phase(at(15, 59)))
        #expect(phase(at(15, 59)) != phase(at(16)))
        #expect(phase(at(20, 59)) != phase(at(21)))
        #expect(phase(at(23, 59)) != phase(at(0, 0, dayOffset: 1)))
    }

    // MARK: Hero

    @Test func theHeroIsTitledByItsPlansOwnMeal() throws {
        // 8am with only dinner planned: the card (and VoiceOver) says tonight, not breakfast.
        let curry = recipe("Curry")
        let result = feed([curry], today: [plan(curry, .dinner)], at: at(8))
        let hero = try #require(result.hero)
        #expect(result.title(for: hero) == "Tonight")
        #expect(result.title(for: TodayFeed.Hero(recipe: curry, reason: .plannedTomorrow(.dinner))) == "Tomorrow night")
        #expect(result.title(for: TodayFeed.Hero(recipe: curry, reason: .quick(minutes: 15))) == "Breakfast")
    }

    @Test func aPlannedBreakfastLeadsInTheMorning() {
        let porridge = recipe("Porridge", category: "Breakfast"), curry = recipe("Curry")
        let result = feed([porridge, curry], today: [plan(curry, .dinner), plan(porridge, .breakfast)], at: at(8))
        #expect(result.tonightOptions.map(\.reason) == [.planned(.breakfast), .planned(.dinner)])
    }

    @Test func aMissedMealComesAfterTheMealsStillAhead() {
        let porridge = recipe("Porridge", category: "Breakfast"), curry = recipe("Curry")
        let result = feed([porridge, curry], today: [plan(porridge, .breakfast), plan(curry, .dinner)], at: at(13))
        #expect(result.tonightOptions.map(\.reason) == [.planned(.dinner), .planned(.breakfast)])
    }

    @Test func lateEveningLeadsWithTomorrowsPlannedBreakfast() throws {
        let porridge = recipe("Porridge", category: "Breakfast"), curry = recipe("Curry")
        let result = feed([porridge, curry], tomorrow: [plan(porridge, .breakfast, dayOffset: 1)], at: at(22))
        #expect(result.hero == TodayFeed.Hero(recipe: porridge, reason: .plannedTomorrow(.breakfast)))
        let hero = try #require(result.hero)
        #expect(result.caption(for: hero) == "Planned for tomorrow's breakfast")
    }

    @Test func lateEveningKeepsTonightsOpenDinner() {
        let curry = recipe("Curry"), porridge = recipe("Porridge", category: "Breakfast")
        let result = feed(
            [curry, porridge], today: [plan(curry, .dinner)], tomorrow: [plan(porridge, .breakfast, dayOffset: 1)],
            at: at(22)
        )
        #expect(result.hero == TodayFeed.Hero(recipe: curry, reason: .planned(.dinner)))
    }

    @Test func lateEveningSuggestsABreakfastAndSaysSo() throws {
        let curry = recipe("Curry"), pancakes = recipe("Pancakes", category: "Breakfast")
        let result = feed([curry, pancakes], at: at(22))
        let hero = try #require(result.hero)
        #expect(hero.recipe == pancakes)
        #expect(result.caption(for: hero) == "For tomorrow's breakfast · Ready in \(DurationFormatter.label(minutes: 15))")
    }

    @Test(arguments: [(8, "For breakfast"), (12, "For lunch"), (18, "For tonight")])
    func aSuggestionNamesItsMeal(hour: Int, label: String) throws {
        let result = feed([recipe("Curry")], at: at(hour))
        let hero = try #require(result.hero)
        #expect(result.caption(for: hero) == "\(label) · Ready in \(DurationFormatter.label(minutes: 15))")
    }

    // MARK: Day strip

    @Test func theStripShowsDonePlannedOpenAndPassedMeals() {
        let porridge = recipe("Porridge"), curry = recipe("Curry")
        let strip = TodayDayStrip.make(
            plans: [plan(porridge, .breakfast, done: true), plan(curry, .dinner)], recipes: [porridge, curry],
            nextMeal: next(at(13)), day: at(13), calendar: cal
        )
        #expect(strip.meals.map(\.text) == ["Breakfast ✓", "Lunch: plan it", "Dinner: Curry"])
        #expect(strip.meals.map(\.isNext) == [false, true, false])
        #expect(strip.meals.map(\.recipeID) == [porridge.id, nil, curry.id])
        #expect(!strip.isTomorrow)
    }

    @Test func anUnplannedMealThatsGoneBySaysSo() {
        let strip = TodayDayStrip.make(plans: [], recipes: [], nextMeal: next(at(19)), day: at(19), calendar: cal)
        #expect(strip.meals.map(\.state) == [.passed, .passed, .open])
        #expect(strip.summary == "Breakfast —. Lunch —. Dinner: plan it")
        #expect(strip.meals.map(\.spokenText) == [
            "Breakfast, nothing planned", "Lunch, nothing planned", "Dinner, nothing planned yet",
        ])
    }

    @Test func anOpenPlanWinsOverATickedOneAtTheSameMeal() {
        let toast = recipe("Toast"), eggs = recipe("Eggs")
        let strip = TodayDayStrip.make(
            plans: [plan(toast, .breakfast, done: true), plan(eggs, .breakfast)], recipes: [toast, eggs],
            nextMeal: next(at(8)), day: at(8), calendar: cal
        )
        #expect(strip.meals.first?.state == .planned("Eggs"))
        #expect(strip.meals.first?.spokenText == "Breakfast: Eggs")
    }

    @Test func aPlanWhoseRecipeIsGoneLeavesTheMealOpen() {
        let gone = recipe("Gone")
        let strip = TodayDayStrip.make(
            plans: [plan(gone, .dinner)], recipes: [], nextMeal: next(at(17)), day: at(17), calendar: cal
        )
        #expect(strip.meals.last?.state == .open)
        #expect(strip.meals.last?.recipeID == nil)
    }

    @Test func aMealCookedWithoutMadeItShowsAsDone() {
        let porridge = recipe("Porridge", lastCookedAt: at(8))
        let strip = TodayDayStrip.make(
            plans: [plan(porridge, .breakfast)], recipes: [porridge], nextMeal: next(at(13)), day: at(13), calendar: cal
        )
        #expect(strip.meals.first?.state == .done("Porridge"))
        #expect(strip.meals.first?.spokenText == "Breakfast, cooked: Porridge")
    }

    @Test func lateEveningShowsTomorrowWithNothingPassed() {
        let porridge = recipe("Porridge")
        let snapshot = TodaySnapshot.make(
            recipes: [porridge],
            plansOn: { date in [plan(porridge, .breakfast, dayOffset: 1)].filter { $0.isOn(date, calendar: cal) } },
            kitchenItemNames: [], inventoryItems: [], streak: .empty, unlockedBadgeIDs: [], now: at(22), calendar: cal
        )
        #expect(snapshot.day.isTomorrow)
        #expect(snapshot.day.date == cal.startOfDay(for: at(0, dayOffset: 1)))
        #expect(snapshot.day.meals.map(\.state) == [.planned("Porridge"), .open, .open])
        #expect(snapshot.day.summary == "Tomorrow. Breakfast: Porridge. Lunch: plan it. Dinner: plan it")
    }
}
