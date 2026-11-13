import Testing
import Foundation
import os
@testable import RecipeFinder

// KitchenInventoryManager.toggleItem / hasItem — the pantry-toggle path behind RecipeDetailView's house icon; confirms toggleItem never crashes on its own.
// (The view-layer bounds guard lives in a SwiftUI closure — UI-layout exemption per coverage policy.)
@MainActor
@Suite struct KitchenItemToggleTests {

    private func makeSUT() -> KitchenInventoryManager {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let storage = LocalStore(userDefaults: defaults)
        return KitchenInventoryManager(storage: storage, kitchenStore: InMemoryKitchenStore())
    }

    // MARK: - toggleItem: add path

    @Test func toggleItem_addsItem_whenAbsent() {
        let sut = makeSUT()
        sut.toggleItem("Chicken")
        #expect(sut.hasItem("Chicken"))
    }

    @Test func toggleItem_addsItem_caseInsensitiveLookup() {
        let sut = makeSUT()
        sut.toggleItem("chicken")
        #expect(sut.hasItem("CHICKEN"))
        #expect(sut.hasItem("Chicken"))
    }

    // MARK: - toggleItem: remove path

    @Test func hasItem_isObserved_soARowRedrawsWhenTheItemIsRemoved() {
        let sut = makeSUT()
        sut.toggleItem("Banana")
        let changed = OSAllocatedUnfairLock(initialState: false)
        withObservationTracking { _ = sut.hasItem("Banana") } onChange: { changed.withLock { $0 = true } }
        sut.toggleItem("Banana")
        #expect(changed.withLock { $0 })
    }

    @Test func toggleItem_removesItem_whenNameHasStraySpaces() {
        let sut = makeSUT()
        sut.toggleItem("Eggs")
        sut.toggleItem(" Eggs ")
        #expect(!sut.hasItem("Eggs"))
        #expect(sut.items.isEmpty)
    }

    @Test func hasItem_ignoresStraySpaces() {
        let sut = makeSUT()
        sut.toggleItem("Eggs")
        #expect(sut.hasItem("  eggs"))
    }

    @Test func toggleItem_removesItem_whenPresent() {
        let sut = makeSUT()
        sut.toggleItem("Garlic")
        sut.toggleItem("Garlic")
        #expect(!sut.hasItem("Garlic"))
        #expect(sut.items.isEmpty)
    }

    @Test func toggleItem_removesItem_caseInsensitiveMatch() {
        let sut = makeSUT()
        sut.toggleItem("Garlic")
        sut.toggleItem("garlic")
        #expect(!sut.hasItem("Garlic"))
    }

    @Test func toggleItem_cycleAddRemoveAdd_leavesItemPresent() {
        let sut = makeSUT()
        sut.toggleItem("Onion")
        sut.toggleItem("Onion")
        sut.toggleItem("Onion")
        #expect(sut.hasItem("Onion"))
        #expect(sut.items.count == 1)
    }

    // MARK: - toggleItem: guard paths (empty / whitespace)

    @Test func toggleItem_emptyName_isNoop() {
        let sut = makeSUT()
        sut.toggleItem("")
        #expect(sut.items.isEmpty)
    }

    @Test func toggleItem_whitespaceOnly_isNoop() {
        let sut = makeSUT()
        sut.toggleItem("   ")
        #expect(sut.items.isEmpty)
    }

    // MARK: - hasItem

    @Test func hasItem_returnsFalse_whenManagerIsEmpty() {
        let sut = makeSUT()
        #expect(!sut.hasItem("Salmon"))
    }

    @Test func hasItem_returnsTrue_afterToggleIn() {
        let sut = makeSUT()
        sut.toggleItem("Salmon")
        #expect(sut.hasItem("Salmon"))
    }

    @Test func hasItem_returnsFalse_afterToggleOut() {
        let sut = makeSUT()
        sut.toggleItem("Salmon")
        sut.toggleItem("Salmon")
        #expect(!sut.hasItem("Salmon"))
    }

    @Test func hasItem_doesNotMatchUnrelatedItems() {
        let sut = makeSUT()
        sut.toggleItem("Beef")
        #expect(!sut.hasItem("Pork"))
    }
}
