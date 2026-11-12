import Testing
import CoreData
import Foundation
@testable import RecipeFinder

/// Collection fake: an array, with switches to make reads or writes fail like a broken store.
@MainActor
final class InMemoryCollectionStore: CollectionStoring {
    var collections: [RecipeCollection]
    var failWrites = false
    var failReads = false
    /// Accepts writes but silently keeps nothing, so the re-read check is what catches it.
    var dropWrites = false

    init(_ collections: [RecipeCollection] = []) { self.collections = collections }

    func fetchCollections() throws -> [RecipeCollection] {
        if failReads { throw CollectionStoreError.storeUnavailable }
        return collections
    }

    func replaceCollections(with replacement: [RecipeCollection]) throws {
        if failWrites { throw CollectionStoreError.storeUnavailable }
        if !dropWrites { collections = replacement }
    }
}

/// Moving the collections blob out of `LocalStore` into `CollectionEntity` (Data safety 1/4, slice 3b).
@MainActor
@Suite struct CollectionMigrationTests {
    private let blobKey = Constants.UserDefaultsKeys.collections
    private let storage = LocalStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    private let soups = RecipeCollection(name: "Soups", colorName: .green, recipeIDs: [UUID(), UUID()],
                                         createdAt: Date(timeIntervalSinceReferenceDate: 800_000_000))
    private let baking = RecipeCollection(name: "Baking", colorName: .orange, recipeIDs: [UUID()],
                                          createdAt: Date(timeIntervalSinceReferenceDate: 800_100_000))
    private var both: [RecipeCollection] { [soups, baking] }

    private func writeBlob(_ collections: [RecipeCollection]) {
        storage.setEncodable(collections, forKey: blobKey)
    }

    private func keptCopy() -> [RecipeCollection]? {
        storage.decodable([RecipeCollection].self, forKey: blobKey)
    }

    private func migrated() -> Bool {
        storage.bool(forKey: MirroredSnapshot<RecipeCollection>.flagKey(for: blobKey))
    }

    private func manager(_ store: any CollectionStoring) -> CollectionManager {
        CollectionManager(storage: storage, collectionStore: store)
    }

    // MARK: - Migration

    @Test func everyBlobCollectionBecomesARowInOrderAndTheKeyIsMarked() {
        writeBlob(both)
        let store = InMemoryCollectionStore()
        let sut = manager(store)
        #expect(store.collections == both)
        #expect(sut.collections == both)
        #expect(migrated())
    }

    @Test func theOldBlobIsKeptForOneRelease() {
        writeBlob(both)
        _ = manager(InMemoryCollectionStore())
        #expect(keptCopy() == both)
    }

    @Test func aMigratedKeyIsNotCopiedAgain() {
        writeBlob(both)
        let store = InMemoryCollectionStore()
        _ = manager(store)
        store.failWrites = true   // a second copy would throw and fall back to the blob
        let again = manager(store)
        #expect(again.collections == both)
        #expect(migrated())
    }

    @Test func noBlobMeansNothingToMoveAndIsMarked() {
        let store = InMemoryCollectionStore()
        let sut = manager(store)
        #expect(sut.collections.isEmpty)
        #expect(migrated())
    }

    @Test func aCorruptBlobIsKeptAsideAndTheStoreIsLeftAlone() {
        storage.set(Data("not json".utf8), forKey: blobKey)
        let store = InMemoryCollectionStore([soups])
        let sut = manager(store)
        #expect(sut.collections == [soups])
        #expect(store.collections == [soups])
        #expect(storage.data(forKey: blobKey + ".corrupt") == Data("not json".utf8))
    }

    @Test func aFailedWriteLeavesTheKeyUnmarkedAndTheCookKeepsTheirCollections() {
        writeBlob(both)
        let store = InMemoryCollectionStore()
        store.failWrites = true
        let sut = manager(store)
        #expect(!migrated())
        #expect(sut.collections == both)
    }

    @Test func aWriteThatDoesNotStickFailsTheCheck() {
        writeBlob(both)
        let store = InMemoryCollectionStore()
        store.dropWrites = true
        let sut = manager(store)
        #expect(!migrated())
        #expect(sut.collections == both)
    }

    @Test func aRetryAfterAHalfFinishedRunDoesNotDuplicate() {
        writeBlob(both)
        let store = InMemoryCollectionStore([soups])   // first run saved one row, then the app died
        let sut = manager(store)
        #expect(store.collections == both)
        #expect(sut.collections == both)
    }

    // MARK: - Changes while the store can't be used

    @Test func editsMadeWhileTheStoreCouldNotBeWrittenAreMovedNextLaunchWithoutDuplicates() {
        let store = InMemoryCollectionStore()
        _ = manager(store)                     // empty store, migrated
        store.collections = both
        store.failWrites = true
        let broken = manager(store)
        broken.rename(soups, to: "Winter soups")
        broken.createCollection(name: "Quick", color: .red)

        store.failWrites = false
        let nextLaunch = manager(store)
        #expect(nextLaunch.collections.map(\.name) == ["Winter soups", "Baking", "Quick"])
        #expect(store.collections.map(\.name) == ["Winter soups", "Baking", "Quick"])
        #expect(migrated())
    }

    @Test func aDeleteMadeWhileTheStoreCannotBeReadStaysDeleted() {
        writeBlob(both)
        let store = InMemoryCollectionStore()
        _ = manager(store)
        store.failReads = true
        let broken = manager(store)
        #expect(broken.collections == both)   // kept copy is current
        broken.delete(soups)

        store.failReads = false
        let nextLaunch = manager(store)
        #expect(nextLaunch.collections == [baking])
        #expect(store.collections == [baking])
    }

    @Test func aSingleRenameWhoseSaveFailsIsKeptNextLaunch() {
        writeBlob(both)
        let store = InMemoryCollectionStore()
        let sut = manager(store)
        store.failWrites = true
        sut.rename(soups, to: "Winter soups")

        store.failWrites = false
        let nextLaunch = manager(store)
        #expect(nextLaunch.collections.map(\.name) == ["Winter soups", "Baking"])
        #expect(store.collections.map(\.name) == ["Winter soups", "Baking"])
    }

    @Test func anUnreadableStoreWithNoKeptCopyIsNeverOverwritten() {
        let store = InMemoryCollectionStore(both)   // e.g. kept copy was corrupt and set aside
        _ = manager(store)
        store.failReads = true
        let broken = manager(store)
        #expect(broken.collections.isEmpty)
        broken.createCollection(name: "Quick")
        broken.purge(recipeID: soups.recipeIDs[0])

        store.failReads = false
        let nextLaunch = manager(store)
        #expect(nextLaunch.collections == both)
        #expect(store.collections == both)
    }

    @Test func aChangeWhoseSaveFailsIsKeptNextLaunch() {
        let store = InMemoryCollectionStore()
        let sut = manager(store)
        store.failWrites = true
        sut.createCollection(name: "Weeknight")

        store.failWrites = false
        let nextLaunch = manager(store)
        #expect(nextLaunch.collections.map(\.name) == ["Weeknight"])
        #expect(store.collections.map(\.name) == ["Weeknight"])
    }

    @Test func aStoreThatComesBackEmptyIsRefilledFromTheKeptCopy() {
        let store = InMemoryCollectionStore()
        let sut = manager(store)
        sut.createCollection(name: "Weeknight")   // after the move: the kept copy must stay current
        store.collections = []                     // recovery replaced an unreadable store with an empty one
        let nextLaunch = manager(store)
        #expect(nextLaunch.collections.map(\.name) == ["Weeknight"])
        #expect(store.collections.map(\.name) == ["Weeknight"])
    }

    @Test func aKeptCopyNewerThanTheStoreWinsNextLaunch() {
        // The app was killed between writing the kept copy and the store, or an older blob-only build ran in between.
        let store = InMemoryCollectionStore()
        let sut = manager(store)
        sut.createCollection(name: "Weeknight")
        var renamed = sut.collections
        renamed[0].name = "School nights"
        writeBlob(renamed)
        let nextLaunch = manager(store)
        #expect(nextLaunch.collections == renamed)
        #expect(store.collections == renamed)
    }

    @Test func deletingTheLastCollectionIsNotUndoneByTheRefill() {
        let store = InMemoryCollectionStore([soups])
        let sut = manager(store)
        sut.delete(soups)
        let nextLaunch = manager(store)
        #expect(nextLaunch.collections.isEmpty)
    }

    // MARK: - Manager on entities

    @Test func editsGoToTheStoreAndTheKeptCopy() {
        let store = InMemoryCollectionStore()
        let sut = manager(store)
        sut.createCollection(name: "Weeknight", color: .teal)
        sut.recolor(sut.collections[0], to: .pink)
        #expect(store.collections == sut.collections)
        #expect(keptCopy() == sut.collections)
        #expect(store.collections.first?.colorName == .pink)
    }

    @Test func removeAllCollectionsEmptiesTheStore() {
        let store = InMemoryCollectionStore(both)
        let sut = manager(store)
        sut.removeAllCollections()
        #expect(sut.collections.isEmpty)
        #expect(store.collections.isEmpty)
        #expect(manager(store).collections.isEmpty)
    }

    @Test func resetAsSettingsRunsItClearsCollections() {
        // DataManagementSettingsView: LocalStore.clearAll() (drops blob + flag), then removeAllCollections().
        writeBlob(both)
        let store = InMemoryCollectionStore()
        let sut = manager(store)
        storage.clearAll()
        sut.removeAllCollections()
        #expect(sut.collections.isEmpty)
        #expect(manager(store).collections.isEmpty)
    }

    @Test func aResetWhoseDeleteFailsIsFinishedNextLaunch() {
        let store = InMemoryCollectionStore(both)
        let sut = manager(store)
        store.failWrites = true
        sut.removeAllCollections()
        #expect(sut.collections.isEmpty)

        store.failWrites = false
        let nextLaunch = manager(store)
        #expect(nextLaunch.collections.isEmpty)
        #expect(store.collections.isEmpty)
    }

    @Test func collectionsMadeAfterAFailedResetSurviveTheRetriedWipe() {
        let store = InMemoryCollectionStore(both)
        let sut = manager(store)
        store.failWrites = true
        sut.removeAllCollections()
        sut.createCollection(name: "Fresh start")

        store.failWrites = false
        let nextLaunch = manager(store)
        #expect(nextLaunch.collections.map(\.name) == ["Fresh start"])
        #expect(store.collections.map(\.name) == ["Fresh start"])
    }

    // MARK: - Core Data store (framework exemption: in-memory SQLite, like CoreDataStorePersistenceTests)

    @Test func coreDataStoreRoundTripsEveryFieldInOrder() throws {
        let sut = CoreDataCollectionStore(persistence: PersistenceController(inMemory: true))
        try sut.replaceCollections(with: [baking, soups])
        #expect(try sut.fetchCollections() == [baking, soups])
        try sut.replaceCollections(with: [soups, baking])
        #expect(try sut.fetchCollections() == [soups, baking])
    }

    @Test func coreDataStoreUpdatesRowsInPlaceAndDropsRemovedOnes() throws {
        let persistence = PersistenceController(inMemory: true)
        let sut = CoreDataCollectionStore(persistence: persistence)
        try sut.replaceCollections(with: both)
        var renamed = soups
        renamed.name = "Winter soups"
        renamed.recipeIDs.append(UUID())
        try sut.replaceCollections(with: [renamed])
        #expect(try sut.fetchCollections() == [renamed])
        let request = NSFetchRequest<NSManagedObject>(entityName: CoreDataCollectionStore.entityName)
        let rows = try persistence.container.viewContext.fetch(request)
        #expect(rows.count == 1)
        #expect(rows.first?.value(forKey: "name") as? String == "Winter soups")
        try sut.replaceCollections(with: [])
        #expect(try sut.fetchCollections().isEmpty)
    }

    @Test func coreDataStoreUpdatesExistingRowsInsteadOfReinserting() throws {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let sut = CoreDataCollectionStore(persistence: persistence)
        try sut.replaceCollections(with: both)
        let request = NSFetchRequest<NSManagedObject>(entityName: CoreDataCollectionStore.entityName)
        let idsBefore = Set(try context.fetch(request).map(\.objectID))

        var renamed = soups
        renamed.name = "Winter soups"
        try sut.replaceCollections(with: [renamed, baking])
        #expect(Set(try context.fetch(request).map(\.objectID)) == idsBefore)
    }

    @Test func coreDataStoreCleansUpRowsWithASharedOrMissingId() throws {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let sut = CoreDataCollectionStore(persistence: persistence)
        try sut.replaceCollections(with: [soups])
        let entity = try #require(NSEntityDescription.entity(forEntityName: CoreDataCollectionStore.entityName,
                                                             in: context))
        NSManagedObject(entity: entity, insertInto: context).setValue(soups.id, forKey: "id")   // a sync duplicate
        _ = NSManagedObject(entity: entity, insertInto: context)                                 // no id at all
        try context.save()

        try sut.replaceCollections(with: [soups])
        let request = NSFetchRequest<NSManagedObject>(entityName: CoreDataCollectionStore.entityName)
        #expect(try context.count(for: request) == 1)
        #expect(try sut.fetchCollections() == [soups])
    }

    @Test func coreDataStoreKeepsOtherCollectionsWhenOneRowIsUnreadable() throws {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let sut = CoreDataCollectionStore(persistence: persistence)
        try sut.replaceCollections(with: both)
        let request = NSFetchRequest<NSManagedObject>(entityName: CoreDataCollectionStore.entityName)
        request.predicate = NSPredicate(format: "id == %@", soups.id as CVarArg)
        try context.fetch(request).first?.setValue(Data("not json".utf8), forKey: "recipeIDs")
        try context.save()

        let fetched = try sut.fetchCollections()
        #expect(fetched.map(\.name) == ["Soups", "Baking"])
        #expect(fetched.first?.recipeIDs.isEmpty == true)
        #expect(fetched.last == baking)
    }
}
