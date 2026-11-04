import SwiftUI

/// The app's standard sheet frame in one place: its own navigation stack, the themed background, and the
/// inline transparent bar. Apply it last, after `.toolbar` and friends, so they sit inside the stack.
extension View {
    func sheetScaffold(_ title: LocalizedStringKey) -> some View {
        sheetScaffold(title: Text(title))
    }

    func sheetScaffold<S: StringProtocol>(_ title: S) -> some View {
        sheetScaffold(title: Text(title))
    }

    /// For sheets that show their own heading in the content instead of a bar title.
    func sheetScaffold() -> some View {
        sheetScaffold(title: Text(verbatim: ""))
    }

    private func sheetScaffold(title: Text) -> some View {
        NavigationStack {
            ZStack {
                AppBackground()
                self
            }
            .navigationTitle(title)
            .appNavigationChrome()
        }
    }

    /// A toolbar button that only closes the sheet — "Done" by default, or e.g. `("Cancel", placement: .cancellationAction)`.
    func sheetDismissButton(
        _ title: LocalizedStringKey = "Done",
        placement: ToolbarItemPlacement = .confirmationAction
    ) -> some View {
        toolbar {
            ToolbarItem(placement: placement) {
                SheetDismissButton(title: title)
            }
        }
    }
}

private struct SheetDismissButton: View {
    let title: LocalizedStringKey
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button(title) { dismiss() }
    }
}
