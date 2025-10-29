import Foundation

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
}
