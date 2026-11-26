import Testing
import CoreData
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

    @Test func syncIsOffUntilTheCookTurnsItOn() {
        let storage = LocalStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        #expect(!SyncPreference.isOn(in: storage))
        storage.set(true, forKey: SyncPreference.key)
        #expect(SyncPreference.isOn(in: storage))
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

    // MARK: - Same thing added on two devices (rows with different ids that mean one thing)

    private func fold(_ rows: [Row]) -> [Row] {
        SyncMerge.foldSameThing(rows, key: { AnyHashable($0.text) }, rank: { String($0.id) }, fold: { kept, _ in kept })
    }

    @Test func rowsForTheSameThingBecomeOneKeepingTheLowestRank() {
        let folded = fold([row(2, "eggs"), row(5, "milk"), row(1, "eggs")])
        #expect(folded == [row(5, "milk"), row(1, "eggs")])
    }

    @Test func everyDeviceKeepsTheSameRowWhateverOrderItHoldsThem() {
        #expect(fold([row(1, "eggs"), row(2, "eggs")]) == [row(1, "eggs")])
        #expect(fold([row(2, "eggs"), row(1, "eggs")]) == [row(1, "eggs")])
    }

    @Test func aDeviceThatHasSeenFewerRowsNeverDeletesTheOneKeptEverywhere() {
        // Device B hasn't received row 1 yet: it may drop row 3, never row 1 (the lowest overall).
        let partial = fold([row(3, "eggs"), row(2, "eggs")])
        #expect(partial == [row(2, "eggs")])
        #expect(fold(partial + [row(1, "eggs")]) == [row(1, "eggs")])
    }

    @Test func differentThingsAreLeftAlone() {
        let rows = [row(1, "eggs"), row(2, "milk"), row(3, "flour")]
        #expect(fold(rows) == rows)
    }

    /// Key = first letter; the rest are marks the fold unions (like a shopping item's stores).
    private func foldMarks(_ rows: [Row]) -> [Row] {
        SyncMerge.foldSameThing(rows, key: { AnyHashable(String($0.text.prefix(1))) }, rank: { String($0.id) }) { kept, others in
            let marks = Set(([kept] + others).flatMap { $0.text.dropFirst() })
            return Row(id: kept.id, text: String(kept.text.prefix(1)) + String(marks.sorted()))
        }
    }

    @Test func anotherRowIsOnlyDroppedOnceTheKeptRowAlreadyHoldsWhatItAdds() {
        let first = foldMarks([row(2, "eb"), row(1, "ea")])
        #expect(first == [row(2, "eb"), row(1, "eab")])
        #expect(foldMarks(first) == [row(1, "eab")])
    }

    @Test func aRowTheKeptRowAlreadyHoldsIsDroppedStraightAway() {
        #expect(foldMarks([row(1, "eab"), row(2, "eb")]) == [row(1, "eab")])
    }

    @Test func twoDevicesFoldingAtOnceLoseNothing() {
        // Device A saw rows 1+2 and wrote 1 = "eab"; device B saw 1+3 and wrote 1 = "eac", landing last. Neither
        // deleted its other row, because the stored kept row didn't hold it yet.
        #expect(foldMarks([row(1, "ea"), row(2, "eb")]) == [row(1, "eab"), row(2, "eb")])
        #expect(foldMarks([row(1, "ea"), row(3, "ec")]) == [row(1, "eac"), row(3, "ec")])
        let afterBoth = [row(1, "eac"), row(2, "eb"), row(3, "ec")]
        let next = foldMarks(afterBoth)
        #expect(next == [row(1, "eabc"), row(2, "eb")])
        #expect(foldMarks(next) == [row(1, "eabc")])
    }

    @Test func aFoldThatChangesNothingLeavesTheRowsAsTheyAre() {
        let rows = [row(1, "eab"), row(4, "m")]
        #expect(foldMarks(rows) == rows)
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
        /// The store file's name (`StoreFileIdentifying`); nil = unknown.
        var file: String?
    }

    private let store = Store()

    private func snapshot(syncOn: Bool = true, foldsSameText: Bool = false) -> MirroredSnapshot<Row> {
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
            sync: .init(
                isOn: { syncOn },
                id: { AnyHashable($0.id) },
                storeFile: { store.file },
                sameThing: foldsSameText
                    ? MirroredSnapshot<Row>.SyncRules.SameThing(key: { AnyHashable($0.text) }, rank: { String($0.id) }, fold: { kept, _ in kept })
                    : nil
            )
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

    @Test func aListClearedOnAnotherDeviceStaysClearedWhenReloaded() {
        let sut = snapshot()
        _ = sut.load()
        sut.save([row(1), row(2)])
        store.rows = []                        // cleared on another device, arrives mid-session
        let reloaded = sut.load()
        #expect(reloaded.isEmpty)
        #expect(store.rows.isEmpty)
        #expect(keptCopy() == [])
    }

    @Test func aListClearedOnAnotherDeviceWhileTheAppWasClosedStaysClearedAtLaunch() {
        store.file = "store-A"
        let first = snapshot()
        _ = first.load()
        first.save([row(1), row(2)])
        store.rows = []                        // the other device's clear arrived; same store file
        let loaded = snapshot().load()
        #expect(loaded.isEmpty)
        #expect(store.rows.isEmpty)
        #expect(keptCopy() == [])
    }

    @Test func aFreshStoreFileGetsTheKeptCopyBackAtLaunch() {
        store.file = "store-A"
        let first = snapshot()
        _ = first.load()
        first.save([row(1), row(2)])
        store.rows = []
        store.file = "store-B"                 // recovery set the unreadable file aside and opened a new one
        let loaded = snapshot().load()
        #expect(loaded == [row(1), row(2)])
        #expect(store.rows == loaded)
    }

    @Test func aSaveThatOnlyReachedTheKeptCopyIsAddedToAnEmptiedStoreAtLaunch() {
        store.file = "store-A"
        store.rows = [row(1)]
        let sut = snapshot()
        _ = sut.load()
        store.failWrites = true
        sut.save([row(1), row(2)])
        store.failWrites = false
        store.rows = []                        // cleared elsewhere meanwhile; this device's new row still counts
        let loaded = snapshot().load()
        #expect(loaded == [row(1), row(2)])
    }

    @Test func aStoreFileSeenOnlyWithSyncOffStillGetsTheKeptCopyBack() {
        store.file = "store-A"
        let off = snapshot(syncOn: false)
        _ = off.load()
        off.save([row(1)])
        store.rows = []
        #expect(snapshot().load() == [row(1)])
    }

    @Test func anEmptiedStoreFileIsFollowedOnlyAfterALoadOfThatFileSucceeded() {
        store.file = "store-A"
        writeKeptCopy([row(1)])
        storage.set(true, forKey: MirroredSnapshot<Row>.flagKey(for: blobKey))
        store.failReads = true
        _ = snapshot().load()                  // unreadable: the file is not recorded as loaded
        store.failReads = false
        #expect(snapshot().load() == [row(1)])
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

    @Test func withSyncOnTheSameThingFromTwoDevicesIsOneRowInTheStore() {
        store.rows = [row(2, "eggs"), row(3, "milk"), row(1, "eggs")]
        let loaded = snapshot(foldsSameText: true).load()
        #expect(loaded == [row(3, "milk"), row(1, "eggs")])
        #expect(store.rows == loaded)
        #expect(keptCopy() == loaded)
    }

    @Test func aSaveAfterTheFoldDoesNotBringTheOtherRowBack() {
        store.rows = [row(1, "eggs"), row(2, "eggs")]
        let sut = snapshot(foldsSameText: true)
        let loaded = sut.load()
        sut.save(loaded + [row(4, "milk")])
        #expect(store.rows == [row(1, "eggs"), row(4, "milk")])
    }

    @Test func withSyncOffTheSameThingTwiceIsLeftAlone() {
        writeKeptCopy([row(1, "eggs"), row(2, "eggs")])
        let loaded = snapshot(syncOn: false, foldsSameText: true).load()
        #expect(loaded == [row(1, "eggs"), row(2, "eggs")])
    }

    @Test func withSyncOffTheKeptCopyStillWins() {
        writeKeptCopy([row(1)])
        _ = snapshot(syncOn: false).load()
        store.rows = [row(1), row(9)]
        #expect(snapshot(syncOn: false).load() == [row(1)])
        #expect(store.rows == [row(1)])
    }
}

private func recipe(
    _ id: UUID, cooks: Int = 0, lastCooked: Date? = nil, favourite: Bool = false, rating: Int = 0,
    photos: [String] = [], notes: String = "", hero: String? = nil
) -> RecipeModel {
    RecipeModel(
        id: id, name: "Fish Pie", category: "Main", difficulty: "Basic", prepTime: "10 minutes",
        cookingTime: "30 minutes", baseServings: 4, ingredients: [], prePrepInstructions: [],
        instructions: ["Bake."], notes: notes, imageName: hero, isFavorite: favourite, isSampleRecipe: true,
        cookCount: cooks, lastCookedAt: lastCooked, rating: rating, photoNames: photos
    )
}

/// Two devices that each added the built-in recipes (same ids) meet in iCloud: each recipe must end up once,
/// with nothing the cook did on either device lost (Data safety 2/4).
@Suite struct RecipeCopyMergeTests {
    private let fishPie = UUID()

    private func copy(_ record: String?, _ model: RecipeModel) -> RecipeCopyMerge.Copy {
        RecipeCopyMerge.Copy(recordName: record, recipe: model)
    }

    @Test func aRecipeHeldOnceIsLeftAlone() {
        let plan = RecipeCopyMerge.plan([copy("a", recipe(fishPie)), copy("b", recipe(UUID()))])
        #expect(plan.isEmpty)
    }

    @Test func twoCopiesBecomeOneKeepingTheLowestRecord() {
        let plan = RecipeCopyMerge.plan([copy("b", recipe(fishPie)), copy("a", recipe(fishPie))])
        #expect(plan.delete == ["b"])
        #expect(plan.update.isEmpty)
    }

    /// Both devices pick the same copy to keep whatever order they see them in, so they never delete each
    /// other's copy and leave none.
    @Test func everyDeviceKeepsTheSameCopy() {
        let seenHere = RecipeCopyMerge.plan([copy("x", recipe(fishPie)), copy("m", recipe(fishPie, cooks: 3))])
        let seenThere = RecipeCopyMerge.plan([copy("m", recipe(fishPie)), copy("x", recipe(fishPie, cooks: 5))])
        #expect(seenHere.delete == ["x"])
        #expect(seenThere.delete == ["x"])
    }

    /// A device that hasn't seen every copy yet still never deletes the copy every device keeps.
    @Test func aDeviceThatHasSeenFewerCopiesNeverDeletesTheOneKeptEverywhere() {
        let all = RecipeCopyMerge.plan([copy("a", recipe(fishPie)), copy("b", recipe(fishPie)), copy("c", recipe(fishPie))])
        let partial = RecipeCopyMerge.plan([copy("b", recipe(fishPie)), copy("c", recipe(fishPie))])
        #expect(all.delete == ["b", "c"])
        #expect(!partial.delete.contains("a"))
    }

    @Test func cooksFavouriteRatingAndPhotosFromEveryCopyAreKept() {
        let early = Date(timeIntervalSince1970: 1_000)
        let late = Date(timeIntervalSince1970: 2_000)
        let plan = RecipeCopyMerge.plan([
            copy("a", recipe(fishPie, cooks: 1, lastCooked: early, photos: ["one.jpg"])),
            copy("b", recipe(fishPie, cooks: 4, lastCooked: late, favourite: true, rating: 5, photos: ["two.jpg", "one.jpg"]))
        ])
        let kept = plan.update["a"]
        #expect(kept?.cookCount == 4)
        #expect(kept?.lastCookedAt == late)
        #expect(kept?.isFavorite == true)
        #expect(kept?.rating == 5)
        #expect(kept?.photoNames == ["one.jpg", "two.jpg"])
        #expect(plan.delete == ["b"])
    }

    @Test func theKeptCopysOwnRatingWins() {
        let plan = RecipeCopyMerge.plan([copy("a", recipe(fishPie, rating: 2)), copy("b", recipe(fishPie, rating: 5))])
        #expect(plan.update["a"] == nil)
    }

    @Test func anUnratedKeptCopyTakesTheOthersRating() {
        let plan = RecipeCopyMerge.plan([copy("a", recipe(fishPie)), copy("b", recipe(fishPie, rating: 3))])
        #expect(plan.update["a"]?.rating == 3)
    }

    @Test func theKeptCopysTextIsWhatStays() {
        let plan = RecipeCopyMerge.plan([copy("a", recipe(fishPie, notes: "mine")), copy("b", recipe(fishPie, notes: "theirs"))])
        #expect(plan.update["a"] == nil)
        #expect(plan.delete == ["b"])
    }

    /// The cook's own hero photo on the copy that goes would leave the recipe; it becomes the hero in place of a
    /// web picture. Not a gallery entry: heroes share one file path per recipe, so the next hero would overwrite it.
    @Test func aHeroPhotoOnlyTheOtherCopyHadReplacesTheKeptCopysWebPicture() {
        let ownHero = "RecipeImages/\(fishPie.uuidString).jpg"
        let plan = RecipeCopyMerge.plan([
            copy("a", recipe(fishPie, photos: ["one.jpg"], hero: "https://example.com/pie.jpg")),
            copy("b", recipe(fishPie, hero: ownHero))
        ])
        #expect(plan.update["a"]?.imageName == ownHero)
        #expect(plan.update["a"]?.photoNames == ["one.jpg"])
        #expect(plan.delete == ["b"])
    }

    @Test func anUnillustratedKeptCopyTakesTheOtherCopysHero() {
        let ownHero = "RecipeImages/\(fishPie.uuidString).jpg"
        let plan = RecipeCopyMerge.plan([copy("a", recipe(fishPie)), copy("b", recipe(fishPie, hero: ownHero))])
        #expect(plan.update["a"]?.imageName == ownHero)
        #expect(plan.update["a"]?.photoNames == [])
    }

    /// A kept copy already showing the cook's own hero keeps it (an older app's absolute path counts too).
    @Test(arguments: ["RecipeImages/mine.jpg", "/var/mobile/Documents/RecipeImages/mine.jpg"])
    func theKeptCopysOwnHeroWins(kept: String) {
        let plan = RecipeCopyMerge.plan([
            copy("a", recipe(fishPie, hero: kept)), copy("b", recipe(fishPie, hero: "RecipeImages/theirs.jpg"))
        ])
        #expect(plan.update["a"] == nil)
    }

    /// Same hero on both copies, or one the kept copy already shows among its photos: nothing to add.
    @Test(arguments: [
        (kept: "RecipeImages/pie.jpg", keptPhotos: [String](), other: "RecipeImages/pie.jpg"),
        (kept: "https://example.com/pie.jpg", keptPhotos: ["RecipeImages/pie.jpg"], other: "RecipeImages/pie.jpg")
    ])
    func aHeroTheKeptCopyAlreadyShowsAddsNothing(kept: String, keptPhotos: [String], other: String) {
        let plan = RecipeCopyMerge.plan([
            copy("a", recipe(fishPie, photos: keptPhotos, hero: kept)), copy("b", recipe(fishPie, hero: other))
        ])
        #expect(plan.update["a"] == nil)
        #expect(plan.delete == ["b"])
    }

    /// A web picture or built-in art (e.g. an older starter version's) isn't a photo the cook took: it must not
    /// count as one (badges, Made it) or show in their gallery.
    @Test(arguments: ["https://example.com/old-pie.jpg", "bundled-art:fish-pie", "RecipeImages/web-pie.jpg"])
    func aHeroThatIsNotTheCooksOwnPhotoStaysOut(other: String) {
        let plan = RecipeCopyMerge.plan([
            copy("a", recipe(fishPie, hero: "https://example.com/pie.jpg")), copy("b", recipe(fishPie, hero: other))
        ])
        #expect(plan.update["a"] == nil)
    }

    /// A copy iCloud hasn't uploaded yet has no record name, so devices can't agree on it: wait for the upload.
    @Test func copiesNotYetInICloudAreLeftForLater() {
        let plan = RecipeCopyMerge.plan([copy(nil, recipe(fishPie)), copy("b", recipe(fishPie, cooks: 2))])
        #expect(plan.isEmpty)
    }

    @Test func onlyRecipesHeldMoreThanOnceAreAskedAbout() {
        let other = UUID()
        #expect(RecipeCopyMerge.repeatedIDs(in: [recipe(fishPie), recipe(other), recipe(fishPie)]) == [fishPie])
        #expect(RecipeCopyMerge.repeatedIDs(in: [recipe(fishPie), recipe(other)]).isEmpty)
    }

    @Test func theListShowsEachRecipeOnceUntilTheCopiesMerge() {
        let other = UUID()
        let shown = RecipeCopyMerge.oneCopyEach([recipe(fishPie, cooks: 1), recipe(other), recipe(fishPie, cooks: 2)])
        #expect(shown.map(\.id) == [fishPie, other])
        #expect(shown.first?.cookCount == 1)
    }
}

/// Until iCloud copies are merged, the store holds two rows per recipe: an edit or delete must reach both, or the
/// untouched copy brings the old version back on the next load.
@MainActor
@Suite struct RecipeCopyWriteTests {
    private let fishPie = UUID()

    private func storeWithTwoCopies() async -> PersistenceController {
        let persistence = PersistenceController(inMemory: true)
        _ = await persistence.seedRecipes([recipe(fishPie)])
        _ = await persistence.seedRecipes([recipe(fishPie)])
        return persistence
    }

    @Test func aStoreCanHoldTwoCopiesOfOneRecipe() async {
        let persistence = await storeWithTwoCopies()
        #expect(persistence.fetchRecipes().filter { $0.id == fishPie }.count == 2)
    }

    @Test func anEditReachesEveryCopy() async {
        let persistence = await storeWithTwoCopies()
        #expect(persistence.updateRecipe(recipe(fishPie, favourite: true, rating: 4)))
        let copies = persistence.fetchRecipes().filter { $0.id == fishPie }
        #expect(copies.count == 2)
        #expect(copies.allSatisfy { $0.isFavorite && $0.rating == 4 })
    }

    @Test func aDeleteRemovesEveryCopy() async {
        let persistence = await storeWithTwoCopies()
        persistence.deleteRecipe(withId: fishPie)
        #expect(persistence.fetchRecipes().isEmpty)
    }

    @Test func withSyncOffCopiesAreNotMerged() async {
        let persistence = await storeWithTwoCopies()
        #expect(await !persistence.mergeSyncedRecipeCopies(of: [fishPie]))
        #expect(persistence.fetchRecipes().count == 2)
    }

    /// Runs the merge the way the app does since issue #16: on a background context, never the main thread.
    private func mergeInBackground(_ persistence: PersistenceController, named: Bool) async -> Bool {
        let container = persistence.container
        let ids: Set<UUID> = [fishPie]
        return await withCheckedContinuation { continuation in
            container.performBackgroundTask { context in
                let merged = PersistenceController.mergeRecipeCopies(of: ids, in: context) { objectIDs in
                    guard named else { return [:] }
                    return Dictionary(uniqueKeysWithValues: objectIDs.map { ($0, $0.uriRepresentation().absoluteString) })
                }
                continuation.resume(returning: merged)
            }
        }
    }

    @Test func copiesInICloudMergeIntoOneKeepingBothCopiesMarks() async {
        let persistence = PersistenceController(inMemory: true)
        _ = await persistence.seedRecipes([recipe(fishPie, cooks: 2)])
        _ = await persistence.seedRecipes([recipe(fishPie, favourite: true)])

        let merged = await mergeInBackground(persistence, named: true)

        let copies = persistence.fetchRecipes().filter { $0.id == fishPie }
        #expect(merged)
        #expect(copies.count == 1)
        #expect(copies.first?.cookCount == 2)
        #expect(copies.first?.isFavorite == true)
    }

    /// Whichever copy the merge keeps, the cook's own hero photo is still the recipe's hero afterwards.
    @Test func aHeroPhotoOnOneCopySurvivesTheMerge() async {
        let ownHero = "RecipeImages/\(fishPie.uuidString).jpg"
        let persistence = PersistenceController(inMemory: true)
        _ = await persistence.seedRecipes([recipe(fishPie, hero: "https://example.com/pie.jpg")])
        _ = await persistence.seedRecipes([recipe(fishPie, hero: ownHero)])

        let merged = await mergeInBackground(persistence, named: true)

        let copies = persistence.fetchRecipes().filter { $0.id == fishPie }
        #expect(merged)
        #expect(copies.count == 1)
        #expect(copies.first?.imageName == ownHero)
        #expect(copies.first?.photoNames == [])
    }

    /// Review of issue #16: the merge runs off the main thread now, so the cook can save between its read and its
    /// save. That edit must stand (optimistic locking): the pass gives up and the next load merges again.
    @Test func anEditSavedWhileTheMergeRunsIsKept() async {
        let persistence = PersistenceController(inMemory: true)
        _ = await persistence.seedRecipes([recipe(fishPie, cooks: 2)])
        _ = await persistence.seedRecipes([recipe(fishPie, favourite: true)])
        let container = persistence.container
        let viewContext = container.viewContext
        let id = fishPie
        let ids: Set<UUID> = [id]

        let merged = await withCheckedContinuation { continuation in
            container.performBackgroundTask { context in
                let result = PersistenceController.mergeRecipeCopies(of: ids, in: context) { objectIDs in
                    // The rows are read; the cook rates the recipe on the main context before the pass saves.
                    viewContext.performAndWait {
                        let request = NSFetchRequest<NSManagedObject>(entityName: "Recipe")
                        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                        do {
                            for row in try viewContext.fetch(request) { row.setValue(4, forKey: "rating") }
                            try viewContext.save()
                        } catch {
                            Issue.record("Couldn't save the edit: \(error)")
                        }
                    }
                    return Dictionary(uniqueKeysWithValues: objectIDs.map { ($0, $0.uriRepresentation().absoluteString) })
                }
                continuation.resume(returning: result)
            }
        }

        // Either the pass gave up (both rows stay, the next load merges) or it merged around the edit; the rating
        // the cook saved stands either way.
        let copies = persistence.fetchRecipes().filter { $0.id == fishPie }
        #expect(!copies.isEmpty)
        #expect(copies.allSatisfy { $0.rating == 4 })
        if merged {
            #expect(copies.count == 1)
            #expect(copies.first?.cookCount == 2)
            #expect(copies.first?.isFavorite == true)
        } else {
            #expect(copies.count == 2)
            #expect(await mergeInBackground(persistence, named: true))
            #expect(persistence.fetchRecipes().filter { $0.id == fishPie }.map(\.rating) == [4])
        }
    }

    /// Inbox 2026-11-15: the test above saves the edit before the pass reads the rows' values (fault firing picks the
    /// edit up), so optimistic locking never had to fire. Here the pass has read every value first, then the cook rates
    /// the recipe: the save must fail and roll back rather than write the stale rating over the edit.
    @Test func anEditSavedAfterTheMergeReadTheRowsIsKept() async {
        let persistence = PersistenceController(inMemory: true)
        _ = await persistence.seedRecipes([recipe(fishPie, cooks: 2)])
        _ = await persistence.seedRecipes([recipe(fishPie, favourite: true)])
        let container = persistence.container
        let viewContext = container.viewContext
        let id = fishPie
        let ids: Set<UUID> = [id]

        let merged = await withCheckedContinuation { continuation in
            container.performBackgroundTask { context in
                let result = PersistenceController.mergeRecipeCopies(of: ids, in: context) { objectIDs in
                    // The pass holds every value of both rows now (faults fired), as it does once it maps them.
                    for objectID in objectIDs {
                        let row = context.object(with: objectID)
                        _ = row.value(forKey: "rating")
                        _ = row.value(forKey: "isFavorite")
                    }
                    viewContext.performAndWait {
                        let request = NSFetchRequest<NSManagedObject>(entityName: "Recipe")
                        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                        do {
                            for row in try viewContext.fetch(request) { row.setValue(4, forKey: "rating") }
                            try viewContext.save()
                        } catch {
                            Issue.record("Couldn't save the edit: \(error)")
                        }
                    }
                    return Dictionary(uniqueKeysWithValues: objectIDs.map { ($0, $0.uriRepresentation().absoluteString) })
                }
                continuation.resume(returning: result)
            }
        }

        let copies = persistence.fetchRecipes().filter { $0.id == fishPie }
        #expect(!copies.isEmpty)
        #expect(copies.allSatisfy { $0.rating == 4 })
        if !merged {
            #expect(copies.count == 2)
            #expect(await mergeInBackground(persistence, named: true))
            let after = persistence.fetchRecipes().filter { $0.id == fishPie }
            #expect(after.map(\.rating) == [4])
            #expect(after.first?.cookCount == 2)
            #expect(after.first?.isFavorite == true)
        }
    }

    @Test func copiesWithoutRecordNamesWaitForALaterPass() async {
        let persistence = await storeWithTwoCopies()

        let merged = await mergeInBackground(persistence, named: false)

        #expect(!merged)
        #expect(persistence.fetchRecipes().filter { $0.id == fishPie }.count == 2)
    }
}

/// What counts as "the same item" on two devices, and what the kept row takes from the others (Data safety 2/4).
@Suite struct SameItemRuleTests {
    private func item(
        _ name: String, unit: String = "", quantity: Int = 1, checked: Bool = false,
        stores: [String] = [], recurring: Bool = false
    ) -> ShoppingListModel {
        ShoppingListModel(name: name, isChecked: checked, quantity: quantity, unit: unit, stores: stores, isRecurring: recurring)
    }

    @Test(arguments: [("Eggs", "", " eggs", ""), ("Flour", "Tablespoons", "flour", "tbsp")])
    func shoppingItemsWithTheSameNameAndUnitAreOneItem(a: String, aUnit: String, b: String, bUnit: String) {
        #expect(item(a, unit: aUnit).sameItemKey == item(b, unit: bUnit).sameItemKey)
    }

    @Test func shoppingItemsInDifferentUnitsStayApart() {
        #expect(item("Flour", unit: "g").sameItemKey != item("Flour", unit: "cups").sameItemKey)
    }

    @Test func theFoldedShoppingItemKeepsItsOwnNameAndTakesTheLargestQuantity() {
        let kept = item("Eggs", quantity: 6)
        let folded = kept.folding([item("eggs", quantity: 12), item("EGGS", quantity: 2)])
        #expect(folded.id == kept.id)
        #expect(folded.name == "Eggs")
        #expect(folded.quantity == 12)
    }

    @Test func aFoldedShoppingItemStaysToBuyUnlessEveryCopyWasTicked() {
        #expect(!item("Eggs", checked: true).folding([item("Eggs")]).isChecked)
        #expect(!item("Eggs", checked: true).folding([item("Eggs")]).isCompleted)
        #expect(item("Eggs", checked: true).folding([item("Eggs", checked: true)]).isChecked)
    }

    @Test func aFoldedShoppingItemKeepsEveryStoreAndStaysRecurringIfAnyCopyWas() {
        let folded = item("Eggs", stores: ["Tesco"]).folding([item("Eggs", stores: ["Lidl", "Tesco"], recurring: true)])
        #expect(folded.stores == ["Tesco", "Lidl"])
        #expect(folded.isRecurring)
    }

    @Test func foldingGivesTheSameItemWhateverOrderTheOthersArriveIn() {
        let kept = item("Eggs", quantity: 2)
        let a = item("Eggs", quantity: 6, stores: ["Lidl"])
        let b = item("Eggs", quantity: 3, stores: ["Aldi"], recurring: true)
        let ab = kept.folding([a, b])
        let ba = kept.folding([b, a])
        #expect(ab.quantity == ba.quantity)
        #expect(Set(ab.stores) == Set(ba.stores))
        #expect(ab.isRecurring == ba.isRecurring)
    }

    @Test func kitchenItemsWithTheSameNameAreOneItem() {
        let a = KitchenItem(name: "Olive oil", category: "Oils", unit: "bottle")
        let b = KitchenItem(name: " olive OIL", category: "Other", unit: "item")
        #expect(a.sameItemKey == b.sameItemKey)
        #expect(a.sameItemKey != KitchenItem(name: "Olive", category: "Oils").sameItemKey)
    }
}
