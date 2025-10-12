import Foundation

enum RecipeViewMode: String, CaseIterable {
    case list = "List"
    case grid = "Grid"
    
    var columns: Int {
        switch self {
        case .list: return 1
        case .grid: return 2
        }
    }
    
    var icon: String {
        switch self {
        case .list: return "rectangle.grid.1x2"
        case .grid: return "square.grid.2x2"
        }
    }
}
