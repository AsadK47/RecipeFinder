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
                VStack(spacing: AppTheme.spacing32) {
                    VStack(spacing: AppTheme.spacing12) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.system(size: AppTheme.fontSize60))
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
                .padding(.top, AppTheme.spacing40)
                .opacity(importer.isLoading ? 0.5 : 1.0)
                
                VStack(alignment: .leading, spacing: AppTheme.spacing8) {
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
                    .cornerRadius(AppTheme.cornerRadius12)
                }
                .padding(.horizontal)
                
                if importer.isLoading {
                    VStack(spacing: AppTheme.spacing24) {
                        ZStack {
                            Circle()
                                .stroke(AppTheme.accentColor(for: selectedTheme).opacity(0.3), lineWidth: 4)
                                .frame(width: AppTheme.width80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: loadingStage.progress)
                                .stroke(
                                    AppTheme.accentColor(for: selectedTheme),
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                )
                                .frame(width: AppTheme.width80, height: 80)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: AppTheme.animationDelayMedium), value: loadingStage)
                            
                            Image(systemName: "sparkles")
                                .font(.title)
                                .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                        }
                        
                        VStack(spacing: AppTheme.spacing8) {
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
                    .padding(.vertical, AppTheme.spacing40)
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
                        .frame(height: AppTheme.height56)
                        .background(urlText.isEmpty ? Color.gray : AppTheme.accentColor(for: selectedTheme))
                        .cornerRadius(AppTheme.cornerRadius16)
                    })
                    .disabled(urlText.isEmpty)
                    .padding(.horizontal)
                }
                
                if let error = importer.errorMessage {
                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        HStack(spacing: AppTheme.spacing12) {
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
                    .background(Color.orange.opacity(AppTheme.shadowLightOpacity))
                    .cornerRadius(AppTheme.cornerRadius12)
                    .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                    Text("Try these examples:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
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
                
                VStack(spacing: AppTheme.spacing8) {
                    HStack(spacing: AppTheme.spacing8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("AI-powered recipe parsing")
                            .font(.caption)
                    }
                    
                    HStack(spacing: AppTheme.spacing8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Works with most recipe websites")
                            .font(.caption)
                    }
                    
                    HStack(spacing: AppTheme.spacing8) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.blue)
                        Text("Your data stays on your device")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
                .padding(.bottom, AppTheme.spacing40)
            }
            
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
    
    private func generateImportNotes(from data: RecipeImporter.ExtractedRecipeData) -> String {
        var notes: [String] = []
        
        if let description = data.description, !description.isEmpty {
            let cleanDescription = description
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            notes.append(cleanDescription)
        }
        
        if let cuisine = data.cuisine, !cuisine.isEmpty {
            notes.append("")
            notes.append("💡 Cuisine: \(cuisine)")
        }
        
        if let category = data.category {
            let pairingSuggestion = getPairingSuggestion(for: category)
            if !pairingSuggestion.isEmpty {
                notes.append("")
                notes.append(pairingSuggestion)
            }
        }
        
        notes.append("")
        let domain = data.sourceURL.host ?? "Unknown"
        let cleanDomain = domain.replacingOccurrences(of: "www.", with: "")
        notes.append("---")
        notes.append("Imported from \(cleanDomain)")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        notes.append("Imported \(dateFormatter.string(from: Date()))")
        
        return notes.joined(separator: "\n")
    }
    
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
                VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppTheme.spacing16)
                .padding(.vertical, AppTheme.spacing12)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                        .fill(AppTheme.accentColor(for: selectedTheme).opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
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
            loadingStage = .fetching
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            loadingStage = .parsing
            
            await importerRef.importRecipe(from: url)
            
            if importerRef.extractedData != nil {
                loadingStage = .extracting
                try? await Task.sleep(nanoseconds: 300_000_000)
                
                loadingStage = .complete
                HapticManager.shared.success()
                try? await Task.sleep(nanoseconds: 200_000_000)
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
