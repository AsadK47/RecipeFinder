import XCTest
@testable import RecipeFinder

@MainActor
final class CookingTipsManagerTests: XCTestCase {

    private var storage: UserScopedStorage!
    private var sut: CookingTipsManager!

    override func setUp() async throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        storage = UserScopedStorage(userDefaults: defaults)
        // Do NOT set currentUserId — loadTips() returns [] when userId is nil
        sut = CookingTipsManager(storage: storage)
    }

    override func tearDown() async throws {
        sut = nil
        storage = nil
    }

    // MARK: - Initial state

    func testInitialState_isEmpty() {
        XCTAssertTrue(sut.tips.isEmpty)
        XCTAssertEqual(sut.searchText, "")
        XCTAssertNil(sut.selectedCategory)
        XCTAssertNil(sut.selectedDifficulty)
        XCTAssertFalse(sut.showFavoritesOnly)
    }

    // MARK: - addTip

    func testAddTip_appendsTip() {
        sut.addTip(makeTip(title: "Sharpen your knife"))
        XCTAssertEqual(sut.tips.count, 1)
        XCTAssertEqual(sut.tips[0].title, "Sharpen your knife")
    }

    // MARK: - deleteTip

    func testDeleteTip_removesById() {
        let tip = makeTip(title: "Blanch veggies")
        sut.addTip(tip)
        sut.deleteTip(sut.tips[0])
        XCTAssertTrue(sut.tips.isEmpty)
    }

    func testDeleteTip_unknownId_doesNothing() {
        sut.addTip(makeTip())
        sut.deleteTip(makeTip())
        XCTAssertEqual(sut.tips.count, 1)
    }

    // MARK: - updateTip

    func testUpdateTip_modifiesTip() {
        let tip = makeTip(title: "Original")
        sut.addTip(tip)
        var updated = sut.tips[0]
        updated.title = "Updated"
        sut.updateTip(updated)
        XCTAssertEqual(sut.tips[0].title, "Updated")
    }

    func testUpdateTip_unknownId_doesNothing() {
        sut.addTip(makeTip(title: "A"))
        sut.updateTip(makeTip(title: "Ghost"))
        XCTAssertEqual(sut.tips[0].title, "A")
    }

    // MARK: - toggleFavorite

    func testToggleFavorite_setsIsFavoriteTrue() {
        sut.addTip(makeTip())
        sut.toggleFavorite(sut.tips[0])
        XCTAssertTrue(sut.tips[0].isFavorite)
    }

    func testToggleFavorite_togglesBackToFalse() {
        sut.addTip(makeTip())
        sut.toggleFavorite(sut.tips[0])
        sut.toggleFavorite(sut.tips[0])
        XCTAssertFalse(sut.tips[0].isFavorite)
    }

    // MARK: - filteredTips — showFavoritesOnly

    func testFilteredTips_showFavoritesOnly_returnsOnlyFavorites() {
        sut.addTip(makeTip(title: "Fav", isFavorite: true))
        sut.addTip(makeTip(title: "Not fav", isFavorite: false))
        sut.showFavoritesOnly = true
        XCTAssertEqual(sut.filteredTips.count, 1)
        XCTAssertTrue(sut.filteredTips[0].isFavorite)
    }

    func testFilteredTips_showFavoritesOff_returnsAll() {
        sut.addTip(makeTip(isFavorite: true))
        sut.addTip(makeTip(isFavorite: false))
        sut.showFavoritesOnly = false
        XCTAssertEqual(sut.filteredTips.count, 2)
    }

    // MARK: - filteredTips — selectedCategory

    func testFilteredTips_selectedCategory_returnsOnlyMatchingCategory() {
        sut.addTip(makeTip(title: "Basics", category: .basics))
        sut.addTip(makeTip(title: "Techniques", category: .techniques))
        sut.selectedCategory = .basics
        XCTAssertEqual(sut.filteredTips.count, 1)
        XCTAssertEqual(sut.filteredTips[0].category, .basics)
    }

    func testFilteredTips_nilCategory_returnsAll() {
        sut.addTip(makeTip(category: .basics))
        sut.addTip(makeTip(category: .techniques))
        sut.selectedCategory = nil
        XCTAssertEqual(sut.filteredTips.count, 2)
    }

    // MARK: - filteredTips — selectedDifficulty

    func testFilteredTips_selectedDifficulty_returnsOnlyMatchingDifficulty() {
        sut.addTip(makeTip(title: "Easy", difficulty: .beginner))
        sut.addTip(makeTip(title: "Hard", difficulty: .advanced))
        sut.selectedDifficulty = .beginner
        XCTAssertEqual(sut.filteredTips.count, 1)
        XCTAssertEqual(sut.filteredTips[0].difficulty, .beginner)
    }

    func testFilteredTips_nilDifficulty_returnsAll() {
        sut.addTip(makeTip(difficulty: .beginner))
        sut.addTip(makeTip(difficulty: .advanced))
        sut.selectedDifficulty = nil
        XCTAssertEqual(sut.filteredTips.count, 2)
    }

    // MARK: - filteredTips — searchText

    func testFilteredTips_searchText_matchesTitle() {
        sut.addTip(makeTip(title: "Caramelise onions"))
        sut.addTip(makeTip(title: "Boil pasta"))
        sut.searchText = "caramel"
        XCTAssertEqual(sut.filteredTips.count, 1)
        XCTAssertEqual(sut.filteredTips[0].title, "Caramelise onions")
    }

    func testFilteredTips_searchText_matchesContent() {
        sut.addTip(makeTip(title: "Tip", content: "use a mandoline slicer"))
        sut.searchText = "mandoline"
        XCTAssertEqual(sut.filteredTips.count, 1)
    }

    func testFilteredTips_searchText_matchesTags() {
        sut.addTip(makeTip(title: "Tip", tags: ["mise en place"]))
        sut.searchText = "mise"
        XCTAssertEqual(sut.filteredTips.count, 1)
    }

    func testFilteredTips_searchText_isCaseInsensitive() {
        sut.addTip(makeTip(title: "SEAR the steak"))
        sut.searchText = "sear"
        XCTAssertEqual(sut.filteredTips.count, 1)
    }

    func testFilteredTips_emptySearchText_returnsAll() {
        sut.addTip(makeTip(title: "A"))
        sut.addTip(makeTip(title: "B"))
        sut.searchText = ""
        XCTAssertEqual(sut.filteredTips.count, 2)
    }

    // MARK: - filteredTips — combined filters

    func testFilteredTips_combined_appliesAllFilters() {
        sut.addTip(makeTip(title: "Knife skills", category: .techniques, difficulty: .intermediate, isFavorite: true))
        sut.addTip(makeTip(title: "Knife care", category: .techniques, difficulty: .beginner, isFavorite: true))
        sut.addTip(makeTip(title: "Pasta basics", category: .basics, difficulty: .beginner, isFavorite: true))

        sut.selectedCategory = .techniques
        sut.selectedDifficulty = .intermediate
        sut.showFavoritesOnly = true
        sut.searchText = "knife"

        XCTAssertEqual(sut.filteredTips.count, 1)
        XCTAssertEqual(sut.filteredTips[0].title, "Knife skills")
    }

    // MARK: - clearFilters

    func testClearFilters_resetsAllFilters() {
        sut.selectedCategory = .basics
        sut.selectedDifficulty = .beginner
        sut.showFavoritesOnly = true
        sut.searchText = "something"

        sut.clearFilters()

        XCTAssertNil(sut.selectedCategory)
        XCTAssertNil(sut.selectedDifficulty)
        XCTAssertFalse(sut.showFavoritesOnly)
        XCTAssertEqual(sut.searchText, "")
    }

    // MARK: - tipsForCategory / tipsForDifficulty

    func testTipsForCategory_returnsMatchingCategory() {
        sut.addTip(makeTip(category: .safety))
        sut.addTip(makeTip(category: .storage))
        XCTAssertEqual(sut.tipsForCategory(.safety).count, 1)
        XCTAssertEqual(sut.tipsForCategory(.storage).count, 1)
    }

    func testTipsForDifficulty_returnsMatchingDifficulty() {
        sut.addTip(makeTip(difficulty: .beginner))
        sut.addTip(makeTip(difficulty: .advanced))
        XCTAssertEqual(sut.tipsForDifficulty(.beginner).count, 1)
        XCTAssertEqual(sut.tipsForDifficulty(.advanced).count, 1)
    }

    // MARK: - tipCount

    func testTipCount_forCategory_returnsCorrectCount() {
        sut.addTip(makeTip(category: .seasoning))
        sut.addTip(makeTip(category: .seasoning))
        sut.addTip(makeTip(category: .basics))
        XCTAssertEqual(sut.tipCount(for: .seasoning), 2)
        XCTAssertEqual(sut.tipCount(for: .basics), 1)
    }

    // MARK: - tipsByCategory

    func testTipsByCategory_groupsCorrectly() {
        sut.addTip(makeTip(category: .equipment))
        sut.addTip(makeTip(category: .equipment))
        sut.addTip(makeTip(category: .ingredients))
        let grouped = sut.tipsByCategory
        XCTAssertEqual(grouped[.equipment]?.count, 2)
        XCTAssertEqual(grouped[.ingredients]?.count, 1)
    }

    // MARK: - favoriteTips

    func testFavoriteTips_returnsOnlyFavorites() {
        sut.addTip(makeTip(isFavorite: true))
        sut.addTip(makeTip(isFavorite: false))
        XCTAssertEqual(sut.favoriteTips.count, 1)
    }

    // MARK: - Helpers

    private func makeTip(
        title: String = "Test Tip",
        content: String = "Some content",
        category: CookingTipCategory = .basics,
        difficulty: TipDifficulty = .beginner,
        isFavorite: Bool = false,
        tags: [String] = []
    ) -> CookingTipModel {
        CookingTipModel(
            title: title,
            content: content,
            category: category,
            difficulty: difficulty,
            isFavorite: isFavorite,
            tags: tags
        )
    }
}
