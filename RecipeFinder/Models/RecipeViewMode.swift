import Foundation

enum RecipeViewMode: String, CaseIterable {
    case list = "List"
    
    var columns: Int {
        return 1
    }
    
    var icon: String {
        return "rectangle.grid.1x2"
    }
}
