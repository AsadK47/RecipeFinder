import SwiftUI

/// The "Chef Type" selection grid on the Account screen. Extracted from
/// `AccountView`.
struct AccountChefTypeSection: View {
    @Binding var selectedChefType: ChefType
    let selectedTheme: AppTheme.ThemeType
    let cardStyle: CardStyle
    let colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: AppTheme.spacing12) {
            HStack {
                Image(systemName: "fork.knife.circle.fill")
                    .adaptiveForegroundColor()
                Text("Chef Type")
                    .font(.headline)
                    .adaptiveForegroundColor()
                Spacer()
            }
            .padding(.horizontal, AppTheme.cardHorizontalPadding)
            .padding(.top, AppTheme.spacing16)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacing12) {
                ForEach(ChefType.allCases, id: \.self) { type in
                    ChefTypeCard(
                        chefType: type,
                        isSelected: selectedChefType == type,
                        selectedTheme: selectedTheme
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedChefType = type
                            HapticManager.shared.light()
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.cardHorizontalPadding)
            .padding(.bottom, AppTheme.spacing16)
        }
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .fill(AppTheme.adaptiveCard(for: colorScheme))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .fill(.ultraThinMaterial)
            }
        }
    }
}
