import SwiftUI

struct DifficultyBarsView: View {
    let difficulty: String
    let size: CGFloat

    init(difficulty: String, size: CGFloat = 4) {
        self.difficulty = difficulty
        self.size = size
    }

    enum Layout {
        static let barCount: Int = 3
        static let barWidthMultiplier: CGFloat = 1.5
        static let barCornerRadiusDivisor: CGFloat = 2
        static let unfilledOpacity: Double = 0.3
        static let heightMultipliers: [CGFloat] = [3, 4, 5]
    }

    var filledBars: Int {
        switch difficulty.lowercased() {
        case "easy":   return 1
        case "medium": return 2
        case "hard":   return 3
        default:       return 2
        }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: size) {
            ForEach(0..<Layout.barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: size / Layout.barCornerRadiusDivisor)
                    .fill(index < filledBars ? Color.blue : Color.gray.opacity(Layout.unfilledOpacity))
                    .frame(
                        width: size * Layout.barWidthMultiplier,
                        height: cascadingHeight(for: index)
                    )
            }
        }
    }

    func cascadingHeight(for index: Int) -> CGFloat {
        let multiplier = index < Layout.heightMultipliers.count
            ? Layout.heightMultipliers[index]
            : Layout.heightMultipliers[1]
        return size * multiplier
    }
}
