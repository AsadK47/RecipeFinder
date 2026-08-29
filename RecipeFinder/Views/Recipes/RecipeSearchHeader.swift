import SwiftUI

/// The screen title with its overflow menu (filters / import / wizard) plus the
/// search field. Extracted from `RecipeSearchView`; the parent owns the focus
/// state and the sheet toggles, which arrive here as a focus binding and closures.
struct RecipeSearchHeader: View {
    @Binding var searchText: String
    var isSearchFocused: FocusState<Bool>.Binding
    let activeFilterCount: Int
    let onToggleFilters: () -> Void
    let onImport: () -> Void
    let onWizard: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted

    var body: some View {
        VStack(spacing: AppTheme.spacing12) {
            headerSection
            searchBarSection
        }
    }

    private var headerSection: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Color.clear
                    .frame(width: max(44, geometry.size.width * 0.15))
                
                Spacer(minLength: 8)
                
                Text("RecipeFinder")
                    .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                    .adaptiveForegroundColor()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Spacer(minLength: 8)
                
                Menu {
                    menuContent
                } label: {
                    CircleButton(icon: "line.3.horizontal") {}
                        .allowsHitTesting(false)
                }
                .frame(width: max(44, geometry.size.width * 0.15))
            }
        }
        .frame(height: AppTheme.height44)
        .padding(.horizontal, AppTheme.spacing20)
        .padding(.top, AppTheme.spacing16)
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

    private var menuContent: some View {
        Group {
            Button(
                action: {
                    HapticManager.shared.light()
                    onToggleFilters()
                },
                label: {
                    Label(activeFilterCount > 0 ? "Filters (\(activeFilterCount))" : "Filters", systemImage: "line.3.horizontal.decrease.circle")
                }
            )
            
            Divider()
            
            Button(
                action: {
                    HapticManager.shared.selection()
                    onImport()
                },
                label: {
                    Label("Import Recipe", systemImage: "plus.circle")
                }
            )
            
            Button(
                action: {
                    HapticManager.shared.selection()
                    onWizard()
                },
                label: {
                    Label("Recipe Wizard", systemImage: "wand.and.stars")
                }
            )
        }
    }
}
