import Testing
import CoreData
import Foundation
@testable import RecipeFinder

/// Recently Deleted (Data safety 4/4): a deleted recipe is hidden everywhere but kept with its photos for 30 days,
/// can be restored or deleted for good, and goes (photos too) once 30 days have passed. In-memory store + a temp
/// documents folder; sync is off in unit tests, so iCloud photo rows are removed straight from the store.
@MainActor
@Suite struct RecentlyDeletedTests {
    private let documents: URL
    private let controller = PersistenceController(inMemory: true)
    /// Fresh per test: never synced, unless a test says otherwise.
    private let syncStorage: LocalStore
    private var context: NSManagedObjectContext { controller.container.viewContext }
    private static let jpeg = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46])
    private static let day: TimeInterval = 24 * 60 * 60
    private static let monday = Date(timeIntervalSince1970: 1_794_000_000)

    init() throws {
        documents = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
        syncStorage = LocalStore(userDefaults: try #require(UserDefaults(suiteName: UUID().uuidString)))
    }

    // MARK: - How long it's kept

    @Test(arguments: [(0.0, false), (29.9, false), (30.1, true), (45.0, true)])
    func aRecipeIsKeptForThirtyDays(daysAgo: Double, expired: Bool) {
        let now = Self.monday.addingTimeInterval(daysAgo * Self.day)

        #expect(RecentlyDeleted.mayPurge(deletedAt: Self.monday, now: now, sync: .neverSynced) == expired)
    }

    @Test(arguments: [(-2.0, 30, "30 days left"), (0.0, 30, "30 days left"), (0.5, 30, "30 days left"), (29.5, 1, "1 day left"),
                      (30.0, 0, "Removed soon"), (31.0, 0, "Removed soon")])
    func theDaysLeftCountDown(daysAgo: Double, days: Int, text: String) {
        let item = DeletedRecipe(recipe: Self.recipe("Pie"), deletedAt: Self.monday)
        let now = Self.monday.addingTimeInterval(daysAgo * Self.day)

        #expect(RecentlyDeleted.daysLeft(item, now: now) == days)
        #expect(RecentlyDeleted.daysLeftText(item, now: now) == text)
    }

    @Test func eachRecipeIsListedOnceWithItsLatestDeleteNewestFirst() {
        let pie = Self.recipe("Pie")
        let soup = Self.recipe("Soup")
        let items = [
            DeletedRecipe(recipe: pie, deletedAt: Self.monday.addingTimeInterval(2 * Self.day)),
            DeletedRecipe(recipe: soup, deletedAt: Self.monday.addingTimeInterval(Self.day)),
            DeletedRecipe(recipe: pie, deletedAt: Self.monday),
        ]

        let listed = RecentlyDeleted.oneEach(items)

        #expect(listed.map(\.id) == [pie.id, soup.id])
        #expect(listed.first?.deletedAt == Self.monday.addingTimeInterval(2 * Self.day))
    }

    // MARK: - When a device may remove it for good

    /// (ever synced, last export start in days after the stamp or nil, import seen this launch, days since the stamp,
    /// may purge). Plain numbers: arguments are built outside the suite's main actor.
    @Test(arguments: [
        // Never synced: 30 days is enough.
        (false, nil, false, 31.0, true),
        (false, nil, false, 29.0, false),
        // Synced: also needs the stamp sent and this launch's import in.
        (true, 1.0, true, 31.0, true),
        (true, 1.0, false, 31.0, false),
        (true, -1.0, true, 31.0, false),
        (true, nil, true, 31.0, false),
        (true, 1.0, true, 29.0, false),
    ] as [(Bool, Double?, Bool, Double, Bool)])
    func aRecipeGoesOnlyOnceEveryDeviceHasHadItsThirtyDays(
        everSynced: Bool, exportDays: Double?, importSeen: Bool, daysSince: Double, purged: Bool
    ) {
        let sync = RecentlyDeleted.SyncState(
            everSynced: everSynced,
            lastExportStart: exportDays.map { Self.monday.addingTimeInterval($0 * Self.day) },
            importSeenThisLaunch: importSeen
        )
        let now = Self.monday.addingTimeInterval(daysSince * Self.day)

        #expect(RecentlyDeleted.mayPurge(deletedAt: Self.monday, now: now, sync: sync) == purged)
    }

    @Test func aStampFromAClockAheadCountsAsMadeNow() {
        let now = Self.monday
        let future = now.addingTimeInterval(40 * Self.day)

        #expect(RecentlyDeleted.effectiveStamp(future, now: now) == now)
        #expect(RecentlyDeleted.effectiveStamp(now.addingTimeInterval(3600), now: now) == now.addingTimeInterval(3600))
        #expect(!RecentlyDeleted.mayPurge(deletedAt: future, now: now, sync: .neverSynced))
    }

    @Test func aBuiltInRecipeInRecentlyDeletedIsNotSeededBack() {
        let kept = Self.recipe("Kept")
        let trashed = Self.recipe("Trashed")
        let new = Self.recipe("New")

        let seeded = RecentlyDeleted.recipesToSeed(bundled: [kept, trashed, new], existing: [kept], trashed: [trashed.id])

        #expect(seeded.map(\.id) == [new.id])
    }

    // MARK: - Hidden everywhere

    @Test func aDeletedRecipeIsHiddenFromEveryLibraryRead() async throws {
        let kept = Self.recipe("Kept")
        let gone = Self.recipe("Gone")
        #expect(controller.saveRecipeModel(kept))
        #expect(controller.saveRecipeModel(gone))

        #expect(controller.moveRecipeToRecentlyDeleted(withId: gone.id, at: Self.monday))

        #expect(controller.fetchRecipes().map(\.id) == [kept.id])
        #expect(await controller.fetchRecipesAsync().map(\.id) == [kept.id])
        #expect(controller.fetchRecipe(withId: gone.id) == nil)
        #expect(controller.fetchRecipeCount() == 1)
        #expect(controller.fetchCollectedRecipeCount() == 1)
        #expect(BackupService(recipeStore: controller).makeArchive().recipes.map(\.id) == [kept.id])
        #expect(controller.fetchRecentlyDeletedRecipes().map(\.id) == [gone.id])
        #expect(controller.fetchRecentlyDeletedRecipes().first?.deletedAt == Self.monday)
    }

    @Test func aRecipeDeletedInTheStoreLeavesTheLoadedLibrary() async {
        let store = makeStore()
        let pie = Self.recipe("Pie")
        #expect(store.add(pie))

        #expect(store.delete(id: pie.id))
        await store.refresh()

        #expect(store.recipes.isEmpty)
        #expect(store.recentlyDeleted.map(\.id) == [pie.id])
    }

    @Test func aRecipeDeletedBeforeTheLibraryLoadedStillShowsInRecentlyDeleted() {
        let store = makeStore()
        let pie = Self.recipe("Pie")
        #expect(controller.saveRecipeModel(pie))

        #expect(store.delete(id: pie.id))

        #expect(store.recentlyDeleted.map(\.id) == [pie.id])
    }

    @Test func aQuickSnackHeldOnlyInMemoryJustLeavesTheList() {
        let store = makeStore()
        let snack = Self.recipe("Snack")
        store.recipes = [snack]

        #expect(store.delete(id: snack.id))
        #expect(store.recipes.isEmpty)
        #expect(store.recentlyDeleted.isEmpty)
    }

    @Test func aRecipeAlreadyInRecentlyDeletedCannotBeDeletedAgain() {
        let store = makeStore()
        let pie = Self.recipe("Pie")
        #expect(store.add(pie))
        #expect(store.delete(id: pie.id))

        #expect(!store.delete(id: pie.id))
        #expect(controller.fetchRecentlyDeletedRecipes().map(\.id) == [pie.id])
    }

    // MARK: - Restore

    @Test func aRestoredRecipeIsBackInTheLibraryWithItsPhoto() async throws {
        let store = makeStore()
        let pie = Self.recipe("Pie", image: "RecipeImages/pie.jpg")
        try writeFile("RecipeImages/pie.jpg")
        #expect(store.add(pie))
        #expect(store.delete(id: pie.id))

        #expect(store.restore(id: pie.id))

        #expect(store.recipes.map(\.id) == [pie.id])
        #expect(store.recentlyDeleted.isEmpty)
        #expect(controller.fetchRecipe(withId: pie.id)?.imageName == "RecipeImages/pie.jpg")
        #expect(controller.fetchRecentlyDeletedRecipes().isEmpty)
        #expect(fileExists("RecipeImages/pie.jpg"))
    }

    @Test func aRestoredRecipeTakesItsPlaceInNameOrder() {
        let store = makeStore()
        let apple = Self.recipe("Apple")
        let banana = Self.recipe("banana")
        let cherry = Self.recipe("Cherry")
        for recipe in [apple, banana, cherry] { #expect(store.add(recipe)) }
        #expect(store.delete(id: banana.id))

        #expect(store.restore(id: banana.id))

        #expect(store.recipes.map(\.name) == ["Apple", "banana", "Cherry"])
    }

    @Test func backgroundTouchUpsLeaveARecentlyDeletedRecipeAlone() async {
        let pie = Self.recipe("Pie")
        #expect(controller.saveRecipeModel(pie))
        #expect(controller.moveRecipeToRecentlyDeleted(withId: pie.id))
        let renamed = RecipeModel(
            id: pie.id, name: "Renamed", category: "Dinner", difficulty: "Easy", prepTime: "5 min",
            cookingTime: "10 min", baseServings: 2, ingredients: pie.ingredients, prePrepInstructions: [],
            instructions: ["Cook"], notes: ""
        )

        #expect(await controller.updateRecipesInBackground([renamed]))
        #expect(!controller.updateRecipe(renamed))

        #expect(controller.fetchRecipes().isEmpty)
        #expect(controller.fetchRecentlyDeletedRecipes().map(\.recipe.name) == ["Pie"])
    }

    @Test func restoringABackupBringsARecentlyDeletedRecipeBack() {
        let pie = Self.recipe("Pie")
        #expect(controller.saveRecipeModel(pie))
        #expect(controller.moveRecipeToRecentlyDeleted(withId: pie.id))

        controller.mergeRecipes([pie])

        #expect(controller.fetchRecipes().map(\.id) == [pie.id])
        #expect(controller.fetchRecentlyDeletedRecipes().isEmpty)
    }

    // MARK: - Photos kept until it really goes

    @Test func deletingKeepsThePhotoFilesAndTheirICloudCopy() async throws {
        try insertPhotoRow("RecipeImages/pie.jpg")
        try writeFile("RecipeImages/pie.jpg")
        try writeFile("RecipeImages/pie_g1.jpg")
        let store = makeStore()
        let pie = Self.recipe("Pie", image: "RecipeImages/pie.jpg", photos: ["RecipeImages/pie_g1.jpg"])
        #expect(store.add(pie))

        #expect(store.delete(id: pie.id))
        await store.photoSync?.value

        #expect(fileExists("RecipeImages/pie.jpg"))
        #expect(fileExists("RecipeImages/pie_g1.jpg"))
        #expect(try photoRowCount() == 1)
    }

    @Test func deletingForeverRemovesTheRecipeItsPhotosAndTheirICloudCopy() async throws {
        try insertPhotoRow("RecipeImages/pie.jpg")
        try writeFile("RecipeImages/pie.jpg")
        let store = makeStore()
        let pie = Self.recipe("Pie", image: "RecipeImages/pie.jpg")
        #expect(store.add(pie))
        #expect(store.delete(id: pie.id))

        #expect(store.deleteForever(id: pie.id))
        await store.photoSync?.value

        #expect(store.recentlyDeleted.isEmpty)
        #expect(controller.fetchRecentlyDeletedRecipes().isEmpty)
        #expect(!fileExists("RecipeImages/pie.jpg"))
        #expect(try photoRowCount() == 0)
    }

    @Test func aPhotoAnotherRecentlyDeletedRecipeShowsStaysUntilThatOneGoes() async throws {
        try insertPhotoRow("RecipeImages/shared.jpg")
        try writeFile("RecipeImages/shared.jpg")
        let store = makeStore()
        let pie = Self.recipe("Pie", image: "RecipeImages/shared.jpg")
        let tart = Self.recipe("Tart", image: "RecipeImages/shared.jpg")
        #expect(store.add(pie))
        #expect(store.add(tart))
        #expect(store.delete(id: pie.id))
        #expect(store.delete(id: tart.id))

        #expect(store.deleteForever(id: pie.id))
        await store.photoSync?.value
        #expect(fileExists("RecipeImages/shared.jpg"))
        #expect(try photoRowCount() == 1)

        #expect(store.deleteForever(id: tart.id))
        await store.photoSync?.value
        #expect(!fileExists("RecipeImages/shared.jpg"))
        #expect(try photoRowCount() == 0)
    }

    @Test func aRecipeInTheLibraryCannotBeDeletedForever() {
        let store = makeStore()
        let pie = Self.recipe("Pie")
        #expect(store.add(pie))

        #expect(!store.deleteForever(id: pie.id))
        #expect(controller.fetchRecipes().map(\.id) == [pie.id])
    }

    @Test func aLibraryCopyWithTheSameIdIsLeftWhenTheDeletedOneGoes() throws {
        // With iCloud sync, another device's copy of a built-in recipe can arrive after this one was deleted.
        let pie = Self.recipe("Pie")
        #expect(controller.saveRecipe(parameters: .init(from: pie)))
        #expect(controller.moveRecipeToRecentlyDeleted(withId: pie.id))
        #expect(controller.saveRecipe(parameters: .init(from: pie)))

        #expect(controller.deleteRecentlyDeletedRecipe(withId: pie.id))

        #expect(controller.fetchRecipes().map(\.id) == [pie.id])
        #expect(controller.fetchRecentlyDeletedRecipes().isEmpty)
    }

    @Test func aRecentlyDeletedRecipesPhotosStillCountAsShownAfterAResetElsewhereCheck() throws {
        let pie = Self.recipe("Pie", image: "RecipeImages/pie.jpg")
        #expect(controller.saveRecipeModel(pie))
        #expect(controller.moveRecipeToRecentlyDeleted(withId: pie.id))

        let view = try ErasedPhotoCleanup.storeView(in: context)

        #expect(view.referencedPaths == ["RecipeImages/pie.jpg"])
    }

    // MARK: - After 30 days

    @Test func afterThirtyDaysTheRecipeAndItsPhotosGo() async throws {
        try insertPhotoRow("RecipeImages/old.jpg")
        try writeFile("RecipeImages/old.jpg")
        try writeFile("RecipeImages/new.jpg")
        let store = makeStore()
        let old = Self.recipe("Old", image: "RecipeImages/old.jpg")
        let new = Self.recipe("New", image: "RecipeImages/new.jpg")
        #expect(store.add(old))
        #expect(store.add(new))
        let now = Date()
        #expect(controller.moveRecipeToRecentlyDeleted(withId: old.id, at: now.addingTimeInterval(-31 * Self.day)))
        #expect(controller.moveRecipeToRecentlyDeleted(withId: new.id, at: now.addingTimeInterval(-29 * Self.day)))
        await store.refresh()

        let removed = await store.purgeExpired(now: now)
        store.syncPhotosWithICloud(removing: removed)
        await store.photoSync?.value

        #expect(store.recentlyDeleted.map(\.id) == [new.id])
        #expect(controller.fetchRecentlyDeletedRecipes().map(\.id) == [new.id])
        #expect(!fileExists("RecipeImages/old.jpg"))
        #expect(fileExists("RecipeImages/new.jpg"))
        #expect(try photoRowCount() == 0)
    }

    @Test func aRecipeRestoredElsewhereBeforeThePurgeIsKept() async {
        // The list was read before another device's restore arrived: the purge re-checks the row's date.
        let store = makeStore()
        let pie = Self.recipe("Pie")
        #expect(store.add(pie))
        #expect(controller.moveRecipeToRecentlyDeleted(withId: pie.id, at: Date().addingTimeInterval(-31 * Self.day)))
        await store.refresh()
        #expect(controller.restoreRecentlyDeletedRecipe(withId: pie.id))

        #expect(await store.purgeExpired(now: Date()).isEmpty)
        #expect(controller.fetchRecipes().map(\.id) == [pie.id])
    }

    @Test func launchingRemovesRecipesDeletedOverThirtyDaysAgo() async throws {
        try writeFile("RecipeImages/old.jpg")
        let old = Self.recipe("Old", image: "RecipeImages/old.jpg")
        #expect(controller.saveRecipeModel(old))
        #expect(controller.moveRecipeToRecentlyDeleted(withId: old.id, at: Date().addingTimeInterval(-31 * Self.day)))
        let store = makeStore()

        store.load()
        for _ in 0..<500 where store.isLoading {
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(!store.isLoading)
        #expect(store.recentlyDeleted.isEmpty)
        #expect(controller.fetchRecentlyDeletedRecipes().isEmpty)
        #expect(!fileExists("RecipeImages/old.jpg"))
    }

    @Test func copiesOfOneRecipeGoTogetherByTheLatestDelete() async throws {
        // Two devices' copies of a built-in recipe, deleted 31 and 5 days ago: neither goes yet, photos stay.
        try writeFile("RecipeImages/pie.jpg")
        let pie = Self.recipe("Pie", image: "RecipeImages/pie.jpg")
        let now = Date()
        #expect(controller.saveRecipe(parameters: .init(from: pie)))
        #expect(controller.moveRecipeToRecentlyDeleted(withId: pie.id, at: now.addingTimeInterval(-31 * Self.day)))
        #expect(controller.saveRecipe(parameters: .init(from: pie)))
        #expect(controller.moveRecipeToRecentlyDeleted(withId: pie.id, at: now.addingTimeInterval(-5 * Self.day)))
        let store = makeStore()

        #expect(await store.purgeExpired(now: now).isEmpty)
        #expect(store.recentlyDeleted.map(\.deletedAt) == [now.addingTimeInterval(-5 * Self.day)])
        #expect(controller.recipeRowCount(withId: pie.id) == 2)
        #expect(fileExists("RecipeImages/pie.jpg"))

        _ = await store.purgeExpired(now: now.addingTimeInterval(26 * Self.day))
        #expect(store.recentlyDeleted.isEmpty)
        #expect(controller.recipeRowCount(withId: pie.id) == 0)
        #expect(!fileExists("RecipeImages/pie.jpg"))
    }

    @Test func aDeviceThatHasSyncedWaitsForThisLaunchsICloudChangesBeforePurging() async {
        syncStorage.set(true, forKey: SyncPreference.everSyncedKey)
        HistoryPurgeRule.recordExport(startedAt: Date(), in: syncStorage)
        let store = makeStore()
        let pie = Self.recipe("Pie")
        #expect(store.add(pie))
        #expect(controller.moveRecipeToRecentlyDeleted(withId: pie.id, at: Date().addingTimeInterval(-31 * Self.day)))

        #expect(await store.purgeExpired(now: Date()).isEmpty)
        #expect(store.recentlyDeleted.map(\.id) == [pie.id])

        controller.finishedICloudImportThisLaunch = true
        _ = await store.purgeExpired(now: Date())
        #expect(store.recentlyDeleted.isEmpty)
        #expect(controller.recipeRowCount(withId: pie.id) == 0)
    }

    @Test func aDeleteThisDeviceHasNotSentYetIsKept() async {
        syncStorage.set(true, forKey: SyncPreference.everSyncedKey)
        controller.finishedICloudImportThisLaunch = true
        HistoryPurgeRule.recordExport(startedAt: Date().addingTimeInterval(-40 * Self.day), in: syncStorage)
        let store = makeStore()
        let pie = Self.recipe("Pie")
        #expect(store.add(pie))
        #expect(controller.moveRecipeToRecentlyDeleted(withId: pie.id, at: Date().addingTimeInterval(-31 * Self.day)))

        #expect(await store.purgeExpired(now: Date()).isEmpty)
        #expect(store.recentlyDeleted.map(\.id) == [pie.id])
    }

    @Test func resetErasesRecentlyDeletedToo() {
        let pie = Self.recipe("Pie")
        #expect(controller.saveRecipeModel(pie))
        #expect(controller.moveRecipeToRecentlyDeleted(withId: pie.id))

        #expect(controller.deleteAllRecipes())

        #expect(controller.fetchRecentlyDeletedRecipes().isEmpty)
    }

    // MARK: - Helpers

    private var imageStore: RecipeImageStore { RecipeImageStore(documentsDirectory: documents) }

    private func makeStore() -> RecipeStore {
        RecipeStore(persistence: controller, imageStore: imageStore, syncStorage: syncStorage)
    }

    private static func recipe(_ name: String, image: String? = nil, photos: [String] = []) -> RecipeModel {
        RecipeModel(
            name: name, category: "Dinner", difficulty: "Easy", prepTime: "5 min", cookingTime: "10 min",
            baseServings: 2, ingredients: [Ingredient(baseQuantity: 1, unit: "", name: "flour")],
            prePrepInstructions: [], instructions: ["Cook"], notes: "", imageName: image, photoNames: photos
        )
    }

    private func writeFile(_ path: String) throws {
        let url = documents.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Self.jpeg.write(to: url)
    }

    private func fileExists(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: documents.appendingPathComponent(path).path)
    }

    private func insertPhotoRow(_ path: String) throws {
        let row = NSEntityDescription.insertNewObject(forEntityName: RecipePhotoSync.entityName, into: context)
        row.setValue(UUID(), forKey: "id")
        row.setValue(path, forKey: "path")
        row.setValue(Self.jpeg, forKey: "data")
        try context.save()
    }

    private func photoRowCount() throws -> Int {
        try context.count(for: NSFetchRequest<NSManagedObject>(entityName: RecipePhotoSync.entityName))
    }
}
