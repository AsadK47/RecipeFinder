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
        (Notification.Name.openRecipes, AppTab.recipes),
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

    @Test func sheetOffersEveryWayToAddInOrder() {
        #expect(AddRecipeOption.allCases == [.link, .web, .paste, .photo, .otherApp, .manual])
    }

    /// The old Import tab's identifiers stay, so UI tests and screenshots keep finding each card.
    @Test func keepsImportIdentifiers() {
        #expect(AddRecipeOption.link.accessibilityID == "import.link")
        #expect(AddRecipeOption.web.accessibilityID == "import.web")
        #expect(AddRecipeOption.paste.accessibilityID == "import.paste")
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

@Suite struct TodayGreetingTests {

    @Test(arguments: [(0, "Good morning"), (7, "Good morning"), (11, "Good morning"),
                      (12, "Good afternoon"), (17, "Good afternoon"),
                      (18, "Good evening"), (23, "Good evening")])
    func greetingFollowsTimeOfDay(hour: Int, expected: String) {
        #expect(TodayView.greeting(forHour: hour) == expected)
    }
}
