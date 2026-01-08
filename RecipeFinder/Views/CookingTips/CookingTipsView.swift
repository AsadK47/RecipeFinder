import SwiftUI

// TODO: Future Enhancement - Add support for helpful pictures and videos to cooking tips
// - Add media attachments to CookingTipModel (images, video URLs)
// - Display images in tip cards
// - Support embedded video playback in detail view
// - Allow users to add their own media to tips

struct CookingTipsView: View {
    @StateObject private var tipsManager = CookingTipsManager.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
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
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            // Back button
                            Button(action: {
                                HapticManager.shared.light()
                                dismiss()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.title3)
                                    .adaptiveForegroundColor()
                                    .frame(width: 44, height: 44)
                            }
                            
                            Spacer()
                            
                            Text("Cooking Tips")
                                .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                                .adaptiveForegroundColor()
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            
                            Spacer()
                            
                            // Menu button
                            Menu {
                                // View mode toggle
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
                                
                                // Filters
                                Button(action: {
                                    showFilters = true
                                    HapticManager.shared.light()
                                }) {
                                    Label(
                                        hasActiveFilters ? "Filters (Active)" : "Filters",
                                        systemImage: "line.3.horizontal.decrease.circle"
                                    )
                                }
                                
                                // Clear filters option if active
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
                                    // Badge indicator if filters are active
                                    if hasActiveFilters {
                                        Circle()
                                            .fill(AppTheme.accentColor(for: selectedTheme))
                                            .frame(width: 8, height: 8)
                                            .offset(x: 10, y: -10)
                                    }
                                    
                                    Image(systemName: "line.3.horizontal")
                                        .adaptiveForegroundColor()
                                        .font(.title3)
                                        .frame(width: 44, height: 44)
                                }
                            }
                        }
                    }
                    .frame(height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // Search Bar
                        searchBar
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                    
                    // Filter Pills
                    if hasActiveFilters {
                        activeFiltersPills
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                    }
                    
                    // Content
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 24) {
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
                        .padding(.top, 16)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                        .frame(width: geometry.size.width - 40)
                    }
                    .scrollDisabled(false)
                    .scrollBounceBehavior(.basedOnSize, axes: .vertical)
                }
            }
        }
        }
        .navigationBarHidden(true)
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
    
    // MARK: - Header
    
    private var header: some View {
        GeometryReader { geometry in
            let spacing = AdaptiveSpacing(geometry: geometry)
            
            HStack(spacing: 0) {
                Spacer()
                
                // Title
                Text("Cooking Tips")
                    .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                    .adaptiveForegroundColor()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Spacer()
            }
            .padding(.horizontal, spacing.md)
        }
        .frame(height: 44)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
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
        .padding(12)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(white: AppTheme.cardDarkOpacity) : Color.white.opacity(AppTheme.cardLightOpacity))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            }
        }
    }
    
    // MARK: - Active Filters Pills
    
    private var activeFiltersPills: some View {
        FlowLayout(spacing: 8) {
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
        }
    }
    
    // MARK: - Compact List View
    
    private var compactListView: some View {
        VStack(spacing: 8) {
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
    
    // MARK: - Category Grid View
    
    private var categoryGridView: some View {
        VStack(spacing: 20) {
            ForEach(CookingTipCategory.allCases) { category in
                let categoryTips = tipsManager.tipsForCategory(category)
                    .filter { tip in
                        tipsManager.searchText.isEmpty ||
                        tip.title.localizedCaseInsensitiveContains(tipsManager.searchText) ||
                        tip.content.localizedCaseInsensitiveContains(tipsManager.searchText)
                    }
                
                if !categoryTips.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        // Category Header - Tappable to expand/collapse
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
                            HStack(spacing: 8) {
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
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
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
                        
                        // Tips in Category - Only show if expanded
                        if expandedCategories.contains(category.rawValue) {
                            VStack(spacing: 12) {
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
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 70))
                .adaptiveForegroundColor(opacity: 0.4)
            
            Text("No Tips Found")
                .font(.title2)
                .fontWeight(.bold)
                .adaptiveForegroundColor()
            
            Text("Try adjusting your filters or search terms")
                .font(.subheadline)
                .adaptiveForegroundColor(opacity: 0.7)
                .multilineTextAlignment(.center)
            
            Button(action: {
                tipsManager.clearFilters()
                HapticManager.shared.light()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
                    Text("Clear Filters")
                        .fontWeight(.semibold)
                }
                .adaptiveForegroundColor()
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(AppTheme.accentColor(for: selectedTheme))
                )
            }
        }
        .padding(40)
    }
    
    // MARK: - Helpers
    
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

// MARK: - Compact Tip Row

struct CompactTipRow: View {
    let tip: CookingTipModel
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Category Icon
                Image(systemName: tip.category.icon)
                    .font(.body)
                    .foregroundColor(colorForCategory(tip.category))
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(tip.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .adaptiveForegroundColor()
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                    
                    // Category and Difficulty
                    HStack(spacing: 8) {
                        Text(tip.category.rawValue)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: tip.difficulty.icon)
                                .font(.caption2)
                            Text(tip.difficulty.rawValue)
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                    }
                }
                
                Spacer(minLength: 8)
                
                // Favorite button
                Button(action: {
                    onToggleFavorite()
                }) {
                    Image(systemName: tip.isFavorite ? "heart.fill" : "heart")
                        .font(.body)
                        .foregroundColor(tip.isFavorite ? .pink : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(white: AppTheme.cardDarkOpacity) : Color.white.opacity(AppTheme.glassLightOpacity))
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

// MARK: - Tip Card

struct CookingTipCard: View {
    let tip: CookingTipModel
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with icon and favorite
                HStack(alignment: .top, spacing: 12) {
                    // Category icon with gradient background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [colorForCategory(tip.category).opacity(0.3), colorForCategory(tip.category).opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: tip.category.icon)
                            .font(.system(size: 22))
                            .foregroundColor(colorForCategory(tip.category))
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        // Title
                        Text(tip.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .adaptiveForegroundColor()
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Category and Difficulty badges
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "bookmark.fill")
                                    .font(.caption2)
                                Text(tip.category.rawValue)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(colorForCategory(tip.category))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(colorForCategory(tip.category).opacity(0.15))
                            )
                            
                            HStack(spacing: 4) {
                                Image(systemName: tip.difficulty.icon)
                                    .font(.caption2)
                                Text(tip.difficulty.rawValue)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.15))
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer(minLength: 4)
                    
                    // Favorite button
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
                
                // Divider
                Rectangle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity))
                    .frame(height: 1)
                
                // Preview of content
                Text(tip.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                
                // Tags
                if !tip.tags.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(tip.tags.prefix(3), id: \.self) { tag in
                            HStack(spacing: 4) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 8))
                                Text(tag)
                                    .font(.caption2)
                            }
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                            )
                        }
                    }
                }
                
                // Footer with chevron
                HStack {
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("Read More")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption)
                    }
                    .foregroundColor(colorForCategory(tip.category))
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? Color(white: AppTheme.cardDarkOpacity) : Color.white.opacity(AppTheme.cardLightOpacity))
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? AppTheme.shadowDarkOpacity : AppTheme.shadowLightOpacity), radius: 8, x: 0, y: 4)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: AppTheme.adaptiveShadow(for: colorScheme), radius: 8, x: 0, y: 4)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [colorForCategory(tip.category).opacity(0.3), colorForCategory(tip.category).opacity(0.0)],
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

// MARK: - Filter Pill

struct FilterPill: View {
    let text: String
    let color: Color
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
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
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color)
        )
    }
}

// MARK: - Filters Sheet

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
                    VStack(alignment: .leading, spacing: 24) {
                        // Favorites Toggle
                        filterCard {
                            Toggle(isOn: $showFavoritesOnly) {
                                HStack(spacing: 12) {
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
                        
                        // Category Filter
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.grid.2x2.fill")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                Text("Category")
                                    .font(.headline)
                                    .adaptiveForegroundColor()
                            }
                            
                            filterCard {
                                VStack(spacing: 8) {
                                    ForEach(CookingTipCategory.allCases) { category in
                                        Button(action: {
                                            selectedCategory = selectedCategory == category ? nil : category
                                            HapticManager.shared.light()
                                        }) {
                                            HStack(spacing: 12) {
                                                Image(systemName: category.icon)
                                                    .font(.body)
                                                    .frame(width: 24)
                                                
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
                                            .padding(.vertical, 8)
                                        }
                                        
                                        if category != CookingTipCategory.allCases.last {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Difficulty Filter
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                Text("Difficulty")
                                    .font(.headline)
                                    .adaptiveForegroundColor()
                            }
                            
                            filterCard {
                                VStack(spacing: 8) {
                                    ForEach(TipDifficulty.allCases, id: \.self) { difficulty in
                                        Button(action: {
                                            selectedDifficulty = selectedDifficulty == difficulty ? nil : difficulty
                                            HapticManager.shared.light()
                                        }) {
                                            HStack(spacing: 12) {
                                                Image(systemName: difficulty.icon)
                                                    .font(.body)
                                                    .frame(width: 24)
                                                
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
                                            .padding(.vertical, 8)
                                        }
                                        
                                        if difficulty != TipDifficulty.allCases.last {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
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
            .padding(16)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color(white: AppTheme.cardDarkOpacity) : Color.white.opacity(AppTheme.cardLightOpacity))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                }
            }
    }
}

#Preview {
    CookingTipsView()
        .environment(\.appTheme, .teal)
}
