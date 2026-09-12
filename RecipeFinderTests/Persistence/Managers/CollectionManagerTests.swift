import Foundation
import Testing
@testable import RecipeFinder

@MainActor
@Suite("CollectionManager")
struct CollectionManagerTests {

    private func makeSUT() -> CollectionManager {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let storage = UserScopedStorage(userDefaults: defaults)
        return CollectionManager(storage: storage)
    }

    private func makeRecipeID() -> UUID { UUID() }

    // MARK: - Initial state

    @Test func initialState_isEmpty() {
        let sut = makeSUT()
        #expect(sut.collections.isEmpty)
    }

    // MARK: - createCollection

    @Test func create_addsCollection() {
        let sut = makeSUT()
        sut.createCollection(name: "Weeknight Dinners")
        #expect(sut.collections.count == 1)
        #expect(sut.collections[0].name == "Weeknight Dinners")
    }

    @Test func create_trimsWhitespace() {
        let sut = makeSUT()
        sut.createCollection(name: "  Party Food  ")
        #expect(sut.collections[0].name == "Party Food")
    }

    @Test func create_emptyName_ignored() {
        let sut = makeSUT()
        sut.createCollection(name: "   ")
        #expect(sut.collections.isEmpty)
    }

    @Test func create_setsColor() {
        let sut = makeSUT()
        sut.createCollection(name: "Desserts", color: .pink)
        #expect(sut.collections[0].colorName == .pink)
    }

    // MARK: - rename

    @Test func rename_updatesName() {
        let sut = makeSUT()
        sut.createCollection(name: "Old Name")
        let collection = sut.collections[0]
        sut.rename(collection, to: "New Name")
        #expect(sut.collections[0].name == "New Name")
    }

    @Test func rename_emptyName_noChange() {
        let sut = makeSUT()
        sut.createCollection(name: "Starters")
        let collection = sut.collections[0]
        sut.rename(collection, to: "  ")
        #expect(sut.collections[0].name == "Starters")
    }

    @Test func rename_unknownCollection_ignored() {
        let sut = makeSUT()
        sut.createCollection(name: "Soups")
        let phantom = RecipeCollection(name: "Phantom")
        sut.rename(phantom, to: "Ghost")
        #expect(sut.collections[0].name == "Soups")
    }

    // MARK: - recolor

    @Test func recolor_updatesColor() {
        let sut = makeSUT()
        sut.createCollection(name: "Salads", color: .green)
        let collection = sut.collections[0]
        sut.recolor(collection, to: .red)
        #expect(sut.collections[0].colorName == .red)
    }

    // MARK: - delete

    @Test func delete_removesCollection() {
        let sut = makeSUT()
        sut.createCollection(name: "Breakfast")
        let collection = sut.collections[0]
        sut.delete(collection)
        #expect(sut.collections.isEmpty)
    }

    @Test func delete_unknownCollection_ignored() {
        let sut = makeSUT()
        sut.createCollection(name: "Lunch")
        let phantom = RecipeCollection(name: "Phantom")
        sut.delete(phantom)
        #expect(sut.collections.count == 1)
    }

    // MARK: - recipe membership

    @Test func addRecipe_membersContainIt() {
        let sut = makeSUT()
        sut.createCollection(name: "Pasta")
        let collection = sut.collections[0]
        let id = makeRecipeID()
        sut.add(recipeID: id, to: collection)
        #expect(sut.collections[0].contains(id))
    }

    @Test func addRecipe_duplicateIgnored() {
        let sut = makeSUT()
        sut.createCollection(name: "Pasta")
        let collection = sut.collections[0]
        let id = makeRecipeID()
        sut.add(recipeID: id, to: collection)
        sut.add(recipeID: id, to: collection)
        #expect(sut.collections[0].recipeIDs.count == 1)
    }

    @Test func removeRecipe_noLongerMember() {
        let sut = makeSUT()
        sut.createCollection(name: "Soups")
        let collection = sut.collections[0]
        let id = makeRecipeID()
        sut.add(recipeID: id, to: collection)
        sut.remove(recipeID: id, from: collection)
        #expect(!sut.collections[0].contains(id))
    }

    @Test func toggle_addsThenRemoves() {
        let sut = makeSUT()
        sut.createCollection(name: "Stews")
        let collection = sut.collections[0]
        let id = makeRecipeID()
        let addedResult = sut.toggle(recipeID: id, in: collection)
        #expect(addedResult == true)
        #expect(sut.collections[0].contains(id))
        let removedResult = sut.toggle(recipeID: id, in: collection)
        #expect(removedResult == false)
        #expect(!sut.collections[0].contains(id))
    }

    // MARK: - purge

    @Test func purge_removesRecipeFromAllCollections() {
        let sut = makeSUT()
        sut.createCollection(name: "A")
        sut.createCollection(name: "B")
        let id = makeRecipeID()
        sut.add(recipeID: id, to: sut.collections[0])
        sut.add(recipeID: id, to: sut.collections[1])
        sut.purge(recipeID: id)
        #expect(!sut.collections[0].contains(id))
        #expect(!sut.collections[1].contains(id))
    }

    // MARK: - collectionsContaining

    @Test func collectionsContaining_returnsOnlyMatching() {
        let sut = makeSUT()
        sut.createCollection(name: "A")
        sut.createCollection(name: "B")
        let id = makeRecipeID()
        sut.add(recipeID: id, to: sut.collections[0])
        let result = sut.collections(containing: id)
        #expect(result.count == 1)
        #expect(result[0].name == "A")
    }

    // MARK: - merge

    @Test func merge_addsNewCollections() {
        let sut = makeSUT()
        sut.createCollection(name: "Existing")
        let incoming = [RecipeCollection(name: "New One")]
        sut.merge(incoming)
        #expect(sut.collections.count == 2)
    }

    @Test func merge_doesNotDuplicate() {
        let sut = makeSUT()
        sut.createCollection(name: "Existing")
        let existing = sut.collections[0]
        sut.merge([existing])
        #expect(sut.collections.count == 1)
    }

    // MARK: - persistence round-trip

    @Test func roundTrip_survivesReload() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let storage = UserScopedStorage(userDefaults: defaults)
        let first = CollectionManager(storage: storage)
        first.createCollection(name: "Baking", color: .orange)
        let id = UUID()
        first.add(recipeID: id, to: first.collections[0])

        let second = CollectionManager(storage: storage)
        #expect(second.collections.count == 1)
        #expect(second.collections[0].name == "Baking")
        #expect(second.collections[0].colorName == .orange)
        #expect(second.collections[0].contains(id))
    }
}
