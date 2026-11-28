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
    /// Whether the card offers "Dinner at": a planned dinner tonight, or a suggestion while the next meal is tonight's
    /// dinner — not a planned lunch/breakfast/snack, tomorrow's plans or a breakfast/lunch idea (not counted from dinner).
    static func asksEatTime(for hero: TodayFeed.Hero, forDinner: Bool = true) -> Bool {
        switch hero.reason {
        case .planned(let meal): meal == .dinner
        case .plannedTomorrow: false
        case .kitchenMatch, .quick, .longer: forDinner
        }
    }
    private static let eveningStartsAt = 18 * 60
    /// After this, an evening line is too late to be useful.
    private static let eveningEndsAt = 22 * 60
    /// Before this it's still night — no "this morning" prep cue at 00:30.
    private static let morningStartsAt = 5 * 60
    private static let noon = 12 * 60

    /// - Morning (5am–noon), tonight's planned dinner needs a head start: "Defrost this morning for tonight".
    /// - Before the start time: "Start by 5:40 to eat at 7" (prep + cook back from `eatAt`).
    /// - Past the start time but before `eatAt`: "Start now to eat by 7:25".
    /// - Evening (6–10pm, or from an hour before a later `eatAt`), unless a planned dinner can still be timed: about
    ///   *this* recipe — "Start now to eat by 7:40", or for a long one "Takes 1 hr 10 min" (Shuffle sits beside it).
    ///   (A library-wide count like "12 under 30 min" read as gibberish to the owner — it named nothing to act on.)
    /// - A planned lunch/breakfast/snack before evening: nothing (its time isn't dinner's).
    /// - `forDinner` false (the next meal is breakfast, lunch or tomorrow): only a planned dinner tonight gets a line.
    /// Nil when there's nothing useful to say (no time on the recipe, too late, nothing quick).
    static func line(
        hero: TodayFeed.Hero?, minuteOfDay now: Int, eatAt: Int = defaultEatAt, forDinner: Bool = true
    ) -> String? {
        let isPlannedDinner = hero?.reason == .planned(.dinner)
        if !forDinner, !isPlannedDinner { return nil }
        let quickLine = hero.flatMap { eveningLine(minutes: $0.recipe.totalMinutes, now: now) }
        // A late dinner (9pm) keeps its "Start by" line past 6pm: quick ideas start an hour before eating at the earliest.
        let isEvening = now >= max(eveningStartsAt, eatAt - 60)

        if isEvening, !isPlannedDinner { return quickLine }
        guard let hero else { return nil }
        // "Start by … to eat at 7" is about dinner; a planned lunch or snack isn't counted back from it.
        if case .planned(let meal) = hero.reason, meal != .dinner { return nil }
        if case .plannedTomorrow = hero.reason { return nil }

        if (morningStartsAt..<noon).contains(now), isPlannedDinner, let cue = PrepAhead.cue(for: hero.recipe) {
            return "\(cue) this morning for tonight"
        }
        return startLine(minutes: hero.recipe.totalMinutes, now: now, eatAt: eatAt) ?? (isEvening ? quickLine : nil)
    }

    /// Longest recipe that still reads as "start now" in the evening; longer ones suggest a quicker pick.
    static let eveningQuickLimit = 45

    private static func eveningLine(minutes: Int, now: Int) -> String? {
        guard minutes > 0, now < eveningEndsAt else { return nil }
        if minutes <= eveningQuickLimit { return "Start now to eat by \(clock(now + minutes))" }
        return "Takes \(duration(minutes))"
    }

    /// The hero card's two timing texts. `menu` labels the eat-time Menu: the timing line itself when it names the eat
    /// time ("Start by 6 to eat at 7", the choice it changes), else "Dinner at 7 pm" so the control never vanishes.
    /// `note` is a line the eat time doesn't name ("Takes 1 hr", "Defrost this morning…"), shown as plain text:
    /// a Menu on a line it doesn't change confused the 2026-11-11 fold (docs/DECISIONS.md, Today+ 1/3 slice 2).
    struct HeroLines: Equatable {
        let note: String?
        let menu: String?
    }

    static func heroLines(timing: String?, asksEatTime: Bool, eatAt: Int) -> HeroLines {
        guard asksEatTime else { return HeroLines(note: timing, menu: nil) }
        if let timing, timing.hasSuffix("to eat at \(clock(eatAt))") { return HeroLines(note: nil, menu: timing) }
        return HeroLines(note: timing, menu: "Dinner at \(clock(eatAt)) pm")
    }

    /// "45 min", "1 hr", "1 hr 10 min".
    static func duration(_ minutes: Int) -> String {
        let hours = minutes / 60, rest = minutes % 60
        if hours == 0 { return "\(rest) min" }
        return rest == 0 ? "\(hours) hr" : "\(hours) hr \(rest) min"
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
