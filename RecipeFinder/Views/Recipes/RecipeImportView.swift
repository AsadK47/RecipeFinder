import SwiftUI

struct RecipeImportView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @StateObject private var importer = RecipeImporter()
    @State private var urlText = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var showImportChoice = false
    @State private var showRecipeWizard = false
    @State private var importMode: ImportMode = .autoFill
    
    enum ImportMode {
        case autoFill
        case manual
    }
    
    var onImport: (RecipeModel) -> Void
    
    var body: some View {
        NavigationView {
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
                        
                        TextField("https://example.com/recipe", text: $urlText)
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
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
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
                                url: "https://www.seriouseats.com/classic-lasagna-meat-sauce-bechamel-recipe",
                                title: "Classic Lasagna",
                                subtitle: "Serious Eats"
                            )
                            exampleButton(
                                url: "https://www.bonappetit.com/recipe/bas-best-chocolate-chip-cookies",
                                title: "Chocolate Chip Cookies",
                                subtitle: "Bon Appétit"
                            )
                            exampleButton(
                                url: "https://www.tamingtwins.com/mexican-chicken-and-rice-one-pot/#wprm-recipe-container-22976",
                                title: "Mexican Chicken and Rice",
                                subtitle: "Taming Twins"
                            )
                        }
                        .padding(.horizontal)
                    }
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
                // Data extracted successfully - show import choice dialog
                showImportChoice = true
            }
        }
        .confirmationDialog("Import Recipe", isPresented: $showImportChoice) {
            Button("Auto-Fill Recipe (\(Int(importer.parseConfidence * 100))% confident)") {
                importMode = .autoFill
                showRecipeWizard = true
            }
            Button("Review & Edit Manually") {
                importMode = .manual
                showRecipeWizard = true
            }
            Button("Cancel", role: .cancel) {
                // Keep the data, user can try again
            }
        } message: {
            if let data = importer.extractedData {
                Text("Recipe '\(data.name)' parsed successfully!\n\nChoose how to proceed:")
            }
        }
        .sheet(isPresented: $showRecipeWizard) {
            if let data = importer.extractedData {
                RecipeWizardView(
                    prefilledData: RecipeWizardView.PrefilledRecipeData(
                        name: data.name,
                        description: data.description,
                        ingredients: data.matchedIngredients,
                        instructions: data.instructions,
                        prepTime: data.prepTimeMinutes,
                        cookTime: data.cookTimeMinutes,
                        servings: data.servings,
                        difficulty: data.difficulty,
                        notes: "Imported from: \(data.sourceURL.absoluteString)\nParse confidence: \(Int(importer.parseConfidence * 100))%"
                    ),
                    autoFillMode: importMode == .autoFill
                ) { newRecipe in
                    onImport(newRecipe)
                    showRecipeWizard = false
                    dismiss()
                }
            }
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
        
        Task {
            await importer.importRecipe(from: url)
        }
    }
}

#Preview {
    RecipeImportView { recipe in
        print("Imported: \(recipe.name)")
    }
}
