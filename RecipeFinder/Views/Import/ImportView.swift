import SwiftUI

/// The Recipes "+" sheet: one box for a pasted link or recipe text (auto-detected), then the other ways to add a recipe,
/// which go straight to the recipe screen via AddRecipeImportFlow, plus a share-sheet hint for social recipes.
struct ImportView: View {
    @Environment(\.recipeStore) private var recipeStore
    @Environment(\.dismiss) private var dismiss
    private var recipes: [RecipeModel] { recipeStore.recipes }


    @State private var pastedInput = ""
    @State private var flowSource: AddRecipeImportFlow.Source?
    @State private var showWebSearch = false
    @State private var showPhotoImport = false
    @State private var showWizard = false
    @State private var showOtherApps = false
    @State private var saveError: String?
    #if DEBUG
    /// Screenshots hook (`-show-low-confidence-import`): opens the review on a deliberately poor import, once.
    @State private var debugLowConfidencePrefill: RecipeWizardView.PrefilledRecipeData?
    @State private var didShowDebugImport = false
    #endif

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 0) {
                    ScreenTitleHeader("Add a Recipe") {
                        CircleButton(icon: "xmark") { dismiss() }
                            .accessibilityLabel("Close")
                            .accessibilityIdentifier("import.close")
                    }

                    ScrollView {
                        VStack(spacing: AppTheme.spacing16) {
                            AddRecipePasteBox(text: $pastedInput, onSubmit: submit)

                            ForEach(AddRecipeOption.allCases) { option in
                                actionCard(option)
                            }

                            shareHint
                        }
                        .padding(.horizontal, AppTheme.spacing20)
                        .padding(.top, AppTheme.spacing16)
                        .padding(.bottom, AppTheme.spacing40)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            // Same Paprika/Mela/CSV import as Settings → Data Management.
            .navigationDestination(isPresented: $showOtherApps) {
                SettingsScreen("From Another App") { OtherAppImportSection() }
            }
        }
        .sheet(item: $flowSource) { source in
            AddRecipeImportFlow(source: source, existingNames: recipes.map(\.name)) { recipe in
                if case .link = source { store(recipe, source: .link) } else { store(recipe, source: .paste) }
            }
        }
        .sheet(isPresented: $showWebSearch) {
            RecipeWebSearchView(existingNames: recipes.map(\.name)) { store($0, source: .link) }
        }
        .sheet(isPresented: $showPhotoImport) {
            PhotoImportSheet { store($0, source: .photo) }
        }
        .sheet(isPresented: $showWizard) {
            RecipeWizardView(prefilledData: nil) { store($0, source: .wizard) }
        }
        .errorAlert("Couldn't Save Recipe", message: $saveError)
        #if DEBUG
        .sheet(item: $debugLowConfidencePrefill) { prefill in
            RecipeWizardView(prefilledData: prefill) { store($0, source: .paste) }
        }
        .onAppear {
            guard !didShowDebugImport, ProcessInfo.processInfo.arguments.contains("-show-low-confidence-import") else { return }
            didShowDebugImport = true
            debugLowConfidencePrefill = RecipeWizardView.PrefilledRecipeData(
                name: "Mystery Stew", description: nil, ingredients: ["beans", "rice", "spices"], instructions: nil,
                prepTime: nil, cookTime: nil, servings: nil, difficulty: nil, notes: nil, category: nil,
                isFavorite: nil, imageURL: nil
            )
        }
        #endif
    }

    /// Appends and persists a recipe; shared by every import route. On save failure the optimistic insert is rolled back and the user alerted.
    private func store(_ recipe: RecipeModel, source: ImportSource = .wizard) {
        switch RecipeImportStore.outcome(didPersist: recipeStore.add(recipe), recipeName: recipe.name, source: source) {
        case .failed(let name):
            saveError = "\"\(name)\" couldn't be saved. Please try again."
        case .saved(let badge):
            HapticManager.shared.success()
            if let badge { BadgeManager.shared.unlockBadge(badge) }
            // Back to the library so the new recipe (and any badge celebration) shows.
            dismiss()
        }
    }

    /// Link → link importer (fetches straight away); anything else → the text reader.
    private func submit(_ raw: String) {
        switch AddRecipeInput.classify(raw) {
        case .empty: return
        case .link(let url): flowSource = .link(url)
        case .text(let text): flowSource = .text(text)
        }
    }

    private func open(_ option: AddRecipeOption) {
        switch option {
        case .web: showWebSearch = true
        case .photo: showPhotoImport = true
        case .otherApp: showOtherApps = true
        case .manual: showWizard = true
        }
    }

    private func actionCard(_ option: AddRecipeOption) -> some View {
        let (icon, color, title, subtitle) = (option.icon, option.color, option.title, option.subtitle)
        return Button(action: {
            HapticManager.shared.light()
            open(option)
        }) {
            HStack(spacing: AppTheme.spacing16) {
                IconBadge(systemName: icon, tint: color, diameter: 44, iconSize: AppTheme.fontSize18, style: .solid)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                    Text(title)
                        .font(.body).fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        // .primary resolves correctly against material backgrounds where adaptiveForegroundColor() can pick the wrong hue.
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(AppTheme.spacing20)
            .appCard()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(option.accessibilityID)
    }

    private var shareHint: some View {
        HStack(spacing: AppTheme.spacing12) {
            Image(systemName: "square.and.arrow.up")
                .font(.body)
                .adaptiveForegroundColor()
            Text("Or share a page from Safari, Instagram or TikTok to **RecipeFinder** — it imports on device, privately.")
                .font(.caption)
                .adaptiveForegroundColor()
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(AppTheme.spacing16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
        .padding(.top, AppTheme.spacing8)
    }
}

/// One box for a link or recipe text. Paste reads the clipboard only through `PasteButton` (the tap is consent, so no
/// "Allow Paste" prompt) and goes straight on, so link → recipe takes two taps from the "+" button.
private struct AddRecipePasteBox: View {
    @Binding var text: String
    /// Main-actor (hence Sendable) because PasteButton may call back from elsewhere.
    let onSubmit: @MainActor (String) -> Void
    @FocusState private var focused: Bool

    var body: some View {
        let handler = onSubmit
        return VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Paste a link or recipe")
                .font(.headline)
                .foregroundStyle(.primary)
            TextField("A recipe link, caption, or ingredients and steps", text: $text, axis: .vertical)
                .lineLimit(2...8)
                .textFieldStyle(.plain)
                .focused($focused)
                .appInputField()
                .accessibilityIdentifier("add.input")
            HStack(spacing: AppTheme.spacing12) {
                PasteButton(payloadType: String.self) { [handler] strings in
                    let pasted = strings.joined(separator: "\n")
                    Task { @MainActor in handler(pasted) }
                }
                .buttonBorderShape(.capsule)
                .labelStyle(.titleAndIcon)
                .tint(AppTheme.accentColor)
                .accessibilityIdentifier("add.paste")
                Spacer(minLength: 0)
                if !text.isBlank {
                    PrimaryButton("Continue", systemImage: "arrow.right", size: .compact) {
                        focused = false
                        handler(text)
                    }
                    .accessibilityIdentifier("add.continue")
                }
            }
        }
        .padding(AppTheme.spacing20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }
}

#Preview {
    ImportView()
}
