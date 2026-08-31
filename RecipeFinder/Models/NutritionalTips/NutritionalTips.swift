
import Foundation

struct NutritionalTip: Identifiable, Codable {
    let id: UUID
    let title: String
    let summary: String
    let fullDescription: String
    let category: NutritionalTipCategory
    let sources: [ScientificSource]
    let actionableSteps: [String]
    let icon: String
    let evidenceLevel: EvidenceLevel

    init(
        id: UUID = UUID(),
        title: String,
        summary: String,
        fullDescription: String,
        category: NutritionalTipCategory,
        sources: [ScientificSource],
        actionableSteps: [String],
        icon: String,
        evidenceLevel: EvidenceLevel = .strong
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.fullDescription = fullDescription
        self.category = category
        self.sources = sources
        self.actionableSteps = actionableSteps
        self.icon = icon
        self.evidenceLevel = evidenceLevel
    }
}

enum NutritionalTipCategory: String, Codable, CaseIterable, Identifiable {
    case plateComposition = "Plate Composition"
    case wholeGrains = "Whole Grains"
    case proteins = "Protein Sources"
    case vegetables = "Vegetables & Fruits"
    case healthyFats = "Healthy Fats"
    case hydration = "Hydration"
    case portionControl = "Portion Control"
    case mealTiming = "Meal Timing"
    case foodQuality = "Food Quality"
    case sustainability = "Sustainability"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .plateComposition: return "🍽️"
        case .wholeGrains: return "🌾"
        case .proteins: return "🥩"
        case .vegetables: return "🥗"
        case .healthyFats: return "🥑"
        case .hydration: return "💧"
        case .portionControl: return "⚖️"
        case .mealTiming: return "⏰"
        case .foodQuality: return "✨"
        case .sustainability: return "🌍"
        }
    }
}

enum EvidenceLevel: String, Codable {
    case strong = "Strong Evidence"
    case moderate = "Moderate Evidence"
    case emerging = "Emerging Evidence"

    var color: String {
        switch self {
        case .strong: return "green"
        case .moderate: return "orange"
        case .emerging: return "blue"
        }
    }

    var description: String {
        switch self {
        case .strong: return "Supported by multiple high-quality studies and systematic reviews"
        case .moderate: return "Supported by several studies with generally consistent findings"
        case .emerging: return "Based on preliminary research; more studies needed"
        }
    }
}

struct ScientificSource: Codable, Identifiable {
    let id: UUID
    let institution: String
    let publication: String?
    let year: Int?
    let url: String?

    init(
        id: UUID = UUID(),
        institution: String,
        publication: String? = nil,
        year: Int? = nil,
        url: String? = nil
    ) {
        self.id = id
        self.institution = institution
        self.publication = publication
        self.year = year
        self.url = url
    }

    var displayText: String {
        var text = institution
        if let pub = publication {
            text += " - \(pub)"
        }
        if let year = year {
            text += " (\(year))"
        }
        return text
    }
}
