import Testing
import Foundation
@testable import RecipeFinder

@Suite("RecipeDraftPreview")
struct RecipeDraftPreviewTests {

    private func draft(
        name: String = "Lemon Cake",
        prep: Int = 0,
        cook: Int = 0,
        servings: Int = 4,
        items: [RecipeWizardView.IngredientItem] = [],
        prePrep: [String] = [],
        steps: [String] = [],
        notes: String = "",
        tags: [String] = [],
        cuisine: String = ""
    ) -> RecipeWizardBuilder.Draft {
        RecipeWizardBuilder.Draft(
            name: name, prepTime: prep, cookTime: cook, difficulty: "Basic", category: "Dessert", servings: servings,
            ingredientItems: items, prePrepSteps: prePrep.map { EditableStep(text: $0) },
            mainInstructions: steps.map { EditableStep(text: $0) }, notes: notes, tags: tags, cuisine: cuisine,
            imageReference: nil, galleryReferences: []
        )
    }

    @Test("A blank draft has no title, no times, and every list empty")
    func blankDraft() {
        let preview = RecipeDraftPreview(draft: draft(name: "  ", items: [RecipeWizardView.IngredientItem()],
                                                      steps: [""]))
        #expect(preview.title == nil)
        #expect(preview.timeSummary == nil)
        #expect(preview.ingredientLines.isEmpty)
        #expect(preview.steps.isEmpty)
        #expect(preview.prePrepSteps.isEmpty)
        #expect(preview.notes == nil)
    }

    @Test("Ingredient groups start where their first row is, and headers are never ingredient lines")
    func ingredientGroupStarts() {
        let items = IngredientTextBlock.items(from: "2 eggs\nFor the sauce:\n3 tbsp honey\n2 tbsp soy sauce\nTo serve:\nsesame seeds")
        let preview = RecipeDraftPreview(draft: draft(items: items))
        #expect(preview.ingredientLines.count == 4)
        #expect(preview.ingredientGroupStarts == [1: "For the sauce", 3: "To serve"])
    }

    @Test("The title is the trimmed name")
    func titleTrimmed() {
        #expect(RecipeDraftPreview(draft: draft(name: "  Lemon Cake ")).title == "Lemon Cake")
    }

    @Test(
        "Times read as prep and cook, skipping whichever is unset",
        arguments: [
            (0, 0, nil),
            (15, 0, "Prep 15 minutes"),
            (0, 90, "Cook 1 hr 30 min"),
            (10, 45, "Prep 10 minutes · Cook 45 minutes")
        ] as [(Int, Int, String?)]
    )
    func timeSummary(prep: Int, cook: Int, expected: String?) {
        #expect(RecipeDraftPreview.timeSummary(prep: prep, cook: cook) == expected)
    }

    @Test("Servings read as a label, singular for one")
    func servingsLabel() {
        #expect(RecipeDraftPreview(draft: draft(servings: 4)).servingsLabel == "Serves 4")
        #expect(RecipeDraftPreview(draft: draft(servings: 1)).servingsLabel == "Serves 1")
    }

    @Test("Ingredient lines read amount, unit and name; a missing amount shows the name alone")
    func ingredientLines() {
        let preview = RecipeDraftPreview(draft: draft(items: [
            RecipeWizardView.IngredientItem(quantity: "200", unit: "g", name: "flour"),
            RecipeWizardView.IngredientItem(quantity: "", unit: "", name: "salt"),
            RecipeWizardView.IngredientItem()
        ]))
        #expect(preview.ingredientLines == ["200 g flour", "salt"])
    }

    @Test("Steps, pre-prep and notes come through; blank notes are nil")
    func listsAndNotes() {
        let preview = RecipeDraftPreview(draft: draft(prePrep: ["Soak beans"], steps: ["Mix", "", "Bake"],
                                                      notes: " Family favourite "))
        #expect(preview.prePrepSteps == ["Soak beans"])
        #expect(preview.steps == ["Mix", "Bake"])
        #expect(preview.notes == "Family favourite")
    }

    @Test("Detail chips list category, difficulty and cuisine (when set), then tags")
    func detailChips() {
        #expect(RecipeDraftPreview(draft: draft()).detailChips == ["Dessert", "Basic"])
        #expect(RecipeDraftPreview(draft: draft(tags: ["Quick"], cuisine: "Italian")).detailChips
                == ["Dessert", "Basic", "Italian", "Quick"])
    }

    @Test(
        "Each part the reader struggled with highlights the section that edits it",
        arguments: [
            (ImportQuality.Field.name, RecipeWizardView.Section.basics),
            (.times, .details),
            (.ingredients, .ingredients),
            (.amounts, .ingredients),
            (.steps, .instructions)
        ]
    )
    func sectionsNeedingCheck(field: ImportQuality.Field, section: RecipeWizardView.Section) {
        #expect(RecipeWizardView.Section.needingCheck([field]) == [section])
    }

    @Test("No struggled parts highlights nothing")
    func nothingNeedsCheck() {
        #expect(RecipeWizardView.Section.needingCheck([]).isEmpty)
    }
}
