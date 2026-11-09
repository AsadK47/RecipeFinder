import SwiftUI

/// Shown at the top of the import review when `ImportQuality` says the read was poor (Import 2/5).
struct ImportQualityBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacing12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text("We couldn't read this one well — check the highlighted parts")
                .font(.subheadline.weight(.semibold))
                .adaptiveForegroundColor()
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("import.lowConfidenceBanner")
    }
}

extension View {
    /// Orange outline around a wizard section the import couldn't read; fixed orange reads on every theme gradient.
    func importHighlight(_ isOn: Bool) -> some View {
        overlay {
            if isOn {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .stroke(Color.orange, lineWidth: 2)
                    .padding(-AppTheme.spacing8)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityHint(isOn ? "Check this part — the import couldn't read it well" : "")
    }
}
