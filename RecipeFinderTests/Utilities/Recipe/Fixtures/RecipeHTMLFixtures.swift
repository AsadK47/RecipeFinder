import Foundation

/// Realistic full-page HTML samples proving the importer survives real-world messiness, not just the clean synthetic markup in `RecipeParserTests`.
/// Embedded as string constants (not bundled resources) so they dodge resource-phase quirks and travel with the test source.
enum RecipeHTMLFixtures {

    /// Modern WordPress blog (most common real case): JSON-LD in `@graph` with `@type`/`recipeYield`/image as arrays and instructions split across `HowToSection` containers.
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

    /// Schema.org microdata (`itemscope`/`itemprop`) with no JSON-LD — an older but common style; flat `<li itemprop>` lists and `<time datetime="PT...">`.
    static let microdataOnly = #"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <title>Hearty Beef Stew | Grandma's Kitchen</title>
    </head>
    <body>
    <header><a href="/">Grandma's Kitchen</a></header>
    <article itemscope itemtype="http://schema.org/Recipe">
      <h1 itemprop="name">Hearty Beef Stew</h1>
      <img itemprop="image" src="https://cdn.example.com/beef-stew.jpg" alt="Beef stew"/>
      <p itemprop="description">A rich, slow-simmered beef stew.</p>
      <ul class="meta">
        <li>Prep: <time itemprop="prepTime" datetime="PT20M">20 minutes</time></li>
        <li>Cook: <time itemprop="cookTime" datetime="PT2H">2 hours</time></li>
        <li>Serves: <span itemprop="recipeYield">6 servings</span></li>
      </ul>
      <h2>Ingredients</h2>
      <ul>
        <li itemprop="recipeIngredient">2 lbs beef chuck, cubed</li>
        <li itemprop="recipeIngredient">3 carrots, sliced</li>
        <li itemprop="recipeIngredient">2 potatoes, diced</li>
        <li itemprop="recipeIngredient">1 onion, chopped</li>
        <li itemprop="recipeIngredient">4 cups beef broth</li>
      </ul>
      <h2>Instructions</h2>
      <ol>
        <li itemprop="recipeInstructions">Brown the beef cubes in a hot pot with a little oil.</li>
        <li itemprop="recipeInstructions">Add the onion and cook until softened.</li>
        <li itemprop="recipeInstructions">Pour in the broth, add the vegetables, and simmer for two hours.</li>
      </ol>
    </article>
    </body>
    </html>
    """#

    /// RDFa Lite only (`vocab`/`typeof`/`property`), no JSON-LD/WPRM/microdata — older Drupal-style sites; bare "Recipe" `typeof`, `<time property datetime="PT...">`, flat instruction list.
    static let rdfaOnly = #"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <title>Roasted Tomato Soup :: Old Farmhouse Blog</title>
    </head>
    <body>
    <header><a href="/">Old Farmhouse Blog</a></header>
    <div vocab="https://schema.org/" typeof="Recipe">
      <h1 property="name">Roasted Tomato Soup</h1>
      <img property="image" src="https://cdn.example.com/tomato-soup.jpg" alt="Tomato soup"/>
      <p property="description">A silky roasted tomato soup with basil.</p>
      <ul class="meta">
        <li>Prep: <time property="prepTime" datetime="PT15M">15 minutes</time></li>
        <li>Cook: <time property="cookTime" datetime="PT40M">40 minutes</time></li>
        <li>Serves: <span property="recipeYield">4 servings</span></li>
      </ul>
      <h2>Ingredients</h2>
      <ul>
        <li property="recipeIngredient">2 lbs ripe tomatoes, halved</li>
        <li property="recipeIngredient">1 onion, quartered</li>
        <li property="recipeIngredient">4 cloves garlic</li>
        <li property="recipeIngredient">2 tbsp olive oil</li>
        <li property="recipeIngredient">1 cup vegetable broth</li>
      </ul>
      <h2>Instructions</h2>
      <ol>
        <li property="recipeInstructions">Roast the tomatoes, onion, and garlic with the oil until charred.</li>
        <li property="recipeInstructions">Blend the roasted vegetables with the broth until smooth.</li>
        <li property="recipeInstructions">Warm through, season, and finish with torn basil.</li>
      </ol>
    </div>
    </body>
    </html>
    """#

    /// Plain blog post with no structured data — just `<h1>`, prose, and "Ingredients"/"Instructions" lists — exercising the free-text fallback (hardest, most common case); `<title>` has a site-name suffix.
    static let plainBlogNoStructuredData = #"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <meta property="og:image" content="https://cdn.example.com/pancakes.jpg" />
    <title>Fluffy Pancakes - The Simple Cook</title>
    </head>
    <body>
    <article>
    <h1>Fluffy Pancakes</h1>
    <p>These are the fluffiest pancakes you'll ever make, and they come together in a single bowl.</p>
    <h2>Ingredients</h2>
    <ul>
    <li>2 cups all-purpose flour</li>
    <li>2 tablespoons sugar</li>
    <li>1 tablespoon baking powder</li>
    <li>1/2 teaspoon salt</li>
    <li>2 large eggs</li>
    <li>1 1/2 cups milk</li>
    <li>3 tablespoons melted butter</li>
    </ul>
    <h2>Instructions</h2>
    <ol>
    <li>Whisk the flour, sugar, baking powder, and salt together in a large bowl.</li>
    <li>In a separate bowl, beat the eggs with the milk and melted butter.</li>
    <li>Pour the wet ingredients into the dry and stir until just combined.</li>
    <li>Cook on a greased griddle over medium heat until golden on both sides.</li>
    </ol>
    </article>
    </body>
    </html>
    """#

    /// JSON-LD whose `@type` is the fully-qualified `https://schema.org/Recipe` URL, not the bare "Recipe" — a common form that must still be recognized.
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

    /// JSON-LD using single values instead of arrays: `recipeIngredient` as one String, `recipeInstructions` as one `HowToStep` — both schema.org-valid and seen in the wild.
    static let jsonLDSingleValues = #"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <title>One-Ingredient Wonder</title>
    <script type="application/ld+json">
    {"@context":"https://schema.org",
     "@type":"Recipe",
     "name":"One-Ingredient Wonder",
     "recipeIngredient":"1 cup magic",
     "recipeInstructions":{"@type":"HowToStep","text":"Stir the magic until it shimmers, then serve."}}
    </script>
    </head>
    <body><h1>One-Ingredient Wonder</h1></body>
    </html>
    """#

    /// Microdata where `recipeInstructions` is one container wrapping `<p>` steps (not one itemprop per step) — steps must be pulled from inside it.
    static let microdataContainerInstructions = #"""
    <!DOCTYPE html>
    <html lang="en">
    <head><meta charset="utf-8"><title>Simple Omelette</title></head>
    <body>
    <article itemscope itemtype="https://schema.org/Recipe">
      <h1 itemprop="name">Simple Omelette</h1>
      <ul>
        <li itemprop="recipeIngredient">3 eggs</li>
        <li itemprop="recipeIngredient">1 tbsp butter</li>
        <li itemprop="recipeIngredient">Salt to taste</li>
      </ul>
      <div itemprop="recipeInstructions">
        <p>Beat the eggs with a pinch of salt.</p>
        <p>Melt the butter in a nonstick pan over medium heat.</p>
        <p>Pour in the eggs and cook until just set, then fold and serve.</p>
      </div>
    </article>
    </body>
    </html>
    """#

    /// Recipe nested under a `WebPage`'s `mainEntity` (Yoast/WordPress shape), not top-level or `@graph`; the body has no lists, so missing the structured data yields a near-empty free-text result.
    static let jsonLDMainEntity = #"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <meta property="og:image" content="https://cdn.example.com/overnight-oats.jpg" />
    <title>Overnight Oats | Healthy Mornings</title>
    <script type="application/ld+json">
    {"@context":"https://schema.org","@type":"WebPage","name":"Overnight Oats",
     "mainEntity":{"@type":"Recipe","name":"Overnight Oats",
      "description":"Creamy make-ahead oats.",
      "prepTime":"PT5M","recipeYield":"2 servings",
      "image":"https://cdn.example.com/overnight-oats.jpg",
      "recipeIngredient":["1 cup rolled oats","1 cup milk","1 tbsp chia seeds","1 tbsp maple syrup"],
      "recipeInstructions":[
        {"@type":"HowToStep","text":"Combine the oats, milk, and chia seeds in a jar."},
        {"@type":"HowToStep","text":"Stir in the maple syrup, cover, and refrigerate overnight."}]}}
    </script>
    </head>
    <body><article><h1>Overnight Oats</h1><p>The easiest breakfast.</p></article></body>
    </html>
    """#

    /// Valid Recipe JSON-LD with trailing commas (a common templating defect `JSONSerialization` tolerates) — regression guard that the JSON-LD path still wins over the free-text fallback.
    static let jsonLDTrailingCommas = #"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <title>No-Knead Bread — Slow Kitchen</title>
    <script type="application/ld+json">
    {"@context":"https://schema.org","@type":"Recipe",
     "name":"No-Knead Bread",
     "prepTime":"PT15M","cookTime":"PT45M","recipeYield":"1 loaf",
     "recipeIngredient":["3 cups flour","1/4 tsp yeast","1.5 tsp salt","1.5 cups water",],
     "recipeInstructions":[
       {"@type":"HowToStep","text":"Mix the flour, yeast, and salt, then stir in the water to form a shaggy dough."},
       {"@type":"HowToStep","text":"Cover and let rest for 12 to 18 hours, then bake in a preheated Dutch oven."},
     ],
    }
    </script>
    </head>
    <body><article><h1>No-Knead Bread</h1></article></body>
    </html>
    """#
}
