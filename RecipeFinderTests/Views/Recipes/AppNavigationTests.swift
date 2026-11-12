import Foundation
import Testing
@testable import RecipeFinder

/// Tab structure (Today · Recipes · Plan · Groceries · Me) and the Recipes "+" sheet that replaced the Import tab.
@Suite struct AppTabTests {

    @Test func tabsAreInDisplayOrder() {
        #expect(AppTab.allCases == [.today, .recipes, .plan, .groceries, .me])
        #expect(AppTab.allCases.map(\.title) == ["Today", "Recipes", "Plan", "Groceries", "Me"])
    }

    @Test func launchLandsOnToday() {
        #expect(AppTab.launchDefault == .today)
    }

    @Test(arguments: [
        (Notification.Name.openToday, AppTab.today),
        (.openRecipes, .recipes),
        (.openRecipe, .recipes),
        (.openGroceries, .groceries),
        (.openMealPlan, .plan),
    ])
    func navigationNotificationOpensItsTab(name: Notification.Name, tab: AppTab) {
        #expect(AppTab.destination(for: name) == tab)
    }

    @Test(arguments: [Notification.Name.openTimer, .cookingModeNextStep, Notification.Name("Unrelated")])
    func otherNotificationsLeaveTheTabAlone(name: Notification.Name) {
        #expect(AppTab.destination(for: name) == nil)
    }

    @Test func everyTabHasAnIcon() {
        #expect(AppTab.allCases.allSatisfy { !$0.icon.isEmpty })
    }
}

@Suite struct AddRecipeOptionTests {

    /// Link and text go through the paste box at the top; these are the other ways in, in order.
    @Test func sheetOffersTheOtherWaysToAddInOrder() {
        #expect(AddRecipeOption.allCases == [.photo, .web, .otherApp, .manual])
    }

    /// The old Import tab's identifiers stay, so UI tests and screenshots keep finding each card.
    @Test func keepsImportIdentifiers() {
        #expect(AddRecipeOption.web.accessibilityID == "import.web")
        #expect(AddRecipeOption.photo.accessibilityID == "import.photo")
        #expect(AddRecipeOption.manual.accessibilityID == "import.wizard")
    }

    @Test func identifiersAndTitlesAreUnique() {
        let options = AddRecipeOption.allCases
        #expect(Set(options.map(\.accessibilityID)).count == options.count)
        #expect(Set(options.map(\.title)).count == options.count)
        #expect(options.allSatisfy { !$0.subtitle.isEmpty && !$0.icon.isEmpty })
    }
}

/// The "+" sheet's one paste box: links go to the link importer, everything else to the text reader.
@Suite struct AddRecipeInputTests {

    @Test(arguments: ["", "   ", "\n\n  \t"])
    func blankIsEmpty(raw: String) {
        #expect(AddRecipeInput.classify(raw) == .empty)
    }

    @Test(arguments: [
        ("https://www.bbcgoodfood.com/recipes/lemon-drizzle", "https://www.bbcgoodfood.com/recipes/lemon-drizzle"),
        ("  http://example.com/stew \n", "http://example.com/stew"),
        ("Made this last night!! https://cooking.example.org/pasta so good", "https://cooking.example.org/pasta"),
    ])
    func aLinkWithFewWordsIsALink(raw: String, expected: String) {
        #expect(AddRecipeInput.classify(raw) == .link(URL(string: expected) ?? URL(fileURLWithPath: "/")))
    }

    @Test func recipeTextIsText() {
        let raw = "Pancakes\n200 g flour\n2 eggs\n300 ml milk\nWhisk everything, then fry in a hot pan."
        #expect(AddRecipeInput.classify(raw) == .text(raw))
    }

    /// An Instagram-style caption with the recipe in it and a link at the end is read as the recipe text.
    @Test func longCaptionMentioningALinkIsText() {
        let raw = "Easy lemon cake: 200 g flour, 2 eggs, zest of two lemons, bake 30 min. More at https://example.com/cake"
        #expect(AddRecipeInput.classify(raw) == .text(raw))
    }

    @Test func textIsTrimmed() {
        #expect(AddRecipeInput.classify("  Nan's stew\nbeef, carrots  \n") == .text("Nan's stew\nbeef, carrots"))
    }

    @Test(arguments: ["ftp://example.com/recipe", "example dot com"])
    func nonWebLinksAreText(raw: String) {
        #expect(AddRecipeInput.classify(raw) == .text(raw))
    }
}

@Suite struct TodayGreetingTests {

    @Test(arguments: [(0, "Good morning"), (7, "Good morning"), (11, "Good morning"),
                      (12, "Good afternoon"), (17, "Good afternoon"),
                      (18, "Good evening"), (23, "Good evening")])
    func greetingFollowsTimeOfDay(hour: Int, expected: String) {
        #expect(TodayView.greeting(forHour: hour) == expected)
    }
}

/// Add flow 2/3: a read link goes straight to the recipe screen unless the library already has that recipe.
@Suite struct AddRecipeLinkResultTests {

    @Test func newRecipeGoesStraightToReview() {
        #expect(AddRecipeLinkResult.decide(recipeName: "Lemon Cake", existingNames: ["Banana Bread"]) == .review)
    }

    @Test(arguments: ["lemon cake", "  Lemon   Cake ", "LEMON CAKE"])
    func sameNameIgnoringCaseAndSpacingAsksFirst(existing: String) {
        #expect(AddRecipeLinkResult.decide(recipeName: "Lemon Cake", existingNames: [existing]) == .duplicate)
    }

    @Test func unnamedRecipeIsNeverADuplicate() {
        #expect(AddRecipeLinkResult.decide(recipeName: "  ", existingNames: ["", "  "]) == .review)
    }

    @Test func emptyLibraryGoesStraightToReview() {
        #expect(AddRecipeLinkResult.decide(recipeName: "Lemon Cake", existingNames: []) == .review)
    }
}

@MainActor @Suite struct AddRecipeFlowSourceTests {

    @Test func sharedLinkIsReadAsLink() {
        guard case .link(let url) = AddRecipeImportFlow.Source.from("https://example.com/cake") else {
            Issue.record("Expected a link")
            return
        }
        #expect(url.host() == "example.com")
    }

    @Test func sharedCaptionIsReadAsText() {
        let caption = "Nan's lemon cake\n200 g flour\n2 eggs\nBake 30 minutes"
        guard case .text(let text) = AddRecipeImportFlow.Source.from(caption) else {
            Issue.record("Expected text")
            return
        }
        #expect(text == caption)
    }
}
