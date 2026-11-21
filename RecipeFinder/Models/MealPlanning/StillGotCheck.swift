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

    /// The question to show, skipping what the cook said "Ask me later" to this session.
    func first(skipping skipped: Set<UUID>) -> Question? {
        questions.first { !skipped.contains($0.id) }
    }

    static let empty = StillGotCheck(questions: [])

    private init(questions: [Question]) {
        self.questions = questions
    }

    /// `inventoryNames`: tracked inventory (with its own expiry dates) also counts as At home, so a name there isn't
    /// asked about — "No" couldn't take it off.
    init(summary: WeekShoppingSummary, kitchenItems: [KitchenItem], inventoryNames: [String] = [], now: Date,
         calendar: Calendar = .current) {
        let tracked = Set(inventoryNames.map { IngredientNormalizer.normalize($0) })
        var needsByName: [String: [WeekShoppingSummary.Item]] = [:]
        for need in summary.items {
            needsByName[IngredientNormalizer.normalize(need.name), default: []].append(need)
        }
        let today = calendar.startOfDay(for: now)
        let asked: [(question: Question, overdue: Int)] = kitchenItems.compactMap { item in
            // Undated (stored before put-away dates were kept): unknown isn't old, so it isn't asked.
            guard item.dateAdded > Self.undated,
                  let keeps = Self.keepsDays(name: item.name, category: item.category),
                  !tracked.contains(IngredientNormalizer.normalize(item.name)),
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

    /// What `KitchenItem` decodes a missing put-away date as.
    private static let undated = Date(timeIntervalSinceReferenceDate: 0)

    /// Fresh herbs the classifier files with the dried spice of the same name (its "coriander" is the seed).
    private static let freshHerbNames: Set<String> = ["coriander", "fresh coriander", "coriander leaves", "coriander leaf"]

    /// Perishable-category foods that keep for weeks (cured, hard, roots and bulbs) — asking about them would nag.
    private static let longKeeperWords: Set<String> = [
        "onion", "onions", "garlic", "potato", "potatoes", "shallot", "shallots", "ginger",
        "egg", "eggs", "butter", "parmesan", "pecorino", "cheddar", "ghee",
        "bacon", "chorizo", "salami", "pepperoni", "prosciutto", "pancetta", "guanciale", "ham", "gammon",
        "lemon", "lemons", "lime", "limes", "apple", "apples", "carrot", "carrots",
    ]

    /// Roughly how many days this food keeps once it's home (fridge, not freezer); nil = keeps for weeks, never asked.
    static func keepsDays(name: String, category: String) -> Int? {
        let lowered = name.trimmed.lowercased()
        if freshHerbNames.contains(lowered) { return keepsDays(category: "Herbs & Fresh Spices") }
        let words = lowered.split { !$0.isLetter }.map(String.init)
        if words.contains(where: longKeeperWords.contains) { return nil }
        return keepsDays(category: category)
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
