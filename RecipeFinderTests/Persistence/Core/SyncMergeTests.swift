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
        #expect(folded == [row(1, "eggs"), row(5, "milk")])
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

    @Test func theKeptRowIsFoldedWithEveryOtherRowForThatThing() {
        var othersSeen: [Row] = []
        let folded = SyncMerge.foldSameThing(
            [row(3, "b"), row(1, "a"), row(2, "c")],
            key: { _ in AnyHashable(0) },
            rank: { String($0.id) },
            fold: { kept, others in
                othersSeen = others
                return Row(id: kept.id, text: ([kept] + others).map(\.text).sorted().joined())
            }
        )
        #expect(folded == [Row(id: 1, text: "abc")])
        #expect(Set(othersSeen.map(\.id)) == [2, 3])
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
        #expect(loaded == [row(1, "eggs"), row(3, "milk")])
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
    photos: [String] = [], notes: String = ""
) -> RecipeModel {
    RecipeModel(
        id: id, name: "Fish Pie", category: "Main", difficulty: "Basic", prepTime: "10 minutes",
        cookingTime: "30 minutes", baseServings: 4, ingredients: [], prePrepInstructions: [],
        instructions: ["Bake."], notes: notes, isFavorite: favourite, isSampleRecipe: true,
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
        #expect(!persistence.mergeSyncedRecipeCopies(of: [fishPie]))
        #expect(persistence.fetchRecipes().count == 2)
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
