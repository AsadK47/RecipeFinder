import Foundation
import UIKit
import Vision

/// Extracts text from an image (a cookbook page, screenshot, or photo) so it can
/// be fed to the same free-text import path as pasted captions. A protocol so the
/// import routing is unit-tested with a fake, independent of Vision.
protocol RecipeImageTextRecognizing: Sendable {
    /// Recognised text, newline-separated top-to-bottom. Empty when no text is
    /// found (callers treat that as "no recipe here").
    func recognizeText(in image: UIImage) async throws -> String
}

/// On-device OCR backed by Vision's `VNRecognizeTextRequest` — private, free, and
/// offline. Uses the accurate path without language correction (which mangles food
/// proper nouns like dish names) and supplements with a culinary custom-word list
/// so Vision treats food-specific terms as valid vocabulary.
///
/// Images that may be rotated (e.g. a cookbook photographed sideways) are retried
/// with up to 3 other orientations when the initial recognition confidence is low.
struct VisionRecipeImageTextRecognizer: RecipeImageTextRecognizing {
    enum RecognitionError: LocalizedError {
        case invalidImage

        var errorDescription: String? {
            switch self {
            case .invalidImage: return "That image couldn't be read."
            }
        }
    }

    // Confidence below this on the first attempt triggers orientation fallbacks.
    private static let confidenceThreshold: Float = 0.55
    // Fewer than this many text blocks and we also try other orientations.
    private static let minimumObservations = 5

    // Domain-specific vocabulary that general English language models don't know,
    // preventing Vision from "correcting" them to dictionary words.
    static let culinaryCustomWords: [String] = [
        "Dynamite", "Sriracha", "Tempura", "Teriyaki", "Katsu", "Tonkatsu",
        "Ramen", "Udon", "Soba", "Edamame", "Miso", "Dashi", "Bonito",
        "Kombu", "Mirin", "Sake", "Furikake", "Gochujang", "Doenjang",
        "Kimchi", "Bibimbap", "Bulgogi", "Japchae",
        "Pho", "Banh", "Laksa", "Satay", "Rendang", "Nasi", "Goreng",
        "Tikka", "Masala", "Biryani", "Dal", "Paneer", "Naan", "Chapati",
        "Dosa", "Raita", "Chutney", "Halloumi", "Tahini", "Harissa",
        "Za'atar", "Sumac", "Dukkah",
        "Prawn", "Prawns", "Chorizo", "Prosciutto", "Pancetta", "Guanciale",
        "Bruschetta", "Cacio", "Carbonara", "Risotto", "Polenta", "Gremolata",
        "Agrodolce", "Bisque", "Roux", "Julienne", "Brunoise", "Chiffonade",
        "Deglaze", "Blanch", "Braise", "Sauté", "Sauteed", "Sautéed",
        "Ceviche", "Chimichurri", "Empanada", "Arepa", "Mole",
        "Worcestershire", "Sambal", "Hoisin", "Tamari",
        "Turmeric", "Cardamom", "Paprika", "Cayenne", "Ancho", "Chipotle",
        "Jalapeño", "Serrano", "Habanero",
        "tsp", "tbsp", "ml", "dl",
    ]

    func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else { throw RecognitionError.invalidImage }
        let naturalOrientation = CGImagePropertyOrientation(image.imageOrientation)

        let first = try await recognize(cgImage: cgImage, orientation: naturalOrientation)

        // Happy path: well-oriented, clear image — return immediately.
        if first.averageConfidence >= Self.confidenceThreshold &&
           first.observationCount >= Self.minimumObservations {
            return first.text
        }

        // Low confidence or sparse results — the image may be rotated. Try the
        // remaining three cardinal orientations and keep the best result.
        var best = first
        for orientation in orientationFallbacks(after: naturalOrientation) {
            let result = try await recognize(cgImage: cgImage, orientation: orientation)
            if result.averageConfidence > best.averageConfidence {
                best = result
            }
            if best.averageConfidence >= Self.confidenceThreshold {
                break
            }
        }

        return best.text
    }

    private struct RecognitionResult {
        let text: String
        let averageConfidence: Float
        let observationCount: Int
    }

    private func recognize(cgImage: CGImage, orientation: CGImagePropertyOrientation) async throws -> RecognitionResult {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let candidates = observations.compactMap { $0.topCandidates(1).first }
                let text = candidates.map(\.string).joined(separator: "\n")
                let total = candidates.map(\.confidence).reduce(0, +)
                let avg: Float = candidates.isEmpty ? 0 : total / Float(candidates.count)
                continuation.resume(returning: RecognitionResult(text: text, averageConfidence: avg, observationCount: observations.count))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            request.customWords = Self.culinaryCustomWords

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// The three cardinal orientations that aren't `start`, tried in the order
    /// most likely to succeed for a sideways-photographed cookbook page.
    func orientationFallbacks(after start: CGImagePropertyOrientation) -> [CGImagePropertyOrientation] {
        [.right, .left, .down, .up].filter { $0 != start }
    }
}

private extension CGImagePropertyOrientation {
    /// Vision reads pixels in their stored orientation, so pass the photo's
    /// display orientation through or text comes out rotated/garbled.
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
