import Testing
@testable import RecipeFinder

/// The recipe editor's modular behaviour: which sections render for a given focus, and the create/edit/focused navigation titles (pins the deep-link focused-vs-full-form logic).
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

    // Each focused section is its own `.sheet(item:)` identity, distinct from the full (nil) editor — so tapping
    // "cook time" then an ingredient re-presents instead of reusing a stale sheet. Guards the detent-size bug fix.
    @Test("Focused edit targets have a stable id distinct from the full editor", arguments: RecipeWizardView.Section.allCases)
    func editTargetIdsAreDistinct(section: RecipeWizardView.Section) {
        let focused = RecipeDetailView.EditTarget(section: section)
        let full = RecipeDetailView.EditTarget(section: nil)
        #expect(focused.id != full.id)
        #expect(focused.id == RecipeDetailView.EditTarget(section: section).id)
    }
}

@Suite struct PhotoRemoveLabelTests {

    @Test("Remove buttons are named by the photo's position, counting from 1", arguments: [(1, "Remove photo 1"), (4, "Remove photo 4")])
    func label(position: Int, expected: String) {
        #expect(RecipeNameStepView.removePhotoLabel(position: position) == expected)
    }
}
