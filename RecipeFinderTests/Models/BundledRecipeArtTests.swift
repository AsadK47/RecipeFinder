import Foundation
import Testing
@testable import RecipeFinder

/// Built-in recipe illustrations: a display fallback that never replaces the cook's own picture.
@MainActor @Suite struct BundledRecipeArtTests {
    private let id = UUID()
    private var available: Set<String> { [id.uuidString] }

    @Test func ownImageWins() {
        #expect(BundledRecipeArt.heroName(imageName: "RecipeImages/mine.jpg", photoNames: ["p.jpg"], id: id,
                                          available: available) == "RecipeImages/mine.jpg")
    }

    @Test func madeItPhotoWinsOverIllustration() {
        #expect(BundledRecipeArt.heroName(imageName: nil, photoNames: ["RecipeImages/cooked.jpg"], id: id,
                                          available: available) == "RecipeImages/cooked.jpg")
    }

    @Test(arguments: [nil, ""])
    func noPictureFallsBackToIllustration(imageName: String?) {
        #expect(BundledRecipeArt.heroName(imageName: imageName, photoNames: [], id: id, available: available)
                == BundledRecipeArt.referencePrefix + id.uuidString)
    }

    @Test func recipeWithoutBundledArtHasNoPicture() {
        #expect(BundledRecipeArt.heroName(imageName: nil, photoNames: [], id: UUID(), available: available) == nil)
    }

    @Test(arguments: [nil, "RecipeImages/a.jpg", "https://example.com/a.jpg", "bundled-art:not-a-real-id"])
    func onlyRealReferencesResolveToAFile(reference: String?) {
        #expect(BundledRecipeArt.fileURL(for: reference) == nil)
    }

    /// The shipped folder: every picture belongs to a bundled recipe, resolves to a real file, and most recipes have one.
    @Test func shippedPicturesMatchBundledRecipes() throws {
        let seedURL = try #require(Bundle.main.url(forResource: "recipes_seed", withExtension: "json"))
        struct Seed: Decodable { let id: UUID }
        let seedIDs = Set(try JSONDecoder().decode([Seed].self, from: Data(contentsOf: seedURL)).map(\.id.uuidString))
        let shipped = BundledRecipeArt.availableIDs
        #expect(shipped.count >= 250)
        #expect(shipped.isSubset(of: seedIDs))
        let anyID = try #require(shipped.first.flatMap(UUID.init(uuidString:)))
        let reference = try #require(BundledRecipeArt.reference(for: anyID))
        #expect(BundledRecipeArt.fileURL(for: reference) != nil)
        #expect(RecipeImageView.resolvedSource(for: reference) != nil)
    }

    // MARK: - Through the app's own paths (would fail if heroImageName / galleryNames lost the fallback)

    private func recipe(id: UUID, imageName: String? = nil, photoNames: [String] = []) -> RecipeModel {
        RecipeModel(id: id, name: "Test", category: "Main", difficulty: "Basic", prepTime: "", cookingTime: "",
                    baseServings: 2, ingredients: [], prePrepInstructions: [], instructions: [], notes: "",
                    imageName: imageName, isSampleRecipe: true, photoNames: photoNames)
    }

    private func shippedID() throws -> UUID {
        try #require(BundledRecipeArt.availableIDs.sorted().first.flatMap(UUID.init(uuidString:)))
    }

    @Test func builtInRecipeWithoutPhotoUsesItsIllustration() throws {
        let id = try shippedID()
        #expect(recipe(id: id).heroImageName == BundledRecipeArt.referencePrefix + id.uuidString)
        #expect(RecipeDetailView.galleryNames(for: recipe(id: id)) == [BundledRecipeArt.referencePrefix + id.uuidString])
    }

    @Test func cooksOwnPhotoReplacesIllustrationInDetail() throws {
        let id = try shippedID()
        let docs = try #require(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first)
        let relative = "RecipeImages/art-test-\(UUID().uuidString).jpg"
        let file = docs.appendingPathComponent(relative)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data([0xFF, 0xD8, 0xFF, 0xD9]).write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        let withPhoto = recipe(id: id, photoNames: [relative])
        #expect(withPhoto.heroImageName == relative)
        #expect(RecipeDetailView.galleryNames(for: withPhoto) == [relative])
    }

    @Test func missingOwnFileShowsPlaceholderEverywhereNotArtInOnePlace() throws {
        let id = try shippedID()
        let stale = recipe(id: id, imageName: "RecipeImages/gone-\(UUID().uuidString).jpg")
        #expect(RecipeDetailView.galleryNames(for: stale).isEmpty)
        #expect(RecipeImageView.resolvedSource(for: stale.heroImageName) == nil)
    }
}
