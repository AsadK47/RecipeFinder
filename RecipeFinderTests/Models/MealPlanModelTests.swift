import XCTest
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
