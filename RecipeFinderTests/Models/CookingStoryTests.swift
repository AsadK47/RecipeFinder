import Foundation
import Testing
@testable import RecipeFinder

/// Me's "Your cooking story": which moments the timeline tells, when, and in what order.
@Suite("CookingStory")
struct CookingStoryTests {

    /// Fixed Gregorian calendar, Monday weeks, UTC — so week maths doesn't depend on the test machine.
    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC") ?? .current
        c.firstWeekday = 2
        return c
    }()

    /// Monday 2 Nov 2026, noon UTC, plus `weeks` and `days`.
    private func day(weeks: Int = 0, days: Int = 0) -> Date {
        let start = Date(timeIntervalSince1970: 1_793_620_800)   // 2026-11-02T12:00:00Z (a Monday)
        return start.addingTimeInterval(TimeInterval((weeks * 7 + days) * 86_400))
    }

    private func badge(_ type: BadgeType, earned: Date?) -> Badge {
        Badge(id: type.rawValue, title: "Title \(type.rawValue)", description: "", icon: "star.fill", color: "blue",
              dateEarned: earned, isUnlocked: earned != nil)
    }

    private func moments(_ cooks: [Date], badges: [Badge] = []) -> [StoryMoment] {
        CookingStory.moments(cookDates: cooks, badges: badges, calendar: calendar)
    }

    private func kinds(_ moments: [StoryMoment]) -> [StoryMoment.Kind] { moments.map(\.kind) }

    @Test("the fixture's start date is a Monday")
    func fixtureIsMonday() {
        #expect(calendar.component(.weekday, from: day()) == 2)
    }

    @Test("no cooks yet → no story, even with badges earned")
    func emptyBeforeFirstCook() {
        #expect(moments([], badges: [badge(.welcomeAboard, earned: day())]).isEmpty)
    }

    @Test("the first cook is dated by the earliest cook, whatever the log's order")
    func firstCookIsEarliest() {
        let story = moments([day(days: 3), day(), day(days: 1)])
        let first = story.first { $0.kind == .firstCook }
        #expect(first?.date == day())
        #expect(first?.title == "Your first cook")
    }

    @Test("meal milestones land on the cook that reached them", arguments: [9, 10, 24, 25, 100])
    func mealMilestones(count: Int) {
        let cooks = (0..<count).map { day(days: $0) }
        let story = moments(cooks)
        for milestone in CookingStory.mealMilestones {
            let moment = story.first { $0.kind == .meals(milestone) }
            if count >= milestone {
                #expect(moment?.date == day(days: milestone - 1))
                #expect(moment?.title == "\(milestone) meals cooked")
            } else {
                #expect(moment == nil)
            }
        }
    }

    @Test("two cooks in one week are one week of streak")
    func sameWeekIsOneWeek() {
        let story = moments([day(), day(days: 2)])
        #expect(!kinds(story).contains(.streak(weeks: 2)))
    }

    @Test("a streak rung lands on the first cook of the week that reached it")
    func streakRungDate() {
        let story = moments([day(), day(weeks: 1, days: 4), day(weeks: 1, days: 5)])
        #expect(story.first { $0.kind == .streak(weeks: 2) }?.date == day(weeks: 1, days: 4))
    }

    @Test("a gap week restarts the count")
    func gapRestarts() {
        let story = moments([day(), day(weeks: 2), day(weeks: 3)])
        let streaks = story.filter { if case .streak = $0.kind { true } else { false } }
        #expect(streaks.map(\.date) == [day(weeks: 3)])
    }

    @Test("four weeks in a row tells 2 and 4 weeks; reaching 2 again later isn't told twice")
    func streakRungsOnce() {
        let cooks = (0..<4).map { day(weeks: $0) } + [day(weeks: 6), day(weeks: 7)]
        let streaks = moments(cooks).filter { if case .streak = $0.kind { true } else { false } }
        #expect(Set(kinds(streaks)) == [.streak(weeks: 2), .streak(weeks: 4)])
        #expect(streaks.count == 2)
    }

    @Test("other badges show on the day they were earned")
    func badgesShow() {
        let story = moments([day(weeks: 1)], badges: [badge(.firstRecipe, earned: day()),
                                                      badge(.firstCookPhoto, earned: day(weeks: 2))])
        #expect(kinds(story).contains(.badge(id: BadgeType.firstRecipe.rawValue)))
        #expect(story.first { $0.badgeID == BadgeType.firstCookPhoto.rawValue }?.date == day(weeks: 2))
    }

    @Test("locked or undated badges aren't told")
    func lockedBadgesHidden() {
        let undated = Badge(id: BadgeType.ratedTen.rawValue, title: "Critic", description: "", icon: "star", color: "blue",
                            dateEarned: nil, isUnlocked: true)
        let story = moments([day()], badges: [badge(.firstImport, earned: nil), undated])
        #expect(story.allSatisfy { $0.badgeID == nil })
    }

    @Test("cook and streak badges aren't told twice — the cook log tells them", arguments: [
        BadgeType.headChef, .cookedTen, .cookedHundred, .streakTwoWeeks, .streakFiftyTwoWeeks,
    ])
    func cookLogBadgesSkipped(type: BadgeType) {
        #expect(moments([day()], badges: [badge(type, earned: day())]).allSatisfy { $0.badgeID == nil })
    }

    @Test("newest first; at the same moment the first cook comes before its badge-free milestones")
    func order() {
        let story = moments([day(), day(weeks: 1)], badges: [badge(.firstRecipe, earned: day(weeks: 3))])
        #expect(kinds(story) == [.badge(id: BadgeType.firstRecipe.rawValue), .streak(weeks: 2), .firstCook])
    }

    @Test("a single cook is both the first cook and nothing else")
    func singleCook() {
        #expect(kinds(moments([day()])) == [.firstCook])
    }

    @Test("ids are unique across a long story")
    func uniqueIDs() {
        let cooks = (0..<60).map { day(weeks: $0) }
        let story = moments(cooks, badges: [badge(.firstRecipe, earned: day())])
        #expect(Set(story.map(\.id)).count == story.count)
    }

    @Test("the year line counts this year's cooks; zero → none", arguments: [
        (0, nil), (1, "1 meal cooked in 2026"), (14, "14 meals cooked in 2026"),
    ] as [(Int, String?)])
    func yearLine(cooks: Int, expected: String?) {
        #expect(CookingStory.yearLine(cooksThisYear: cooks, now: day(), calendar: calendar) == expected)
    }
}
