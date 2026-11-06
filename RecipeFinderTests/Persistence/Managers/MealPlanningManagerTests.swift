import XCTest
import Testing
@testable import RecipeFinder

@MainActor
final class MealPlanningManagerTests: XCTestCase {

    private var storage: LocalStore!
    private var sut: MealPlanningManager!
    private let recipeId = UUID()

    override func setUp() async throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        storage = LocalStore(userDefaults: defaults)
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
        XCTAssertEqual(chicken?.unit, "unit", "The ingredient unit is carried through, not dropped")
        XCTAssertEqual(summary.items.filter { $0.name.lowercased().contains("chicken") }.count, 1)
    }

    func testWeekShoppingSummary_sumsSameUnitButKeepsDifferentUnitsSeparate() {
        // Two recipes both need "flour": one in grams, one in cups. Grams should sum; cups stay a separate line.
        let a = RecipeModel(
            name: "Bread", category: "Test", difficulty: "Basic", prepTime: "5 min", cookingTime: "5 min",
            baseServings: 1, ingredients: [Ingredient(baseQuantity: 200, unit: "g", name: "flour")],
            prePrepInstructions: [], instructions: [], notes: ""
        )
        let b = RecipeModel(
            name: "Rolls", category: "Test", difficulty: "Basic", prepTime: "5 min", cookingTime: "5 min",
            baseServings: 1, ingredients: [Ingredient(baseQuantity: 100, unit: "g", name: "flour")],
            prePrepInstructions: [], instructions: [], notes: ""
        )
        let c = RecipeModel(
            name: "Pancakes", category: "Test", difficulty: "Basic", prepTime: "5 min", cookingTime: "5 min",
            baseServings: 1, ingredients: [Ingredient(baseQuantity: 1, unit: "cup", name: "flour")],
            prePrepInstructions: [], instructions: [], notes: ""
        )
        let start = weekStart(containing: Date())
        let d1 = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let d2 = Calendar.current.date(byAdding: .day, value: 2, to: start)!
        let d3 = Calendar.current.date(byAdding: .day, value: 3, to: start)!
        sut.addMealPlan(makePlan(recipeId: a.id, recipeName: a.name, date: d1, mealTime: .dinner))
        sut.addMealPlan(makePlan(recipeId: b.id, recipeName: b.name, date: d2, mealTime: .dinner))
        sut.addMealPlan(makePlan(recipeId: c.id, recipeName: c.name, date: d3, mealTime: .dinner))

        let summary = sut.weekShoppingSummary(forWeekStarting: start, recipes: [a, b, c])
        let flour = summary.items.filter { $0.name.lowercased().contains("flour") }

        XCTAssertEqual(flour.count, 2, "Grams merge into one line; cups stay separate")
        XCTAssertEqual(flour.first { $0.unit == "g" }?.quantity, 300, "200g + 100g sum")
        XCTAssertEqual(flour.first { $0.unit == "cup" }?.quantity, 1)
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
        sut.reload()
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

// MARK: - Recurring meal plans

@MainActor
@Suite("Recurring meal plans")
struct RecurringMealPlanTests {

    private func makeManager() -> MealPlanningManager {
        MealPlanningManager(storage: LocalStore(
            userDefaults: UserDefaults(suiteName: UUID().uuidString)!
        ))
    }

    private func makePlan(
        recipeName: String = "Test",
        date: Date = Date(),
        mealTime: MealTime = .dinner,
        isRecurring: Bool = false
    ) -> MealPlanModel {
        MealPlanModel(recipeId: UUID(), recipeName: recipeName, date: date, mealTime: mealTime, isRecurring: isRecurring)
    }

    private func weekStart(containing date: Date) -> Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: date)?.start ?? date
    }

    // MARK: toggleRecurring

    @Test func toggleRecurring_setsFlag() {
        let sut = makeManager()
        let plan = makePlan()
        sut.addMealPlan(plan)
        sut.toggleRecurring(plan)
        #expect(sut.mealPlan(for: plan.date, mealTime: plan.mealTime)?.isRecurring == true)
    }

    @Test func toggleRecurring_clearsFlag() {
        let sut = makeManager()
        let plan = makePlan(isRecurring: true)
        sut.addMealPlan(plan)
        sut.toggleRecurring(plan)
        #expect(sut.mealPlan(for: plan.date, mealTime: plan.mealTime)?.isRecurring == false)
    }

    @Test func toggleRecurring_noopsForUnknownId() {
        let sut = makeManager()
        let notAdded = makePlan()
        sut.toggleRecurring(notAdded)  // should not crash
        #expect(sut.mealPlans.isEmpty)
    }

    // MARK: propagateRecurring

    @Test func propagateRecurring_createsEntryForMatchingWeekday() {
        let cal = Calendar.current
        let sut = makeManager()

        // 14 days ago and 7 days ago share the same weekday
        let today = cal.startOfDay(for: Date())
        let fourteenDaysAgo = cal.date(byAdding: .day, value: -14, to: today)!
        let sevenDaysAgo    = cal.date(byAdding: .day, value: -7,  to: today)!

        let template = makePlan(recipeName: "Weekly Pasta", date: fourteenDaysAgo, mealTime: .dinner)
        sut.addMealPlan(template)
        sut.toggleRecurring(template)

        sut.propagateRecurring(toWeekStarting: weekStart(containing: sevenDaysAgo))

        let projected = sut.mealPlan(for: sevenDaysAgo, mealTime: .dinner)
        #expect(projected?.recipeName == "Weekly Pasta")
        #expect(projected?.isRecurring == true)
    }

    @Test func propagateRecurring_doesNotDuplicateExistingSlot() {
        let cal = Calendar.current
        let sut = makeManager()

        let today       = cal.startOfDay(for: Date())
        let sevenDaysAgo = cal.date(byAdding: .day, value: -7, to: today)!

        // Recurring template from last week
        let template = makePlan(recipeName: "Template", date: sevenDaysAgo, mealTime: .lunch)
        sut.addMealPlan(template)
        sut.toggleRecurring(template)

        // Concrete override already in this week's slot
        sut.addMealPlan(makePlan(recipeName: "Override", date: today, mealTime: .lunch))

        sut.propagateRecurring(toWeekStarting: weekStart(containing: today))

        #expect(sut.mealPlan(for: today, mealTime: .lunch)?.recipeName == "Override")
    }

    @Test func propagateRecurring_isIdempotent() {
        let cal = Calendar.current
        let sut = makeManager()

        let today        = cal.startOfDay(for: Date())
        let fourteenDaysAgo = cal.date(byAdding: .day, value: -14, to: today)!
        let sevenDaysAgo    = cal.date(byAdding: .day, value: -7,  to: today)!

        let template = makePlan(recipeName: "Pasta", date: fourteenDaysAgo, mealTime: .dinner)
        sut.addMealPlan(template)
        sut.toggleRecurring(template)

        let start = weekStart(containing: sevenDaysAgo)
        sut.propagateRecurring(toWeekStarting: start)
        sut.propagateRecurring(toWeekStarting: start)

        let count = sut.mealPlans.filter {
            cal.isDate($0.date, inSameDayAs: sevenDaysAgo) && $0.mealTime == .dinner
        }.count
        #expect(count == 1)
    }

    @Test func propagateRecurring_doesNothingWithNoTemplates() {
        let sut = makeManager()
        sut.propagateRecurring(toWeekStarting: Date())
        #expect(sut.mealPlans.isEmpty)
    }

    // MARK: clearOldMealPlans

    @Test func clearOldMealPlans_preservesRecurringEntries() {
        let cal = Calendar.current
        let sut = makeManager()

        let fourteenDaysAgo = cal.date(byAdding: .day, value: -14, to: Date())!
        let recurring = makePlan(recipeName: "Recurring", date: fourteenDaysAgo, mealTime: .dinner)
        sut.addMealPlan(recurring)
        sut.toggleRecurring(recurring)

        sut.addMealPlan(makePlan(recipeName: "Old One-Off", date: fourteenDaysAgo, mealTime: .lunch))

        sut.clearOldMealPlans()

        #expect(sut.mealPlans.contains { $0.recipeName == "Recurring" })
        #expect(!sut.mealPlans.contains { $0.recipeName == "Old One-Off" })
    }

    // MARK: Codable round-trip

    @Test func isRecurring_roundTripsJSON() throws {
        let plan = makePlan(isRecurring: true)
        let data = try JSONEncoder().encode(plan)
        let decoded = try JSONDecoder().decode(MealPlanModel.self, from: data)
        #expect(decoded.isRecurring == true)
        #expect(decoded.id == plan.id)
    }

    @Test func isRecurring_defaultsFalseForLegacyJSON() throws {
        // Simulates JSON written before the isRecurring field was added
        let legacyJSON = """
        {"id":"00000000-0000-0000-0000-000000000001",
         "recipeId":"00000000-0000-0000-0000-000000000002",
         "recipeName":"Pasta","date":1000000,"mealTime":"Dinner","servings":4,
         "isCompleted":false,"createdDate":999999}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(MealPlanModel.self, from: legacyJSON)
        #expect(decoded.isRecurring == false)
    }
}

// MARK: - Removal persistence

@MainActor
@Suite("Meal plan removal persistence")
struct MealPlanRemovalPersistenceTests {

    @Test("Removing a slot persists, so a fresh manager on the same store doesn't see it")
    func removeBySlot_persistsAcrossReload() throws {
        let storage = LocalStore(userDefaults: try #require(UserDefaults(suiteName: UUID().uuidString)))
        let date = Date()
        let sut = MealPlanningManager(storage: storage)
        sut.addMealPlan(MealPlanModel(recipeId: UUID(), recipeName: "Porridge", date: date, mealTime: .breakfast))
        sut.addMealPlan(MealPlanModel(recipeId: UUID(), recipeName: "Soup", date: date, mealTime: .lunch))

        sut.removeMealPlan(for: date, mealTime: .breakfast)

        let reloaded = MealPlanningManager(storage: storage)
        #expect(reloaded.mealPlans.map(\.recipeName) == ["Soup"])
    }
}
