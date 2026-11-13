import CoreData
import Foundation

/// Reloads every list when iCloud brings in another device's changes (Data safety 2/4). The store posts a
/// remote-change notification for every write, so the persistent history decides: only transactions written by
/// CloudKit's importer count — this device's own saves are already on screen, and reloading for them would loop.
@MainActor
final class CloudSyncReloader {
    /// Transaction author `NSPersistentCloudKitContainer` uses when it writes rows fetched from iCloud.
    nonisolated static let importAuthorPrefix = "NSCloudKitMirroringDelegate.import"

    nonisolated static func containsCloudImport(authors: [String?]) -> Bool {
        authors.contains { $0?.hasPrefix(importAuthorPrefix) == true }
    }

    private let container: NSPersistentContainer
    private let settleDelay: Duration
    private let reload: @MainActor () -> Void
    private let logger = AppLogger.logger(category: "CloudSyncReloader")
    /// History before this point is already reflected on screen (launch loaded it).
    private var lastToken: NSPersistentHistoryToken?
    private var observer: (any NSObjectProtocol)?
    private var pendingCheck: Task<Void, Never>?

    /// `settleDelay`: an import arrives as a burst of notifications; wait for it to settle so the lists reload once.
    init(container: NSPersistentContainer, settleDelay: Duration = .milliseconds(500), reload: @escaping @MainActor () -> Void) {
        self.container = container
        self.settleDelay = settleDelay
        self.reload = reload
        lastToken = container.persistentStoreCoordinator.currentPersistentHistoryToken(fromStores: nil)
    }

    func start() {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange, object: container.persistentStoreCoordinator, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.scheduleCheck() }
        }
    }

    func stop() {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        observer = nil
        pendingCheck?.cancel()
        pendingCheck = nil
    }

    private func scheduleCheck() {
        pendingCheck?.cancel()
        let delay = settleDelay
        pendingCheck = Task { [weak self] in
            do {
                try await Task.sleep(for: delay)
            } catch {
                return // superseded by a newer notification
            }
            self?.checkForCloudChanges()
        }
    }

    /// Reads the history written since the last check and reloads once if any of it came from iCloud.
    func checkForCloudChanges() {
        let request = NSPersistentHistoryChangeRequest.fetchHistory(after: lastToken)
        request.resultType = .transactionsOnly
        do {
            let result = try container.viewContext.execute(request) as? NSPersistentHistoryResult
            let transactions = result?.result as? [NSPersistentHistoryTransaction] ?? []
            guard let newest = transactions.last else { return }
            lastToken = newest.token
            if Self.containsCloudImport(authors: transactions.map(\.author)) {
                logger.debug("☁️ iCloud brought in changes — reloading")
                reload()
            }
        } catch {
            logger.error("❌ Reading store history failed: \(error.localizedDescription)")
        }
    }
}
