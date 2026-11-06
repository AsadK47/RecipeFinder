import SwiftUI

/// Groceries tab header: title, overflow menu (kitchen + shopping actions), and search field.
struct GroceriesHeader<MenuContent: View>: View {
    @Binding var searchText: String
    var isSearchFocused: FocusState<Bool>.Binding
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
            placeholder: "Add or search groceries…",
            isFocused: isSearchFocused,
            onSubmit: onSubmit,
            accessibilityID: "groceries.search"
        )
        .padding(.horizontal, AppTheme.spacing20)
        .padding(.bottom, AppTheme.spacing12)
    }
}
