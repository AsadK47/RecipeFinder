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

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
            WizardCard {
                VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        Text("Prep Time")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        DurationPicker(title: "Prep Time", minutes: $prepTime, maxHours: 5)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        Text("Cook Time")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        DurationPicker(title: "Cook Time", minutes: $cookTime, maxHours: 8)
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
                                value: $servings, in: Validator.servingsRange,
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

/// Hours + minutes menus: one tap each instead of dozens of 5-minute stepper taps. 0 reads "Not set", as on the recipe screen.
private struct DurationPicker: View {
    let title: String
    @Binding var minutes: Int
    let maxHours: Int

    var body: some View {
        HStack(spacing: AppTheme.spacing8) {
            Text(minutes == 0 ? "Not set" : DurationFormatter.label(minutes: minutes))
                .adaptiveSecondaryForeground()
            Spacer()
            Picker("\(title) hours", selection: Binding(
                get: { DurationFormatter.hours(of: minutes) },
                set: { minutes = DurationFormatter.total(minutes, settingHours: $0) }
            )) {
                ForEach(0...max(maxHours, DurationFormatter.hours(of: minutes)), id: \.self) { Text("\($0) hr").tag($0) }
            }
            .pickerStyle(.menu)
            Picker("\(title) minutes", selection: Binding(
                get: { DurationFormatter.minutes(of: minutes) },
                set: { minutes = DurationFormatter.total(minutes, settingMinutes: $0) }
            )) {
                ForEach(DurationFormatter.minuteChoices(including: minutes), id: \.self) { Text("\($0) min").tag($0) }
            }
            .pickerStyle(.menu)
        }
        .frame(minHeight: 44)
    }
}
