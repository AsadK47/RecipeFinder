import Foundation

/// "Still got the coriander?" — the plan trusts what's At home, so a bunch of coriander put away a fortnight ago keeps
/// it off the list. This asks about the perishables the next week's plan counts on once they've been At home longer
/// than they usually keep; pantry staples are trusted. Derived from the existing put-away date (nothing new stored). Pure.
struct StillGotCheck: Equatable {
    struct Question: Equatable, Identifiable {
        let item: KitchenItem
        /// The plan's lines for this ingredient (one per unit), what "No" puts on the list.
        let needs: [WeekShoppingSummary.Item]
        let daysAtHome: Int

        var id: UUID { item.id }

        var title: String { "Still got the \(item.name.trimmed.lowercased())?" }

        var detail: String {
            daysAtHome > 30 ? "At home for over a month" : "At home for \(daysAtHome) days"
        }

        /// Gone: off At home, and what the plan needs onto the list (minus what's already there, so it never doubles).
        @MainActor
        func answerNo(kitchen: any KitchenInventoryManaging, shopping: any ShoppingListManaging) {
            kitchen.removeItem(item)
            let plan = WeekGroceryPlan(
                summary: WeekShoppingSummary(items: needs, mealsCovered: 0, missingRecipeNames: []),
                kitchenNames: [],
                listItems: shopping.items
            )
            plan.add(to: shopping)
        }

        /// Still there: counts as put away today, so it isn't asked again until it's old again.
        @MainActor
        func answerYes(kitchen: any KitchenInventoryManaging) {
            kitchen.stillHave(item)
        }
    }

    /// Longest overdue first.
    let questions: [Question]

    var first: Question? { questions.first }

    static let empty = StillGotCheck(questions: [])

    private init(questions: [Question]) {
        self.questions = questions
    }

    init(summary: WeekShoppingSummary, kitchenItems: [KitchenItem], now: Date, calendar: Calendar = .current) {
        var needsByName: [String: [WeekShoppingSummary.Item]] = [:]
        for need in summary.items {
            needsByName[IngredientNormalizer.normalize(need.name), default: []].append(need)
        }
        let today = calendar.startOfDay(for: now)
        let asked: [(question: Question, overdue: Int)] = kitchenItems.compactMap { item in
            guard let keeps = Self.keepsDays(category: item.category),
                  let needs = needsByName[IngredientNormalizer.normalize(item.name)] else { return nil }
            let added = calendar.startOfDay(for: item.dateAdded)
            let days = calendar.dateComponents([.day], from: added, to: today).day ?? 0
            guard days > keeps else { return nil }
            return (Question(item: item, needs: needs, daysAtHome: days), days - keeps)
        }
        questions = asked
            .sorted { $0.overdue != $1.overdue ? $0.overdue > $1.overdue : $0.question.item.name < $1.question.item.name }
            .map(\.question)
    }

    /// Roughly how many days a kind of food keeps once it's home (fridge, not freezer); nil = a staple, never asked.
    static func keepsDays(category: String) -> Int? {
        switch category {
        case "Meat", "Poultry", "Seafood": 3
        case "Bakery": 4
        case "Herbs & Fresh Spices": 5
        case "Produce", "Vegetables", "Fruits": 7
        case "Dairy & Eggs": 10
        default: nil
        }
    }
}
