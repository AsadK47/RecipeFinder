import SwiftUI

/// The cooking tips filter sheet: favorites toggle, category, and difficulty.
struct FiltersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    @Binding var selectedCategory: CookingTipCategory?
    @Binding var selectedDifficulty: TipDifficulty?
    @Binding var showFavoritesOnly: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                    ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: AppTheme.spacing32) {
                        filterCard {
                            Toggle(isOn: $showFavoritesOnly) {
                                HStack(spacing: AppTheme.spacing12) {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.pink)
                                        .font(.body)
                                    Text("Show Favorites Only")
                                        .fontWeight(.medium)
                                        .adaptiveForegroundColor()
                                }
                            }
                            .tint(AppTheme.accentColor(for: selectedTheme))
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                            HStack(spacing: AppTheme.spacing8) {
                                Image(systemName: "square.grid.2x2.fill")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                Text("Category")
                                    .font(.headline)
                                    .adaptiveForegroundColor()
                            }
                            
                            filterCard {
                                VStack(spacing: AppTheme.spacing8) {
                                    ForEach(CookingTipCategory.allCases) { category in
                                        Button(action: {
                                            selectedCategory = selectedCategory == category ? nil : category
                                            HapticManager.shared.light()
                                        }) {
                                            HStack(spacing: AppTheme.spacing12) {
                                                Image(systemName: category.icon)
                                                    .font(.body)
                                                    .frame(width: AppTheme.iconSize24)
                                                
                                                Text(category.rawValue)
                                                    .font(.body)
                                                
                                                Spacer()
                                                
                                                if selectedCategory == category {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                                        .font(.body)
                                                }
                                            }
                                            .adaptiveForegroundColor()
                                            .padding(.vertical, AppTheme.spacing8)
                                        }
                                        
                                        if category != CookingTipCategory.allCases.last {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                            HStack(spacing: AppTheme.spacing8) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                Text("Difficulty")
                                    .font(.headline)
                                    .adaptiveForegroundColor()
                            }
                            
                            filterCard {
                                VStack(spacing: AppTheme.spacing8) {
                                    ForEach(TipDifficulty.allCases, id: \.self) { difficulty in
                                        Button(action: {
                                            selectedDifficulty = selectedDifficulty == difficulty ? nil : difficulty
                                            HapticManager.shared.light()
                                        }) {
                                            HStack(spacing: AppTheme.spacing12) {
                                                Image(systemName: difficulty.icon)
                                                    .font(.body)
                                                    .frame(width: AppTheme.iconSize24)
                                                
                                                Text(difficulty.rawValue)
                                                    .font(.body)
                                                
                                                Spacer()
                                                
                                                if selectedDifficulty == difficulty {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                                        .font(.body)
                                                }
                                            }
                                            .adaptiveForegroundColor()
                                            .padding(.vertical, AppTheme.spacing8)
                                        }
                                        
                                        if difficulty != TipDifficulty.allCases.last {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(AppTheme.spacing24)
                }
                .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func filterCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(AppTheme.spacing16)
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
