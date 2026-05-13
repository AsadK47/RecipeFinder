import SwiftUI

struct DietaryTagsDisplayView: View {
    let tags: [DietaryTag]
    let calories: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Dietary Info")
                .font(.headline)
                .adaptiveForegroundColor()

            VStack(spacing: AppTheme.spacing8) {
                if let calories = calories {
                    HStack {
                        Image(systemName: "flame.fill")
                        Text("\(calories) calories per serving")
                            .font(.subheadline)
                        Spacer()
                    }
                    .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                }

                if !tags.isEmpty {
                    FlowLayout(spacing: AppTheme.spacing6) {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: AppTheme.spacing4) {
                                Text(tag.icon)
                                    .font(.caption2)
                                Text(tag.rawValue)
                                    .font(.caption2)
                            }
                            .padding(.horizontal, AppTheme.spacing8)
                            .padding(.vertical, AppTheme.spacing4)
                            .background(Color.white.opacity(AppTheme.overlayLightOpacity))
                            .adaptiveForegroundColor()
                            .cornerRadius(AppTheme.cornerRadius12)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(.ultraThinMaterial)
            }
        }
    }
}
