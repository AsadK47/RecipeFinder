import SwiftUI

/// One sheet from a pasted/shared link or recipe text to the recipe screen: a short "Reading…" state, then the same
/// draft screen as "Start blank". Failures stay in this sheet with a way forward (paste the text, start from it).
struct AddRecipeImportFlow: View {
    enum Source: Identifiable {
        case link(URL)
        case text(String)

        var id: String {
            switch self {
            case .link(let url): "link:\(url.absoluteString)"
            case .text(let text): "text:\(text.hashValue)"
            }
        }

        /// A shared/clipboard string: a web link when it is one, else read as recipe text.
        static func from(_ raw: String) -> Source {
            if case .link(let url) = AddRecipeInput.classify(raw) { return .link(url) }
            return .text(raw)
        }
    }

    let source: Source
    var existingNames: [String] = []
    /// Called with the recipe the cook saved on the recipe screen.
    let onImport: (RecipeModel) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var importer = RecipeImporter()
    @State private var phase: Phase = .reading
    @State private var duplicateReview: RecipeWizardView.PrefilledRecipeData?
    @State private var fallbackText = ""
    @State private var showsFallbackEditor = false
    @State private var didStart = false
    private let builder = RecipeImportBuilder()

    private enum Phase {
        case reading
        /// nil = start blank.
        case review(RecipeWizardView.PrefilledRecipeData?)
        case linkFailed(String)
        case textFailed(String)
    }

    var body: some View {
        Group {
            if case .review(let prefill) = phase {
                RecipeWizardView(prefilledData: prefill) { recipe in
                    onImport(recipe)
                    dismiss()
                }
                .id(prefill?.id)
            } else {
                statusScreen
                    .sheetDismissButton("Cancel", placement: .cancellationAction)
                    .sheetScaffold("Add a Recipe")
            }
        }
        .task {
            guard !didStart else { return }
            didStart = true
            switch source {
            case .link(let url): await read(url)
            case .text(let text): await read(text)
            }
        }
        .alert("Recipe Already Saved", isPresented: Binding(
            get: { duplicateReview != nil },
            set: { if !$0 { duplicateReview = nil } }
        ), presenting: duplicateReview) { prefill in
            Button("Add Anyway") {
                duplicateReview = nil
                phase = .review(prefill)
            }
            Button("Cancel", role: .cancel) { dismiss() }
        } message: { prefill in
            Text("\"\(prefill.name ?? "This recipe")\" is already in your recipes. Add another copy?")
        }
    }

    // MARK: - Reading

    private func read(_ url: URL) async {
        phase = .reading
        if Self.forcesFailure {
            fail(link: "Couldn't read a recipe from this page.")
            return
        }
        await importer.importRecipe(from: url)
        guard let data = importer.extractedData else {
            fail(link: importer.errorMessage ?? "Couldn't read a recipe from this page.")
            return
        }
        let recipe = builder.build(from: data)
        var prefill = RecipeWizardView.PrefilledRecipeData(recipe: recipe)
        prefill.sourceConfidence = importer.parseConfidence
        HapticManager.shared.success()
        switch AddRecipeLinkResult.decide(recipeName: recipe.name, existingNames: existingNames) {
        case .review: phase = .review(prefill)
        case .duplicate: duplicateReview = prefill
        }
    }

    private func read(_ text: String) async {
        phase = .reading
        if !Self.forcesFailure, let prefill = await RecipeTextImportRouter().prefill(for: text) {
            HapticManager.shared.success()
            phase = .review(prefill)
        } else {
            HapticManager.shared.error()
            fallbackText = text
            phase = .textFailed(text)
        }
    }

    private func fail(link message: String) {
        HapticManager.shared.error()
        phase = .linkFailed(message)
    }

    // MARK: - Screens

    @ViewBuilder
    private var statusScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacing20) {
                switch phase {
                case .reading, .review: readingCard
                case .linkFailed(let message): linkFailedCard(message)
                case .textFailed: textFailedCard
                }
            }
            .padding(AppTheme.spacing20)
        }
    }

    private var readingCard: some View {
        VStack(spacing: AppTheme.spacing16) {
            ProgressView()
                .controlSize(.large)
            Text("Reading the recipe…")
                .font(.headline)
                .adaptiveForegroundColor()
            if case .link(let url) = source, let host = url.host() {
                Text(host.replacingOccurrences(of: "www.", with: ""))
                    .font(.subheadline)
                    .adaptiveSecondaryForeground()
            }
            Text("It opens ready to check and save.")
                .font(.footnote)
                .adaptiveSecondaryForeground()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacing40)
        .appCard()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("add.reading")
    }

    private func linkFailedCard(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing16) {
            Label("Couldn't read this page", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .adaptiveForegroundColor()
                .fixedSize(horizontal: false, vertical: true)
            Text("Copy the recipe from the page and paste it here — the ingredients and steps are read the same way.")
                .font(.footnote)
                .adaptiveSecondaryForeground()
                .fixedSize(horizontal: false, vertical: true)
            if showsFallbackEditor {
                fallbackEditor
            } else {
                PrimaryButton("Paste the recipe text instead", systemImage: "doc.on.clipboard", fillWidth: true) {
                    showsFallbackEditor = true
                }
                .accessibilityIdentifier("import.pasteInstead")
            }
            startBlankButton
        }
        .padding(AppTheme.spacing20)
        .appCard()
    }

    private var textFailedCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing16) {
            Label("No recipe found yet", systemImage: "text.magnifyingglass")
                .font(.headline)
                .foregroundStyle(.orange)
            Text("Put the ingredients and steps on separate lines and try again, or keep this text and fill in the rest yourself.")
                .font(.subheadline)
                .adaptiveForegroundColor()
                .fixedSize(horizontal: false, vertical: true)
            fallbackEditor
            PrimaryButton("Start from this text", systemImage: "square.and.pencil", fillWidth: true, variant: .secondary) {
                phase = .review(RecipeWizardView.PrefilledRecipeData(unparsedText: fallbackText))
            }
            .accessibilityIdentifier("import.startFromText")
        }
        .padding(AppTheme.spacing20)
        .appCard()
    }

    private var fallbackEditor: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            TextEditor(text: $fallbackText)
                .frame(minHeight: 160)
                .scrollContentBackground(.hidden)
                .padding(AppTheme.spacing8)
                .appInputField()
                .accessibilityIdentifier("add.fallbackText")
            PrimaryButton("Read this text", systemImage: "sparkles", fillWidth: true) {
                let text = fallbackText
                Task { await read(text) }
            }
            .disabled(fallbackText.isBlank)
            .accessibilityIdentifier("add.readText")
        }
    }

    private var startBlankButton: some View {
        Button("Start blank instead") {
            phase = .review(nil)
        }
        .font(.subheadline.weight(.semibold))
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("add.startBlank")
    }

    /// Screenshots/UI-test hook (`-force-import-failure`): links fail without a fetch and the text reader finds
    /// nothing, since on-device AI can read a recipe out of almost anything.
    private static var forcesFailure: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-force-import-failure")
        #else
        false
        #endif
    }
}
