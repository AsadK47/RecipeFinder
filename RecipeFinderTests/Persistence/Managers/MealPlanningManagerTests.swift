import XCTest
import Testing
@testable import RecipeFinder

@MainActor
final class MealPlanningManagerTests: XCTestCase {

    private var storage: LocalStore!
    private var sut: MealPlanningManager!
    private var mealPlanStore: InMemoryMealPlanStore!
    private let recipeId = UUID()

    override func setUp() async throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        storage = LocalStore(userDefaults: defaults)
        mealPlanStore = InMemoryMealPlanStore()
        sut = MealPlanningManager(storage: storage, mealPlanStore: mealPlanStore)
    }

    override func tearDown() async throws {
        sut = nil
        mealPlanStore = nil
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
        let sut2 = MealPlanningManager(storage: storage, mealPlanStore: mealPlanStore)
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
        sut.addMealPlan(makePlan(recipeId: a.id, recipeName: a.name, date: d1, mealTime: .dinner, servings: 1))
        sut.addMealPlan(makePlan(recipeId: b.id, recipeName: b.name, date: d2, mealTime: .dinner, servings: 1))
        sut.addMealPlan(makePlan(recipeId: c.id, recipeName: c.name, date: d3, mealTime: .dinner, servings: 1))

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
        mealTime: MealTime = .breakfast,
        servings: Int = 4
    ) -> MealPlanModel {
        MealPlanModel(
            recipeId: recipeId ?? self.recipeId,
            recipeName: recipeName,
            date: date,
            mealTime: mealTime,
            servings: servings
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

    @Test("preserves custom order and slots a new meal ahead of the first later one")
    func preservesCustomOrderAndSlotsNewByTime() {
        // A 3pm snack goes ahead of the dragged-up 7pm dinner; the dragged order of the rest stays.
        let result = MealPlanningManager.sortedOrderedMealTimes(
            existing: [.dinner, .breakfast, .lunch],
            selected: [.breakfast, .dinner, .lunch, .snack]
        )
        #expect(result == [.snack, .dinner, .breakfast, .lunch])
    }

    @Test("a day opens in time order: a 3pm snack sits between lunch and dinner")
    func snackSitsBetweenLunchAndDinner() {
        #expect(MealPlanningManager.sortedOrderedMealTimes(existing: [], selected: [.dinner, .snack, .lunch, .breakfast])
            == [.breakfast, .lunch, .snack, .dinner])
    }

    @Test("a reminder time the cook set orders the day")
    func reminderTimesOrderTheDay() {
        // A late breakfast (brunch at 12:30) after an early lunch at 12:00.
        let minutes: [MealTime: Int] = [.breakfast: 12 * 60 + 30, .lunch: 12 * 60]
        let result = MealPlanningManager.sortedOrderedMealTimes(
            existing: [], selected: [.breakfast, .lunch]
        ) { minutes[$0] ?? $0.defaultMinuteOfDay }
        #expect(result == [.lunch, .breakfast])
    }

    @Test("a meal added to a day slots in by time, ahead of later meals")
    func addedMealSlotsInByTime() {
        // Owner 2026-11-22: dinner from Plan my week, then lunch added → lunch must show above dinner.
        #expect(MealPlanningManager.sortedOrderedMealTimes(existing: [.dinner], selected: [.dinner, .lunch])
            == [.lunch, .dinner])
        #expect(MealPlanningManager.sortedOrderedMealTimes(existing: [.lunch, .dinner], selected: [.breakfast, .lunch, .dinner])
            == [.breakfast, .lunch, .dinner])
    }

    @Test("a meal added after a drag keeps the dragged order")
    func addedMealKeepsDraggedOrder() {
        #expect(MealPlanningManager.sortedOrderedMealTimes(existing: [.dinner, .lunch], selected: [.breakfast, .lunch, .dinner])
            == [.breakfast, .dinner, .lunch])
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
        ), mealPlanStore: InMemoryMealPlanStore())
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
        let mealPlanStore = InMemoryMealPlanStore()
        let sut = MealPlanningManager(storage: storage, mealPlanStore: mealPlanStore)
        sut.addMealPlan(MealPlanModel(recipeId: UUID(), recipeName: "Porridge", date: date, mealTime: .breakfast))
        sut.addMealPlan(MealPlanModel(recipeId: UUID(), recipeName: "Soup", date: date, mealTime: .lunch))

        sut.removeMealPlan(for: date, mealTime: .breakfast)

        let reloaded = MealPlanningManager(storage: storage, mealPlanStore: mealPlanStore)
        #expect(reloaded.mealPlans.map(\.recipeName) == ["Soup"])
    }
}

// MARK: - Week shopping summary servings

@MainActor
@Suite("Week shopping summary scales to planned servings")
struct WeekShoppingSummaryServingsTests {

    private func makeRecipe(baseServings: Int) -> RecipeModel {
        RecipeModel(
            name: "Stew", category: "Test", difficulty: "Basic", prepTime: "5 min", cookingTime: "5 min",
            baseServings: baseServings, ingredients: [Ingredient(baseQuantity: 200, unit: "g", name: "beef")],
            prePrepInstructions: [], instructions: [], notes: ""
        )
    }

    private func summary(planned servings: Int, baseServings: Int) -> WeekShoppingSummary {
        let sut = MealPlanningManager(storage: LocalStore(
            userDefaults: UserDefaults(suiteName: UUID().uuidString)!
        ), mealPlanStore: InMemoryMealPlanStore())
        let recipe = makeRecipe(baseServings: baseServings)
        let start = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        sut.addMealPlan(MealPlanModel(
            recipeId: recipe.id, recipeName: recipe.name, date: start, mealTime: .dinner, servings: servings
        ))
        return sut.weekShoppingSummary(forWeekStarting: start, recipes: [recipe])
    }

    @Test(arguments: [(2, 2, 200), (4, 2, 400), (1, 2, 100)])
    func buysForPlannedServings(planned: Int, base: Int, expectedGrams: Int) {
        let beef = summary(planned: planned, baseServings: base).items.first { $0.name.lowercased().contains("beef") }
        #expect(beef?.quantity == expectedGrams)
        #expect(beef?.unit == "g")
    }

    @Test func zeroBaseServingsFallsBackToRecipeAmounts() {
        let beef = summary(planned: 4, baseServings: 0).items.first { $0.name.lowercased().contains("beef") }
        #expect(beef?.quantity == 200)
    }
}

/// Owner 2026-11-20: "can't clear old plans" — Clear Past Plans takes every plan before today off the week. Cooking
/// history lives on the recipe (`cookCount`, `lastCookedAt`), so clearing a plan loses nothing cooked.
@MainActor
@Suite("Clear past plans")
struct ClearPastPlansTests {
    private let calendar = Calendar.current

    private func makeManager(_ plans: [MealPlanModel]) -> MealPlanningManager {
        makeManager(storage: LocalStore(userDefaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard),
                    store: InMemoryMealPlanStore(plans))
    }

    private func makeManager(storage: LocalStore, store: InMemoryMealPlanStore) -> MealPlanningManager {
        MealPlanningManager(storage: storage, mealPlanStore: store,
                            reminders: FakeMealReminderScheduler(), planNudges: FakePlanNudgeScheduler())
    }

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: Date())) ?? Date()
    }

    private func plan(_ name: String, on date: Date, _ mealTime: MealTime = .dinner, recurring: Bool = false) -> MealPlanModel {
        MealPlanModel(recipeId: UUID(), recipeName: name, date: date, mealTime: mealTime, isRecurring: recurring)
    }

    @Test func yesterdaysPlanIsCleared() {
        let sut = makeManager([plan("Yesterday", on: day(-1)), plan("Three days ago", on: day(-3), .lunch)])
        sut.clearOldMealPlans()
        #expect(sut.mealPlans.isEmpty)
    }

    @Test func todayAndLaterStay() {
        let sut = makeManager([plan("Tonight", on: day(0)), plan("Tomorrow", on: day(1)), plan("Gone", on: day(-1))])
        sut.clearOldMealPlans()
        #expect(Set(sut.mealPlans.map(\.recipeName)) == ["Tonight", "Tomorrow"])
    }

    @Test func pastCountMatchesWhatClears() {
        let sut = makeManager([plan("A", on: day(-1)), plan("B", on: day(-20), .lunch), plan("C", on: day(2))])
        #expect(sut.pastPlanCount(keepingCookedIn: []) == 2)
        sut.clearOldMealPlans()
        #expect(sut.pastPlanCount(keepingCookedIn: []) == 0)
    }

    @Test func weeklyDinnerKeepsOnlyItsNewestCopy() {
        let sut = makeManager([
            plan("Pasta", on: day(-14), recurring: true),
            plan("Pasta", on: day(-7), recurring: true),
        ])
        sut.clearOldMealPlans()
        #expect(sut.mealPlans.map(\.date) == [day(-7)])
    }

    @Test func weeklyDinnerWithACopyAheadClearsEveryPastCopy() {
        let sut = makeManager([
            plan("Pasta", on: day(-7), recurring: true),
            plan("Pasta", on: day(0), recurring: true),
        ])
        sut.clearOldMealPlans()
        #expect(sut.mealPlans.map(\.date) == [day(0)])
    }

    @Test func cookedPastDinnersStay() {
        var cooked = plan("Cooked", on: day(-2))
        cooked.isCompleted = true
        let sut = makeManager([cooked, plan("Skipped", on: day(-2), .lunch)])
        sut.clearPastMealPlans(keepingCookedIn: [])
        #expect(sut.mealPlans.map(\.recipeName) == ["Cooked"])
    }

    @Test func clearedPlansStayGoneAfterReload() {
        let store = InMemoryMealPlanStore([plan("Yesterday", on: day(-1))])
        let storage = LocalStore(userDefaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
        makeManager(storage: storage, store: store).clearOldMealPlans()
        #expect(makeManager(storage: storage, store: store).mealPlans.isEmpty)
    }
}

/// Plan bug hunt 2026-11-20 (two reviewers agreed on each): weekly meals, their reminders, synced twins and shopping from today.
@MainActor
@Suite("Plan bug hunt")
struct PlanBugHuntTests {
    private let calendar = Calendar.current
    private let storage = LocalStore(userDefaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
    private let reminders = FakeMealReminderScheduler()

    private func makeManager(_ store: InMemoryMealPlanStore = InMemoryMealPlanStore()) -> MealPlanningManager {
        MealPlanningManager(
            storage: storage, mealPlanStore: store,
            badgeManager: BadgeManager(storage: storage, badgeStore: InMemoryEarnedBadgeStore()),
            reminders: reminders, planNudges: FakePlanNudgeScheduler()
        )
    }

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: Date())) ?? Date()
    }

    private func weekStart(containing date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
    }

    private func clock(_ hour: Int) -> Date {
        calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
    }

    /// A weekly dinner started two weeks ago and copied into last week and this week.
    private func weeklyDinner(_ sut: MealPlanningManager, reminder: Date? = nil) {
        sut.addMealPlan(MealPlanModel(recipeId: UUID(), recipeName: "Pasta", date: day(-14), mealTime: .dinner,
                                      isRecurring: true, reminderTime: reminder))
        sut.propagateRecurring(toWeekStarting: weekStart(containing: day(-7)))
        sut.propagateRecurring(toWeekStarting: weekStart(containing: day(0)))
    }

    /// Ids whose last call was a schedule: `syncReminder` always cancels first, so equal counts mean it's pending.
    private var liveReminders: Set<String> {
        Set(reminders.scheduled.map(\.id).filter { id in
            reminders.scheduled.filter { $0.id == id }.count == reminders.cancelled.filter { $0 == id }.count
        })
    }

    @Test func aRemovedWeeklyCopyStaysGone() {
        let sut = makeManager()
        weeklyDinner(sut)
        sut.removeMealPlan(for: day(0), mealTime: .dinner)
        sut.propagateRecurring(toWeekStarting: weekStart(containing: day(0)))
        #expect(sut.mealPlan(for: day(0), mealTime: .dinner) == nil)
    }

    @Test func stopRepeatingOnAnyCopyEndsTheSeries() throws {
        let sut = makeManager()
        weeklyDinner(sut)
        let thisWeek = try #require(sut.mealPlan(for: day(0), mealTime: .dinner))
        sut.toggleRecurring(thisWeek)
        sut.propagateRecurring(toWeekStarting: weekStart(containing: day(7)))
        #expect(sut.mealPlan(for: day(7), mealTime: .dinner) == nil)
    }

    /// Reviewer 2026-11-21: a later copy sitting *before* the tapped one (iCloud / restore order) shifted the index,
    /// so Stop Repeating read past the end of the array and crashed.
    @Test func stopRepeatingWithALaterCopyListedFirstKeepsThisWeeksMeal() throws {
        let sut = makeManager()
        let recipe = UUID()
        let nextWeek = MealPlanModel(recipeId: recipe, recipeName: "Pasta", date: day(7), mealTime: .dinner,
                                     isRecurring: true, reminderTime: clock(19))
        sut.addMealPlan(nextWeek)
        sut.addMealPlan(MealPlanModel(recipeId: recipe, recipeName: "Pasta", date: day(0), mealTime: .dinner,
                                      isRecurring: true, reminderTime: clock(19)))
        let thisWeek = try #require(sut.mealPlan(for: day(0), mealTime: .dinner))
        sut.toggleRecurring(thisWeek)
        let kept = try #require(sut.mealPlan(for: day(0), mealTime: .dinner))
        #expect(!kept.isRecurring)
        #expect(sut.mealPlan(for: day(7), mealTime: .dinner) == nil)
        // The removed copy's weekly reminder goes with it.
        #expect(!liveReminders.contains("meal-\(nextWeek.id.uuidString)"))
    }

    @Test func aWeeklySeriesHasOneLiveReminder() {
        let sut = makeManager()
        weeklyDinner(sut, reminder: clock(19))
        #expect(liveReminders.count == 1)
    }

    /// Reviewer 2026-11-21: a backup restore brought next week's copy of a weekly dinner, but only the added copy was
    /// re-synced — this week's copy kept its weekly reminder too, so the dinner reminder fired twice a week.
    @Test func restoringANewerWeeklyCopyLeavesOneLiveReminder() {
        let sut = makeManager()
        weeklyDinner(sut, reminder: clock(19))
        let nextWeek = MealPlanModel(recipeId: UUID(), recipeName: "Pasta", date: day(7), mealTime: .dinner,
                                     isRecurring: true, reminderTime: clock(19))
        sut.merge([nextWeek])
        #expect(liveReminders == ["meal-\(nextWeek.id.uuidString)"])
    }

    /// Reviewer + challenger 2026-11-22: a backup taken before the reminder was set holds the newer copy with none;
    /// once it's the newest it would silence the series, so it takes the time this device's series already has.
    @Test(arguments: [nil, 18] as [Int?])
    func aRestoredWeeklyCopyKeepsThisDevicesReminderTime(restoredHour: Int?) throws {
        let sut = makeManager()
        weeklyDinner(sut, reminder: clock(19))
        let nextWeek = MealPlanModel(recipeId: UUID(), recipeName: "Pasta", date: day(7), mealTime: .dinner,
                                     isRecurring: true, reminderTime: restoredHour.map(clock))
        sut.merge([nextWeek])
        #expect(liveReminders == ["meal-\(nextWeek.id.uuidString)"])
        let ringing = try #require(reminders.scheduled.last { $0.id == "meal-\(nextWeek.id.uuidString)" })
        #expect(calendar.component(.hour, from: ringing.date) == 19)
    }

    @Test func removingAWeeklyDinnerLeavesNoReminder() {
        let sut = makeManager()
        weeklyDinner(sut, reminder: clock(19))
        sut.removeMealPlan(for: day(0), mealTime: .dinner)
        #expect(liveReminders.isEmpty)
    }

    @Test func twoDevicesPlanningOneNightKeepOneDinner() {
        let store = InMemoryMealPlanStore()
        storage.set(true, forKey: SyncPreference.key)
        let sut = makeManager(store)
        sut.addMealPlan(MealPlanModel(recipeId: UUID(), recipeName: "Mine", date: day(1), mealTime: .dinner))
        // The other device's dinner for the same night arrives through iCloud.
        store.plans.append(MealPlanModel(recipeId: UUID(), recipeName: "Theirs", date: day(1), mealTime: .dinner))
        sut.reload()
        #expect(sut.mealPlans(for: day(1)).count == 1)
    }

    @Test func aPlanDeletedOnAnotherDeviceCancelsItsReminder() {
        let store = InMemoryMealPlanStore()
        storage.set(true, forKey: SyncPreference.key)
        let sut = makeManager(store)
        let plan = MealPlanModel(recipeId: UUID(), recipeName: "Dal", date: day(2), mealTime: .dinner, reminderTime: clock(18))
        sut.addMealPlan(plan)
        store.plans.removeAll()   // deleted on the other device
        sut.reload()
        #expect(!liveReminders.contains("meal-\(plan.id.uuidString)"))
    }

    /// Groceries' "From your plan" starts the seven days at now, so meals already eaten aren't shopped for.
    @Test func shoppingFromTodayLeavesOutMealsAlreadyPast() {
        let recipe = RecipeModel(
            name: "Dal", category: "Main", difficulty: "Basic", prepTime: "5 min", cookingTime: "20 min",
            baseServings: 2, ingredients: [Ingredient(baseQuantity: 200, unit: "g", name: "lentils")],
            prePrepInstructions: [], instructions: [], notes: ""
        )
        let sut = makeManager()
        sut.addMealPlan(MealPlanModel(recipeId: recipe.id, recipeName: recipe.name, date: day(-1), mealTime: .dinner, servings: 2))
        sut.addMealPlan(MealPlanModel(recipeId: recipe.id, recipeName: recipe.name, date: day(1), mealTime: .lunch, servings: 2))
        let summary = sut.weekShoppingSummary(forWeekStarting: Date(), recipes: [recipe])
        #expect(summary.mealsCovered == 1)
    }

    @Test func madeItMarksThatDaysPlanCooked() {
        let sut = makeManager()
        let recipeID = UUID()
        sut.addMealPlan(MealPlanModel(recipeId: recipeID, recipeName: "Dal", date: day(0), mealTime: .dinner))
        sut.addMealPlan(MealPlanModel(recipeId: recipeID, recipeName: "Dal", date: day(2), mealTime: .dinner))
        sut.markCooked(recipeID: recipeID, on: Date())
        #expect(sut.mealPlan(for: day(0), mealTime: .dinner)?.isCompleted == true)
        #expect(sut.mealPlan(for: day(2), mealTime: .dinner)?.isCompleted == false)
    }

    // MARK: Review round 1 (challenger + deep reviewer)

    @Test func madeItKeepsTheWeeklyReminderRinging() throws {
        let sut = makeManager()
        weeklyDinner(sut, reminder: clock(19))
        let tonight = try #require(sut.mealPlan(for: day(0), mealTime: .dinner))
        sut.markCooked(recipeID: tonight.recipeId, on: Date())
        #expect(liveReminders.count == 1)
    }

    @Test func stoppingASeriesTakesItsLaterCopiesOff() throws {
        let sut = makeManager()
        weeklyDinner(sut)
        sut.propagateRecurring(toWeekStarting: weekStart(containing: day(7)))
        let thisWeek = try #require(sut.mealPlan(for: day(0), mealTime: .dinner))
        sut.toggleRecurring(thisWeek)
        #expect(sut.mealPlan(for: day(7), mealTime: .dinner) == nil)
        #expect(sut.mealPlan(for: day(0), mealTime: .dinner) != nil)
    }

    @Test func changingAWeeklyReminderOnAnEarlierCopyMovesTheSeriesReminder() throws {
        let sut = makeManager()
        weeklyDinner(sut, reminder: clock(19))
        sut.propagateRecurring(toWeekStarting: weekStart(containing: day(7)))
        var thisWeek = try #require(sut.mealPlan(for: day(0), mealTime: .dinner))
        thisWeek.reminderTime = clock(18)
        sut.updateMealPlan(thisWeek)
        let live = try #require(liveReminders.first)
        #expect(liveReminders.count == 1)
        let ringing = try #require(reminders.scheduled.last { $0.id == live })
        #expect(calendar.component(.hour, from: ringing.date) == 18)
    }

    @Test func aTwinTheCookPickedBeatsAnAutomaticWeeklyCopy() {
        let picked = MealPlanModel(recipeId: UUID(), recipeName: "Curry", date: day(7), mealTime: .dinner,
                                   createdDate: day(-3))
        let copied = MealPlanModel(recipeId: UUID(), recipeName: "Pasta", date: day(7), mealTime: .dinner,
                                   isRecurring: true, createdDate: day(0))
        #expect(MealPlanningManager.foldRank(picked) < MealPlanningManager.foldRank(copied))
    }

    @Test func aFoldedTwinKeepsTheCookedMarkAndReminder() {
        let kept = MealPlanModel(recipeId: UUID(), recipeName: "Curry", date: day(-1), mealTime: .dinner)
        let other = MealPlanModel(recipeId: UUID(), recipeName: "Curry", date: day(-1), mealTime: .dinner,
                                  isCompleted: true, reminderTime: clock(18))
        let folded = MealPlanningManager.foldTwins(kept, [other])
        #expect(folded.isCompleted)
        #expect(folded.reminderTime == clock(18))
        #expect(folded.id == kept.id)
    }

    @Test func aWeeklyDinnerCountsAsPlannedOnAWeekNotYetFilled() {
        let weekly = MealPlanModel(recipeId: UUID(), recipeName: "Pasta", date: day(-7), mealTime: .dinner,
                                   isRecurring: true)
        #expect(MealPlanModel.hasDinner(on: day(7), plans: [weekly]))
        #expect(!MealPlanModel.hasDinner(on: day(8), plans: [weekly]))
        #expect(!MealPlanModel.hasDinner(on: day(7), plans: [MealPlanModel(
            recipeId: UUID(), recipeName: "Once", date: day(-7), mealTime: .dinner)]))
    }
}

/// Pins the pure fill rule `propagateRecurring` now delegates to, so the extraction can't change what a week gets.
@Suite("Weekly copies for a week")
struct WeeklyCopiesTests {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/London") ?? .gmt
        return cal
    }

    /// Monday 23 Nov 2026 + `days`.
    private func day(_ days: Int) -> Date {
        let monday = calendar.date(from: DateComponents(year: 2026, month: 11, day: 23)) ?? .distantPast
        return calendar.date(byAdding: .day, value: days, to: monday) ?? .distantPast
    }

    private func plan(_ name: String, on date: Date, _ mealTime: MealTime = .dinner, weekly: Bool = true,
                      servings: Int = 2, reminder: Date? = nil) -> MealPlanModel {
        MealPlanModel(recipeId: UUID(), recipeName: name, date: date, mealTime: mealTime, servings: servings,
                      isRecurring: weekly, reminderTime: reminder)
    }

    @Test func anEmptyNightTakesTheNewestCopyOfItsSeries() {
        let reminder = day(-14)
        let plans = [plan("Old", on: day(-14)), plan("New", on: day(-7), servings: 4, reminder: reminder)]
        let copies = MealPlanningManager.weeklyCopies(of: plans, forWeekStarting: day(0), calendar: calendar)
        #expect(copies.count == 1)
        let copy = copies.first
        #expect(copy?.recipeName == "New")
        #expect(copy.map { calendar.isDate($0.date, inSameDayAs: day(0)) } == true)
        #expect(copy?.isRecurring == true)
        #expect(copy?.servings == 4)
        #expect(copy?.reminderTime == reminder)
    }

    @Test func aNightAlreadyPlannedIsLeftAlone() {
        let plans = [plan("Weekly", on: day(-7)), plan("Picked", on: day(0), weekly: false)]
        #expect(MealPlanningManager.weeklyCopies(of: plans, forWeekStarting: day(0), calendar: calendar).isEmpty)
    }

    @Test func oneOffsAndCopiesFromLaterWeeksAreNotTemplates() {
        // "Later" shares Wednesday with the week's empty day(2): only the `date < start` rule keeps it out.
        let plans = [plan("Once", on: day(-7), weekly: false), plan("Later", on: day(9))]
        #expect(MealPlanningManager.weeklyCopies(of: plans, forWeekStarting: day(0), calendar: calendar).isEmpty)
    }

    @Test func eachMealTimeFillsOnItsOwnWeekday() {
        let plans = [plan("Brunch", on: day(-2), .lunch), plan("Curry", on: day(-4), .dinner)]
        let copies = MealPlanningManager.weeklyCopies(of: plans, forWeekStarting: day(0), calendar: calendar)
        let slots = Set(copies.map { "\($0.recipeName)-\(calendar.component(.weekday, from: $0.date))-\($0.mealTime)" })
        #expect(slots == ["Brunch-\(calendar.component(.weekday, from: day(5)))-\(MealTime.lunch)",
                          "Curry-\(calendar.component(.weekday, from: day(3)))-\(MealTime.dinner)"])
    }

    @Test func aWeekAcrossTheAutumnClockChangeFillsTheRightNights() {
        // UK clocks go back on Sunday 25 Oct 2026, so this week has a 25-hour day: counting 24-hour steps from
        // Thursday would land twice on the Sunday and never reach Monday.
        let date = { (day: Int) in self.calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: 18))
            ?? .distantPast }
        let plans = [plan("Monday curry", on: date(19))]
        let copies = MealPlanningManager.weeklyCopies(of: plans, forWeekStarting: date(22), calendar: calendar)
        #expect(copies.count == 1)
        #expect(copies.first.map { calendar.isDate($0.date, inSameDayAs: date(26)) } == true)
    }
}

// MARK: - Time of day

@MainActor
@Suite("A day's meals in time order")
struct MealTimeOfDayTests {

    private func at(_ hour: Int, _ minute: Int = 0) -> Date? {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date())
    }

    @Test func aMealWithoutAReminderIsEatenAtItsUsualTime() {
        let plan = MealPlanModel(recipeId: UUID(), recipeName: "Dal", date: Date(), mealTime: .snack)
        #expect(plan.minuteOfDay() == 15 * 60)
    }

    @Test func aReminderTimeIsWhenTheMealIsEaten() {
        let plan = MealPlanModel(
            recipeId: UUID(), recipeName: "Dal", date: Date(), mealTime: .dinner, reminderTime: at(17, 45)
        )
        #expect(plan.minuteOfDay() == 17 * 60 + 45)
    }

    @Test func slotOrderBreaksATie() {
        let lunch = MealPlanModel(recipeId: UUID(), recipeName: "Dal", date: Date(), mealTime: .lunch, reminderTime: at(15))
        let snack = MealPlanModel(recipeId: UUID(), recipeName: "Dal", date: Date(), mealTime: .snack)
        #expect(MealPlanModel.eatenBefore(lunch, snack))
        #expect(!MealPlanModel.eatenBefore(snack, lunch))
    }

    @Test func mealPlansForADayComeInTimeOrder() throws {
        let sut = MealPlanningManager(
            storage: LocalStore(userDefaults: try #require(UserDefaults(suiteName: UUID().uuidString))),
            mealPlanStore: InMemoryMealPlanStore(), reminders: FakeMealReminderScheduler()
        )
        let day = try #require(Calendar.current.date(byAdding: .day, value: 2, to: Date()))
        for mealTime in [MealTime.dinner, .snack, .lunch] {
            sut.addMealPlan(MealPlanModel(recipeId: UUID(), recipeName: "Dal", date: day, mealTime: mealTime))
        }
        #expect(sut.mealPlans(for: day).map(\.mealTime) == [.lunch, .snack, .dinner])
    }
}

// MARK: - Undo a take-off

@MainActor
@Suite("Undo taking a meal off")
struct UndoTakeOffTests {

    private let reminders = FakeMealReminderScheduler()
    /// Fresh per test (Swift Testing builds a new suite value for each), so no test touches the shared defaults.
    private let storage: LocalStore
    /// Today and the next two weeks, from midnight; `day(n)` reads one.
    private let days: [Date]

    init() throws {
        storage = LocalStore(userDefaults: try #require(UserDefaults(suiteName: UUID().uuidString)))
        let today = Calendar.current.startOfDay(for: Date())
        days = try (0...14).map { try #require(Calendar.current.date(byAdding: .day, value: $0, to: today)) }
    }

    private func makeManager() -> MealPlanningManager {
        MealPlanningManager(storage: storage, mealPlanStore: InMemoryMealPlanStore(), reminders: reminders)
    }

    private func day(_ offset: Int) -> Date {
        days[offset]
    }

    private func plan(_ name: String, on date: Date, recurring: Bool = false, recipe: UUID = UUID()) -> MealPlanModel {
        MealPlanModel(
            recipeId: recipe, recipeName: name, date: date, mealTime: .dinner, isRecurring: recurring,
            reminderTime: Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: date)
        )
    }

    /// What was scheduled after the `count`-th entry (the fake's log only grows).
    private func scheduled(after count: Int, id: UUID) -> FakeMealReminderScheduler.Scheduled? {
        reminders.scheduled.dropFirst(count).last { $0.id == "meal-\(id.uuidString)" }
    }

    @Test func undoPutsAOneOffBack() {
        let sut = makeManager()
        let dal = plan("Dal", on: day(2))
        sut.addMealPlan(dal)
        let before = sut.plansChangedByRemoving(dal)
        sut.removeMealPlan(dal)
        let afterRemoval = reminders.scheduled.count

        sut.restore(before)

        #expect(sut.mealPlans.map(\.id) == [dal.id])
        #expect(scheduled(after: afterRemoval, id: dal.id) != nil)
    }

    @Test func undoBringsAWeeklySeriesBackRepeating() {
        let sut = makeManager()
        let recipe = UUID()
        let tonight = plan("Tacos", on: day(2), recurring: true, recipe: recipe)
        let nextWeek = plan("Tacos", on: day(9), recurring: true, recipe: recipe)
        sut.addMealPlan(tonight)
        sut.addMealPlan(nextWeek)
        let before = sut.plansChangedByRemoving(tonight)
        #expect(Set(before.map(\.id)) == [tonight.id, nextWeek.id])
        sut.removeMealPlan(tonight) // stops the series and drops next week's copy
        let afterRemoval = reminders.scheduled.count

        sut.restore(before)

        #expect(Set(sut.mealPlans.map(\.id)) == [tonight.id, nextWeek.id])
        let allRepeat = sut.mealPlans.allSatisfy { $0.isRecurring }
        #expect(allRepeat)
        #expect(scheduled(after: afterRemoval, id: nextWeek.id)?.repeatsWeekly == true)
    }

    @Test func undoTakingOffALaterCopyMakesTheEarlierOneRepeatAgain() {
        let sut = makeManager()
        let recipe = UUID()
        let tonight = plan("Tacos", on: day(2), recurring: true, recipe: recipe)
        let nextWeek = plan("Tacos", on: day(9), recurring: true, recipe: recipe)
        sut.addMealPlan(tonight)
        sut.addMealPlan(nextWeek)
        let before = sut.plansChangedByRemoving(nextWeek)
        sut.removeMealPlan(nextWeek) // tonight's copy stays, as a one-off with its own reminder
        #expect(sut.mealPlans.first { $0.id == tonight.id }?.isRecurring == false)
        let afterRemoval = reminders.scheduled.count

        sut.restore(before)

        #expect(sut.mealPlans.first { $0.id == tonight.id }?.isRecurring == true)
        #expect(scheduled(after: afterRemoval, id: nextWeek.id)?.repeatsWeekly == true)
        #expect(scheduled(after: afterRemoval, id: tonight.id) == nil) // the series rings once, from its newest copy
    }

    @Test func undoLeavesANightPlannedSinceAlone() {
        let sut = makeManager()
        let dal = plan("Dal", on: day(2))
        sut.addMealPlan(dal)
        let before = sut.plansChangedByRemoving(dal)
        sut.removeMealPlan(dal)
        let pasta = plan("Pasta", on: day(2))
        sut.addMealPlan(pasta)

        let skipped = sut.restore(before)

        #expect(sut.mealPlans.map(\.id) == [pasta.id])
        #expect(skipped.map(\.id) == [dal.id]) // so Undo can say the dal stayed off
    }

    @Test func undoDoesNotCountANightReplannedWithTheSameDish() {
        let sut = makeManager()
        let recipe = UUID()
        let dal = plan("Dal", on: day(2), recipe: recipe)
        sut.addMealPlan(dal)
        let before = sut.plansChangedByRemoving(dal)
        sut.removeMealPlan(dal)
        let dalAgain = plan("Dal", on: day(2), recipe: recipe)
        sut.addMealPlan(dalAgain)

        let skipped = sut.restore(before)

        #expect(skipped.isEmpty)
        #expect(sut.mealPlans.map(\.id) == [dalAgain.id])
    }

    @Test func undoThatPutsEverythingBackSkipsNothing() {
        let sut = makeManager()
        let dal = plan("Dal", on: day(2))
        sut.addMealPlan(dal)
        let before = sut.plansChangedByRemoving(dal)
        sut.removeMealPlan(dal)

        let skipped = sut.restore(before)

        #expect(skipped.isEmpty)
    }

    @Test func undoSkipsAOneOffWhoseNightAWeeklyCopyRefilled() throws {
        let sut = makeManager()
        let recipe = UUID()
        let lastWeek = plan("Tacos", on: day(2), recurring: true, recipe: recipe)
        let dal = plan("Dal", on: day(9))
        sut.addMealPlan(lastWeek)
        sut.addMealPlan(dal)
        let before = sut.plansChangedByRemoving(dal)
        sut.removeMealPlan(dal)
        sut.propagateRecurring(toWeekStarting: Calendar.current.startOfDay(for: day(9)))
        let refilled = try #require(sut.mealPlan(for: day(9), mealTime: .dinner))
        #expect(refilled.recipeName == "Tacos")

        let skipped = sut.restore(before)

        #expect(skipped.map(\.id) == [dal.id])
        #expect(sut.mealPlan(for: day(9), mealTime: .dinner)?.recipeName == "Tacos")
    }

    // MARK: - Take-off removes the tapped meal, not whatever now fills its night

    @Test func takeOffRemovesTheMealAndReturnsItForUndo() {
        let sut = makeManager()
        let dal = plan("Dal", on: day(2))
        sut.addMealPlan(dal)

        let tookOff = sut.takeOff(dal)

        #expect(tookOff?.removed.id == dal.id)
        #expect(tookOff?.before.map(\.id) == [dal.id])
        #expect(sut.mealPlans.isEmpty)
    }

    @Test func aStaleTakeOffLeavesTheDishPlannedSince() {
        let sut = makeManager()
        let dal = plan("Dal", on: day(2))
        sut.addMealPlan(dal)
        sut.takeOff(dal)
        let pasta = plan("Pasta", on: day(2))
        sut.addMealPlan(pasta)

        let tookOff = sut.takeOff(dal) // a second tap from a screen that still showed the dal

        #expect(sut.mealPlans.map(\.id) == [pasta.id])
        #expect(tookOff == nil) // nothing came off, so nothing for Undo
    }

    /// Same dish planned again that night: the slot fallback must not take the new copy for the stale tap's.
    @Test func aStaleTakeOffLeavesTheSameDishPlannedAgainSince() {
        let sut = makeManager()
        let recipe = UUID()
        let dal = plan("Dal", on: day(2), recipe: recipe)
        sut.addMealPlan(dal)
        sut.takeOff(dal)
        let again = plan("Dal", on: day(2), recipe: recipe)
        sut.addMealPlan(again)

        let tookOff = sut.takeOff(dal) // a second tap from a screen that still showed the first dal

        #expect(sut.mealPlans.map(\.id) == [again.id])
        #expect(tookOff == nil)
    }

    @Test func aStaleTakeOffOfAWeeklyMealLeavesTheDishPlannedSince() {
        let sut = makeManager()
        let tacos = plan("Tacos", on: day(2), recurring: true)
        sut.addMealPlan(tacos)
        sut.takeOff(tacos)
        let pasta = plan("Pasta", on: day(2))
        sut.addMealPlan(pasta)

        sut.takeOff(tacos)

        #expect(sut.mealPlans.map(\.id) == [pasta.id])
    }

    @Test func undoAfterAStaleTakeOffKeepsTheDishPlannedSince() {
        let sut = makeManager()
        let dal = plan("Dal", on: day(2))
        sut.addMealPlan(dal)
        let first = sut.takeOff(dal)?.before ?? []
        let pasta = plan("Pasta", on: day(2))
        sut.addMealPlan(pasta)
        let second = sut.takeOff(dal)?.before ?? []

        let skipped = sut.restore(first + second)

        #expect(sut.mealPlans.map(\.id) == [pasta.id])
        #expect(skipped.map(\.id) == [dal.id])
    }

    /// Put back by Undo, then folded into its twin: taking it off again still finds the same dish.
    @Test func aMealPutBackByUndoCanBeTakenOffViaItsFoldTwin() {
        let sut = makeManager()
        let recipe = UUID()
        let dal = plan("Dal", on: day(2), recipe: recipe)
        sut.addMealPlan(dal)
        sut.restore(sut.takeOff(dal)?.before ?? [])
        sut.removeMealPlan(dal) // an iCloud fold keeps the other device's copy instead
        let twin = plan("Dal", on: day(2), recipe: recipe)
        sut.addMealPlan(twin)

        let tookOff = sut.takeOff(dal)

        #expect(tookOff?.removed.id == twin.id)
        #expect(sut.mealPlans.isEmpty)
    }

    /// An iCloud fold kept the other device's copy of the same dish while the hold menu showed ours: it comes off.
    @Test func takeOffFindsTheSameDishWhenAFoldKeptItsTwin() {
        let sut = makeManager()
        let recipe = UUID()
        let kept = plan("Dal", on: day(2), recipe: recipe)
        sut.addMealPlan(kept)
        let held = plan("Dal", on: day(2), recipe: recipe) // folded away; its id is gone

        let tookOff = sut.takeOff(held)

        #expect(sut.mealPlans.isEmpty)
        #expect(tookOff?.removed.id == kept.id)
        #expect(tookOff?.before.map(\.id) == [kept.id])
    }
}
