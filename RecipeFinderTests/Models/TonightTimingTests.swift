import Testing
import Foundation
@testable import RecipeFinder

/// Today's time-aware Tonight line: morning prep, afternoon start-by, evening quick ideas.
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
        let line = TonightTiming.line(hero: planned(recipe(prep: "40 min", cook: "40 min")), quickCount: 3, minuteOfDay: at(15))
        #expect(line == "Start by 5:40 to eat at 7")
    }

    @Test func pastTheStartTimeSaysStartNowAndWhenItsReady() {
        let line = TonightTiming.line(hero: planned(recipe(prep: "10 min", cook: "1 hr")), quickCount: 0, minuteOfDay: at(18, 15))
        #expect(line == "Start now to eat by 7:25")
    }

    @Test func eatTimeIsHonoured() {
        let line = TonightTiming.line(hero: planned(recipe()), quickCount: 0, minuteOfDay: at(14), eatAt: at(20, 30))
        #expect(line == "Start by 7:50 to eat at 8:30")
    }

    @Test func morningPrepCueForTonightsPlannedDinner() {
        let tikka = recipe(steps: ["Marinate the chicken for at least 4 hours.", "Grill."])
        #expect(TonightTiming.line(hero: planned(tikka), quickCount: 0, minuteOfDay: at(8)) == "Marinate this morning for tonight")
    }

    @Test func morningWithoutPrepFallsBackToTheStartTime() {
        #expect(TonightTiming.line(hero: planned(recipe()), quickCount: 0, minuteOfDay: at(9)) == "Start by 6:20 to eat at 7")
    }

    @Test func prepCueIsOnlyForAPlannedDinner() {
        let tikka = recipe(steps: ["Marinate overnight."])
        let suggestion = TodayFeed.Hero(recipe: tikka, reason: .quick(minutes: 40))
        #expect(TonightTiming.line(hero: suggestion, quickCount: 0, minuteOfDay: at(8)) == "Start by 6:20 to eat at 7")
    }

    @Test func eveningWithoutAPlanOffersQuickIdeas() {
        let hero = TodayFeed.Hero(recipe: recipe(), reason: .kitchenMatch(have: 3, total: 4))
        #expect(TonightTiming.line(hero: hero, quickCount: 12, minuteOfDay: at(19)) == "Quick tonight? 12 under 30 min")
        #expect(TonightTiming.line(hero: nil, quickCount: 2, minuteOfDay: at(20)) == "Quick tonight? 2 under 30 min")
    }

    @Test func eveningStartsAtSixAndEndsAtTen() {
        let hero = TodayFeed.Hero(recipe: recipe(), reason: .kitchenMatch(have: 3, total: 4))
        #expect(TonightTiming.line(hero: hero, quickCount: 2, minuteOfDay: at(18)) == "Quick tonight? 2 under 30 min")
        #expect(TonightTiming.line(hero: hero, quickCount: 2, minuteOfDay: at(17, 59)) == "Start by 6:20 to eat at 7")
        #expect(TonightTiming.line(hero: hero, quickCount: 2, minuteOfDay: at(22)) == nil)
    }

    @Test func noMorningPrepCueInTheSmallHours() {
        let tikka = recipe(steps: ["Marinate overnight."])
        #expect(TonightTiming.line(hero: planned(tikka), quickCount: 0, minuteOfDay: at(0, 30)) == "Start by 6:20 to eat at 7")
        #expect(TonightTiming.line(hero: planned(tikka), quickCount: 0, minuteOfDay: at(5)) == "Marinate this morning for tonight")
    }

    @Test func eveningWithNothingQuickSaysNothing() {
        #expect(TonightTiming.line(hero: nil, quickCount: 0, minuteOfDay: at(19)) == nil)
    }

    @Test func eveningWithAPlannedDinnerStillTimesIt() {
        #expect(TonightTiming.line(hero: planned(recipe()), quickCount: 5, minuteOfDay: at(18, 30)) == "Start now to eat by 7:10")
    }

    @Test func afterEatingTimeAnUncookedPlanTurnsToQuickIdeas() {
        #expect(TonightTiming.line(hero: planned(recipe()), quickCount: 5, minuteOfDay: at(21)) == "Quick tonight? 5 under 30 min")
        #expect(TonightTiming.line(hero: planned(recipe()), quickCount: 0, minuteOfDay: at(21)) == nil)
    }

    @Test func afterEatingTimeInTheAfternoonSaysNothing() {
        // An early eat time (5pm) has passed before evening starts.
        #expect(TonightTiming.line(hero: planned(recipe()), quickCount: 5, minuteOfDay: at(17, 30), eatAt: at(17)) == nil)
    }

    @Test func aPlannedLunchIsNotCountedBackFromDinner() {
        let lunch = TodayFeed.Hero(recipe: recipe(), reason: .planned(.lunch))
        #expect(TonightTiming.line(hero: lunch, quickCount: 4, minuteOfDay: at(10)) == nil)
        #expect(TonightTiming.line(hero: lunch, quickCount: 4, minuteOfDay: at(19)) == "Quick tonight? 4 under 30 min")
    }

    @Test func unknownTimeSaysNothingBeforeEvening() {
        #expect(TonightTiming.line(hero: planned(recipe(prep: "", cook: "")), quickCount: 4, minuteOfDay: at(15)) == nil)
    }

    @Test func recipeLongerThanTheDaySoFarSaysNothing() {
        #expect(TonightTiming.line(hero: planned(recipe(prep: "1 hr", cook: "20 hours")), quickCount: 0, minuteOfDay: at(9)) == nil)
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
