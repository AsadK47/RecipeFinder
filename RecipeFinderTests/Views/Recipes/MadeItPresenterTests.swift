import Testing
import UIKit
@testable import RecipeFinder

/// Sequencing for the Made it sheet: badge celebrations wait while it is up, held for cooking mode, or still
/// animating closed (presenting mid-dismiss silently dropped the celebration).
@MainActor
@Suite("MadeItPresenter")
struct MadeItPresenterTests {

    private let recipeId = UUID()

    private func request() -> MadeItPresenter.Request {
        MadeItPresenter.Request(
            recipeId: recipeId,
            summary: MadeItSummary(cookNumber: 1, streakWeeks: 1, rating: 0, milestone: nil),
            onRate: { _ in },
            onPhotoSelected: { _ in }
        )
    }

    @Test("a new presenter is idle")
    func idle_byDefault() {
        let sut = MadeItPresenter()
        #expect(sut.request == nil)
        #expect(!sut.isBusy)
    }

    @Test("presenting shows the sheet and holds back other sheets")
    func present_showsAndBlocks() {
        let sut = MadeItPresenter()
        sut.present(request())
        #expect(sut.request != nil)
        #expect(sut.isBusy)
    }

    @Test("a held request doesn't show yet but still holds back a badge celebration")
    func hold_blocksWithoutShowing() {
        let sut = MadeItPresenter()
        sut.hold(request())
        #expect(sut.request == nil)
        #expect(sut.isBusy)
    }

    @Test("releasing a held request shows it once")
    func presentHeld_showsOnce() {
        let sut = MadeItPresenter()
        let held = request()
        sut.hold(held)
        sut.presentHeld()
        #expect(sut.request?.id == held.id)
        sut.dismiss()
        sut.didDismiss()
        sut.presentHeld()
        #expect(sut.request == nil)
        #expect(!sut.isBusy)
    }

    @Test("closing the sheet keeps celebrations waiting until the dismiss animation ends")
    func dismiss_unblocksOnlyAfterDidDismiss() {
        let sut = MadeItPresenter()
        sut.present(request())
        sut.dismiss()
        #expect(sut.request == nil)
        #expect(sut.isBusy)
        sut.didDismiss()
        #expect(!sut.isBusy)
    }

    @Test("only the screen showing that recipe presents the sheet")
    func presentsOnlyForTheMatchingRecipe() {
        let sut = MadeItPresenter()
        sut.present(request())
        #expect(sut.request(for: recipeId) != nil)
        #expect(sut.request(for: UUID()) == nil)
    }
}
