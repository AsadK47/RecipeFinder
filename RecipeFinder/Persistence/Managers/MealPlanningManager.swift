import Foundation

@MainActor
final class MealPlanningManager: ObservableObject {
    static let shared = MealPlanningManager()

    @Published private(set) var mealPlans: [MealPlanModel] = []
    
    private let saveKey = "mealPlansStorage"
    private let storage: UserScopedStorage
    private let badgeManager: BadgeManager

    private init() {
        self.storage = .shared
        self.badgeManager = .shared
        loadMealPlans()
    }

    init(storage: UserScopedStorage, badgeManager: BadgeManager = .shared) {
        self.storage = storage
        self.badgeManager = badgeManager
        loadMealPlans()
    }

    func reloadForCurrentUser() {
        loadMealPlans()
    }
    
    /// Faithful, non-destructive restore: unions incoming plans by id and persists.
    /// Unlike `addMealPlan`, it doesn't collapse same-day/same-slot entries —
    /// restored plans keep the identity and fields they had when backed up.
    func merge(_ incoming: [MealPlanModel]) {
        mealPlans = BackupMerge.merged(existing: mealPlans, incoming: incoming)
        saveMealPlans()
    }

    func addMealPlan(_ mealPlan: MealPlanModel) {
        if let existingIndex = mealPlans.firstIndex(where: {
            Calendar.current.isDate($0.date, inSameDayAs: mealPlan.date) &&
            $0.mealTime == mealPlan.mealTime
        }) {
            mealPlans[existingIndex] = mealPlan
        } else {
            mealPlans.append(mealPlan)
        }

        HapticManager.shared.medium()
        saveMealPlans()
        badgeManager.unlockBadge(.mealPlanner)
    }
    
    func updateMealPlan(_ mealPlan: MealPlanModel) {
        if let index = mealPlans.firstIndex(where: { $0.id == mealPlan.id }) {
            mealPlans[index] = mealPlan
            HapticManager.shared.light()
            saveMealPlans()
        }
    }
    
    func removeMealPlan(_ mealPlan: MealPlanModel) {
        mealPlans.removeAll { $0.id == mealPlan.id }
        HapticManager.shared.light()
        saveMealPlans()
    }
    
    func removeMealPlan(for date: Date, mealTime: MealTime) {
        mealPlans.removeAll {
            Calendar.current.isDate($0.date, inSameDayAs: date) &&
            $0.mealTime == mealTime
        }
        HapticManager.shared.light()
        saveMealPlans()
    }
    
    func toggleCompletion(_ mealPlan: MealPlanModel) {
        if let index = mealPlans.firstIndex(where: { $0.id == mealPlan.id }) {
            mealPlans[index].isCompleted.toggle()
            HapticManager.shared.light()
            saveMealPlans()
        }
    }

    func toggleRecurring(_ mealPlan: MealPlanModel) {
        guard let index = mealPlans.firstIndex(where: { $0.id == mealPlan.id }) else { return }
        mealPlans[index].isRecurring.toggle()
        HapticManager.shared.light()
        saveMealPlans()
    }

    /// Copies recurring meals from any previous week into the target week.
    /// For each weekday+mealTime slot in the 7-day window starting at `startDate`
    /// that has no concrete entry, the most recent recurring template for that
    /// weekday+mealTime is materialised as a new stored entry (also marked recurring
    /// so it continues to propagate in future weeks). Idempotent: calling it twice
    /// for the same week produces no duplicates.
    func propagateRecurring(toWeekStarting startDate: Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: startDate)
        guard let end = cal.date(byAdding: .day, value: 7, to: start) else { return }

        let templates = mealPlans.filter { $0.isRecurring && $0.date < start }
        guard !templates.isEmpty else { return }

        // Pre-build an O(1) occupied-slot lookup instead of O(P) contains per slot.
        struct SlotKey: Hashable { let day: Date; let mealTime: MealTime }
        let occupiedSlots = Set(mealPlans.map { SlotKey(day: cal.startOfDay(for: $0.date), mealTime: $0.mealTime) })

        // Pre-build template lookup by (weekday, mealTime), keeping the most recent
        // per slot, so the inner loop is O(1) instead of O(T) filter + max.
        struct TemplateKey: Hashable { let weekday: Int; let mealTime: MealTime }
        var templateBySlot: [TemplateKey: MealPlanModel] = [:]
        for template in templates {
            let key = TemplateKey(weekday: cal.component(.weekday, from: template.date), mealTime: template.mealTime)
            if templateBySlot[key].map({ template.date > $0.date }) ?? true {
                templateBySlot[key] = template
            }
        }

        var newEntries: [MealPlanModel] = []
        var newOccupied: Set<SlotKey> = []

        for dayOffset in 0..<7 {
            guard let candidate = cal.date(byAdding: .day, value: dayOffset, to: start),
                  candidate < end else { continue }
            let targetWeekday = cal.component(.weekday, from: candidate)

            for mealTime in MealTime.allCases {
                let slot = SlotKey(day: candidate, mealTime: mealTime)
                guard !occupiedSlots.contains(slot) && !newOccupied.contains(slot) else { continue }

                guard let template = templateBySlot[TemplateKey(weekday: targetWeekday, mealTime: mealTime)] else { continue }

                newEntries.append(MealPlanModel(
                    recipeId: template.recipeId,
                    recipeName: template.recipeName,
                    date: candidate,
                    mealTime: mealTime,
                    servings: template.servings,
                    notes: template.notes,
                    isRecurring: true
                ))
                newOccupied.insert(slot)
            }
        }

        guard !newEntries.isEmpty else { return }
        mealPlans.append(contentsOf: newEntries)
        saveMealPlans()
    }

    func clearOldMealPlans() {
        guard let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else {
            return
        }
        // Recurring entries are retained as templates; only past one-off meals are purged.
        mealPlans.removeAll { $0.date < oneWeekAgo && !$0.isRecurring }
        saveMealPlans()
    }
    
    func mealPlan(for date: Date, mealTime: MealTime) -> MealPlanModel? {
        mealPlans.first {
            Calendar.current.isDate($0.date, inSameDayAs: date) &&
            $0.mealTime == mealTime
        }
    }
    
    func mealPlans(for date: Date) -> [MealPlanModel] {
        mealPlans.filter {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }.sorted { $0.mealTime.sortOrder < $1.mealTime.sortOrder }
    }
    
    func hasMealPlans(for date: Date) -> Bool {
        mealPlans.contains {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }
    
    func mealPlansForWeek(starting startDate: Date) -> WeeklyMealPlan {
        let start = Calendar.current.startOfDay(for: startDate)
        guard let end = Calendar.current.date(byAdding: .day, value: 7, to: start) else {
            return WeeklyMealPlan(startDate: start, meals: [])
        }
        
        let weekMeals = mealPlans.filter { meal in
            meal.date >= start && meal.date < end
        }
        
        return WeeklyMealPlan(startDate: start, meals: weekMeals)
    }
    
    /// Aggregates the ingredients needed for every incomplete meal planned in
    /// the week, resolving recipes from the caller's collection and merging
    /// duplicates by normalized ingredient name.
    ///
    /// Recipes are matched by id first, then by name as a fallback so meals
    /// survive a recipe being deleted and re-imported with a new id.
    func weekShoppingSummary(forWeekStarting startDate: Date, recipes: [RecipeModel]) -> WeekShoppingSummary {
        let plannedMeals = mealPlansForWeek(starting: startDate).meals.filter { !$0.isCompleted }

        var quantities: [String: Int] = [:]
        var itemOrder: [String] = []
        var mealsCovered = 0
        var missingRecipeNames: [String] = []

        for meal in plannedMeals {
            let recipe = recipes.first { $0.id == meal.recipeId }
                ?? recipes.first { $0.name.caseInsensitiveCompare(meal.recipeName) == .orderedSame }

            guard let recipe else {
                if !missingRecipeNames.contains(meal.recipeName) {
                    missingRecipeNames.append(meal.recipeName)
                }
                continue
            }

            mealsCovered += 1

            for ingredient in recipe.ingredients {
                let name = IngredientNormalizer.normalize(ingredient.mainIngredientName)
                guard !name.isEmpty else { continue }

                if quantities[name] == nil {
                    itemOrder.append(name)
                }
                quantities[name, default: 0] += 1
            }
        }

        let items = itemOrder.map { WeekShoppingSummary.Item(name: $0, quantity: quantities[$0] ?? 0) }
        return WeekShoppingSummary(items: items, mealsCovered: mealsCovered, missingRecipeNames: missingRecipeNames)
    }

    /// Returns a stable display order for `selected`, preserving any custom
    /// sequence in `existing` and appending newly-added slots in their natural
    /// sort position (breakfast → lunch → dinner → snack).
    nonisolated static func sortedOrderedMealTimes(
        existing: [MealTime],
        selected: Set<MealTime>
    ) -> [MealTime] {
        var result = existing.filter { selected.contains($0) }
        for mealTime in MealTime.allCases.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            if selected.contains(mealTime) && !result.contains(mealTime) {
                result.append(mealTime)
            }
        }
        return result
    }

    var todaysMealPlans: [MealPlanModel] {
        mealPlans(for: Date())
    }
    
    var upcomingMealPlans: [MealPlanModel] {
        mealPlans.filter { $0.isUpcoming }
            .sorted { $0.date < $1.date }
    }
    
    var incompleteMealPlans: [MealPlanModel] {
        mealPlans.filter { !$0.isCompleted }
    }
    
    var mealPlansByDate: [(date: Date, meals: [MealPlanModel])] {
        let grouped = Dictionary(grouping: mealPlans) { meal in
            Calendar.current.startOfDay(for: meal.date)
        }
        
        return grouped.sorted { $0.key < $1.key }
            .map { (date: $0.key, meals: $0.value.sorted { $0.mealTime.sortOrder < $1.mealTime.sortOrder }) }
    }
    
    private func saveMealPlans() {
        storage.setEncodable(mealPlans, forKey: saveKey)
    }
    
    private func loadMealPlans() {
        if let data = storage.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([MealPlanModel].self, from: data) {
            mealPlans = decoded
        } else {
            mealPlans = []
        }
    }
}
