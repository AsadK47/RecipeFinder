import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

private let logger = AppLogger.logger(category: "PhotoImport")

/// Photo-to-recipe: pick up to five photos (a recipe over several pages), a PDF, or capture a cookbook page, OCR on device (Vision), route the text through the shared interpreter, then present the wizard to review before saving.
struct PhotoImportSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isPickingPDF = false
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var prefill: RecipeWizardView.PrefilledRecipeData?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    /// Text the photo yielded when no recipe was found — kept so the cook can start from it instead of a dead end.
    @State private var unparsedText: String?

    private let recognizer: RecipeImageTextRecognizing = VisionRecipeImageTextRecognizer()

    /// Called with the finished recipe once the user confirms it in the wizard.
    var onImport: (RecipeModel) -> Void

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        // Capture the theme as a Sendable value so the @Sendable label closures don't touch @MainActor state.
        let theme = ThemeStore.shared.theme
        return VStack(spacing: AppTheme.spacing16) {
            Text("Point at a cookbook page, screenshot, or handwritten recipe — or pick up to \(MultiPageRecipeReader.maxPhotos) photos, or a PDF. We read the text on your device — nothing leaves your phone.")
                .font(.subheadline)
                .adaptiveForegroundColor()
                .multilineTextAlignment(.center)

            PhotosPicker(selection: $selectedItems, maxSelectionCount: MultiPageRecipeReader.maxPhotos, matching: .images) {
                photoSourceLabel(icon: "photo.on.rectangle", title: "Choose from Library", theme: theme)
            }
            .disabled(isProcessing)

            Button { isPickingPDF = true } label: {
                photoSourceLabel(icon: "doc.richtext", title: "Choose a PDF", theme: theme)
            }
            .disabled(isProcessing)
            .accessibilityIdentifier("import.pdf")

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

            if let unparsedText {
                Button("Start from this text") {
                    prefill = RecipeWizardView.PrefilledRecipeData(unparsedText: unparsedText)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("import.startFromText")
            }

            Spacer()
        }
        .padding(AppTheme.spacing20)
        .sheetDismissButton("Cancel", placement: .cancellationAction)
        .sheetScaffold("Scan a Photo")
        .onChange(of: selectedItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task { await handlePickedItems(newItems) }
        }
        .fileImporter(isPresented: $isPickingPDF, allowedContentTypes: [.pdf]) { result in
            switch result {
            case let .success(url): Task { await processPDF(at: url) }
            case .failure: errorMessage = "That PDF couldn't be opened."
            }
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

    private var reader: MultiPageRecipeReader { MultiPageRecipeReader(recognizer: recognizer) }

    /// Several photos are one recipe across pages, read in the order picked.
    private func handlePickedItems(_ items: [PhotosPickerItem]) async {
        selectedItems = []
        var images: [UIImage] = []
        for item in items {
            do {
                guard let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
                    errorMessage = "One of those images couldn't be loaded."
                    return
                }
                images.append(image)
            } catch {
                logger.error("❌ Failed to load picked photo: \(error)")
                errorMessage = "One of those images couldn't be loaded."
                return
            }
        }
        await read { try await reader.text(fromImages: images) }
    }

    private func processPDF(at url: URL) async {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            await read { try await reader.text(fromPDF: data) }
        } catch {
            errorMessage = "That PDF couldn't be opened."
            HapticManager.shared.error()
        }
    }

    private func process(_ image: UIImage) async {
        await read { try await recognizer.recognizeText(in: image) }
    }

    /// Gets the text (OCR, PDF text, or several pages), then routes it like any other text import.
    private func read(_ extract: () async throws -> String) async {
        errorMessage = nil
        unparsedText = nil
        isProcessing = true
        defer { isProcessing = false }
        do {
            let text = try await extract()
            if let result = await RecipeTextImportRouter().prefill(for: text) {
                prefill = result
            } else {
                errorMessage = "Couldn't find a recipe in that photo. Try a clearer, straight-on shot."
                unparsedText = text.trimmed.isEmpty ? nil : text
                HapticManager.shared.error()
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "That image couldn't be read."
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
