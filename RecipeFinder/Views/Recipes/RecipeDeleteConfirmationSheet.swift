import SwiftUI

struct RecipeDeleteConfirmationSheet: View {
    let recipeName: String
    @Binding var dontAskAgain: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    
    var body: some View {
        GeometryReader { geometry in
            let contentMaxWidth = max(0, geometry.size.width - 48)

            ZStack {
                AppBackground()
                
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius3)
                        .fill(AppTheme.subtleStroke)
                        .frame(width: AppTheme.iconSize40, height: 5)
                        .padding(.top, AppTheme.spacing12)
                    
                    VStack(spacing: AppTheme.spacing32) {
                        IconBadge(systemName: "fork.knife.circle.fill", tint: .orange, diameter: AppTheme.width80,
                                  iconSize: AppTheme.fontSize50, weight: .regular)
                            .padding(.top, AppTheme.spacing20)
                        
                        VStack(spacing: AppTheme.spacing12) {
                            Text("Remove this recipe?")
                                .font(.title2)
                                .fontWeight(.bold)
                                .adaptiveForegroundColor()
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(recipeName.isEmpty ? "This recipe will be removed from your collection." : "\(recipeName) will be removed from your collection.")
                                .font(.body)
                                .adaptiveForegroundColor(opacity: AppTheme.nearSolidOpacity)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: contentMaxWidth)
                            
                            Text("This can't be undone, but you can always import it again! 📖")
                                .font(.subheadline)
                                .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: contentMaxWidth)
                                .padding(.top, AppTheme.spacing4)
                        }
                        .padding(.horizontal, AppTheme.spacing24)
                    
                        Button(action: {
                            dontAskAgain.toggle()
                            HapticManager.shared.selection()
                        }) {
                            HStack(spacing: AppTheme.spacing12) {
                                Image(systemName: dontAskAgain ? "checkmark.square.fill" : "square")
                                    .font(.title3)
                                    .foregroundStyle(dontAskAgain ? AppTheme.accentColor : .white.opacity(AppTheme.mediumEmphasisOpacity))
                                    .accessibilityHidden(true)
                                
                                Text("Don't ask me again")
                                    .font(.subheadline)
                                    .adaptiveForegroundColor()
                                
                                Spacer()
                            }
                            .frame(maxWidth: contentMaxWidth)
                            .padding(.horizontal, AppTheme.spacing24)
                        }
                        .buttonStyle(PlainButtonStyle())
                        // A custom checkbox is otherwise silent about its state in VoiceOver.
                        .accessibilityAddTraits(dontAskAgain ? .isSelected : [])
                        .accessibilityValue(dontAskAgain ? "On" : "Off")

                        VStack(spacing: AppTheme.spacing12) {
                            Button(action: {
                                HapticManager.shared.light()
                                onConfirm()
                            }) {
                                Text("Remove Recipe")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: contentMaxWidth)
                                    .padding(.vertical, AppTheme.spacing16)
                                    .background(AppTheme.destructiveFill)
                                    .cornerRadius(AppTheme.cornerRadius12)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                HapticManager.shared.light()
                                onCancel()
                            }) {
                                Text("Keep It")
                                    .font(.headline)
                                    .adaptiveForegroundColor()
                                    .frame(maxWidth: contentMaxWidth)
                                    .padding(.vertical, AppTheme.spacing16)
                                    .background(AppTheme.subtleFill)
                                    .cornerRadius(AppTheme.cornerRadius12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, AppTheme.spacing24)
                        .padding(.top, AppTheme.spacing8)
                    }
                    .padding(.bottom, AppTheme.spacing40)
                }
            }
        }
        .presentationDetents([.height(480)])
        .presentationDragIndicator(.hidden)
    }
}

/// The one recipe-delete flow (list long-press and detail menu): honours "don't ask again", otherwise confirms via
/// `RecipeDeleteConfirmationSheet`. Callers set `pending`; the delete runs after the sheet is gone so `onDeleted`
/// (e.g. popping the detail screen) never races the sheet's own dismissal.
private struct RecipeDeleteFlowModifier: ViewModifier {
    @Binding var pending: RecipeModel?
    let onDeleted: (RecipeModel) -> Void

    @Environment(\.recipeStore) private var recipeStore
    @AppStorage("skipRecipeDeleteConfirmation") private var skipConfirmation: Bool = false
    @State private var confirming: RecipeModel?
    @State private var confirmed: RecipeModel?
    @State private var dontAskAgain = false

    func body(content: Content) -> some View {
        content
            .onChange(of: pending) { _, recipe in
                guard let recipe else { return }
                pending = nil
                if skipConfirmation {
                    delete(recipe)
                } else {
                    confirming = recipe
                    HapticManager.shared.warning()
                }
            }
            .sheet(item: $confirming, onDismiss: finishConfirmedDelete) { recipe in
                RecipeDeleteConfirmationSheet(
                    recipeName: recipe.name,
                    dontAskAgain: $dontAskAgain,
                    onConfirm: {
                        if dontAskAgain { skipConfirmation = true }
                        confirmed = recipe
                        confirming = nil
                    },
                    onCancel: { confirming = nil }
                )
            }
    }

    private func finishConfirmedDelete() {
        dontAskAgain = false
        guard let recipe = confirmed else { return }
        confirmed = nil
        delete(recipe)
    }

    private func delete(_ recipe: RecipeModel) {
        withAnimation {
            recipeStore.delete(id: recipe.id)
        }
        HapticManager.shared.success()
        onDeleted(recipe)
    }
}

extension View {
    /// Attaches the shared delete flow; set `pending` to a recipe to request its deletion.
    func recipeDeleteFlow(pending: Binding<RecipeModel?>,
                          onDeleted: @escaping (RecipeModel) -> Void = { _ in }) -> some View {
        modifier(RecipeDeleteFlowModifier(pending: pending, onDeleted: onDeleted))
    }
}
