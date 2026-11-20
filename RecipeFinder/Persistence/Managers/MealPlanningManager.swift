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
    /// Plans Clear Past Plans would take off.
    var pastPlanCount: Int { get }
    func mealPlan(for date: Date, mealTime: MealTime) -> MealPlanModel?
    func mealPlans(for date: Date) -> [MealPlanModel]
    func hasMealPlans(for date: Date) -> Bool
    func mealPlansForWeek(starting startDate: Date) -> WeeklyMealPlan
    func weekShoppingSummary(forWeekStarting startDate: Date, recipes: [RecipeModel]) -> WeekShoppingSummary
    /// The same, leaving out days before `earliest` (Plan's Add Week: meals already eaten aren't shopped for).
    func weekShoppingSummary(forWeekStarting startDate: Date, recipes: [RecipeModel], from earliest: Date) -> WeekShoppingSummary
    /// Re-reads the Sunday-nudge switch and plans, then schedules or cancels the one pending nudge.
    func syncPlanNudge()
    /// Dishes passed on in Plan my week in the last 30 days (`PlanDeckMemory`).
    func recentlyPassedDinners() -> Set<UUID>
    /// Remembers a dish passed on in Plan my week for 30 days.
    func rememberPassedDinner(_ recipeID: UUID)
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
    @ObservationIgnored private let planNudges: any PlanNudgeScheduling
    @ObservationIgnored private let storage: LocalStore

    static let blobKey = "mealPlansStorage"

    private init() {
        self.mirror = MealPlanningManager.makeMirror(
            storage: .shared, store: CoreDataMealPlanStore(persistence: .shared)
        )
        self.badgeManager = .shared
        self.reminders = NotificationManager.shared
        self.planNudges = NotificationManager.shared
        self.storage = .shared
        loadMealPlans()
    }

    init(
        storage: LocalStore,
        mealPlanStore: any MealPlanStoring,
        badgeManager: BadgeManager = .shared,
        reminders: any MealReminderScheduling = NotificationManager.shared,
        planNudges: any PlanNudgeScheduling = NotificationManager.shared
    ) {
        self.mirror = MealPlanningManager.makeMirror(storage: storage, store: mealPlanStore)
        self.badgeManager = badgeManager
        self.reminders = reminders
        self.planNudges = planNudges
        self.storage = storage
        loadMealPlans()
    }

    private static func makeMirror(storage: LocalStore, store: any MealPlanStoring) -> MirroredSnapshot<MealPlanModel> {
        MirroredSnapshot(
            blobKey: blobKey, storage: storage,
            fetch: { try store.fetchMealPlans() },
            replace: { try store.replaceMealPlans(with: $0) },
            sync: .iCloudRules(
                storage: storage, store: store, id: { $0.id },
                // Two devices planning the same night (or both copying a weekly meal into it) make two rows with
                // different ids; keep one per slot so groceries, Tonight and reminders count it once.
                sameThing: .init(key: { AnyHashable(SlotKey($0)) }, rank: { $0.id.uuidString }, fold: { kept, _ in kept })
            )
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
        // Planned by any route (deck, picker, Today): the dish is wanted again, so its pass is forgotten.
        PlanDeckMemory.update(in: storage, passed: [], planned: [mealPlan.recipeId], at: Date())
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
        remove { $0.id == mealPlan.id }
    }

    func removeMealPlan(for date: Date, mealTime: MealTime) {
        remove { $0.isSlot(date, mealTime) }
    }

    /// Removing a copy of a weekly meal also stops its series: otherwise the next copy refills the night from an
    /// earlier week and the meal can never be taken off.
    private func remove(where matches: (MealPlanModel) -> Bool) {
        let removed = mealPlans.filter(matches)
        for plan in removed { cancelReminder(for: plan) }
        mealPlans.removeAll(where: matches)
        for plan in removed where plan.isRecurring { stopSeries(of: plan) }
        HapticManager.shared.light()
        saveMealPlans()
        syncSeriesReminders()
    }

    /// Every copy of `plan`'s weekly series becomes a one-off, so nothing copies it forward again.
    private func stopSeries(of plan: MealPlanModel) {
        let key = SeriesKey(plan, calendar: .current)
        for index in mealPlans.indices
        where mealPlans[index].isRecurring && SeriesKey(mealPlans[index], calendar: .current) == key {
            mealPlans[index].isRecurring = false
        }
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
        if mealPlans[index].isRecurring {
            // Stop Repeating on any week's copy ends the series, not just that copy.
            stopSeries(of: mealPlans[index])
        } else {
            mealPlans[index].isRecurring = true
        }
        HapticManager.shared.light()
        saveMealPlans()
        // Recurrence flips reminders between weekly-repeat and one-off.
        syncReminder(for: mealPlans[index])
        syncSeriesReminders()
    }

    /// Materialises the latest recurring template into each empty slot of the target week (stays recurring); idempotent.
    func propagateRecurring(toWeekStarting startDate: Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: startDate)
        guard let end = cal.date(byAdding: .day, value: 7, to: start) else { return }

        let templates = mealPlans.filter { $0.isRecurring && $0.date < start }
        guard !templates.isEmpty else { return }

        // O(1) occupied-slot lookup instead of O(P) contains per slot.
        let occupiedSlots = Set(mealPlans.map { SlotKey($0, calendar: cal) })

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
        // The newest copy now carries the series' weekly reminder; the copies before it drop theirs.
        syncSeriesReminders()
    }

    /// Clear Past Plans: takes every plan before today off the planner (see `pastPlans`).
    func clearOldMealPlans() {
        let past = Self.pastPlans(mealPlans, now: Date())
        guard !past.isEmpty else { return }
        for plan in mealPlans where past.contains(plan.id) { cancelReminder(for: plan) }
        mealPlans.removeAll { past.contains($0.id) }
        saveMealPlans()
    }

    /// How many plans Clear Past Plans would take off, for its confirmation.
    var pastPlanCount: Int { Self.pastPlans(mealPlans, now: Date()).count }

    /// Plans on days before today: one-offs, and every copy of a weekly meal except the newest of its series (weekday +
    /// meal time), which `propagateRecurring` copies forward. Cooking history lives on the recipe (`cookCount`,
    /// `lastCookedAt`), so clearing a plan loses nothing cooked.
    nonisolated static func pastPlans(_ plans: [MealPlanModel], now: Date, calendar: Calendar = .current) -> Set<UUID> {
        let today = calendar.startOfDay(for: now)
        let newestOfSeries = Set(newestRecurringCopies(plans, calendar: calendar))
        return Set(plans.filter { $0.date < today && !newestOfSeries.contains($0.id) }.map(\.id))
    }

    /// The newest copy of each weekly series (weekday + meal time) — the one later weeks are copied from.
    nonisolated static func newestRecurringCopies(_ plans: [MealPlanModel], calendar: Calendar = .current) -> [UUID] {
        var newest: [SeriesKey: MealPlanModel] = [:]
        for plan in plans where plan.isRecurring {
            let key = SeriesKey(plan, calendar: calendar)
            if newest[key].map({ plan.date > $0.date }) ?? true { newest[key] = plan }
        }
        return newest.values.map(\.id)
    }

    /// A planner slot: the day (start of day) and meal time — one dish each.
    struct SlotKey: Hashable {
        let day: Date
        let mealTime: MealTime

        init(day: Date, mealTime: MealTime) {
            self.day = day
            self.mealTime = mealTime
        }

        init(_ plan: MealPlanModel, calendar: Calendar = .current) {
            self.init(day: calendar.startOfDay(for: plan.date), mealTime: plan.mealTime)
        }
    }

    /// A weekly series: same weekday and meal time (how `propagateRecurring` matches templates).
    struct SeriesKey: Hashable {
        let weekday: Int
        let mealTime: MealTime

        init(_ plan: MealPlanModel, calendar: Calendar) {
            weekday = calendar.component(.weekday, from: plan.date)
            mealTime = plan.mealTime
        }
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
        weekShoppingSummary(forWeekStarting: startDate, recipes: recipes, from: .distantPast)
    }

    func weekShoppingSummary(forWeekStarting startDate: Date, recipes: [RecipeModel], from earliest: Date) -> WeekShoppingSummary {
        let firstDay = Calendar.current.startOfDay(for: earliest)
        let plannedMeals = mealPlansForWeek(starting: startDate).meals.filter { !$0.isCompleted && $0.date >= firstDay }

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

        // A weekly series rings once a week: only its newest copy holds the repeating reminder (a weekly trigger
        // ignores the date, so every copy holding one fired its own alert each week).
        if plan.isRecurring, !Self.newestRecurringCopies(mealPlans).contains(plan.id) { return }

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

    /// Re-syncs every weekly copy, so the series' reminder sits on its newest copy alone.
    private func syncSeriesReminders() {
        for plan in mealPlans where plan.isRecurring { syncReminder(for: plan) }
    }

    private func cancelReminder(for plan: MealPlanModel) {
        reminders.cancelNotification(identifier: reminderId(for: plan))
    }

    /// Combines a meal's day with a reminder's clock time into the concrete fire date. Extracted for testing.
    nonisolated static func reminderFireDate(day: Date, time: Date, calendar: Calendar = .current) -> Date? {
        let t = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(bySettingHour: t.hour ?? 0, minute: t.minute ?? 0, second: 0, of: day)
    }

    // MARK: - Sunday planning nudge

    /// Runs after every load and save, so planning (or a synced plan from another device) moves the nudge on.
    /// One call either way: re-adding the same identifier replaces the pending nudge, and a remove followed by an add
    /// isn't promised to run in order, so a cancel first could delete the fresh nudge.
    func syncPlanNudge() {
        if storage.bool(forKey: SundayPlanNudge.settingKey),
           let fire = SundayPlanNudge.fireDate(now: Date(), plans: mealPlans) {
            planNudges.schedulePlanNudge(at: fire, identifier: SundayPlanNudge.identifier)
        } else {
            planNudges.cancelNotification(identifier: SundayPlanNudge.identifier)
        }
    }

    private func saveMealPlans() {
        mirror.save(mealPlans)
        syncPlanNudge()
    }

    private func loadMealPlans() {
        let before = mealPlans
        mealPlans = mirror.load()
        reconcileReminders(from: before)
        syncPlanNudge()
        // Runs at launch, so passes older than 30 days leave the device even if the deck is never opened again.
        PlanDeckMemory.update(in: storage, passed: [], planned: [], at: Date())
    }

    /// After a reload (iCloud brought another device's edits), plans deleted or folded away there lose their reminder
    /// here, and changed ones are re-synced. Nothing to do on the first load: the reminders were set when planned.
    private func reconcileReminders(from before: [MealPlanModel]) {
        guard !before.isEmpty else { return }
        let now = Dictionary(mealPlans.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for plan in before where now[plan.id] == nil { cancelReminder(for: plan) }
        let previous = Dictionary(before.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for plan in mealPlans where previous[plan.id] != plan { syncReminder(for: plan) }
        syncSeriesReminders()
    }

    // MARK: - Plan my week memory

    func recentlyPassedDinners() -> Set<UUID> {
        PlanDeckMemory.load(from: storage).recentlyPassed(at: Date())
    }

    func rememberPassedDinner(_ recipeID: UUID) {
        PlanDeckMemory.update(in: storage, passed: [recipeID], planned: [], at: Date())
    }
}
