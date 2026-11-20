import Foundation

/// Keeps the screen awake while a screen is up (the shop, the hob) and restores what it was after — so the
/// Settings "Keep screen awake" choice survives leaving.
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
}
