import CoreData
import Foundation

/// Re-reads every list after another device's edits land in the store (iCloud sync, Data safety 2/4), so the cook
/// sees them without relaunching. A burst of store changes (an iCloud import arrives in many saves) waits `delay`
/// and reloads once; changes this app made itself reload nothing.
@MainActor
final class RemoteChangeReloader {
    private let delay: Duration
    private let hasOutsideChanges: @MainActor () -> Bool
    private let reloads: [@MainActor () async -> Void]
    private var observer: (any NSObjectProtocol)?
    private var pending: Task<Void, Never>?

    init(
        delay: Duration = .seconds(1),
        hasOutsideChanges: @escaping @MainActor () -> Bool,
        reloads: [@MainActor () async -> Void]
    ) {
        self.delay = delay
        self.hasOutsideChanges = hasOutsideChanges
        self.reloads = reloads
    }

    /// Listens for `store`'s remote-change notifications. They arrive on a background queue, so each hops to the
    /// main actor first. Lives as long as the app; never removed.
    func observe(_ store: NSPersistentStoreCoordinator, in center: NotificationCenter = .default) {
        guard observer == nil else { return }
        observer = center.addObserver(forName: .NSPersistentStoreRemoteChange, object: store, queue: nil) { _ in
            Task { @MainActor in self.storeChanged() }
        }
    }

    func storeChanged() {
        guard pending == nil else { return }
        pending = Task {
            do {
                try await Task.sleep(for: delay)
            } catch {
                pending = nil
                return
            }
            // Cleared before reloading: a change during the reload gets its own pass.
            pending = nil
            guard hasOutsideChanges() else { return }
            for reload in reloads {
                await reload()
            }
        }
    }

    /// Waits for a scheduled reload to finish (tests).
    func waitUntilIdle() async {
        await pending?.value
    }

    var isReloadPending: Bool { pending != nil }
}
