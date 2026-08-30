import SwiftUI

/// The Kitchen screen's title bar (with overflow menu) and search field.
/// Extracted from `KitchenView`.
struct KitchenHeader: View {
    @Binding var searchText: String
    @FocusState.Binding var isSearchFocused: Bool
    let hasItems: Bool
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    let onQuickAdd: () -> Void
    let onClearKitchen: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.spacing12) {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Color.clear
                        .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
                    
                    Spacer()
                    
                    Text("Kitchen")
                        .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                        .adaptiveForegroundColor()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Spacer()
                    
                    Menu {
                        Button(action: onQuickAdd) {
                            Label("Quick Add", systemImage: "plus.circle")
                        }
                        
                        if hasItems {
                            Divider()
                            
                            Button(role: .destructive, action: onClearKitchen) {
                                Label("Clear Kitchen", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: AppTheme.fontSize20))
                            .adaptiveForegroundColor()
                            .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
                    }
                    .accessibilityLabel("Kitchen menu")
                    .accessibilityHint("Opens menu to add ingredients or clear kitchen inventory")
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
                            Text("Search ingredients...")
                                .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                        }
                        TextField("", text: $searchText)
                            .focused($isSearchFocused)
                            .autocorrectionDisabled()
                            .adaptiveForegroundColor()
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
