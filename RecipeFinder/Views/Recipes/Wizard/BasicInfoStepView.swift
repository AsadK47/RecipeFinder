import SwiftUI

/// Step 2 of the Recipe Wizard: prep/cook time, difficulty, category, servings.
struct BasicInfoStepView: View {
    @Binding var prepTime: Int
    @Binding var cookTime: Int
    @Binding var difficulty: String
    @Binding var category: String
    @Binding var servings: Int
    let difficulties: [String]
    let categories: [String]
    let appTheme: AppTheme.ThemeType
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    let totalSteps: Int

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
            WizardStepHeader(
                title: "Tell us more",
                subtitle: "Add some details about your recipe",
                stepNumber: 2,
                totalSteps: totalSteps,
                illustration: "slider.horizontal.3"
            )

            WizardCard(cardStyle: cardStyle, colorScheme: colorScheme) {
                VStack(spacing: AppTheme.spacing24) {
                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        Text("Prep Time")
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack {
                            Stepper("\(prepTime) minutes", value: $prepTime, in: 0...300, step: 5)
                                .font(.body)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        Text("Cook Time")
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack {
                            Stepper("\(cookTime) minutes", value: $cookTime, in: 0...480, step: 5)
                                .font(.body)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        Text("Difficulty")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Picker("Difficulty", selection: $difficulty) {
                            ForEach(difficulties, id: \.self) { diff in
                                Text(diff).tag(diff)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        Text("Category")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Picker("Category", selection: $category) {
                            ForEach(categories, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        Text("Servings")
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack {
                            Stepper(
                                value: $servings, in: 1...20,
                                label: {
                                    HStack(spacing: AppTheme.spacing8) {
                                        Text("\(servings)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(AppTheme.accentColor(for: appTheme))
                                            .frame(minWidth: AppTheme.iconSize32)
                                        Text(servings == 1 ? "serving" : "servings")
                                            .font(.body)
                                            .adaptiveSecondaryForeground()
                                    }
                                }
                            )
                        }
                    }
                }
                .padding()
            }
        }
    }
}
