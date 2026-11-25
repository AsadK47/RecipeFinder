import Testing
import Foundation
@testable import RecipeFinder

/// The toast's dismiss timer and VoiceOver text. `ToastModifier.body` is layout plus calls to these (thin glue; that it
/// posts the announcement for every toast is *unconfirmed* by a test — CHALLENGES 2026-11-24).
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

    @Test("A toast without a button is announced as its message")
    func plainToastAnnouncesItsMessage() {
        #expect(ToastAnnouncement.text(for: "No past plans to clear", actionTitle: nil) == "No past plans to clear")
    }

    @Test("A toast with a button says the button is there")
    func actionToastNamesTheButton() {
        #expect(ToastAnnouncement.text(for: "1 meal taken off", actionTitle: "Undo") == "1 meal taken off. Undo available")
    }
}

/// Plan's "stayed off" note after Undo waits before it shows; a take-off in that wait must call it off.
@MainActor
@Suite("Delayed toast")
struct DelayedToastTests {

    @MainActor
    private final class Shown {
        var messages: [String] = []
        var current: String?
        func show(_ message: String) { messages.append(message); current = message }
    }

    @Test("A note shows once its wait is over")
    func showsAfterTheWait() async {
        let shown = Shown()
        var delayed = DelayedToast()
        delayed.show("Tacos stayed off", after: .milliseconds(1)) { shown.show($0) }
        await delayed.pending?.value
        #expect(shown.current == "Tacos stayed off")
    }

    @Test("A take-off during the wait calls the note off")
    func callOffDuringTheWaitKeepsItHidden() async {
        let shown = Shown()
        var delayed = DelayedToast()
        delayed.show("Tacos stayed off", after: .seconds(60)) { shown.show($0) }
        let waiting = delayed.pending
        delayed.callOff { shown.current = nil }
        await waiting?.value
        #expect(shown.messages.isEmpty)
        #expect(delayed.pending == nil)
    }

    @Test("A take-off while the note is up hides it")
    func callOffHidesAShownNote() async {
        let shown = Shown()
        var delayed = DelayedToast()
        delayed.show("Tacos stayed off", after: .milliseconds(1)) { shown.show($0) }
        await delayed.pending?.value
        delayed.callOff { shown.current = nil }
        #expect(shown.current == nil)
    }

    @Test("A newer note replaces one still waiting")
    func newerNoteReplacesTheWaitingOne() async {
        let shown = Shown()
        var delayed = DelayedToast()
        delayed.show("Tacos stayed off", after: .seconds(60)) { shown.show($0) }
        let first = delayed.pending
        delayed.show("2 meals stayed off", after: .milliseconds(1)) { shown.show($0) }
        await first?.value
        await delayed.pending?.value
        #expect(shown.messages == ["2 meals stayed off"])
    }
}
