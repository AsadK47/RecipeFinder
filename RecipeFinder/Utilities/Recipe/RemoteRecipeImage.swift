import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Trust-boundary rules for a picture downloaded from a recipe website: web links only, size-capped, decoded with
/// ImageIO (never trusted by extension or MIME type) and re-encoded as a downscaled JPEG we own.
enum RemoteRecipeImage {
    static let maxBytes = 10 * 1024 * 1024
    static let maxPixelSize = 1600
    /// Matches `AppTheme.jpegCompressionQuality` (user photos); kept here so decoding stays off the main actor.
    static let jpegQuality = 0.8

    /// The http(s) URL to download for a stored image reference, or nil for local files, assets and other schemes.
    static func downloadableURL(from reference: String?) -> URL? {
        guard let reference = reference?.trimmingCharacters(in: .whitespacesAndNewlines), !reference.isEmpty,
              let url = URL(string: reference),
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
              let host = url.host, !host.isEmpty else { return nil }
        return url
    }

    /// Decodes untrusted bytes and returns a JPEG whose longest side is at most `maxPixelSize`.
    static func normalisedJPEG(from data: Data, maxPixelSize: Int = maxPixelSize) throws -> Data {
        guard data.count <= maxBytes else { throw RemoteImageError.tooLarge }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let typeIdentifier = CGImageSourceGetType(source) as String?,
              UTType(typeIdentifier)?.conforms(to: .image) == true,
              CGImageSourceGetCount(source) > 0 else { throw RemoteImageError.notAnImage }
        // Never upscale: a small picture keeps its own size.
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let width = properties?[kCGImagePropertyPixelWidth] as? Int ?? maxPixelSize
        let height = properties?[kCGImagePropertyPixelHeight] as? Int ?? maxPixelSize
        let targetSide = max(1, min(maxPixelSize, max(width, height)))
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: targetSide,
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
