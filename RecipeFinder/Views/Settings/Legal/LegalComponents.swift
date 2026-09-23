import SwiftUI

/// Shared building blocks for the legal information screens: text primitives used
/// by the policy documents and the row components used by the overview.

struct SectionTitle: View {
    let text: String
    @Environment(\.colorScheme) var colorScheme
    
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
    @Environment(\.colorScheme) var colorScheme
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(.body)
            .foregroundStyle(colorScheme == .dark ? AppTheme.textColor(for: colorScheme, opacity: AppTheme.cardLightOpacity) : .black.opacity(AppTheme.highEmphasisOpacity))
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct LegalBulletPoint: View {
    let text: String
    @Environment(\.colorScheme) var colorScheme
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacing8) {
            Text("•")
                .adaptiveSecondaryForeground()
            Text(text)
                .font(.body)
                .foregroundStyle(colorScheme == .dark ? AppTheme.textColor(for: colorScheme, opacity: AppTheme.cardLightOpacity) : .black.opacity(AppTheme.highEmphasisOpacity))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, AppTheme.spacing8)
    }
}

struct CompanyDetailRow: View {
    let label: String
    let value: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.subheadline)
                .adaptiveSecondaryForeground()
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .adaptiveForegroundColor()
        }
        .padding(.vertical, AppTheme.spacing2)
    }
}

struct CompanyInfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .adaptiveSecondaryForeground()
                .frame(width: AppTheme.width140, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(valueColor == .primary ? AppTheme.textColor(for: colorScheme) : valueColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, AppTheme.spacing4)
    }
}

struct LegalDocRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    @Environment(\.colorScheme) var colorScheme
    
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
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacing12) {
            ZStack {
                Circle()
                    .fill(color.opacity(AppTheme.cardDarkOpacity))
                    .frame(width: 40, height: AppTheme.height40)
                
                Image(systemName: icon)
                    .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                    .foregroundStyle(color)
            }
            
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
