import SwiftUI

/// The Shopping List title bar (with overflow menu) and add-item search field.
/// Extracted from `ShoppingListView`.
struct ShoppingListHeader: View {
    @Binding var searchText: String
    @FocusState.Binding var isSearchFocused: Bool
    let hasItems: Bool
    let isAllCollapsed: Bool
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    let onQuickAdd: () -> Void
    let onShare: () -> Void
    let onToggleCollapseAll: () -> Void
    let onClearItems: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.spacing12) {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Color.clear
                        .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
                    
                    Spacer()
                    
                    Text("Shopping List")
                        .font(.system(size: min(32, geometry.size.width * 0.082), weight: .bold))
                        .adaptiveForegroundColor()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Spacer()
                    
                    Menu {
                        Button(action: {
                            HapticManager.shared.light()
                            onQuickAdd()
                        }) {
                            Label("Quick Add", systemImage: "plus.circle")
                        }
                        
                        Button(action: {
                            HapticManager.shared.light()
                            onShare()
                        }) {
                            Label("Share List", systemImage: "square.and.arrow.up")
                        }
                        
                        if hasItems {
                            Divider()
                            
                            Button(
                                action: onToggleCollapseAll,
                                label: {
                                    Label(
                                        isAllCollapsed ? "Expand All" : "Collapse All",
                                        systemImage: isAllCollapsed ? "chevron.down.circle" : "chevron.up.circle"
                                    )
                                }
                            )
                            
                            Divider()
                            
                            Button(
                                role: .destructive,
                                action: onClearItems,
                                label: {
                                    Label("Clear Items", systemImage: "trash")
                                }
                            )
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: AppTheme.fontSize20))
                            .adaptiveForegroundColor()
                            .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
                    }
                    .accessibilityLabel("Shopping list menu")
                    .accessibilityHint("Opens menu with options to add items, share list, or manage categories")
                }
            }
            .frame(height: AppTheme.height44)
            .padding(.horizontal, AppTheme.spacing20)
            .padding(.top, AppTheme.spacing16)
            
            HStack(spacing: AppTheme.spacing12) {
                HStack(spacing: AppTheme.spacing12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.adaptiveHighEmphasis(for: colorScheme))
                        .font(.body)
                    
                    ZStack(alignment: .leading) {
                        if searchText.isEmpty {
                            Text("Add item...")
                                .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                        }
                        TextField("", text: $searchText)
                            .focused($isSearchFocused)
                            .autocorrectionDisabled()
                            .adaptiveForegroundColor()
                            .onSubmit(onSubmit)
                    }
                    
                    if !searchText.isEmpty {
                        Button(
                            action: { 
                                searchText = ""
                            },
                            label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
                            }
                        )
                    }
                }
                .padding(AppTheme.spacing16)
                .background {
                    if cardStyle == .solid {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                            .fill(AppTheme.adaptiveCard(for: colorScheme))
                    } else {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                            .fill(.ultraThinMaterial)
                    }
                }
                
                if isSearchFocused {
                    Button(
                        action: {
                            searchText = ""
                            isSearchFocused = false
                        },
                        label: {
                            Text("Cancel")
                                .adaptiveForegroundColor()
                                .fontWeight(.semibold)
                        }
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.horizontal, AppTheme.spacing20)
            .padding(.bottom, AppTheme.spacing12)
            .animation(.spring(response: 0.3), value: isSearchFocused)
        }
    }
}
