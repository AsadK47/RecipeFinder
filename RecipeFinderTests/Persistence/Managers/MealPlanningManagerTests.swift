import XCTest
@testable import RecipeFinder

@MainActor
final class MealPlanningManagerTests: XCTestCase {

    private var storage: UserScopedStorage!
    private var sut: MealPlanningManager!
    private let recipeId = UUID()

    override func setUp() async throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        storage = UserScopedStorage(userDefaults: defaults)
        sut = MealPlanningManager(storage: storage)
    }

    override func tearDown() async throws {
        sut = nil
        storage = nil
    }

    // MARK: - Initial state

    func testInitialState_isEmpty() {
        XCTAssertTrue(sut.mealPlans.isEmpty)
    }

    // MARK: - addMealPlan

    func testAddMealPlan_addsNewPlan() {
        sut.addMealPlan(makePlan(mealTime: .breakfast))
        XCTAssertEqual(sut.mealPlans.count, 1)
    }

    func testAddMealPlan_differentMealTimes_bothAdded() {
        sut.addMealPlan(makePlan(mealTime: .breakfast))
        sut.addMealPlan(makePlan(mealTime: .dinner))
        XCTAssertEqual(sut.mealPlans.count, 2)
    }

    func testAddMealPlan_sameDateAndMealTime_replacesExisting() {
        let date = Date()
        let original = makePlan(recipeName: "Original", date: date, mealTime: .lunch)
        let replacement = makePlan(recipeName: "Replacement", date: date, mealTime: .lunch)

        sut.addMealPlan(original)
        sut.addMealPlan(replacement)

        XCTAssertEqual(sut.mealPlans.count, 1)
        XCTAssertEqual(sut.mealPlans[0].recipeName, "Replacement")
    }

    func testAddMealPlan_sameDateDifferentMealTime_bothKept() {
        let date = Date()
        sut.addMealPlan(makePlan(date: date, mealTime: .breakfast))
        sut.addMealPlan(makePlan(date: date, mealTime: .lunch))
        XCTAssertEqual(sut.mealPlans.count, 2)
    }

    // MARK: - removeMealPlan (by id)

    func testRemoveMealPlan_removesById() {
        let plan = makePlan()
        sut.addMealPlan(plan)
        sut.removeMealPlan(sut.mealPlans[0])
        XCTAssertTrue(sut.mealPlans.isEmpty)
    }

    // MARK: - removeMealPlan (by date + mealTime)

    func testRemoveMealPlan_byDateAndMealTime_removesCorrectPlan() {
        let date = Date()
        sut.addMealPlan(makePlan(date: date, mealTime: .breakfast))
        sut.addMealPlan(makePlan(date: date, mealTime: .lunch))
        sut.removeMealPlan(for: date, mealTime: .breakfast)
        XCTAssertEqual(sut.mealPlans.count, 1)
        XCTAssertEqual(sut.mealPlans[0].mealTime, .lunch)
    }

    // MARK: - toggleCompletion

    func testToggleCompletion_marksCompleted() {
        sut.addMealPlan(makePlan())
        let plan = sut.mealPlans[0]
        sut.toggleCompletion(plan)
        XCTAssertTrue(sut.mealPlans[0].isCompleted)
    }

    func testToggleCompletion_togglesBackToIncomplete() {
        sut.addMealPlan(makePlan())
        let plan = sut.mealPlans[0]
        sut.toggleCompletion(plan)
        sut.toggleCompletion(sut.mealPlans[0])
        XCTAssertFalse(sut.mealPlans[0].isCompleted)
    }

    // MARK: - mealPlan(for:mealTime:)

    func testMealPlan_forDateAndTime_returnsMatch() {
        let date = Date()
        sut.addMealPlan(makePlan(recipeName: "Oatmeal", date: date, mealTime: .breakfast))
        let result = sut.mealPlan(for: date, mealTime: .breakfast)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.recipeName, "Oatmeal")
    }

    func testMealPlan_forDateAndTime_returnsNilWhenAbsent() {
        XCTAssertNil(sut.mealPlan(for: Date(), mealTime: .dinner))
    }

    // MARK: - mealPlans(for:)

    func testMealPlans_forDate_returnsAllPlansForThatDay() {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        sut.addMealPlan(makePlan(date: today, mealTime: .breakfast))
        sut.addMealPlan(makePlan(date: today, mealTime: .dinner))
        sut.addMealPlan(makePlan(date: tomorrow, mealTime: .breakfast))
        XCTAssertEqual(sut.mealPlans(for: today).count, 2)
        XCTAssertEqual(sut.mealPlans(for: tomorrow).count, 1)
    }

    // MARK: - hasMealPlans(for:)

    func testHasMealPlans_trueWhenDateHasPlan() {
        let date = Date()
        sut.addMealPlan(makePlan(date: date))
        XCTAssertTrue(sut.hasMealPlans(for: date))
    }

    func testHasMealPlans_falseWhenNoPlans() {
        XCTAssertFalse(sut.hasMealPlans(for: Date()))
    }

    // MARK: - clearOldMealPlans

    func testClearOldMealPlans_removesPlansOlderThanOneWeek() {
        let eightDaysAgo = Calendar.current.date(byAdding: .day, value: -8, to: Date())!
        let today = Date()
        saveDirectly([
            makePlan(date: eightDaysAgo),
            makePlan(date: today, mealTime: .dinner)
        ])
        sut.clearOldMealPlans()
        XCTAssertEqual(sut.mealPlans.count, 1)
        XCTAssertTrue(Calendar.current.isDateInToday(sut.mealPlans[0].date))
    }

    // MARK: - Persistence

    func testPersistence_acrossReload() {
        sut.addMealPlan(makePlan(recipeName: "Pancakes"))
        let sut2 = MealPlanningManager(storage: storage)
        XCTAssertEqual(sut2.mealPlans.count, 1)
        XCTAssertEqual(sut2.mealPlans[0].recipeName, "Pancakes")
    }

    // MARK: - Helpers

    private func makePlan(
        recipeName: String = "Test Recipe",
        date: Date = Date(),
        mealTime: MealTime = .breakfast
    ) -> MealPlanModel {
        MealPlanModel(
            recipeId: recipeId,
            recipeName: recipeName,
            date: date,
            mealTime: mealTime
        )
    }

    /// Seeds meal plans directly into storage and reloads.
    private func saveDirectly(_ plans: [MealPlanModel]) {
        if let data = try? JSONEncoder().encode(plans) {
            storage.set(data, forKey: "mealPlansStorage")
        }
        sut.reloadForCurrentUser()
    }
}
