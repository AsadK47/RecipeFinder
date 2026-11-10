import SwiftUI

/// What the review sheet is estimating for; Identifiable so the sheet is presented with `.sheet(item:)`.
struct AmountEstimateTarget: Identifiable {
    let id = UUID()
    let request: AmountEstimateRequest
    let ingredients: [Ingredient]
}

/// "Estimate amounts": the on-device model suggests amounts for the gaps, the cook checks or edits each one, and only
/// what they save is written back. Nothing leaves the device.
struct AmountEstimateReviewSheet: View {
    let target: AmountEstimateTarget
    let estimator: IngredientAmountEstimating
    /// Called with the recipe's ingredients, gaps filled from the accepted rows.
    let onSave: ([Ingredient]) -> Void
    /// The no-dead-end fallback when estimating fails: open the editor to type amounts by hand.
    let onEditManually: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var rows: [AmountEstimateDraftRow] = []
    @State private var phase = Phase.estimating

    private enum Phase { case estimating, review, failed }

    var body: some View {
        content
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(phase != .review || AmountEstimateDraft.estimates(from: rows).isEmpty)
                        .accessibilityIdentifier("estimate.save")
                }
            }
            .sheetDismissButton("Cancel", placement: .cancellationAction)
            .sheetScaffold("Estimate Amounts")
            .task { await estimate() }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .estimating:
            VStack(spacing: AppTheme.spacing12) {
                ProgressView()
                Text("Estimating amounts on your device…")
                    .font(.subheadline)
                    .adaptiveSecondaryForeground()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed:
            VStack(spacing: AppTheme.spacing12) {
                Text("Couldn't estimate amounts for this recipe.")
                    .font(.subheadline)
                    .adaptiveForegroundColor()
                Button("Add your amounts") {
                    dismiss()
                    onEditManually()
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .review:
            reviewList
        }
    }

    private var reviewList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                Text("Suggested amounts — check them before you cook. Clear any you'd rather leave blank.")
                    .font(.subheadline)
                    .adaptiveSecondaryForeground()
                ForEach($rows) { $row in
                    HStack(spacing: AppTheme.spacing8) {
                        Text(row.name)
                            .font(.body)
                            .adaptiveForegroundColor()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        TextField("Amount", text: $row.quantityText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 72)
                            .textFieldStyle(.plain)
                            .appInputField()
                            .accessibilityLabel("Amount of \(row.name)")
                        TextField("Unit", text: $row.unit)
                            .textInputAutocapitalization(.never)
                            .frame(width: 64)
                            .textFieldStyle(.plain)
                            .appInputField()
                            .accessibilityLabel("Unit for \(row.name)")
                    }
                    .padding(AppTheme.spacing12)
                    .appCard()
                }
            }
            .padding(AppTheme.spacing20)
        }
    }

    private func estimate() async {
        do {
            guard let estimates = try await estimator.estimateAmounts(for: target.request) else {
                phase = .failed
                return
            }
            rows = AmountEstimateDraft.rows(for: target.request, ingredients: target.ingredients, estimates: estimates)
            phase = rows.isEmpty ? .failed : .review
        } catch {
            Self.logger.error("Amount estimate failed: \(error.localizedDescription, privacy: .public)")
            phase = .failed
        }
    }

    private func save() {
        onSave(AmountEstimateApplier.apply(AmountEstimateDraft.estimates(from: rows), to: target.ingredients))
        dismiss()
    }

    private static let logger = AppLogger.logger(category: "AmountEstimate")
}
