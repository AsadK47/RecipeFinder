import SwiftUI

/// Settings → Data Management → Recently Deleted: recipes the cook deleted, kept with their photos for 30 days.
/// Restore puts one back; Delete Now removes it (and its photos) straight away.
struct RecentlyDeletedView: View {
    @Environment(\.recipeStore) private var recipeStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingDelete: DeletedRecipe?
    @State private var failure: String?

    var body: some View {
        SettingsScreen("Recently Deleted") {
            if recipeStore.recentlyDeleted.isEmpty {
                emptyState
            } else {
                Text("Recipes you delete wait here with their photos for 30 days, so you can bring them back.")
                    .font(.subheadline)
                    .adaptiveSecondaryForeground()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                SettingsCard {
                    VStack(spacing: 0) {
                        ForEach(Array(recipeStore.recentlyDeleted.enumerated()), id: \.element.id) { index, item in
                            if index > 0 { SettingsRowDivider() }
                            row(item)
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("recentlyDeleted.screen")
        .confirmationDialog(
            "Delete this recipe now?",
            isPresented: .isPresent($confirmingDelete),
            titleVisibility: .visible,
            presenting: confirmingDelete
        ) { item in
            Button("Delete Now", role: .destructive) { deleteNow(item) }
            Button("Cancel", role: .cancel) { confirmingDelete = nil }
        } message: { item in
            Text("\(item.recipe.name) and its photos will be removed for good.")
        }
        .errorAlert("Something Went Wrong", message: $failure)
    }

    private var emptyState: some View {
        SettingsCard {
            VStack(spacing: AppTheme.spacing12) {
                IconBadge(systemName: "trash", tint: .gray, diameter: AppTheme.width80,
                          iconSize: AppTheme.fontSize50, weight: .regular)
                Text("Nothing here")
                    .font(.headline)
                    .adaptiveForegroundColor()
                Text("Recipes you delete wait here for 30 days, so you can bring them back.")
                    .font(.subheadline)
                    .adaptiveSecondaryForeground()
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                PrimaryButton("Back to Settings", size: .compact, variant: .secondary) { dismiss() }
            }
            .padding(AppTheme.spacing20)
        }
    }

    private func row(_ item: DeletedRecipe) -> some View {
        HStack(spacing: AppTheme.spacing12) {
            RecipeImageView(recipe: item.recipe, imageName: item.recipe.heroImageName, height: 56)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius10))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                Text(item.recipe.name)
                    .font(.body.weight(.semibold))
                    .adaptiveForegroundColor()
                    .lineLimit(2)
                Text(RecentlyDeleted.daysLeftText(item, now: Date()))
                    .font(.caption)
                    .adaptiveSecondaryForeground()
            }

            Spacer(minLength: AppTheme.spacing8)

            PrimaryButton("Restore", size: .compact) { restore(item) }
                .accessibilityLabel("Restore \(item.recipe.name)")
                .accessibilityIdentifier("recentlyDeleted.restore")

            Button { confirmingDelete = item } label: {
                Image(systemName: "trash")
                    .font(.body)
                    .adaptiveForegroundColor()
                    .frame(width: AppTheme.iconSize40, height: AppTheme.iconSize40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete \(item.recipe.name) now")
        }
        .padding(.horizontal, AppTheme.spacing16)
        .padding(.vertical, AppTheme.spacing12)
    }

    private func restore(_ item: DeletedRecipe) {
        if withAnimation(.appSpring, { recipeStore.restore(id: item.id) }) {
            HapticManager.shared.success()
        } else {
            HapticManager.shared.error()
            failure = "\(item.recipe.name) couldn't be restored. Please try again."
        }
    }

    private func deleteNow(_ item: DeletedRecipe) {
        confirmingDelete = nil
        if withAnimation(.appSpring, { recipeStore.deleteForever(id: item.id) }) {
            HapticManager.shared.success()
        } else {
            HapticManager.shared.error()
            failure = "\(item.recipe.name) couldn't be deleted. Please try again."
        }
    }
}

#Preview {
    NavigationStack {
        RecentlyDeletedView()
    }
}
