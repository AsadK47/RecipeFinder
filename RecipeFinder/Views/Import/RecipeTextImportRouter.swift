import Foundation

/// Turns free text — a pasted caption, photo OCR output, or a share-sheet
/// payload — into wizard prefill for review. Runs the on-device interpreter when
/// it's available and falls back to the heuristic `TextRecipeParser`, so the
/// paste-text, photo, and share entry points all share one path. The interpreter
/// is injected so the routing is unit-tested without the model or network.
@MainActor
struct RecipeTextImportRouter {
    private let interpreter: RecipeTextInterpreting

    init(interpreter: RecipeTextInterpreting = makeRecipeTextInterpreter()) {
        self.interpreter = interpreter
    }

    /// Wizard prefill for the text, or `nil` when no recipe could be found.
    func prefill(for text: String) async -> RecipeWizardView.PrefilledRecipeData? {
        switch await SharedTextImporter(interpreter: interpreter).handle(text) {
        case .interpreted(let recipe):
            return RecipeWizardView.PrefilledRecipeData(interpreted: recipe)
        case .needsManualEntry(let raw):
            return TextRecipeParser.parse(raw)
        }
    }
}

/// Selects the on-device FoundationModels interpreter when the OS and hardware
/// support it, otherwise an interpreter that always declines so callers fall
/// back to the heuristic parser / manual entry.
func makeRecipeTextInterpreter() -> RecipeTextInterpreting {
    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
        return FoundationModelsRecipeInterpreter()
    }
    #endif
    return UnavailableRecipeTextInterpreter()
}
