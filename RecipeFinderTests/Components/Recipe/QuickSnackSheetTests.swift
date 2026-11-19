import Testing
import Foundation
@testable import RecipeFinder

@Suite("QuickSnackSheet")
struct QuickSnackSheetTests {

    @Test("A quick snack saves Basic difficulty, one of the listed levels")
    func snackIsBasic() {
        let snack = QuickSnackSheet.makeSnack(name: "Apple", servings: 2, emoji: "🍎")
        #expect(snack.difficulty == "Basic")
        #expect(RecipeWizardBuilder.difficultyLevels.contains(snack.difficulty))
    }

    @Test("The Basic difficulty filter finds a quick snack")
    func basicFilterFindsSnack() {
        let snack = QuickSnackSheet.makeSnack(name: "Apple", servings: 1, emoji: "🍎")
        #expect(RecipeWizardBuilder.normalizeDifficulty(snack.difficulty) == "Basic")
    }

    @Test("A quick snack keeps its name, servings and emoji note")
    func snackKeepsDetails() {
        let snack = QuickSnackSheet.makeSnack(name: "Crisps", servings: 3, emoji: "🥔")
        #expect(snack.name == "Crisps")
        #expect(snack.category == "Snack")
        #expect(snack.currentServings == 3)
        #expect(snack.baseServings == 3)
        #expect(snack.notes == "🥔 Quick snack")
        #expect(snack.instructions == ["Enjoy your Crisps!"])
    }
}
