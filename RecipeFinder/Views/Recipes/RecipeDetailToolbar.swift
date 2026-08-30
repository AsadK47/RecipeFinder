import SwiftUI

/// The trailing toolbar controls on the recipe detail screen: timer, edit, share,
/// add-all-to-shopping, and favorite. Extracted from `RecipeDetailView`.
struct RecipeDetailToolbar: View {
    let recipe: RecipeModel
    @ObservedObject var recipeTimer: RecipeTimerManager
    let colorScheme: ColorScheme
    let onSetTimer: () -> Void
    let onEdit: () -> Void
    let onAddAllToShopping: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.spacing16) {
            if recipeTimer.isActive {
                Menu {
                    Button(action: onSetTimer) {
                        Label("Set New Timer", systemImage: "clock")
                    }

                    Divider()

                    Button(action: { recipeTimer.togglePause() }) {
                        Label(recipeTimer.isPaused ? "Resume" : "Pause", systemImage: recipeTimer.isPaused ? "play.fill" : "pause.fill")
                    }

                    Button(role: .destructive, action: { recipeTimer.stop() }) {
                        Label("Stop", systemImage: "stop.fill")
                    }
                } label: {
                    Text(recipeTimer.displayTime)
                        .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                        .adaptiveForegroundColor()
                        .padding(.horizontal, AppTheme.spacing10)
                        .padding(.vertical, AppTheme.spacing4)
                        .background(
                            Capsule()
                                .fill(colorScheme == .dark ? Color.white.opacity(AppTheme.overlayLightOpacity) : Color.black.opacity(AppTheme.dividerOpacity))
                        )
                }
                .accessibilityLabel("Recipe timer")
                .accessibilityHint("Open timer actions")
            } else {
                Button(action: onSetTimer) {
                    Image(systemName: "timer")
                        .font(.title3)
                        .adaptiveForegroundColor()
                }
                .accessibilityLabel("Set recipe timer")
            }
            
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.title3)
                    .adaptiveForegroundColor()
            }
            
            ShareLink(item: recipe.shareText, subject: Text(recipe.name)) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .adaptiveForegroundColor()
            }
            .accessibilityLabel("Share recipe")
            .accessibilityHint("Share this recipe as text")

            Button(action: onAddAllToShopping) {
                Image(systemName: "cart.badge.plus")
                    .font(.title3)
                    .adaptiveForegroundColor()
            }
            .disabled(recipe.ingredients.isEmpty)
            .accessibilityLabel("Add all ingredients to shopping list")
            .accessibilityHint("Adds every ingredient from this recipe in one tap")
            
            Button(action: onToggleFavorite) {
                Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundColor(recipe.isFavorite ? .red : .white)
            }
        }
    }
}
