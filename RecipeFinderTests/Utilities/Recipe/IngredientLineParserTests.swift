import Testing
import Foundation
@testable import RecipeFinder

/// The canonical ingredient-line parser shared by import and the manual wizard; cases include real scanned-cookbook OCR lines (spelled-out units, `1`→`I` slips, glued unicode fractions).
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
            ("I onion, thinly sliced", 1.0, "1", "", "onion, thinly sliced"),
            // Import regressions (Add flow 3/3):
            ("1-1/2 teaspoons lemon zest", 1.5, "1 1/2", "tsp", "lemon zest"),     // US hyphenated mixed number
            ("1 tbsp. olive oil", 1.0, "1", "tbsp", "olive oil"),                  // dotted abbreviation
            ("225g/8oz cherry tomatoes", 225.0, "225", "g", "cherry tomatoes"),    // second measure dropped
            ("2 tbsp / 30 ml olive oil", 2.0, "2", "tbsp", "olive oil"),
            ("0.8421052632 2 cups plain yogurt", 2.0, "2", "cup", "plain yogurt"), // decimal scale artifact
            ("1.5 1 teaspoon ginger paste", 1.0, "1", "tsp", "ginger paste"),
            ("1.75 tbsp ghee", 1.75, "1.75", "tbsp", "ghee")                       // a real decimal stays
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
        "Strips leading list/checkbox markers so the amount parses (regression: WPRM ▢ lines)",
        arguments: [
            // (input, quantity, unit, name) — real lines from the seed corpus that previously parsed as qty 0.
            ("▢100 g all-purpose flour", 100.0, "g", "all-purpose flour"),
            ("▢3 tablespoons oil of choice", 3.0, "tbsp", "oil of choice"),
            ("▢2½ teaspoons kosher salt", 2.5, "tsp", "kosher salt"),
            ("▢1 bay leaf", 1.0, "", "bay leaf"),
            ("- 2 eggs", 2.0, "", "eggs"),
            ("• 500 g beef", 500.0, "g", "beef"),
            ("☐ 1 cup rice", 1.0, "cup", "rice")
        ]
    )
    func stripsLeadingMarkers(input: String, quantity: Double, unit: String, name: String) {
        let p = IngredientLineParser.parse(input)
        #expect(p.quantity == quantity)
        #expect(p.unit == unit)
        #expect(p.name == name)
    }

    @Test(
        "Drops a prepended scrape/scale artifact and keeps the real second amount (regression)",
        arguments: [
            // (input, quantity, unit, name) — real seed lines where the scraper prepended a scaled/garbage number.
            ("750 500 grams (1 pound) ground beef or lamb", 500.0, "g", "ground beef or lamb"),
            ("5 1 teaspoon ginger paste", 1.0, "tsp", "ginger paste"),
            ("3 2 teaspoons garlic paste", 2.0, "tsp", "garlic paste"),
            ("5 900g boneless lamb leg", 900.0, "g", "boneless lamb leg"),
            ("8421052632 2 cups (475 ml) plain whole milk yogurt", 2.0, "cup", "plain whole milk yogurt"),
            ("4210526316 1/2 teaspoon ground cumin", 0.5, "tsp", "ground cumin")
        ]
    )
    func dropsLeadingScrapeArtifact(input: String, quantity: Double, unit: String, name: String) {
        let p = IngredientLineParser.parse(input)
        #expect(abs(p.quantity - quantity) < 0.0001, "quantity for \(input)")
        #expect(p.unit == unit, "unit for \(input)")
        #expect(p.name == name, "name for \(input)")
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

    /// Broad real-world corpus (many recipes/formats/cuisines) so coverage is
    /// proven against more than one example and regressions can't creep back.
    @Test(
        "Real-world ingredient-line corpus",
        arguments: [
            // (input, quantity, unit, name)
            ("3 large eggs", 3.0, "", "large eggs"),
            ("1/2 teaspoon baking soda", 0.5, "tsp", "baking soda"),
            ("2 1/2 cups all-purpose flour", 2.5, "cup", "all-purpose flour"),
            ("1 (400g) can chopped tomatoes", 1.0, "can", "chopped tomatoes"),
            ("400 g spaghetti", 400.0, "g", "spaghetti"),
            ("2 tbsp extra-virgin olive oil", 2.0, "tbsp", "extra-virgin olive oil"),
            ("Salt and freshly ground black pepper", 0.0, "", "Salt and freshly ground black pepper"),
            ("1 kg beef, cubed", 1.0, "kg", "beef, cubed"),
            ("¼ cup (60 ml) milk", 0.25, "cup", "milk"),
            ("2 cloves of garlic, crushed", 2.0, "clove", "garlic, crushed"),
            ("1 handful fresh basil", 1.0, "handful", "fresh basil"),
            ("3-4 tablespoons water", 4.0, "tbsp", "water"),
            ("8 fl oz heavy cream", 8.0, "fl oz", "heavy cream"),
            ("500ml chicken stock", 500.0, "ml", "chicken stock"),
            ("2 sticks butter", 2.0, "stick", "butter"),
            ("1½ lb potatoes", 1.5, "lbs", "potatoes"),
            ("2 medium onions, diced", 2.0, "", "medium onions, diced"),
            ("1/3 cup sugar", 1.0 / 3.0, "cup", "sugar"),
            ("100 grams dark chocolate", 100.0, "g", "dark chocolate"),
            ("1 x 400g tin coconut milk", 400.0, "g", "tin coconut milk"),      // UK multipack
            ("2 to 3 cups broth", 3.0, "cup", "broth")                          // "to" range
        ]
    )
    func corpus(input: String, quantity: Double, unit: String, name: String) {
        let p = IngredientLineParser.parse(input)
        #expect(abs(p.quantity - quantity) < 0.0001, "quantity for \(input)")
        #expect(p.unit == unit, "unit for \(input)")
        #expect(p.name == name, "name for \(input)")
    }

    @Test("A bare name with no quantity or unit is preserved")
    func bareName() {
        let p = IngredientLineParser.parse("freshly ground pepper")
        #expect(p.quantity == 0)
        #expect(p.unit == "")
        #expect(p.name == "freshly ground pepper")
    }
}
