import Foundation

/// Several named kitchen timers at once ("Rice 12:00", "Sauce 4:30") that outlive the step that started them.
/// A pure value: time is passed in, so every rule here is unit-tested without waiting on a clock.
struct CookingTimerBoard: Equatable {
    struct Timer: Identifiable, Equatable {
        let id: UUID
        let name: String
        /// The step that started it, so that step's button can't start a second copy.
        let key: String?
        /// When it goes off; nil while paused.
        var endDate: Date?
        /// Seconds left at the moment it was paused.
        var pausedRemaining: Int

        var isPaused: Bool { endDate == nil }

        func remaining(at now: Date) -> Int {
            guard let endDate else { return pausedRemaining }
            return max(0, Int(ceil(endDate.timeIntervalSince(now))))
        }

        func isDone(at now: Date) -> Bool { remaining(at: now) == 0 }
    }

    private(set) var timers: [Timer] = []

    /// Starts a timer, or returns the one `key` already has. Nil for a non-positive length.
    @discardableResult
    mutating func start(name: String, seconds: Int, key: String?, now: Date, id: UUID = UUID()) -> Timer? {
        if let key, let existing = timer(forKey: key) { return existing }
        guard seconds > 0 else { return nil }
        let timer = Timer(id: id, name: name, key: key, endDate: now.addingTimeInterval(TimeInterval(seconds)), pausedRemaining: 0)
        timers.append(timer)
        return timer
    }

    func timer(forKey key: String) -> Timer? {
        timers.first { $0.key == key }
    }

    func timer(_ id: UUID) -> Timer? {
        timers.first { $0.id == id }
    }

    /// Pauses a running timer or resumes a paused one; a finished timer stays finished. Returns the new state.
    @discardableResult
    mutating func togglePause(_ id: UUID, now: Date) -> Timer? {
        guard let i = timers.firstIndex(where: { $0.id == id }) else { return nil }
        var timer = timers[i]
        let left = timer.remaining(at: now)
        guard left > 0 else { return timer }
        if timer.isPaused {
            timer.endDate = now.addingTimeInterval(TimeInterval(left))
            timer.pausedRemaining = 0
        } else {
            timer.endDate = nil
            timer.pausedRemaining = left
        }
        timers[i] = timer
        return timer
    }

    /// Adds time to a timer; a finished one counts on again from now ("+1 min" when the rice needs a bit longer).
    @discardableResult
    mutating func add(seconds: Int, to id: UUID, now: Date) -> Timer? {
        guard seconds > 0, let i = timers.firstIndex(where: { $0.id == id }) else { return nil }
        var timer = timers[i]
        let left = timer.remaining(at: now) + seconds
        if timer.isPaused {
            timer.pausedRemaining = left
        } else {
            timer.endDate = now.addingTimeInterval(TimeInterval(left))
        }
        timers[i] = timer
        return timer
    }

    mutating func remove(_ id: UUID) {
        timers.removeAll { $0.id == id }
    }

    /// "12:00", "0:45", "1:05:00" — minutes and seconds, hours only when there are some.
    static func clock(seconds: Int) -> String {
        let s = max(0, seconds)
        let hours = s / 3600, minutes = (s % 3600) / 60, secs = s % 60
        let tail = String(format: "%02d", secs)
        return hours > 0 ? "\(hours):\(String(format: "%02d", minutes)):\(tail)" : "\(minutes):\(tail)"
    }

    /// What VoiceOver reads: "12 minutes 5 seconds".
    static func spoken(seconds: Int) -> String {
        let s = max(0, seconds)
        let hours = s / 3600, minutes = (s % 3600) / 60, secs = s % 60
        var parts: [String] = []
        if hours > 0 { parts.append(hours == 1 ? "1 hour" : "\(hours) hours") }
        if minutes > 0 { parts.append(minutes == 1 ? "1 minute" : "\(minutes) minutes") }
        if secs > 0 || parts.isEmpty { parts.append(secs == 1 ? "1 second" : "\(secs) seconds") }
        return parts.joined(separator: " ")
    }
}

/// Names a step's timer after what it's timing: the ingredient the step mentions first ("Rice"), else the step
/// itself ("Step 4"), so several timers on screen can be told apart at a glance.
enum CookingTimerName {
    static func name(for stepText: String, uses: [StepIngredientMatcher.Use], ingredients: [Ingredient], fallback: String) -> String {
        let text = stepText.lowercased()
        let named: [(position: Int, name: String)] = uses.compactMap { use in
            guard ingredients.indices.contains(use.index) else { return nil }
            let name = short(ingredients[use.index].displayParts.name)
            guard !name.isEmpty else { return nil }
            return (position(of: name.lowercased(), in: text) ?? Int.max, name)
        }
        guard let first = named.min(by: { $0.position < $1.position }) else { return fallback }
        return first.name.prefix(1).uppercased() + first.name.dropFirst()
    }

    /// Two words at most, from the end — "Light soy sauce" → "soy sauce" — so a pill stays short.
    private static func short(_ name: String) -> String {
        let cleaned = name.replacingOccurrences(of: #"\s*\(.*?\)"#, with: "", options: .regularExpression)
        let words = cleaned.split(whereSeparator: \.isWhitespace)
        return words.suffix(2).joined(separator: " ")
    }

    /// Where the step mentions the name: the whole name, else its last word, else that word without a plural "s".
    private static func position(of name: String, in text: String) -> Int? {
        var candidates = [name]
        if let last = name.split(separator: " ").last.map(String.init) {
            candidates.append(last)
            if last.count > 3, last.hasSuffix("s") { candidates.append(String(last.dropLast())) }
        }
        for candidate in candidates {
            if let range = text.range(of: candidate) {
                return text.distance(from: text.startIndex, to: range.lowerBound)
            }
        }
        return nil
    }
}
