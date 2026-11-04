import SwiftUI

private let logger = AppLogger.logger(category: "RecipeImport")

struct RecipeImportView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var importer = RecipeImporter()
    @State private var urlText = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var loadingStage: LoadingStage = .idle
    @State private var pendingRecipe: RecipeModel?
    /// A clean import opens in the editor for review (like paste/photo imports) instead of saving blind.
    @State private var reviewPrefill: RecipeWizardView.PrefilledRecipeData?
    @State private var showDuplicateAlert = false
    @State private var showIncompleteAlert = false
    private let builder = RecipeImportBuilder()

    /// When set (e.g. from the share extension), prefills the URL field and auto-starts the import.
    var initialURL: String? = nil
    var existingNames: [String] = []
    var onImport: (RecipeModel) -> Void

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
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                AppBackground()

                VStack(spacing: AppTheme.spacing32) {
                    VStack(spacing: AppTheme.spacing12) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.system(size: AppTheme.fontSize60))
                            .foregroundStyle(AppTheme.accentColor)
                    
                    Text("Import Recipe")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Paste a recipe URL and let AI parse it automatically")
                        .font(.subheadline)
                        .adaptiveSecondaryForeground()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, AppTheme.spacing40)
                .opacity(importer.isLoading ? 0.5 : 1.0)
                
                VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                    Text("Recipe URL")
                        .font(.headline)
                        .adaptiveForegroundColor()
                    
                    HStack {
                        Image(systemName: "link")
                            .adaptiveSecondaryForeground()
                        
                        TextField("https://example.com/recipe...", text: $urlText)
                            .textFieldStyle(.plain)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .focused($isTextFieldFocused)
                            .disabled(importer.isLoading)
                        
                        if urlText.isEmpty {
                            Button(action: pasteFromClipboard) {
                                Image(systemName: "doc.on.clipboard")
                                    .adaptiveSecondaryForeground()
                            }
                        } else {
                            Button(action: { urlText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .adaptiveSecondaryForeground()
                            }
                        }
                    }
                    .padding()
                    .appCard(cornerRadius: AppTheme.cornerRadius12)
                }
                .padding(.horizontal)
                
                if importer.isLoading {
                    VStack(spacing: AppTheme.spacing24) {
                        ZStack {
                            Circle()
                                .stroke(AppTheme.accentColor.opacity(0.3), lineWidth: 4)
                                .frame(width: AppTheme.width80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: loadingStage.progress)
                                .stroke(
                                    AppTheme.accentColor,
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                )
                                .frame(width: AppTheme.width80, height: 80)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: AppTheme.animationDelayMedium), value: loadingStage)
                            
                            Image(systemName: "sparkles")
                                .font(.title)
                                .foregroundStyle(AppTheme.accentColor)
                        }
                        
                        VStack(spacing: AppTheme.spacing8) {
                            Text(loadingStage.message)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text("\(Int(loadingStage.progress * 100))% complete")
                                .font(.caption)
                                .adaptiveSecondaryForeground()
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
                        .background(urlText.isEmpty ? Color.gray : AppTheme.accentColor)
                        .cornerRadius(AppTheme.cornerRadius16)
                    })
                    .disabled(urlText.isEmpty)
                    .padding(.horizontal)
                }
                
                if let error = importer.errorMessage {
                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        HStack(spacing: AppTheme.spacing12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            
                            Text("Import Failed")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                        
                        Text(error)
                            .font(.subheadline)
                            .adaptiveSecondaryForeground()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(AppTheme.warning.opacity(AppTheme.shadowLightOpacity))
                    .cornerRadius(AppTheme.cornerRadius12)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                VStack(spacing: AppTheme.spacing8) {
                    HStack(spacing: AppTheme.spacing8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.purple)
                        Text("AI-powered recipe parsing")
                            .font(.caption)
                            .adaptiveForegroundColor()
                    }

                    HStack(spacing: AppTheme.spacing8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Works with most recipe websites")
                            .font(.caption)
                            .adaptiveForegroundColor()
                    }

                    HStack(spacing: AppTheme.spacing8) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.blue)
                        Text("Your data stays on your device")
                            .font(.caption)
                            .adaptiveForegroundColor()
                    }
                }
                .padding(.bottom, AppTheme.spacing40)
            }
            
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(item: $reviewPrefill) { prefill in
            RecipeWizardView(prefilledData: prefill) { reviewed in
                onImport(reviewed)
                dismiss()
            }
        }
        .alert(
            "Recipe Already Saved",
            isPresented: $showDuplicateAlert,
            presenting: pendingRecipe
        ) { recipe in
            Button("Import Anyway") {
                onImport(recipe)
                pendingRecipe = nil
                dismiss()
            }
            Button("Cancel", role: .cancel) {
                pendingRecipe = nil
            }
        } message: { recipe in
            Text("\"\(recipe.name)\" is already in your recipes. Import as a duplicate?")
        }
        .alert(
            "Recipe looks incomplete",
            isPresented: $showIncompleteAlert,
            presenting: pendingRecipe
        ) { recipe in
            Button("Save & Add Later") {
                onImport(recipe)
                pendingRecipe = nil
                dismiss()
            }
            Button("Cancel", role: .cancel) {
                pendingRecipe = nil
            }
        } message: { recipe in
            let missing = recipe.ingredients.isEmpty
                ? (recipe.instructions.isEmpty ? "ingredients or steps" : "ingredients")
                : "cooking steps"
            Text("We couldn't find the \(missing) for \"\(recipe.name)\". Save it and add them yourself, or cancel?")
        }
        .onAppear {
            if let initialURL, urlText.isEmpty {
                urlText = initialURL
                importRecipe()
            }
        }

    }

    private func pasteFromClipboard() {
        guard let string = UIPasteboard.general.string,
              let url = URL(string: string.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme == "https" || url.scheme == "http" else { return }
        urlText = string.trimmingCharacters(in: .whitespacesAndNewlines)
        HapticManager.shared.light()
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
            try? await Task.sleep(nanoseconds: AppTheme.hapticIntervalXLong)
            
            loadingStage = .parsing
            
            await importerRef.importRecipe(from: url)
            
            if let data = importerRef.extractedData {
                loadingStage = .extracting
                try? await Task.sleep(nanoseconds: AppTheme.hapticIntervalLong)

                loadingStage = .complete
                HapticManager.shared.success()
                try? await Task.sleep(nanoseconds: AppTheme.hapticIntervalBase)

                let recipe = builder.build(from: data)
                let isDuplicate = existingNames.contains {
                    $0.trimmingCharacters(in: .whitespaces).lowercased() ==
                    recipe.name.trimmingCharacters(in: .whitespaces).lowercased()
                }
                if isDuplicate {
                    pendingRecipe = recipe
                    loadingStage = .idle
                    showDuplicateAlert = true
                } else if recipe.ingredients.isEmpty || recipe.instructions.isEmpty {
                    // Don't silently save an incomplete import — let the user decide.
                    pendingRecipe = recipe
                    loadingStage = .idle
                    showIncompleteAlert = true
                } else {
                    loadingStage = .idle
                    reviewPrefill = RecipeWizardView.PrefilledRecipeData(recipe: recipe)
                }
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
