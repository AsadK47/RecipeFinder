import SwiftUI

/// Navigation chrome for `RecipeWizardView`: the top bar, step progress bar,
/// and the back/next footer. Split out to keep the main view focused on state
/// and step routing; these are pure UI driven by the view's existing state.
extension RecipeWizardView {

    var headerBar: some View {
        GeometryReader { geometry in
            HStack {
                Button(action: {
                    HapticManager.shared.selection()
                    dismiss()
                }) {
                    Text("Cancel")
                        .font(.body)
                        .adaptiveForegroundColor()
                        .padding(.horizontal, AppTheme.spacing16)
                        .padding(.vertical, AppTheme.spacing8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(AppTheme.cornerRadius12)
                }

                Spacer()

                Text("Recipe Wizard")
                    .font(.system(size: min(24, geometry.size.width * 0.06), weight: .bold))
                    .adaptiveForegroundColor()

                Spacer()

                // Invisible mirror of the Cancel button so the title stays centred.
                Button(action: {}) {
                    Text("Cancel")
                        .font(.body)
                        .foregroundStyle(.clear)
                        .padding(.horizontal, AppTheme.spacing16)
                        .padding(.vertical, AppTheme.spacing8)
                }
                .disabled(true)
            }
        }
        .frame(height: AppTheme.height44)
    }

    var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(AppTheme.shadowDarkOpacity))

                Rectangle()
                    .fill(Color.white)
                    .frame(width: geometry.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps))
            }
        }
        .frame(height: AppTheme.height4)
        .padding(.horizontal, AppTheme.spacing20)
        .padding(.top, AppTheme.spacing8)
    }

    var navigationButtons: some View {
        HStack(spacing: AppTheme.spacing16) {
            if currentStep > 0 {
                Button(action: {
                    HapticManager.shared.selection()
                    withAnimation {
                        currentStep -= 1
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(AppTheme.shadowDarkOpacity))
                    .adaptiveForegroundColor()
                    .cornerRadius(AppTheme.cornerRadius12)
                }
            }

            Button(action: {
                HapticManager.shared.selection()
                if currentStep < totalSteps - 1 {
                    withAnimation {
                        currentStep += 1
                    }
                } else {
                    createRecipe()
                }
            }) {
                HStack {
                    Text(currentStep < totalSteps - 1 ? "Next" : (editingRecipeId != nil ? "Update Recipe" : "Create Recipe"))
                    if currentStep < totalSteps - 1 {
                        Image(systemName: "chevron.right")
                    } else {
                        Image(systemName: "checkmark")
                    }
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canProceed ? Color.white : Color.white.opacity(AppTheme.glassLightOpacity))
                .foregroundStyle(canProceed ? AppTheme.accentColor(for: appTheme) : .white)
                .cornerRadius(AppTheme.cornerRadius12)
            }
            .disabled(!canProceed)
        }
        .padding()
    }

    var canProceed: Bool {
        switch currentStep {
        case 0:
            do {
                try Validator.validateRecipeName(recipeName)
                return true
            } catch {
                return false
            }
        case 1:
            return servings > 0
        case 2:
            return ingredientItems.contains { !$0.name.isEmpty }
        case 3:
            return true
        case 4:
            return mainInstructions.contains { !$0.text.isEmpty }
        case 5:
            return true
        default:
            return false
        }
    }
}
