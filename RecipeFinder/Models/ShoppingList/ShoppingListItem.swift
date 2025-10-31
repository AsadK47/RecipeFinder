import Foundation

struct ShoppingListItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var quantity: Int
    var unit: String
    var isChecked: Bool = false
    var isCompleted: Bool = false
    var category: String
    var dateAdded: Date
    
    init(id: UUID = UUID(), name: String, isChecked: Bool = false, quantity: Int = 1, unit: String = "", category: String = "Other", dateAdded: Date = Date()) {
        self.id = id
        self.name = name
        self.isChecked = isChecked
        self.isCompleted = isChecked
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.dateAdded = dateAdded
    }
}
