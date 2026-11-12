import Testing
import Foundation
import ImageIO
import UIKit
@testable import RecipeFinder

/// Shared helpers for the picture-download tests.
enum RemoteImageFixtures {
    /// PNG bytes of a solid image at an exact pixel size.
    static func png(width: Int, height: Int) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        return renderer.pngData { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    /// (type identifier, width, height) of encoded image bytes.
    static func describe(_ data: Data) -> (type: String?, width: Int, height: Int) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return (nil, 0, 0) }
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        return (
            CGImageSourceGetType(source) as String?,
            properties?[kCGImagePropertyPixelWidth] as? Int ?? 0,
            properties?[kCGImagePropertyPixelHeight] as? Int ?? 0
        )
    }
}

@Suite("RemoteRecipeImage")
struct RemoteRecipeImageTests {

    @Test("Web links are downloadable", arguments: [
        "https://example.com/pie.jpg", "http://example.com/pie.png", "HTTPS://Example.com/a.webp",
        "  https://example.com/pie.jpg  "
    ])
    func webLinksAreDownloadable(reference: String) {
        #expect(RemoteRecipeImage.downloadableURL(from: reference)?.host?.lowercased() == "example.com")
    }

    @Test("Anything that isn't a web link is never fetched", arguments: [
        "", "RecipeImages/ABC.jpg", "/var/mobile/RecipeImages/ABC.jpg", "file:///etc/passwd",
        "ftp://example.com/pie.jpg", "data:image/png;base64,AAAA", "javascript:alert(1)", "https://", "pie"
    ])
    func otherReferencesAreNotDownloadable(reference: String) {
        #expect(RemoteRecipeImage.downloadableURL(from: reference) == nil)
    }

    @Test("A missing reference is not downloadable")
    func nilIsNotDownloadable() {
        #expect(RemoteRecipeImage.downloadableURL(from: nil) == nil)
    }

    @Test("A big picture becomes a JPEG no wider than 1600px, keeping its shape")
    func bigPictureIsDownscaledToJPEG() throws {
        let jpeg = try RemoteRecipeImage.normalisedJPEG(from: RemoteImageFixtures.png(width: 3200, height: 2000))
        let info = RemoteImageFixtures.describe(jpeg)
        #expect(info.type == "public.jpeg")
        #expect(info.width == 1600)
        #expect(info.height == 1000)
    }

    @Test("A small picture keeps its size")
    func smallPictureIsNotUpscaled() throws {
        let jpeg = try RemoteRecipeImage.normalisedJPEG(from: RemoteImageFixtures.png(width: 120, height: 80))
        let info = RemoteImageFixtures.describe(jpeg)
        #expect(info.type == "public.jpeg")
        #expect(info.width == 120)
        #expect(info.height == 80)
    }

    @Test("A web page served instead of a picture is rejected")
    func htmlIsNotAnImage() {
        let html = Data("<!doctype html><html><body>Not found</body></html>".utf8)
        #expect(throws: RemoteImageError.notAnImage) { try RemoteRecipeImage.normalisedJPEG(from: html) }
    }

    @Test("Empty bytes are rejected")
    func emptyIsNotAnImage() {
        #expect(throws: RemoteImageError.notAnImage) { try RemoteRecipeImage.normalisedJPEG(from: Data()) }
    }

    @Test("Bytes over the 10 MB cap are rejected before decoding")
    func oversizedIsRejected() {
        let huge = Data(count: RemoteRecipeImage.maxBytes + 1)
        #expect(throws: RemoteImageError.tooLarge) { try RemoteRecipeImage.normalisedJPEG(from: huge) }
    }
}
