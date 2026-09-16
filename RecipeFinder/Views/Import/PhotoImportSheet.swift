import SwiftUI
import PhotosUI

/// Photo-to-recipe entry point: pick a cookbook page / screenshot from the
/// library or capture one with the camera, OCR it on device (Vision), then route
/// the recognised text through the same interpreter/parser and present the
/// wizard to review and edit before saving.
struct PhotoImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal

    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var prefill: RecipeWizardView.PrefilledRecipeData?
    @State private var showReview = false
    @State private var isProcessing = false
    @State private var errorMessage: String?

    private let recognizer: RecipeImageTextRecognizing = VisionRecipeImageTextRecognizer()

    /// Called with the finished recipe once the user confirms it in the wizard.
    var onImport: (RecipeModel) -> Void

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        // Capture the actor-isolated theme as a Sendable value so the picker/button
        // label closures (inferred @Sendable under Swift 6) don't touch @MainActor state.
        let theme = selectedTheme
        let scheme = colorScheme
        return NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: theme, colorScheme: scheme)
                    .ignoresSafeArea()

                VStack(spacing: AppTheme.spacing16) {
                    Text("Point at a cookbook page, screenshot, or handwritten recipe. We read the text on your device — nothing leaves your phone.")
                        .font(.subheadline)
                        .adaptiveForegroundColor()
                        .multilineTextAlignment(.center)

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        photoSourceLabel(icon: "photo.on.rectangle", title: "Choose from Library", theme: theme)
                    }
                    .disabled(isProcessing)

                    if cameraAvailable {
                        Button { showCamera = true } label: {
                            photoSourceLabel(icon: "camera", title: "Take a Photo", theme: theme)
                        }
                        .disabled(isProcessing)
                    }

                    if isProcessing {
                        ProgressView("Reading recipe…")
                            .padding(.top, AppTheme.spacing8)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()
                }
                .padding(AppTheme.spacing20)
                .navigationTitle("Scan a Photo")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task { await handlePickedItem(newItem) }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                Task { await process(image) }
            }
            .ignoresSafeArea()
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

    private func handlePickedItem(_ item: PhotosPickerItem) async {
        selectedItem = nil
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            errorMessage = "That image couldn't be loaded."
            return
        }
        await process(image)
    }

    private func process(_ image: UIImage) async {
        errorMessage = nil
        isProcessing = true
        defer { isProcessing = false }
        do {
            let text = try await recognizer.recognizeText(in: image)
            if let result = await RecipeTextImportRouter().prefill(for: text) {
                prefill = result
                showReview = true
            } else {
                errorMessage = "Couldn't find a recipe in that photo. Try a clearer, straight-on shot."
                HapticManager.shared.error()
            }
        } catch {
            errorMessage = "That image couldn't be read."
            HapticManager.shared.error()
        }
    }
}

/// File-scope so the `PhotosPicker`/`Button` label builders (inferred nonisolated
/// under Swift 6) can build it without crossing actor isolation.
@ViewBuilder
private func photoSourceLabel(icon: String, title: String, theme: AppTheme.ThemeType) -> some View {
    HStack(spacing: AppTheme.spacing12) {
        Image(systemName: icon)
        Text(title).fontWeight(.semibold)
    }
    .adaptiveForegroundColor()
    .frame(maxWidth: .infinity)
    .frame(height: AppTheme.height56)
    .background(AppTheme.accentColor(for: theme), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius16))
}
