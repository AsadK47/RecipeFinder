import SwiftUI

struct InfoItem: View {
    let icon: String
    let label: String
    let value: String

    private enum Layout {
        static let iconFrameHeight: CGFloat = AppTheme.height28
        static let difficultyBarSize: CGFloat = 4
    }

    var iconColor: Color {
        switch icon {
        case "clock":      return .orange
        case "flame":      return .red
        case "chart.bar":  return .blue
        case "fork.knife": return .green
        default:           return .white
        }
    }

    var body: some View {
        VStack(spacing: AppTheme.spacing8) {
            Group {
                if icon == "chart.bar" {
                    DifficultyBarsView(difficulty: value, size: Layout.difficultyBarSize)
                        .frame(height: Layout.iconFrameHeight)
                } else {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(iconColor)
                        .frame(height: Layout.iconFrameHeight)
                }
            }

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}
