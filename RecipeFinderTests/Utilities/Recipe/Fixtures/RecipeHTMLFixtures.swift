import Foundation

/// Realistic, full-page HTML samples that mirror how real recipe sites structure
/// their markup — used to prove the importer survives real-world messiness rather
/// than only the clean synthetic markup in `RecipeParserTests`.
///
/// Embedded as string constants (not bundled resource files) so the fixtures are
/// robust to test-target resource-phase quirks and travel with the test source.
enum RecipeHTMLFixtures {

    /// Modern WordPress food blog: JSON-LD inside `@graph`, `@type` as an array,
    /// `recipeYield` as an array, image as an array, and instructions split across
    /// `HowToSection` containers. Represents the single most common real-world case.
    static let modernWordPressBlog = #"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <meta property="og:image" content="https://cdn.example.com/garlic-butter-chicken.jpg" />
    <title>Garlic Butter Chicken - Example Kitchen</title>
    <script type="application/ld+json">
    {"@context":"https://schema.org","@graph":[
    {"@type":"WebSite","name":"Example Kitchen","url":"https://example.com"},
    {"@type":"WebPage","@id":"https://example.com/garlic-butter-chicken","name":"Garlic Butter Chicken"},
    {"@type":["Recipe","NewsArticle"],
     "name":"Garlic Butter Chicken",
     "description":"Juicy pan-seared chicken in a rich garlic butter sauce.",
     "prepTime":"PT10M","cookTime":"PT20M","totalTime":"PT30M",
     "recipeYield":["4","4 servings"],
     "recipeCuisine":"American","recipeCategory":["Dinner","Main Course"],
     "image":["https://cdn.example.com/garlic-butter-chicken.jpg"],
     "recipeIngredient":["4 boneless chicken thighs","4 tbsp butter","6 cloves garlic, minced","1/2 cup chicken broth","Salt &amp; pepper to taste"],
     "recipeInstructions":[
       {"@type":"HowToSection","name":"Prep","itemListElement":[
         {"@type":"HowToStep","text":"Pat the chicken dry and season generously with salt and pepper."}]},
       {"@type":"HowToSection","name":"Cook","itemListElement":[
         {"@type":"HowToStep","text":"Sear the chicken in butter over medium-high heat until golden, about 6 minutes per side."},
         {"@type":"HowToStep","text":"Add the garlic and broth, then simmer until the sauce thickens."}]}
     ]}
    ]}
    </script>
    </head>
    <body><article><h1>Garlic Butter Chicken</h1></article></body>
    </html>
    """#

    /// Same shape, but `@type` is the fully-qualified schema.org URL
    /// (`https://schema.org/Recipe`) rather than the bare `"Recipe"`. Plenty of
    /// real sites emit this form, and it must still be recognized as a recipe.
    static let schemaOrgURLType = #"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <title>Classic Lemonade - Example Kitchen</title>
    <script type="application/ld+json">
    {"@context":"https://schema.org",
     "@type":"https://schema.org/Recipe",
     "name":"Classic Lemonade",
     "description":"Refreshing homemade lemonade.",
     "prepTime":"PT5M",
     "recipeYield":"6",
     "recipeIngredient":["1 cup sugar","1 cup water","1 cup fresh lemon juice","4 cups cold water"],
     "recipeInstructions":[
       {"@type":"HowToStep","text":"Make a simple syrup by heating the sugar and 1 cup water until dissolved."},
       {"@type":"HowToStep","text":"Stir in the lemon juice and cold water, then chill before serving."}
     ]}
    </script>
    </head>
    <body><h1>Classic Lemonade</h1></body>
    </html>
    """#
}
