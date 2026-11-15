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
    private var context: NSManagedObjectContext { controller.container.viewContext }
    private static let jpeg = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46])
    private static let day: TimeInterval = 24 * 60 * 60
    private static let monday = Date(timeIntervalSince1970: 1_794_000_000)

    init() throws {
        documents = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
    }

    // MARK: - How long it's kept

    @Test(arguments: [(0.0, false), (29.9, false), (30.1, true), (45.0, true)])
    func aRecipeIsKeptForThirtyDays(daysAgo: Double, expired: Bool) {
        let item = DeletedRecipe(recipe: Self.recipe("Pie"), deletedAt: Self.monday)

        #expect(RecentlyDeleted.isExpired(item, now: Self.monday.addingTimeInterval(daysAgo * Self.day)) == expired)
    }

    @Test(arguments: [(-2.0, 30, "30 days left"), (0.0, 30, "30 days left"), (0.5, 30, "30 days left"), (29.5, 1, "1 day left"),
                      (30.0, 0, "Removed soon"), (31.0, 0, "Removed soon")])
    func theDaysLeftCountDown(daysAgo: Double, days: Int, text: String) {
        let item = DeletedRecipe(recipe: Self.recipe("Pie"), deletedAt: Self.monday)
        let now = Self.monday.addingTimeInterval(daysAgo * Self.day)

        #expect(RecentlyDeleted.daysLeft(item, now: now) == days)
        #expect(RecentlyDeleted.daysLeftText(item, now: now) == text)
    }

    @Test func eachRecipeIsListedOnceWithItsFirstDeleteNewestFirst() {
        let pie = Self.recipe("Pie")
        let soup = Self.recipe("Soup")
        let items = [
            DeletedRecipe(recipe: pie, deletedAt: Self.monday.addingTimeInterval(2 * Self.day)),
            DeletedRecipe(recipe: soup, deletedAt: Self.monday.addingTimeInterval(Self.day)),
            DeletedRecipe(recipe: pie, deletedAt: Self.monday),
        ]

        let listed = RecentlyDeleted.oneEach(items)

        #expect(listed.map(\.id) == [soup.id, pie.id])
        #expect(listed.last?.deletedAt == Self.monday)
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
        let store = RecipeStore(persistence: controller, imageStore: imageStore)
        let pie = Self.recipe("Pie")
        #expect(store.add(pie))

        #expect(store.delete(id: pie.id))
        await store.refresh()

        #expect(store.recipes.isEmpty)
        #expect(store.recentlyDeleted.map(\.id) == [pie.id])
    }

    @Test func aRecipeDeletedBeforeTheLibraryLoadedStillShowsInRecentlyDeleted() {
        let store = RecipeStore(persistence: controller, imageStore: imageStore)
        let pie = Self.recipe("Pie")
        #expect(controller.saveRecipeModel(pie))

        #expect(store.delete(id: pie.id))

        #expect(store.recentlyDeleted.map(\.id) == [pie.id])
    }

    @Test func aRecipeTheStoreDoesNotHoldCannotBeDeleted() {
        let store = RecipeStore(persistence: controller, imageStore: imageStore)
        let snack = Self.recipe("Snack")
        store.recipes = [snack]

        #expect(!store.delete(id: snack.id))
        #expect(store.recipes.map(\.id) == [snack.id])
        #expect(store.recentlyDeleted.isEmpty)
    }

    // MARK: - Restore

    @Test func aRestoredRecipeIsBackInTheLibraryWithItsPhoto() async throws {
        let store = RecipeStore(persistence: controller, imageStore: imageStore)
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
        let store = RecipeStore(persistence: controller, imageStore: imageStore)
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
        let store = RecipeStore(persistence: controller, imageStore: imageStore)
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
        let store = RecipeStore(persistence: controller, imageStore: imageStore)
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
        let store = RecipeStore(persistence: controller, imageStore: imageStore)
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
        let store = RecipeStore(persistence: controller, imageStore: imageStore)
        let old = Self.recipe("Old", image: "RecipeImages/old.jpg")
        let new = Self.recipe("New", image: "RecipeImages/new.jpg")
        #expect(store.add(old))
        #expect(store.add(new))
        let now = Date()
        #expect(controller.moveRecipeToRecentlyDeleted(withId: old.id, at: now.addingTimeInterval(-31 * Self.day)))
        #expect(controller.moveRecipeToRecentlyDeleted(withId: new.id, at: now.addingTimeInterval(-29 * Self.day)))
        await store.refresh()

        let removed = store.purgeExpired(now: now)
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
        let store = RecipeStore(persistence: controller, imageStore: imageStore)
        let pie = Self.recipe("Pie")
        #expect(store.add(pie))
        #expect(controller.moveRecipeToRecentlyDeleted(withId: pie.id, at: Date().addingTimeInterval(-31 * Self.day)))
        await store.refresh()
        #expect(controller.restoreRecentlyDeletedRecipe(withId: pie.id))

        #expect(store.purgeExpired(now: Date()).isEmpty)
        #expect(controller.fetchRecipes().map(\.id) == [pie.id])
    }

    @Test func launchingRemovesRecipesDeletedOverThirtyDaysAgo() async throws {
        try writeFile("RecipeImages/old.jpg")
        let old = Self.recipe("Old", image: "RecipeImages/old.jpg")
        #expect(controller.saveRecipeModel(old))
        #expect(controller.moveRecipeToRecentlyDeleted(withId: old.id, at: Date().addingTimeInterval(-31 * Self.day)))
        let store = RecipeStore(persistence: controller, imageStore: imageStore)

        store.load()
        for _ in 0..<500 where store.isLoading {
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(!store.isLoading)
        #expect(store.recentlyDeleted.isEmpty)
        #expect(controller.fetchRecentlyDeletedRecipes().isEmpty)
        #expect(!fileExists("RecipeImages/old.jpg"))
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
