import Testing
import Foundation
@testable import RecipeFinder

/// Plan's week as seven dinner photos: which dish each night shows, and "hold = move" (move a dinner to another
/// night; swap when that night already has one). Fixed UTC calendar, week of Monday 16 Nov 2026.
@Suite struct WeekDinnersTests {

    private let cal: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current
        return cal
    }()

    /// Monday 16 Nov 2026 at `hour` + `offset` days.
    private func day(_ offset: Int, hour: Int = 0) -> Date {
        let monday = cal.date(from: DateComponents(year: 2026, month: 11, day: 16, hour: hour)) ?? Date()
        return cal.date(byAdding: .day, value: offset, to: monday) ?? monday
    }

    private var week: [Date] { (0..<7).map { day($0) } }

    private func recipe(_ name: String) -> RecipeModel {
        RecipeModel(
            name: name, category: "Main", difficulty: "Basic", prepTime: "0 min", cookingTime: "20 min",
            baseServings: 2, ingredients: [], prePrepInstructions: [], instructions: ["Cook"], notes: ""
        )
    }

    private func plan(_ recipe: RecipeModel, on date: Date, _ mealTime: MealTime = .dinner) -> MealPlanModel {
        MealPlanModel(recipeId: recipe.id, recipeName: recipe.name, date: date, mealTime: mealTime)
    }

    // MARK: - Nights

    @Test func showsSevenNightsInWeekOrder() {
        let nights = WeekDinners.nights(week: week, plans: [], recipes: [], today: day(2), calendar: cal)
        #expect(nights.map { $0.date } == week)
        #expect(nights.allSatisfy { $0.plan == nil && $0.recipe == nil })
    }

    @Test func eachNightShowsItsDinnerNotOtherMeals() {
        let pasta = recipe("Pasta")
        let toast = recipe("Toast")
        let plans = [plan(toast, on: day(1, hour: 9), .breakfast), plan(pasta, on: day(1, hour: 14))]
        let nights = WeekDinners.nights(week: week, plans: plans, recipes: [pasta, toast], today: day(0), calendar: cal)
        #expect(nights[1].recipe?.name == "Pasta")
        #expect(nights[1].plan?.recipeName == "Pasta")
        #expect(nights[0].recipe == nil)
    }

    @Test func breakfastAloneLeavesTheNightEmpty() {
        let toast = recipe("Toast")
        let nights = WeekDinners.nights(week: week, plans: [plan(toast, on: day(3), .breakfast)], recipes: [toast],
                                        today: day(0), calendar: cal)
        #expect(nights[3].plan == nil)
    }

    @Test func reimportedRecipeIsFoundByName() {
        let old = recipe("Curry")
        let reimported = recipe("Curry")
        let nights = WeekDinners.nights(week: week, plans: [plan(old, on: day(4))], recipes: [reimported],
                                        today: day(0), calendar: cal)
        #expect(nights[4].recipe?.id == reimported.id)
    }

    @Test func deletedRecipeKeepsThePlanWithoutAPhoto() {
        let gone = recipe("Gone stew")
        let nights = WeekDinners.nights(week: week, plans: [plan(gone, on: day(5))], recipes: [],
                                        today: day(0), calendar: cal)
        #expect(nights[5].plan?.recipeName == "Gone stew")
        #expect(nights[5].recipe == nil)
    }

    @Test func marksTonightAndPastNights() {
        let nights = WeekDinners.nights(week: week, plans: [], recipes: [], today: day(2, hour: 18), calendar: cal)
        #expect(nights.map { $0.isToday } == [false, false, true, false, false, false, false])
        #expect(nights.map { $0.isPast } == [true, true, false, false, false, false, false])
    }

    // MARK: - Move

    @Test func moveToAnEmptyNightChangesOnlyThatDinnersDay() {
        let pasta = plan(recipe("Pasta"), on: day(1, hour: 14))
        let moved = WeekDinners.move(pasta, to: day(4), plans: [pasta], today: day(0), calendar: cal)
        #expect(moved.count == 1)
        #expect(moved.first?.id == pasta.id)
        #expect(moved.first?.date == day(4, hour: 14))
    }

    @Test func moveOntoAPlannedNightSwapsTheTwoDinners() {
        let pasta = plan(recipe("Pasta"), on: day(1, hour: 14))
        let curry = plan(recipe("Curry"), on: day(4, hour: 10))
        let moved = WeekDinners.move(pasta, to: day(4), plans: [pasta, curry], today: day(0), calendar: cal)
        #expect(moved.count == 2)
        #expect(moved.first { $0.id == pasta.id }?.date == day(4, hour: 14))
        #expect(moved.first { $0.id == curry.id }?.date == day(1, hour: 10))
    }

    @Test func moveIgnoresOtherMealsOnTheTargetNight() {
        let pasta = plan(recipe("Pasta"), on: day(1))
        let lunch = plan(recipe("Soup"), on: day(4), .lunch)
        let moved = WeekDinners.move(pasta, to: day(4), plans: [pasta, lunch], today: day(0), calendar: cal)
        #expect(moved.map { $0.id } == [pasta.id])
    }

    @Test func moveToTheSameNightChangesNothing() {
        let pasta = plan(recipe("Pasta"), on: day(1, hour: 14))
        #expect(WeekDinners.move(pasta, to: day(1, hour: 20), plans: [pasta], today: day(0), calendar: cal).isEmpty)
    }

    @Test func moveKeepsTheTimeAcrossAClockChange() {
        var london = Calendar(identifier: .gregorian)
        london.timeZone = TimeZone(identifier: "Europe/London") ?? .current
        // Sat 24 Oct 2026 18:00 BST → Mon 26 Oct (clocks went back on Sun 25 Oct).
        let saturday = london.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 18)) ?? Date()
        let monday = london.date(from: DateComponents(year: 2026, month: 10, day: 26)) ?? Date()
        let pasta = MealPlanModel(recipeId: UUID(), recipeName: "Pasta", date: saturday, mealTime: .dinner)
        let moved = WeekDinners.move(pasta, to: monday, plans: [pasta], today: saturday, calendar: london)
        let parts = moved.first.map { london.dateComponents([.day, .hour], from: $0.date) }
        #expect(parts?.day == 26)
        #expect(parts?.hour == 18)
    }

    @Test func moveTargetsAreTheOtherNightsWithTheirDish() {
        let pasta = recipe("Pasta")
        let curry = recipe("Curry")
        let plans = [plan(pasta, on: day(1)), plan(curry, on: day(3))]
        let nights = WeekDinners.nights(week: week, plans: plans, recipes: [pasta, curry], today: day(0), calendar: cal)
        let targets = WeekDinners.moveTargets(from: nights[1], in: nights)
        #expect(targets.map { $0.date } == [day(0), day(2), day(3), day(4), day(5), day(6)])
        #expect(targets.first { $0.date == day(3) }?.plan?.recipeName == "Curry")
    }

    @Test func moveTargetsSkipPastNights() {
        let pasta = recipe("Pasta")
        let nights = WeekDinners.nights(week: week, plans: [plan(pasta, on: day(3))], recipes: [pasta],
                                        today: day(3), calendar: cal)
        let targets = WeekDinners.moveTargets(from: nights[3], in: nights)
        #expect(targets.map { $0.date } == [day(4), day(5), day(6)])
    }

    /// Plan shows a past night's dinner only once it was cooked (`MealPlanModel.isShown`), so a past dinner is
    /// history: it offers no moves and a move request changes nothing.
    @Test func cookedPastDinnerOffersNoMoves() {
        let pasta = recipe("Pasta")
        let curry = recipe("Curry")
        let plans = [plan(pasta, on: day(0)), plan(curry, on: day(4))]
        let nights = WeekDinners.nights(week: week, plans: plans, recipes: [pasta, curry], today: day(3), calendar: cal)
        #expect(WeekDinners.moveTargets(from: nights[0], in: nights).isEmpty)
    }

    @Test func pastDinnerDoesNotMoveOntoAnEmptyNight() {
        let pasta = plan(recipe("Pasta"), on: day(0, hour: 18))
        #expect(WeekDinners.move(pasta, to: day(3), plans: [pasta], today: day(3), calendar: cal).isEmpty)
    }

    @Test func pastDinnerDoesNotSwapWithAPlannedNight() {
        let pasta = plan(recipe("Pasta"), on: day(0))
        let curry = plan(recipe("Curry"), on: day(4))
        #expect(WeekDinners.move(pasta, to: day(4), plans: [pasta, curry], today: day(3), calendar: cal).isEmpty)
    }

    @Test func aDinnerCantMoveOntoACookedPastNight() {
        let pasta = recipe("Pasta")
        let curry = recipe("Curry")
        let plans = [plan(pasta, on: day(0)), plan(curry, on: day(4))]
        let nights = WeekDinners.nights(week: week, plans: plans, recipes: [pasta, curry], today: day(3), calendar: cal)
        #expect(!WeekDinners.moveTargets(from: nights[4], in: nights).contains { $0.date == day(0) })
    }

    /// Tonight's dinner whose time has already gone (planned for 8am, now 8pm) is still tonight's: it can move.
    @Test func tonightsDinnerMovesEvenAfterItsTime() {
        let pasta = plan(recipe("Pasta"), on: day(3, hour: 8))
        let moved = WeekDinners.move(pasta, to: day(4), plans: [pasta], today: day(3, hour: 20), calendar: cal)
        #expect(moved.first?.date == day(4, hour: 8))
    }

    @Test func nothingMovesIntoThePast() {
        let pasta = plan(recipe("Pasta"), on: day(4))
        #expect(WeekDinners.move(pasta, to: day(1), plans: [pasta], today: day(3), calendar: cal).isEmpty)
    }

    @Test func repeatingDinnersDontMoveOrGetSwapped() {
        let pasta = recipe("Pasta")
        let curry = recipe("Curry")
        var weekly = plan(pasta, on: day(1))
        weekly.isRecurring = true
        let once = plan(curry, on: day(4))
        let nights = WeekDinners.nights(week: week, plans: [weekly, once], recipes: [pasta, curry],
                                        today: day(0), calendar: cal)
        #expect(WeekDinners.moveTargets(from: nights[1], in: nights).isEmpty)
        #expect(!WeekDinners.moveTargets(from: nights[4], in: nights).contains { $0.date == day(1) })
        #expect(WeekDinners.move(weekly, to: day(5), plans: [weekly, once], today: day(0), calendar: cal).isEmpty)
        #expect(WeekDinners.move(once, to: day(1), plans: [weekly, once], today: day(0), calendar: cal).isEmpty)
    }

    // MARK: - VoiceOver hint

    /// The hint names what the hold menu offers: cook when the recipe exists, take off always, move only when
    /// `moveTargets` has somewhere to go (not past, not repeating, not when every other night is behind us).
    @Test func dinnerHintMatchesTheHoldMenu() {
        let pasta = recipe("Pasta"), curry = recipe("Curry"), gone = recipe("Gone")
        var weekly = plan(curry, on: day(4))
        weekly.isRecurring = true
        let plans = [plan(pasta, on: day(1)), plan(pasta, on: day(3)), weekly, plan(gone, on: day(5))]
        let nights = WeekDinners.nights(week: week, plans: plans, recipes: [pasta, curry], today: day(2), calendar: cal)
        let hint = { (offset: Int) in WeekDinnersView.dinnerHint(nights[offset], in: nights) }

        #expect(hint(1) == "Opens the recipe. Use actions to cook it again or take it off the plan.")
        #expect(hint(3) == "Opens the recipe. Use actions to cook it, move it or take it off the plan.")
        #expect(hint(4) == "Opens the recipe. Use actions to cook it or take it off and stop it repeating.")
        #expect(hint(5) == "This recipe is no longer in your library. Use actions to move it or take it off the plan.")
    }

    @Test func dinnerHintOffersNoMoveWhenNoOtherNightIsAhead() {
        let pasta = recipe("Pasta")
        let nights = WeekDinners.nights(week: week, plans: [plan(pasta, on: day(6))], recipes: [pasta],
                                        today: day(6), calendar: cal)
        #expect(WeekDinners.moveTargets(from: nights[6], in: nights).isEmpty)
        #expect(!WeekDinnersView.dinnerHint(nights[6], in: nights).contains("move it"))
    }
}
