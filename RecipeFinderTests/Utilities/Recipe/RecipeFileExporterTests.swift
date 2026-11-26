import Testing
import Foundation
@testable import RecipeFinder

@Suite struct RecipeFileExporterTests {

    // MARK: - Helpers

    private func makeRecipe(
        name: String = "Spaghetti Bolognese",
        notes: String = "A classic.\nhttps://example.com/spaghetti"
    ) -> RecipeModel {
        var r = RecipeModel(
            name: name,
            category: "Main",
            difficulty: "Medium",
            prepTime: "15 minutes",
            cookingTime: "45 minutes",
            baseServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 400, unit: "g", name: "beef mince"),
                Ingredient(baseQuantity: 2, unit: "cloves", name: "garlic"),
            ],
            prePrepInstructions: ["Peel the garlic"],
            instructions: ["Brown the mince", "Add sauce", "Simmer 30 min"],
            notes: notes,
            imageName: "https://example.com/image.jpg",
            tags: ["italian", "pasta"],
            dietaryInfo: DietaryInfo(isGlutenFree: true),
            cuisine: "Italian"
        )
        r.isFavorite = true
        r.rating = 5
        r.cookCount = 12
        return r
    }

    // MARK: - Round-trip

    @Test func roundTripPreservesName() throws {
        let recipe = makeRecipe()
        let data = try RecipeFileExporter.encode(recipe)
        let decoded = try RecipeFileExporter.decode(data)
        #expect(decoded.name == "Spaghetti Bolognese")
    }

    @Test func roundTripPreservesIngredients() throws {
        let recipe = makeRecipe()
        let data = try RecipeFileExporter.encode(recipe)
        let decoded = try RecipeFileExporter.decode(data)
        #expect(decoded.ingredients.count == 2)
        #expect(decoded.ingredients[0].name == "Beef Mince")
        #expect(decoded.ingredients[0].baseQuantity == 400)
        #expect(decoded.ingredients[0].unit == "g")
    }

    @Test func roundTripPreservesInstructions() throws {
        let recipe = makeRecipe()
        let data = try RecipeFileExporter.encode(recipe)
        let decoded = try RecipeFileExporter.decode(data)
        #expect(decoded.instructions == ["Brown the mince", "Add sauce", "Simmer 30 min"])
    }

    @Test func roundTripPreservesPrePrep() throws {
        let recipe = makeRecipe()
        let data = try RecipeFileExporter.encode(recipe)
        let decoded = try RecipeFileExporter.decode(data)
        #expect(decoded.prePrepInstructions == ["Peel the garlic"])
    }

    @Test func roundTripPreservesCuisineTagsDietaryInfo() throws {
        let recipe = makeRecipe()
        let data = try RecipeFileExporter.encode(recipe)
        let decoded = try RecipeFileExporter.decode(data)
        #expect(decoded.cuisine == "Italian")
        #expect(decoded.tags == ["italian", "pasta"])
        #expect(decoded.dietaryInfo.isGlutenFree == true)
    }

    @Test func roundTripPreservesHTTPImageURL() throws {
        let recipe = makeRecipe()
        let data = try RecipeFileExporter.encode(recipe)
        let decoded = try RecipeFileExporter.decode(data)
        #expect(decoded.imageName == "https://example.com/image.jpg")
    }

    // MARK: - Personal data isolation

    @Test func decodeAssignsNewUUID() throws {
        let recipe = makeRecipe()
        let data = try RecipeFileExporter.encode(recipe)
        let decoded = try RecipeFileExporter.decode(data)
        #expect(decoded.id != recipe.id)
    }

    @Test func decodeResetsPersonalData() throws {
        let recipe = makeRecipe()
        let data = try RecipeFileExporter.encode(recipe)
        let decoded = try RecipeFileExporter.decode(data)
        #expect(decoded.isFavorite == false)
        #expect(decoded.rating == 0)
        #expect(decoded.cookCount == 0)
        #expect(decoded.lastCookedAt == nil)
    }

    // MARK: - Image URL handling

    @Test func localImagePathIsDropped() throws {
        let r = RecipeModel(
            name: "Local Image Recipe",
            category: "Main",
            difficulty: "Easy",
            prepTime: "10 min",
            cookingTime: "20 min",
            baseServings: 2,
            ingredients: [],
            prePrepInstructions: [],
            instructions: ["Cook it"],
            notes: "",
            imageName: "/var/mobile/Containers/Data/Application/abc123/recipe.jpg"
        )
        let data = try RecipeFileExporter.encode(r)
        let decoded = try RecipeFileExporter.decode(data)
        #expect(decoded.imageName == nil)
    }

    // MARK: - Source URL reconstruction

    @Test func sourceURLAppearsInDecodedNotes() throws {
        let recipe = makeRecipe(notes: "Good recipe.\nhttps://example.com/spaghetti")
        let data = try RecipeFileExporter.encode(recipe)
        let decoded = try RecipeFileExporter.decode(data)
        #expect(decoded.importedFromURL?.absoluteString == "https://example.com/spaghetti")
    }

    @Test func recipeWithNoSourceURLHasNoFooter() throws {
        let recipe = makeRecipe(notes: "My own creation.")
        let data = try RecipeFileExporter.encode(recipe)
        let decoded = try RecipeFileExporter.decode(data)
        #expect(decoded.importedFromURL == nil)
        #expect(decoded.notes == "My own creation.")
    }

    // MARK: - Version guard

    @Test func unsupportedVersionThrows() throws {
        // Build a minimal JSON with version 99 to trigger the version guard.
        let json = """
        {
          "version": 99,
          "name": "Future Recipe",
          "category": "Main",
          "difficulty": "Easy",
          "prepTime": "",
          "cookingTime": "",
          "baseServings": 2,
          "ingredients": [],
          "prePrepInstructions": [],
          "instructions": [],
          "notes": "",
          "tags": [],
          "dietaryInfo": {
            "isVegetarian": false,
            "isVegan": false,
            "isGlutenFree": false,
            "isDairyFree": false,
            "isNutFree": false,
            "isLowCarb": false,
            "isKeto": false
          }
        }
        """
        let data = Data(json.utf8)
        #expect(throws: RecipeFileError.self) {
            _ = try RecipeFileExporter.decode(data)
        }
    }

    // MARK: - Opening a file (Files / iCloud Drive, opened in place)

    private func writeTempFile(_ data: Data) throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("Shared.recipefinderrecipe")
        try data.write(to: url)
        return url
    }

    private func removeTempFile(_ url: URL) {
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    @Test func readFromURLDecodesTheRecipe() throws {
        let url = try writeTempFile(try RecipeFileExporter.encode(makeRecipe()))
        defer { removeTempFile(url) }
        let recipe = try RecipeFileExporter.read(from: url, access: AccessSpy(grants: true).access)
        #expect(recipe.name == "Spaghetti Bolognese")
    }

    @Test func readFromURLStartsAndStopsScopedAccess() throws {
        let url = try writeTempFile(try RecipeFileExporter.encode(makeRecipe()))
        defer { removeTempFile(url) }
        let spy = AccessSpy(grants: true)
        _ = try RecipeFileExporter.read(from: url, access: spy.access)
        #expect(spy.starts == [url])
        #expect(spy.stops == [url])
    }

    @Test func readFromURLStopsScopedAccessWhenTheFileIsDamaged() throws {
        let url = try writeTempFile(Data("not a recipe".utf8))
        defer { removeTempFile(url) }
        let spy = AccessSpy(grants: true)
        #expect(throws: (any Error).self) {
            _ = try RecipeFileExporter.read(from: url, access: spy.access)
        }
        #expect(spy.starts == [url])
        #expect(spy.stops == [url])
    }

    @Test func readFromURLDoesNotStopAccessItNeverGot() throws {
        let url = try writeTempFile(try RecipeFileExporter.encode(makeRecipe()))
        defer { removeTempFile(url) }
        let spy = AccessSpy(grants: false)
        _ = try RecipeFileExporter.read(from: url, access: spy.access)
        #expect(spy.starts == [url])
        #expect(spy.stops.isEmpty)
    }

    @Test func readFromURLRejectsAFileOverTheSizeLimit() throws {
        let url = try writeTempFile(Data(count: RecipeFileExporter.maxFileBytes + 1))
        defer { removeTempFile(url) }
        let spy = AccessSpy(grants: true)
        #expect(throws: RecipeFileError.tooLarge) {
            _ = try RecipeFileExporter.read(from: url, access: spy.access)
        }
        #expect(spy.stops == [url])
    }

    // MARK: - Coordinated read (a Files / iCloud Drive placeholder downloads before it is read)

    @Test func readGoesThroughFileCoordination() throws {
        let url = try writeTempFile(try RecipeFileExporter.encode(makeRecipe()))
        defer { removeTempFile(url) }
        let coordinator = CoordinationSpy()
        _ = try RecipeFileExporter.read(from: url, access: AccessSpy(grants: true).access, coordination: coordinator.coordination)
        #expect(coordinator.coordinated == [url])
    }

    @Test func readUsesTheURLTheCoordinatorHandsOver() throws {
        let opened = try writeTempFile(Data("not a recipe".utf8))
        defer { removeTempFile(opened) }
        let handedOver = try writeTempFile(try RecipeFileExporter.encode(makeRecipe(name: "Coordinated Curry")))
        defer { removeTempFile(handedOver) }
        let coordinator = CoordinationSpy(handsOver: handedOver)
        let recipe = try RecipeFileExporter.read(from: opened, access: AccessSpy(grants: true).access, coordination: coordinator.coordination)
        #expect(recipe.name == "Coordinated Curry")
    }

    @Test func coordinationFailureSurfacesAndStopsAccess() throws {
        let url = try writeTempFile(try RecipeFileExporter.encode(makeRecipe()))
        defer { removeTempFile(url) }
        let spy = AccessSpy(grants: true)
        let coordinator = CoordinationSpy(fails: CocoaError(.fileReadNoPermission))
        #expect(throws: CocoaError.self) {
            _ = try RecipeFileExporter.read(from: url, access: spy.access, coordination: coordinator.coordination)
        }
        #expect(spy.stops == [url])
    }

    @Test func scopedAccessIsHeldWhileCoordinating() throws {
        let url = try writeTempFile(try RecipeFileExporter.encode(makeRecipe()))
        defer { removeTempFile(url) }
        let spy = AccessSpy(grants: true)
        let coordinator = CoordinationSpy(onCoordinate: { #expect(spy.starts == [url] && spy.stops.isEmpty) })
        _ = try RecipeFileExporter.read(from: url, access: spy.access, coordination: coordinator.coordination)
        #expect(coordinator.coordinated == [url])
    }

    @Test func systemCoordinatorReadsAPlainFile() throws {
        let url = try writeTempFile(try RecipeFileExporter.encode(makeRecipe()))
        defer { removeTempFile(url) }
        let recipe = try RecipeFileExporter.read(from: url, access: AccessSpy(grants: true).access, coordination: .fileCoordinator)
        #expect(recipe.name == "Spaghetti Bolognese")
    }

    @Test func systemCoordinatorSurfacesAMissingFile() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).recipefinderrecipe")
        #expect(throws: (any Error).self) {
            _ = try RecipeFileExporter.read(from: url, access: AccessSpy(grants: true).access, coordination: .fileCoordinator)
        }
    }

    @Test func tooLargeErrorExplainsItself() {
        #expect(RecipeFileError.tooLarge.errorDescription?.isEmpty == false)
    }
}

/// Records scoped-access calls so tests can check every start is balanced by a stop.
private final class AccessSpy: @unchecked Sendable {
    private let lock = NSLock()
    private let grants: Bool
    private var _starts: [URL] = []
    private var _stops: [URL] = []

    init(grants: Bool) { self.grants = grants }

    var starts: [URL] { lock.withLock { _starts } }
    var stops: [URL] { lock.withLock { _stops } }

    var access: ScopedFileAccess {
        ScopedFileAccess(
            start: { url in self.lock.withLock { self._starts.append(url) }; return self.grants },
            stop: { url in self.lock.withLock { self._stops.append(url) } }
        )
    }
}

/// Stands in for `NSFileCoordinator`: records which URLs were coordinated and can hand over another URL or fail.
private final class CoordinationSpy: @unchecked Sendable {
    private let lock = NSLock()
    private let handsOver: URL?
    private let fails: (any Error)?
    private let onCoordinate: @Sendable () -> Void
    private var _coordinated: [URL] = []

    init(handsOver: URL? = nil, fails: (any Error)? = nil, onCoordinate: @escaping @Sendable () -> Void = {}) {
        self.handsOver = handsOver
        self.fails = fails
        self.onCoordinate = onCoordinate
    }

    var coordinated: [URL] { lock.withLock { _coordinated } }

    var coordination: FileReadCoordination {
        FileReadCoordination { url, body in
            self.lock.withLock { self._coordinated.append(url) }
            self.onCoordinate()
            if let fails = self.fails { throw fails }
            return try body(self.handsOver ?? url)
        }
    }
}
