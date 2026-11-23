import Testing
import Foundation
@testable import RecipeFinder

/// The toast's dismiss timer. `ToastModifier.body` is layout plus this one call (exempt as thin glue).
@Suite("Toast dismissal")
struct ToastDismissalTests {

    @Test("A wait that runs its full time clears the toast")
    func fullWaitDismisses() async {
        let dismiss = await ToastDismissal.shouldDismiss(after: .milliseconds(1))
        #expect(dismiss)
    }

    @Test("A cancelled wait leaves the newer message on screen")
    func cancelledWaitKeepsNewerMessage() async {
        // `.task(id: message)` cancels the old wait when a second message arrives; it must not clear the new one.
        let wait = Task { await ToastDismissal.shouldDismiss(after: .seconds(60)) }
        wait.cancel()
        let dismiss = await wait.value
        #expect(!dismiss)
    }

    @Test("A wait cancelled before it starts sleeping does not clear the toast")
    func preCancelledWaitKeepsMessage() async {
        let wait = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return await ToastDismissal.shouldDismiss(after: .milliseconds(1))
        }
        let dismiss = await wait.value
        #expect(!dismiss)
    }
}
