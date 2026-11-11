import Testing
import Foundation
@testable import RecipeFinder

@Suite("RecipeWizardBuilder")
struct RecipeWizardBuilderTests {

    // MARK: - normalizeDifficulty

    @Test(
        "Free-text difficulty maps onto the wizard's three levels",
        arguments: [
            ("easy", "Basic"),
            ("Beginner", "Basic"),
            ("basic", "Basic"),
            ("hard", "Expert"),
            ("Advanced", "Expert"),
            ("EXPERT", "Expert"),
            ("medium", "Intermediate"),
            ("", "Intermediate"),
            ("something odd", "Intermediate")
        ]
    )
    func normalizesDifficulty(input: String, expected: String) {
        #expect(RecipeWizardBuilder.normalizeDifficulty(input) == expected)
    }

    // MARK: - makeIngredients

    @Test("Blank-name rows are dropped and a blank amount stays 0 (no invented 1)")
    func mapsIngredientsDroppingBlankRows() {
        let items = [
            RecipeWizardView.IngredientItem(quantity: "2", unit: "cups", name: "flour"),
            RecipeWizardView.IngredientItem(quantity: "", unit: "", name: ""),
            RecipeWizardView.IngredientItem(quantity: "", unit: "pinch", name: "salt")
        ]

        let ingredients = RecipeWizardBuilder.makeIngredients(from: items)

        // `Ingredient` capitalizes names via its name formatter; assert the
        // formatted form so the test tracks the type's real behaviour.
        #expect(ingredients.count == 2)
        #expect(ingredients[0].name == "Flour")
        #expect(ingredients[0].baseQuantity == 2.0)
        #expect(ingredients[1].name == "Salt")
        #expect(ingredients[1].baseQuantity == 0)
    }

    // MARK: - validate

    @Test("A fully valid draft passes validation")
    func validatesGoodDraft() throws {
        try RecipeWizardBuilder.validate(
            name: "Pancakes",
            servings: 4,
            ingredientItems: [RecipeWizardView.IngredientItem(quantity: "2", unit: "cups", name: "flour")],
            mainInstructions: [EditableStep(text: "Mix and cook")]
        )
    }

    @Test("A short name is rejected")
    func rejectsShortName() {
        #expect(throws: (any Error).self) {
            try RecipeWizardBuilder.validate(
                name: "Ab",
                servings: 4,
                ingredientItems: [RecipeWizardView.IngredientItem(quantity: "2", unit: "cups", name: "flour")],
                mainInstructions: [EditableStep(text: "Mix and cook")]
            )
        }
    }

    @Test("Out-of-range servings are rejected")
    func rejectsBadServings() {
        #expect(throws: (any Error).self) {
            try RecipeWizardBuilder.validate(
                name: "Pancakes",
                servings: 0,
                ingredientItems: [RecipeWizardView.IngredientItem(quantity: "2", unit: "cups", name: "flour")],
                mainInstructions: [EditableStep(text: "Mix and cook")]
            )
        }
    }

    @Test("No ingredients throws the ingredient error with its original wording")
    func rejectsMissingIngredients() {
        #expect(throws: RecipeWizardBuilder.BuilderError.missingIngredients) {
            try RecipeWizardBuilder.validate(
                name: "Pancakes",
                servings: 4,
                ingredientItems: [RecipeWizardView.IngredientItem(quantity: "", unit: "", name: "")],
                mainInstructions: [EditableStep(text: "Mix and cook")]
            )
        }
        #expect(RecipeWizardBuilder.BuilderError.missingIngredients.errorDescription == "Please add at least one ingredient")
    }

    @Test("No cooking instructions throws the instruction error with its original wording")
    func rejectsMissingInstructions() {
        #expect(throws: RecipeWizardBuilder.BuilderError.missingInstructions) {
            try RecipeWizardBuilder.validate(
                name: "Pancakes",
                servings: 4,
                ingredientItems: [RecipeWizardView.IngredientItem(quantity: "2", unit: "cups", name: "flour")],
                mainInstructions: [EditableStep(text: "   ")]
            )
        }
        #expect(RecipeWizardBuilder.BuilderError.missingInstructions.errorDescription == "Please add at least one cooking instruction")
    }

    // MARK: - assemble

    @Test("Assembling formats times, carries servings, and drops blank steps")
    func assemblesRecipe() {
        let id = UUID()
        let recipe = RecipeWizardBuilder.assemble(
            recipeId: id,
            name: "Pancakes",
            category: "Breakfast",
            difficulty: "Basic",
            prepTime: 10,
            cookTime: 20,
            servings: 3,
            ingredientItems: [RecipeWizardView.IngredientItem(quantity: "2", unit: "cups", name: "flour")],
            prePrepSteps: [EditableStep(text: "Sift flour"), EditableStep(text: "  ")],
            mainInstructions: [EditableStep(text: "Mix"), EditableStep(text: "Cook")],
            notes: "Serve warm",
            imageReference: "/tmp/img.jpg",
            isFavorite: true
        )

        #expect(recipe.id == id)
        #expect(recipe.name == "Pancakes")
        #expect(recipe.category == "Breakfast")
        #expect(recipe.prepTime == "10 minutes")
        #expect(recipe.cookingTime == "20 minutes")
        #expect(recipe.baseServings == 3)
        #expect(recipe.currentServings == 3)
        #expect(recipe.ingredients.count == 1)
        #expect(recipe.prePrepInstructions == ["Sift flour"])
        #expect(recipe.instructions == ["Mix", "Cook"])
        #expect(recipe.notes == "Serve warm")
        #expect(recipe.imageName == "/tmp/img.jpg")
        #expect(recipe.isFavorite == true)
        #expect(recipe.tags.isEmpty)
    }

    @Test("Tags are carried through to the assembled recipe", arguments: [
        (["spicy", "quick"], ["spicy", "quick"]),
        ([], []),
        (["Comfort Food"], ["Comfort Food"])
    ] as [([String], [String])])
    func assemblesWithTags(tags: [String], expected: [String]) {
        let recipe = RecipeWizardBuilder.assemble(
            recipeId: UUID(),
            name: "Pasta",
            category: "Main",
            difficulty: "Basic",
            prepTime: 5,
            cookTime: 15,
            servings: 2,
            ingredientItems: [RecipeWizardView.IngredientItem(quantity: "200", unit: "g", name: "pasta")],
            prePrepSteps: [],
            mainInstructions: [EditableStep(text: "Boil and serve")],
            notes: "",
            imageReference: nil,
            isFavorite: false,
            tags: tags
        )
        #expect(recipe.tags == expected)
    }

    @Test("Editing keeps fields the wizard doesn't edit: sample flag, rating, dietary info, cook history")
    func mergeEditPreservesUneditedFields() {
        var stored = RecipeModel(name: "Tandoori Chicken", category: "Main", difficulty: "Medium",
                                 prepTime: "10 minutes", cookingTime: "30 minutes", baseServings: 4,
                                 ingredients: [], prePrepInstructions: [], instructions: ["Grill."],
                                 notes: "https://example.com/tandoori", isSampleRecipe: true,
                                 cookCount: 3, lastCookedAt: Date(timeIntervalSince1970: 1_000), rating: 4)
        stored.dietaryInfo.isGlutenFree = true

        // What the wizard hands back: its own fields edited, everything else at defaults.
        let edited = RecipeModel(id: stored.id, name: "Tandoori Chicken (mine)", category: "Main",
                                 difficulty: "Intermediate", prepTime: "15 minutes", cookingTime: "30 minutes",
                                 baseServings: 2, ingredients: [], prePrepInstructions: [],
                                 instructions: ["Marinate.", "Grill."], notes: stored.notes)

        let merged = RecipeWizardBuilder.mergeEdit(edited, onto: stored)

        #expect(merged.name == "Tandoori Chicken (mine)")
        #expect(merged.instructions == ["Marinate.", "Grill."])
        #expect(merged.isSampleRecipe)
        #expect(merged.rating == 4)
        #expect(merged.dietaryInfo.isGlutenFree)
        #expect(merged.cookCount == 3)
        #expect(merged.lastCookedAt == stored.lastCookedAt)
        // Regression: an edited bundled recipe must not start re-checking its source site.
        #expect(!merged.shouldAutoRefreshFromSource)
    }

    @Test("Fraction quantities parse instead of silently saving as 1", arguments: [
        ("1/2", 0.5), ("1 1/2", 1.5), ("⅓", 1.0 / 3.0), ("0.44", 0.44), ("", 0), ("1,5", 1.5), (".5", 0.5), ("½", 0.5),
    ])
    func parsesFractionQuantities(text: String, expected: Double) {
        let item = RecipeWizardView.IngredientItem(quantity: text, unit: "cup", name: "flour")
        let quantity = RecipeWizardBuilder.makeIngredients(from: [item]).first?.baseQuantity ?? -1
        #expect(abs(quantity - expected) < 0.0001)
    }

    @Test("Edit round-trip: a ⅓ cup ingredient keeps its amount through the editor")
    func fractionRoundTripsThroughEditor() {
        let line = "\(FractionFormatter.format(1.0 / 3.0)) cup sugar"
        let parsed = WizardIngredientParser.parse(line)
        let item = RecipeWizardView.IngredientItem(quantity: parsed.quantity, unit: parsed.unit, name: parsed.name)
        let quantity = RecipeWizardBuilder.makeIngredients(from: [item]).first?.baseQuantity ?? -1
        #expect(abs(quantity - 1.0 / 3.0) < 0.0001)
    }

    @Test("Editor prefill from a recipe keeps its fields (shared by Edit and URL-import review)")
    func prefillFromRecipe() {
        let recipe = RecipeModel(name: "Scones", category: "Baking", difficulty: "Basic", prepTime: "0 minutes",
                                 cookingTime: "20 minutes", baseServings: 6,
                                 ingredients: [Ingredient(baseQuantity: 1.0 / 3.0, unit: "cup", name: "sugar")],
                                 prePrepInstructions: [], instructions: ["Bake."],
                                 notes: "https://example.com/scones", imageName: "https://example.com/scones.jpg")
        let prefill = RecipeWizardView.PrefilledRecipeData(recipe: recipe)
        #expect(prefill.name == "Scones")
        #expect(prefill.prepTime == 0)          // unknown stays unknown — no invented 15 min
        #expect(prefill.cookTime == 20)
        #expect(prefill.servings == 6)
        #expect(prefill.imageURL == "https://example.com/scones.jpg")
        #expect(prefill.ingredients?.first?.hasPrefix(FractionFormatter.format(1.0 / 3.0)) == true)
    }

    // MARK: - Original import text (Import 1/5)

    @Test func assembleCarriesTheOriginalImportText() {
        let recipe = RecipeWizardBuilder.assemble(
            recipeId: UUID(), name: "Soup", category: "Main", difficulty: "Basic", prepTime: 5, cookTime: 20,
            servings: 2, ingredientItems: [RecipeWizardView.IngredientItem(quantity: "1", unit: "", name: "onion")],
            prePrepSteps: [], mainInstructions: [EditableStep(text: "Simmer")], notes: "", imageReference: nil,
            isFavorite: false, sourceText: "pasted text"
        )
        #expect(recipe.sourceText == "pasted text")
    }

    @Test func editPrefillCarriesTheOriginalImportText() {
        var recipe = RecipeModel(
            name: "Soup", category: "Main", difficulty: "Basic", prepTime: "5 minutes", cookingTime: "20 minutes",
            baseServings: 2, ingredients: [], prePrepInstructions: [], instructions: ["Simmer"], notes: ""
        )
        recipe.sourceText = "pasted text"
        #expect(RecipeWizardView.PrefilledRecipeData(recipe: recipe).sourceText == "pasted text")
    }

    @Test func mergeEditKeepsStoredSourceTextWhenEditHasNone() {
        var stored = RecipeModel(
            name: "Soup", category: "Main", difficulty: "Basic", prepTime: "5 minutes", cookingTime: "20 minutes",
            baseServings: 2, ingredients: [], prePrepInstructions: [], instructions: ["Simmer"], notes: ""
        )
        stored.sourceText = "pasted text"
        var edited = stored
        edited.sourceText = nil
        #expect(RecipeWizardBuilder.mergeEdit(edited, onto: stored).sourceText == "pasted text")
    }

    // MARK: - Manual-entry fixes (2026-11-09)

    @Test("Whitespace-only rows are dropped and names are trimmed")
    func trimsAndDropsBlankRows() {
        let items = [
            RecipeWizardView.IngredientItem(quantity: " 2 ", unit: " g ", name: "  sugar  "),
            RecipeWizardView.IngredientItem(quantity: "", unit: "", name: "   ")
        ]
        let ingredients = RecipeWizardBuilder.makeIngredients(from: items)
        #expect(ingredients.count == 1)
        #expect(ingredients[0].name == "Sugar")
        #expect(ingredients[0].unit == "g")
        #expect(ingredients[0].baseQuantity == 2)
    }

    @Test("An amount written in words is kept in the name instead of becoming 0")
    func keepsWordAmountsInName() {
        let item = RecipeWizardView.IngredientItem(quantity: "a few", unit: "", name: "curry leaves")
        let ingredient = RecipeWizardBuilder.makeIngredients(from: [item]).first
        #expect(ingredient?.baseQuantity == 0)
        #expect(ingredient?.name == "A Few Curry Leaves")
    }

    @Test("Recipe name is trimmed when saved")
    func trimsRecipeName() {
        let recipe = RecipeWizardBuilder.assemble(
            recipeId: UUID(), name: "  Soup  ", category: "Soup", difficulty: "Basic", prepTime: 0, cookTime: 0,
            servings: 2, ingredientItems: [RecipeWizardView.IngredientItem(quantity: "1", unit: "", name: "leek")],
            prePrepSteps: [], mainInstructions: [EditableStep(text: "Cook")], notes: "", imageReference: nil,
            isFavorite: false
        )
        #expect(recipe.name == "Soup")
    }

    @Test("Draft ignores row ids and blank rows but notices real edits")
    func draftDetectsRealChangesOnly() {
        func draft(_ items: [RecipeWizardView.IngredientItem], name: String = "Soup") -> RecipeWizardBuilder.Draft {
            RecipeWizardBuilder.Draft(
                name: name, prepTime: 0, cookTime: 0, difficulty: "Basic", category: "Soup", servings: 4,
                ingredientItems: items, prePrepSteps: [EditableStep()], mainInstructions: [EditableStep()],
                notes: "", tags: [], cuisine: "", imageReference: nil, galleryReferences: []
            )
        }
        let blank = draft([RecipeWizardView.IngredientItem()])
        #expect(blank == draft([RecipeWizardView.IngredientItem(), RecipeWizardView.IngredientItem()]))
        #expect(blank != draft([RecipeWizardView.IngredientItem(quantity: "", unit: "", name: "leek")]))
        #expect(blank != draft([RecipeWizardView.IngredientItem()], name: "Stew"))
        #expect(blank == draft([RecipeWizardView.IngredientItem()], name: " Soup "))
    }

    // MARK: - Text blocks (Manual 2/3)

    @Test("a pasted block of mixed lines becomes one row per line, blanks skipped")
    func pastedIngredientBlockBecomesRows() {
        let pasted = """
        200g plain flour

        1 1/2 cups milk
        ½ tsp salt
        1,5 dl cream
        2 eggs
        a few basil leaves
        3 tbsp olive oil, plus extra
          1 onion, diced
        pinch of pepper
        400 g tin chopped tomatoes
        """
        let items = IngredientTextBlock.items(from: pasted)
        #expect(items.count == 10)
        #expect(items[0].name == "plain flour")
        #expect(items[0].unit == "g")
        #expect(RecipeWizardBuilder.parseAmount(items[1].quantity) == 1.5)
        #expect(RecipeWizardBuilder.parseAmount(items[2].quantity) == 0.5)
        #expect(RecipeWizardBuilder.parseAmount(items[3].quantity) == 1.5)
        #expect(items[5].quantity.isEmpty)
        #expect(items[5].name.contains("basil"))
        #expect(items[7].name == "onion, diced")
    }

    @Test("rows → text → rows keeps every amount, unit and name")
    func ingredientTextRoundTrip() {
        let original = IngredientTextBlock.items(from: "200 g flour\n2 eggs\nsalt, to taste\n1 1/2 cup milk")
        let again = IngredientTextBlock.items(from: IngredientTextBlock.text(from: original))
        #expect(again.map(\.quantity) == original.map(\.quantity))
        #expect(again.map(\.unit) == original.map(\.unit))
        #expect(again.map(\.name) == original.map(\.name))
    }

    @Test("step lines drop blanks and pasted numbering")
    func stepBlockDropsNumbering() {
        let steps = StepTextBlock.steps(from: "1. Heat the oil.\n\n2) Add onions\nStep 3: Simmer 20 min\nServe hot")
        #expect(steps == ["Heat the oil.", "Add onions", "Simmer 20 min", "Serve hot"])
        #expect(StepTextBlock.steps(from: StepTextBlock.text(from: steps)) == steps)
    }

    @Test("a step starting with a quantity isn't mistaken for numbering")
    func stepWithLeadingQuantityKept() {
        #expect(StepTextBlock.steps(from: "2 cups of water go in the pot") == ["2 cups of water go in the pot"])
        #expect(StepTextBlock.steps(from: "1.5 cups stock, then 10-15 min") == ["1.5 cups stock, then 10-15 min"])
    }
}

/// Add flow 3/3 slice 2: ingredient groups ("For the sauce") are a label on each row, written as "Title:" header lines
/// in text — never an ingredient row of their own.
@Suite("Ingredient sections")
struct IngredientSectionsTests {

    @Test("Header lines are recognised and read back as the group title", arguments: [
        ("For the sauce:", "For the sauce"), ("FOR THE CHICKEN", "For the chicken"), ("To make the glaze:", "To make the glaze"),
        ("Topping:", "Topping"), ("For the Dressing", "For the Dressing")
    ])
    func headerTitles(line: String, title: String) {
        #expect(IngredientSections.title(ofHeaderLine: line) == title)
    }

    @Test("Ingredient lines are never headers", arguments: [
        "200 g flour", "salt, to taste", "For 4 people: 2 eggs", "Butter", "1 tbsp oil:", "Note: use ripe bananas"
    ])
    func ingredientLinesAreNotHeaders(line: String) {
        #expect(IngredientSections.title(ofHeaderLine: line) == nil)
    }

    @Test("The text box groups rows under each header and drops the header itself")
    func textBlockGroupsRows() {
        let items = IngredientTextBlock.items(from: "2 eggs\nFor the sauce:\n3 tbsp honey\n2 tbsp soy sauce")
        #expect(items.map(\.name) == ["eggs", "honey", "soy sauce"])
        #expect(items.map(\.section) == ["", "For the sauce", "For the sauce"])
    }

    @Test("Groups survive text → rows → text → rows")
    func textBlockRoundTrip() {
        let text = "For the chicken:\n500 g chicken thighs\n1 egg\nFor the sauce:\n3 tbsp honey"
        let once = IngredientTextBlock.items(from: text)
        let twice = IngredientTextBlock.items(from: IngredientTextBlock.text(from: once))
        #expect(IngredientTextBlock.text(from: once) == text)
        #expect(twice.map(\.section) == once.map(\.section))
        #expect(twice.map(\.name) == once.map(\.name))
    }

    @Test("Saving keeps each row's group; ungrouped rows have none")
    func makeIngredientsKeepsSection() {
        let items = IngredientTextBlock.items(from: "salt\nFor the sauce:\n3 tbsp honey")
        let ingredients = RecipeWizardBuilder.makeIngredients(from: items)
        #expect(ingredients.map(\.section) == [nil, "For the sauce"])
        #expect(ingredients.count == 2)
    }

    @Test("Editing a saved recipe writes its groups back as header lines")
    func editPrefillWritesHeaders() {
        let recipe = RecipeModel(
            name: "Sticky Chicken", category: "Main", difficulty: "Basic", prepTime: "10 minutes",
            cookingTime: "20 minutes", baseServings: 4, currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 1, unit: "", name: "egg"),
                Ingredient(baseQuantity: 3, unit: "tbsp", name: "honey", section: "For the sauce"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "soy sauce", section: "For the sauce")
            ],
            prePrepInstructions: [], instructions: ["Cook."], notes: ""
        )
        let lines = RecipeWizardView.PrefilledRecipeData(recipe: recipe).ingredients ?? []
        #expect(lines.count == 4)
        #expect(lines[1] == "For the sauce:")
        let items = IngredientTextBlock.items(from: lines.joined(separator: "\n"))
        #expect(items.map(\.section) == ["", "For the sauce", "For the sauce"])
    }

    @Test("A group title shows only where the group starts")
    func titleStartingAt() {
        let ingredients = [
            Ingredient(baseQuantity: 1, unit: "", name: "egg"),
            Ingredient(baseQuantity: 3, unit: "tbsp", name: "honey", section: "Sauce"),
            Ingredient(baseQuantity: 2, unit: "tbsp", name: "soy", section: "Sauce"),
            Ingredient(baseQuantity: 1, unit: "tsp", name: "sesame", section: "To serve")
        ]
        #expect((0..<5).map { IngredientSections.title(startingAt: $0, in: ingredients) } == [nil, "Sauce", nil, "To serve", nil])
    }

    @Test("Imports with header lines group the ingredients and never make a header an ingredient")
    func importBuilderGroups() {
        let ingredients = RecipeImportBuilder().parseIngredients(["FOR THE SAUCE", "3 tbsp honey", "", "Garnish:", "1 tsp sesame seeds"])
        #expect(ingredients.map(\.section) == ["For the sauce", "Garnish"])
        #expect(ingredients.map(\.baseQuantity) == [3, 1])
    }

    @Test("Section round-trips through JSON, and stored ingredients without one still decode")
    func codable() throws {
        let original = Ingredient(baseQuantity: 2, unit: "tbsp", name: "honey", section: "For the sauce")
        let decoded = try JSONDecoder().decode(Ingredient.self, from: JSONEncoder().encode(original))
        #expect(decoded.section == "For the sauce")
        let legacy = Data(#"{"id":"\#(UUID().uuidString)","baseQuantity":1,"unit":"","name":"egg"}"#.utf8)
        #expect(try JSONDecoder().decode(Ingredient.self, from: legacy).section == nil)
    }

    @Test("Accepting an estimated amount keeps the group")
    func withAmountKeepsSection() {
        let row = Ingredient(baseQuantity: 0, unit: "", name: "honey", section: "Sauce")
        #expect(row.withAmount(2, unit: "tbsp").section == "Sauce")
    }
}
