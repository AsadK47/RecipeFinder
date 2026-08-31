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
        CookingTipCategoryGrid(
            tipsManager: tipsManager,
            expandedCategories: $expandedCategories,
            selectedTheme: selectedTheme,
            colorScheme: colorScheme,
            onSelectTip: { tip in
                selectedTip = tip
                HapticManager.shared.light()
            }
        )
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
}

#Preview {
    CookingTipsView()
        .environment(\.appTheme, .teal)
}
