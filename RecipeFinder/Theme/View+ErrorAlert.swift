import SwiftUI

extension Binding where Value == Bool {
    /// True while `optional` holds a value; setting false clears it — the "show while non-nil" pattern for alerts and dialogs.
    /// Derived through a key path, not `Binding(get:set:)`: iOS 27's closures are `@Sendable` and `Binding` isn't.
    static func isPresent<T>(_ optional: Binding<T?>) -> Binding<Bool> {
        optional[dynamicMember: \.isPresentFlag]
    }
}

extension Optional {
    /// Writing false clears the value; writing true changes nothing (there's nothing to present).
    fileprivate var isPresentFlag: Bool {
        get { self != nil }
        set { if !newValue { self = nil } }
    }
}

extension View {
    /// OK-only alert shown while `message` is non-nil; dismissing clears it.
    func errorAlert(_ title: LocalizedStringKey, message: Binding<String?>) -> some View {
        // `presenting:` keeps the text on screen through the dismiss animation after the binding is cleared.
        alert(title, isPresented: .isPresent(message), presenting: message.wrappedValue) { _ in
            Button("OK", role: .cancel) { message.wrappedValue = nil }
        } message: { text in
            Text(text)
        }
    }
}
