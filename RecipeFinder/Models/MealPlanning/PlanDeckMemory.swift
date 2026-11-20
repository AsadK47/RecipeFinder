import Foundation

/// Dishes passed on in "Plan my week", remembered on this device for 30 days so the next deck deals fresh dishes first
/// (a passed dish still fills a night once the fresh ones run out). Planning a dish forgets its pass. Kept in
/// `LocalStore` (`rf.` key → cleared by Reset, never synced) via `MealPlanningManager`, which also drops expired
/// entries at launch; Privacy Policy §4.2 lists it.
struct PlanDeckMemory: Codable, Equatable {
    static let storageKey = "planDeckPassed"
    static let rememberedDays = 30

    /// When each dish was last passed on.
    private(set) var passedOn: [UUID: Date]

    init(passedOn: [UUID: Date] = [:]) {
        self.passedOn = passedOn
    }

    /// Dishes passed on in the last 30 days. A date in the future (clock set wrong) doesn't count, so it can't pin a
    /// dish to the back of the deck for good.
    func recentlyPassed(at now: Date, calendar: Calendar = .current) -> Set<UUID> {
        Set(passedOn.filter { isRecent($0.value, at: now, calendar: calendar) }.keys)
    }

    /// What one deck did: `passed` were passed on in it (each starts a fresh 30 days), `planned` were planned (their
    /// pass is forgotten, even one made in the same deck). Expired entries are dropped.
    mutating func record(passed: Set<UUID>, planned: Set<UUID>, at now: Date, calendar: Calendar = .current) {
        for id in passed { passedOn[id] = now }
        for id in planned { passedOn[id] = nil }
        passedOn = passedOn.filter { isRecent($0.value, at: now, calendar: calendar) }
    }

    private func isRecent(_ date: Date, at now: Date, calendar: Calendar) -> Bool {
        let cutoff = calendar.date(byAdding: .day, value: -Self.rememberedDays, to: now) ?? now
        return date > cutoff && date <= now
    }

    // MARK: - Stored on the device

    static func load(from storage: LocalStore) -> PlanDeckMemory {
        storage.decodable(PlanDeckMemory.self, forKey: storageKey) ?? PlanDeckMemory()
    }

    func save(to storage: LocalStore) {
        storage.setEncodable(self, forKey: Self.storageKey)
    }

    /// Records passes and plans in the stored memory and drops expired entries; writes only when something changed.
    static func update(
        in storage: LocalStore, passed: Set<UUID>, planned: Set<UUID>, at now: Date, calendar: Calendar = .current
    ) {
        let stored = load(from: storage)
        var memory = stored
        memory.record(passed: passed, planned: planned, at: now, calendar: calendar)
        if memory != stored { memory.save(to: storage) }
    }
}
