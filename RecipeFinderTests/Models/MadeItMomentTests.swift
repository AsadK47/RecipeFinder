import Testing
@testable import RecipeFinder

/// What the Made it moment says and how it moves. Pure, so the copy and the Reduce Motion rule are pinned here.
@Suite("MadeItMoment")
struct MadeItMomentTests {

    // MARK: - Subtitle: this dish

    @Test("the first cook of a recipe is called out by name")
    func firstCookOfARecipe() {
        #expect(MadeItMoment.subtitle(recipeName: "Lemon Drizzle", timesCooked: 1) == "First time making Lemon Drizzle!")
    }

    @Test("a repeat cook says how many times this dish has been made")
    func repeatCook() {
        #expect(MadeItMoment.subtitle(recipeName: "Lemon Drizzle", timesCooked: 4) == "Lemon Drizzle · made 4 times")
    }

    @Test("a recipe with no name falls back to a friendly line", arguments: ["", "   "])
    func unnamedRecipe(name: String) {
        #expect(MadeItMoment.subtitle(recipeName: name, timesCooked: 1) == "Nice cooking!")
        #expect(MadeItMoment.subtitle(recipeName: name, timesCooked: 3) == "Nice cooking!")
    }

    @Test("a name is trimmed before it is shown")
    func nameIsTrimmed() {
        #expect(MadeItMoment.subtitle(recipeName: "  Dal  ", timesCooked: 2) == "Dal · made 2 times")
    }

    // MARK: - Week line: dinners cooked per week is the north star

    @Test("the week line counts cooks this week", arguments: [
        (1, "Your first cook this week"),
        (2, "2 cooks this week"),
        (7, "7 cooks this week"),
    ])
    func weekLine(count: Int, expected: String) {
        #expect(MadeItMoment.weekLine(cooksThisWeek: count) == expected)
    }

    @Test("no week line without a cook this week", arguments: [0, -1])
    func noWeekLine(count: Int) {
        #expect(MadeItMoment.weekLine(cooksThisWeek: count) == nil)
    }

    // MARK: - Photo nudge

    @Test("a dish with no cook photo yet asks for one with a reason")
    func firstPhotoIsNudged() {
        let nudge = MadeItMoment.photoNudge(hasCookPhoto: false)
        #expect(nudge == .firstPhoto)
        #expect(nudge.prompt == "Add a photo to remember this one")
    }

    @Test("a dish that already has a cook photo still offers another, quietly")
    func anotherPhotoIsQuiet() {
        let nudge = MadeItMoment.photoNudge(hasCookPhoto: true)
        #expect(nudge == .another)
        #expect(nudge.prompt == nil)
    }

    // MARK: - Motion

    @Test("Reduce Motion keeps the haptic but drops the confetti and the pop")
    func reduceMotion() {
        let motion = MadeItMoment.motion(reduceMotion: true)
        #expect(!motion.firesConfetti)
        #expect(!motion.popsIn)
        #expect(motion.playsHaptic)
    }

    @Test("full motion fires confetti, pops the picture in and plays the haptic")
    func fullMotion() {
        let motion = MadeItMoment.motion(reduceMotion: false)
        #expect(motion.firesConfetti)
        #expect(motion.popsIn)
        #expect(motion.playsHaptic)
    }

    // MARK: - VoiceOver

    @Test("VoiceOver hears the cook number, the dish, the streak and the week")
    func announcementReadsEveryReward() {
        let text = MadeItMoment.announcement(
            cookNumber: 12, recipeName: "Dal", timesCooked: 1, streakWeeks: 3, cooksThisWeek: 2
        )
        #expect(text == "Made it! Cook number 12. First time making Dal! 3-week cooking streak. 2 cooks this week.")
    }

    @Test("the announcement leaves out a streak or week line that isn't there")
    func announcementSkipsMissingRewards() {
        let text = MadeItMoment.announcement(
            cookNumber: 1, recipeName: "Dal", timesCooked: 2, streakWeeks: 0, cooksThisWeek: 0
        )
        #expect(text == "Made it! Cook number 1. Dal · made 2 times.")
    }

    @Test("the streak line reads naturally for one week and many", arguments: [
        (1, "1-week cooking streak"),
        (5, "5-week cooking streak"),
    ])
    func streakLine(weeks: Int, expected: String) {
        #expect(MadeItMoment.streakLine(weeks: weeks) == expected)
    }

    @Test("no streak line without a streak")
    func noStreakLine() {
        #expect(MadeItMoment.streakLine(weeks: 0) == nil)
    }

    // MARK: - Summary built from a cook

    @Test("the summary reads the recipe's own cook count and whether it already has a cook photo")
    func summaryFromRecipe() {
        var recipe = RecipeModel(
            name: "Dal", category: "Main", difficulty: "Easy", prepTime: "10 min", cookingTime: "30 min",
            baseServings: 4, ingredients: [], prePrepInstructions: [], instructions: ["Simmer"], notes: "",
            cookCount: 1, photoNames: []
        )
        let first = MadeItSummary(recipe: recipe, cookNumber: 9, streakWeeks: 2, cooksThisWeek: 3, milestone: nil)
        #expect(first.timesCooked == 1)
        #expect(first.recipeName == "Dal")
        #expect(!first.hasCookPhoto)
        #expect(first.cooksThisWeek == 3)

        recipe.cookCount = 5
        recipe.photoNames = ["RecipeImages/dal.jpg"]
        let again = MadeItSummary(recipe: recipe, cookNumber: 10, streakWeeks: 2, cooksThisWeek: 4, milestone: nil)
        #expect(again.timesCooked == 5)
        #expect(again.hasCookPhoto)
    }
}
