import Foundation

/// Curated ingredient-substitution table, looked up by `IngredientNameFormatter.matchKey` so prep words, amounts and case don't matter.
enum IngredientSubstituteProvider {

    // Called per ingredient per RecipeIngredientsSection body eval; cache so repeated renders are O(1).
    private static let cache = MemoCache<String, [String]>(maxSize: 300)

    static func substitutes(for ingredientName: String) -> [String] {
        let key = IngredientNameFormatter.matchKey(ingredientName)
        return cache.value(for: key) { key in
            if let exact = table[key] { return exact }
            // Whole-word match, most specific key first: "large eggs" → "eggs", "full-fat buttermilk" → "buttermilk"
            // (not "butter"/"milk"), and "eggplant" matches nothing.
            let words = IngredientWordMatcher.words(in: key)
            return keysBySpecificity
                .first { IngredientWordMatcher.matches(textWords: words, keyword: $0) }
                .flatMap { table[$0] } ?? []
        }
    }

    // Longest key first, then alphabetical, so the winner is deterministic (Dictionary order isn't).
    private static let keysBySpecificity: [String] = table.keys.sorted { lhs, rhs in
        let l = lhs.split(separator: " ").count, r = rhs.split(separator: " ").count
        return l != r ? l > r : lhs < rhs
    }

    private static let table: [String: [String]] = [
        // Dairy
        "buttermilk": [
            "1 cup milk + 1 tbsp white vinegar — let sit 5 min",
            "1 cup plain yoghurt",
            "1 cup kefir",
        ],
        "butter": [
            "Equal weight coconut oil",
            "¾ the quantity of olive oil (for baking)",
            "Equal quantity margarine",
        ],
        "milk": [
            "Equal quantity oat milk, almond milk, or soy milk",
            "Equal quantity cream diluted half-and-half with water",
        ],
        "cream": [
            "Equal quantity coconut cream",
            "Equal quantity Greek yoghurt (don't boil)",
            "Half cream + half milk",
        ],
        "double cream": [
            "Equal quantity coconut cream",
            "¾ cup milk + ¼ cup butter (for cooking, not whipping)",
        ],
        "heavy cream": [
            "Equal quantity coconut cream",
            "¾ cup milk + ¼ cup butter (for cooking, not whipping)",
        ],
        "sour cream": [
            "Equal quantity plain Greek yoghurt",
            "Equal quantity crème fraîche",
            "1 cup cream + 1 tbsp lemon juice",
        ],
        "cream cheese": [
            "Equal quantity mascarpone",
            "Equal quantity ricotta (blend smooth first)",
        ],
        "greek yoghurt": [
            "Equal quantity sour cream",
            "Equal quantity crème fraîche",
            "Equal quantity plain yoghurt (less thick)",
        ],
        "plain yoghurt": [
            "Equal quantity sour cream",
            "Equal quantity Greek yoghurt",
            "Equal quantity crème fraîche",
        ],
        "parmesan": [
            "Equal quantity pecorino romano",
            "Equal quantity grana padano",
            "Equal quantity nutritional yeast (vegan)",
        ],

        // Eggs
        "egg": [
            "3 tbsp aquafaba (chickpea water) per egg",
            "1 flax egg: 1 tbsp ground flaxseed + 3 tbsp water, rest 5 min",
            "¼ cup mashed banana per egg (adds sweetness)",
        ],
        "eggs": [
            "3 tbsp aquafaba (chickpea water) per egg",
            "1 flax egg: 1 tbsp ground flaxseed + 3 tbsp water, rest 5 min",
            "¼ cup mashed banana per egg (adds sweetness)",
        ],

        // Flour & leavening
        "plain flour": [
            "Gluten-free flour blend + ¼ tsp xanthan gum per cup",
            "Equal quantity spelt flour (slightly denser result)",
        ],
        "all-purpose flour": [
            "Gluten-free flour blend + ¼ tsp xanthan gum per cup",
            "Equal quantity whole wheat flour (denser, nuttier)",
        ],
        "self-raising flour": [
            "1 cup plain flour + 1½ tsp baking powder + ¼ tsp salt",
        ],
        "baking powder": [
            "¼ tsp bicarbonate of soda + ½ tsp cream of tartar per tsp",
            "¼ tsp bicarb + ½ tsp white vinegar per tsp",
        ],
        "bicarbonate of soda": [
            "3× the quantity of baking powder (and reduce other acids in the recipe)",
        ],
        "bicarb": [
            "3× the quantity of baking powder (and reduce other acids in the recipe)",
        ],
        "baking soda": [
            "3× the quantity of baking powder (and reduce other acids in the recipe)",
        ],
        "cornstarch": [
            "Equal quantity arrowroot powder",
            "2× the quantity of plain flour",
        ],
        "cornflour": [
            "Equal quantity arrowroot powder",
            "2× the quantity of plain flour",
        ],

        // Sweeteners
        "sugar": [
            "Equal quantity coconut sugar",
            "¾ the quantity of honey (reduce other liquid by ¼ cup)",
            "¾ the quantity of maple syrup (reduce other liquid by 3 tbsp)",
        ],
        "caster sugar": [
            "Blitz regular granulated sugar in a blender until fine",
        ],
        "brown sugar": [
            "Equal quantity white sugar + 1 tsp molasses per 100 g",
            "Equal quantity coconut sugar",
        ],
        "honey": [
            "Equal quantity maple syrup",
            "Equal quantity agave nectar",
            "¾ the quantity of sugar + ¼ cup extra liquid",
        ],
        "maple syrup": [
            "Equal quantity honey",
            "Equal quantity agave nectar",
        ],

        // Fats & oils
        "olive oil": [
            "Equal quantity avocado oil",
            "Equal quantity vegetable oil",
            "Equal quantity melted coconut oil",
        ],
        "vegetable oil": [
            "Equal quantity sunflower oil",
            "Equal quantity rapeseed oil",
            "Equal quantity melted coconut oil",
        ],

        // Flavourings
        "vanilla extract": [
            "Equal quantity vanilla bean paste",
            "½ vanilla pod (scrape seeds)",
            "2× the quantity of vanilla essence",
        ],
        "lemon juice": [
            "Equal quantity lime juice",
            "Half the quantity of white wine vinegar",
        ],
        "lime juice": [
            "Equal quantity lemon juice",
            "Half the quantity of cider vinegar",
        ],

        // Stocks & liquids
        "chicken stock": [
            "Equal quantity vegetable stock",
            "Equal quantity water + ½ tsp soy sauce",
        ],
        "vegetable stock": [
            "Equal quantity water + 1 tsp miso paste",
            "Equal quantity chicken stock",
        ],
        "white wine": [
            "Equal quantity chicken or vegetable stock + 1 tsp white wine vinegar",
            "Equal quantity white grape juice + splash of vinegar",
        ],
        "red wine": [
            "Equal quantity beef stock + 1 tsp red wine vinegar",
            "Equal quantity red grape juice + splash of vinegar",
        ],

        // Condiments & sauces
        "soy sauce": [
            "Equal quantity tamari (gluten-free)",
            "Equal quantity coconut aminos (lower sodium)",
            "Half the quantity of fish sauce",
        ],

        // Chocolate & cocoa
        "cocoa powder": [
            "3 tbsp carob powder per 1 tbsp cocoa",
            "1 tbsp melted dark chocolate per tbsp (reduce fat slightly)",
        ],
        "dark chocolate": [
            "3 tbsp cocoa powder + 1 tbsp butter per 30 g",
            "Equal quantity semi-sweet chocolate chips",
        ],

        // Breadcrumbs
        "breadcrumbs": [
            "Equal quantity crushed crackers or crispbreads",
            "Equal quantity rolled oats (for toppings)",
            "Equal quantity panko",
        ],
    ]
}
