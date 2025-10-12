import SwiftUI

struct RecipeSearchView: View {
    @Binding var recipes: [RecipeModel]
    @State private var searchText = ""
    @State private var viewMode: RecipeViewMode = .list
    @State private var showFilters = false
    @State private var selectedCategory: String? = nil
    @State private var selectedDifficulty: String? = nil
    @State private var maxCookTime: Int? = nil
    @Environment(\.colorScheme) var colorScheme

    var filteredRecipes: [RecipeModel] {
        var results = recipes
        
        // Search filter
        if !searchText.isEmpty {
            results = results.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Category filter
        if let category = selectedCategory {
            results = results.filter { $0.category == category }
        }
        
        // Difficulty filter
        if let difficulty = selectedDifficulty {
            results = results.filter { $0.difficulty == difficulty }
        }
        
        // Cook time filter
        if let maxTime = maxCookTime {
            results = results.filter { recipe in
                let time = extractMinutes(from: recipe.cookingTime)
                return time <= maxTime
            }
        }
        
        return results
    }
    
    var activeFilterCount: Int {
        var count = 0
        if selectedCategory != nil { count += 1 }
        if selectedDifficulty != nil { count += 1 }
        if maxCookTime != nil { count += 1 }
        return count
    }
    
    var categories: [String] {
        Array(Set(recipes.map { $0.category })).sorted()
    }
    
    var difficulties: [String] {
        Array(Set(recipes.map { $0.difficulty })).sorted()
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
                                    if let category = selectedCategory {
                                        FilterChip(label: category, icon: "fork.knife") {
                                            selectedCategory = nil
                                        }
                                    }
                                    
                                    if let difficulty = selectedDifficulty {
                                        FilterChip(label: difficulty, icon: "chart.bar.fill") {
                                            selectedDifficulty = nil
                                        }
                                    }
                                    
                                    if let time = maxCookTime {
                                        FilterChip(label: "≤ \(time) min", icon: "clock.fill") {
                                            maxCookTime = nil
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
                    
                    ScrollView {
                        if viewMode == .list {
                            LazyVStack(spacing: 10) {
                                ForEach(filteredRecipes) { recipe in
                                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
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
                                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showFilters) {
                FilterSheet(
                    categories: categories,
                    difficulties: difficulties,
                    selectedCategory: $selectedCategory,
                    selectedDifficulty: $selectedDifficulty,
                    maxCookTime: $maxCookTime
                )
            }
        }
    }
    
    private func clearAllFilters() {
        withAnimation {
            selectedCategory = nil
            selectedDifficulty = nil
            maxCookTime = nil
        }
    }
}

// MARK: - Filter Chip Component
struct FilterChip: View {
    let label: String
    let icon: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(AppTheme.accentColor.opacity(0.9))
        )
    }
}

// MARK: - Filter Sheet
struct FilterSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let categories: [String]
    let difficulties: [String]
    @Binding var selectedCategory: String?
    @Binding var selectedDifficulty: String?
    @Binding var maxCookTime: Int?
    
    let cookTimeOptions = [15, 30, 45, 60, 90]
    
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
                                    FilterButton(
                                        label: category,
                                        isSelected: selectedCategory == category
                                    ) {
                                        selectedCategory = selectedCategory == category ? nil : category
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
                                    FilterButton(
                                        label: difficulty,
                                        isSelected: selectedDifficulty == difficulty
                                    ) {
                                        selectedDifficulty = selectedDifficulty == difficulty ? nil : difficulty
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
                                    FilterButton(
                                        label: "≤ \(time) min",
                                        isSelected: maxCookTime == time
                                    ) {
                                        maxCookTime = maxCookTime == time ? nil : time
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        selectedCategory = nil
                        selectedDifficulty = nil
                        maxCookTime = nil
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
}

// MARK: - Filter Button Component
struct FilterButton: View {
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

