import SwiftUI

/// Metric / imperial measurement system picker.
struct UnitsSettingsView: View {
    @AppStorage("measurementSystem") private var measurementSystem: MeasurementSystem = .metric

    var body: some View {
        SettingsScreen("Units & Measurements") {
            VStack(spacing: AppTheme.spacing8) {
                SettingsSectionHeader(title: "Measurement System")

                SettingsCard {
                    VStack(spacing: 0) {
                        ForEach(Array(MeasurementSystem.allCases.enumerated()), id: \.element) { index, system in
                            SettingsChoiceRow(
                                icon: "\(system.icon).fill",
                                iconColor: .blue,
                                title: system.rawValue,
                                subtitle: system == .metric ? "kg, g, ml, l" : "lb, oz, cups, fl oz",
                                isSelected: measurementSystem == system
                            ) {
                                measurementSystem = system
                            }

                            if index < MeasurementSystem.allCases.count - 1 {
                                SettingsRowDivider()
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        UnitsSettingsView()
    }
}
