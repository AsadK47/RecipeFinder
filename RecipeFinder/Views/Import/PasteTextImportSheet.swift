import SwiftUI

/// Paste-a-caption entry point: the user drops in free text (an Instagram/TikTok
/// caption, notes, a message), we route it through the on-device interpreter /
/// heuristic parser, and present the wizard to review and edit before saving.
struct PasteTextImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal

    @State private var text = ""
    @State private var prefill: RecipeWizardView.PrefilledRecipeData?
    @State private var showReview = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @FocusState private var focused: Bool

    /// Called with the finished recipe once the user confirms it in the wizard.
    var onImport: (RecipeModel) -> Void

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                    Text("Paste a recipe from anywhere — a caption, notes, or a message. We'll pull out the ingredients and steps for you to review.")
                        .font(.subheadline)
                        .adaptiveForegroundColor()

                    TextEditor(text: $text)
                        .focused($focused)
                        .frame(minHeight: 220)
                        .padding(AppTheme.spacing8)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
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
                            .foregroundColor(.orange)
                    }

                    Spacer()
                }
                .padding(AppTheme.spacing20)
                .navigationTitle("Paste Text")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        if isProcessing {
                            ProgressView()
                        } else {
                            Button("Import") { run() }
                                .disabled(trimmed.isEmpty)
                        }
                    }
                }
                .onAppear { focused = true }
            }
        }
        .sheet(isPresented: $showReview) {
            if let prefill {
                RecipeWizardView(prefilledData: prefill) { recipe in
                    onImport(recipe)
                    dismiss()
                }
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
                showReview = true
            } else {
                errorMessage = "Couldn't find a recipe in that text. Try putting ingredients and steps on separate lines."
                HapticManager.shared.error()
            }
        }
    }
}
