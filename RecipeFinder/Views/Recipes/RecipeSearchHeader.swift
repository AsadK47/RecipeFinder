import SwiftUI
import TipKit

/// The screen title with a filter button plus the search field.
/// Import and manual creation live on the dedicated Import tab — not here.
struct RecipeSearchHeader: View {
    @Binding var searchText: String
    var isSearchFocused: FocusState<Bool>.Binding
    let activeFilterCount: Int
    let onToggleFilters: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted

    private let canMakeNowTip = CanMakeNowTip()

    var body: some View {
        VStack(spacing: AppTheme.spacing12) {
            headerSection
            searchBarSection
        }
    }

    private var headerSection: some View {
        ScreenTitleHeader("RecipeFinder") {
            Button {
                HapticManager.shared.light()
                onToggleFilters()
            } label: {
                CircleButton(icon: "line.3.horizontal.decrease") {}
                    .allowsHitTesting(false)
                    .overlay(alignment: .topTrailing) {
                        if activeFilterCount > 0 {
                            Text("\(activeFilterCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(3)
                                .background(.orange, in: Circle())
                                .offset(x: 4, y: -4)
                        }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(activeFilterCount > 0 ? "Filters, \(activeFilterCount) active" : "Filters")
            .popoverTip(canMakeNowTip, arrowEdge: .top)
        }
    }

    private var searchBarSection: some View {
        HStack(spacing: AppTheme.spacing12) {
            HStack(spacing: AppTheme.spacing12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.adaptiveHighEmphasis(for: colorScheme))
                    .font(.system(size: AppTheme.fontSize18, weight: .medium))
                
                ZStack(alignment: .leading) {
                    if searchText.isEmpty {
                        Text("What would you like to eat...?")
                            .font(.system(size: AppTheme.fontSize16))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(AppTheme.disabledEmphasisOpacity) : .black.opacity(AppTheme.disabledEmphasisOpacity))
                    }
                    TextField("", text: $searchText)
                        .focused(isSearchFocused)
                        .autocorrectionDisabled()
                        .font(.system(size: AppTheme.fontSize16))
                        .adaptiveForegroundColor()
                        .tint(AppTheme.textColor(for: colorScheme))
                }
                
                if !searchText.isEmpty {
                    Button(
                        action: { 
                            searchText = ""
                        },
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
                            .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                            .adaptiveForegroundColor()
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, AppTheme.spacing20)
        .padding(.bottom, AppTheme.spacing12)
        .animation(.spring(response: 0.3), value: isSearchFocused.wrappedValue)
    }

}
