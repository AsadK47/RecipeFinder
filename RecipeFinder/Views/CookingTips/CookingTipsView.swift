import SwiftUI

struct CookingTipsView: View {
    @StateObject private var tipsManager = CookingTipsManager.shared
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    @State private var selectedTip: CookingTipModel?
    @State private var showFilters = false
    @State private var viewMode: ViewMode = .card
    @State private var expandedCategories: Set<String> = []
    
    enum ViewMode {
        case list
        case card
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            GeometryReader { _ in
                    VStack(spacing: 0) {
                        searchBar
                            .padding(.horizontal, AppTheme.spacing20)
                            .padding(.top, AppTheme.spacing12)
                    
                    if hasActiveFilters {
                        activeFiltersPills
                            .padding(.horizontal, AppTheme.spacing20)
                            .padding(.top, AppTheme.spacing12)
                    }
                    
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: AppTheme.spacing32) {
                            if tipsManager.filteredTips.isEmpty {
                                emptyStateView
                            } else {
                                if viewMode == .card {
                                    categoryGridView
                                } else {
                                    compactListView
                                }
                            }
                        }
                        .padding(.top, AppTheme.spacing16)
                        .padding(.horizontal, AppTheme.spacing20)
                        .padding(.bottom, AppTheme.spacing100)
                        .frame(maxWidth: .infinity)
                    }
                    .scrollDisabled(false)
                    .scrollBounceBehavior(.basedOnSize, axes: .vertical)
                }
            }
        }
        .navigationTitle("Cooking Tips")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            viewMode = viewMode == .card ? .list : .card
                        }
                        HapticManager.shared.light()
                    }) {
                        Label(
                            viewMode == .card ? "List View" : "Card View",
                            systemImage: viewMode == .card ? "list.bullet" : "square.grid.2x2"
                        )
                    }
                    
                    Divider()
                    
                    Button(action: {
                        showFilters = true
                        HapticManager.shared.light()
                    }) {
                        Label(
                            hasActiveFilters ? "Filters (Active)" : "Filters",
                            systemImage: "line.3.horizontal.decrease.circle"
                        )
                    }
                    
                    if hasActiveFilters {
                        Button(action: {
                            tipsManager.clearFilters()
                            HapticManager.shared.light()
                        }) {
                            Label("Clear Filters", systemImage: "xmark.circle")
                        }
                    }
                } label: {
                    ZStack {
                        if hasActiveFilters {
                            Circle()
                                .fill(AppTheme.accentColor(for: selectedTheme))
                                .frame(width: 8, height: AppTheme.height8)
                                .offset(x: 10, y: -10)
                        }
                        
                        Image(systemName: "line.3.horizontal")
                            .adaptiveForegroundColor()
                            .font(.title3)
                    }
                }
            }
        }
        .sheet(item: $selectedTip) { tip in
            CookingTipDetailView(tip: tip, onToggleFavorite: {
                tipsManager.toggleFavorite(tip)
            })
        }
        .sheet(isPresented: $showFilters) {
            FiltersSheet(
                selectedCategory: $tipsManager.selectedCategory,
                selectedDifficulty: $tipsManager.selectedDifficulty,
                showFavoritesOnly: $tipsManager.showFavoritesOnly
            )
        }
    }
    
    private var header: some View {
        GeometryReader { geometry in
            let spacing = AdaptiveSpacing(geometry: geometry)
            
            HStack(spacing: 0) {
                Spacer()
                
                Text("Cooking Tips")
                    .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                    .adaptiveForegroundColor()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Spacer()
            }
            .padding(.horizontal, spacing.md)
        }
        .frame(height: AppTheme.height44)
        .padding(.horizontal, AppTheme.spacing20)
        .padding(.top, AppTheme.spacing16)
    }
    
    private var searchBar: some View {
        HStack(spacing: AppTheme.spacing12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.body)
            
            TextField("Search Tips...", text: $tipsManager.searchText)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !tipsManager.searchText.isEmpty {
                Button(action: {
                    tipsManager.searchText = ""
                    HapticManager.shared.light()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.body)
                }
            }
        }
        .padding(AppTheme.spacing12)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(AppTheme.adaptiveCard(for: colorScheme))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(.ultraThinMaterial)
            }
        }
    }
    
    private var activeFiltersPills: some View {
        FlowLayout(spacing: AppTheme.spacing8) {
            if let category = tipsManager.selectedCategory {
                FilterPill(
                    text: category.rawValue,
                    color: AppTheme.accentColor(for: selectedTheme),
                    onRemove: { tipsManager.selectedCategory = nil }
                )
            }
            
            if let difficulty = tipsManager.selectedDifficulty {
                FilterPill(
                    text: difficulty.rawValue,
                    color: .orange,
                    onRemove: { tipsManager.selectedDifficulty = nil }
                )
            }
            
            if tipsManager.showFavoritesOnly {
                FilterPill(
                    text: "Favorites",
                    color: .pink,
                    onRemove: { tipsManager.showFavoritesOnly = false }
                )
            }
            
            Button(action: {
                tipsManager.clearFilters()
                HapticManager.shared.light()
            }) {
                Text("Clear All")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                    .padding(.horizontal, AppTheme.spacing12)
                    .padding(.vertical, AppTheme.spacing6)
            }
        }
    }
    
    private var compactListView: some View {
        VStack(spacing: AppTheme.spacing8) {
            ForEach(tipsManager.filteredTips) { tip in
                CompactTipRow(tip: tip, onTap: {
                    selectedTip = tip
                    HapticManager.shared.light()
                }, onToggleFavorite: {
                    tipsManager.toggleFavorite(tip)
                })
            }
        }
    }
    
    private var categoryGridView: some View {
        VStack(spacing: AppTheme.spacing24) {
            ForEach(CookingTipCategory.allCases) { category in
                let categoryTips = tipsManager.tipsForCategory(category)
                    .filter { tip in
                        tipsManager.searchText.isEmpty ||
                        tip.title.localizedCaseInsensitiveContains(tipsManager.searchText) ||
                        tip.content.localizedCaseInsensitiveContains(tipsManager.searchText)
                    }
                
                if !categoryTips.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if expandedCategories.contains(category.rawValue) {
                                    expandedCategories.remove(category.rawValue)
                                } else {
                                    expandedCategories.insert(category.rawValue)
                                }
                            }
                            HapticManager.shared.light()
                        }) {
                            HStack(spacing: AppTheme.spacing8) {
                                Image(systemName: category.icon)
                                    .font(.title3)
                                    .foregroundColor(colorForCategory(category))
                                
                                Text(category.rawValue)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .adaptiveForegroundColor()
                                
                                Spacer()
                                
                                Text("\(categoryTips.count)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, AppTheme.spacing8)
                                    .padding(.vertical, AppTheme.spacing4)
                                    .background(
                                        Capsule()
                                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity))
                                    )
                                
                                Image(systemName: expandedCategories.contains(category.rawValue) ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        if expandedCategories.contains(category.rawValue) {
                            VStack(spacing: AppTheme.spacing12) {
                                ForEach(categoryTips) { tip in
                                    CookingTipCard(tip: tip, onTap: {
                                        selectedTip = tip
                                        HapticManager.shared.light()
                                    }, onToggleFavorite: {
                                        tipsManager.toggleFavorite(tip)
                                    })
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.spacing24) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: AppTheme.fontSize60))
                .adaptiveForegroundColor(opacity: AppTheme.lowEmphasisOpacity)
            
            Text("No Tips Found")
                .font(.title2)
                .fontWeight(.bold)
                .adaptiveForegroundColor()
            
            Text("Try adjusting your filters or search terms")
                .font(.subheadline)
                .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                .multilineTextAlignment(.center)
            
            Button(action: {
                tipsManager.clearFilters()
                HapticManager.shared.light()
            }) {
                HStack(spacing: AppTheme.spacing8) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
                    Text("Clear Filters")
                        .fontWeight(.semibold)
                }
                .adaptiveForegroundColor()
                .padding(.horizontal, AppTheme.spacing24)
                .padding(.vertical, AppTheme.spacing12)
                .background(
                    Capsule()
                        .fill(AppTheme.accentColor(for: selectedTheme))
                )
            }
        }
        .padding(AppTheme.spacing48)
    }
    
    private var hasActiveFilters: Bool {
        tipsManager.selectedCategory != nil ||
        tipsManager.selectedDifficulty != nil ||
        tipsManager.showFavoritesOnly
    }
    
    private func colorForCategory(_ category: CookingTipCategory) -> Color {
        switch category.color {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "cyan": return .cyan
        case "indigo": return .indigo
        case "yellow": return .yellow
        case "pink": return .pink
        case "mint": return .mint
        default: return AppTheme.accentColor(for: selectedTheme)
        }
    }
}

struct CompactTipRow: View {
    let tip: CookingTipModel
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.spacing12) {
                Image(systemName: tip.category.icon)
                    .font(.body)
                    .foregroundColor(colorForCategory(tip.category))
                    .frame(width: AppTheme.iconSize32)
                
                VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                    Text(tip.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .adaptiveForegroundColor()
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                    
                    HStack(spacing: AppTheme.spacing8) {
                        Text(tip.category.rawValue)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: AppTheme.spacing4) {
                            Image(systemName: tip.difficulty.icon)
                                .font(.caption2)
                            Text(tip.difficulty.rawValue)
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                    }
                }
                
                Spacer(minLength: 8)
                
                Button(action: {
                    onToggleFavorite()
                }) {
                    Image(systemName: tip.isFavorite ? "heart.fill" : "heart")
                        .font(.body)
                        .foregroundColor(tip.isFavorite ? .pink : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.vertical, AppTheme.spacing8)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(AppTheme.adaptiveGlass(for: colorScheme))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func colorForCategory(_ category: CookingTipCategory) -> Color {
        switch category.color {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "cyan": return .cyan
        case "indigo": return .indigo
        case "yellow": return .yellow
        case "pink": return .pink
        case "mint": return .mint
        default: return AppTheme.accentColor(for: selectedTheme)
        }
    }
}

struct CookingTipCard: View {
    let tip: CookingTipModel
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                HStack(alignment: .top, spacing: AppTheme.spacing12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [colorForCategory(tip.category).opacity(AppTheme.shadowDarkOpacity), colorForCategory(tip.category).opacity(AppTheme.shadowLightOpacity)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: AppTheme.iconSize48, height: AppTheme.height48)
                        
                        Image(systemName: tip.category.icon)
                            .font(.system(size: AppTheme.fontSize22))
                            .foregroundColor(colorForCategory(tip.category))
                    }
                    
                    VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                        Text(tip.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .adaptiveForegroundColor()
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(spacing: AppTheme.spacing8) {
                            HStack(spacing: AppTheme.spacing4) {
                                Image(systemName: "bookmark.fill")
                                    .font(.caption2)
                                Text(tip.category.rawValue)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(colorForCategory(tip.category))
                            .padding(.horizontal, AppTheme.spacing8)
                            .padding(.vertical, AppTheme.spacing4)
                            .background(
                                Capsule()
                                    .fill(colorForCategory(tip.category).opacity(AppTheme.cardDarkOpacity))
                            )
                            
                            HStack(spacing: AppTheme.spacing4) {
                                Image(systemName: tip.difficulty.icon)
                                    .font(.caption2)
                                Text(tip.difficulty.rawValue)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, AppTheme.spacing8)
                            .padding(.vertical, AppTheme.spacing4)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(AppTheme.cardDarkOpacity))
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer(minLength: 4)
                    
                    Button(action: {
                        onToggleFavorite()
                    }) {
                        Image(systemName: tip.isFavorite ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundColor(tip.isFavorite ? .pink : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Rectangle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity))
                    .frame(height: AppTheme.height1)
                
                Text(tip.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(AppTheme.lineSpacingNormal)
                
                if !tip.tags.isEmpty {
                    FlowLayout(spacing: AppTheme.spacing6) {
                        ForEach(tip.tags.prefix(3), id: \.self) { tag in
                            HStack(spacing: AppTheme.spacing4) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: AppTheme.fontSize11))
                                Text(tag)
                                    .font(.caption2)
                            }
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, AppTheme.spacing8)
                            .padding(.vertical, AppTheme.spacing4)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(colorScheme == .dark ? AppTheme.dividerOpacity : 0.05))
                            )
                        }
                    }
                }
                
                HStack {
                    Spacer()
                    
                    HStack(spacing: AppTheme.spacing4) {
                        Text("Read More")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption)
                    }
                    .foregroundColor(colorForCategory(tip.category))
                }
            }
            .padding(AppTheme.spacing24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius20)
                        .fill(AppTheme.adaptiveCard(for: colorScheme))
                        .shadow(color: AppTheme.adaptiveShadow(for: colorScheme), radius: 8, x: 0, y: 4)
                } else {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: AppTheme.adaptiveShadow(for: colorScheme), radius: 8, x: 0, y: 4)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius20)
                    .stroke(
                        LinearGradient(
                            colors: [colorForCategory(tip.category).opacity(AppTheme.shadowDarkOpacity), colorForCategory(tip.category).opacity(0.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func colorForCategory(_ category: CookingTipCategory) -> Color {
        switch category.color {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "cyan": return .cyan
        case "indigo": return .indigo
        case "yellow": return .yellow
        case "pink": return .pink
        case "mint": return .mint
        default: return AppTheme.accentColor(for: selectedTheme)
        }
    }
}

struct FilterPill: View {
    let text: String
    let color: Color
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: AppTheme.spacing4) {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
            
            Button(action: {
                onRemove()
                HapticManager.shared.light()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .adaptiveForegroundColor()
        .padding(.horizontal, AppTheme.spacing12)
        .padding(.vertical, AppTheme.spacing6)
        .background(
            Capsule()
                .fill(color)
        )
    }
}

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

#Preview {
    CookingTipsView()
        .environment(\.appTheme, .teal)
}
