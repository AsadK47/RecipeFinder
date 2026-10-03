import SwiftUI

/// Behavioural seam so views depend on this protocol, not the `CookingStreakManager` singleton, and tests can inject a fake.
@MainActor
protocol CookingStreakTracking: AnyObject, Observable {
    var streak: CookingStreak { get }
    func recordCook(on date: Date)
    func reloadForCurrentUser()
}

extension CookingStreakTracking {
    /// Record a cook at the current moment. (A protocol requirement can't carry a default arg.)
    func recordCookToday() { recordCook(on: Date()) }
}

private struct CookingStreakTrackingKey: EnvironmentKey {
    static var defaultValue: any CookingStreakTracking {
        MainActor.assumeIsolated { CookingStreakManager.shared }
    }
}

extension EnvironmentValues {
    /// Injected cooking-streak tracker; defaults to the shared singleton, override with `.environment(\.cookingStreak, fake)`.
    var cookingStreak: any CookingStreakTracking {
        get { self[CookingStreakTrackingKey.self] }
        set { self[CookingStreakTrackingKey.self] = newValue }
    }
}

/// Owns the per-user cook-date log and derives the weekly cooking streak. Recording is called from the
/// single cook choke point (`RecipeDetailView.recordCook`, which cooking-mode's finish also routes through).
@MainActor
@Observable
final class CookingStreakManager: CookingStreakTracking {
    static let shared = CookingStreakManager()

    private(set) var streak: CookingStreak = .empty

    @ObservationIgnored private let storage: UserScopedStorage
    @ObservationIgnored private let saveKey = "cookDatesLog"
    @ObservationIgnored private var cookDates: [Date] = []

    private init() {
        self.storage = .shared
        load()
    }

    init(storage: UserScopedStorage) {
        self.storage = storage
        load()
    }

    func recordCook(on date: Date = Date()) {
        cookDates.append(date)
        storage.setEncodable(cookDates, forKey: saveKey)
        recompute()
    }

    func reloadForCurrentUser() {
        load()
    }

    private func load() {
        if let data = storage.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Date].self, from: data) {
            cookDates = decoded
        } else {
            cookDates = []
        }
        recompute()
    }

    private func recompute() {
        streak = CookingStreak.compute(cookDates: cookDates)
    }
}
