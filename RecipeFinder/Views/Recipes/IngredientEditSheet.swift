import SwiftUI

/// A form for editing a single ingredient's amount and unit. Extracted from
/// `RecipeDetailView`; the parent owns the edited values and the save action.
struct IngredientEditSheet: View {
    let ingredientName: String
    @Binding var editingQuantity: String
    @Binding var editingUnit: String
    let onCancel: () -> Void
    let onSave: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal

    private let cookingUnits: [(group: String, units: [String])] = [
        ("Volume – Metric",   ["ml", "cl", "dl", "l"]),
        ("Volume – Imperial", ["tsp", "tbsp", "fl oz", "cup", "pt", "qt", "gal"]),
        ("Weight – Metric",   ["g", "kg"]),
        ("Weight – Imperial", ["oz", "lb"]),
        ("Count & Other",     ["piece", "whole", "slice", "clove", "can", "jar",
                               "package", "bunch", "sprig", "leaf", "sheet",
                               "pinch", "dash", "drop", "handful"]),
    ]

    private func groupLabel(for unit: String) -> String {
        cookingUnits.first { $0.units.contains(unit) }?.group ?? "Other"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()

                Form {
                    Section {
                        Text(ingredientName)
                            .font(.headline)
                    } header: {
                        Text("Ingredient")
                    }

                    Section {
                        HStack {
                            Text("Amount")
                            Spacer()
                            TextField("0", text: $editingQuantity)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: AppTheme.width80)
                        }

                        Picker("Unit", selection: $editingUnit) {
                            Text("none").tag("")
                            ForEach(cookingUnits, id: \.group) { group in
                                Section(group.group) {
                                    ForEach(group.units, id: \.self) { unit in
                                        Text(unit).tag(unit)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Quantity")
                    } footer: {
                        if !editingUnit.isEmpty {
                            Text("Group: \(groupLabel(for: editingUnit))")
                                .font(.caption)
                                .adaptiveSecondaryForeground()
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
