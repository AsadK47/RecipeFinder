import SwiftUI

/// Compact opt-in sheet for choosing the clock time a meal reminder fires.
struct MealReminderSheet: View {
    let mealTime: MealTime
    let recipeName: String
    @State private var time: Date
    let onSave: (Date) -> Void
    let onCancel: () -> Void

    init(
        mealTime: MealTime,
        recipeName: String,
        initialTime: Date,
        onSave: @escaping (Date) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.mealTime = mealTime
        self.recipeName = recipeName
        self._time = State(initialValue: initialTime)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.spacing24) {
                DatePicker("Reminder time", selection: $time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()

                Text("We'll remind you to make \(recipeName) at this time.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding(AppTheme.spacing20)
            .navigationTitle("\(mealTime.rawValue) Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(time) }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
