import XCTest
@testable import RecipeFinder

@MainActor
final class PersistenceControllerTests: XCTestCase {

    /// Regression guard: the persistent store loads synchronously, so the
    /// controller must report ready as soon as it exists. When this flag was
    /// set through a deferred Task instead, the launch-time fetchRecipes()
    /// saw `false`, returned [], and the recipe list stayed empty for the
    /// whole session (intermittently, depending on runloop scheduling).
    func testStoreIsLoadedImmediatelyAfterAccess() {
        let controller = PersistenceController.shared
        XCTAssertTrue(controller.isStoreLoaded)
        XCTAssertNil(controller.loadError)
    }

    func testFetchRecipesWithReadyStoreDoesNotFailFromStoreState() {
        // With the store ready, an empty result can only mean "no recipes
        // for this scope", never "store wasn't loaded yet".
        XCTAssertTrue(PersistenceController.shared.isStoreLoaded)
        _ = PersistenceController.shared.fetchRecipes()
    }
}
