import PhotosUI
import SwiftUI
import UIKit

/// Manage a recipe's photos (add/take/remove) outside the post-cook prompt and wizard; each change persists optimistically with rollback.
struct RecipePhotoManagerSheet: View {
    @Binding var recipe: RecipeModel

    @Environment(\.dismiss) private var dismiss

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var showSaveError = false
    @State private var photoViewer: PhotoViewerSource?
    @Environment(\.recipeStore) private var recipeStore

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: AppTheme.spacing12)]

    /// Every displayable image for the recipe: the main image first, then photos.
    private var allImageNames: [String] {
        ([recipe.imageName].compactMap { $0 } + recipe.photoNames)
            .filter { RecipeImageView.hasDisplayableImage($0) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: AppTheme.spacing20) {
                        if allImageNames.isEmpty {
                            emptyState
                        } else {
                            photoGrid
                        }
                        addButtons
                    }
                    .padding(AppTheme.spacing20)
                }
            }
            .appNavigationTitle("Photos")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { image in addPhotos([image]) }
            }
            .onChange(of: selectedItems) { _, items in
                guard !items.isEmpty else { return }
                Task { await addPickedItems(items) }
            }
            .alert("Couldn't Save Photos", isPresented: $showSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your photo change couldn't be saved. Please try again.")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.spacing8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: AppTheme.fontSize60))
                .adaptiveSecondaryForeground()
            Text("No photos yet")
                .font(.headline)
                .adaptiveForegroundColor()
            Text("Add a photo of this dish to bring the recipe to life.")
                .font(.subheadline)
                .adaptiveSecondaryForeground()
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacing24)
    }

    private var photoGrid: some View {
        LazyVGrid(columns: columns, spacing: AppTheme.spacing12) {
            ForEach(Array(allImageNames.enumerated()), id: \.element) { index, name in
                RecipeImageView(imageName: name, height: 100, recipeName: recipe.name)
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        photoViewer = PhotoViewerSource(imageNames: allImageNames, recipeName: recipe.name, startIndex: index)
                    }
                    .overlay(alignment: .topTrailing) {
                        Button {
                            removePhoto(name)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .black.opacity(0.5))
                                .padding(AppTheme.spacing6)
                        }
                        .accessibilityLabel("Remove photo")
                    }
            }
        }
        .fullScreenCover(item: $photoViewer) { FullScreenPhotoViewer(source: $0) }
    }

    private var addButtons: some View {
        VStack(spacing: AppTheme.spacing12) {
            PhotosPicker(selection: $selectedItems, matching: .images) {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.spacing14)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                            .fill(AppTheme.accentColor)
                    )
                    .foregroundStyle(.white)
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.plain)

            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button { showCamera = true } label: {
                    Label("Take Photo", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.spacing14)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                .fill(Color.white.opacity(AppTheme.overlayLightOpacity))
                        )
                        .adaptiveForegroundColor()
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Mutations (optimistic, persisted, rolled back on failure)

    private func addPickedItems(_ items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }
        selectedItems = []
        guard !images.isEmpty else { return }
        addPhotos(images)
    }

    private func addPhotos(_ images: [UIImage]) {
        let store = RecipeImageStore()
        let newPaths = store.persistGallery(images, recipeId: recipe.id, startingIndex: recipe.photoNames.count)
        guard !newPaths.isEmpty else { return }
        recipe.photoNames.append(contentsOf: newPaths)
        persist { recipe.photoNames.removeLast(newPaths.count) }
    }

    private func removePhoto(_ name: String) {
        let store = RecipeImageStore()
        let previousImageName = recipe.imageName
        let previousPhotoNames = recipe.photoNames

        if recipe.imageName == name {
            recipe.imageName = nil
        } else {
            recipe.photoNames.removeAll { $0 == name }
        }

        persist(
            onFailure: {
                recipe.imageName = previousImageName
                recipe.photoNames = previousPhotoNames
            },
            onSuccess: { store.deleteIfLocal(name) }
        )
    }

    /// Persists the recipe; on failure runs `onFailure` to roll back the optimistic edit and surfaces an alert.
    private func persist(onFailure: () -> Void, onSuccess: () -> Void = {}) {
        guard recipeStore.save(recipe) else {
            onFailure()
            showSaveError = true
            return
        }
        onSuccess()
        HapticManager.shared.success()
    }
}
