import Testing
@testable import RecipeFinder

/// The recipe editor's modular behaviour: which sections render for a given
/// focus, and the navigation title. Pins the focused-vs-full-form logic behind
/// the deep-link (tap ingredients → Ingredients-only editor) and the create /
/// edit / focused titles.
@MainActor
@Suite("Recipe editor sections")
struct RecipeWizardSectionTests {

    @Test("Unfocused shows every section in display order")
    func showsAllWhenUnfocused() {
        #expect(RecipeWizardView.Section.shown(for: nil) == RecipeWizardView.Section.allCases)
    }

    @Test("Focused shows only that one section", arguments: RecipeWizardView.Section.allCases)
    func showsOnlyFocusedSection(section: RecipeWizardView.Section) {
        #expect(RecipeWizardView.Section.shown(for: section) == [section])
    }

    @Test("Every section has a non-empty title", arguments: RecipeWizardView.Section.allCases)
    func everySectionHasATitle(section: RecipeWizardView.Section) {
        #expect(!section.title.isEmpty)
    }

    @Test("Focused title is the section's own title")
    func focusedTitleUsesSection() {
        #expect(RecipeWizardView.editorTitle(focus: .ingredients, isEditing: true) == "Ingredients")
        #expect(RecipeWizardView.editorTitle(focus: .details, isEditing: false) == "Details")
    }

    @Test("Unfocused title reflects create vs edit")
    func unfocusedTitleReflectsMode() {
        #expect(RecipeWizardView.editorTitle(focus: nil, isEditing: false) == "New Recipe")
        #expect(RecipeWizardView.editorTitle(focus: nil, isEditing: true) == "Edit Recipe")
    }
}
