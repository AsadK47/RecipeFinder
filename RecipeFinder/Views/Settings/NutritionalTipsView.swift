import SwiftUI

struct NutritionalTipsView: View {
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @Environment(\.colorScheme) var colorScheme

    @State private var selectedCategory: NutritionalTipCategory? = nil
    @State private var selectedTip: NutritionalTip? = nil
    @State private var showTipDetail = false
    @State private var showFilterMenu = false

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                    VStack(spacing: AppTheme.spacing24) {
                        tipOfTheDayCard

                        tipsGrid
                    }
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.top, AppTheme.spacing16)
                    .padding(.bottom, AppTheme.spacing100)
                }
        }
        .navigationTitle("Nutrition Tips")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        selectedCategory = nil
                        HapticManager.shared.light()
                    }) {
                        HStack {
                            Text("All Tips")
                            if selectedCategory == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    Divider()

                    ForEach(NutritionalTipCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                            HapticManager.shared.light()
                        }) {
                            HStack {
                                Text("\(category.icon) \(category.rawValue)")
                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: selectedCategory == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                        .adaptiveForegroundColor()
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showTipDetail) {
            if let tip = selectedTip {
                TipDetailView(tip: tip)
            }
        }
    }

    private var tipOfTheDayCard: some View {
        let tip = NutritionalTipsDatabase.tipOfTheDay()

        return Button(action: {
            selectedTip = tip
            showTipDetail = true
            HapticManager.shared.light()
        }) {
            HStack(spacing: AppTheme.spacing16) {
                Text(tip.icon)
                    .font(.system(size: AppTheme.fontSize50))

                VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                    HStack {
                        Text("💡")
                            .font(.caption2)
                        Text("TIP OF THE DAY")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                    }

                    Text(tip.title)
                        .font(.headline)
                        .adaptiveForegroundColor()
                        .multilineTextAlignment(.leading)

                    Text(tip.summary)
                        .font(.caption)
                        .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
            }
            .padding()
            .background {
                cardBackground()
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                            .stroke(AppTheme.accentColor(for: selectedTheme).opacity(0.5), lineWidth: 2)
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var tipsGrid: some View {
        let filteredTips: [NutritionalTip]
        if let category = selectedCategory {
            filteredTips = NutritionalTipsDatabase.tips(forCategory: category)
        } else {
            filteredTips = NutritionalTipsDatabase.allTips
        }

        return LazyVStack(spacing: AppTheme.spacing16) {
            ForEach(filteredTips) { tip in
                NutritionalTipCard(tip: tip) {
                    selectedTip = tip
                    showTipDetail = true
                    HapticManager.shared.light()
                }
            }
        }
    }

    private func cardBackground() -> some View {
        Group {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .fill(AppTheme.adaptiveCardMedium(for: colorScheme))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .fill(.ultraThinMaterial)
            }
        }
    }
}

struct NutritionalTipsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NutritionalTipsView()
        }
    }
}
