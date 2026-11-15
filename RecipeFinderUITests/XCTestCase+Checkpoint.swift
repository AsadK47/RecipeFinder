import XCTest

extension XCTestCase {
    /// Screenshot just before a critical step, kept only when the test fails: a red run shows the screens that led
    /// to the failure, a green run carries no extra attachments. Use at the taps and waits a flow depends on, not
    /// every step (per-step capture cost ~40% of UI test time).
    @MainActor
    func checkpoint(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "checkpoint: \(name)"
        shot.lifetime = .deleteOnSuccess
        add(shot)
    }
}
