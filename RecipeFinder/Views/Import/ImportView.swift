import SwiftUI

/// The centre-tab import hub: the app's front door for getting recipes in.
/// Reuses the existing import (`RecipeImportView`) and manual-create
/// (`RecipeWizardView`) flows so behaviour stays consistent with the rest of the
/// app, and points people at the share-sheet route for social recipes.
struct ImportView: View {
    @Binding var recipes: [RecipeModel]

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("guestModeEnabled") private var guestModeEnabled = false
    @StateObject private var authManager = AuthenticationManager.shared

    @State private var showLinkImport = false
    @State private var showPasteImport = false
    @State private var showPhotoImport = false
    @State private var showWizard = false
    @State private var saveErrorRecipeName: String?
    @State private var showSignUpForGuest = false

    private enum ImportSource { case link, photo, paste, wizard }

    private var isGuest: Bool { guestModeEnabled && !authManager.isAuthenticated }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()

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
                                action: isGuest ? { showSignUpForGuest = true } : { showLinkImport = true }
                            )
                            .accessibilityIdentifier("import.link")

                            actionCard(
                                icon: "doc.on.clipboard",
                                color: .green,
                                title: "Paste text",
                                subtitle: "Paste a caption, note, or message — we pull out the recipe to review.",
                                action: isGuest ? { showSignUpForGuest = true } : { showPasteImport = true }
                            )
                            .accessibilityIdentifier("import.paste")

                            actionCard(
                                icon: "text.viewfinder",
                                color: .purple,
                                title: "Scan a photo",
                                subtitle: "A cookbook page, screenshot, or handwritten recipe — read on device.",
                                action: isGuest ? { showSignUpForGuest = true } : { showPhotoImport = true }
                            )
                            .accessibilityIdentifier("import.photo")

                            actionCard(
                                icon: "square.and.pencil",
                                color: .blue,
                                title: "Create manually",
                                subtitle: "Add a recipe yourself, step by step.",
                                action: isGuest ? { showSignUpForGuest = true } : { showWizard = true }
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
        .sheet(isPresented: $showPasteImport) {
            PasteTextImportSheet { store($0, source: .paste) }
        }
        .sheet(isPresented: $showPhotoImport) {
            PhotoImportSheet { store($0, source: .photo) }
        }
        .sheet(isPresented: $showWizard) {
            RecipeWizardView(prefilledData: nil) { store($0, source: .wizard) }
        }
        .sheet(isPresented: $showSignUpForGuest) {
            NavigationStack { AuthenticationView() }
        }
        .alert(
            "Couldn't Save Recipe",
            isPresented: Binding(
                get: { saveErrorRecipeName != nil },
                set: { if !$0 { saveErrorRecipeName = nil } }
            ),
            presenting: saveErrorRecipeName
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { name in
            Text("\"\(name)\" couldn't be saved. Please try again.")
        }
    }

    /// Appends a finished recipe to the list and persists it. Shared by every
    /// import route so they save identically. If the save fails, the optimistic
    /// insertion is rolled back and the user is alerted rather than the recipe
    /// silently disappearing on relaunch.
    private func store(_ recipe: RecipeModel, source: ImportSource = .wizard) {
        recipes.append(recipe)

        guard PersistenceController.shared.saveRecipeModel(recipe) else {
            recipes.removeAll { $0.id == recipe.id }
            saveErrorRecipeName = recipe.name
            return
        }

        HapticManager.shared.success()

        switch source {
        case .link, .paste:
            BadgeManager.shared.unlockBadge(.firstImport)
        case .photo:
            BadgeManager.shared.unlockBadge(.firstPhotoImport)
        case .wizard:
            break
        }
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
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                    Text(title)
                        .font(.body).fontWeight(.semibold)
                        .adaptiveForegroundColor()
                    Text(subtitle)
                        .font(.caption)
                        .adaptiveForegroundColor()
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
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
    ImportView(recipes: .constant([]))
        .environment(\.appTheme, .teal)
}
