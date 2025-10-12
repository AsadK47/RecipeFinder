//
//  ContentView.swift
//  RecipeFinder
//
//  Created by asad.e.khan on 10/12/2024.
//

import SwiftUI
import SwiftData
import ConfettiSwiftUI

// MARK: - Theme Configuration
struct AppTheme {
    // Purple to Blue to Teal gradient
    static let gradientStart = Color(red: 131/255, green: 58/255, blue: 180/255) // Purple
    static let gradientMiddle = Color(red: 88/255, green: 86/255, blue: 214/255) // Blue-Purple
    static let gradientEnd = Color(red: 64/255, green: 224/255, blue: 208/255) // Turquoise/Teal
    
    static let cardBackground = Color.white.opacity(0.95)
    static let cardBackgroundDark = Color(white: 0.15)
    static let accentColor = Color(red: 131/255, green: 58/255, blue: 180/255)
    static let secondaryText = Color.gray
    static let dividerColor = Color.gray.opacity(0.3)
    
    static func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [gradientStart, gradientMiddle, gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Models
struct ShoppingListItem: Identifiable {
    let id = UUID()
    var name: String
    var isChecked: Bool
    var quantity: Int
}

// MARK: - Reusable Components

// Modern Card Container
struct CardView<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
    }
}

// Glassmorphic Card
struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
            )
    }
}

// MARK: - View Mode Enum
enum RecipeViewMode: String, CaseIterable {
    case list = "List"
    case grid2 = "Grid 2x2"
    case grid3 = "Grid 3x3"
    var columns: Int {
        switch self {
        case .list: return 1
        case .grid2: return 2
        case .grid3: return 3
        }
    }
    
    var icon: String {
        switch self {
        case .list: return "rectangle.grid.1x2"
        case .grid2: return "square.grid.2x2"
        case .grid3: return "square.grid.3x3"
        }
    }
}

// Recipe Card Component with Grid Support and Bubble Style
struct RecipeCard: View {
    let recipe: RecipeModel
    let viewMode: RecipeViewMode
    
    init(recipe: RecipeModel, viewMode: RecipeViewMode = .list) {
        self.recipe = recipe
        self.viewMode = viewMode
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Image on the left
            RecipeImageView(
                imageName: recipe.imageName,
                height: viewMode == .list ? 120 : (viewMode == .grid2 ? 100 : 80)
            )
            .frame(width: viewMode == .list ? 120 : (viewMode == .grid2 ? 100 : 80))
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 24,
                    bottomLeadingRadius: 24
                )
            )
            
            // Content in the middle
            VStack(alignment: .leading, spacing: viewMode == .grid3 ? 4 : 8) {
                Text(recipe.name)
                    .font(viewMode == .grid3 ? .caption : .headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if viewMode != .grid3 {
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(recipe.prepTime)
                                .font(.caption)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar")
                                .font(.caption)
                            Text(recipe.difficulty)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(AppTheme.secondaryText)
                }
                
                if viewMode == .list {
                    Text(recipe.category)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(AppTheme.accentColor)
                        )
                        .foregroundColor(.white)
                } else if viewMode == .grid2 {
                    HStack(spacing: 4) {
                        Image(systemName: "fork.knife")
                            .font(.caption2)
                        Text(recipe.category)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(AppTheme.accentColor)
                } else {
                    // Grid 3 - minimal info
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(recipe.prepTime)
                            .font(.caption2)
                    }
                    .foregroundColor(AppTheme.secondaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, viewMode == .grid3 ? 8 : 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Chevron on the right
            if viewMode == .list {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.accentColor.opacity(0.6))
                    .padding(.trailing, 16)
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }
}

// Recipe Image Component
struct RecipeImageView: View {
    let imageName: String?
    let height: CGFloat
    
    init(imageName: String?, height: CGFloat = 200) {
        self.imageName = imageName
        self.height = height
    }
    
    private var hasSpecificImage: Bool {
        if let imageName = imageName {
            return UIImage(named: imageName) != nil
        }
        return false
    }
    
    var body: some View {
        ZStack {
            if hasSpecificImage {
                Image(imageName!)
                    .resizable()
                    .scaledToFill()
                    .frame(height: height)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Image("food_icon")
                    .resizable()
                    .scaledToFill()
                    .frame(height: height)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                            )
                    )
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }
}

// Modern Search Bar
struct ModernSearchBar: View {
    @Binding var text: String
    var placeholder: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField(placeholder, text: $text)
                    .focused($isFocused)
                    .autocorrectionDisabled()
                
                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            if isFocused {
                Button("Cancel") {
                    text = ""
                    isFocused = false
                }
                .foregroundColor(AppTheme.accentColor)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: isFocused)
    }
}

// Info Pair with Modern Styling
struct InfoPairView: View {
    let label1: String
    let value1: String
    let icon1: String
    let label2: String
    let value2: String
    let icon2: String
    
    var body: some View {
        HStack(spacing: 0) {
            InfoItem(icon: icon1, label: label1, value: value1)
            
            Divider()
                .frame(height: 60)
                .padding(.horizontal)
            
            InfoItem(icon: icon2, label: label2, value: value2)
        }
    }
}

struct InfoItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppTheme.accentColor)
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
}

// Ingredient Row with Modern Checkbox
struct IngredientRowView: View {
    let ingredient: Ingredient
    let isChecked: Bool
    let toggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { withAnimation(.spring(response: 0.3)) { toggle() } }) {
                ZStack {
                    Circle()
                        .strokeBorder(isChecked ? AppTheme.accentColor : Color.gray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(AppTheme.accentColor))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(isChecked)
                    .foregroundColor(isChecked ? .gray : .primary)
                
                Text("\(String(format: "%.2f", ingredient.quantity)) \(ingredient.unit)")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Ingredient Button Component
struct IngredientButton: View {
    let ingredient: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(ingredient)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.accentColor.opacity(0.6))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Shopping List Input Bar
struct ShoppingListInputBar: View {
    @Binding var text: String
    var onAdd: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(AppTheme.accentColor)
                
                TextField("Add item...", text: $text)
                    .focused($isFocused)
                    .autocorrectionDisabled()
                    .onSubmit {
                        onAdd()
                    }
                
                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            if !text.isEmpty {
                Button(action: onAdd) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(AppTheme.accentColor)
                        )
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: text.isEmpty)
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @State private var recipes: [RecipeModel] = []
    @State private var selectedTab: Int = 0
    @State private var shoppingListItems: [ShoppingListItem] = []
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                RecipeSearchView(recipes: $recipes)
                    .tabItem {
                        Label("Recipes", systemImage: "book.fill")
                    }
                    .tag(0)

                IngredientSearchView(recipes: $recipes)
                    .tabItem {
                        Label("Ingredients", systemImage: "leaf.fill")
                    }
                    .tag(1)

                ShoppingListView(shoppingListItems: $shoppingListItems)
                    .tabItem {
                        Label("Shopping", systemImage: "cart.fill")
                    }
                    .tag(2)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(3)
            }
            .tint(AppTheme.accentColor)
        }
        .onAppear(perform: loadRecipes)
    }

    private func loadRecipes() {
        PersistenceController.shared.clearDatabase()
        PersistenceController.shared.populateDatabase()
        recipes = PersistenceController.shared.fetchRecipes()
    }
}

// MARK: - Recipe Search View
struct RecipeSearchView: View {
    @Binding var recipes: [RecipeModel]
    @State private var searchText = ""
    @State private var viewMode: RecipeViewMode = .list
    @Environment(\.colorScheme) var colorScheme

    var filteredRecipes: [RecipeModel] {
        searchText.isEmpty ? recipes : recipes.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 16), count: viewMode.columns)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        HStack {
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
                        .padding(.horizontal)
                        
                        ModernSearchBar(text: $searchText, placeholder: "What would you like to eat...?")
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    ScrollView {
                        if viewMode == .list {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredRecipes) { recipe in
                                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                        RecipeCard(recipe: recipe, viewMode: .list)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
                        } else {
                            LazyVGrid(columns: gridColumns, spacing: 16) {
                                ForEach(filteredRecipes) { recipe in
                                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                        RecipeCard(recipe: recipe, viewMode: viewMode)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Ingredient Search View
struct IngredientSearchView: View {
    @Binding var recipes: [RecipeModel]
    @State private var searchText = ""
    @State private var expandedSections: Set<String> = []
    @State private var viewMode: RecipeViewMode = .list
    @Environment(\.colorScheme) var colorScheme
    
    var groupedIngredients: [(key: String, value: [String])] {
        Dictionary(grouping: Set(recipes.flatMap { $0.ingredients.map { $0.name } })) {
            String($0.prefix(1).uppercased())
        }
        .mapValues { $0.sorted() }
        .sorted { $0.key < $1.key }
    }

    var filteredRecipes: [RecipeModel] {
        searchText.isEmpty ? recipes : recipes.filter { recipe in
            recipe.ingredients.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 16), count: viewMode.columns)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Search by Ingredient")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            if !searchText.isEmpty {
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
                        }
                        .padding(.horizontal)
                        
                        ModernSearchBar(text: $searchText, placeholder: "What's in the fridge...?")
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    if searchText.isEmpty {
                        ingredientAlphabetView
                    } else {
                        recipeResultsView
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
    
    private var ingredientAlphabetView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(groupedIngredients, id: \.key) { letter, ingredients in
                    GlassCard {
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedSections.contains(letter) },
                                set: { isExpanded in
                                    withAnimation(.spring(response: 0.3)) {
                                        if isExpanded {
                                            expandedSections.insert(letter)
                                        } else {
                                            expandedSections.remove(letter)
                                        }
                                    }
                                }
                            )
                        ) {
                            VStack(spacing: 10) {
                                ForEach(ingredients, id: \.self) { ingredient in
                                    IngredientButton(ingredient: ingredient) {
                                        searchText = ingredient
                                    }
                                }
                            }
                            .padding(.top, 10)
                        } label: {
                            HStack {
                                Text(letter)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppTheme.accentColor)
                                
                                Text("\(ingredients.count) ingredients")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                                
                                Spacer()
                            }
                        }
                        .padding()
                    }
                }
            }
            .padding()
        }
    }
    
    private var recipeResultsView: some View {
        ScrollView {
            if viewMode == .list {
                LazyVStack(spacing: 16) {
                    ForEach(filteredRecipes) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            RecipeCard(recipe: recipe, viewMode: .list)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            } else {
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(filteredRecipes) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            RecipeCard(recipe: recipe, viewMode: viewMode)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Recipe Detail View
struct RecipeDetailView: View {
    @State private var recipe: RecipeModel
    @State private var ingredientsState: [Bool]
    @State private var expandedSections: Set<String> = ["Ingredients", "Pre-Prep", "Instructions", "Notes"]
    @Environment(\.colorScheme) var colorScheme
    
    init(recipe: RecipeModel) {
        self.recipe = recipe
        _ingredientsState = State(initialValue: Array(repeating: false, count: recipe.ingredients.count))
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Title directly on gradient
                    Text(recipe.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    
                    // All info cards with consistent spacing
                    VStack(spacing: 16) {
                        CardView {
                            InfoPairView(
                                label1: "Prep time", value1: recipe.prepTime, icon1: "clock",
                                label2: "Cook time", value2: recipe.cookingTime, icon2: "flame"
                            )
                            .padding()
                        }
                        
                        CardView {
                            InfoPairView(
                                label1: "Difficulty", value1: recipe.difficulty, icon1: "chart.bar",
                                label2: "Category", value2: recipe.category, icon2: "fork.knife"
                            )
                            .padding()
                        }
                        
                        // Updated Servings Card with Icon
                        CardView {
                            HStack {
                                VStack(spacing: 8) {
                                    Image(systemName: "person.2.fill")
                                        .font(.title2)
                                        .foregroundColor(AppTheme.accentColor)
                                    Text("Servings")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.secondaryText)
                                    Text("\(recipe.currentServings)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                
                                Divider()
                                    .frame(height: 60)
                                    .padding(.horizontal)
                                
                                HStack(spacing: 12) {
                                    Button(action: {
                                        if recipe.currentServings > 1 {
                                            recipe.currentServings -= 1
                                        }
                                    }) {
                                        Image(systemName: "minus")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                            .background(
                                                Circle()
                                                    .fill(AppTheme.accentColor)
                                            )
                                    }
                                    
                                    Button(action: {
                                        recipe.currentServings += 1
                                    }) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                            .background(
                                                Circle()
                                                    .fill(AppTheme.accentColor)
                                            )
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding()
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Collapsible Ingredients section
                    collapsibleSection(title: "Ingredients", icon: "leaf.fill") {
                        VStack(spacing: 12) {
                            ForEach(recipe.ingredients.indices, id: \.self) { index in
                                IngredientRowView(
                                    ingredient: recipe.ingredients[index],
                                    isChecked: ingredientsState[index],
                                    toggle: { ingredientsState[index].toggle() }
                                )
                            }
                        }
                    }
                    
                    // Collapsible Pre-prep section
                    if !recipe.prePrepInstructions.isEmpty {
                        collapsibleSection(title: "Pre-Prep", icon: "list.clipboard") {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(recipe.prePrepInstructions.indices, id: \.self) { index in
                                    instructionRow(number: index + 1, text: recipe.prePrepInstructions[index])
                                }
                            }
                        }
                    }
                    
                    // Collapsible Instructions section
                    collapsibleSection(title: "Instructions", icon: "text.alignleft") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(recipe.instructions.indices, id: \.self) { index in
                                instructionRow(number: index + 1, text: recipe.instructions[index])
                            }
                        }
                    }
                    
                    // Collapsible Notes section
                    if !recipe.notes.isEmpty {
                        collapsibleSection(title: "Notes", icon: "note.text") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(recipe.notes.split(separator: "."), id: \.self) { sentence in
                                    if !sentence.trimmingCharacters(in: .whitespaces).isEmpty {
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "circle.fill")
                                                .font(.system(size: 6))
                                                .foregroundColor(AppTheme.accentColor)
                                                .padding(.top, 6)
                                            Text(sentence.trimmingCharacters(in: .whitespaces))
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: recipe.currentServings) { oldValue, newValue in
            adjustIngredients(for: newValue)
        }
    }
    
    // COLLAPSIBLE section view with expand/collapse animation
    private func collapsibleSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        let isExpanded = expandedSections.contains(title)
        
        return VStack(alignment: .leading, spacing: 12) {
            // Tappable header
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if isExpanded {
                        expandedSections.remove(title)
                    } else {
                        expandedSections.insert(title)
                    }
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.title3)
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Chevron indicator
                    Image(systemName: "chevron.down")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.8))
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .animation(.spring(response: 0.3), value: isExpanded)
                }
                .padding(.top, 24)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Collapsible content
            if isExpanded {
                CardView {
                    content()
                        .frame(maxWidth: .infinity, alignment: .leading) // Force full width
                        .padding(20)
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
            }
        }
        .frame(maxWidth: .infinity) // Ensure container fills width
        .padding(.horizontal, 20)
    }
    
    private func instructionRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.gradientStart, AppTheme.gradientMiddle],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading) // Ensure full width alignment
    }
    
    private func adjustIngredients(for newServings: Int) {
        let factor = Double(newServings) / Double(recipe.baseServings)
        recipe.ingredients = recipe.ingredients.map { ingredient in
            var updatedIngredient = ingredient
            updatedIngredient.quantity = ingredient.baseQuantity * factor
            return updatedIngredient
        }
    }
}

// MARK: - Shopping List View
struct ShoppingListView: View {
    @Binding var shoppingListItems: [ShoppingListItem]
    @State private var newItem: String = ""
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        Text("Shopping List")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
                        ShoppingListInputBar(text: $newItem, onAdd: addItem)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    if shoppingListItems.isEmpty {
                        emptyStateView
                    } else {
                        shoppingListContent
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.5))
            
            Text("Your shopping list is empty")
                .font(.title3)
                .foregroundColor(.white)
            
            Text("Add items to get started")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxHeight: .infinity)
    }
    
    private var shoppingListContent: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 12) {
                ForEach(shoppingListItems.indices, id: \.self) { index in
                    GlassCard {
                        HStack(spacing: 16) {
                            Button(action: { toggleItem(at: index) }) {
                                ZStack {
                                    Circle()
                                        .strokeBorder(
                                            shoppingListItems[index].isChecked ? AppTheme.accentColor : Color.gray,
                                            lineWidth: 2
                                        )
                                        .frame(width: 28, height: 28)
                                    
                                    if shoppingListItems[index].isChecked {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: 28, height: 28)
                                            .background(Circle().fill(AppTheme.accentColor))
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(shoppingListItems[index].name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .strikethrough(shoppingListItems[index].isChecked)
                                    .foregroundColor(shoppingListItems[index].isChecked ? .gray : .primary)
                                
                                if shoppingListItems[index].quantity > 0 {
                                    Text("Quantity: \(shoppingListItems[index].quantity)")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                            }
                            
                            Spacer()
                            
                            Stepper("", value: Binding(
                                get: { shoppingListItems[index].quantity },
                                set: { shoppingListItems[index].quantity = $0 }
                            ), in: 0...100)
                            .labelsHidden()
                        }
                        .padding()
                    }
                    .transition(.scale.combined(with: .opacity))
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation {
                                _ = shoppingListItems.remove(at: index)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func addItem() {
        guard !newItem.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        withAnimation(.spring(response: 0.3)) {
            shoppingListItems.append(ShoppingListItem(name: newItem, isChecked: false, quantity: 1))
            newItem = ""
        }
    }

    private func toggleItem(at index: Int) {
        withAnimation(.spring(response: 0.3)) {
            shoppingListItems[index].isChecked.toggle()
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @State private var confettiTrigger: Int = 0
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @Environment(\.colorScheme) var colorScheme
    
    enum AppearanceMode: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
        
        var icon: String {
            switch self {
            case .system: return "circle.lefthalf.filled"
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Settings")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            CardView {
                                VStack(alignment: .leading, spacing: 16) {
                                    settingRow(icon: "bell.fill", title: "Notifications", color: .orange)
                                    
                                    Divider()
                                    
                                    // Dark Mode Toggle with Picker
                                    HStack(spacing: 16) {
                                        Image(systemName: appearanceMode.icon)
                                            .foregroundColor(.purple)
                                            .frame(width: 30)
                                        
                                        Text("Appearance")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                        
                                        Menu {
                                            Picker("Appearance", selection: $appearanceMode) {
                                                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                                    Label(mode.rawValue, systemImage: mode.icon)
                                                        .tag(mode)
                                                }
                                            }
                                        } label: {
                                            HStack(spacing: 6) {
                                                Text(appearanceMode.rawValue)
                                                    .font(.subheadline)
                                                    .foregroundColor(AppTheme.accentColor)
                                                Image(systemName: "chevron.up.chevron.down")
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color(.systemGray6))
                                            )
                                        }
                                    }
                                    
                                    Divider()
                                    settingRow(icon: "globe", title: "Language", color: .blue)
                                }
                                .padding()
                            }
                            
                            CardView {
                                VStack(alignment: .leading, spacing: 16) {
                                    settingRow(icon: "person.fill", title: "Account", color: .green)
                                    Divider()
                                    settingRow(icon: "lock.fill", title: "Privacy", color: .red)
                                }
                                .padding()
                            }
                            
                            Button(action: { confettiTrigger += 1 }) {
                                HStack {
                                    Image(systemName: "party.popper.fill")
                                    Text("Celebrate!")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [AppTheme.gradientStart, AppTheme.gradientMiddle],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                            }
                            .confettiCannon(
                                trigger: $confettiTrigger,
                                num: 50,
                                radius: 500.0
                            )
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(appearanceMode == .system ? nil : (appearanceMode == .light ? .light : .dark))
    }
    
    private func settingRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
    }
}

#Preview {
    ContentView()
}
