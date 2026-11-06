import SwiftUI

extension Binding where Value == Bool {
    /// True while `optional` holds a value; setting false clears it — the "show while non-nil" pattern for alerts and dialogs.
    static func isPresent<T>(_ optional: Binding<T?>) -> Binding<Bool> {
        Binding(
            get: { optional.wrappedValue != nil },
            set: { if !$0 { optional.wrappedValue = nil } }
        )
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
