import SwiftUI

/// The centre-tab import hub: the app's front door for getting recipes in.
/// Reuses the existing import (`RecipeImportView`) and manual-create
/// (`RecipeWizardView`) flows so behaviour stays consistent with the rest of the
/// app, and points people at the share-sheet route for social recipes.
struct ImportView: View {
    @Binding var recipes: [RecipeModel]

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal

    @State private var showLinkImport = false
    @State private var showPasteImport = false
    @State private var showPhotoImport = false
    @State private var showWizard = false
    @State private var saveErrorRecipeName: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.spacing16) {
                        header

                        actionCard(
                            icon: "link",
                            color: .orange,
                            title: "Paste a link",
                            subtitle: "Import from a recipe website — we fetch and parse it for you.",
                            action: { showLinkImport = true }
                        )

                        actionCard(
                            icon: "doc.on.clipboard",
                            color: .green,
                            title: "Paste text",
                            subtitle: "Paste a caption, note, or message — we pull out the recipe to review.",
                            action: { showPasteImport = true }
                        )

                        actionCard(
                            icon: "text.viewfinder",
                            color: .purple,
                            title: "Scan a photo",
                            subtitle: "A cookbook page, screenshot, or handwritten recipe — read on device.",
                            action: { showPhotoImport = true }
                        )

                        actionCard(
                            icon: "square.and.pencil",
                            color: .blue,
                            title: "Create manually",
                            subtitle: "Add a recipe yourself, step by step.",
                            action: { showWizard = true }
                        )

                        shareHint
                    }
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.top, AppTheme.spacing16)
                    .padding(.bottom, AppTheme.spacing40)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showLinkImport) {
            RecipeImportView(initialURL: nil, existingNames: recipes.map(\.name)) { store($0) }
        }
        .sheet(isPresented: $showPasteImport) {
            PasteTextImportSheet { store($0) }
        }
        .sheet(isPresented: $showPhotoImport) {
            PhotoImportSheet { store($0) }
        }
        .sheet(isPresented: $showWizard) {
            RecipeWizardView(prefilledData: nil) { store($0) }
        }
        .alert(
            "Couldn't Save Recipe",
            isPresented: Binding(
                get: { saveErrorRecipeName != nil },
                set: { if !$0 { saveErrorRecipeName = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\"\(saveErrorRecipeName ?? "")\" couldn't be saved. Please try again.")
        }
    }

    /// Appends a finished recipe to the list and persists it. Shared by every
    /// import route so they save identically. If the save fails, the optimistic
    /// insertion is rolled back and the user is alerted rather than the recipe
    /// silently disappearing on relaunch.
    private func store(_ recipe: RecipeModel) {
        recipes.append(recipe)

        guard PersistenceController.shared.saveRecipeModel(recipe) else {
            recipes.removeAll { $0.id == recipe.id }
            saveErrorRecipeName = recipe.name
            return
        }

        HapticManager.shared.success()
    }

    private var header: some View {
        VStack(spacing: AppTheme.spacing8) {
            Image(systemName: "tray.and.arrow.down.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.orange)

            Text("Import a Recipe")
                .font(.system(size: AppTheme.fontSize34, weight: .bold))
                .adaptiveForegroundColor()

            Text("Bring recipes in from anywhere — free and unlimited.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func actionCard(icon: String, color: Color, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.shared.light()
            action()
        }) {
            HStack(spacing: AppTheme.spacing16) {
                ZStack {
                    Circle().fill(color).frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                    Text(title)
                        .font(.body).fontWeight(.semibold)
                        .adaptiveForegroundColor()
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(AppTheme.spacing20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius16))
        }
        .buttonStyle(.plain)
    }

    private var shareHint: some View {
        HStack(spacing: AppTheme.spacing12) {
            Image(systemName: "square.and.arrow.up")
                .font(.body)
                .foregroundColor(.secondary)
            Text("Or share a page from Safari, Instagram or TikTok to **RecipeFinder** — it imports on device, privately.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(AppTheme.spacing16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
        .padding(.top, AppTheme.spacing8)
    }
}

#Preview {
    ImportView(recipes: .constant([]))
        .environment(\.appTheme, .teal)
}
