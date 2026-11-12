import Foundation

/// User-created recipe group; stored on the phone (`CollectionEntity` rows), membership by ID so RecipeModel stays untouched.
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

/// Collection colour chip; string-backed so new colours don't break encoded archives.
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
