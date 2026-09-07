import Testing
import Foundation
@testable import RecipeFinder

/// The canonical ingredient-line parser shared by import and the manual wizard.
/// Cases include the real OCR lines from a scanned cookbook page (spelled-out
/// units, `1`→`I` OCR slips, glued unicode fractions).
@Suite struct IngredientLineParserTests {

    @Test(
        "Parses quantity, canonical unit, and full name",
        arguments: [
            // (input, quantity, quantityText, unit, name)
            ("2 cups flour", 2.0, "2", "cup", "flour"),
            ("1 1/2 cups sugar", 1.5, "1 1/2", "cup", "sugar"),
            ("200g flour", 200.0, "200", "g", "flour"),
            ("3/4 - 1 cup milk", 1.0, "1", "cup", "milk"),          // range → upper bound
            ("¾ cup sugar", 0.75, "3/4", "cup", "sugar"),
            ("2 tablespoons olive oil", 2.0, "2", "tbsp", "olive oil"),   // spelled-out unit
            ("500 grams beef", 500.0, "500", "g", "beef"),
            ("1 lb ground beef", 1.0, "1", "lbs", "ground beef"),
            ("1 clove garlic, minced", 1.0, "1", "clove", "garlic, minced"), // prep note retained
            ("salt to taste", 0.0, "", "", "salt to taste"),               // no fabricated 1
            ("1 (14 oz) can diced tomatoes", 1.0, "1", "can", "diced tomatoes"),
            ("1,5 dl milk", 1.5, "1.5", "dl", "milk"),                     // euro decimal
            ("pinch of salt", 0.0, "", "pinch", "salt"),                   // leading "of" dropped
            // Real OCR lines from PhotoRecipe.jpeg:
            ("2 tablespoons cornflour", 2.0, "2", "tbsp", "cornflour"),
            ("I tablespoon rice vinegar", 1.0, "1", "tbsp", "rice vinegar"), // OCR "1"→"I"
            ("1½ red pepper, cut into chunks", 1.5, "1 1/2", "", "red pepper, cut into chunks"),
            ("½ green pepper, cut into chunks", 0.5, "1/2", "", "green pepper, cut into chunks"),
            ("300g raw peeled king prawns", 300.0, "300", "g", "raw peeled king prawns"),
            ("I onion, thinly sliced", 1.0, "1", "", "onion, thinly sliced")
        ]
    )
    func parses(input: String, quantity: Double, quantityText: String, unit: String, name: String) {
        let p = IngredientLineParser.parse(input)
        #expect(p.quantity == quantity)
        #expect(p.quantityText == quantityText)
        #expect(p.unit == unit)
        #expect(p.name == name)
    }

    @Test(
        "Unit synonyms collapse to a canonical token",
        arguments: [
            ("1 teaspoon vanilla", "tsp"),
            ("2 Tbsp butter", "tbsp"),
            ("3 ounces chocolate", "oz"),
            ("2 pounds potatoes", "lbs"),
            ("500 millilitres stock", "ml"),
            ("1 litre water", "l"),
            ("2 tins beans", "can")
        ]
    )
    func canonicalisesUnits(input: String, expectedUnit: String) {
        #expect(IngredientLineParser.parse(input).unit == expectedUnit)
    }

    @Test("A bare name with no quantity or unit is preserved")
    func bareName() {
        let p = IngredientLineParser.parse("freshly ground pepper")
        #expect(p.quantity == 0)
        #expect(p.unit == "")
        #expect(p.name == "freshly ground pepper")
    }
}
