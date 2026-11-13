import Testing
import CoreData
import Foundation
@testable import RecipeFinder

/// Meal plan fake: an array, with switches to make reads or writes fail like a broken store.
@MainActor
final class InMemoryMealPlanStore: MealPlanStoring {
    var plans: [MealPlanModel]
    var failWrites = false
    var failReads = false

    init(_ plans: [MealPlanModel] = []) { self.plans = plans }

    func fetchMealPlans() throws -> [MealPlanModel] {
        if failReads { throw MealPlanStoreError.storeUnavailable }
        return plans
    }

    func replaceMealPlans(with replacement: [MealPlanModel]) throws {
        if failWrites { throw MealPlanStoreError.storeUnavailable }
        plans = replacement
    }
}

/// Moving the meal plans blob out of `LocalStore` into `MealPlanEntity` (Data safety 1/4, slice 3c). The shared
/// copy/fallback rules are covered in depth by `CollectionMigrationTests` (same `MirroredSnapshot`); these pin the
/// meal plan wiring and the Core Data mapping.
@MainActor
@Suite struct MealPlanMigrationTests {
    private let blobKey = MealPlanningManager.blobKey
    private let storage = LocalStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    private let tonight = MealPlanModel(
        recipeId: UUID(), recipeName: "Dal", date: Date(timeIntervalSinceReferenceDate: 815_000_000),
        mealTime: .dinner, servings: 2, notes: "Double the garlic", isCompleted: true, isRecurring: true,
        createdDate: Date(timeIntervalSinceReferenceDate: 814_900_000),
        reminderTime: Date(timeIntervalSinceReferenceDate: 815_010_000)
    )
    private let breakfast = MealPlanModel(
        recipeId: UUID(), recipeName: "Porridge", date: Date(timeIntervalSinceReferenceDate: 815_100_000),
        mealTime: .breakfast, createdDate: Date(timeIntervalSinceReferenceDate: 814_950_000)
    )
    private var both: [MealPlanModel] { [tonight, breakfast] }

    private func writeBlob(_ plans: [MealPlanModel]) {
        storage.setEncodable(plans, forKey: blobKey)
    }

    private func keptCopy() -> [MealPlanModel]? {
        storage.decodable([MealPlanModel].self, forKey: blobKey)
    }

    private func migrated() -> Bool {
        storage.bool(forKey: MirroredSnapshot<MealPlanModel>.flagKey(for: blobKey))
    }

    private func manager(_ store: any MealPlanStoring) -> MealPlanningManager {
        MealPlanningManager(storage: storage, mealPlanStore: store, badgeManager: BadgeManager(storage: storage),
                            reminders: FakeMealReminderScheduler())
    }

    // MARK: - Migration

    @Test func everyBlobPlanBecomesARowInOrderAndTheKeyIsMarked() {
        writeBlob(both)
        let store = InMemoryMealPlanStore()
        let sut = manager(store)
        #expect(store.plans == both)
        #expect(sut.mealPlans == both)
        #expect(migrated())
        #expect(keptCopy() == both)
    }

    @Test func aFailedWriteLeavesTheKeyUnmarkedAndTheCookKeepsTheirPlans() {
        writeBlob(both)
        let store = InMemoryMealPlanStore()
        store.failWrites = true
        let sut = manager(store)
        #expect(!migrated())
        #expect(sut.mealPlans == both)
    }

    @Test func aCorruptBlobIsKeptAsideAndTheStoreIsLeftAlone() {
        storage.set(Data("not json".utf8), forKey: blobKey)
        let store = InMemoryMealPlanStore([tonight])
        let sut = manager(store)
        #expect(sut.mealPlans == [tonight])
        #expect(store.plans == [tonight])
    }

    @Test func aPlanAddedWhileTheStoreFailsIsKeptNextLaunch() {
        let store = InMemoryMealPlanStore()
        let sut = manager(store)
        store.failWrites = true
        sut.addMealPlan(breakfast)

        store.failWrites = false
        let nextLaunch = manager(store)
        #expect(nextLaunch.mealPlans == [breakfast])
        #expect(store.plans == [breakfast])
    }

    // MARK: - Manager on entities

    @Test func editsGoToTheStoreAndTheKeptCopy() {
        let store = InMemoryMealPlanStore()
        let sut = manager(store)
        sut.addMealPlan(tonight)
        sut.addMealPlan(breakfast)
        sut.toggleCompletion(breakfast)
        sut.removeMealPlan(tonight)
        #expect(store.plans == sut.mealPlans)
        #expect(keptCopy() == sut.mealPlans)
        #expect(store.plans.map(\.isCompleted) == [true])
    }

    @Test func removeAllMealPlansEmptiesTheStore() {
        let store = InMemoryMealPlanStore(both)
        let sut = manager(store)
        sut.removeAllMealPlans()
        #expect(sut.mealPlans.isEmpty)
        #expect(store.plans.isEmpty)
        #expect(manager(store).mealPlans.isEmpty)
    }

    @Test func resetAsSettingsRunsItClearsPlans() {
        // DataManagementSettingsView: LocalStore.clearAll() (drops blob + flag), then removeAllMealPlans().
        writeBlob(both)
        let store = InMemoryMealPlanStore()
        let sut = manager(store)
        storage.clearAll()
        sut.removeAllMealPlans()
        #expect(sut.mealPlans.isEmpty)
        #expect(manager(store).mealPlans.isEmpty)
    }

    @Test func aResetWhoseDeleteFailsIsFinishedNextLaunch() {
        let store = InMemoryMealPlanStore(both)
        let sut = manager(store)
        store.failWrites = true
        sut.removeAllMealPlans()
        #expect(sut.mealPlans.isEmpty)

        store.failWrites = false
        #expect(manager(store).mealPlans.isEmpty)
        #expect(store.plans.isEmpty)
    }

    // MARK: - Core Data store (framework exemption: in-memory SQLite, like CoreDataStorePersistenceTests)

    @Test func coreDataStoreRoundTripsEveryFieldInOrder() throws {
        let sut = CoreDataMealPlanStore(persistence: PersistenceController(inMemory: true))
        try sut.replaceMealPlans(with: [breakfast, tonight])
        #expect(try sut.fetchMealPlans() == [breakfast, tonight])
        try sut.replaceMealPlans(with: [tonight, breakfast])
        #expect(try sut.fetchMealPlans() == [tonight, breakfast])
    }

    @Test func coreDataStoreKeepsTodaysExactTimes() throws {
        // Plans made in the app carry sub-second dates; a lossy round trip would fail the copy check every launch.
        let now = MealPlanModel(recipeId: UUID(), recipeName: "Soup", date: Date(), mealTime: .lunch,
                                reminderTime: Date())
        let sut = CoreDataMealPlanStore(persistence: PersistenceController(inMemory: true))
        try sut.replaceMealPlans(with: [now])
        #expect(try sut.fetchMealPlans() == [now])
    }

    @Test func coreDataStoreClearsOptionalFields() throws {
        let sut = CoreDataMealPlanStore(persistence: PersistenceController(inMemory: true))
        try sut.replaceMealPlans(with: [tonight])
        var cleared = tonight
        cleared.notes = nil
        cleared.reminderTime = nil
        try sut.replaceMealPlans(with: [cleared])
        #expect(try sut.fetchMealPlans() == [cleared])
    }

    @Test func coreDataStoreUpdatesExistingRowsInsteadOfReinserting() throws {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let sut = CoreDataMealPlanStore(persistence: persistence)
        try sut.replaceMealPlans(with: both)
        let request = NSFetchRequest<NSManagedObject>(entityName: CoreDataMealPlanStore.entityName)
        let idsBefore = Set(try context.fetch(request).map(\.objectID))

        var moved = tonight
        moved.servings = 6
        try sut.replaceMealPlans(with: [moved, breakfast])
        #expect(Set(try context.fetch(request).map(\.objectID)) == idsBefore)
        #expect(try sut.fetchMealPlans() == [moved, breakfast])

        try sut.replaceMealPlans(with: [breakfast])
        #expect(try context.count(for: request) == 1)
    }

    @Test func coreDataStoreSkipsARowWithoutARecipeAndCleansUpDuplicates() throws {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let sut = CoreDataMealPlanStore(persistence: persistence)
        try sut.replaceMealPlans(with: [tonight])
        let entity = try #require(NSEntityDescription.entity(forEntityName: CoreDataMealPlanStore.entityName,
                                                             in: context))
        NSManagedObject(entity: entity, insertInto: context).setValue(tonight.id, forKey: "id")   // a sync duplicate
        try context.save()
        #expect(try sut.fetchMealPlans() == [tonight])   // the half-empty duplicate isn't shown

        try sut.replaceMealPlans(with: [tonight])
        let request = NSFetchRequest<NSManagedObject>(entityName: CoreDataMealPlanStore.entityName)
        #expect(try context.count(for: request) == 1)
    }
}
