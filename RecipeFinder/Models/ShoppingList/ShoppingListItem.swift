import Foundation

struct ShoppingListItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var quantity: Int
    var isChecked: Bool = false
    var category: String
    
    init(id: UUID = UUID(), name: String, isChecked: Bool = false, quantity: Int = 1, category: String = "Other") {
        self.id = id
        self.name = name
        self.isChecked = isChecked
        self.quantity = quantity
        self.category = category
    }
}
