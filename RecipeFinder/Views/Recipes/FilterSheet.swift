import SwiftUI

struct FilterSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    let categories: [String]
    let difficulties: [String]
    let availableTags: [String]
    let availableCuisines: [String]
    let availableIngredients: Set<String>
    @Binding var selectedCategories: Set<String>
    @Binding var selectedDifficulties: Set<String>
    @Binding var selectedCookTimes: Set<Int>
    @Binding var selectedDietaryFilters: Set<String>
    @Binding var selectedTags: Set<String>
    @Binding var selectedCuisines: Set<String>
    @Binding var sortOrder: SortOrder
    @Binding var ingredientSearchText: String
    @Binding var availableIngredientsOnly: Bool
    @Binding var showFavoritesOnly: Bool
    
    let cookTimeOptions = [15, 30, 45, 60, 90, 121]
    let dietaryOptions = ["Vegetarian", "Vegan", "Gluten-Free", "Dairy-Free", "Nut-Free", "Low-Carb", "Keto"]
    
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: AppTheme.spacing8, alignment: .center)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.spacing32) {
                        HStack {
                            Text("Sort")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            Spacer()
                            Picker("Sort", selection: $sortOrder) {
                                ForEach(SortOrder.allCases, id: \.self) { order in
                                    Text(order.rawValue).tag(order)
                                }
                            }
                            .pickerStyle(.menu)
                            .adaptiveForegroundColor()
                        }

                        Divider()
                            .background(Color.white.opacity(AppTheme.shadowDarkOpacity))

                        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                            HStack {
                                Text("Show Favorites Only")
                                    .font(.headline)
                                    .adaptiveForegroundColor()
                                
                                Spacer()
                                
                                Toggle("", isOn: $showFavoritesOnly)
                                    .tint(AppTheme.accentColor)
                            }
                        }
                        
                        Divider()
                            .background(Color.white.opacity(AppTheme.shadowDarkOpacity))
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                            HStack {
                                VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                                    Text("What Can I Make?")
                                        .font(.headline)

                                    Text("Recipes using ingredients you have")
                                        .font(.caption)
                                        .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $availableIngredientsOnly)
                                    .tint(AppTheme.accentColor)
                                    .disabled(availableIngredients.isEmpty)
                            }
                            
                            if availableIngredients.isEmpty {
                                Text("Add ingredients in Kitchen Inventory first")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Divider()
                            .background(Color.white.opacity(AppTheme.shadowDarkOpacity))
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                            Text("Search by Ingredient")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            TextField("E.g., Chicken, Tomato...", text: $ingredientSearchText)
                                .textFieldStyle(.plain)
                                .padding(AppTheme.spacing12)
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius10)
                                        .fill(Color.white.opacity(AppTheme.cardDarkOpacity))
                                )
                                .adaptiveForegroundColor()
                        }
                        
                        Divider()
                            .background(Color.white.opacity(AppTheme.shadowDarkOpacity))
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                            Text("Dietary Preferences")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            LazyVGrid(columns: columns, spacing: AppTheme.spacing8) {
                                ForEach(dietaryOptions, id: \.self) { diet in
                                    RecipeFilterButton(
                                        label: diet,
                                        isSelected: selectedDietaryFilters.contains(diet)
                                    ) {
                                        toggleSelection(diet, in: $selectedDietaryFilters)
                                    }
                                }
                            }
                        }
                        
                        Divider()
                            .background(Color.white.opacity(AppTheme.shadowDarkOpacity))
                        
                        if !availableTags.isEmpty {
                            VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                                Text("Tags")
                                    .font(.headline)
                                    .adaptiveForegroundColor()

                                LazyVGrid(columns: columns, spacing: AppTheme.spacing8) {
                                    ForEach(availableTags, id: \.self) { tag in
                                        RecipeFilterButton(
                                            label: tag,
                                            isSelected: selectedTags.contains(tag)
                                        ) {
                                            toggleSelection(tag, in: $selectedTags)
                                        }
                                    }
                                }
                            }

                            Divider()
                                .background(Color.white.opacity(AppTheme.shadowDarkOpacity))
                        }

                        if !availableCuisines.isEmpty {
                            VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                                Text("Cuisine")
                                    .font(.headline)
                                    .adaptiveForegroundColor()

                                LazyVGrid(columns: columns, spacing: AppTheme.spacing8) {
                                    ForEach(availableCuisines, id: \.self) { cuisine in
                                        RecipeFilterButton(
                                            label: cuisine,
                                            isSelected: selectedCuisines.contains(cuisine)
                                        ) {
                                            toggleSelection(cuisine, in: $selectedCuisines)
                                        }
                                    }
                                }
                            }

                            Divider()
                                .background(Color.white.opacity(AppTheme.shadowDarkOpacity))
                        }

                        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                            Text("Course / Category")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            LazyVGrid(columns: columns, spacing: AppTheme.spacing8) {
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
                            .background(Color.white.opacity(AppTheme.shadowDarkOpacity))
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                            Text("Difficulty")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            LazyVGrid(columns: columns, spacing: AppTheme.spacing8) {
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
                            .background(Color.white.opacity(AppTheme.shadowDarkOpacity))
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                            Text("Max Cooking Time")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            LazyVGrid(columns: columns, spacing: AppTheme.spacing8) {
                                ForEach(cookTimeOptions, id: \.self) { time in
                                    RecipeFilterButton(
                                        label: time > 120 ? "> 120 min" : "≤ \(time) min",
                                        isSelected: selectedCookTimes.contains(time)
                                    ) {
                                        toggleSelection(time, in: $selectedCookTimes)
                                    }
                                }
                            }
                        }
                    }
                    .padding(AppTheme.spacing24)
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
                        selectedDietaryFilters.removeAll()
                        selectedTags.removeAll()
                        selectedCuisines.removeAll()
                        ingredientSearchText = ""
                        availableIngredientsOnly = false
                        showFavoritesOnly = false
                        sortOrder = .nameAZ
                    }
                    .adaptiveForegroundColor()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .adaptiveForegroundColor()
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
