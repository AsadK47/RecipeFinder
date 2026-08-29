import SwiftUI

struct RecipeDeleteConfirmationSheet: View {
    let recipeName: String
    @Binding var dontAskAgain: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        GeometryReader { geometry in
            let contentMaxWidth = max(0, geometry.size.width - 48)

            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius3)
                        .fill(Color.white.opacity(AppTheme.shadowDarkOpacity))
                        .frame(width: AppTheme.iconSize40, height: 5)
                        .padding(.top, AppTheme.spacing12)
                    
                    VStack(spacing: AppTheme.spacing32) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(AppTheme.cardDarkOpacity))
                                .frame(width: AppTheme.width80, height: 80)
                            
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: AppTheme.fontSize50))
                                .foregroundColor(.orange)
                        }
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
                                    .foregroundColor(dontAskAgain ? AppTheme.accentColor : .white.opacity(AppTheme.mediumEmphasisOpacity))
                                
                                Text("Don't ask me again")
                                    .font(.subheadline)
                                    .adaptiveForegroundColor()
                                
                                Spacer()
                            }
                            .frame(maxWidth: contentMaxWidth)
                            .padding(.horizontal, AppTheme.spacing24)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        VStack(spacing: AppTheme.spacing12) {
                            Button(action: {
                                HapticManager.shared.light()
                                onConfirm()
                            }) {
                                Text("Remove Recipe")
                                    .font(.headline)
                                    .adaptiveForegroundColor()
                                    .frame(maxWidth: contentMaxWidth)
                                    .padding(.vertical, AppTheme.spacing16)
                                    .background(Color.orange)
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
                                    .background(Color.white.opacity(AppTheme.cardDarkOpacity))
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
