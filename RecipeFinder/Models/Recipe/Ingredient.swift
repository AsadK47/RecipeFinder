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
        // A zero/unspecified amount shows no fabricated "1" — just the unit, if any.
        guard converted.quantity > 0 else {
            return converted.unit
        }
        let formattedValue = FractionFormatter.format(converted.quantity)
        return converted.unit.isEmpty ? formattedValue : "\(formattedValue) \(converted.unit)"
    }
    
    var displayName: String {
        // From the stored name — `name` is Title-Cased for matching/grocery use, which read badly in recipes.
        IngredientNameFormatter.formatForDisplay(_name)
    }
    
    /// What the recipe screen shows: the name as written, split once at the first comma into the bold name and the
    /// note ("Butter" / "melted, plus extra for cooking"). Unlike `mainIngredientName` (a matching key that strips
    /// brackets and reorders words), nothing is dropped or moved.
    var displayParts: (name: String, note: String?) {
        let raw = _name.trimmingCharacters(in: .whitespaces)
        // Split at the first comma outside brackets — "kombu (2 pieces, about 5 inches), dried" keeps its bracket whole.
        var depth = 0
        var boundary: String.Index?
        for index in raw.indices {
            switch raw[index] {
            case "(": depth += 1
            case ")": depth = max(0, depth - 1)
            case "," where depth == 0: boundary = index
            default: break
            }
            if boundary != nil { break }
        }
        guard let comma = boundary else { return (IngredientNameFormatter.formatForDisplay(raw), nil) }
        let note = raw[raw.index(after: comma)...].trimmingCharacters(in: .whitespaces)
        return (IngredientNameFormatter.formatForDisplay(String(raw[..<comma])), note.isEmpty ? nil : note)
    }

    var mainIngredientName: String {
        return IngredientNameFormatter.extractMainName(name)
    }
    
    var preparationNotes: String? {
        return IngredientNameFormatter.extractPreparationNotes(name)
    }
}

extension Ingredient {
    /// Lines that never need an amount — seasoning to taste, garnish, frying/greasing oil, ice, soaking water — so a blank
    /// amount there isn't a gap. Mirrors `tools/audit-missing-amounts.py`, which audits the bundled recipes.
    static let amountOptionalPattern =
        #"to taste|to serve|to garnish|for garnish|to decorate|to dust|to top|optional|as needed|pinch|splash|"#
        + #"for (deep |shallow |pan[- ])?frying|for (dusting|greasing|brushing|sprinkling|rolling|proving|coating|cooking|"#
        + #"drizzling|soaking|dipping|pan-frying)|cooking spray|oil spray|toppings of your choice|"#
        + #"^(fine sea )?salt and (freshly ground )?(black )?pepper$|^ice( cubes)?$|^(freshly ground )?black pepper$|"#
        + #"^black pepper, freshly ground$"#

    /// Same ingredient (id and name as written) with a new amount — used when the user accepts an estimate.
    func withAmount(_ quantity: Double, unit: String) -> Ingredient {
        Ingredient(id: id, baseQuantity: quantity, unit: unit, name: _name)
    }

    /// True when the recipe gives no amount for an ingredient that normally needs one (e.g. "flour" with no quantity).
    var isMissingAmount: Bool {
        baseQuantity <= 0
            && name.range(of: Self.amountOptionalPattern, options: [.regularExpression, .caseInsensitive]) == nil
    }
}

/// Recipe-level view of missing amounts, used to decide whether to invite the user to fill them in.
enum IngredientAmountGaps {
    /// At least half of the ingredients lack an amount they'd normally need — the recipe is hard to cook as written.
    static func isMostlyMissing(_ ingredients: [Ingredient]) -> Bool {
        let gaps = ingredients.filter(\.isMissingAmount).count
        return gaps > 0 && gaps * 2 >= ingredients.count
    }
}
