import SwiftUI

struct ShoppingListItem: Identifiable {
    let id = UUID()
    var name: String
    var isChecked: Bool
    var quantity: Int
}
