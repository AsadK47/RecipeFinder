import Testing
import CoreData
import Foundation
@testable import RecipeFinder

/// Recipe photos travel with iCloud sync (Data safety 2/4 slice 4b): the photo files on disk are mirrored into
/// `RecipePhotoEntity` rows (CloudKit carries those), and rows from another device are written back to disk.
/// In-memory store + a temp documents folder; no real iCloud.
@MainActor
@Suite struct RecipePhotoSyncTests {
    private let documents: URL
    private let controller = PersistenceController(inMemory: true)
    private var context: NSManagedObjectContext { controller.container.viewContext }
    private static let jpeg = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46])
    private static let otherJpeg = Data([0xFF, 0xD8, 0xFF, 0xE1, 0x00, 0x22, 0x45, 0x78, 0x69, 0x66])
    private static let monday = Date(timeIntervalSince1970: 1_794_000_000)
    private static let tuesday = monday.addingTimeInterval(24 * 60 * 60)

    init() throws {
        documents = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
    }

    // MARK: - Which photos travel

    @Test(arguments: [
        "RecipeImages/7D0B1A4C-2F3E-4C5D-9E8F-0A1B2C3D4E5F.jpg",
        "RecipeImages/7D0B1A4C-2F3E-4C5D-9E8F-0A1B2C3D4E5F_g1E2D3C4B-5A69-4788-9A0B-C1D2E3F40516.jpg"
    ])
    func theCooksOwnPhotosTravel(reference: String) {
        #expect(RecipePhotoSync.syncablePath(reference) == reference)
    }

    @Test(arguments: [
        "", "https://example.com/pie.jpg", "RecipeImages/web-abc123.jpg", "/var/mobile/Documents/RecipeImages/a.jpg",
        "RecipeImages/../secrets.jpg", "RecipeImages/sub/a.jpg", "RecipeImages/", "RecipeImages/a.png",
        "Other/a.jpg", "RecipeImages/.jpg", "pie_photo"
    ])
    func otherReferencesDoNotTravel(reference: String) {
        #expect(RecipePhotoSync.syncablePath(reference) == nil)
    }

    @Test func aRecipesHeroAndGalleryPhotosAreBothReferenced() {
        let withPhotos = Self.recipe("Pie", image: "RecipeImages/a.jpg",
                                     photos: ["RecipeImages/a_gb.jpg", "https://example.com/c.jpg"])
        let webOnly = Self.recipe("Soup", image: "https://example.com/soup.jpg")

        let paths = RecipePhotoSync.referencedPaths(in: [withPhotos, webOnly, Self.recipe("Toast")])

        #expect(paths == ["RecipeImages/a.jpg", "RecipeImages/a_gb.jpg"])
    }

    // MARK: - This device → store

    @Test func aPhotoOnlyOnThisDeviceIsCopiedIntoTheStore() throws {
        try writeFile("RecipeImages/a.jpg", Self.jpeg)

        let outcome = mirror(["RecipeImages/a.jpg"])

        #expect(outcome == RecipePhotoSync.Outcome(uploaded: 1, downloaded: 0))
        #expect(try storedRows() == ["RecipeImages/a.jpg": Self.jpeg])
    }

    @Test func aPhotoAlreadyInTheStoreIsNotCopiedAgain() throws {
        try writeFile("RecipeImages/a.jpg", Self.jpeg)
        mirror(["RecipeImages/a.jpg"])

        let second = mirror(["RecipeImages/a.jpg"])

        #expect(second == RecipePhotoSync.Outcome(uploaded: 0, downloaded: 0))
        #expect(try rowCount() == 1)
    }

    @Test func aReferencedPhotoMissingOnDiskIsSkipped() throws {
        let outcome = mirror(["RecipeImages/gone.jpg"])

        #expect(outcome == RecipePhotoSync.Outcome(uploaded: 0, downloaded: 0))
        #expect(try rowCount() == 0)
    }

    @Test func anUnreferencedOrWebCopyFileIsNotCopied() throws {
        try writeFile("RecipeImages/orphan.jpg", Self.jpeg)
        try writeFile("RecipeImages/web-abc.jpg", Self.jpeg)

        mirror(["RecipeImages/web-abc.jpg"])

        #expect(try rowCount() == 0)
    }

    @Test func manyPhotosAreAllCopied() throws {
        let paths = (0..<20).map { "RecipeImages/p\($0).jpg" }
        for path in paths { try writeFile(path, Self.jpeg) }

        let outcome = mirror(Set(paths))

        #expect(outcome.uploaded == 20)
        #expect(try Set(storedRows().keys) == Set(paths))
    }

    // MARK: - Store → this device

    @Test func aPhotoFromAnotherDeviceIsWrittenToDisk() throws {
        try insertRow(path: "RecipeImages/b.jpg", data: Self.jpeg)

        let outcome = mirror([])

        #expect(outcome == RecipePhotoSync.Outcome(uploaded: 0, downloaded: 1))
        #expect(try readFile("RecipeImages/b.jpg") == Self.jpeg)
    }

    @Test func aPhotoThatMatchesTheStoreIsLeftAlone() throws {
        try writeFile("RecipeImages/b.jpg", Self.jpeg, modified: Self.monday)
        try insertRow(path: "RecipeImages/b.jpg", data: Self.jpeg, updatedAt: Self.monday)

        let outcome = mirror(["RecipeImages/b.jpg"])

        #expect(outcome == RecipePhotoSync.Outcome(uploaded: 0, downloaded: 0))
    }

    @Test func aPhotoReplacedOnThisDeviceIsSentAgain() throws {
        try writeFile("RecipeImages/hero.jpg", Self.jpeg, modified: Self.monday)
        mirror(["RecipeImages/hero.jpg"])
        try writeFile("RecipeImages/hero.jpg", Self.otherJpeg, modified: Self.tuesday)

        let outcome = mirror(["RecipeImages/hero.jpg"])

        #expect(outcome == RecipePhotoSync.Outcome(uploaded: 1, downloaded: 0))
        #expect(try storedRows() == ["RecipeImages/hero.jpg": Self.otherJpeg])
    }

    @Test func aNewerPhotoFromAnotherDeviceReplacesTheOlderFile() throws {
        try writeFile("RecipeImages/hero.jpg", Self.jpeg, modified: Self.monday)
        try insertRow(path: "RecipeImages/hero.jpg", data: Self.otherJpeg, updatedAt: Self.tuesday)

        let outcome = mirror(["RecipeImages/hero.jpg"])

        #expect(outcome == RecipePhotoSync.Outcome(uploaded: 0, downloaded: 1))
        #expect(try readFile("RecipeImages/hero.jpg") == Self.otherJpeg)
    }

    @Test func aNewerPhotoOnThisDeviceIsNeverReplacedByAnOlderOne() throws {
        try writeFile("RecipeImages/hero.jpg", Self.otherJpeg, modified: Self.tuesday)
        try insertRow(path: "RecipeImages/hero.jpg", data: Self.jpeg, updatedAt: Self.monday)

        let outcome = mirror(["RecipeImages/hero.jpg"])

        #expect(outcome == RecipePhotoSync.Outcome(uploaded: 1, downloaded: 0))
        #expect(try readFile("RecipeImages/hero.jpg") == Self.otherJpeg)
        #expect(try storedRows() == ["RecipeImages/hero.jpg": Self.otherJpeg])
    }

    @Test func aReceivedPhotoIsNotSentStraightBack() throws {
        try insertRow(path: "RecipeImages/b.jpg", data: Self.jpeg, updatedAt: Self.monday)
        mirror([])

        let second = mirror(["RecipeImages/b.jpg"])

        #expect(second == RecipePhotoSync.Outcome(uploaded: 0, downloaded: 0))
    }

    @Test func twoRowsForOnePathAreBothUpdatedAndTheNewestIsReceived() throws {
        try insertRow(path: "RecipeImages/b.jpg", data: Self.jpeg, updatedAt: Self.monday)
        try insertRow(path: "RecipeImages/b.jpg", data: Self.otherJpeg, updatedAt: Self.tuesday)

        #expect(mirror([]).downloaded == 1)
        #expect(try readFile("RecipeImages/b.jpg") == Self.otherJpeg)

        let replaced = Self.jpeg + Data([0x02])
        try writeFile("RecipeImages/b.jpg", replaced, modified: Self.tuesday.addingTimeInterval(3600))
        #expect(mirror(["RecipeImages/b.jpg"]).uploaded == 1)
        let rows = try context.fetch(NSFetchRequest<NSManagedObject>(entityName: RecipePhotoSync.entityName))
        #expect(rows.count == 2)
        #expect(rows.allSatisfy { $0.value(forKey: "data") as? Data == replaced })
    }

    @Test(arguments: ["RecipeImages/../escaped.jpg", "../escaped.jpg", "/tmp/escaped.jpg", "RecipeImages/web-x.jpg"])
    func aStoredPhotoWithAPathOutsideThePhotoFolderIsNotWritten(path: String) throws {
        try insertRow(path: path, data: Self.jpeg)

        let outcome = mirror([])

        #expect(outcome.downloaded == 0)
        #expect(!FileManager.default.fileExists(atPath: documents.appendingPathComponent("escaped.jpg").path))
        #expect(!FileManager.default.fileExists(atPath: documents.deletingLastPathComponent()
            .appendingPathComponent("escaped.jpg").path))
    }

    @Test(arguments: [Data("not a photo".utf8), Data()])
    func aStoredRowThatIsNotAJPEGIsNotWritten(data: Data) throws {
        try insertRow(path: "RecipeImages/bad.jpg", data: data)

        let outcome = mirror([])

        #expect(outcome.downloaded == 0)
        #expect(!FileManager.default.fileExists(atPath: documents.appendingPathComponent("RecipeImages/bad.jpg").path))
    }

    @Test func aStoredRowWithNoPhotoYetIsSkipped() throws {
        try insertRow(path: "RecipeImages/later.jpg", data: nil)

        #expect(mirror([]).downloaded == 0)
    }

    @Test func bothDirectionsRunInOnePass() throws {
        try writeFile("RecipeImages/mine.jpg", Self.jpeg)
        try insertRow(path: "RecipeImages/theirs.jpg", data: Self.jpeg)

        let outcome = mirror(["RecipeImages/mine.jpg"])

        #expect(outcome == RecipePhotoSync.Outcome(uploaded: 1, downloaded: 1))
        #expect(try readFile("RecipeImages/theirs.jpg") == Self.jpeg)
        #expect(try Set(storedRows().keys) == ["RecipeImages/mine.jpg", "RecipeImages/theirs.jpg"])
    }

    @Test func mirroringNeverTouchesRecipes() throws {
        let recipe = Self.recipe("Pie")
        #expect(controller.saveRecipeModel(recipe))
        try writeFile("RecipeImages/a.jpg", Self.jpeg)

        mirror(["RecipeImages/a.jpg"])

        #expect(controller.fetchRecipes().map(\.id) == [recipe.id])
    }

    // MARK: - Wiring

    @Test func resetAlsoErasesTheSyncedPhotos() throws {
        try insertRow(path: "RecipeImages/b.jpg", data: Self.jpeg)
        #expect(controller.saveRecipeModel(Self.recipe("Pie")))

        controller.deleteAllRecipes()

        #expect(try rowCount() == 0)
        #expect(controller.fetchRecipes().isEmpty)
    }

    @Test func withSyncOffNothingIsMirrored() async throws {
        try writeFile("RecipeImages/a.jpg", Self.jpeg)

        let outcome = await controller.mirrorRecipePhotos(referencedPaths: ["RecipeImages/a.jpg"], documentsDirectory: documents)

        #expect(outcome == nil)
        #expect(try rowCount() == 0)
    }

    @Test func theShippedModelHasAPhotoEntityCloudKitCanCarry() throws {
        let entity = try #require(controller.container.managedObjectModel.entitiesByName["RecipePhotoEntity"])
        let data = try #require(entity.attributesByName["data"])

        #expect(entity.attributesByName["path"]?.attributeType == .stringAttributeType)
        #expect(entity.attributesByName["id"]?.attributeType == .UUIDAttributeType)
        #expect(entity.attributesByName["updatedAt"]?.attributeType == .dateAttributeType)
        #expect(data.attributeType == .binaryDataAttributeType)
        #expect(data.allowsExternalBinaryDataStorage)
    }

    // MARK: - Helpers

    private static func recipe(_ name: String, image: String? = nil, photos: [String] = []) -> RecipeModel {
        RecipeModel(
            name: name, category: "Dinner", difficulty: "Easy", prepTime: "5 min", cookingTime: "10 min",
            baseServings: 2, ingredients: [], prePrepInstructions: [], instructions: ["Cook"], notes: "",
            imageName: image, photoNames: photos
        )
    }

    @discardableResult
    private func mirror(_ referenced: Set<String>) -> RecipePhotoSync.Outcome {
        RecipePhotoSync.mirror(referencedPaths: referenced, in: context, documentsDirectory: documents)
    }

    private func writeFile(_ path: String, _ data: Data, modified: Date? = nil) throws {
        let url = documents.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
        if let modified {
            try FileManager.default.setAttributes([.modificationDate: modified], ofItemAtPath: url.path)
        }
    }

    private func readFile(_ path: String) throws -> Data {
        try Data(contentsOf: documents.appendingPathComponent(path))
    }

    private func insertRow(path: String, data: Data?, updatedAt: Date? = nil) throws {
        let row = NSEntityDescription.insertNewObject(forEntityName: RecipePhotoSync.entityName, into: context)
        row.setValue(UUID(), forKey: "id")
        row.setValue(path, forKey: "path")
        row.setValue(data, forKey: "data")
        row.setValue(updatedAt, forKey: "updatedAt")
        try context.save()
    }

    private func storedRows() throws -> [String: Data] {
        let rows = try context.fetch(NSFetchRequest<NSManagedObject>(entityName: RecipePhotoSync.entityName))
        var result: [String: Data] = [:]
        for row in rows {
            if let path = row.value(forKey: "path") as? String { result[path] = row.value(forKey: "data") as? Data }
        }
        return result
    }

    private func rowCount() throws -> Int {
        try context.count(for: NSFetchRequest<NSManagedObject>(entityName: RecipePhotoSync.entityName))
    }
}
