import Foundation
import SwiftUI

struct NoteModel: Identifiable, Codable {
    var id: UUID
    var title: String
    var content: String
    var category: NoteCategory
    var tags: [String]
    var isPinned: Bool
    var createdDate: Date
    var modifiedDate: Date
    var linkedRecipeID: UUID?
    
    init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        category: NoteCategory = .general,
        tags: [String] = [],
        isPinned: Bool = false,
        createdDate: Date = Date(),
        modifiedDate: Date = Date(),
        linkedRecipeID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
        self.tags = tags
        self.isPinned = isPinned
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
        self.linkedRecipeID = linkedRecipeID
    }
}

enum NoteCategory: String, Codable, CaseIterable {
    // Top 3 prominent categories
    case general = "General"
    case recipe = "Recipe Ideas"
    case shopping = "Shopping"
    
    // Additional 6 categories (collapsed)
    case mealPlan = "Meal Planning"
    case tips = "Cooking Tips"
    case journal = "Food Journal"
    case ingredients = "Ingredients"
    case techniques = "Techniques"
    case restaurants = "Restaurants"
    
    // Catch-all
    case other = "Other"
    
    var icon: String {
        switch self {
        case .general: return "note.text"
        case .recipe: return "fork.knife"
        case .shopping: return "cart"
        case .mealPlan: return "calendar"
        case .tips: return "lightbulb"
        case .journal: return "book"
        case .ingredients: return "leaf"
        case .techniques: return "hand.raised"
        case .restaurants: return "building.2"
        case .other: return "ellipsis.circle"
        }
    }
    
    // Top 3 categories to show prominently
    static var topCategories: [NoteCategory] {
        [.general, .recipe, .shopping]
    }
    
    // Other categories (collapsed by default)
    static var moreCategories: [NoteCategory] {
        [.mealPlan, .tips, .journal, .ingredients, .techniques, .restaurants, .other]
    }
}

// Extension for search and filtering
extension NoteModel {
    func matches(searchText: String) -> Bool {
        guard !searchText.isEmpty else { return true }
        let lowercased = searchText.lowercased()
        return title.lowercased().contains(lowercased) ||
               content.lowercased().contains(lowercased) ||
               tags.contains(where: { $0.lowercased().contains(lowercased) })
    }
}
