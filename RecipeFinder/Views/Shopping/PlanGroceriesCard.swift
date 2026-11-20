import SwiftUI

/// Groceries' "From your plan" card: what the next seven days of planned meals still need from the shop, added in
/// one tap. It goes once the list (or the kitchen) covers the plan, or on Not now until the plan needs more.
struct PlanGroceriesCard: View {
    let plan: WeekGroceryPlan
    let onAdd: () -> Void
    let onNotNow: () -> Void

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
            HStack(spacing: AppTheme.spacing8) {
                PrimaryButton(plan.addButtonTitle, systemImage: "cart.badge.plus", fillWidth: true, action: onAdd)
                    .accessibilityIdentifier("groceries.fromPlan.add")
                PrimaryButton("Not now", variant: .secondary, action: onNotNow)
                    .fixedSize()
                    .accessibilityIdentifier("groceries.fromPlan.notNow")
            }
        }
        .padding()
        .appCard()
    }
}
