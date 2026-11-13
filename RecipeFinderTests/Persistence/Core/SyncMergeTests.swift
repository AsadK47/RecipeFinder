import Testing
import Foundation
@testable import RecipeFinder

private struct Row: Codable, Equatable {
    var id: Int
    var text: String
}

private func row(_ id: Int, _ text: String = "") -> Row { Row(id: id, text: text.isEmpty ? "v\(id)" : text) }

/// The merge rules a synced list uses (Data safety 2/4): this device's edits on top of what the store holds now.
@Suite struct SyncMergeTests {
    private func apply(base: [Row], local: [Row], store: [Row]) -> [Row] {
        SyncMerge.applyEdits(base: base, local: local, store: store, id: \.id)
    }

    @Test func aRowAnotherDeviceAddedIsKept() {
        let merged = apply(base: [row(1)], local: [row(1), row(2)], store: [row(1), row(9)])
        #expect(merged == [row(1), row(2), row(9)])
    }

    @Test func aRowDeletedHereIsDeleted() {
        let merged = apply(base: [row(1), row(2)], local: [row(1)], store: [row(1), row(2), row(9)])
        #expect(merged == [row(1), row(9)])
    }

    @Test func aRowEditedHereWins() {
        let merged = apply(base: [row(1)], local: [row(1, "mine")], store: [row(1, "theirs")])
        #expect(merged == [row(1, "mine")])
    }

    @Test func aRowLeftUnchangedHereTakesTheOtherDevicesEdit() {
        let merged = apply(base: [row(1), row(2)], local: [row(1), row(2, "mine")], store: [row(1, "theirs"), row(2)])
        #expect(merged == [row(1, "theirs"), row(2, "mine")])
    }

    @Test func aRowDeletedElsewhereButEditedHereComesBack() {
        let merged = apply(base: [row(1)], local: [row(1, "mine")], store: [])
        #expect(merged == [row(1, "mine")])
    }

    @Test func aRowDeletedElsewhereAndUnchangedHereStaysDeleted() {
        let merged = apply(base: [row(1), row(2)], local: [row(1), row(2)], store: [row(2)])
        #expect(merged == [row(2)])
    }

    @Test func thisDevicesOrderComesFirst() {
        let merged = apply(base: [row(1), row(2)], local: [row(2), row(1)], store: [row(1), row(2)])
        #expect(merged == [row(2), row(1)])
    }

    @Test func duplicateIdsKeepTheFirstRow() {
        let merged = apply(base: [], local: [row(1, "a"), row(1, "b")], store: [row(1, "c"), row(3), row(3, "x")])
        #expect(merged == [row(1, "a"), row(3)])
    }

    @Test func addingAKeptCopyNeverDeletesStoreRows() {
        let merged = SyncMerge.addKeptCopy([row(1, "mine"), row(2)], to: [row(1, "theirs"), row(9)], id: \.id)
        #expect(merged == [row(1, "mine"), row(2), row(9)])
    }
}

/// `MirroredSnapshot` with sync rules on: the store wins and is never replaced wholesale.
@MainActor
@Suite struct MirroredSnapshotSyncTests {
    private let blobKey = "syncTestRows"
    private let storage = LocalStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)

    @MainActor
    private final class Store {
        var rows: [Row] = []
        var failReads = false
        var failWrites = false
    }

    private let store = Store()

    private func snapshot(syncOn: Bool = true) -> MirroredSnapshot<Row> {
        let store = store
        return MirroredSnapshot(
            blobKey: blobKey,
            storage: storage,
            fetch: {
                if store.failReads { throw MirroredSnapshotError.verificationFailed }
                return store.rows
            },
            replace: {
                if store.failWrites { throw MirroredSnapshotError.verificationFailed }
                store.rows = $0
            },
            sync: .init(isOn: { syncOn }, id: { AnyHashable($0.id) })
        )
    }

    private func keptCopy() -> [Row]? { storage.decodable([Row].self, forKey: blobKey) }
    private func writeKeptCopy(_ rows: [Row]) { storage.setEncodable(rows, forKey: blobKey) }

    @Test func firstMoveOnASecondDeviceAddsItsRowsAndKeepsTheFirstDevices() {
        store.rows = [row(1), row(9)]          // synced from the other device
        writeKeptCopy([row(1, "mine"), row(2)])
        let loaded = snapshot().load()
        #expect(loaded == [row(1, "mine"), row(2), row(9)])
        #expect(store.rows == loaded)
        #expect(keptCopy() == loaded)
        #expect(storage.bool(forKey: MirroredSnapshot<Row>.flagKey(for: blobKey)))
    }

    @Test func aStoreNewerThanTheKeptCopyWinsAndTheCopyFollows() {
        let first = snapshot()
        _ = first.load()
        first.save([row(1)])
        store.rows = [row(1), row(9)]          // another device added a row
        let loaded = snapshot().load()
        #expect(loaded == [row(1), row(9)])
        #expect(keptCopy() == [row(1), row(9)])
    }

    @Test func aSaveKeepsRowsAnotherDeviceAddedWhileTheAppWasOpen() {
        let sut = snapshot()
        _ = sut.load()
        sut.save([row(1)])
        store.rows.append(row(9))              // arrives from iCloud mid-session
        sut.save([row(1), row(2)])
        #expect(store.rows == [row(1), row(2), row(9)])
        #expect(keptCopy() == store.rows)
    }

    @Test func aSaveHereDoesNotBringBackARowDeletedElsewhere() {
        store.rows = [row(1), row(2)]
        let sut = snapshot()
        _ = sut.load()
        store.rows = [row(2)]                  // deleted on another device mid-session
        sut.save([row(1), row(2), row(3)])
        #expect(store.rows == [row(2), row(3)])
    }

    @Test func anEmptyStoreGetsTheKeptCopyBackInsteadOfWipingIt() {
        let first = snapshot()
        _ = first.load()
        first.save([row(1), row(2)])
        store.rows = []                        // recovery opened a fresh store, or the first import hasn't landed
        let loaded = snapshot().load()
        #expect(loaded == [row(1), row(2)])
        #expect(store.rows == loaded)
        #expect(keptCopy() == loaded)
    }

    @Test func aDeleteHereRemovesOnlyThatRow() {
        store.rows = [row(1), row(2)]
        let sut = snapshot()
        _ = sut.load()
        store.rows.append(row(9))
        sut.save([row(1)])
        #expect(store.rows == [row(1), row(9)])
    }

    @Test func aFailedSaveIsAddedToTheStoreNextLaunch() {
        store.rows = [row(1)]
        let sut = snapshot()
        _ = sut.load()
        store.failWrites = true
        sut.save([row(1), row(2)])
        #expect(keptCopy() == [row(1), row(2)])
        store.failWrites = false
        store.rows.append(row(9))
        let loaded = snapshot().load()
        #expect(loaded == [row(1), row(2), row(9)])
        #expect(store.rows == loaded)
    }

    @Test func anUnreadableStoreRunsOnTheKeptCopyWithoutReplacingTheStoreNextLaunch() {
        store.rows = [row(1), row(9)]
        writeKeptCopy([row(1)])
        store.failReads = true
        let sut = snapshot()
        #expect(sut.load() == [row(1)])
        store.failReads = false
        #expect(snapshot().load() == [row(1), row(9)])
        #expect(store.rows == [row(1), row(9)])
    }

    @Test func withSyncOffTheKeptCopyStillWins() {
        writeKeptCopy([row(1)])
        _ = snapshot(syncOn: false).load()
        store.rows = [row(1), row(9)]
        #expect(snapshot(syncOn: false).load() == [row(1)])
        #expect(store.rows == [row(1)])
    }
}
