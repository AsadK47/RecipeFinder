import SwiftUI

/// Seam so views depend on this protocol, not the singleton, and tests can inject a fake.
@MainActor
protocol MealPlanningManaging: AnyObject, Observable {
    func addMealPlan(_ mealPlan: MealPlanModel)
    func updateMealPlan(_ mealPlan: MealPlanModel)
    func removeMealPlan(for date: Date, mealTime: MealTime)
    /// The plans taking `plan` off would change, as they are now: it, and for a weekly meal every copy of its series.
    func plansChangedByRemoving(_ plan: MealPlanModel) -> [MealPlanModel]
    /// Undo for a take-off: puts `plans` back as they were (by id), skipping a slot the cook has filled since.
    /// Returns the plans it skipped, so the cook can be told they stayed off.
    @discardableResult func restore(_ plans: [MealPlanModel]) -> [MealPlanModel]
    func toggleRecurring(_ mealPlan: MealPlanModel)
    func propagateRecurring(toWeekStarting startDate: Date)
    func clearOldMealPlans()
    /// Marks the plans for `recipeID` on `day` cooked (Made it), so a past day keeps showing them as done.
    func markCooked(recipeID: UUID, on day: Date)
    /// Clear Past Plans: past plans go, except dinners cooked on their day (looked up in `recipes`).
    func clearPastMealPlans(keepingCookedIn recipes: [RecipeModel])
    /// Plans Clear Past Plans would take off.
    func pastPlanCount(keepingCookedIn recipes: [RecipeModel]) -> Int
    func mealPlan(for date: Date, mealTime: MealTime) -> MealPlanModel?
    func mealPlans(for date: Date) -> [MealPlanModel]
    func hasMealPlans(for date: Date) -> Bool
    func mealPlansForWeek(starting startDate: Date) -> WeeklyMealPlan
    /// Every weekly copy (the series later weeks are filled from).
    var recurringMealPlans: [MealPlanModel] { get }
    func weekShoppingSummary(forWeekStarting startDate: Date, recipes: [RecipeModel]) -> WeekShoppingSummary
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
                sameThing: .init(key: { AnyHashable(SlotKey($0)) },
                                 rank: MealPlanningManager.foldRank, fold: MealPlanningManager.foldTwins)
            )
        )
    }

    /// Same-slot twins: a dish the cook picked beats a weekly copy made automatically, a cooked one beats an uncooked
    /// one, then the most recently planned wins; the id breaks ties. Identical on every device, as `SameThing.rank`
    /// requires: lowest rank is kept.
    nonisolated static func foldRank(_ plan: MealPlanModel) -> String {
        let newestFirst = Int64(1e13) - Int64(plan.createdDate.timeIntervalSince1970 * 1000)
        return (plan.isRecurring ? "1" : "0") + (plan.isCompleted ? "0" : "1")
            + String(format: "%014lld-", max(newestFirst, 0)) + plan.id.uuidString
    }

    /// The kept twin stays cooked, weekly or reminded if either was, so a merge never hides a cooked night or drops
    /// a reminder (earliest reminder time, so the order rows arrive in doesn't matter).
    nonisolated static func foldTwins(_ kept: MealPlanModel, _ others: [MealPlanModel]) -> MealPlanModel {
        var merged = kept
        merged.isCompleted = ([kept] + others).contains(where: \.isCompleted)
        merged.isRecurring = ([kept] + others).contains(where: \.isRecurring)
        merged.reminderTime = kept.reminderTime ?? others.compactMap(\.reminderTime).min()
        return merged
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
        // A restored weekly copy may become its series' newest, which holds the reminder: it takes the time this
        // device's series already has, so an older backup can't silence or move the cook's current reminder.
        let localTimes = Self.seriesReminderTimes(mealPlans)
        let addedIDs = Set(added.map(\.id))
        mealPlans = merged.map { plan in
            guard plan.isRecurring, addedIDs.contains(plan.id),
                  let local = localTimes[SeriesKey(plan, calendar: .current)] else { return plan }
            var adopted = plan
            adopted.reminderTime = local
            return adopted
        }
        saveMealPlans()
        // Re-arm reminders for newly-restored plans so they survive a device migration.
        for plan in mealPlans where addedIDs.contains(plan.id) { syncReminder(for: plan) }
        // A restored newer weekly copy takes the series' reminder, so the older copy must give its own up.
        syncSeriesReminders()
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
        // Replacing a series' newest copy hands its weekly reminder back to the copy before it.
        syncSeriesReminders()
        badgeManager.unlockBadge(.mealPlanner)
    }
    
    func updateMealPlan(_ mealPlan: MealPlanModel) {
        if let index = mealPlans.firstIndex(where: { $0.id == mealPlan.id }) {
            let reminderChanged = mealPlans[index].reminderTime != mealPlan.reminderTime
            mealPlans[index] = mealPlan
            if mealPlan.isRecurring, reminderChanged {
                // A weekly meal's reminder belongs to the series (its newest copy rings), so every copy takes it.
                let key = SeriesKey(mealPlan, calendar: .current)
                for other in mealPlans.indices
                where mealPlans[other].isRecurring && SeriesKey(mealPlans[other], calendar: .current) == key {
                    mealPlans[other].reminderTime = mealPlan.reminderTime
                }
            }
            HapticManager.shared.light()
            saveMealPlans()
            syncReminder(for: mealPlan)
            syncSeriesReminders()
        }
    }
    
    func removeMealPlan(_ mealPlan: MealPlanModel) {
        remove { $0.id == mealPlan.id }
    }

    func removeMealPlan(for date: Date, mealTime: MealTime) {
        remove { $0.isSlot(date, mealTime) }
    }

    func plansChangedByRemoving(_ plan: MealPlanModel) -> [MealPlanModel] {
        guard plan.isRecurring else { return mealPlans.filter { $0.id == plan.id } }
        let key = SeriesKey(plan, calendar: .current)
        return mealPlans.filter { $0.id == plan.id || ($0.isRecurring && SeriesKey($0, calendar: .current) == key) }
    }

    @discardableResult func restore(_ plans: [MealPlanModel]) -> [MealPlanModel] {
        var restored: [MealPlanModel] = []
        for plan in plans {
            if let index = mealPlans.firstIndex(where: { $0.id == plan.id }) {
                mealPlans[index] = plan
            } else if mealPlans.contains(where: { $0.isSlot(plan.date, plan.mealTime) }) {
                continue // a meal planned there since wins: a night never holds two
            } else {
                mealPlans.append(plan)
            }
            restored.append(plan)
        }
        guard !restored.isEmpty else { return [] }
        saveMealPlans()
        for plan in restored { syncReminder(for: plan) }
        syncSeriesReminders()
        return []
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

    /// Every copy of `plan`'s weekly series becomes a one-off, so nothing copies it forward again; copies already made
    /// for later weeks (by `propagateRecurring`, never picked by the cook) go, so a stopped meal doesn't turn up again.
    private func stopSeries(of plan: MealPlanModel) {
        let key = SeriesKey(plan, calendar: .current)
        let inSeries = { (other: MealPlanModel) in other.isRecurring && SeriesKey(other, calendar: .current) == key }
        let later = mealPlans.filter { inSeries($0) && $0.date > plan.date && $0.id != plan.id }
        for copy in later { cancelReminder(for: copy) }
        mealPlans.removeAll { copy in later.contains { $0.id == copy.id } }
        for index in mealPlans.indices where inSeries(mealPlans[index]) {
            mealPlans[index].isRecurring = false
            // The weekly reminder sat on the newest copy; each copy left behind now needs its own one-off.
            syncReminder(for: mealPlans[index])
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

    func markCooked(recipeID: UUID, on day: Date) {
        var changed: [MealPlanModel] = []
        for index in mealPlans.indices
        where mealPlans[index].recipeId == recipeID && mealPlans[index].isOn(day) && !mealPlans[index].isCompleted {
            mealPlans[index].isCompleted = true
            changed.append(mealPlans[index])
        }
        guard !changed.isEmpty else { return }
        saveMealPlans()
        // Cooked: no reminder to cook it.
        for plan in changed { syncReminder(for: plan) }
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
        // Stopping already re-synced every copy it changed (a second cancel-then-add risks losing the reminder, as
        // remove/add aren't promised to run in order). Looked up again: stopSeries may have shifted `index`.
        if let toggled = mealPlans.first(where: { $0.id == mealPlan.id }), toggled.isRecurring {
            syncReminder(for: toggled)
        }
        syncSeriesReminders()
    }

    /// Materialises the latest recurring template into each empty slot of the target week (stays recurring); idempotent.
    func propagateRecurring(toWeekStarting startDate: Date) {
        let newEntries = Self.weeklyCopies(of: mealPlans, forWeekStarting: startDate)
        guard !newEntries.isEmpty else { return }
        mealPlans.append(contentsOf: newEntries)
        saveMealPlans()
        // The newest copy now carries the series' weekly reminder; the copies before it drop theirs.
        syncSeriesReminders()
    }

    func clearOldMealPlans() {
        clearPastMealPlans(keepingCookedIn: [])
    }

    /// Clear Past Plans: takes plans before today off the planner (see `pastPlans`).
    func clearPastMealPlans(keepingCookedIn recipes: [RecipeModel]) {
        let past = Self.pastPlans(mealPlans, now: Date(), recipes: recipes)
        guard !past.isEmpty else { return }
        for plan in mealPlans where past.contains(plan.id) { cancelReminder(for: plan) }
        mealPlans.removeAll { past.contains($0.id) }
        saveMealPlans()
    }

    /// How many plans Clear Past Plans would take off, for its confirmation.
    func pastPlanCount(keepingCookedIn recipes: [RecipeModel]) -> Int {
        Self.pastPlans(mealPlans, now: Date(), recipes: recipes).count
    }

    func mealPlan(for date: Date, mealTime: MealTime) -> MealPlanModel? {
        mealPlans.first { $0.isSlot(date, mealTime) }
    }
    
    func mealPlans(for date: Date) -> [MealPlanModel] {
        mealPlans.filter { $0.isOn(date) }.sorted(by: MealPlanModel.eatenBefore)
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

    /// Stable order for `selected`: keeps `existing` sequence (a dragged order), slots new meals in by time of day.
    nonisolated static func sortedOrderedMealTimes(
        existing: [MealTime],
        selected: Set<MealTime>,
        minuteOfDay: (MealTime) -> Int = { $0.defaultMinuteOfDay }
    ) -> [MealTime] {
        // Read once up front: `minuteOfDay` is non-escaping, so the comparator closure can't hold it.
        let minutes = Dictionary(uniqueKeysWithValues: MealTime.allCases.map { ($0, minuteOfDay($0)) })
        let key = { (time: MealTime) in (minutes[time] ?? time.defaultMinuteOfDay, time.sortOrder) }
        var result = existing.filter { selected.contains($0) }
        for mealTime in selected.sorted(by: { key($0) < key($1) }) where !result.contains(mealTime) {
            // A newly added meal slots in by when it's eaten (lunch above dinner, a 3pm snack between them), ahead of
            // the first later meal, so any dragged order is kept.
            let index = result.firstIndex { key($0) > key(mealTime) } ?? result.endIndex
            result.insert(mealTime, at: index)
        }
        return result
    }

    var recurringMealPlans: [MealPlanModel] { mealPlans.filter(\.isRecurring) }

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

        // A cooked one-off needs no nudge; a weekly series keeps ringing for the weeks ahead even once this copy is
        // cooked (its later copies may not exist yet).
        guard plan.isRecurring || !plan.isCompleted,
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
