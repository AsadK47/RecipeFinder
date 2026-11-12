import CryptoKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Trust-boundary rules for a recipe website's picture: public https links only, size- and pixel-capped, decoded
/// with ImageIO (never trusted by extension or MIME type) and re-encoded as a downscaled JPEG we own.
enum RemoteRecipeImage {
    static let maxBytes = 10 * 1024 * 1024
    static let maxPixelSize = 1600
    /// Header-declared pixels above this are refused before decoding (a small file can claim a huge canvas).
    static let maxSourcePixels = 50_000_000
    /// Matches `AppTheme.jpegCompressionQuality` (user photos); kept here so decoding stays off the main actor.
    static let jpegQuality = 0.8

    /// The https URL to download for a stored image reference; nil for local files, other schemes and hosts on the
    /// phone's own network (no surprise local-network traffic from an imported page).
    static func downloadableURL(from reference: String?) -> URL? {
        guard let reference = reference?.trimmingCharacters(in: .whitespacesAndNewlines), !reference.isEmpty,
              let url = URL(string: reference),
              url.scheme?.lowercased() == "https",
              let host = url.host?.lowercased(), !host.isEmpty,
              !isPrivateHost(host) else { return nil }
        return url
    }

    /// Where the phone's copy of a web picture lives, keyed by its URL so the recipe keeps the URL as its source
    /// (refresh, export and backups compare and carry the URL) and recipes sharing a picture share one file.
    static func storedPath(for reference: String?) -> String? {
        guard let url = downloadableURL(from: reference) else { return nil }
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let hex = digest.prefix(16).map { String(format: "%02x", $0) }.joined()
        return "RecipeImages/web-\(hex).jpg"
    }

    static func isPrivateHost(_ host: String) -> Bool {
        if host == "localhost" || host.hasSuffix(".localhost") || host.hasSuffix(".local") { return true }
        // IPv6 literals: there's no reason for a recipe picture to use one.
        if host.contains(":") { return true }
        let parts = host.split(separator: ".", omittingEmptySubsequences: false).map { Int($0) }
        guard parts.count == 4, parts.allSatisfy({ $0.map { (0...255).contains($0) } ?? false }) else { return false }
        let octets = parts.compactMap { $0 }
        switch (octets[0], octets[1]) {
        case (0, _), (10, _), (127, _), (169, 254), (192, 168): return true
        case (172, 16...31), (100, 64...127): return true
        default: return false
        }
    }

    /// Decodes untrusted bytes and returns a JPEG whose longest side is at most `maxPixelSize` (never upscaled).
    static func normalisedJPEG(
        from data: Data,
        maxPixelSize: Int = RemoteRecipeImage.maxPixelSize,
        maxSourcePixels: Int = RemoteRecipeImage.maxSourcePixels
    ) throws -> Data {
        guard data.count <= maxBytes else { throw RemoteImageError.tooLarge }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let typeIdentifier = CGImageSourceGetType(source) as String?,
              UTType(typeIdentifier)?.conforms(to: .image) == true,
              CGImageSourceGetCount(source) > 0,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0 else { throw RemoteImageError.notAnImage }
        let pixels = width.multipliedReportingOverflow(by: height)
        guard !pixels.overflow, pixels.partialValue <= maxSourcePixels else { throw RemoteImageError.tooLarge }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: min(maxPixelSize, max(width, height)),
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw RemoteImageError.notAnImage
        }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output as CFMutableData, UTType.jpeg.identifier as CFString, 1, nil
        ) else { throw RemoteImageError.notAnImage }
        let quality: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: jpegQuality]
        CGImageDestinationAddImage(destination, image, quality as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw RemoteImageError.notAnImage }
        return output as Data
    }
}
