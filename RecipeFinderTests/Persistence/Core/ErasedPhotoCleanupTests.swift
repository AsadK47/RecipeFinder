import Testing
import CoreData
import Foundation
@testable import RecipeFinder

/// After a Reset (or the last photo deleted) on another device with iCloud sync on, this device's photo files go too
/// — but only on a strong signal: the store this device has seen photo rows in now holds none, and no recipe in it
/// shows one of the cook's photos. In-memory store + a temp documents folder; no real iCloud.
@MainActor
@Suite struct ErasedPhotoCleanupTests {
    private let documents: URL
    private let controller = PersistenceController(inMemory: true)
    private var context: NSManagedObjectContext { controller.container.viewContext }
    private static let jpeg = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46])
    private static let monday = Date(timeIntervalSince1970: 1_794_000_000)
    private static let tuesday = monday.addingTimeInterval(24 * 60 * 60)

    init() throws {
        documents = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
    }

    // MARK: - When to clear

    @Test func aStoreWithPhotoRowsIsRemembered() {
        let store = ErasedPhotoCleanup.StoreView(photoRows: 2, referencedPaths: ["RecipeImages/a.jpg"])

        #expect(ErasedPhotoCleanup.step(store: store, storeFile: "file-A", remembered: nil) == .remember("file-A"))
    }

    @Test func aRememberedStoreWithPhotoRowsNeedsNothing() {
        let store = ErasedPhotoCleanup.StoreView(photoRows: 2, referencedPaths: ["RecipeImages/a.jpg"])

        #expect(ErasedPhotoCleanup.step(store: store, storeFile: "file-A", remembered: "file-A") == .nothing)
    }

    @Test func theRememberedStoreLeftWithNoPhotosClearsThePhotoFiles() {
        let store = ErasedPhotoCleanup.StoreView(photoRows: 0, referencedPaths: [])

        #expect(ErasedPhotoCleanup.step(store: store, storeFile: "file-A", remembered: "file-A") == .clear)
    }

    @Test(arguments: [nil, "file-old"])
    func anEmptyStoreInANewFileKeepsThePhotos(remembered: String?) {
        // Recovery or a first import still on its way: the rows haven't arrived, nothing was erased.
        let store = ErasedPhotoCleanup.StoreView(photoRows: 0, referencedPaths: [])

        #expect(ErasedPhotoCleanup.step(store: store, storeFile: "file-A", remembered: remembered) == .nothing)
    }

    @Test func aRecipeThatStillShowsAPhotoKeepsThePhotos() {
        // Its row is on its way (or not sent yet): a recipe pointing at a photo is never an erased library.
        let store = ErasedPhotoCleanup.StoreView(photoRows: 0, referencedPaths: ["RecipeImages/a.jpg"])

        #expect(ErasedPhotoCleanup.step(store: store, storeFile: "file-A", remembered: "file-A") == .nothing)
    }

    @Test func anUnreadableStoreKeepsThePhotos() {
        #expect(ErasedPhotoCleanup.step(store: nil, storeFile: "file-A", remembered: "file-A") == .nothing)
    }

    @Test func anUnknownStoreFileKeepsThePhotos() {
        let store = ErasedPhotoCleanup.StoreView(photoRows: 0, referencedPaths: [])

        #expect(ErasedPhotoCleanup.step(store: store, storeFile: nil, remembered: "file-A") == .nothing)
    }

    // MARK: - Reading the store

    @Test func theStoreViewCountsPhotoRowsAndTheCooksPhotosRecipesShow() throws {
        #expect(controller.saveRecipeModel(Self.recipe(
            "Pie", image: "RecipeImages/a.jpg", photos: ["RecipeImages/a_g1.jpg", "https://example.com/c.jpg"]
        )))
        #expect(controller.saveRecipeModel(Self.recipe("Soup", image: "https://example.com/soup.jpg")))
        try insertRow(path: "RecipeImages/a.jpg")

        let view = try ErasedPhotoCleanup.storeView(in: context)

        #expect(view == ErasedPhotoCleanup.StoreView(
            photoRows: 1, referencedPaths: ["RecipeImages/a.jpg", "RecipeImages/a_g1.jpg"]
        ))
    }

    @Test func anErasedStoreReadsAsNoPhotos() throws {
        #expect(controller.saveRecipeModel(Self.recipe("Toast")))

        let view = try ErasedPhotoCleanup.storeView(in: context)

        #expect(view == ErasedPhotoCleanup.StoreView(photoRows: 0, referencedPaths: []))
    }

    // MARK: - Clearing files

    @Test func clearingRemovesTheCooksPhotoFilesWrittenBeforeTheCheck() throws {
        try writeFile("RecipeImages/a.jpg", modified: Self.monday)
        try writeFile("RecipeImages/a_g1.jpg", modified: Self.monday)

        let removed = try ErasedPhotoCleanup.removeFiles(in: documents, keeping: [], modifiedBefore: Self.tuesday)

        #expect(removed == 2)
        #expect(!exists("RecipeImages/a.jpg"))
        #expect(!exists("RecipeImages/a_g1.jpg"))
    }

    @Test func aPhotoSavedAfterTheCheckIsKept() throws {
        // The cook may have added a photo on this device while the check ran.
        try writeFile("RecipeImages/new.jpg", modified: Self.tuesday)

        let removed = try ErasedPhotoCleanup.removeFiles(in: documents, keeping: [], modifiedBefore: Self.monday)

        #expect(removed == 0)
        #expect(exists("RecipeImages/new.jpg"))
    }

    @Test func aPhotoARecipeShowsIsKept() throws {
        try writeFile("RecipeImages/a.jpg", modified: Self.monday)

        let removed = try ErasedPhotoCleanup.removeFiles(
            in: documents, keeping: ["RecipeImages/a.jpg"], modifiedBefore: Self.tuesday
        )

        #expect(removed == 0)
        #expect(exists("RecipeImages/a.jpg"))
    }

    @Test(arguments: ["RecipeImages/web-abc123.jpg", "RecipeImages/notes.txt", "RecipeImages/.hidden.jpg"])
    func filesThatAreNotTheCooksPhotosAreKept(path: String) throws {
        try writeFile(path, modified: Self.monday)

        let removed = try ErasedPhotoCleanup.removeFiles(in: documents, keeping: [], modifiedBefore: Self.tuesday)

        #expect(removed == 0)
        #expect(exists(path))
    }

    @Test func filesOutsideThePhotoFolderAreKept() throws {
        try writeFile("Other/a.jpg", modified: Self.monday)

        let removed = try ErasedPhotoCleanup.removeFiles(in: documents, keeping: [], modifiedBefore: Self.tuesday)

        #expect(removed == 0)
        #expect(exists("Other/a.jpg"))
    }

    @Test func noPhotoFolderClearsNothing() throws {
        #expect(try ErasedPhotoCleanup.removeFiles(in: documents, keeping: [], modifiedBefore: Self.tuesday) == 0)
    }

    // MARK: - Helpers

    private static func recipe(_ name: String, image: String? = nil, photos: [String] = []) -> RecipeModel {
        RecipeModel(
            name: name, category: "Dinner", difficulty: "Easy", prepTime: "5 min", cookingTime: "10 min",
            baseServings: 2, ingredients: [], prePrepInstructions: [], instructions: ["Cook"], notes: "",
            imageName: image, photoNames: photos
        )
    }

    private func writeFile(_ path: String, modified: Date) throws {
        let url = documents.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Self.jpeg.write(to: url)
        try FileManager.default.setAttributes([.modificationDate: modified], ofItemAtPath: url.path)
    }

    private func exists(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: documents.appendingPathComponent(path).path)
    }

    private func insertRow(path: String) throws {
        let row = NSEntityDescription.insertNewObject(forEntityName: RecipePhotoSync.entityName, into: context)
        row.setValue(UUID(), forKey: "id")
        row.setValue(path, forKey: "path")
        row.setValue(Self.jpeg, forKey: "data")
        row.setValue(Self.monday, forKey: "updatedAt")
        try context.save()
    }
}
