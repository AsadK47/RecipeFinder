import SwiftUI

/// A horizontal scrolling row of tag pills. Used in recipe rows and detail views.
struct TagRowView: View {
    let tags: [String]
    var font: Font = .caption
    var maxVisible: Int = 5

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacing4) {
                ForEach(tags.prefix(maxVisible), id: \.self) { tag in
                    Text(tag)
                        .font(font)
                        .adaptiveSecondaryForeground()
                        .padding(.horizontal, AppTheme.spacing8)
                        .padding(.vertical, AppTheme.spacing2)
                        .background(Color(.systemGray5), in: Capsule())
                }
                if tags.count > maxVisible {
                    Text("+\(tags.count - maxVisible)")
                        .font(font)
                        .adaptiveSecondaryForeground()
                }
            }
        }
    }
}
