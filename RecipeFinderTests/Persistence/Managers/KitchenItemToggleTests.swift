import Testing
import Foundation
@testable import RecipeFinder

// Tests for KitchenInventoryManager.toggleItem / hasItem —
// the pantry-toggle path used by the house icon in RecipeDetailView.
//
// The view-layer bounds guard (guard index < recipe.ingredients.count)
// cannot be unit-tested here; it lives in a SwiftUI closure (UI layout
// exemption per coverage policy). These tests cover the underlying
// manager behaviour to confirm toggleItem never crashes on its own.
@MainActor
@Suite struct KitchenItemToggleTests {

    private func makeSUT() -> KitchenInventoryManager {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let storage = UserScopedStorage(userDefaults: defaults)
        return KitchenInventoryManager(storage: storage)
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
