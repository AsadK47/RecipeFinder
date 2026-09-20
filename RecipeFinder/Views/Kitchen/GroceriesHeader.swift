import SwiftUI

/// Header for the Groceries tab: title, a fridge button that opens kitchen inventory,
/// an overflow menu for shopping actions, and a search field.
struct GroceriesHeader<MenuContent: View>: View {
    @Binding var searchText: String
    var isSearchFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void
    let onKitchenTap: () -> Void
    @ViewBuilder let menuContent: () -> MenuContent

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted

    var body: some View {
        VStack(spacing: AppTheme.spacing12) {
            ScreenTitleHeader("Groceries") {
                HStack(spacing: AppTheme.spacing8) {
                    Button(action: onKitchenTap) {
                        CircleButton(icon: "refrigerator") {}
                            .allowsHitTesting(false)
                    }
                    .accessibilityLabel("Kitchen inventory")

                    Menu {
                        menuContent()
                    } label: {
                        CircleButton(icon: "line.3.horizontal") {}
                            .allowsHitTesting(false)
                    }
                    .accessibilityLabel("More options")
                }
            }

            searchBar
        }
    }

    private var searchBar: some View {
        HStack(spacing: AppTheme.spacing12) {
            HStack(spacing: AppTheme.spacing12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.adaptiveHighEmphasis(for: colorScheme))
                    .font(.system(size: AppTheme.fontSize18, weight: .medium))

                ZStack(alignment: .leading) {
                    if searchText.isEmpty {
                        Text("Add or search groceries…")
                            .font(.callout)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(AppTheme.disabledEmphasisOpacity) : .black.opacity(AppTheme.disabledEmphasisOpacity))
                    }
                    TextField("", text: $searchText)
                        .focused(isSearchFocused)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit(onSubmit)
                        .font(.callout)
                        .adaptiveForegroundColor()
                        .tint(AppTheme.textColor(for: colorScheme))
                }

                if !searchText.isEmpty {
                    Button(
                        action: { searchText = "" },
                        label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: AppTheme.fontSize18))
                                .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
                        }
                    )
                }
            }
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.vertical, AppTheme.spacing14)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                        .fill(AppTheme.adaptiveCard(for: colorScheme))
                } else {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                        .fill(.ultraThinMaterial)
                }
            }

            if isSearchFocused.wrappedValue {
                Button(
                    action: {
                        searchText = ""
                        isSearchFocused.wrappedValue = false
                    },
                    label: {
                        Text("Cancel")
                            .font(.callout.weight(.semibold))
                            .adaptiveForegroundColor()
                    }
                )
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, AppTheme.spacing20)
        .padding(.bottom, AppTheme.spacing12)
        .animation(.spring(response: 0.3), value: isSearchFocused.wrappedValue)
    }
}
