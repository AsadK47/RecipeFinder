import SwiftUI

/// Groceries' "From your plan" card: what the next seven days of planned meals still need from the shop, added in
/// one tap. It disappears once the list (or the kitchen) covers the plan.
struct PlanGroceriesCard: View {
    let plan: WeekGroceryPlan
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            HStack(spacing: AppTheme.spacing12) {
                IconBadge(systemName: "calendar.badge.checkmark", tint: AppTheme.accentColor, diameter: 40)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                    Text("From your plan")
                        .font(.headline)
                        .adaptiveForegroundColor()
                    Text(plan.cardDetail)
                        .font(.subheadline)
                        .adaptiveSecondaryForeground()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
            PrimaryButton(plan.addButtonTitle, systemImage: "cart.badge.plus", fillWidth: true, action: onAdd)
                .accessibilityIdentifier("groceries.fromPlan.add")
        }
        .padding()
        .appCard()
    }
}
