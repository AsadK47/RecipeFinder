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
        case "easy": return 1
        case "medium": return 2
        case "hard": return 3
        default: return 2
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
        case 0: return size * 3
        case 1: return size * 4
        case 2: return size * 5
        default: return size * 4
        }
    }
}
