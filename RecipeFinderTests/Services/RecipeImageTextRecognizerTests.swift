import Testing
import Foundation
import UIKit
@testable import RecipeFinder

/// OCR seam: a fake recognizer's text flows through the same routing as pasted
/// captions, and the real Vision recogniser rejects an unreadable image. The
/// Vision recognition path itself isn't exercised offline.
@MainActor
@Suite struct RecipeImageTextRecognizerTests {

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

    @Test func visionRecognizerRejectsUnreadableImage() async {
        await #expect(throws: VisionRecipeImageTextRecognizer.RecognitionError.self) {
            _ = try await VisionRecipeImageTextRecognizer().recognizeText(in: UIImage())
        }
    }
}
