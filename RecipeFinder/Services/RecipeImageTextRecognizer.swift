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
/// offline. Uses the accurate path with language correction, which suits prose
/// recipe text. Runs off the main actor (the request is a struct method on a
/// non-isolated type) so the blocking `perform` never stalls the UI.
struct VisionRecipeImageTextRecognizer: RecipeImageTextRecognizing {
    enum RecognitionError: LocalizedError {
        case invalidImage

        var errorDescription: String? {
            switch self {
            case .invalidImage: return "That image couldn't be read."
            }
        }
    }

    func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else { throw RecognitionError.invalidImage }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
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
