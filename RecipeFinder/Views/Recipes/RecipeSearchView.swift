import SwiftUI

struct RecipeSearchView: View {
    @Binding var recipes: [RecipeModel]
    @ObservedObject var shoppingListManager: ShoppingListManager
    @State private var searchText = ""
    @State private var viewMode: RecipeViewMode = .list
    @State private var showFilters = false
    @State private var selectedCategories: Set<String> = []
    @State private var selectedDifficulties: Set<String> = []
    @State private var selectedCookTimes: Set<Int> = []
    @Environment(\.colorScheme) var colorScheme

    var filteredRecipes: [RecipeModel] {
        var results = recipes
        
        // Search filter
        if !searchText.isEmpty {
            results = results.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Category filter (OR logic - show if matches any selected category)
        if !selectedCategories.isEmpty {
            results = results.filter { selectedCategories.contains($0.category) }
        }
        
        // Difficulty filter (OR logic - show if matches any selected difficulty)
        if !selectedDifficulties.isEmpty {
            results = results.filter { selectedDifficulties.contains($0.difficulty) }
        }
        
        // Cook time filter (OR logic - show if under any selected time limit)
        if !selectedCookTimes.isEmpty {
            results = results.filter { recipe in
                let time = extractMinutes(from: recipe.cookingTime)
                return selectedCookTimes.contains { time <= $0 }
            }
        }
        
        return results
    }
    
    var activeFilterCount: Int {
        return selectedCategories.count + selectedDifficulties.count + selectedCookTimes.count
    }
    
    var categories: [String] {
        let validCategories = ["Appetizer", "Main Course", "Side", "Dessert", "Breakfast", "Soup", "Drink", "Bread"]
        return Array(Set(recipes.map { $0.category }))
            .filter { validCategories.contains($0) }
            .sorted()
    }
    
    var difficulties: [String] {
        ["Easy", "Medium", "Hard"]
    }
    
    private func extractMinutes(from timeString: String) -> Int {
        let components = timeString.components(separatedBy: " ")
        if let minutes = components.first, let value = Int(minutes) {
            return value
        }
        return 0
    }
    
    var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: viewMode.columns)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        HStack {
                            // Filter button
                            Button(action: { showFilters.toggle() }) {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(
                                            Circle()
                                                .fill(.ultraThinMaterial)
                                        )
                                    
                                    if activeFilterCount > 0 {
                                        Text("\(activeFilterCount)")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .frame(width: 18, height: 18)
                                            .background(Circle().fill(Color.red))
                                            .offset(x: 4, y: -4)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Text("Recipe Finder")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Menu {
                                ForEach(RecipeViewMode.allCases, id: \.self) { mode in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3)) {
                                            viewMode = mode
                                        }
                                    }) {
                                        Label(mode.rawValue, systemImage: mode.icon)
                                    }
                                }
                            } label: {
                                Image(systemName: viewMode.icon)
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        ModernSearchBar(text: $searchText, placeholder: "What would you like to eat...?")
                            .padding(.horizontal, 20)
                        
                        // Active filters chips
                        if activeFilterCount > 0 {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Array(selectedCategories), id: \.self) { category in
                                        FilterChip(label: category, icon: "fork.knife") {
                                            selectedCategories.remove(category)
                                        }
                                    }
                                    
                                    ForEach(Array(selectedDifficulties), id: \.self) { difficulty in
                                        FilterChip(label: difficulty, icon: "chart.bar.fill") {
                                            selectedDifficulties.remove(difficulty)
                                        }
                                    }
                                    
                                    ForEach(Array(selectedCookTimes), id: \.self) { time in
                                        FilterChip(label: "≤ \(time) min", icon: "clock.fill") {
                                            selectedCookTimes.remove(time)
                                        }
                                    }
                                    
                                    Button(action: clearAllFilters) {
                                        Text("Clear All")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(Color.red.opacity(0.8))
                                            )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.top, 20)
                    
                    if filteredRecipes.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            if viewMode == .list {
                                LazyVStack(spacing: 10) {
                                    ForEach(filteredRecipes) { recipe in
                                        NavigationLink(destination: RecipeDetailView(recipe: recipe, shoppingListManager: shoppingListManager)) {
                                            RecipeCard(recipe: recipe, viewMode: .list)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                            } else {
                                LazyVGrid(columns: gridColumns, spacing: 12) {
                                    ForEach(filteredRecipes) { recipe in
                                        NavigationLink(destination: RecipeDetailView(recipe: recipe, shoppingListManager: shoppingListManager)) {
                                            CompactRecipeCard(recipe: recipe)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .padding(.bottom, 20)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showFilters) {
                FilterSheet(
                    categories: categories,
                    difficulties: difficulties,
                    selectedCategories: $selectedCategories,
                    selectedDifficulties: $selectedDifficulties,
                    selectedCookTimes: $selectedCookTimes
                )
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.5))
            
            Text("No recipes found")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Try adjusting your filters or search")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            if activeFilterCount > 0 {
                Button(action: clearAllFilters) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Clear All Filters")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }
    
    private func clearAllFilters() {
        withAnimation {
            selectedCategories.removeAll()
            selectedDifficulties.removeAll()
            selectedCookTimes.removeAll()
        }
    }
}

// MARK: - Filter Sheet
struct FilterSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let categories: [String]
    let difficulties: [String]
    @Binding var selectedCategories: Set<String>
    @Binding var selectedDifficulties: Set<String>
    @Binding var selectedCookTimes: Set<Int>
    
    let cookTimeOptions = [15, 30, 45, 60, 90, 120]
    
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 8, alignment: .center)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Category Filter
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Course / Category")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: columns, spacing: 8) {
                                ForEach(categories, id: \.self) { category in
                                    RecipeFilterButton(
                                        label: category,
                                        isSelected: selectedCategories.contains(category)
                                    ) {
                                        toggleSelection(category, in: $selectedCategories)
                                    }
                                }
                            }
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        // Difficulty Filter
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Difficulty")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: columns, spacing: 8) {
                                ForEach(difficulties, id: \.self) { difficulty in
                                    RecipeFilterButton(
                                        label: difficulty,
                                        isSelected: selectedDifficulties.contains(difficulty)
                                    ) {
                                        toggleSelection(difficulty, in: $selectedDifficulties)
                                    }
                                }
                            }
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        // Cook Time Filter
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Max Cooking Time")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: columns, spacing: 8) {
                                ForEach(cookTimeOptions, id: \.self) { time in
                                    RecipeFilterButton(
                                        label: "≤ \(time) min",
                                        isSelected: selectedCookTimes.contains(time)
                                    ) {
                                        toggleSelection(time, in: $selectedCookTimes)
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        selectedCategories.removeAll()
                        selectedDifficulties.removeAll()
                        selectedCookTimes.removeAll()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func toggleSelection<T: Hashable>(_ item: T, in set: Binding<Set<T>>) {
        if set.wrappedValue.contains(item) {
            set.wrappedValue.remove(item)
        } else {
            set.wrappedValue.insert(item)
        }
    }
}

// MARK: - Recipe Filter Button Component (specific styling for recipe filters)
struct RecipeFilterButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    Capsule()
                        .fill(isSelected ? AppTheme.accentColor : Color.white.opacity(0.15))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
