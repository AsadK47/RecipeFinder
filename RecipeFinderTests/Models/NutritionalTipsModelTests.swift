import Testing
@testable import RecipeFinder

@Suite struct NutritionalTipsModelTests {

    // MARK: - NutritionalTipCategory.id

    @Test func categoryId_equalsRawValue() {
        for category in NutritionalTipCategory.allCases {
            #expect(category.id == category.rawValue)
        }
    }

    // MARK: - NutritionalTipCategory.icon

    @Test func categoryIcon_nonEmptyForAllCases() {
        for category in NutritionalTipCategory.allCases {
            #expect(!category.icon.isEmpty, "\(category) has no icon")
        }
    }

    @Test(arguments: [
        (NutritionalTipCategory.plateComposition, "🍽️"),
        (.wholeGrains, "🌾"),
        (.proteins, "🥩"),
        (.vegetables, "🥗"),
        (.healthyFats, "🥑"),
        (.hydration, "💧"),
        (.portionControl, "⚖️"),
        (.mealTiming, "⏰"),
        (.foodQuality, "✨"),
        (.sustainability, "🌍")
    ])
    func categoryIcon_exactValues(_ category: NutritionalTipCategory, _ icon: String) {
        #expect(category.icon == icon)
    }

    @Test func categoryAllCases_countIsTen() {
        #expect(NutritionalTipCategory.allCases.count == 10)
    }

    @Test func categoryIcons_allDistinct() {
        let icons = NutritionalTipCategory.allCases.map(\.icon)
        #expect(icons.count == Set(icons).count, "Duplicate icons found across categories")
    }

    // MARK: - EvidenceLevel.rawValue

    @Test(arguments: [
        (EvidenceLevel.strong, "Strong Evidence"),
        (.moderate, "Moderate Evidence"),
        (.emerging, "Emerging Evidence")
    ])
    func evidenceLevel_rawValues(_ level: EvidenceLevel, _ raw: String) {
        #expect(level.rawValue == raw)
    }

    // MARK: - EvidenceLevel.color

    @Test(arguments: [
        (EvidenceLevel.strong, "green"),
        (.moderate, "orange"),
        (.emerging, "blue")
    ])
    func evidenceLevel_color(_ level: EvidenceLevel, _ color: String) {
        #expect(level.color == color)
    }

    @Test func evidenceLevel_colorsAreDistinct() {
        let colors = [EvidenceLevel.strong.color, EvidenceLevel.moderate.color, EvidenceLevel.emerging.color]
        #expect(colors.count == Set(colors).count)
    }

    // MARK: - EvidenceLevel.description

    @Test func evidenceLevel_description_nonEmptyForAllCases() {
        #expect(!EvidenceLevel.strong.description.isEmpty)
        #expect(!EvidenceLevel.moderate.description.isEmpty)
        #expect(!EvidenceLevel.emerging.description.isEmpty)
    }

    @Test func evidenceLevel_descriptions_areDistinct() {
        let descs = [EvidenceLevel.strong.description, EvidenceLevel.moderate.description, EvidenceLevel.emerging.description]
        #expect(descs.count == Set(descs).count)
    }

    // MARK: - ScientificSource.displayText

    @Test func displayText_institutionOnly() {
        let source = ScientificSource(institution: "WHO")
        #expect(source.displayText == "WHO")
    }

    @Test func displayText_withPublication() {
        let source = ScientificSource(institution: "Harvard", publication: "NEJM")
        #expect(source.displayText == "Harvard - NEJM")
    }

    @Test func displayText_withYear() {
        let source = ScientificSource(institution: "CDC", year: 2022)
        #expect(source.displayText == "CDC (2022)")
    }

    @Test func displayText_withPublicationAndYear() {
        let source = ScientificSource(institution: "NIH", publication: "Lancet", year: 2021)
        #expect(source.displayText == "NIH - Lancet (2021)")
    }

    @Test func displayText_nilOptionals_noExtraCharacters() {
        let source = ScientificSource(institution: "FAO", publication: nil, year: nil)
        #expect(source.displayText == "FAO")
        #expect(!source.displayText.contains("-"))
        #expect(!source.displayText.contains("("))
    }
}
