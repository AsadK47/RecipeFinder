import XCTest
import Testing
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

    // MARK: - weekShoppingSummary

    func testWeekShoppingSummary_mergesDuplicateIngredientsAcrossMeals() {
        let curry = makeRecipe(name: "Chicken Curry", ingredientNames: ["chicken breast", "onion", "garlic"])
        let stirFry = makeRecipe(name: "Chicken Stir Fry", ingredientNames: ["chicken breast", "peppers"])
        let start = weekStart(containing: Date())
        let dayOne = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let dayTwo = Calendar.current.date(byAdding: .day, value: 2, to: start)!

        sut.addMealPlan(makePlan(recipeId: curry.id, recipeName: curry.name, date: dayOne, mealTime: .dinner))
        sut.addMealPlan(makePlan(recipeId: stirFry.id, recipeName: stirFry.name, date: dayTwo, mealTime: .dinner))

        let summary = sut.weekShoppingSummary(forWeekStarting: start, recipes: [curry, stirFry])

        XCTAssertEqual(summary.mealsCovered, 2)
        XCTAssertTrue(summary.missingRecipeNames.isEmpty)

        let chicken = summary.items.first { $0.name.lowercased().contains("chicken") }
        XCTAssertEqual(chicken?.quantity, 2, "Chicken appears in both meals so it should merge with quantity 2")
        XCTAssertEqual(summary.items.filter { $0.name.lowercased().contains("chicken") }.count, 1)
    }

    func testWeekShoppingSummary_skipsCompletedMeals() {
        let recipe = makeRecipe(name: "Pasta", ingredientNames: ["spaghetti"])
        var plan = makePlan(recipeId: recipe.id, recipeName: recipe.name, date: Date(), mealTime: .dinner)
        plan.isCompleted = true
        sut.addMealPlan(plan)

        let summary = sut.weekShoppingSummary(forWeekStarting: weekStart(containing: Date()), recipes: [recipe])

        XCTAssertTrue(summary.isEmpty)
        XCTAssertEqual(summary.mealsCovered, 0)
    }

    func testWeekShoppingSummary_reportsMissingRecipesOnce() {
        let start = weekStart(containing: Date())
        let dayOne = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let dayTwo = Calendar.current.date(byAdding: .day, value: 2, to: start)!
        sut.addMealPlan(makePlan(recipeName: "Deleted Recipe", date: dayOne, mealTime: .dinner))
        sut.addMealPlan(makePlan(recipeName: "Deleted Recipe", date: dayTwo, mealTime: .lunch))

        let summary = sut.weekShoppingSummary(forWeekStarting: start, recipes: [])

        XCTAssertTrue(summary.items.isEmpty)
        XCTAssertEqual(summary.mealsCovered, 0)
        XCTAssertEqual(summary.missingRecipeNames, ["Deleted Recipe"])
    }

    func testWeekShoppingSummary_fallsBackToNameWhenIdChanged() {
        let reimported = makeRecipe(name: "Chicken Curry", ingredientNames: ["chicken breast"])
        sut.addMealPlan(makePlan(recipeId: UUID(), recipeName: "chicken curry", date: Date(), mealTime: .dinner))

        let summary = sut.weekShoppingSummary(forWeekStarting: weekStart(containing: Date()), recipes: [reimported])

        XCTAssertEqual(summary.mealsCovered, 1)
        XCTAssertTrue(summary.missingRecipeNames.isEmpty)
        XCTAssertFalse(summary.items.isEmpty)
    }

    func testWeekShoppingSummary_excludesMealsOutsideTheWeek() {
        let recipe = makeRecipe(name: "Pasta", ingredientNames: ["spaghetti"])
        let start = weekStart(containing: Date())
        let nextWeek = Calendar.current.date(byAdding: .day, value: 8, to: start)!
        sut.addMealPlan(makePlan(recipeId: recipe.id, recipeName: recipe.name, date: nextWeek, mealTime: .dinner))

        let summary = sut.weekShoppingSummary(forWeekStarting: start, recipes: [recipe])

        XCTAssertTrue(summary.isEmpty)
    }

    // MARK: - Helpers

    private func weekStart(containing date: Date) -> Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: date)?.start ?? date
    }

    private func makeRecipe(name: String, ingredientNames: [String]) -> RecipeModel {
        RecipeModel(
            name: name,
            category: "Test",
            difficulty: "Easy",
            prepTime: "10 min",
            cookingTime: "20 min",
            baseServings: 4,
            ingredients: ingredientNames.map { Ingredient(baseQuantity: 1, unit: "unit", name: $0) },
            prePrepInstructions: [],
            instructions: [],
            notes: ""
        )
    }

    private func makePlan(
        recipeId: UUID? = nil,
        recipeName: String = "Test Recipe",
        date: Date = Date(),
        mealTime: MealTime = .breakfast
    ) -> MealPlanModel {
        MealPlanModel(
            recipeId: recipeId ?? self.recipeId,
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

// MARK: - sortedOrderedMealTimes

@Suite("MealPlanningManager.sortedOrderedMealTimes")
struct SortedOrderedMealTimesTests {

    @Test("initialises from empty in natural sort order")
    func initialisesEmpty() {
        let result = MealPlanningManager.sortedOrderedMealTimes(
            existing: [],
            selected: [.lunch, .dinner]
        )
        #expect(result == [.lunch, .dinner])
    }

    @Test("preserves custom order and appends new items at their natural position")
    func preservesCustomOrderAndAppendsNew() {
        let result = MealPlanningManager.sortedOrderedMealTimes(
            existing: [.dinner, .breakfast, .lunch],
            selected: [.breakfast, .dinner, .lunch, .snack]
        )
        #expect(result == [.dinner, .breakfast, .lunch, .snack])
    }

    @Test("removes items no longer selected")
    func removesUnselected() {
        let result = MealPlanningManager.sortedOrderedMealTimes(
            existing: [.breakfast, .lunch, .dinner],
            selected: [.breakfast, .dinner]
        )
        #expect(result == [.breakfast, .dinner])
    }

    @Test("returns empty when selection is empty")
    func returnsEmptyForEmptySelection() {
        let result = MealPlanningManager.sortedOrderedMealTimes(
            existing: [.breakfast, .dinner],
            selected: []
        )
        #expect(result.isEmpty)
    }
}
