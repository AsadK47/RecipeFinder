import Foundation

/// Turns free text (pasted caption, photo OCR, share payload) into wizard prefill via the on-device interpreter or heuristic `TextRecipeParser` fallback; one shared path for paste/photo/share, interpreter injected for testability.
@MainActor
struct RecipeTextImportRouter {
    private let interpreter: RecipeTextInterpreting

    init(interpreter: RecipeTextInterpreting = makeRecipeTextInterpreter()) {
        self.interpreter = interpreter
    }

    /// Wizard prefill for the text, or `nil` when no recipe could be found.
    func prefill(for text: String) async -> RecipeWizardView.PrefilledRecipeData? {
        var prefill: RecipeWizardView.PrefilledRecipeData?
        switch await SharedTextImporter(interpreter: interpreter).handle(text) {
        case .interpreted(let recipe):
            prefill = RecipeWizardView.PrefilledRecipeData(interpreted: recipe)
        case .needsManualEntry(let raw):
            prefill = TextRecipeParser.parse(raw)
        }
        // Keep what the user gave us so the recipe can be re-imported later as the parser improves.
        prefill?.sourceText = text
        return prefill
    }
}

/// On-device FoundationModels interpreter when OS/hardware support it, else one that always declines so callers fall back to the heuristic parser.
func makeRecipeTextInterpreter() -> RecipeTextInterpreting {
    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
        return FoundationModelsRecipeInterpreter()
    }
    #endif
    return UnavailableRecipeTextInterpreter()
}
