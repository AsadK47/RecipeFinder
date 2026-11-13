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
}
