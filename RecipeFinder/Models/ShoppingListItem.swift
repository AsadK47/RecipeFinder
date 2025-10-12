import SwiftUI

struct ShoppingListItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var isChecked: Bool
    var quantity: Int
    var category: String
    var dateAdded: Date
    
    init(id: UUID = UUID(), name: String, isChecked: Bool = false, quantity: Int = 1, category: String = "Other", dateAdded: Date = Date()) {
        self.id = id
        self.name = name
        self.isChecked = isChecked
        self.quantity = quantity
        self.category = category
        self.dateAdded = dateAdded
    }
}
