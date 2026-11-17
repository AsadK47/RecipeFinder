import SwiftUI

/// Groceries tab header: title, overflow menu (actions for the side showing), and the add/search field.
struct GroceriesHeader<MenuContent: View>: View {
    @Binding var searchText: String
    var isSearchFocused: FocusState<Bool>.Binding
    let placeholder: String
    let onSubmit: () -> Void
    @ViewBuilder let menuContent: () -> MenuContent

    var body: some View {
        VStack(spacing: AppTheme.spacing12) {
            ScreenTitleHeader("Groceries") {
                CircleMenuButton(accessibilityLabel: "More options", content: menuContent)
            }

            searchBar
        }
    }

    private var searchBar: some View {
        AppSearchField(
            text: $searchText,
            placeholder: placeholder,
            isFocused: isSearchFocused,
            onSubmit: onSubmit,
            accessibilityID: "groceries.search"
        )
        .padding(.horizontal, AppTheme.spacing20)
        .padding(.bottom, AppTheme.spacing12)
    }
}
