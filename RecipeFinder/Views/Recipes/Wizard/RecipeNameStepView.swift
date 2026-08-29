import SwiftUI

/// Step 1 of the Recipe Wizard: recipe name and photo.
struct RecipeNameStepView: View {
    @Binding var recipeName: String
    @Binding var selectedRecipeImage: UIImage?
    @Binding var existingImageReference: String?
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    let totalSteps: Int
    let onPickPhoto: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
            WizardStepHeader(
                title: "Let's start with a name",
                subtitle: "What would you like to call this recipe?",
                stepNumber: 1,
                totalSteps: totalSteps,
                illustration: "doc.text.fill"
            )

            WizardCard(cardStyle: cardStyle, colorScheme: colorScheme) {
                VStack(spacing: AppTheme.spacing16) {
                    TextField("Recipe Name", text: $recipeName)
                        .font(.title2)
                        .padding()
                        .background(Color.white.opacity(AppTheme.dividerOpacity))
                        .cornerRadius(AppTheme.cornerRadius12)

                    VStack(alignment: .leading, spacing: AppTheme.spacing10) {
                        Text("Recipe Photo")
                            .font(.headline)
                            .foregroundColor(.primary)

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
                                                        .foregroundColor(.secondary)
                                                    Text("Add photo")
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                    }
                                }
                                .overlay(alignment: .bottomTrailing) {
                                    if selectedRecipeImage != nil || existingImageReference != nil {
                                        Label("Tap to change", systemImage: "photo.on.rectangle")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundColor(.white)
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
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(.black.opacity(0.55), in: Circle())
                                }
                                .buttonStyle(.plain)
                                .padding(AppTheme.spacing8)
                            }
                        }
                    }

                    if let validationMessage = recipeNameValidationMessage {
                        Text(validationMessage)
                            .font(.caption)
                            .foregroundColor(.red)
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
