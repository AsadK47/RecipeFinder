import SwiftUI

private let logger = AppLogger.logger(category: "RecipeImport")


struct RecipeImportView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var importer = RecipeImporter()
    @State private var urlText = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var showRecipeWizard = false
    @State private var loadingStage: LoadingStage = .idle
    
    enum LoadingStage {
        case idle
        case fetching
        case parsing
        case extracting
        case complete
        
        var message: String {
            switch self {
            case .idle: return ""
            case .fetching: return "Fetching recipe from website..."
            case .parsing: return "Parsing recipe data..."
            case .extracting: return "Extracting ingredients..."
            case .complete: return "Ready!"
            }
        }
        
        var progress: Double {
            switch self {
            case .idle: return 0.0
            case .fetching: return 0.33
            case .parsing: return 0.66
            case .extracting: return 0.90
            case .complete: return 1.0
            }
        }
    }
    
    var onImport: (RecipeModel) -> Void
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                VStack(spacing: AppTheme.spacingXXL) {
                    // Header
                    VStack(spacing: AppTheme.spacingMD) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.system(size: AppTheme.fontSizeDisplay))
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
                .opacity(importer.isLoading ? 0.5 : 1.0)
                
                // URL Input
                VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
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
                
                // Import Button or Loading State
                if importer.isLoading {
                    // Enhanced loading view with stages
                    VStack(spacing: AppTheme.spacingXL) {
                        ZStack {
                            // Animated circle background
                            Circle()
                                .stroke(AppTheme.accentColor(for: selectedTheme).opacity(0.3), lineWidth: 4)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: loadingStage.progress)
                                .stroke(
                                    AppTheme.accentColor(for: selectedTheme),
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                )
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.5), value: loadingStage)
                            
                            Image(systemName: "sparkles")
                                .font(.title)
                                .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                        }
                        
                        VStack(spacing: AppTheme.spacingSM) {
                            Text(loadingStage.message)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("\(Int(loadingStage.progress * 100))% complete")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .animation(.easeInOut, value: loadingStage)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .padding(.horizontal)
                } else {
                    Button(action: importRecipe, label: {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Import Recipe")
                        }
                        .font(.headline)
                        .adaptiveForegroundColor()
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(urlText.isEmpty ? Color.gray : AppTheme.accentColor(for: selectedTheme))
                        .cornerRadius(16)
                    })
                    .disabled(urlText.isEmpty)
                    .padding(.horizontal)
                }
                
                // Error Message
                if let error = importer.errorMessage {
                    VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                        HStack(spacing: AppTheme.spacingMD) {
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
                VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                    Text("Try these examples:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
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
                VStack(spacing: AppTheme.spacingSM) {
                    HStack(spacing: AppTheme.spacingSM) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("AI-powered recipe parsing")
                            .font(.caption)
                    }
                    
                    HStack(spacing: AppTheme.spacingSM) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Works with most recipe websites")
                            .font(.caption)
                    }
                    
                    HStack(spacing: AppTheme.spacingSM) {
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
                VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
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
        
        // Simulate loading stages for better UX
        Task {
            loadingStage = .fetching
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            
            loadingStage = .parsing
            
            await importerRef.importRecipe(from: url)
            
            if importerRef.extractedData != nil {
                loadingStage = .extracting
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                
                loadingStage = .complete
                HapticManager.shared.success()
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
            } else {
                loadingStage = .idle
                HapticManager.shared.error()
            }
        }
    }
}

#Preview {
    RecipeImportView { recipe in
        logger.debug("Imported: \(recipe.name)")
    }
}
