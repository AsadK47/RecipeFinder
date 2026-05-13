import XCTest
@testable import RecipeFinder

final class NutritionalTipsModelTests: XCTestCase {

    // MARK: - NutritionalTipCategory.id

    func testCategoryId_equalsRawValue() {
        for category in NutritionalTipCategory.allCases {
            XCTAssertEqual(category.id, category.rawValue)
        }
    }

    // MARK: - NutritionalTipCategory.icon

    func testCategoryIcon_nonEmptyForAllCases() {
        for category in NutritionalTipCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "\(category) has no icon")
        }
    }

    func testCategoryIcon_exactValues() {
        XCTAssertEqual(NutritionalTipCategory.plateComposition.icon, "🍽️")
        XCTAssertEqual(NutritionalTipCategory.wholeGrains.icon, "🌾")
        XCTAssertEqual(NutritionalTipCategory.proteins.icon, "🥩")
        XCTAssertEqual(NutritionalTipCategory.vegetables.icon, "🥗")
        XCTAssertEqual(NutritionalTipCategory.healthyFats.icon, "🥑")
        XCTAssertEqual(NutritionalTipCategory.hydration.icon, "💧")
        XCTAssertEqual(NutritionalTipCategory.portionControl.icon, "⚖️")
        XCTAssertEqual(NutritionalTipCategory.mealTiming.icon, "⏰")
        XCTAssertEqual(NutritionalTipCategory.foodQuality.icon, "✨")
        XCTAssertEqual(NutritionalTipCategory.sustainability.icon, "🌍")
    }

    func testCategoryAllCases_countIsTen() {
        XCTAssertEqual(NutritionalTipCategory.allCases.count, 10)
    }

    func testCategoryIcons_allDistinct() {
        let icons = NutritionalTipCategory.allCases.map(\.icon)
        XCTAssertEqual(icons.count, Set(icons).count, "Duplicate icons found across categories")
    }

    // MARK: - EvidenceLevel.rawValue

    func testEvidenceLevel_rawValues() {
        XCTAssertEqual(EvidenceLevel.strong.rawValue, "Strong Evidence")
        XCTAssertEqual(EvidenceLevel.moderate.rawValue, "Moderate Evidence")
        XCTAssertEqual(EvidenceLevel.emerging.rawValue, "Emerging Evidence")
    }

    // MARK: - EvidenceLevel.color

    func testEvidenceLevel_color_strong_isGreen() {
        XCTAssertEqual(EvidenceLevel.strong.color, "green")
    }

    func testEvidenceLevel_color_moderate_isOrange() {
        XCTAssertEqual(EvidenceLevel.moderate.color, "orange")
    }

    func testEvidenceLevel_color_emerging_isBlue() {
        XCTAssertEqual(EvidenceLevel.emerging.color, "blue")
    }

    func testEvidenceLevel_colorsAreDistinct() {
        let colors = [EvidenceLevel.strong.color, EvidenceLevel.moderate.color, EvidenceLevel.emerging.color]
        XCTAssertEqual(colors.count, Set(colors).count)
    }

    // MARK: - EvidenceLevel.description

    func testEvidenceLevel_description_nonEmptyForAllCases() {
        XCTAssertFalse(EvidenceLevel.strong.description.isEmpty)
        XCTAssertFalse(EvidenceLevel.moderate.description.isEmpty)
        XCTAssertFalse(EvidenceLevel.emerging.description.isEmpty)
    }

    func testEvidenceLevel_descriptions_areDistinct() {
        let descs = [EvidenceLevel.strong.description, EvidenceLevel.moderate.description, EvidenceLevel.emerging.description]
        XCTAssertEqual(descs.count, Set(descs).count)
    }

    // MARK: - ScientificSource.displayText

    func testDisplayText_institutionOnly() {
        let source = ScientificSource(institution: "WHO")
        XCTAssertEqual(source.displayText, "WHO")
    }

    func testDisplayText_withPublication() {
        let source = ScientificSource(institution: "Harvard", publication: "NEJM")
        XCTAssertEqual(source.displayText, "Harvard - NEJM")
    }

    func testDisplayText_withYear() {
        let source = ScientificSource(institution: "CDC", year: 2022)
        XCTAssertEqual(source.displayText, "CDC (2022)")
    }

    func testDisplayText_withPublicationAndYear() {
        let source = ScientificSource(institution: "NIH", publication: "Lancet", year: 2021)
        XCTAssertEqual(source.displayText, "NIH - Lancet (2021)")
    }

    func testDisplayText_nilOptionals_noExtraCharacters() {
        let source = ScientificSource(institution: "FAO", publication: nil, year: nil)
        XCTAssertEqual(source.displayText, "FAO")
        XCTAssertFalse(source.displayText.contains("-"))
        XCTAssertFalse(source.displayText.contains("("))
    }
}
