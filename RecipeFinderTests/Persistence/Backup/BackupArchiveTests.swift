import Testing
import Foundation
@testable import RecipeFinder

@Suite struct BackupArchiveTests {

    private static func sampleRecipe(name: String) -> RecipeModel {
        RecipeModel(
            name: name,
            category: "Main",
            difficulty: "Basic",
            prepTime: "5 min",
            cookingTime: "10 min",
            baseServings: 2,
            ingredients: [],
            prePrepInstructions: [],
            instructions: ["Do the thing."],
            notes: ""
        )
    }

    private static func makeArchive() -> BackupArchive {
        BackupArchive(
            exportedAt: Date(timeIntervalSince1970: 1_700_000_000), // integer secs → exact ISO-8601 round-trip
            recipes: [sampleRecipe(name: "Soup"), sampleRecipe(name: "Stew")]
        )
    }

    // MARK: - Round trip

    @Test func encodeThenDecode_preservesCoreContent() throws {
        let original = Self.makeArchive()

        let data = try BackupCodec.encode(original)
        let restored = try BackupCodec.decode(data)

        #expect(restored.schemaVersion == BackupArchive.currentSchemaVersion)
        #expect(restored.exportedAt == original.exportedAt)
        #expect(restored.recipes.map(\.id) == original.recipes.map(\.id))
        #expect(restored.recipes.map(\.name) == ["Soup", "Stew"])
    }

    @Test func emptyStores_roundTripAsEmpty_notNil() throws {
        let restored = try BackupCodec.decode(try BackupCodec.encode(BackupArchive()))
        #expect(restored.recipes.isEmpty)
        #expect(restored.shoppingList.isEmpty)
        #expect(restored.kitchenItems.isEmpty)
        #expect(restored.kitchenInventory.isEmpty)
        #expect(restored.mealPlans.isEmpty)
        #expect(restored.badges.isEmpty)
    }

    // MARK: - Schema guard

    @Test func decode_rejectsNewerSchemaVersion() throws {
        var future = Self.makeArchive()
        future.schemaVersion = BackupArchive.currentSchemaVersion + 1
        let data = try BackupCodec.encode(future)

        #expect(throws: BackupError.unsupportedSchemaVersion(
            found: BackupArchive.currentSchemaVersion + 1,
            supported: BackupArchive.currentSchemaVersion
        )) {
            try BackupCodec.decode(data)
        }
    }

    @Test func decode_rejectsGarbage() {
        let garbage = Data("not a backup".utf8)
        #expect(throws: BackupError.corruptedData) {
            try BackupCodec.decode(garbage)
        }
    }

    @Test func fileExtension_isStable() {
        #expect(BackupCodec.fileExtension == "recipefinderbackup")
    }
}
