import Foundation

/// The add/import-review screen's read-only view of a draft: the recipe as it will look once saved. Pure so the
/// screen's copy is unit-tested; the view only decides how each part looks when it's still empty.
struct RecipeDraftPreview: Equatable {
    let title: String?
    let timeSummary: String?
    let servingsLabel: String
    let detailChips: [String]
    let ingredientLines: [String]
    let prePrepSteps: [String]
    let steps: [String]
    let notes: String?

    init(draft: RecipeWizardBuilder.Draft) {
        title = draft.name.isEmpty ? nil : draft.name
        timeSummary = Self.timeSummary(prep: draft.prepTime, cook: draft.cookTime)
        servingsLabel = "Serves \(draft.servings)"
        detailChips = [draft.category, draft.difficulty, draft.cuisine].filter { !$0.isEmpty } + draft.tags
        ingredientLines = draft.ingredients.compactMap { parts in
            // A row with only an amount isn't an ingredient yet (the save path drops it too).
            guard let name = parts.last, !name.isEmpty else { return nil }
            return parts.filter { !$0.isEmpty }.joined(separator: " ")
        }
        prePrepSteps = draft.prePrep
        steps = draft.steps
        notes = draft.notes.isEmpty ? nil : draft.notes
    }

    /// "Prep 10 minutes · Cook 1 hr", leaving out whichever time is unset; nil when neither is.
    static func timeSummary(prep: Int, cook: Int) -> String? {
        let parts = [
            prep > 0 ? "Prep \(DurationFormatter.label(minutes: prep))" : nil,
            cook > 0 ? "Cook \(DurationFormatter.label(minutes: cook))" : nil
        ].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

extension RecipeWizardView.Section: Identifiable {
    var id: Self { self }

    /// The sections that edit the parts an import couldn't read, so the screen can outline them (Import 2/5).
    static func needingCheck(_ missing: Set<ImportQuality.Field>) -> Set<Self> {
        Set(missing.map { field in
            switch field {
            case .name: .basics
            case .times: .details
            case .ingredients, .amounts: .ingredients
            case .steps: .instructions
            }
        })
    }
}
