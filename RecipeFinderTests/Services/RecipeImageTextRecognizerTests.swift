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

/// PDFs and multi-photo imports: pages joined in order, text pages read directly, scanned pages sent to OCR.
/// PDFs are drawn in the test (UIGraphicsPDFRenderer) so no binary fixtures are needed.
@MainActor
@Suite("MultiPageRecipeReader") struct MultiPageRecipeReaderTests {

    /// Answers with the image's width so tests can see which page reached OCR, and in what order.
    struct WidthRecognizer: RecipeImageTextRecognizing {
        func recognizeText(in image: UIImage) async throws -> String { "page \(Int(image.size.width))" }
    }

    private let reader = MultiPageRecipeReader(recognizer: WidthRecognizer())

    private func image(width: CGFloat) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: width, height: 10)).image { _ in }
    }

    private func pdf(pages: [String?]) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 300, height: 400))
        return renderer.pdfData { context in
            for text in pages {
                context.beginPage()
                if let text {
                    (text as NSString).draw(in: CGRect(x: 20, y: 20, width: 260, height: 360),
                                            withAttributes: [.font: UIFont.systemFont(ofSize: 12)])
                } else {
                    UIColor.gray.setFill()
                    context.fill(CGRect(x: 50, y: 50, width: 100, height: 100))   // a "scan": no text layer
                }
            }
        }
    }

    @Test("Pages join in order with blank ones skipped")
    func join() {
        #expect(MultiPageRecipeReader.join(["  Soup \n", "", "\n", "Method"]) == "Soup\n\nMethod")
    }

    @Test("Photos are read in the order picked, at most five")
    func photos() async throws {
        let images = (1...7).map { image(width: CGFloat($0)) }
        let text = try await reader.text(fromImages: images)
        #expect(text == "page 1\n\npage 2\n\npage 3\n\npage 4\n\npage 5")
    }

    @Test("PDF text pages are read directly; scanned pages go to OCR, in page order")
    func pdfMixed() async throws {
        let data = pdf(pages: ["Tomato Soup\nIngredients\n4 tomatoes\n1 onion", nil, "Method\nSimmer for 20 minutes, then blend."])
        let text = try await reader.text(fromPDF: data)
        let soup = try #require(text.range(of: "Tomato Soup"))
        let scan = try #require(text.range(of: "page 600"))          // 300 pt × render scale 2
        let method = try #require(text.range(of: "Simmer for 20 minutes"))
        #expect(soup.lowerBound < scan.lowerBound)
        #expect(scan.lowerBound < method.lowerBound)
    }

    @Test("Something that isn't a PDF is refused with a readable message")
    func notAPDF() async {
        await #expect(throws: MultiPageRecipeReader.ReadError.unreadablePDF) {
            try await reader.text(fromPDF: Data("hello".utf8))
        }
        #expect(MultiPageRecipeReader.ReadError.unreadablePDF.errorDescription == "That PDF couldn't be opened.")
    }
}
