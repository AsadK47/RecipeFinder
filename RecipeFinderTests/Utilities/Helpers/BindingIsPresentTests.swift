import SwiftUI
import Testing
@testable import RecipeFinder

/// Pins `Binding.isPresent(_:)` — the "show while non-nil" binding behind `errorAlert` and the rename-store alert.
@MainActor
@Suite struct BindingIsPresentTests {
    /// Test-only storage for a hand-made binding; single-threaded under `@MainActor`.
    private final class Box: @unchecked Sendable {
        var value: String?
        init(_ value: String?) { self.value = value }
    }

    private func binding(_ box: Box) -> Binding<String?> {
        Binding(get: { box.value }, set: { box.value = $0 })
    }

    @Test func isTrueWhileValueIsPresent() {
        let box = Box("Oops")
        #expect(Binding.isPresent(binding(box)).wrappedValue)
    }

    @Test func isFalseWhenValueIsNil() {
        let box = Box(nil)
        #expect(!Binding.isPresent(binding(box)).wrappedValue)
    }

    @Test func settingFalseClearsTheValue() {
        let box = Box("Oops")
        let isPresent = Binding.isPresent(binding(box))
        isPresent.wrappedValue = false
        #expect(box.value == nil)
        #expect(!isPresent.wrappedValue)
    }

    @Test func settingTrueLeavesTheValueAlone() {
        let box = Box("Oops")
        Binding.isPresent(binding(box)).wrappedValue = true
        #expect(box.value == "Oops")

        let empty = Box(nil)
        Binding.isPresent(binding(empty)).wrappedValue = true
        #expect(empty.value == nil)
    }
}
