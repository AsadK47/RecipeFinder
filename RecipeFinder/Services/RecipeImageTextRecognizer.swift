import Foundation
import UIKit
import Vision

/// Extracts image text for the free-text import path; a protocol so import routing is unit-tested with a fake, independent of Vision.
protocol RecipeImageTextRecognizing: Sendable {
    /// Recognised text, newline-separated top-to-bottom; empty means no text found ("no recipe here").
    func recognizeText(in image: UIImage) async throws -> String
}

/// On-device OCR via Vision: accurate path, no language correction (it mangles dish names), plus a culinary custom-word list; retries up to 3 orientations when initial confidence is low.
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

    // Domain vocabulary general English models lack, preventing Vision from "correcting" them to dictionary words.
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

        // Low confidence or sparse results — image may be rotated; try the other cardinal orientations, keep the best.
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

    /// The three cardinal orientations other than `start`, ordered for a sideways-photographed cookbook page.
    func orientationFallbacks(after start: CGImagePropertyOrientation) -> [CGImagePropertyOrientation] {
        [.right, .left, .down, .up].filter { $0 != start }
    }
}

private extension CGImagePropertyOrientation {
    /// Vision reads pixels in stored orientation, so pass display orientation through or text comes out rotated/garbled.
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
