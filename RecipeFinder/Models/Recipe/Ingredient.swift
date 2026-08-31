import Foundation

struct Ingredient: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    let baseQuantity: Double
    let unit: String
    private var _name: String
    
    var name: String {
        get { _name.capitalized }
        set { _name = newValue }
    }
    
    init(id: UUID = UUID(), baseQuantity: Double, unit: String, name: String) {
        self.id = id
        self.baseQuantity = baseQuantity
        self.unit = unit
        self._name = name
    }
    
    enum CodingKeys: String, CodingKey {
        case id, baseQuantity, unit
        case _name = "name"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Ingredient, rhs: Ingredient) -> Bool {
        lhs.id == rhs.id
    }
    
    func scaledQuantity(for scaleFactor: Double) -> Double {
        baseQuantity * scaleFactor
    }
    
    func formattedQuantity(for scaleFactor: Double) -> String {
        FractionFormatter.format(scaledQuantity(for: scaleFactor))
    }
    
    func converted(to system: MeasurementSystem, scaleFactor: Double = 1.0) -> (quantity: Double, unit: String) {
        let scaledQty = scaledQuantity(for: scaleFactor)
        return UnitConversion.convert(value: scaledQty, unit: unit, to: system, ingredientName: name)
    }
    
    func formattedWithUnit(for scaleFactor: Double, system: MeasurementSystem) -> String {
        let converted = converted(to: system, scaleFactor: scaleFactor)
        let formattedValue = FractionFormatter.format(converted.quantity)
        return converted.unit.isEmpty ? formattedValue : "\(formattedValue) \(converted.unit)"
    }
    
    var displayName: String {
        return IngredientNameFormatter.formatForDisplay(name)
    }
    
    var mainIngredientName: String {
        return IngredientNameFormatter.extractMainName(name)
    }
    
    var preparationNotes: String? {
        return IngredientNameFormatter.extractPreparationNotes(name)
    }
}
