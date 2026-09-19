import Testing
import TipKit
@testable import RecipeFinder

// Regression: CookingModeTip was displaying up to 3 times (TipKit default).
// MaxDisplayCount(1) must be present so the tip appears at most once.
@Suite struct RecipeTipsTests {

    @Test func cookingModeTip_hasExactlyOneOption() {
        #expect(CookingModeTip().options.count == 1)
    }

    @Test func cookingModeTip_optionIsMaxDisplayCount() {
        let options = CookingModeTip().options
        #expect(options.first is Tips.MaxDisplayCount)
    }

    @Test func canMakeNowTip_hasNoCustomOptions() {
        #expect(CanMakeNowTip().options.isEmpty)
    }
}
