import Foundation

/// Today's one "do this now": the most pressing thing to act on before the next meal, so Today shows a single line
/// instead of a prep-ahead row per plan plus a list of items going off (owner 2026-11-20: "slightly cluttered").
enum TodayNudge: Equatable {
    /// Tomorrow's planned meal needs starting tonight (marinate, soak, defrost…).
    case prepAhead(PrepAheadNudge)
    /// Kitchen items going off soon, with a recipe that uses them.
    case useSoon(UseSoonPair)

    /// The one to show, most pressing first: something going off today (it's wasted by tomorrow), then tomorrow's
    /// prep (miss it tonight and the plan the cook made can't happen), then whatever goes off soonest.
    /// Once today's meals are over (`dayIsOver`: Today has moved on to tomorrow) there's no meal left to use today's
    /// item in, but a marinade can still go on, so prep comes first.
    static func pick(prepAhead: [PrepAheadNudge], useSoon: [UseSoonPair], dayIsOver: Bool = false) -> TodayNudge? {
        if !dayIsOver, let today = useSoon.first(where: { $0.daysLeft < 1 }) { return .useSoon(today) }
        if let prep = prepAhead.first { return .prepAhead(prep) }
        return useSoon.first.map(TodayNudge.useSoon)
    }

    var recipe: RecipeModel {
        switch self {
        case .prepAhead(let nudge): nudge.recipe
        case .useSoon(let pair): pair.recipe
        }
    }

    var title: String {
        switch self {
        case .prepAhead: "Prep ahead"
        case .useSoon: "Use it up"
        }
    }

    var message: String {
        switch self {
        case .prepAhead(let nudge): nudge.message
        case .useSoon(let pair): pair.message
        }
    }

    var symbol: String {
        switch self {
        case .prepAhead: "timer"
        case .useSoon: "leaf"
        }
    }

    /// Use it up is built from the kitchen, so it links there (Kitchen you can find, owner 2026-11-17).
    var linksToKitchen: Bool {
        if case .useSoon = self { return true }
        return false
    }
}
