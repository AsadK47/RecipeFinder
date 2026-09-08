import Foundation

/// Real recipe text captured from textonlyrecipes.com (a plain-text recipe site),
/// used as a corpus for `TextRecipeParser` — the same path pasted captions and
/// photo OCR go through. Two shapes are represented: explicit `Ingredients:` /
/// `Instructions:` headers (curry, pancakes, bolognese) and a header-less
/// blank-line-separated layout (banana bread) that exercises line classification.
///
/// Stored as string constants (not bundled files) so they travel with the source,
/// matching `RecipeHTMLFixtures`.
enum TextRecipeFixtures {

    /// Header-less: title, blank line, quantity-led ingredients, blank line, then
    /// prose instruction paragraphs. Source: /recipes/banana-bread.
    static let bananaBread = """
    Banana Bread

    1 cup granulated sugar
    8 tablespoons (1 stick) unsalted butter, room temperature
    2 large eggs
    3 ripe bananas
    1 tablespoon milk
    1 teaspoon ground cinnamon
    2 cups all-purpose flour
    1 teaspoon baking powder
    1 teaspoon baking soda
    1 teaspoon salt

    Preheat the oven to 325 degrees F. Butter a 9 x 5 x 3 inch loaf pan.

    Cream the sugar and butter in a large mixing bowl until light and fluffy. Add the eggs one at a time, beating well after each addition.

    In a small bowl, mash the bananas with a fork. Mix in the milk and cinnamon. In another bowl, mix together the flour, baking powder, baking soda and salt.

    Add the banana mixture to the creamed mixture and stir until combined. Add dry ingredients, mixing just until flour disappears.

    Pour batter into prepared pan and bake 1 hour to 1 hour 10 minutes, until a toothpick inserted in the center comes out clean. Set aside to cool on a rack for 15 minutes. Remove bread from pan, invert onto rack and cool completely before slicing.

    Spread slices with honey or serve with ice cream.
    """

    /// Headered, bulleted ingredients with ranges ("3-4"), "to taste", and a
    /// garnish line; numbered instructions. Source: /recipes/chicken-curry.
    static let chickenCurry = """
    Chicken Curry
    Ingredients:
    - 1 kg chicken, skinless and bone-in, cut into pieces
    - 2 onions, finely chopped
    - 3 tomatoes, pureed
    - 3-4 cloves of garlic, minced
    - 1-inch piece of ginger, grated
    - 2 green chilies, slit
    - 1 tsp turmeric powder
    - 2 tsp red chili powder
    - 2 tsp coriander powder
    - 1 tsp cumin powder
    - 1 tsp garam masala
    - Salt to taste
    - 2 tbsp oil
    - Fresh coriander leaves, for garnishing
    Instructions:
    1. Heat oil in a deep pan or kadai over medium heat. Add the chopped onions and sauté until golden brown.
    2. Add minced garlic and grated ginger. Sauté for 1-2 minutes until fragrant.
    3. Add the pureed tomatoes, green chilies, and cook for about 5 minutes until the oil separates from the mixture.
    4. In a small bowl, mix together turmeric powder, red chili powder, coriander powder, cumin powder, and salt. Add this spice mixture to the pan and cook for another 2 minutes.
    5. Add the chicken pieces to the pan and coat them well with the spice mixture. Cook for a few minutes until the chicken starts to brown.
    6. Add water, cover the pan, and let the chicken simmer on low heat for about 20-25 minutes or until it is cooked through and tender. Stir occasionally.
    7. Sprinkle garam masala over the chicken curry and mix well. Cook for an additional 2 minutes.
    8. Garnish with fresh coriander leaves and serve hot with steamed rice or naan bread.
    """

    /// Headered, bulleted ingredients with fractions; numbered instructions.
    /// Source: /recipes/pancakes.
    static let pancakes = """
    Pancakes
    Ingredients:
    - 1 cup all-purpose flour
    - 2 tablespoons granulated sugar
    - 1 teaspoon baking powder
    - 1/2 teaspoon baking soda
    - 1/4 teaspoon salt
    - 3/4 cup milk
    - 1/4 cup plain yogurt
    - 1 large egg
    - 2 tablespoons unsalted butter, melted
    - 1 teaspoon vanilla extract
    Instructions:
    1. In a large mixing bowl, whisk together the flour, sugar, baking powder, baking soda, and salt.
    2. In a separate bowl, combine the milk, yogurt, egg, melted butter, and vanilla extract. Whisk until well blended.
    3. Pour the wet ingredients into the dry ingredients. Stir together until just combined. Do not over-mix; the batter should be slightly lumpy.
    4. Heat a non-stick skillet or griddle over medium heat. Lightly grease the surface with butter or cooking spray.
    5. Pour around 1/4 cup of batter onto the hot skillet for each pancake.
    6. Cook until bubbles form on the surface, then flip and cook on the other side until golden brown and cooked through.
    7. Repeat with the remaining batter, adding more butter or cooking spray as needed.
    8. Serve the pancakes warm with your favorite toppings such as maple syrup, fresh fruits, or whipped cream.
    """

    /// Headered, with "1 can (14 oz) ..." parentheticals and mixed units.
    /// Source: /recipes/spaghetti-bolognese.
    static let spaghettiBolognese = """
    Spaghetti Bolognese
    Ingredients:
    - 1 lb ground beef
    - 1 medium onion, chopped
    - 2 cloves garlic, minced
    - 1 can (14 oz) crushed tomatoes
    - 1 can (6 oz) tomato paste
    - 1 cup beef broth
    - 1 tsp dried basil
    - 1 tsp dried oregano
    - 1/2 tsp salt
    - 1/4 tsp black pepper
    - 1/4 cup grated Parmesan cheese
    - 12 oz spaghetti noodles
    Instructions:
    1. In a large skillet, cook the ground beef over medium heat until browned. Drain off any excess fat.
    2. Add the chopped onion and minced garlic to the skillet with the beef. Cook for an additional 2-3 minutes, until the onion is soft.
    3. Stir in the crushed tomatoes, tomato paste, beef broth, basil, oregano, salt, and pepper. Bring the mixture to a simmer and let cook for 10-15 minutes, stirring occasionally.
    4. While the sauce is simmering, cook the spaghetti noodles according to the package instructions. Drain and set aside.
    5. Serve the spaghetti topped with the bolognese sauce and sprinkled with Parmesan cheese. Enjoy!
    """

    /// Headered; range ("6-7"), "1 package (14.1 ounces)" parenthetical, and a
    /// trailing "Note:" line (currently counted as a final instruction).
    /// Source: /recipes/apple-pie.
    static let applePie = """
    Apple Pie
    Ingredients:
    - 6-7 medium-sized apples, peeled, cored, and sliced
    - 1 cup granulated sugar
    - 2 tablespoons all-purpose flour
    - 1 teaspoon ground cinnamon
    - 1/4 teaspoon ground nutmeg
    - 1/4 teaspoon salt
    - 2 tablespoons unsalted butter, cut into small pieces
    - 1 package (14.1 ounces) refrigerated pie crusts (or homemade pie crust)
    - 1 tablespoon milk (for brushing the crust)
    - Additional sugar for sprinkling (optional)
    Instructions:
    1. Preheat your oven to 425°F (220°C).
    2. In a large bowl, combine the sliced apples, sugar, flour, cinnamon, nutmeg, and salt. Mix well until the apples are evenly coated.
    3. Roll out one pie crust and place it in a 9-inch pie dish. Press the crust gently against the bottom and sides of the dish.
    4. Pour the apple mixture into the crust and dot the top with the small pieces of butter.
    5. Roll out the second pie crust and lay it over the filling. You can either create a lattice pattern or simply place the crust over the top and cut slits for ventilation. Seal and crimp the edges of the crust.
    6. Brush the top crust with milk for a golden finish. Optionally, sprinkle some sugar on the crust.
    7. Place the pie dish on a baking sheet to catch any drips, and bake in the preheated oven for 45-50 minutes, or until the crust is golden brown, and the filling is bubbly.
    8. Once done, remove the pie from the oven and let it cool on a wire rack for at least 2 hours before serving. This cooling time allows the filling to set.
    9. Serve warm or at room temperature. Enjoy your homemade Apple Pie!
    Note: You can add a scoop of vanilla ice cream or a dollop of whipped cream on top for an extra touch.
    """

    /// Headered with blank lines inside the ingredient block; mixed number
    /// ("1 1/2 cups"). Source: /recipes/oatmeal-cookies.
    static let oatmealCookies = """
    Oatmeal Cookies
    Ingredients:

    - 1 cup unsalted butter, at room temperature
    - 1 cup brown sugar
    - 1/2 cup granulated sugar
    - 2 large eggs
    - 1 teaspoon vanilla extract
    - 1 1/2 cups all-purpose flour
    - 1 teaspoon baking powder
    - 1/2 teaspoon baking soda
    - 1/2 teaspoon salt
    - 3 cups old-fashioned rolled oats
    - 1 cup raisins or chocolate chips (optional)

    Instructions:
    1. Preheat the oven to 350 degrees F (175 degrees C).
    2. In a large bowl, cream the butter, brown sugar, and granulated sugar together until light and fluffy.
    3. Beat in the eggs one at a time, then stir in the vanilla extract.
    4. In a separate bowl, whisk together the flour, baking powder, baking soda, and salt.
    5. Gradually stir the dry ingredients into the butter mixture until fully incorporated.
    6. Stir in the oats and raisins or chocolate chips (if using).
    7. Drop the dough by spoonfuls onto a baking sheet lined with parchment paper.
    8. Bake for 12-15 minutes or until lightly golden brown.
    9. Remove from the oven and let cool for 5 minutes before transferring to a wire rack to cool completely.
    10. Serve and enjoy!
    """

    /// Headered; "to taste"/"for garnish"/"for cooking" no-quantity lines and a
    /// trailing "Note:". Source: /recipes/lentil-soup.
    static let lentilSoup = """
    Lentil Soup
    Ingredients:
    - 1 cup dried lentils
    - 1 onion, diced
    - 2 carrots, peeled and chopped
    - 2 celery stalks, chopped
    - 3 garlic cloves, minced
    - 4 cups vegetable broth
    - 1 can diced tomatoes
    - 1 teaspoon ground cumin
    - 1 teaspoon ground coriander
    - 1/2 teaspoon paprika
    - 1/4 teaspoon cayenne pepper (optional)
    - Salt and pepper to taste
    - Fresh parsley or cilantro, chopped (for garnish)
    - Olive oil for cooking
    Instructions:
    1. Rinse the lentils under cold water and set aside.
    2. In a large pot, heat some olive oil over medium heat. Add the diced onion, chopped carrots, and celery. Cook for about 5 minutes until the vegetables are softened.
    3. Add minced garlic, ground cumin, ground coriander, paprika, and cayenne pepper (if using). Stir well to coat the vegetables in the spices and cook for an additional minute.
    4. Pour in the vegetable broth and add the lentils and diced tomatoes (with their juices). Bring the soup to a boil, then reduce the heat to low, cover the pot, and let it simmer for about 20-25 minutes or until the lentils are tender.
    5. Season with salt and pepper to taste.
    6. Ladle the soup into bowls and garnish with fresh parsley or cilantro.
    7. Serve hot and enjoy!
    Note: You can customize the soup by adding other vegetables, such as bell peppers or spinach, and adjust the amount of spices according to your taste preferences.
    """

    /// Headered, preceded by an intro sentence (not an ingredient). Condiment
    /// with cups/tbsp/tsp. Source: /recipes/barbecue-sauce.
    static let barbecueSauce = """
    Barbecue Sauce
    Here's a simple and classic recipe for barbecue sauce:
    Ingredients:
    - 1 cup ketchup
    - 1/4 cup brown sugar
    - 1/4 cup apple cider vinegar
    - 2 tablespoons molasses
    - 1 tablespoon Worcestershire sauce
    - 1 tablespoon Dijon mustard
    - 1 teaspoon smoked paprika
    - 1 teaspoon garlic powder
    - 1/2 teaspoon onion powder
    - 1/2 teaspoon salt
    - 1/4 teaspoon black pepper
    Instructions:
    1. In a medium saucepan, combine all the ingredients.
    2. Whisk the mixture until well combined and smooth.
    3. Place the saucepan over medium heat and bring the mixture to a simmer.
    4. Reduce the heat to low and let it simmer gently for about 10-15 minutes, stirring occasionally.
    5. Remove the sauce from heat and let it cool completely before using.
    6. Transfer the barbecue sauce to an airtight container or jar and store in the refrigerator.
    7. Use the sauce to baste your preferred meat or as a dipping sauce. Enjoy!
    """

    /// Header-less drink: glued "6oz" units, a single instruction, and a "*"
    /// footnote (currently counted as an ingredient). Source: /recipes/margaritas.
    static let margaritas = """
    Margaritas
    Margaritas
    6oz frozen limeade
    3oz tequila
    2oz triple sec
    6oz water
    4 cups ice cubes
    Blend all ingredients throughly in blender. Serve in salt rimmed glasses.
    *on the rocks: use 3-4 cups cold water for ice
    """

    /// Headered; decimal weight ("1.5 lbs"), "1-inch piece", "1 can (14 oz)",
    /// and many spice lines. Source: /recipes/instant-pot-tikka-masala.
    static let tikkaMasala = """
    Instant Pot Tikka Masala
    Ingredients:
    - 1.5 lbs boneless, skinless chicken breasts, cut into bite-sized pieces
    - 1 yellow onion, diced
    - 4 cloves garlic, minced
    - 1-inch piece of ginger, grated
    - 1 can (14 oz) diced tomatoes
    - 1 cup chicken broth
    - 1/2 cup heavy cream
    - 2 tablespoons tomato paste
    - 2 tablespoons garam masala
    - 1 tablespoon ground coriander
    - 1 tablespoon ground cumin
    - 1 teaspoon turmeric
    - 1 teaspoon paprika
    - 1/2 teaspoon cayenne pepper (optional)
    - Salt and pepper, to taste
    - Fresh cilantro, for garnish
    Instructions:
    1. Set the Instant Pot to sauté mode and add a splash of oil. Sauté the onion, garlic, and ginger until softened.
    2. Add the chicken pieces and cook until browned on all sides.
    3. Stir in the diced tomatoes, chicken broth, tomato paste, garam masala, coriander, cumin, turmeric, paprika, and cayenne pepper (if using). Season with salt and pepper.
    4. Close the Instant Pot lid and set to manual high pressure for 10 minutes.
    5. Once the timer goes off, allow the pressure to release naturally for 10 minutes, then do a quick pressure release.
    6. Stir in the heavy cream and adjust seasoning, if necessary.
    7. Serve over rice and garnish with fresh cilantro. Enjoy!
    """
}
