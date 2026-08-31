import SwiftUI
import SafariServices

struct TipDetailView: View {
    let tip: NutritionalTip
    
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var safariItem: IdentifiableURL?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.spacing32) {
                        HStack {
                            Text(tip.icon)
                                .font(.system(size: AppTheme.fontSize60))
                            
                            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                                Text(tip.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .adaptiveForegroundColor()
                                
                                Text(tip.category.rawValue)
                                    .font(.subheadline)
                                    .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                            }
                            
                            Spacer()
                        }
                        
                        EvidenceBadge(level: tip.evidenceLevel)
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                            Text("What the Science Says")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            Text(tip.fullDescription)
                                .font(.body)
                                .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background {
                            cardBackground()
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                            Text("What You Can Do")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            ForEach(Array(tip.actionableSteps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: AppTheme.spacing12) {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .adaptiveForegroundColor()
                                        .frame(width: 24, height: AppTheme.height24)
                                        .background(AppTheme.accentColor(for: selectedTheme))
                                        .clipShape(Circle())
                                    
                                    Text(step)
                                        .font(.body)
                                        .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background {
                            cardBackground()
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                            HStack {
                                Image(systemName: "graduationcap.fill")
                                Text("Scientific Sources")
                                    .font(.headline)
                            }
                            .adaptiveForegroundColor()
                            
                            ForEach(tip.sources) { source in
                                Button(action: {
                                    if let urlString = source.url, let url = URL(string: urlString) {
                                        safariItem = IdentifiableURL(url: url)
                                        HapticManager.shared.light()
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                                                Text(source.institution)
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .adaptiveForegroundColor()
                                                
                                                if let pub = source.publication {
                                                    Text(pub)
                                                        .font(.caption)
                                                        .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                                                }
                                                
                                                if let year = source.year {
                                                    Text("Published: \(year, format: .number.grouping(.never))")
                                                        .font(.caption2)
                                                        .adaptiveForegroundColor(opacity: AppTheme.glassLightOpacity)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            if source.url != nil {
                                                Image(systemName: "arrow.up.right.circle.fill")
                                                    .font(.title3)
                                                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                            } else {
                                                Image(systemName: "info.circle.fill")
                                                    .font(.title3)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                            .fill(source.url != nil ? Color.white.opacity(AppTheme.cardDarkOpacity) : Color.white.opacity(AppTheme.glassSubtleOpacity))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                                    .stroke(source.url != nil ? AppTheme.accentColor(for: selectedTheme).opacity(0.3) : Color.clear, lineWidth: 1)
                                            )
                                    )
                                }
                                .disabled(source.url == nil)
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            Text("Evidence Level: \(tip.evidenceLevel.description)")
                                .font(.caption)
                                .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
                                .italic()
                            
                            Divider()
                                .background(Color.white.opacity(AppTheme.shadowDarkOpacity))
                                .padding(.vertical, AppTheme.spacing8)
                            
                            HStack(spacing: AppTheme.spacing6) {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                Text("Tap any source with a link icon to read the full peer-reviewed research.")
                            }
                            .font(.caption2)
                            .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                        }
                        .padding()
                        .background {
                            cardBackground()
                        }
                    }
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.bottom, AppTheme.spacing100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .adaptiveForegroundColor()
                }
            }
            .fullScreenCover(item: $safariItem) { item in
                SafariView(url: item.url)
                    .ignoresSafeArea()
            }
        }
    }
    
    private func cardBackground() -> some View {
        Group {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .fill(AppTheme.adaptiveCardMedium(for: colorScheme))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .fill(.ultraThinMaterial)
            }
        }
    }
}

struct EvidenceBadge: View {
    let level: EvidenceLevel
    
    var body: some View {
        HStack(spacing: AppTheme.spacing4) {
            Image(systemName: level == .strong ? "checkmark.seal.fill" : level == .moderate ? "checkmark.circle.fill" : "sparkles")
                .font(.caption2)
            Text(level.rawValue)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, AppTheme.spacing8)
        .padding(.vertical, AppTheme.spacing4)
        .background(badgeColor.opacity(AppTheme.overlayLightOpacity))
        .foregroundColor(badgeColor)
        .cornerRadius(AppTheme.cornerRadius8)
    }
    
    private var badgeColor: Color {
        switch level {
        case .strong: return .green
        case .moderate: return .orange
        case .emerging: return .blue
        }
    }
}

private struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        return SFSafariViewController(url: url, configuration: config)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
