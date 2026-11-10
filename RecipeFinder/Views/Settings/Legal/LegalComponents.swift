import SwiftUI

/// Shared text/row primitives for the legal information screens.

struct SectionTitle: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(.title3)
            .fontWeight(.bold)
            .adaptiveForegroundColor()
            .padding(.top, AppTheme.spacing8)
    }
}

struct BodyText: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(.body)
            .foregroundStyle(AppTheme.adaptive(light: .black.opacity(AppTheme.highEmphasisOpacity), dark: .white.opacity(AppTheme.cardLightOpacity)))
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct LegalBulletPoint: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacing8) {
            Text("•")
                .adaptiveSecondaryForeground()
            Text(text)
                .font(.body)
                .foregroundStyle(AppTheme.adaptive(light: .black.opacity(AppTheme.highEmphasisOpacity), dark: .white.opacity(AppTheme.cardLightOpacity)))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, AppTheme.spacing8)
    }
}

struct LegalDocRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    
    var body: some View {
        HStack(spacing: AppTheme.spacing12) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.title3)
                .frame(width: AppTheme.width30)
            
            VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                Text(title)
                    .font(.subheadline)
                    .adaptiveForegroundColor()
                Text(subtitle)
                    .font(.caption)
                    .adaptiveSecondaryForeground()
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .adaptiveSecondaryForeground()
        }
        .padding(AppTheme.spacing24)
    }
}

struct ComplianceBadge: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacing12) {
            IconBadge(systemName: icon, tint: color, diameter: AppTheme.height40, iconSize: AppTheme.fontSize18)
            
            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .adaptiveForegroundColor()
                
                Text(description)
                    .font(.caption)
                    .adaptiveSecondaryForeground()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, AppTheme.spacing4)
    }
}

/// When the Privacy Policy / Terms copy last changed — bump this when you edit either document.
/// (Was `Date()` at render time, so the pages always claimed they were updated today.)
enum LegalDocument {
    static let lastUpdated = "10 November 2026"
}

/// Shared frame for legal documents: themed background, title + subtitle header, scrolling body, Done button.
struct LegalDocumentScaffold<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                Text(title)
                    .font(.system(size: AppTheme.fontSize32, weight: .bold))
                    .adaptiveForegroundColor()

                Text(subtitle)
                    .font(.caption)
                    .adaptiveSecondaryForeground()

                Divider()

                content
            }
            .padding(AppTheme.spacing32)
        }
        .sheetDismissButton()
        .sheetScaffold()
    }
}
