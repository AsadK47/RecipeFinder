import Foundation

struct DietaryInfo: Codable, Hashable {
    var isVegetarian: Bool
    var isVegan: Bool
    var isGlutenFree: Bool
    var isDairyFree: Bool
    var isNutFree: Bool
    var isLowCarb: Bool
    var isKeto: Bool
    
    init(
        isVegetarian: Bool = false,
        isVegan: Bool = false,
        isGlutenFree: Bool = false,
        isDairyFree: Bool = false,
        isNutFree: Bool = false,
        isLowCarb: Bool = false,
        isKeto: Bool = false
    ) {
        self.isVegetarian = isVegetarian
        self.isVegan = isVegan
        self.isGlutenFree = isGlutenFree
        self.isDairyFree = isDairyFree
        self.isNutFree = isNutFree
        self.isLowCarb = isLowCarb
        self.isKeto = isKeto
    }
    
    var activeTags: [String] {
        var tags: [String] = []
        if isVegetarian { tags.append("Vegetarian") }
        if isVegan { tags.append("Vegan") }
        if isGlutenFree { tags.append("Gluten-Free") }
        if isDairyFree { tags.append("Dairy-Free") }
        if isNutFree { tags.append("Nut-Free") }
        if isLowCarb { tags.append("Low-Carb") }
        if isKeto { tags.append("Keto") }
        return tags
    }
}
