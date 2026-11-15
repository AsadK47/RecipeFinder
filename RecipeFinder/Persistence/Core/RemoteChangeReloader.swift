import CoreData
import Foundation

private let diagnosticsLogger = AppLogger.logger(category: "Diagnostics")

/// Re-reads every list after another device's edits land in the store (iCloud sync, Data safety 2/4), so the cook
/// sees them without relaunching. A burst of store changes (an iCloud import arrives in many saves) waits `delay`
/// and reloads once; changes this app made itself reload nothing. The check is async so reading the store's history
/// never holds the main thread (a first iCloud import is thousands of transactions; issue #16). Passes run one after
/// another; a step slower than `slowStep` is reported by name, so a freeze says which list held the main thread.
@MainActor
final class RemoteChangeReloader {
    /// One list's re-read; `name` is what a slow-step report says (never anything the cook entered).
    struct Reload {
        let name: String
        let run: @MainActor () async -> Void
    }

    static let slowStep: Duration = .milliseconds(100)

    private let delay: Duration
    private let hasOutsideChanges: @MainActor () async -> Bool
    private let reloads: [Reload]
    private let reportSlowStep: @MainActor (_ name: String, _ took: Duration) -> Void
    private var observer: (any NSObjectProtocol)?
    /// True from a store change until its pass checks for outside changes: more changes meanwhile join that pass.
    private var isScheduled = false
    /// The latest pass, kept until the next one replaces it so `waitUntilIdle` can wait for all of it.
    private var latestPass: Task<Void, Never>?

    init(
        delay: Duration = .seconds(1),
        hasOutsideChanges: @escaping @MainActor () async -> Bool,
        reloads: [Reload],
        reportSlowStep: @escaping @MainActor (_ name: String, _ took: Duration) -> Void = { name, took in
            diagnosticsLogger.error("⚠️ Slow iCloud reload step \(name, privacy: .public): \(Int(took / .milliseconds(1))) ms")
        }
    ) {
        self.delay = delay
        self.hasOutsideChanges = hasOutsideChanges
        self.reloads = reloads
        self.reportSlowStep = reportSlowStep
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
        guard !isScheduled else { return }
        isScheduled = true
        let previous = latestPass
        latestPass = Task {
            await previous?.value
            do {
                try await Task.sleep(for: delay)
            } catch {
                isScheduled = false
                return
            }
            // Cleared before checking: a change during the check or the reloads gets its own pass.
            isScheduled = false
            guard await timed("outside-change check", hasOutsideChanges) else { return }
            for reload in reloads {
                await timed(reload.name, reload.run)
            }
        }
    }

    private func timed<T>(_ name: String, _ step: @MainActor () async -> T) async -> T {
        let clock = ContinuousClock()
        let start = clock.now
        let result = await step()
        let took = clock.now - start
        if took > Self.slowStep { reportSlowStep(name, took) }
        return result
    }

    /// Waits until every scheduled pass, its check and its reloads have finished (tests).
    func waitUntilIdle() async {
        while let pass = latestPass {
            await pass.value
            if latestPass == pass, !isScheduled { return }
        }
    }

    var isReloadPending: Bool { isScheduled }
}
