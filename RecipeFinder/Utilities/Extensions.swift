import Foundation
import UIKit

// Debug Logging
/// Prints debug messages only in DEBUG builds
func debugLog(_ message: String) {
    #if DEBUG
    // swiftlint:disable:next no_print
    print(message)
    #endif
}

// Array Safe Subscript
extension Array {
    /// Safely access array elements by index
    /// Returns nil if index is out of bounds instead of crashing
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// String Extensions
extension String {
    /// Capitalizes only the first letter of the string
    var capitalizedFirst: String {
        guard !isEmpty else { return self }
        return prefix(1).uppercased() + dropFirst()
    }
    
    /// Removes extra whitespace and newlines
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Checks if string contains only whitespace
    var isBlank: Bool {
        trimmed.isEmpty
    }
    
    /// Find all ranges matching a pattern
    func ranges(of pattern: String, options: NSString.CompareOptions = []) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var searchRange = startIndex..<endIndex
        
        while let range = self.range(of: pattern, options: options, range: searchRange) {
            ranges.append(range)
            searchRange = range.upperBound..<endIndex
        }
        
        return ranges
    }
}

// UIColor Extensions for Tab Bar Styling
extension UIColor {
    /// Blends this color with another color
    func blended(with color: UIColor, ratio: CGFloat = 0.5) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let blendRatio = max(0, min(1, ratio))
        
        return UIColor(
            red: r1 * (1 - blendRatio) + r2 * blendRatio,
            green: g1 * (1 - blendRatio) + g2 * blendRatio,
            blue: b1 * (1 - blendRatio) + b2 * blendRatio,
            alpha: a1 * (1 - blendRatio) + a2 * blendRatio
        )
    }
    
    /// Creates a lighter version of the color
    func lighter(by percentage: CGFloat = 0.2) -> UIColor {
        return adjust(by: abs(percentage))
    }
    
    /// Creates a darker version of the color
    func darker(by percentage: CGFloat = 0.2) -> UIColor {
        return adjust(by: -abs(percentage))
    }
    
    private func adjust(by percentage: CGFloat) -> UIColor {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return UIColor(
            red: min(red + percentage, 1.0),
            green: min(green + percentage, 1.0),
            blue: min(blue + percentage, 1.0),
            alpha: alpha
        )
    }
}

