import Testing
import UIKit
@testable import RecipeFinder

/// Sequencing for the root-presented Made it sheet: badge celebrations wait while it is up or held for cooking mode.
@MainActor
@Suite("MadeItPresenter")
struct MadeItPresenterTests {

    private func request() -> MadeItPresenter.Request {
        MadeItPresenter.Request(
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
        sut.request = nil
        sut.presentHeld()
        #expect(sut.request == nil)
        #expect(!sut.isBusy)
    }

    @Test("dismissing the sheet frees the queue for a celebration")
    func dismiss_unblocks() {
        let sut = MadeItPresenter()
        sut.present(request())
        sut.request = nil
        #expect(!sut.isBusy)
    }
}
