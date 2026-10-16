import SwiftUI
import PhotosUI

private let logger = AppLogger.logger(category: "PhotoImport")

/// Photo-to-recipe: pick or capture a cookbook page/screenshot, OCR on device (Vision), route the text through the shared interpreter, then present the wizard to review before saving.
struct PhotoImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal

    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var prefill: RecipeWizardView.PrefilledRecipeData?
    @State private var isProcessing = false
    @State private var errorMessage: String?

    private let recognizer: RecipeImageTextRecognizing = VisionRecipeImageTextRecognizer()

    /// Called with the finished recipe once the user confirms it in the wizard.
    var onImport: (RecipeModel) -> Void

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        // Capture theme/scheme as Sendable values so the @Sendable label closures don't touch @MainActor state.
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
                            .foregroundStyle(.orange)
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
        // Process after the camera sheet fully dismisses; presenting the review sheet while the camera is still dismissing makes SwiftUI drop it.
        .sheet(isPresented: $showCamera, onDismiss: {
            if let image = capturedImage {
                capturedImage = nil
                Task { await process(image) }
            }
        }) {
            CameraPicker { image in
                capturedImage = image
                showCamera = false
            }
            .ignoresSafeArea()
        }
        .sheet(item: $prefill) { prefill in
            RecipeWizardView(prefilledData: prefill) { recipe in
                onImport(recipe)
                dismiss()
            }
        }
    }

    private func handlePickedItem(_ item: PhotosPickerItem) async {
        selectedItem = nil
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "That image couldn't be loaded."
                return
            }
            await process(image)
        } catch {
            logger.error("❌ Failed to load picked photo: \(error)")
            errorMessage = "That image couldn't be loaded."
        }
    }

    private func process(_ image: UIImage) async {
        errorMessage = nil
        isProcessing = true
        defer { isProcessing = false }
        do {
            let text = try await recognizer.recognizeText(in: image)
            if let result = await RecipeTextImportRouter().prefill(for: text) {
                prefill = result
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

/// File-scope so the nonisolated PhotosPicker/Button label builders can build it without crossing actor isolation.
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
