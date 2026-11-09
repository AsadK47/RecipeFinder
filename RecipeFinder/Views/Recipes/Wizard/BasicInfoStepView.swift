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

    /// 0 means the cook hasn't set it — say so, matching the recipe screen, rather than "0 minutes".
    private func timeLabel(_ minutes: Int) -> String {
        minutes == 0 ? "Not set" : DurationFormatter.label(minutes: minutes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
            WizardStepHeader(
                title: "Tell us more",
                subtitle: "Add some details about your recipe",
                illustration: "slider.horizontal.3"
            )

            WizardCard {
                VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        Text("Prep Time")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        HStack {
                            Stepper(timeLabel(prepTime), value: $prepTime, in: 0...300, step: 5)
                                .font(.body)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        Text("Cook Time")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        HStack {
                            Stepper(timeLabel(cookTime), value: $cookTime, in: 0...480, step: 5)
                                .font(.body)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        Text("Difficulty")
                            .font(.headline)
                            .foregroundStyle(.primary)

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
                            .foregroundStyle(.primary)

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
                            .foregroundStyle(.primary)

                        HStack {
                            Stepper(
                                value: $servings, in: 1...20,
                                label: {
                                    HStack(spacing: AppTheme.spacing8) {
                                        Text("\(servings)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .adaptiveForegroundColor()
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
