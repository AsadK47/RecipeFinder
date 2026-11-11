import Foundation

/// The time-aware line under Today's Tonight card: what to do about dinner given the time of day.
/// Pure (minutes since midnight in, text out) so the clock rules are testable.
enum TonightTiming {
    /// 7pm — when dinner is assumed to be eaten until the cook picks another time.
    static let defaultEatAt = 19 * 60
    /// What the cook can pick for "Dinner at": 5pm to 10pm on the half hour.
    static let eatTimeChoices = Array(stride(from: 17 * 60, through: 22 * 60, by: 30))
    /// The saved eat time, or 7pm when the stored value isn't one of the choices (first launch, corrupt defaults).
    static func eatAt(stored: Int) -> Int {
        eatTimeChoices.contains(stored) ? stored : defaultEatAt
    }
    private static let eveningStartsAt = 18 * 60
    /// After this, "Quick tonight?" is too late to be useful.
    private static let eveningEndsAt = 22 * 60
    /// Before this it's still night — no "this morning" prep cue at 00:30.
    private static let morningStartsAt = 5 * 60
    private static let noon = 12 * 60

    /// - Morning (5am–noon), tonight's planned dinner needs a head start: "Defrost this morning for tonight".
    /// - Before the start time: "Start by 5:40 to eat at 7" (prep + cook back from `eatAt`).
    /// - Past the start time but before `eatAt`: "Start now to eat by 7:25".
    /// - Evening (6–10pm), unless a planned dinner can still be timed: "Quick tonight? 12 under 30 min".
    /// - A planned lunch/breakfast/snack before evening: nothing (its time isn't dinner's).
    /// Nil when there's nothing useful to say (no time on the recipe, too late, nothing quick).
    static func line(hero: TodayFeed.Hero?, quickCount: Int, minuteOfDay now: Int, eatAt: Int = defaultEatAt) -> String? {
        let isPlannedDinner = hero?.reason == .planned(.dinner)
        let quickLine = quickCount > 0 && now < eveningEndsAt ? "Quick tonight? \(quickCount) under \(TodayFeed.quickLimitMinutes) min" : nil
        let isEvening = now >= eveningStartsAt

        if isEvening, !isPlannedDinner { return quickLine }
        guard let hero else { return nil }
        // "Start by … to eat at 7" is about dinner; a planned lunch or snack isn't counted back from it.
        if case .planned(let meal) = hero.reason, meal != .dinner { return nil }

        if (morningStartsAt..<noon).contains(now), isPlannedDinner, let cue = PrepAhead.cue(for: hero.recipe) {
            return "\(cue) this morning for tonight"
        }
        return startLine(minutes: hero.recipe.totalMinutes, now: now, eatAt: eatAt) ?? (isEvening ? quickLine : nil)
    }

    private static func startLine(minutes: Int, now: Int, eatAt: Int) -> String? {
        guard minutes > 0, minutes <= eatAt, now < eatAt else { return nil }
        let start = eatAt - minutes
        if now <= start {
            return "Start by \(clock(start)) to eat at \(clock(eatAt))"
        }
        return "Start now to eat by \(clock(now + minutes))"
    }

    /// Minutes since midnight for `date`.
    static func minuteOfDay(_ date: Date, calendar: Calendar = .current) -> Int {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    /// Spoken-style 12-hour time: "7" on the hour, else "5:40".
    static func clock(_ minuteOfDay: Int) -> String {
        let wrapped = ((minuteOfDay % 1440) + 1440) % 1440
        let hour = wrapped / 60 % 12 == 0 ? 12 : wrapped / 60 % 12
        let minute = wrapped % 60
        guard minute > 0 else { return "\(hour)" }
        return minute < 10 ? "\(hour):0\(minute)" : "\(hour):\(minute)"
    }
}
