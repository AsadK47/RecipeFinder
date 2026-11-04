import SwiftUI

/// Paste-a-caption entry point: free text is routed through the on-device interpreter/heuristic parser, then the wizard is presented to review before saving.
struct PasteTextImportSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var prefill: RecipeWizardView.PrefilledRecipeData?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @FocusState private var focused: Bool

    /// Called with the finished recipe once the user confirms it in the wizard.
    var onImport: (RecipeModel) -> Void

    private var trimmed: String { text.trimmed }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing16) {
            Text("Paste a recipe from anywhere — a caption, notes, or a message. We'll pull out the ingredients and steps for you to review.")
                .font(.subheadline)
                .adaptiveForegroundColor()

            TextEditor(text: $text)
                .focused($focused)
                .frame(minHeight: 220)
                .padding(AppTheme.spacing8)
                .appCard(cornerRadius: AppTheme.cornerRadius12)
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("Paste recipe text here…")
                            .adaptiveSecondaryForeground()
                            .padding(AppTheme.spacing16)
                            .allowsHitTesting(false)
                    }
                }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }

            Spacer()
        }
        .padding(AppTheme.spacing20)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if isProcessing {
                    ProgressView()
                } else {
                    Button("Import") { run() }
                        .disabled(trimmed.isEmpty)
                }
            }
        }
        .sheetDismissButton("Cancel", placement: .cancellationAction)
        .onAppear { focused = true }
        .sheetScaffold("Paste Text")
        .sheet(item: $prefill) { prefill in
            RecipeWizardView(prefilledData: prefill) { recipe in
                onImport(recipe)
                dismiss()
            }
        }
    }

    private func run() {
        focused = false
        errorMessage = nil
        Task {
            isProcessing = true
            defer { isProcessing = false }
            if let result = await RecipeTextImportRouter().prefill(for: text) {
                prefill = result
            } else {
                errorMessage = "Couldn't find a recipe in that text. Try putting ingredients and steps on separate lines."
                HapticManager.shared.error()
            }
        }
    }
}
