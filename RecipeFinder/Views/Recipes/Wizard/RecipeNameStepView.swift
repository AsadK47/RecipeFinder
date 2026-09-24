import SwiftUI

/// Step 1 of the Recipe Wizard: recipe name and photo.
struct RecipeNameStepView: View {
    @Binding var recipeName: String
    @Binding var selectedRecipeImage: UIImage?
    @Binding var existingImageReference: String?
    @Binding var selectedGalleryImages: [UIImage]
    @Binding var existingGalleryReferences: [String]
    let colorScheme: ColorScheme
    let onPickPhoto: () -> Void
    let onAddGalleryPhoto: () -> Void

    private var totalGalleryCount: Int {
        existingGalleryReferences.count + selectedGalleryImages.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
            WizardStepHeader(
                title: "Let's start with a name",
                subtitle: "What would you like to call this recipe?",
                illustration: "doc.text.fill"
            )

            WizardCard {
                VStack(spacing: AppTheme.spacing16) {
                    TextField("Recipe Name", text: $recipeName)
                        .font(.title2)
                        .padding()
                        .background(Color.white.opacity(AppTheme.dividerOpacity))
                        .cornerRadius(AppTheme.cornerRadius12)

                    VStack(alignment: .leading, spacing: AppTheme.spacing10) {
                        Text("Recipe Photo")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        ZStack(alignment: .topTrailing) {
                            Button(action: onPickPhoto) {
                                Group {
                                    if let selectedRecipeImage {
                                        Image(uiImage: selectedRecipeImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 180)
                                            .frame(maxWidth: .infinity)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
                                    } else if let existingImageReference, !existingImageReference.isEmpty {
                                        RecipeImageView(imageName: existingImageReference, height: 180)
                                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
                                    } else {
                                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                            .fill(Color.white.opacity(AppTheme.dividerOpacity))
                                            .frame(height: 180)
                                            .overlay {
                                                VStack(spacing: AppTheme.spacing8) {
                                                    Image(systemName: "photo.badge.plus")
                                                        .font(.system(size: AppTheme.fontSize28))
                                                        .adaptiveSecondaryForeground()
                                                    Text("Add photo")
                                                        .font(.subheadline)
                                                        .adaptiveSecondaryForeground()
                                                }
                                            }
                                    }
                                }
                                .overlay(alignment: .bottomTrailing) {
                                    if selectedRecipeImage != nil || existingImageReference != nil {
                                        Label("Tap to change", systemImage: "photo.on.rectangle")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, AppTheme.spacing8)
                                            .padding(.vertical, AppTheme.spacing4)
                                            .background(.black.opacity(0.45), in: Capsule())
                                            .padding(AppTheme.spacing10)
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            if selectedRecipeImage != nil || existingImageReference != nil {
                                Button(action: {
                                    HapticManager.shared.light()
                                    selectedRecipeImage = nil
                                    existingImageReference = nil
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(.black.opacity(0.55), in: Circle())
                                }
                                .buttonStyle(.plain)
                                .padding(AppTheme.spacing8)
                            }
                        }
                    }

                    Divider()
                        .padding(.vertical, AppTheme.spacing4)

                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        HStack {
                            Text("Additional Photos")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("Up to 4")
                                .font(.caption)
                                .adaptiveSecondaryForeground()
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppTheme.spacing8) {
                                ForEach(Array(existingGalleryReferences.enumerated()), id: \.offset) { idx, ref in
                                    ZStack(alignment: .topTrailing) {
                                        RecipeImageView(imageName: ref, height: 80)
                                            .frame(width: 80, height: 80)
                                        Button {
                                            existingGalleryReferences.remove(at: idx)
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.white)
                                                .frame(width: 20, height: 20)
                                                .background(.black.opacity(0.55), in: Circle())
                                        }
                                        .buttonStyle(.plain)
                                        .padding(4)
                                    }
                                }

                                ForEach(Array(selectedGalleryImages.enumerated()), id: \.offset) { idx, img in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius8))
                                        Button {
                                            selectedGalleryImages.remove(at: idx)
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.white)
                                                .frame(width: 20, height: 20)
                                                .background(.black.opacity(0.55), in: Circle())
                                        }
                                        .buttonStyle(.plain)
                                        .padding(4)
                                    }
                                }

                                if totalGalleryCount < 4 {
                                    Button(action: onAddGalleryPhoto) {
                                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius8)
                                            .fill(Color.white.opacity(AppTheme.dividerOpacity))
                                            .frame(width: 80, height: 80)
                                            .overlay {
                                                VStack(spacing: AppTheme.spacing4) {
                                                    Image(systemName: "plus")
                                                        .font(.system(size: AppTheme.fontSize20))
                                                        .adaptiveSecondaryForeground()
                                                    Text("Add")
                                                        .font(.caption2)
                                                        .adaptiveSecondaryForeground()
                                                }
                                            }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    if let validationMessage = recipeNameValidationMessage {
                        Text(validationMessage)
                            .font(.caption)
                            .foregroundStyle(AppTheme.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
        }
    }

    private var recipeNameValidationMessage: String? {
        let trimmed = recipeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        do {
            try Validator.validateRecipeName(recipeName)
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}
