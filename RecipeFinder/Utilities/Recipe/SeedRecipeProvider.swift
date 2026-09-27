import Foundation

/// Bundled starter recipes for brand-new users; all carry `isSampleRecipe = true` and fixed UUIDs so seeding is idempotent even if the guard flag resets.
enum SeedRecipeProvider {

    static let recipes: [RecipeModel] = [
        spaghettibolognese,
        chickenTikkaMasala,
        avocadoToast,
        bananaBread,
        classicPancakes,
        greekSalad,
    ]

    // MARK: - Recipes

    private static let spaghettibolognese = RecipeModel(
        id: UUID(uuidString: "5EED0001-0000-0000-0000-000000000001")!,
        name: "Spaghetti Bolognese",
        category: "Pasta",
        difficulty: "Medium",
        prepTime: "15 minutes",
        cookingTime: "45 minutes",
        baseServings: 4,
        ingredients: [
            .init(baseQuantity: 400, unit: "g", name: "spaghetti"),
            .init(baseQuantity: 500, unit: "g", name: "beef mince"),
            .init(baseQuantity: 1,   unit: "",  name: "onion, finely diced"),
            .init(baseQuantity: 3,   unit: "",  name: "garlic cloves, crushed"),
            .init(baseQuantity: 2,   unit: "",  name: "carrots, finely diced"),
            .init(baseQuantity: 2,   unit: "",  name: "celery sticks, finely diced"),
            .init(baseQuantity: 400, unit: "g", name: "chopped tomatoes"),
            .init(baseQuantity: 2,   unit: "tbsp", name: "tomato purée"),
            .init(baseQuantity: 150, unit: "ml", name: "red wine"),
            .init(baseQuantity: 1,   unit: "tsp", name: "dried oregano"),
            .init(baseQuantity: 2,   unit: "tbsp", name: "olive oil"),
        ],
        prePrepInstructions: [],
        instructions: [
            "Heat the olive oil in a large pan over medium-high heat. Add the onion, carrot, and celery and cook for 8 minutes until softened.",
            "Add the garlic and cook for 1 minute. Increase heat to high, add the mince, and brown thoroughly, breaking it up as you go.",
            "Pour in the red wine and let it reduce by half, about 3 minutes.",
            "Stir in the chopped tomatoes, tomato purée, and oregano. Season well, then reduce heat to low and simmer for 30 minutes, stirring occasionally.",
            "Cook the spaghetti in salted boiling water according to the packet instructions. Reserve a cupful of pasta water before draining.",
            "Add a splash of pasta water to the sauce to loosen if needed. Toss the spaghetti through the sauce and serve immediately.",
        ],
        notes: "The sauce improves with time — make it a day ahead and reheat gently. Freeze in portions for up to 3 months.",
        isSampleRecipe: true
    )

    private static let chickenTikkaMasala = RecipeModel(
        id: UUID(uuidString: "5EED0001-0000-0000-0000-000000000002")!,
        name: "Chicken Tikka Masala",
        category: "Curry",
        difficulty: "Medium",
        prepTime: "20 minutes",
        cookingTime: "30 minutes",
        baseServings: 4,
        ingredients: [
            .init(baseQuantity: 700, unit: "g", name: "chicken breast, cut into chunks"),
            .init(baseQuantity: 200, unit: "ml", name: "natural yoghurt"),
            .init(baseQuantity: 2,   unit: "tbsp", name: "tikka masala paste"),
            .init(baseQuantity: 1,   unit: "",  name: "onion, finely sliced"),
            .init(baseQuantity: 400, unit: "g", name: "chopped tomatoes"),
            .init(baseQuantity: 150, unit: "ml", name: "double cream"),
            .init(baseQuantity: 1,   unit: "tsp", name: "garam masala"),
            .init(baseQuantity: 1,   unit: "tsp", name: "ground cumin"),
            .init(baseQuantity: 1,   unit: "tsp", name: "ground coriander"),
            .init(baseQuantity: 2,   unit: "tbsp", name: "vegetable oil"),
            .init(baseQuantity: 1,   unit: "handful", name: "fresh coriander, to serve"),
        ],
        prePrepInstructions: [
            "Mix the chicken with the yoghurt and 1 tbsp of the tikka paste. Cover and marinate for at least 30 minutes (overnight is better).",
        ],
        instructions: [
            "Heat a grill to high. Thread the marinated chicken onto skewers and grill for 8–10 minutes, turning once, until lightly charred. Set aside.",
            "Heat the oil in a large pan. Fry the onion over medium heat for 10 minutes until golden.",
            "Add the remaining tikka paste, cumin, coriander, and garam masala. Stir for 2 minutes.",
            "Add the chopped tomatoes and simmer for 10 minutes. Stir in the cream.",
            "Add the grilled chicken and simmer for a further 5 minutes. Season to taste.",
            "Scatter over fresh coriander and serve with rice and naan.",
        ],
        notes: "Use a good-quality tikka paste — Patak's or homemade both work well. Marinating overnight dramatically improves the flavour.",
        isSampleRecipe: true
    )

    private static let avocadoToast = RecipeModel(
        id: UUID(uuidString: "5EED0001-0000-0000-0000-000000000003")!,
        name: "Avocado Toast",
        category: "Breakfast",
        difficulty: "Easy",
        prepTime: "5 minutes",
        cookingTime: "5 minutes",
        baseServings: 2,
        ingredients: [
            .init(baseQuantity: 2, unit: "",     name: "ripe avocados"),
            .init(baseQuantity: 4, unit: "slices", name: "sourdough bread"),
            .init(baseQuantity: 1, unit: "tbsp", name: "lemon juice"),
            .init(baseQuantity: 1, unit: "pinch", name: "chilli flakes"),
            .init(baseQuantity: 2, unit: "",     name: "eggs (optional, poached)"),
            .init(baseQuantity: 1, unit: "pinch", name: "flaky sea salt"),
        ],
        prePrepInstructions: [],
        instructions: [
            "Toast the sourdough slices until golden.",
            "Halve and stone the avocados. Scoop the flesh into a bowl, add the lemon juice and a pinch of salt, then mash to your preferred texture — chunky or smooth.",
            "Spread the avocado generously onto the toast.",
            "Top with chilli flakes and a final pinch of flaky salt. Add a poached egg if you like.",
        ],
        notes: "The lemon juice prevents browning and brightens the flavour. Add a handful of cherry tomatoes or crumbled feta for variety.",
        isFavorite: false,
        dietaryInfo: DietaryInfo(isVegetarian: true, isVegan: true, isGlutenFree: false),
        isSampleRecipe: true
    )

    private static let bananaBread = RecipeModel(
        id: UUID(uuidString: "5EED0001-0000-0000-0000-000000000004")!,
        name: "Banana Bread",
        category: "Baking",
        difficulty: "Easy",
        prepTime: "15 minutes",
        cookingTime: "60 minutes",
        baseServings: 10,
        ingredients: [
            .init(baseQuantity: 3,   unit: "",    name: "very ripe bananas"),
            .init(baseQuantity: 200, unit: "g",   name: "self-raising flour"),
            .init(baseQuantity: 140, unit: "g",   name: "caster sugar"),
            .init(baseQuantity: 100, unit: "g",   name: "butter, softened"),
            .init(baseQuantity: 2,   unit: "",    name: "eggs, beaten"),
            .init(baseQuantity: 1,   unit: "tsp", name: "baking powder"),
            .init(baseQuantity: 1,   unit: "tsp", name: "vanilla extract"),
            .init(baseQuantity: 50,  unit: "g",   name: "walnuts, roughly chopped (optional)"),
        ],
        prePrepInstructions: [
            "Preheat oven to 180°C (160°C fan). Grease a 900g loaf tin and line with baking parchment.",
        ],
        instructions: [
            "Mash the bananas in a large bowl until smooth.",
            "Beat in the butter and sugar until combined, then add the eggs and vanilla.",
            "Sift in the flour and baking powder and fold gently until just combined — don't overmix.",
            "Fold in the walnuts if using.",
            "Pour into the prepared tin and bake for 55–65 minutes, until a skewer inserted in the centre comes out clean.",
            "Cool in the tin for 10 minutes, then turn out onto a wire rack.",
        ],
        notes: "The riper the bananas the better — black skins give the sweetest loaf. Wrap tightly and it keeps well for 4 days.",
        dietaryInfo: DietaryInfo(isVegetarian: true),
        isSampleRecipe: true
    )

    private static let classicPancakes = RecipeModel(
        id: UUID(uuidString: "5EED0001-0000-0000-0000-000000000005")!,
        name: "Classic Pancakes",
        category: "Breakfast",
        difficulty: "Easy",
        prepTime: "10 minutes",
        cookingTime: "15 minutes",
        baseServings: 4,
        ingredients: [
            .init(baseQuantity: 200, unit: "g",  name: "plain flour"),
            .init(baseQuantity: 2,   unit: "",   name: "eggs"),
            .init(baseQuantity: 300, unit: "ml", name: "milk"),
            .init(baseQuantity: 1,   unit: "tbsp", name: "caster sugar"),
            .init(baseQuantity: 1,   unit: "tsp",  name: "baking powder"),
            .init(baseQuantity: 1,   unit: "pinch", name: "salt"),
            .init(baseQuantity: 1,   unit: "tbsp", name: "butter, for frying"),
        ],
        prePrepInstructions: [],
        instructions: [
            "Whisk together the flour, baking powder, sugar, and salt in a large bowl.",
            "Make a well in the centre and add the eggs and half the milk. Whisk from the centre outwards until smooth, then add the remaining milk.",
            "Heat a knob of butter in a non-stick frying pan over medium heat until foaming.",
            "Pour in a ladleful of batter and cook for 2–3 minutes until bubbles appear on the surface and the edges look set.",
            "Flip and cook for another minute until golden. Repeat with the remaining batter.",
            "Serve immediately with your choice of toppings — maple syrup, fresh berries, or sliced banana.",
        ],
        notes: "Let the batter rest for 5 minutes for fluffier pancakes. Keep finished pancakes warm in a low oven (100°C) while you cook the rest.",
        dietaryInfo: DietaryInfo(isVegetarian: true),
        isSampleRecipe: true
    )

    private static let greekSalad = RecipeModel(
        id: UUID(uuidString: "5EED0001-0000-0000-0000-000000000006")!,
        name: "Greek Salad",
        category: "Salad",
        difficulty: "Easy",
        prepTime: "10 minutes",
        cookingTime: "0 minutes",
        baseServings: 2,
        ingredients: [
            .init(baseQuantity: 4,   unit: "",    name: "ripe tomatoes, roughly chopped"),
            .init(baseQuantity: 1,   unit: "",    name: "cucumber, roughly chopped"),
            .init(baseQuantity: 1,   unit: "",    name: "red onion, thinly sliced"),
            .init(baseQuantity: 100, unit: "g",   name: "kalamata olives"),
            .init(baseQuantity: 200, unit: "g",   name: "feta cheese, broken into chunks"),
            .init(baseQuantity: 3,   unit: "tbsp", name: "extra virgin olive oil"),
            .init(baseQuantity: 1,   unit: "tbsp", name: "red wine vinegar"),
            .init(baseQuantity: 1,   unit: "tsp",  name: "dried oregano"),
        ],
        prePrepInstructions: [],
        instructions: [
            "Combine the tomatoes, cucumber, and red onion in a large bowl.",
            "Scatter over the olives and feta.",
            "Whisk together the olive oil, vinegar, and oregano. Season with black pepper only — the feta and olives are already salty.",
            "Drizzle the dressing over the salad and toss gently so the feta stays in chunks.",
            "Serve immediately with crusty bread.",
        ],
        notes: "Greek salad should not be refrigerated — serve at room temperature for the best flavour. Assemble just before serving.",
        dietaryInfo: DietaryInfo(isVegetarian: true, isGlutenFree: true),
        isSampleRecipe: true
    )
}
