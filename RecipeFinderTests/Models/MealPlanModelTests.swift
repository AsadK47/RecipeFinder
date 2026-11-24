import XCTest
import Testing
@testable import RecipeFinder

final class MealPlanModelTests: XCTestCase {

    // MARK: - isToday

    func testIsToday_trueForCurrentDate() {
        XCTAssertTrue(makePlan(date: Date()).isToday)
    }

    func testIsToday_falseForYesterday() {
        XCTAssertFalse(makePlan(date: daysFromNow(-1)).isToday)
    }

    func testIsToday_falseForTomorrow() {
        XCTAssertFalse(makePlan(date: daysFromNow(1)).isToday)
    }

    // MARK: - isOn / isSlot

    func testIsOn_matchesAnyTimeOnSameDay() {
        let plan = makePlan(date: Date())
        XCTAssertTrue(plan.isOn(Calendar.current.startOfDay(for: Date())))
        XCTAssertFalse(plan.isOn(daysFromNow(1)))
    }

    func testIsSlot_requiresSameDayAndMealTime() {
        let plan = makePlan(date: Date())
        XCTAssertTrue(plan.isSlot(Date(), .dinner))
        XCTAssertFalse(plan.isSlot(Date(), .lunch))
        XCTAssertFalse(plan.isSlot(daysFromNow(1), .dinner))
    }

    // MARK: - isPast

    func testIsPast_trueForYesterday() {
        XCTAssertTrue(makePlan(date: daysFromNow(-1)).isPast)
    }

    func testIsPast_falseForTomorrow() {
        XCTAssertFalse(makePlan(date: daysFromNow(1)).isPast)
    }

    // MARK: - isUpcoming

    func testIsUpcoming_trueForTomorrow() {
        XCTAssertTrue(makePlan(date: daysFromNow(1)).isUpcoming)
    }

    func testIsUpcoming_falseForToday() {
        XCTAssertFalse(makePlan(date: Date()).isUpcoming)
    }

    func testIsUpcoming_falseForYesterday() {
        XCTAssertFalse(makePlan(date: daysFromNow(-1)).isUpcoming)
    }

    // MARK: - normalizedDate

    func testNormalizedDate_stripsTimeComponent() {
        let now = Date()
        let plan = makePlan(date: now)
        let expected = Calendar.current.startOfDay(for: now)
        XCTAssertEqual(plan.normalizedDate, expected)
    }

    // MARK: - WeeklyMealPlan.totalMealsPlanned

    func testTotalMealsPlanned_countsAllMeals() {
        let week = WeeklyMealPlan(startDate: Date(), meals: [
            makePlan(date: Date()),
            makePlan(date: Date()),
            makePlan(date: Date())
        ])
        XCTAssertEqual(week.totalMealsPlanned, 3)
    }

    func testTotalMealsPlanned_emptyMeals_returnsZero() {
        XCTAssertEqual(WeeklyMealPlan(startDate: Date(), meals: []).totalMealsPlanned, 0)
    }

    // MARK: - WeeklyMealPlan.completedMealsCount

    func testCompletedMealsCount_countsOnlyCompleted() {
        let week = WeeklyMealPlan(startDate: Date(), meals: [
            makePlan(date: Date(), isCompleted: true),
            makePlan(date: Date(), isCompleted: false),
            makePlan(date: Date(), isCompleted: true)
        ])
        XCTAssertEqual(week.completedMealsCount, 2)
    }

    func testCompletedMealsCount_noneCompleted_returnsZero() {
        let week = WeeklyMealPlan(startDate: Date(), meals: [
            makePlan(date: Date(), isCompleted: false),
            makePlan(date: Date(), isCompleted: false)
        ])
        XCTAssertEqual(week.completedMealsCount, 0)
    }

    // MARK: - WeeklyMealPlan.mealsByDay

    func testMealsByDay_groupsByNormalizedDate() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let week = WeeklyMealPlan(startDate: today, meals: [
            makePlan(date: today),
            makePlan(date: today),
            makePlan(date: tomorrow)
        ])

        XCTAssertEqual(week.mealsByDay[today]?.count, 2)
        XCTAssertEqual(week.mealsByDay[tomorrow]?.count, 1)
    }

    func testMealsByDay_emptyMeals_returnsEmptyDictionary() {
        let week = WeeklyMealPlan(startDate: Date(), meals: [])
        XCTAssertTrue(week.mealsByDay.isEmpty)
    }

    // MARK: - MealTime.sortOrder

    func testMealTimeSortOrder_isStrictlyIncreasing() {
        let orderedTimes: [MealTime] = [.breakfast, .lunch, .dinner, .snack]
        let orders = orderedTimes.map(\.sortOrder)
        for i in 1..<orders.count {
            XCTAssertGreaterThan(orders[i], orders[i - 1])
        }
    }

    // MARK: - Helpers

    private func makePlan(date: Date, isCompleted: Bool = false) -> MealPlanModel {
        MealPlanModel(
            recipeId: UUID(),
            recipeName: "Test Recipe",
            date: date,
            mealTime: .dinner,
            isCompleted: isCompleted
        )
    }

    private func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date())!
    }
}

/// Plan bug hunt 2026-11-20: the day list matched a plan's recipe by id only, so a re-imported recipe showed as an
/// empty "Tap to add recipe" slot while This week's dinners (by id, then name) showed its photo.
@Suite("Plan → recipe lookup")
struct MealPlanRecipeLookupTests {
    private func recipe(_ name: String) -> RecipeModel {
        RecipeModel(name: name, category: "Main", difficulty: "Basic", prepTime: "5 min", cookingTime: "5 min",
                    baseServings: 2, ingredients: [], prePrepInstructions: [], instructions: [], notes: "")
    }

    @Test func findsTheRecipeById() {
        let dal = recipe("Dal")
        let plan = MealPlanModel(recipeId: dal.id, recipeName: "Old name", date: Date(), mealTime: .dinner)
        #expect(plan.recipe(in: [recipe("Old name"), dal])?.id == dal.id)
    }

    @Test func aReimportedRecipeIsFoundByName() {
        let reimported = recipe("Chicken Curry")
        let plan = MealPlanModel(recipeId: UUID(), recipeName: "chicken curry", date: Date(), mealTime: .dinner)
        #expect(plan.recipe(in: [reimported])?.id == reimported.id)
    }

    @Test func aDeletedRecipeIsNil() {
        let plan = MealPlanModel(recipeId: UUID(), recipeName: "Popcorn", date: Date(), mealTime: .snack)
        #expect(plan.recipe(in: [recipe("Dal")]) == nil)
    }
}

/// Owner 2026-11-20: past days show a plan only if that dish was cooked; today and later are unaffected.
@Suite("Past plans show only when cooked")
struct MealPlanShownTests {
    private let cal: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current
        return cal
    }()

    private func at(_ day: Int, _ hour: Int = 0) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour)) ?? Date()
    }

    private func recipe(cookedAt: Date?) -> RecipeModel {
        RecipeModel(name: "Dal", category: "Main", difficulty: "Basic", prepTime: "5 min", cookingTime: "5 min",
                    baseServings: 2, ingredients: [], prePrepInstructions: [], instructions: [], notes: "",
                    lastCookedAt: cookedAt)
    }

    private func plan(_ recipe: RecipeModel, on date: Date, completed: Bool = false) -> MealPlanModel {
        MealPlanModel(recipeId: recipe.id, recipeName: recipe.name, date: date, mealTime: .dinner, isCompleted: completed)
    }

    @Test func aPastPlanCookedThatDayShows() {
        let dal = recipe(cookedAt: at(18, 19))
        #expect(plan(dal, on: at(18)).isShown(now: at(20, 9), recipes: [dal], calendar: cal))
    }

    @Test func aPastPlanMarkedCookedShows() {
        let dal = recipe(cookedAt: nil)
        #expect(plan(dal, on: at(18), completed: true).isShown(now: at(20, 9), recipes: [dal], calendar: cal))
    }

    @Test func aPastPlanNotCookedIsHidden() {
        let dal = recipe(cookedAt: at(19, 19))  // cooked, but the day after its plan
        #expect(!plan(dal, on: at(18)).isShown(now: at(20, 9), recipes: [dal], calendar: cal))
    }

    @Test func todayAndLaterShowUncooked() {
        let dal = recipe(cookedAt: nil)
        #expect(plan(dal, on: at(20)).isShown(now: at(20, 22), recipes: [dal], calendar: cal))
        #expect(plan(dal, on: at(23)).isShown(now: at(20, 22), recipes: [dal], calendar: cal))
    }
}

/// Undo after a take-off can't put a meal back on a night planned since; the toast has to say so.
@Suite("Undo: meals that couldn't go back")
struct MealPlanNotPutBackTests {
    private func plan(_ name: String, recipe: UUID = UUID()) -> MealPlanModel {
        MealPlanModel(recipeId: recipe, recipeName: name, date: Date(), mealTime: .dinner)
    }

    @Test func nothingSkippedSaysNothing() {
        #expect(MealPlanModel.notPutBackMessage([]) == nil)
    }

    @Test func oneSkippedNamesTheMeal() {
        #expect(MealPlanModel.notPutBackMessage([plan("Dal")]) == "Dal stayed off: another meal is planned there now")
    }

    @Test func severalSkippedCountThem() {
        #expect(MealPlanModel.notPutBackMessage([plan("Dal"), plan("Tacos")])
                == "2 meals stayed off: other meals are planned there now")
    }

    @Test func copiesOfOneWeeklyDishCountOnce() {
        let tacos = UUID()
        #expect(MealPlanModel.notPutBackMessage([plan("Tacos", recipe: tacos), plan("Tacos", recipe: tacos)])
                == "Tacos stayed off: another meal is planned there now")
    }
}

/// Plan's take-off toast: one Undo for take-offs in a row, and a count of meals that actually came off.
@Suite("Take-off toast and Undo")
struct MealPlanTakeOffTests {
    private let day: TimeInterval = 86_400
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func plan(_ name: String, week: Int = 0, recurring: Bool = false) -> MealPlanModel {
        MealPlanModel(recipeId: UUID(), recipeName: name, date: start.addingTimeInterval(Double(week) * 7 * day),
                      mealTime: .dinner, isRecurring: recurring)
    }

    @Test func firstTakeOffNamesTheMeal() {
        let dal = plan("Dal")
        let result = MealPlanTakeOff.after(taking: dal, changed: [dal], earlier: [], isStillPlanned: { _ in false })
        #expect(result.message == "Dal taken off")
        #expect(result.undo == [dal])
    }

    @Test func firstTakeOffOfAWeeklyMealSaysItStoppedRepeating() {
        let tacos = plan("Tacos", recurring: true)
        let result = MealPlanTakeOff.after(taking: tacos, changed: [tacos], earlier: [], isStillPlanned: { _ in false })
        #expect(result.message == "Tacos taken off and stopped repeating")
    }

    @Test func aSecondTakeOffSharesTheUndoAndKeepsTheFirstSnapshot() {
        let dal = plan("Dal")
        var edited = dal
        edited.servings = 9
        let curry = plan("Curry", week: 1)
        let result = MealPlanTakeOff.after(taking: curry, changed: [curry, edited], earlier: [dal],
                                           isStillPlanned: { _ in false })
        #expect(result.undo == [dal, curry])
        #expect(result.message == "2 meals taken off")
    }

    /// W2 of a W1–W3 weekly series: W2 and W3 come off, W1 only stops repeating and stays planned.
    /// Then one more meal comes off: 3 meals, not 4.
    @Test func anEarlierWeeklyCopyThatStaysPlannedIsNotCounted() {
        let w1 = plan("Tacos", week: 0, recurring: true)
        let w2 = plan("Tacos", week: 1, recurring: true)
        let w3 = plan("Tacos", week: 2, recurring: true)
        let dal = plan("Dal", week: 3)
        let result = MealPlanTakeOff.after(taking: dal, changed: [dal], earlier: [w1, w2, w3],
                                           isStillPlanned: { $0.id == w1.id })
        #expect(result.message == "3 meals taken off")
        #expect(result.undo == [w1, w2, w3, dal])
    }

    /// A stale second tap on a dinner already taken off changes nothing: still one meal off, not "2 meals".
    @Test func aTakeOffThatChangesNothingKeepsTheOneMealMessage() {
        let dal = plan("Dal")
        let result = MealPlanTakeOff.after(taking: dal, changed: [], earlier: [dal], isStillPlanned: { _ in false })
        #expect(result.message == "Dal taken off")
        #expect(result.undo == [dal])
    }
}
