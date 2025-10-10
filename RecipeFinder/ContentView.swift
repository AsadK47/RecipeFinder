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
    // Instagram-inspired gradient colors
    static let gradientStart = Color(red: 131/255, green: 58/255, blue: 180/255) // Purple
    static let gradientMiddle = Color(red: 253/255, green: 29/255, blue: 29/255) // Red
    static let gradientEnd = Color(red: 252/255, green: 176/255, blue: 69/255) // Orange
    
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

// Recipe Image with Gradient Overlay
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
        ZStack(alignment: .bottomLeading) {
            Image(hasSpecificImage ? imageName! : "food_icon")
                .resizable()
                .scaledToFill()
                .frame(height: height)
                .clipped()
            
            // Gradient overlay for better text readability
            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Camera icon for fallback
            if !hasSpecificImage {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                            .padding()
                    }
                }
            }
        }
        .cornerRadius(20)
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

// Modern Ingredient Button
struct IngredientButton: View {
    let ingredient: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(ingredient)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(AppTheme.accentColor.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// Scale Button Style for Better Interaction
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

// Shopping List Input Bar
struct ShoppingListInputBar: View {
    @Binding var text: String
    let onAdd: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(AppTheme.accentColor)
                
                TextField("Add item...", text: $text)
                    .focused($isFocused)
                    .onSubmit(onAdd)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            Button(action: onAdd) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
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
            }
            .disabled(text.isEmpty)
            .opacity(text.isEmpty ? 0.5 : 1.0)
        }
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
    @Environment(\.colorScheme) var colorScheme

    var filteredRecipes: [RecipeModel] {
        searchText.isEmpty ? recipes : recipes.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        Text("Recipe Finder")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
                        ModernSearchBar(text: $searchText, placeholder: "What would you like to eat...?")
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredRecipes) { recipe in
                                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                    RecipeCard(recipe: recipe)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

// Recipe Card Component
struct RecipeCard: View {
    let recipe: RecipeModel
    
    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                RecipeImageView(imageName: recipe.imageName, height: 100)
                    .frame(width: 100, height: 100)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 16) {
                        Label(recipe.prepTime, systemImage: "clock")
                        Label(recipe.difficulty, systemImage: "chart.bar")
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                    
                    Text(recipe.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AppTheme.accentColor.opacity(0.2))
                        )
                        .foregroundColor(AppTheme.accentColor)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
        }
    }
}

// MARK: - Ingredient Search View
struct IngredientSearchView: View {
    @Binding var recipes: [RecipeModel]
    @State private var searchText = ""
    @State private var expandedSections: Set<String> = []
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        Text("Search by Ingredient")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
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
            LazyVStack(spacing: 16) {
                ForEach(filteredRecipes) { recipe in
                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                        RecipeCard(recipe: recipe)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
}

// MARK: - Recipe Detail View
struct RecipeDetailView: View {
    @State private var recipe: RecipeModel
    @State private var ingredientsState: [Bool]
    @Environment(\.colorScheme) var colorScheme
    
    init(recipe: RecipeModel) {
        self.recipe = recipe
        _ingredientsState = State(initialValue: Array(repeating: false, count: recipe.ingredients.count))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                RecipeImageView(imageName: recipe.imageName, height: 300)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text(recipe.name)
                        .font(.system(size: 28, weight: .bold))
                    
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
                    
                    CardView {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Servings")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                                Text("\(recipe.currentServings)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            Stepper("", value: $recipe.currentServings, in: 1...100)
                                .labelsHidden()
                        }
                        .padding()
                    }
                    .onChange(of: recipe.currentServings) { oldValue, newValue in
                        adjustIngredients(for: newValue)
                    }
                    
                    sectionView(title: "Ingredients", icon: "leaf.fill") {
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
                    
                    if !recipe.prePrepInstructions.isEmpty {
                        sectionView(title: "Pre-Prep", icon: "list.clipboard") {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(recipe.prePrepInstructions.indices, id: \.self) { index in
                                    instructionRow(number: index + 1, text: recipe.prePrepInstructions[index])
                                }
                            }
                        }
                    }
                    
                    sectionView(title: "Instructions", icon: "text.alignleft") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(recipe.instructions.indices, id: \.self) { index in
                                instructionRow(number: index + 1, text: recipe.instructions[index])
                            }
                        }
                    }
                    
                    if !recipe.notes.isEmpty {
                        sectionView(title: "Notes", icon: "note.text") {
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
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(AppTheme.backgroundGradient(for: colorScheme).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func sectionView<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.accentColor)
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            CardView {
                content()
                    .padding()
            }
        }
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
                .fixedSize(horizontal: false, vertical: true)
        }
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
    @Environment(\.colorScheme) var colorScheme
    
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
                                    settingRow(icon: "moon.fill", title: "Dark Mode", color: .purple)
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
