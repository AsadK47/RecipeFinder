import SwiftUI

struct DifficultyBarsView: View {
    let difficulty: String
    let size: CGFloat
    
    init(difficulty: String, size: CGFloat = 4) {
        self.difficulty = difficulty
        self.size = size
    }
    
    private var filledBars: Int {
        switch difficulty.lowercased() {
        case "basic": return 1
        case "intermediate": return 2
        case "expert": return 3
        default: return 1
        }
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: size) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: size / 2)
                    .fill(index < filledBars ? Color.blue : Color.gray.opacity(0.3))
                    .frame(
                        width: size * 1.5,
                        height: cascadingHeight(for: index)
                    )
            }
        }
    }
    
    private func cascadingHeight(for index: Int) -> CGFloat {
        switch index {
        case 0: return size * 3  // Small bar
        case 1: return size * 4  // Medium bar
        case 2: return size * 5  // Large bar
        default: return size * 4
        }
    }
}
