import XCTest
@testable import RecipeFinder

final class QuickSnackViewModelTests: XCTestCase {

    private var sut: QuickSnackViewModel!

    override func setUp() {
        super.setUp()
        sut = QuickSnackViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialSnackName_isEmpty() {
        XCTAssertTrue(sut.snackName.isEmpty)
    }

    func testInitialServings_isMinimum() {
        XCTAssertEqual(sut.servings, 1)
    }

    func testInitialSelectedEmoji_isApple() {
        XCTAssertEqual(sut.selectedEmoji, "🍎")
    }

    func testInitialShowEmojiPicker_isFalse() {
        XCTAssertFalse(sut.showEmojiPicker)
    }

    func testInitialSelectedDietaryFilters_isEmpty() {
        XCTAssertTrue(sut.selectedDietaryFilters.isEmpty)
    }

    func testInitialSelectedSnack_isNil() {
        XCTAssertNil(sut.selectedSnack)
    }

    // MARK: - hasCustomInput

    func testHasCustomInput_whenSnackNameIsEmpty_returnsFalse() {
        sut.snackName = ""
        XCTAssertFalse(sut.hasCustomInput)
    }

    func testHasCustomInput_whenSnackNameIsNonEmpty_returnsTrue() {
        sut.snackName = "Apple"
        XCTAssertTrue(sut.hasCustomInput)
    }

    // MARK: - canAddSnack

    func testCanAddSnack_whenSnackNameIsEmpty_returnsFalse() {
        sut.snackName = ""
        XCTAssertFalse(sut.canAddSnack)
    }

    func testCanAddSnack_whenSnackNameIsNonEmpty_returnsTrue() {
        sut.snackName = "Granola Bar"
        XCTAssertTrue(sut.canAddSnack)
    }

    // MARK: - filteredSnacks

    func testFilteredSnacks_withNoFilters_returnsAllSnacks() {
        sut.selectedDietaryFilters = []
        XCTAssertEqual(sut.filteredSnacks.count, SnackDatabase.allSnacks.count)
    }

    func testFilteredSnacks_withVeganFilter_returnsOnlyVeganSnacks() {
        sut.selectedDietaryFilters = [.vegan]
        let results = sut.filteredSnacks
        XCTAssertTrue(results.allSatisfy { $0.dietaryTags.contains(.vegan) })
    }

    func testFilteredSnacks_withMultipleFilters_returnsSnacksSatisfyingAllFilters() {
        sut.selectedDietaryFilters = [.vegan, .glutenFree]
        let results = sut.filteredSnacks
        XCTAssertTrue(results.allSatisfy {
            $0.dietaryTags.contains(.vegan) && $0.dietaryTags.contains(.glutenFree)
        })
    }

    // MARK: - selectSnack

    func testSelectSnack_setsEmojiFromSnack() {
        let snack = makeSnack(emoji: "🍌", name: "Banana")
        sut.selectSnack(snack)
        XCTAssertEqual(sut.selectedEmoji, "🍌")
    }

    func testSelectSnack_setsSnackNameFromSnack() {
        let snack = makeSnack(emoji: "🍌", name: "Banana")
        sut.selectSnack(snack)
        XCTAssertEqual(sut.snackName, "Banana")
    }

    func testSelectSnack_setsSelectedSnack() {
        let snack = makeSnack(emoji: "🍌", name: "Banana")
        sut.selectSnack(snack)
        XCTAssertEqual(sut.selectedSnack?.id, snack.id)
    }

    // MARK: - createSnackRecipe

    func testCreateSnackRecipe_usesSnackName() {
        sut.snackName = "Trail Mix"
        let recipe = sut.createSnackRecipe()
        XCTAssertEqual(recipe.name, "Trail Mix")
    }

    func testCreateSnackRecipe_usesCurrentServings() {
        sut.snackName = "Trail Mix"
        sut.servings = 3
        let recipe = sut.createSnackRecipe()
        XCTAssertEqual(recipe.currentServings, 3)
    }

    func testCreateSnackRecipe_categoryIsSnack() {
        sut.snackName = "Trail Mix"
        let recipe = sut.createSnackRecipe()
        XCTAssertEqual(recipe.category, "Snack")
    }

    func testCreateSnackRecipe_prepTimeIsZero() {
        sut.snackName = "Trail Mix"
        let recipe = sut.createSnackRecipe()
        XCTAssertEqual(recipe.prepTime, "0 min")
    }

    func testCreateSnackRecipe_difficultyIsOne() {
        sut.snackName = "Trail Mix"
        let recipe = sut.createSnackRecipe()
        XCTAssertEqual(recipe.difficulty, 1)
    }

    func testCreateSnackRecipe_notesContainEmojiPrefix() {
        sut.snackName = "Apple"
        sut.selectedEmoji = "🍎"
        let recipe = sut.createSnackRecipe()
        XCTAssertTrue(recipe.notes?.contains("Quick snack - 🍎") == true)
    }

    func testCreateSnackRecipe_withSelectedSnackAndCalories_notesContainCalories() {
        let snack = makeSnack(emoji: "🍎", name: "Apple", calories: 95)
        sut.snackName = "Apple"
        sut.selectSnack(snack)
        let recipe = sut.createSnackRecipe()
        XCTAssertTrue(recipe.notes?.contains("Calories: ~95 per serving") == true)
    }

    func testCreateSnackRecipe_withSelectedSnackAndDietaryTags_notesContainTags() {
        let snack = makeSnack(emoji: "🍎", name: "Apple", dietaryTags: [.vegan, .glutenFree])
        sut.snackName = "Apple"
        sut.selectSnack(snack)
        let recipe = sut.createSnackRecipe()
        XCTAssertTrue(recipe.notes?.contains("Dietary:") == true)
        XCTAssertTrue(recipe.notes?.contains("Vegan") == true)
        XCTAssertTrue(recipe.notes?.contains("Gluten-Free") == true)
    }

    func testCreateSnackRecipe_withSelectedSnackAndNoTags_notesDoNotContainDietaryLine() {
        let snack = makeSnack(emoji: "🍎", name: "Apple", dietaryTags: [])
        sut.snackName = "Apple"
        sut.selectSnack(snack)
        let recipe = sut.createSnackRecipe()
        XCTAssertFalse(recipe.notes?.contains("Dietary:") == true)
    }

    func testCreateSnackRecipe_withNoSelectedSnack_notesContainOnlyPrefix() {
        sut.snackName = "Apple"
        sut.selectedEmoji = "🍎"
        let recipe = sut.createSnackRecipe()
        XCTAssertEqual(recipe.notes, "Quick snack - 🍎")
    }

    func testCreateSnackRecipe_isFavoriteIsFalse() {
        sut.snackName = "Apple"
        let recipe = sut.createSnackRecipe()
        XCTAssertFalse(recipe.isFavorite)
    }

    func testCreateSnackRecipe_ingredientsAreEmpty() {
        sut.snackName = "Apple"
        let recipe = sut.createSnackRecipe()
        XCTAssertTrue(recipe.ingredients.isEmpty)
    }

    // MARK: - Helpers

    private func makeSnack(
        emoji: String,
        name: String,
        dietaryTags: [DietaryTag] = [],
        calories: Int? = nil
    ) -> SnackItem {
        SnackItem(
            emoji: emoji,
            name: name,
            dietaryTags: dietaryTags,
            calories: calories,
            category: .fruit
        )
    }
}
