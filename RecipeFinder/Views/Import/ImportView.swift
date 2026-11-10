import SwiftUI

/// Centre-tab import hub reusing RecipeImportView and RecipeWizardView for consistent behaviour, plus a share-sheet hint for social recipes.
struct ImportView: View {
    @Environment(\.recipeStore) private var recipeStore
    private var recipes: [RecipeModel] { recipeStore.recipes }


    @State private var showLinkImport = false
    @State private var showPasteImport = false
    @State private var showWebSearch = false
    @State private var showPhotoImport = false
    @State private var showWizard = false
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
                    ScreenTitleHeader("Import a Recipe") {
                        Image(systemName: "tray.and.arrow.down.fill")
                            .font(.system(size: AppTheme.fontSize20, weight: .semibold))
                            .foregroundStyle(.orange)
                            .frame(width: AppTheme.height44, alignment: .trailing)
                            .accessibilityHidden(true)
                    }

                    ScrollView {
                        VStack(spacing: AppTheme.spacing16) {
                            actionCard(
                                icon: "link",
                                color: .orange,
                                title: "Paste a link",
                                subtitle: "Import from a recipe website — we fetch and parse it for you.",
                                action: { showLinkImport = true }
                            )
                            .accessibilityIdentifier("import.link")

                            actionCard(
                                icon: "globe",
                                color: .blue,
                                title: "Search the web",
                                subtitle: "Find a recipe online, then import the page you're on.",
                                action: { showWebSearch = true }
                            )
                            .accessibilityIdentifier("import.web")

                            actionCard(
                                icon: "doc.on.clipboard",
                                color: .green,
                                title: "Paste text",
                                subtitle: "Paste a caption, note, or message — we pull out the recipe to review.",
                                action: { showPasteImport = true }
                            )
                            .accessibilityIdentifier("import.paste")

                            actionCard(
                                icon: "text.viewfinder",
                                color: .purple,
                                title: "Scan a photo",
                                subtitle: "A cookbook page, screenshot, or handwritten recipe — read on device.",
                                action: { showPhotoImport = true }
                            )
                            .accessibilityIdentifier("import.photo")

                            actionCard(
                                icon: "square.and.pencil",
                                color: .blue,
                                title: "Create manually",
                                subtitle: "Add a recipe yourself, step by step.",
                                action: { showWizard = true }
                            )
                            .accessibilityIdentifier("import.wizard")

                            shareHint
                        }
                        .padding(.horizontal, AppTheme.spacing20)
                        .padding(.top, AppTheme.spacing16)
                        .padding(.bottom, AppTheme.spacing40)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showLinkImport) {
            RecipeImportView(initialURL: nil, existingNames: recipes.map(\.name)) { store($0, source: .link) }
        }
        .sheet(isPresented: $showWebSearch) {
            RecipeWebSearchView(existingNames: recipes.map(\.name)) { store($0, source: .link) }
        }
        .sheet(isPresented: $showPasteImport) {
            PasteTextImportSheet { store($0, source: .paste) }
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
        }
    }

    private func actionCard(icon: String, color: Color, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.shared.light()
            action()
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

#Preview {
    ImportView()
}
