import Testing
import Foundation
@testable import RecipeFinder

// Groceries writes itself, slice 4: "Still got the coriander?" — asks about perishables At home the plan counts on
// once they've been there longer than they usually keep.
@Suite("StillGotCheck")
struct StillGotCheckTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London") ?? .gmt
        return calendar
    }()

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: 21, hour: 18)) ?? Date()
    }

    private func daysAgo(_ days: Int) -> Date {
        calendar.date(byAdding: .day, value: -days, to: now) ?? now
    }

    private func atHome(_ name: String, _ category: String, daysAgo days: Int) -> KitchenItem {
        KitchenItem(name: name, category: category, dateAdded: daysAgo(days))
    }

    private func summary(_ items: [WeekShoppingSummary.Item]) -> WeekShoppingSummary {
        WeekShoppingSummary(items: items, mealsCovered: 1, missingRecipeNames: [])
    }

    private func need(_ name: String, _ quantity: Int = 1, _ unit: String = "") -> WeekShoppingSummary.Item {
        WeekShoppingSummary.Item(name: name, quantity: quantity, unit: unit)
    }

    private func check(_ needs: [WeekShoppingSummary.Item], _ kitchen: [KitchenItem]) -> StillGotCheck {
        StillGotCheck(summary: summary(needs), kitchenItems: kitchen, now: now, calendar: calendar)
    }

    @Test("Asks about fresh herbs the plan needs once they've been at home longer than they keep")
    func asksAboutOldHerbs() {
        let result = check([need("coriander")], [atHome("Coriander", "Herbs & Fresh Spices", daysAgo: 9)])

        #expect(result.questions.map(\.item.name) == ["Coriander"])
        #expect(result.questions.first?.title == "Still got the coriander?")
    }

    @Test("Doesn't ask about something put away recently")
    func freshItemsAreTrusted() {
        let result = check([need("coriander")], [atHome("Coriander", "Herbs & Fresh Spices", daysAgo: 2)])

        #expect(result.questions.isEmpty)
    }

    @Test("Doesn't ask about pantry staples, however long they've been there")
    func staplesAreTrusted() {
        let result = check([need("rice")], [atHome("Rice", "Grains & Pasta", daysAgo: 200)])

        #expect(result.questions.isEmpty)
    }

    @Test("Doesn't ask about old perishables the plan doesn't need")
    func onlyWhatThePlanNeeds() {
        let result = check([need("onion")], [atHome("Milk", "Dairy & Eggs", daysAgo: 30)])

        #expect(result.questions.isEmpty)
    }

    @Test("Matches the plan's ingredient after normalising the name")
    func matchesNormalisedNames() {
        let result = check([need("Coriander")], [atHome("  coriander ", "Herbs & Fresh Spices", daysAgo: 9)])

        #expect(result.questions.count == 1)
    }

    @Test("Each kind of food keeps for its own time", arguments: [
        ("Herbs & Fresh Spices", 5), ("Produce", 7), ("Vegetables", 7), ("Fruits", 7),
        ("Meat", 3), ("Poultry", 3), ("Seafood", 3), ("Dairy & Eggs", 10), ("Bakery", 4),
    ])
    func keepsForItsOwnTime(category: String, days: Int) {
        #expect(StillGotCheck.keepsDays(category: category) == days)
        #expect(check([need("thing")], [atHome("Thing", category, daysAgo: days)]).questions.isEmpty)
        #expect(check([need("thing")], [atHome("Thing", category, daysAgo: days + 1)]).questions.count == 1)
    }

    @Test("Staple categories never ask", arguments: ["Grains & Pasta", "Frozen", "Canned & Jarred", "Other", "Sweeteners"])
    func staplesNeverAsk(category: String) {
        #expect(StillGotCheck.keepsDays(category: category) == nil)
    }

    @Test("The longest overdue is asked first")
    func longestOverdueFirst() {
        let result = check([need("milk"), need("coriander"), need("chicken")], [
            atHome("Milk", "Dairy & Eggs", daysAgo: 12),          // 2 over
            atHome("Coriander", "Herbs & Fresh Spices", daysAgo: 11), // 6 over
            atHome("Chicken", "Poultry", daysAgo: 7),             // 4 over
        ])

        #expect(result.questions.map(\.item.name) == ["Coriander", "Chicken", "Milk"])
        #expect(result.first?.item.name == "Coriander")
    }

    @Test("Says how long it's been at home", arguments: [(6, "At home for 6 days"), (31, "At home for over a month")])
    func detailSaysHowLong(days: Int, detail: String) {
        let result = check([need("coriander")], [atHome("Coriander", "Herbs & Fresh Spices", daysAgo: days)])

        #expect(result.first?.detail == detail)
    }

    @Test("An item from before put-away dates were kept counts as old, not as days since 2001")
    func undatedItemsAreOld() {
        let item = KitchenItem(name: "Basil", category: "Herbs & Fresh Spices",
                               dateAdded: Date(timeIntervalSinceReferenceDate: 0))
        let result = check([need("basil")], [item])

        #expect(result.first?.detail == "At home for over a month")
    }

    @Test("Carries every line the plan needs for that ingredient")
    func carriesThePlansNeeds() {
        let result = check([need("milk", 200, "ml"), need("onion"), need("milk", 1, "pint")],
                           [atHome("Milk", "Dairy & Eggs", daysAgo: 20)])

        #expect(result.first?.needs == [need("milk", 200, "ml"), need("milk", 1, "pint")])
    }

    // MARK: - Answering

    @MainActor
    private func makeShopping() -> ShoppingListManager {
        let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard
        return ShoppingListManager(storage: LocalStore(userDefaults: defaults), shoppingListStore: InMemoryShoppingListStore())
    }

    private var longAgo: Date { Date(timeIntervalSinceReferenceDate: 0) }

    /// A kitchen whose store already holds `items` (put away whenever their `dateAdded` says).
    @MainActor
    private func makeKitchen(_ items: [KitchenItem] = []) -> KitchenInventoryManager {
        let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard
        return KitchenInventoryManager(storage: LocalStore(userDefaults: defaults), kitchenStore: InMemoryKitchenStore(items))
    }

    @MainActor @Test("No takes it off At home and puts what the plan needs on the list")
    func noMovesItToTheList() throws {
        let kitchen = makeKitchen([KitchenItem(name: "Coriander", category: "Herbs & Fresh Spices", dateAdded: longAgo)])
        let shopping = makeShopping()
        let item = try #require(kitchen.items.first)
        let question = StillGotCheck.Question(item: item, needs: [need("coriander", 2, "bunch")], daysAtHome: 9)

        question.answerNo(kitchen: kitchen, shopping: shopping)

        #expect(!kitchen.hasItem("Coriander"))
        #expect(shopping.items.map { $0.name.lowercased() } == ["coriander"])
        #expect(shopping.items.first?.quantity == 2)
    }

    @MainActor @Test("No never doubles what's already on the list")
    func noNeverDoubles() throws {
        let kitchen = makeKitchen([KitchenItem(name: "Coriander", category: "Herbs & Fresh Spices", dateAdded: longAgo)])
        let shopping = makeShopping()
        shopping.addItem(name: "Coriander", quantity: 2, unit: "bunch", category: nil)
        let item = try #require(kitchen.items.first)
        let question = StillGotCheck.Question(item: item, needs: [need("coriander", 2, "bunch")], daysAtHome: 9)

        question.answerNo(kitchen: kitchen, shopping: shopping)

        #expect(shopping.items.count == 1)
        #expect(shopping.items.first?.quantity == 2)
    }

    @MainActor @Test("Yes keeps it At home and marks it fresh, so the question doesn't come straight back")
    func yesStopsTheQuestion() throws {
        let kitchen = makeKitchen([KitchenItem(name: "Coriander", category: "Herbs & Fresh Spices", dateAdded: longAgo)])
        let item = try #require(kitchen.items.first)
        let plan = summary([need("coriander")])
        #expect(StillGotCheck(summary: plan, kitchenItems: kitchen.items, now: Date()).questions.count == 1)

        StillGotCheck.Question(item: item, needs: [need("coriander")], daysAtHome: 9).answerYes(kitchen: kitchen)

        #expect(kitchen.hasItem("Coriander"))
        #expect(StillGotCheck(summary: plan, kitchenItems: kitchen.items, now: Date()).questions.isEmpty)
    }

    @MainActor @Test("Buying something again that's already At home makes it fresh")
    func putAwayAgainRefreshesTheDate() {
        let kitchen = makeKitchen([KitchenItem(name: "Coriander", category: "Herbs & Fresh Spices", dateAdded: longAgo)])

        kitchen.putAway(["coriander "])

        #expect(kitchen.items.count == 1)
        #expect((kitchen.items.first?.dateAdded ?? .distantPast) > Date(timeIntervalSinceNow: -60))
    }
}
