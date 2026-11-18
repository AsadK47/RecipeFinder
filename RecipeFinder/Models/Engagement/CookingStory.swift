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
/// a badge was earned late, e.g. after a restore), plus the other badges on the day they were earned — first save, first
/// photo, imports. A cook or streak badge is left out only when the log tells that same milestone, so nothing shows
/// twice and nothing earned goes untold. Badges earned on one day (an import or restore unlocks several at once) fold
/// into one line, so they don't push the cooking out of the preview. Pure, so the timeline is pinned by tests.
enum CookingStory {
    /// The same rungs as the cook-count and streak badges, so the story and the shelf tell one story.
    static let mealMilestones = [10, 25, 50, 100]
    static let streakMilestones = [2, 4, 12, 52]

    /// The moment the cook log tells instead of each cook or streak badge.
    private static let cookLogBadges: [String: StoryMoment.Kind] = [
        BadgeType.headChef.rawValue: .firstCook,
        BadgeType.cookedTen.rawValue: .meals(10),
        BadgeType.cookedTwentyFive.rawValue: .meals(25),
        BadgeType.cookedFifty.rawValue: .meals(50),
        BadgeType.cookedHundred.rawValue: .meals(100),
        BadgeType.streakTwoWeeks.rawValue: .streak(weeks: 2),
        BadgeType.streakFourWeeks.rawValue: .streak(weeks: 4),
        BadgeType.streakTwelveWeeks.rawValue: .streak(weeks: 12),
        BadgeType.streakFiftyTwoWeeks.rawValue: .streak(weeks: 52),
    ]

    /// Newest first. Empty until the first cook — before that the hero and the cookbook carry the invitation. Cooks
    /// after `now` (another device's wrong clock) are left out, as the streak leaves them out.
    static func moments(cookDates: [Date], badges: [Badge], now: Date = Date(),
                        calendar: Calendar = .current) -> [StoryMoment] {
        let cooks = cookDates.filter { $0 <= now }.sorted()
        guard let first = cooks.first else { return [] }

        var moments = [StoryMoment(kind: .firstCook, date: first, title: "Your first cook",
                                   detail: "Your first meal cooked", icon: "flag.fill", colorName: nil)]
        for milestone in mealMilestones where cooks.count >= milestone {
            moments.append(StoryMoment(kind: .meals(milestone), date: cooks[milestone - 1],
                                       title: "\(milestone) meals cooked", detail: "Meal number \(milestone)",
                                       icon: "fork.knife", colorName: nil))
        }
        moments += streakMoments(cooks: cooks, calendar: calendar)
        let told = Set(moments.map(\.kind))
        let earned = badges.filter { badge in
            guard badge.isUnlocked, badge.dateEarned != nil else { return false }
            guard let kind = cookLogBadges[badge.id] else { return true }
            return !told.contains(kind)
        }
        moments += badgeMoments(earned, calendar: calendar)
        // Newest first; on the same instant keep the order above (first cook, meals, streaks, badges).
        return moments.enumerated()
            .sorted { $0.element.date != $1.element.date ? $0.element.date > $1.element.date : $0.offset < $1.offset }
            .map(\.element)
    }

    /// One line per badge, or one line per day when several were earned that day ("3 badges earned"), opening the
    /// day's newest badge.
    private static func badgeMoments(_ badges: [Badge], calendar: Calendar) -> [StoryMoment] {
        let byDay = Dictionary(grouping: badges) { calendar.startOfDay(for: $0.dateEarned ?? .distantPast) }
        return byDay.values.compactMap { group in
            let ordered = group.sorted {
                let (lhs, rhs) = ($0.dateEarned ?? .distantPast, $1.dateEarned ?? .distantPast)
                return lhs != rhs ? lhs > rhs : $0.id < $1.id
            }
            guard let newest = ordered.first, let date = newest.dateEarned else { return nil }
            if ordered.count == 1 {
                return StoryMoment(kind: .badge(id: newest.id), date: date, title: newest.title,
                                   detail: "Badge earned", icon: newest.icon, colorName: newest.color)
            }
            return StoryMoment(kind: .badge(id: newest.id), date: date, title: "\(ordered.count) badges earned",
                               detail: ordered.map(\.title).joined(separator: ", "), icon: "medal.fill",
                               colorName: newest.color)
        }
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
