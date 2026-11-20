import Foundation

/// Keeps the screen awake while a screen is up (the shop) and restores what it was after, rather than forcing it
/// off — leaving can't switch off a keep-awake something else turned on.
@MainActor
final class ScreenAwakeHold {
    private let read: @MainActor () -> Bool
    private let write: @MainActor (Bool) -> Void
    private var before: Bool?

    init(read: @escaping @MainActor () -> Bool, write: @escaping @MainActor (Bool) -> Void) {
        self.read = read
        self.write = write
    }

    func begin() {
        if before == nil { before = read() }
        write(true)
    }

    func end() {
        guard let before else { return }
        write(before)
        self.before = nil
    }

    /// Re-takes the hold when the app comes back (a call, the lock screen or another app can drop it) and lets go
    /// while it's away, so the screens holding it behave the same.
    func sceneChanged(isActive: Bool) {
        if isActive { begin() } else { end() }
    }
}

/// Settings › Display "Keep Screen Awake", applied at the app root. Coming back to the app only ever turns it on:
/// writing "off" there could land after cooking mode or the shop has switched it on. Off is written when the switch
/// is turned off, from Settings, where neither of those screens is up.
@MainActor
struct KeepAwakeSetting {
    let write: @MainActor (Bool) -> Void

    func switched(on: Bool) {
        write(on)
    }

    func appBecameActive(settingOn: Bool) {
        if settingOn { write(true) }
    }
}
