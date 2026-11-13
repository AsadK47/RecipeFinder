import Testing
import Foundation
@testable import RecipeFinder

/// Today's time-aware Tonight line: morning prep, afternoon start-by, evening "start now" or "pick something quicker".
@Suite struct TonightTimingTests {

    private func recipe(prep: String = "10 min", cook: String = "30 min", steps: [String] = ["Cook"]) -> RecipeModel {
        RecipeModel(
            name: "Curry", category: "Main", difficulty: "Basic", prepTime: prep, cookingTime: cook, baseServings: 2,
            ingredients: [], prePrepInstructions: [], instructions: steps, notes: ""
        )
    }

    private func at(_ hour: Int, _ minute: Int = 0) -> Int { hour * 60 + minute }

    private func planned(_ recipe: RecipeModel) -> TodayFeed.Hero { .init(recipe: recipe, reason: .planned(.dinner)) }

    @Test func afternoonCountsBackFromSevenToTheStartTime() {
        // 40 + 40 = 80 min before 7pm.
        let line = TonightTiming.line(hero: planned(recipe(prep: "40 min", cook: "40 min")), minuteOfDay: at(15))
        #expect(line == "Start by 5:40 to eat at 7")
    }

    @Test func pastTheStartTimeSaysStartNowAndWhenItsReady() {
        let line = TonightTiming.line(hero: planned(recipe(prep: "10 min", cook: "1 hr")), minuteOfDay: at(18, 15))
        #expect(line == "Start now to eat by 7:25")
    }

    @Test func eatTimeIsHonoured() {
        let line = TonightTiming.line(hero: planned(recipe()), minuteOfDay: at(14), eatAt: at(20, 30))
        #expect(line == "Start by 7:50 to eat at 8:30")
    }

    @Test func morningPrepCueForTonightsPlannedDinner() {
        let tikka = recipe(steps: ["Marinate the chicken for at least 4 hours.", "Grill."])
        #expect(TonightTiming.line(hero: planned(tikka), minuteOfDay: at(8)) == "Marinate this morning for tonight")
    }

    @Test func morningWithoutPrepFallsBackToTheStartTime() {
        #expect(TonightTiming.line(hero: planned(recipe()), minuteOfDay: at(9)) == "Start by 6:20 to eat at 7")
    }

    @Test func prepCueIsOnlyForAPlannedDinner() {
        let tikka = recipe(steps: ["Marinate overnight."])
        let suggestion = TodayFeed.Hero(recipe: tikka, reason: .quick(minutes: 40))
        #expect(TonightTiming.line(hero: suggestion, minuteOfDay: at(8)) == "Start by 6:20 to eat at 7")
    }

    @Test func eveningWithoutAPlanSaysWhenThisRecipeWouldBeReady() {
        let hero = TodayFeed.Hero(recipe: recipe(), reason: .kitchenMatch(have: 3, total: 4))
        #expect(TonightTiming.line(hero: hero, minuteOfDay: at(19)) == "Start now to eat by 7:40")
        #expect(TonightTiming.line(hero: nil, minuteOfDay: at(20)) == nil)
    }

    @Test func eveningWithALongRecipeSuggestsSomethingQuicker() {
        let hero = TodayFeed.Hero(recipe: recipe(prep: "1 hr", cook: "10 min"), reason: .kitchenMatch(have: 3, total: 4))
        #expect(TonightTiming.line(hero: hero, minuteOfDay: at(19)) == "Takes 1 hr 10 min · Shuffle for something quicker")
    }

    @Test(arguments: [(45, "Start now to eat by 7:45"), (46, "Takes 46 min · Shuffle for something quicker")])
    func eveningQuickLimitIsFortyFiveMinutes(minutes: Int, expected: String) {
        let hero = TodayFeed.Hero(recipe: recipe(prep: "", cook: "\(minutes) min"), reason: .kitchenMatch(have: 1, total: 2))
        #expect(TonightTiming.line(hero: hero, minuteOfDay: at(19)) == expected)
    }

    @Test(arguments: [(45, "45 min"), (60, "1 hr"), (70, "1 hr 10 min"), (125, "2 hr 5 min")])
    func durationReadsNaturally(minutes: Int, expected: String) {
        #expect(TonightTiming.duration(minutes) == expected)
    }

    @Test func eveningStartsAtSixAndEndsAtTen() {
        let hero = TodayFeed.Hero(recipe: recipe(), reason: .kitchenMatch(have: 3, total: 4))
        #expect(TonightTiming.line(hero: hero, minuteOfDay: at(18)) == "Start now to eat by 6:40")
        #expect(TonightTiming.line(hero: hero, minuteOfDay: at(17, 59)) == "Start by 6:20 to eat at 7")
        #expect(TonightTiming.line(hero: hero, minuteOfDay: at(22)) == nil)
    }

    @Test func noMorningPrepCueInTheSmallHours() {
        let tikka = recipe(steps: ["Marinate overnight."])
        #expect(TonightTiming.line(hero: planned(tikka), minuteOfDay: at(0, 30)) == "Start by 6:20 to eat at 7")
        #expect(TonightTiming.line(hero: planned(tikka), minuteOfDay: at(5)) == "Marinate this morning for tonight")
    }

    @Test func eveningWithNothingPickedSaysNothing() {
        #expect(TonightTiming.line(hero: nil, minuteOfDay: at(19)) == nil)
    }

    @Test func eveningWithAPlannedDinnerStillTimesIt() {
        #expect(TonightTiming.line(hero: planned(recipe()), minuteOfDay: at(18, 30)) == "Start now to eat by 7:10")
    }

    @Test func afterEatingTimeAnUncookedPlanSaysWhenItWouldBeReady() {
        #expect(TonightTiming.line(hero: planned(recipe()), minuteOfDay: at(21)) == "Start now to eat by 9:40")
        #expect(TonightTiming.line(hero: planned(recipe(prep: "", cook: "")), minuteOfDay: at(21)) == nil)
    }

    @Test func afterEatingTimeInTheAfternoonSaysNothing() {
        // An early eat time (5pm) has passed before evening starts.
        #expect(TonightTiming.line(hero: planned(recipe()), minuteOfDay: at(17, 30), eatAt: at(17)) == nil)
    }

    @Test func aPlannedLunchIsNotCountedBackFromDinner() {
        let lunch = TodayFeed.Hero(recipe: recipe(), reason: .planned(.lunch))
        #expect(TonightTiming.line(hero: lunch, minuteOfDay: at(10)) == nil)
        #expect(TonightTiming.line(hero: lunch, minuteOfDay: at(19)) == "Start now to eat by 7:40")
    }

    @Test func unknownTimeSaysNothingBeforeEvening() {
        #expect(TonightTiming.line(hero: planned(recipe(prep: "", cook: "")), minuteOfDay: at(15)) == nil)
    }

    @Test func recipeLongerThanTheDaySoFarSaysNothing() {
        #expect(TonightTiming.line(hero: planned(recipe(prep: "1 hr", cook: "20 hours")), minuteOfDay: at(9)) == nil)
    }

    @Test func eatTimeChoicesRunFiveToTenEveryHalfHourAndIncludeSeven() {
        let choices = TonightTiming.eatTimeChoices
        #expect(choices.first == at(17))
        #expect(choices.last == at(22))
        #expect(choices.count == 11)
        #expect(choices.contains(TonightTiming.defaultEatAt))
    }

    @Test(arguments: [(19 * 60, 19 * 60), (20 * 60 + 30, 20 * 60 + 30), (0, 19 * 60), (-5, 19 * 60), (24 * 60, 19 * 60), (19 * 60 + 7, 19 * 60)])
    func storedEatTimeFallsBackToSevenUnlessItsAChoice(stored: Int, expected: Int) {
        #expect(TonightTiming.eatAt(stored: stored) == expected)
    }

    @Test func dinnerTimeIsOfferedForDinnerAndSuggestionsButNotAPlannedLunch() {
        #expect(TonightTiming.asksEatTime(for: planned(recipe())))
        #expect(TonightTiming.asksEatTime(for: .init(recipe: recipe(), reason: .quick(minutes: 20))))
        #expect(TonightTiming.asksEatTime(for: .init(recipe: recipe(), reason: .kitchenMatch(have: 2, total: 3))))
        #expect(!TonightTiming.asksEatTime(for: .init(recipe: recipe(), reason: .planned(.lunch))))
    }

    @Test func aLateDinnerKeepsItsStartLineUntilAnHourBefore() {
        let hero = TodayFeed.Hero(recipe: recipe(), reason: .kitchenMatch(have: 3, total: 4))
        #expect(TonightTiming.line(hero: hero, minuteOfDay: at(18, 30), eatAt: at(21)) == "Start by 8:20 to eat at 9")
        #expect(TonightTiming.line(hero: hero, minuteOfDay: at(20), eatAt: at(21)) == "Start now to eat by 8:40")
    }

    @Test func aLaterEatTimeMovesTheStartTime() {
        let hero = planned(recipe(prep: "40 min", cook: "40 min"))
        let line = TonightTiming.line(hero: hero, minuteOfDay: at(15), eatAt: TonightTiming.eatAt(stored: at(21)))
        #expect(line == "Start by 7:40 to eat at 9")
    }

    @Test(arguments: [(0, "12"), (19 * 60, "7"), (17 * 60 + 40, "5:40"), (12 * 60 + 5, "12:05"), (25 * 60, "1"), (-20, "11:40")])
    func clockReadsLikeSpeech(minute: Int, expected: String) {
        #expect(TonightTiming.clock(minute) == expected)
    }

    @Test func minuteOfDayReadsTheClock() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current
        let date = cal.date(from: DateComponents(year: 2026, month: 11, day: 11, hour: 17, minute: 40)) ?? Date()
        #expect(TonightTiming.minuteOfDay(date, calendar: cal) == 17 * 60 + 40)
    }
}
