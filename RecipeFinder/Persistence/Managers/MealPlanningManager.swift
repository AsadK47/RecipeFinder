import SwiftUI

/// Seam so views depend on this protocol, not the singleton, and tests can inject a fake.
@MainActor
protocol MealPlanningManaging: AnyObject, Observable {
    func addMealPlan(_ mealPlan: MealPlanModel)
    func updateMealPlan(_ mealPlan: MealPlanModel)
    func removeMealPlan(for date: Date, mealTime: MealTime)
    func toggleRecurring(_ mealPlan: MealPlanModel)
    func propagateRecurring(toWeekStarting startDate: Date)
    func clearOldMealPlans()
    func mealPlan(for date: Date, mealTime: MealTime) -> MealPlanModel?
    func mealPlans(for date: Date) -> [MealPlanModel]
    func hasMealPlans(for date: Date) -> Bool
    func mealPlansForWeek(starting startDate: Date) -> WeeklyMealPlan
    func weekShoppingSummary(forWeekStarting startDate: Date, recipes: [RecipeModel]) -> WeekShoppingSummary
}

private struct MealPlanningManagingKey: EnvironmentKey {
    // SwiftUI reads environment defaults on the main actor, so assuming isolation is safe.
    static var defaultValue: any MealPlanningManaging {
        MainActor.assumeIsolated { MealPlanningManager.shared }
    }
}

extension EnvironmentValues {
    /// Injected meal planner; defaults to shared, override with `.environment(\.mealPlanning, fake)`.
    var mealPlanning: any MealPlanningManaging {
        get { self[MealPlanningManagingKey.self] }
        set { self[MealPlanningManagingKey.self] = newValue }
    }
}

@MainActor
@Observable
final class MealPlanningManager: MealPlanningManaging {
    static let shared = MealPlanningManager()

    private(set) var mealPlans: [MealPlanModel] = []

    /// Plans live in `MealPlanEntity` rows; the old `LocalStore` blob is kept current for one release.
    @ObservationIgnored private let mirror: MirroredSnapshot<MealPlanModel>
    @ObservationIgnored private let badgeManager: BadgeManager
    @ObservationIgnored private let reminders: any MealReminderScheduling

    static let blobKey = "mealPlansStorage"

    private init() {
        self.mirror = MealPlanningManager.makeMirror(
            storage: .shared, store: CoreDataMealPlanStore(persistence: .shared)
        )
        self.badgeManager = .shared
        self.reminders = NotificationManager.shared
        loadMealPlans()
    }

    init(
        storage: LocalStore,
        mealPlanStore: any MealPlanStoring,
        badgeManager: BadgeManager = .shared,
        reminders: any MealReminderScheduling = NotificationManager.shared
    ) {
        self.mirror = MealPlanningManager.makeMirror(storage: storage, store: mealPlanStore)
        self.badgeManager = badgeManager
        self.reminders = reminders
        loadMealPlans()
    }

    private static func makeMirror(storage: LocalStore, store: any MealPlanStoring) -> MirroredSnapshot<MealPlanModel> {
        MirroredSnapshot(
            blobKey: blobKey, storage: storage,
            fetch: { try store.fetchMealPlans() },
            replace: { try store.replaceMealPlans(with: $0) }
        )
    }

    /// Erase & Reset: removes every plan. If the store can't delete now, the next launch finishes it.
    func removeAllMealPlans() {
        // Cancelled first: a weekly reminder outliving its plan would keep firing with nothing left to delete.
        for plan in mealPlans { cancelReminder(for: plan) }
        mirror.removeAll()
        loadMealPlans()
    }

    func reload() {
        loadMealPlans()
    }
    
    /// Non-destructive restore: unions incoming plans by id without collapsing same-slot entries.
    func merge(_ incoming: [MealPlanModel]) {
        let (merged, added) = BackupMerge.mergedWithAdditions(existing: mealPlans, incoming: incoming)
        mealPlans = merged
        saveMealPlans()
        // Re-arm reminders for newly-restored plans so they survive a device migration.
        for plan in added { syncReminder(for: plan) }
    }

    func addMealPlan(_ mealPlan: MealPlanModel) {
        if let existingIndex = mealPlans.firstIndex(where: { $0.isSlot(mealPlan.date, mealPlan.mealTime) }) {
            // The replaced occupant has a different id, so cancel its reminder before it's overwritten.
            cancelReminder(for: mealPlans[existingIndex])
            mealPlans[existingIndex] = mealPlan
        } else {
            mealPlans.append(mealPlan)
        }

        HapticManager.shared.medium()
        saveMealPlans()
        syncReminder(for: mealPlan)
        badgeManager.unlockBadge(.mealPlanner)
    }
    
    func updateMealPlan(_ mealPlan: MealPlanModel) {
        if let index = mealPlans.firstIndex(where: { $0.id == mealPlan.id }) {
            mealPlans[index] = mealPlan
            HapticManager.shared.light()
            saveMealPlans()
            syncReminder(for: mealPlan)
        }
    }
    
    func removeMealPlan(_ mealPlan: MealPlanModel) {
        cancelReminder(for: mealPlan)
        mealPlans.removeAll { $0.id == mealPlan.id }
        HapticManager.shared.light()
        saveMealPlans()
    }
    
    func removeMealPlan(for date: Date, mealTime: MealTime) {
        for plan in mealPlans where plan.isSlot(date, mealTime) {
            cancelReminder(for: plan)
        }
        mealPlans.removeAll { $0.isSlot(date, mealTime) }
        HapticManager.shared.light()
        saveMealPlans()
    }
    
    func toggleCompletion(_ mealPlan: MealPlanModel) {
        if let index = mealPlans.firstIndex(where: { $0.id == mealPlan.id }) {
            mealPlans[index].isCompleted.toggle()
            HapticManager.shared.light()
            saveMealPlans()
            // Don't nag to cook a meal already marked done; re-arm if it's un-completed.
            syncReminder(for: mealPlans[index])
        }
    }

    func toggleRecurring(_ mealPlan: MealPlanModel) {
        guard let index = mealPlans.firstIndex(where: { $0.id == mealPlan.id }) else { return }
        mealPlans[index].isRecurring.toggle()
        HapticManager.shared.light()
        saveMealPlans()
        // Recurrence flips the reminder between weekly-repeat and one-off.
        syncReminder(for: mealPlans[index])
    }

    /// Materialises the latest recurring template into each empty slot of the target week (stays recurring); idempotent.
    func propagateRecurring(toWeekStarting startDate: Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: startDate)
        guard let end = cal.date(byAdding: .day, value: 7, to: start) else { return }

        let templates = mealPlans.filter { $0.isRecurring && $0.date < start }
        guard !templates.isEmpty else { return }

        // O(1) occupied-slot lookup instead of O(P) contains per slot.
        struct SlotKey: Hashable { let day: Date; let mealTime: MealTime }
        let occupiedSlots = Set(mealPlans.map { SlotKey(day: cal.startOfDay(for: $0.date), mealTime: $0.mealTime) })

        // Template lookup by (weekday, mealTime) keeping the most recent, so inner loop is O(1).
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
                    isRecurring: true,
                    reminderTime: template.reminderTime
                ))
                newOccupied.insert(slot)
            }
        }

        guard !newEntries.isEmpty else { return }
        mealPlans.append(contentsOf: newEntries)
        saveMealPlans()
        for entry in newEntries { syncReminder(for: entry) }
    }

    func clearOldMealPlans() {
        guard let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else {
            return
        }
        // Recurring entries are retained as templates; only past one-off meals are purged.
        for plan in mealPlans where plan.date < oneWeekAgo && !plan.isRecurring {
            cancelReminder(for: plan)
        }
        mealPlans.removeAll { $0.date < oneWeekAgo && !$0.isRecurring }
        saveMealPlans()
    }
    
    func mealPlan(for date: Date, mealTime: MealTime) -> MealPlanModel? {
        mealPlans.first { $0.isSlot(date, mealTime) }
    }
    
    func mealPlans(for date: Date) -> [MealPlanModel] {
        mealPlans.filter { $0.isOn(date) }.sorted { $0.mealTime.sortOrder < $1.mealTime.sortOrder }
    }
    
    func hasMealPlans(for date: Date) -> Bool {
        mealPlans.contains { $0.isOn(date) }
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
    
    /// Aggregates ingredients for the week's incomplete meals (merged by normalized name); recipes matched by id then name to survive re-imports.
    func weekShoppingSummary(forWeekStarting startDate: Date, recipes: [RecipeModel]) -> WeekShoppingSummary {
        let plannedMeals = mealPlansForWeek(starting: startDate).meals.filter { !$0.isCompleted }

        // Merge by (name, unit) so amounts in the same unit sum and different units stay separate — reusing the
        // same per-ingredient mapping the single-recipe "add to groceries" path uses, so both carry real amounts.
        struct Key: Hashable { let name: String; let unit: String }
        var quantities: [Key: Int] = [:]
        var itemOrder: [Key] = []
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

            // Buy for the servings planned for this meal, not the recipe's base servings.
            let scaleFactor = recipe.baseServings > 0 ? Double(meal.servings) / Double(recipe.baseServings) : 1
            for ingredient in recipe.ingredients {
                guard let line = RecipeShoppingList.item(from: ingredient, scaleFactor: scaleFactor) else { continue }
                let key = Key(name: line.name, unit: line.unit)
                if quantities[key] == nil {
                    itemOrder.append(key)
                }
                quantities[key, default: 0] += line.quantity
            }
        }

        let items = itemOrder.map { WeekShoppingSummary.Item(name: $0.name, quantity: quantities[$0] ?? 0, unit: $0.unit) }
        return WeekShoppingSummary(items: items, mealsCovered: mealsCovered, missingRecipeNames: missingRecipeNames)
    }

    /// Stable order for `selected`: preserves `existing` sequence, appends new slots in natural sort.
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
    
    // MARK: - Reminders

    /// Stable notification id for a plan, so re-scheduling replaces rather than duplicates.
    private func reminderId(for plan: MealPlanModel) -> String { "meal-\(plan.id.uuidString)" }

    /// Cancels any existing reminder for the plan, then schedules a fresh one when it still warrants one.
    private func syncReminder(for plan: MealPlanModel) {
        let id = reminderId(for: plan)
        reminders.cancelNotification(identifier: id)

        guard !plan.isCompleted,
              let time = plan.reminderTime,
              let fireDate = Self.reminderFireDate(day: plan.date, time: time) else { return }
        // A one-off whose moment has passed is pointless; a weekly repeat still fires on its next weekday.
        if !plan.isRecurring && fireDate <= Date() { return }

        reminders.scheduleMealReminder(
            mealName: plan.mealTime.rawValue,
            recipeName: plan.recipeName,
            date: fireDate,
            identifier: id,
            repeatsWeekly: plan.isRecurring
        )
    }

    private func cancelReminder(for plan: MealPlanModel) {
        reminders.cancelNotification(identifier: reminderId(for: plan))
    }

    /// Combines a meal's day with a reminder's clock time into the concrete fire date. Extracted for testing.
    nonisolated static func reminderFireDate(day: Date, time: Date, calendar: Calendar = .current) -> Date? {
        let t = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(bySettingHour: t.hour ?? 0, minute: t.minute ?? 0, second: 0, of: day)
    }

    private func saveMealPlans() {
        mirror.save(mealPlans)
    }

    private func loadMealPlans() {
        mealPlans = mirror.load()
    }
}
