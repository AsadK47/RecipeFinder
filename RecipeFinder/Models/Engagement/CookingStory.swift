import Foundation

/// One moment on Me's "Your cooking story": a dated line with an icon, newest first.
struct StoryMoment: Identifiable, Equatable {
    enum Kind: Hashable {
        case firstCook
        case meals(Int)
        case streak(weeks: Int)
        case badge(id: String)
    }

    let kind: Kind
    let date: Date
    let title: String
    let detail: String
    let icon: String
    /// The badge's colour name (`Badge.color(for:)`); nil for cook-log moments, which use the theme accent.
    let colorName: String?

    var id: String {
        switch kind {
        case .firstCook: "first-cook"
        case .meals(let count): "meals-\(count)"
        case .streak(let weeks): "streak-\(weeks)"
        case .badge(let id): "badge-\(id)"
        }
    }

    /// The badge a tap opens on the trophy shelf; nil for moments that aren't badges.
    var badgeID: String? {
        if case .badge(let id) = kind { return id }
        return nil
    }
}

/// Me's "Your cooking story": first cook, meal and streak milestones read from the cook log (so they're right even when
/// a badge was earned late, e.g. after a restore), plus every other badge on the day it was earned — first save, first
/// photo, imports. Badges for the same milestones as the cook log are left out so nothing shows twice. Pure, so the
/// timeline is pinned by tests.
enum CookingStory {
    /// The same rungs as the cook-count and streak badges, so the story and the shelf tell one story.
    static let mealMilestones = [10, 25, 50, 100]
    static let streakMilestones = [2, 4, 12, 52]

    /// Badges the cook log already tells as a moment of its own.
    private static let cookLogBadges = Set([
        BadgeType.headChef, .cookedTen, .cookedTwentyFive, .cookedFifty, .cookedHundred,
        .streakTwoWeeks, .streakFourWeeks, .streakTwelveWeeks, .streakFiftyTwoWeeks,
    ].map(\.rawValue))

    /// Newest first. Empty until the first cook — before that the hero and the cookbook carry the invitation.
    static func moments(cookDates: [Date], badges: [Badge], calendar: Calendar = .current) -> [StoryMoment] {
        let cooks = cookDates.sorted()
        guard let first = cooks.first else { return [] }

        var moments = [StoryMoment(kind: .firstCook, date: first, title: "Your first cook",
                                   detail: "Where it all started", icon: "flag.fill", colorName: nil)]
        for milestone in mealMilestones where cooks.count >= milestone {
            moments.append(StoryMoment(kind: .meals(milestone), date: cooks[milestone - 1],
                                       title: "\(milestone) meals cooked", detail: "Meal number \(milestone)",
                                       icon: "fork.knife", colorName: nil))
        }
        moments += streakMoments(cooks: cooks, calendar: calendar)
        for badge in badges where badge.isUnlocked && !cookLogBadges.contains(badge.id) {
            guard let earned = badge.dateEarned else { continue }
            moments.append(StoryMoment(kind: .badge(id: badge.id), date: earned, title: badge.title,
                                       detail: "Badge earned", icon: badge.icon, colorName: badge.color))
        }
        // Newest first; on the same instant keep the order above (first cook, meals, streaks, badges).
        return moments.enumerated()
            .sorted { $0.element.date != $1.element.date ? $0.element.date > $1.element.date : $0.offset < $1.offset }
            .map(\.element)
    }

    /// The cook that first made each streak rung: weeks in a row with at least one cook, counted the way the streak is.
    /// A rung is told once, the first time it's reached, even if a later run reaches it again.
    private static func streakMoments(cooks: [Date], calendar: Calendar) -> [StoryMoment] {
        var moments: [StoryMoment] = []
        var reached = Set<Int>()
        var run = 0
        var lastWeek: Date?
        for cook in cooks {
            let week = calendar.dateInterval(of: .weekOfYear, for: cook)?.start ?? calendar.startOfDay(for: cook)
            if week == lastWeek { continue }
            if let lastWeek, calendar.date(byAdding: .weekOfYear, value: 1, to: lastWeek) == week {
                run += 1
            } else {
                run = 1
            }
            lastWeek = week
            if streakMilestones.contains(run), reached.insert(run).inserted {
                moments.append(StoryMoment(kind: .streak(weeks: run), date: cook, title: "\(run) weeks in a row",
                                           detail: "A cook every week for \(run) weeks", icon: "flame.fill",
                                           colorName: nil))
            }
        }
        return moments
    }

    /// "14 meals cooked in 2026" under the card's title; nil before the first cook of the year.
    static func yearLine(cooksThisYear: Int, now: Date = Date(), calendar: Calendar = .current) -> String? {
        guard cooksThisYear > 0 else { return nil }
        let year = calendar.component(.year, from: now)
        return cooksThisYear == 1 ? "1 meal cooked in \(year)" : "\(cooksThisYear) meals cooked in \(year)"
    }

    /// How many moments the card shows before "Show all".
    static let previewCount = 5
}
