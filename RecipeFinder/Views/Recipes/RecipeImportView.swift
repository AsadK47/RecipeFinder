import SwiftUI

struct RecipeImportView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @StateObject private var importer = RecipeImporter()
    @State private var urlText = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var showRecipeWizard = false
    
    var onImport: (RecipeModel) -> Void
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                    
                    Text("Import Recipe")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Paste a recipe URL and let AI parse it automatically")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // URL Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recipe URL")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.secondary)
                        
                        TextField("https://example.com/recipe...", text: $urlText)
                            .textFieldStyle(.plain)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .focused($isTextFieldFocused)
                            .disabled(importer.isLoading)
                        
                        if !urlText.isEmpty {
                            Button(action: { urlText = "" }, label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            })
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Import Button
                Button(action: importRecipe, label: {
                    HStack {
                        if importer.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Import Recipe")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(urlText.isEmpty || importer.isLoading ? Color.gray : AppTheme.accentColor(for: selectedTheme))
                    .cornerRadius(16)
                })
                .disabled(urlText.isEmpty || importer.isLoading)
                .padding(.horizontal)
                
                // Error Message
                if let error = importer.errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            
                            Text("Import Failed")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Example URLs
                VStack(alignment: .leading, spacing: 12) {
                    Text("Try these examples:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        exampleButton(
                            url: "https://www.allrecipes.com/recipe/223042/chicken-parmesan/", 
                            title: "Chicken Parmesan",
                            subtitle: "AllRecipes"
                        )
                        exampleButton(
                            url: "https://www.bbcgoodfood.com/recipes/spaghetti-carbonara-recipe",
                            title: "Spaghetti Carbonara",
                            subtitle: "BBC Good Food"
                        )
                        exampleButton(
                            url: "https://www.tamingtwins.com/mexican-chicken-and-rice-one-pot/",
                            title: "Mexican Chicken and Rice",
                            subtitle: "Taming Twins"
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Info
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("AI-powered recipe parsing")
                            .font(.caption)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Works with most recipe websites")
                            .font(.caption)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.blue)
                        Text("Your data stays on your device")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
                .padding(.bottom, 40)
            }
            
            // Offline Banner on top of content
            OfflineBanner()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: importer.extractedData) { _, newValue in
            if newValue != nil {
                // Data extracted successfully - open wizard directly with pre-filled data
                showRecipeWizard = true
            }
        }
        .sheet(isPresented: $showRecipeWizard) {
            if let data = importer.extractedData {
                RecipeWizardView(
                    prefilledData: RecipeWizardView.PrefilledRecipeData(
                        name: data.name,
                        description: data.description,
                        ingredients: data.rawIngredients,
                        instructions: data.instructions,
                        prepTime: data.prepTimeMinutes,
                        cookTime: data.cookTimeMinutes,
                        servings: data.servings,
                        difficulty: data.difficulty,
                        notes: generateImportNotes(from: data),
                        category: data.category,
                        isFavorite: false
                    )
                ) { newRecipe in
                    onImport(newRecipe)
                    showRecipeWizard = false
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// Generate comprehensive notes from imported recipe data
    /// Follows the format of the Achari Chicken Curry sample recipe
    private func generateImportNotes(from data: RecipeImporter.ExtractedRecipeData) -> String {
        var notes: [String] = []
        
        // 1. Recipe description (if available) - PRIMARY CONTENT
        if let description = data.description, !description.isEmpty {
            // Clean up the description
            let cleanDescription = description
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            notes.append(cleanDescription)
        }
        
        // 2. Add cuisine-specific tips (if available)
        if let cuisine = data.cuisine, !cuisine.isEmpty {
            notes.append("") // Blank line
            notes.append("💡 Cuisine: \(cuisine)")
        }
        
        // 3. Add pairing suggestions based on category
        if let category = data.category {
            let pairingSuggestion = getPairingSuggestion(for: category)
            if !pairingSuggestion.isEmpty {
                notes.append("") // Blank line
                notes.append(pairingSuggestion)
            }
        }
        
        // 4. Source attribution (minimal, at the end)
        notes.append("") // Blank line
        let domain = data.sourceURL.host ?? "Unknown"
        let cleanDomain = domain.replacingOccurrences(of: "www.", with: "")
        notes.append("---")
        notes.append("Imported from \(cleanDomain)")
        
        // 4. Description if available
        
        // Add date for record-keeping (subtle)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        notes.append("Imported \(dateFormatter.string(from: Date()))")
        
        return notes.joined(separator: "\n")
    }
    
    /// Get pairing suggestions based on recipe category
    private func getPairingSuggestion(for category: String) -> String {
        switch category.lowercased() {
        case "main", "dinner", "entree", "entrée":
            return "🍽️ Perfect for pairing with rice, naan, or your favorite sides."
        case "dessert", "sweet":
            return "🍰 Great with coffee, tea, or as a sweet treat after dinner."
        case "breakfast":
            return "☕ Best enjoyed fresh in the morning with coffee or juice."
        case "appetizer", "starter":
            return "🥗 Ideal as a starter or party appetizer."
        case "soup", "stew":
            return "🍲 Serve hot with crusty bread or crackers."
        case "salad":
            return "🥗 Light and refreshing as a side or main course."
        case "drink", "beverage":
            return "🥤 Serve chilled or at the recommended temperature."
        default:
            return ""
        }
    }
    
    private func exampleButton(url: String, title: String, subtitle: String) -> some View {
        Button(
            action: { 
                urlText = url
                HapticManager.shared.light()
            },
            label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.accentColor(for: selectedTheme).opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.accentColor(for: selectedTheme).opacity(0.3), lineWidth: 1)
                        )
                )
            }
        )
        .buttonStyle(PlainButtonStyle())
    }
    
    private func importRecipe() {
        isTextFieldFocused = false
        HapticManager.shared.selection()
        
        guard let url = URL(string: urlText) else {
            importer.errorMessage = "Invalid URL"
            return
        }
        
        let importerRef = importer
        
        Task {
            await importerRef.importRecipe(from: url)
        }
    }
}

#Preview {
    RecipeImportView { recipe in
        debugLog("Imported: \(recipe.name)")
    }
}
