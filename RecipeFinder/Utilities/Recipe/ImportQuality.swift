import Foundation

/// How well an import was read (Import 2/5). The score decides whether the wizard warns; the missing fields decide what
/// it highlights. Pure so it's unit-tested without the wizard.
enum ImportQuality {
    enum Field: CaseIterable, Hashable {
        case name, ingredients, steps, amounts, times
    }

    struct Assessment: Equatable {
        let score: Double
        let missing: Set<Field>
        /// Below this the wizard shows "We couldn't read this one well".
        var isLow: Bool { score < 0.6 }
    }

    /// A URL parse's confidence (or 1.0 for an on-device AI read) is the score when present; otherwise the score comes
    /// from which fields were found. Missing fields are always computed from the content itself.
    static func assess(_ prefill: RecipeWizardView.PrefilledRecipeData) -> Assessment {
        let ingredients = (prefill.ingredients ?? []).filter { !$0.trimmed.isEmpty }
        let steps = (prefill.instructions ?? []).filter { !$0.trimmed.isEmpty }

        var missing = Set<Field>()
        if (prefill.name ?? "").trimmed.isEmpty { missing.insert(.name) }
        if ingredients.isEmpty { missing.insert(.ingredients) }
        if steps.isEmpty { missing.insert(.steps) }
        if !ingredients.contains(where: hasAmount) { missing.insert(.amounts) }
        if (prefill.prepTime ?? 0) <= 0 && (prefill.cookTime ?? 0) <= 0 { missing.insert(.times) }

        let found = Field.allCases.filter { !missing.contains($0) }.reduce(0) { $0 + weight($1) }
        let score = prefill.sourceConfidence ?? found
        return Assessment(score: min(max(score, 0), 1), missing: missing)
    }

    private static func weight(_ field: Field) -> Double {
        switch field {
        case .name: 0.2
        case .ingredients, .steps: 0.3
        case .amounts, .times: 0.1
        }
    }

    /// An ingredient line that starts with a number or vulgar fraction ("2 eggs", "½ cup", "1/2 tsp", "200g").
    private static func hasAmount(_ line: String) -> Bool {
        line.trimmed.range(of: #"^[0-9½¼¾⅓⅔⅛⅜⅝⅞]"#, options: .regularExpression) != nil
    }
}
