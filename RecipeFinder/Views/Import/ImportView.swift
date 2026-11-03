import SwiftUI

/// Centre-tab import hub reusing RecipeImportView and RecipeWizardView for consistent behaviour, plus a share-sheet hint for social recipes.
struct ImportView: View {
    @Environment(\.recipeStore) private var recipeStore
    private var recipes: [RecipeModel] { recipeStore.recipes }

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("guestModeEnabled") private var guestModeEnabled = false
    @Environment(\.auth) private var authManager

    @State private var showLinkImport = false
    @State private var showPasteImport = false
    @State private var showPhotoImport = false
    @State private var showWizard = false
    @State private var saveErrorRecipeName: String?
    @State private var showSignUpForGuest = false

    private var isGuest: Bool { guestModeEnabled && !authManager.isAuthenticated }
    /// Only divert guests to sign-up when the auth UI exists. In a guest-only build there's no
    /// account to create, so guests run every import/create action directly.
    private var gatesToSignUp: Bool { isGuest && AuthUIGate.showAuthUI }

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
                                action: gatesToSignUp ? { showSignUpForGuest = true } : { showLinkImport = true }
                            )
                            .accessibilityIdentifier("import.link")

                            actionCard(
                                icon: "doc.on.clipboard",
                                color: .green,
                                title: "Paste text",
                                subtitle: "Paste a caption, note, or message — we pull out the recipe to review.",
                                action: gated { showPasteImport = true }
                            )
                            .accessibilityIdentifier("import.paste")

                            actionCard(
                                icon: "text.viewfinder",
                                color: .purple,
                                title: "Scan a photo",
                                subtitle: "A cookbook page, screenshot, or handwritten recipe — read on device.",
                                action: gated { showPhotoImport = true }
                            )
                            .accessibilityIdentifier("import.photo")

                            actionCard(
                                icon: "square.and.pencil",
                                color: .blue,
                                title: "Create manually",
                                subtitle: "Add a recipe yourself, step by step.",
                                action: gatesToSignUp ? { showSignUpForGuest = true } : { showWizard = true }
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

    /// Wraps an import action with the guest gate: guests who must sign up go to sign-up, everyone else runs it.
    private func gated(_ action: @escaping () -> Void) -> () -> Void {
        {
            if gatesToSignUp {
                showSignUpForGuest = true
            } else {
                action()
            }
        }
    }

    /// Appends and persists a recipe; shared by every import route. On save failure the optimistic insert is rolled back and the user alerted.
    private func store(_ recipe: RecipeModel, source: ImportSource = .wizard) {
        switch RecipeImportStore.outcome(didPersist: recipeStore.add(recipe), recipeName: recipe.name, source: source) {
        case .failed(let name):
            saveErrorRecipeName = name
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
        .environment(\.appTheme, .teal)
}
