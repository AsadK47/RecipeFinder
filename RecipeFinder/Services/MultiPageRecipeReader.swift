import Foundation
import PDFKit
import UIKit

/// Reads a recipe that spans several pages — up to five photos, or a PDF — into one block of text for the normal
/// text-import router. PDF pages with real text use it directly; scanned (image-only) pages go through OCR.
struct MultiPageRecipeReader {
    /// Most recipes fit on a few pages; more photos usually means the wrong ones were picked.
    static let maxPhotos = 5
    /// A page with less text than this is treated as a scan and read with OCR instead.
    static let minimumPageText = 20
    /// Scans render at this scale for OCR — sharp enough for body text without huge images.
    static let renderScale: CGFloat = 2

    enum ReadError: LocalizedError, Equatable {
        case unreadablePDF

        var errorDescription: String? {
            switch self {
            case .unreadablePDF: "That PDF couldn't be opened."
            }
        }
    }

    let recognizer: RecipeImageTextRecognizing

    /// Pages in the order given, blank ones skipped, separated by a blank line so headings stay on their own lines.
    static func join(_ pages: [String]) -> String {
        pages.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }

    func text(fromImages images: [UIImage]) async throws -> String {
        var pages: [String] = []
        for image in images.prefix(Self.maxPhotos) {
            pages.append(try await recognizer.recognizeText(in: image))
        }
        return Self.join(pages)
    }

    func text(fromPDF data: Data) async throws -> String {
        guard let document = PDFDocument(data: data), document.pageCount > 0 else { throw ReadError.unreadablePDF }
        var pages: [String] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            let embedded = page.string ?? ""
            if embedded.trimmingCharacters(in: .whitespacesAndNewlines).count >= Self.minimumPageText {
                pages.append(embedded)
            } else {
                pages.append(try await recognizer.recognizeText(in: Self.render(page)))
            }
        }
        return Self.join(pages)
    }

    /// Draws a page on white (scans are often transparent) for OCR.
    static func render(_ page: PDFPage) -> UIImage {
        let bounds = page.bounds(for: .mediaBox)
        let size = CGSize(width: bounds.width * renderScale, height: bounds.height * renderScale)
        return UIGraphicsImageRenderer(size: size).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            context.cgContext.translateBy(x: 0, y: size.height)
            context.cgContext.scaleBy(x: renderScale, y: -renderScale)
            page.draw(with: .mediaBox, to: context.cgContext)
        }
    }
}
