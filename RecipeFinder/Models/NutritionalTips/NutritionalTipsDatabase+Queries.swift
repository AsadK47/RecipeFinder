
import Foundation

/// Read-only queries over `NutritionalTipsDatabase.allTips`.
extension NutritionalTipsDatabase {

    static func tips(forCategory category: NutritionalTipCategory) -> [NutritionalTip] {
        allTips.filter { $0.category == category }
    }

    static func tipOfTheDay() -> NutritionalTip {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % allTips.count
        return allTips[index]
    }

    static func randomTips(count: Int) -> [NutritionalTip] {
        Array(allTips.shuffled().prefix(count))
    }

    static func essentialTips() -> [NutritionalTip] {
        allTips.filter { $0.evidenceLevel == .strong }.prefix(5).map { $0 }
    }
}
