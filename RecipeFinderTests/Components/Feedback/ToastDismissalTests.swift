import Testing
import Foundation
@testable import RecipeFinder

/// The toast's dismiss timer and VoiceOver text. `ToastModifier.body` is layout plus calls to these (thin glue).
@MainActor
@Suite("Toast dismissal")
struct ToastDismissalTests {

    @MainActor
    private final class Shown {
        var message: String?
        init(_ message: String?) { self.message = message }
    }

    private func dismiss(_ shown: Shown, showing text: String, after duration: Duration) -> Task<Void, Never> {
        Task { @MainActor in
            await ToastDismissal.run(
                showing: text, for: duration, current: { shown.message }, clear: { shown.message = nil }
            )
        }
    }

    @Test("A wait that runs its full time clears the toast")
    func fullWaitClears() async {
        let shown = Shown("Added to Groceries")
        await dismiss(shown, showing: "Added to Groceries", after: .milliseconds(1)).value
        #expect(shown.message == nil)
    }

    @Test("A newer message survives the old wait being cancelled")
    func newerMessageSurvivesCancelledWait() async {
        // `.task(id: message)` cancels the old wait when a second message arrives; it must not clear the new one.
        let shown = Shown("1 meal taken off")
        let wait = dismiss(shown, showing: "1 meal taken off", after: .seconds(60))
        shown.message = "2 meals taken off"
        wait.cancel()
        await wait.value
        #expect(shown.message == "2 meals taken off")
    }

    @Test("Leaving the screen still clears the toast, so an old Undo can't come back")
    func cancelledWithSameMessageClears() async {
        // `.task` is also cancelled when the view disappears; the message is unchanged then.
        let shown = Shown("1 meal taken off")
        let wait = dismiss(shown, showing: "1 meal taken off", after: .seconds(60))
        wait.cancel()
        await wait.value
        #expect(shown.message == nil)
    }

    @Test("Every toast is announced to VoiceOver, not only ones with a button")
    func plainToastIsAnnounced() {
        #expect(ToastAnnouncement.text(for: "No past plans to clear", actionTitle: nil) == "No past plans to clear")
    }

    @Test("A toast with a button says the button is there")
    func actionToastNamesTheButton() {
        #expect(ToastAnnouncement.text(for: "1 meal taken off", actionTitle: "Undo") == "1 meal taken off. Undo available")
    }
}
