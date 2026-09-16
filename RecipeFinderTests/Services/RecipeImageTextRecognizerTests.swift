import Testing
import Foundation
import UIKit
import ImageIO
@testable import RecipeFinder

@MainActor
@Suite("RecipeImageTextRecognizer") struct RecipeImageTextRecognizerTests {

    // MARK: - Protocol seam

    struct FakeRecognizer: RecipeImageTextRecognizing {
        var text: String
        func recognizeText(in image: UIImage) async throws -> String { text }
    }

    struct DecliningInterpreter: RecipeTextInterpreting {
        func interpret(_ text: String) async throws -> InterpretedRecipe? { nil }
    }

    @Test func recognizedTextFlowsIntoWizardPrefill() async throws {
        let caption = """
        Tomato Soup
        Ingredients
        2 tomatoes
        1 onion
        Method
        Simmer everything
        """
        let text = try await FakeRecognizer(text: caption).recognizeText(in: UIImage())
        let router = RecipeTextImportRouter(interpreter: DecliningInterpreter())

        let prefill = await router.prefill(for: text)
        #expect(prefill?.name == "Tomato Soup")
    }

    // MARK: - Invalid image guard

    @Test func visionRecognizerRejectsUnreadableImage() async {
        await #expect(throws: VisionRecipeImageTextRecognizer.RecognitionError.self) {
            _ = try await VisionRecipeImageTextRecognizer().recognizeText(in: UIImage())
        }
    }

    // MARK: - Orientation fallbacks

    let recognizer = VisionRecipeImageTextRecognizer()

    // The four cardinal orientations Vision uses for still-image recipes.
    private let cardinals: [CGImagePropertyOrientation] = [.up, .right, .left, .down]

    @Test(arguments: [CGImagePropertyOrientation.up, .right, .left, .down])
    func orientationFallbacksExcludesStart(start: CGImagePropertyOrientation) {
        let fallbacks = recognizer.orientationFallbacks(after: start)
        #expect(!fallbacks.contains(start))
    }

    @Test(arguments: [CGImagePropertyOrientation.up, .right, .left, .down])
    func orientationFallbacksReturnsThreeOrientations(start: CGImagePropertyOrientation) {
        let fallbacks = recognizer.orientationFallbacks(after: start)
        #expect(fallbacks.count == 3)
    }

    @Test(arguments: [CGImagePropertyOrientation.up, .right, .left, .down])
    func orientationFallbacksCoverAllCardinals(start: CGImagePropertyOrientation) {
        let fallbacks = recognizer.orientationFallbacks(after: start)
        let covered = Set([start] + fallbacks)
        #expect(covered == Set([.up, .right, .left, .down]))
    }

    @Test(arguments: [CGImagePropertyOrientation.up, .right, .left, .down])
    func orientationFallbacksHaveNoDuplicates(start: CGImagePropertyOrientation) {
        let fallbacks = recognizer.orientationFallbacks(after: start)
        #expect(fallbacks.count == Set(fallbacks).count)
    }

    // MARK: - Culinary custom words

    @Test func culinaryCustomWordsIsNonEmpty() {
        #expect(!VisionRecipeImageTextRecognizer.culinaryCustomWords.isEmpty)
    }

    @Test func culinaryCustomWordsHasNoDuplicates() {
        let words = VisionRecipeImageTextRecognizer.culinaryCustomWords
        #expect(words.count == Set(words).count)
    }

    @Test(arguments: ["Dynamite", "Sriracha", "Tempura", "Teriyaki", "Prawn", "Prawns"])
    func culinaryCustomWordsContainsFoodTerm(term: String) {
        #expect(VisionRecipeImageTextRecognizer.culinaryCustomWords.contains(term))
    }
}
