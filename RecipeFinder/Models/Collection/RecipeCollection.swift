import Foundation

/// A user-created named group of recipes. Collections are local-only, backed
/// by `CollectionManager` (JSON in `UserScopedStorage`). Recipe membership is
/// stored here as a set of IDs so no changes are needed to `RecipeModel`.
struct RecipeCollection: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var colorName: CollectionColor
    var recipeIDs: [UUID]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        colorName: CollectionColor = .blue,
        recipeIDs: [UUID] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorName = colorName
        self.recipeIDs = recipeIDs
        self.createdAt = createdAt
    }

    mutating func add(_ recipeID: UUID) {
        guard !recipeIDs.contains(recipeID) else { return }
        recipeIDs.append(recipeID)
    }

    mutating func remove(_ recipeID: UUID) {
        recipeIDs.removeAll { $0 == recipeID }
    }

    func contains(_ recipeID: UUID) -> Bool {
        recipeIDs.contains(recipeID)
    }
}

/// Palette for collection colour chips. Stored as a string so new colours can
/// be added without breaking existing encoded archives.
enum CollectionColor: String, Codable, CaseIterable, Identifiable {
    case blue, green, orange, pink, purple, red, teal, yellow

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }
}

import SwiftUI

extension CollectionColor {
    var swiftUIColor: Color {
        switch self {
        case .blue:   return .blue
        case .green:  return .green
        case .orange: return .orange
        case .pink:   return .pink
        case .purple: return .purple
        case .red:    return .red
        case .teal:   return .teal
        case .yellow: return .yellow
        }
    }
}
