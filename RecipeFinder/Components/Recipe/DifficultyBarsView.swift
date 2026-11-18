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

    /// Bars filled for the recipe's level: the app's own Basic / Intermediate / Expert (and imported labels such as
    /// easy / medium / hard) map through `RecipeWizardBuilder.normalizeDifficulty`; anything else shows the middle.
    var filledBars: Int {
        let level = RecipeWizardBuilder.normalizeDifficulty(difficulty)
        let index = RecipeWizardBuilder.difficultyLevels.firstIndex(of: level) ?? 1
        return min(index + 1, Layout.barCount)
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
