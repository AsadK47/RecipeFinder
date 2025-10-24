import Foundation

extension PersistenceController {
    func populateDatabase() {
        clearDatabase()
        
        print("🔄 Populating database with sample recipes...")
        
        saveRecipe(
            name: "Achari Chicken Curry (Instant Pot Version)",
            category: "Main",
            difficulty: "Intermediate",
            prepTime: "20 minutes",
            cookingTime: "20 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 3, unit: "tbsp", name: "oil of choice"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "cumin seeds"),
                Ingredient(baseQuantity: 1, unit: "", name: "bay leaf"),
                Ingredient(baseQuantity: 1, unit: "", name: "onion, diced"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "minced garlic"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "minced ginger"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "coriander powder"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "fennel seeds"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "paprika"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "salt"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "turmeric"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "amchur (dried mango powder)"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "fenugreek (methi) seeds"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "garam masala"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "kalonji (nigella seeds)"),
                Ingredient(baseQuantity: 0.25, unit: "tsp", name: "black pepper"),
                Ingredient(baseQuantity: 0.25, unit: "tsp", name: "cayenne"),
                Ingredient(baseQuantity: 2, unit: "lbs", name: "skinless and boneless chicken thighs, cut into bite-sized pieces"),
                Ingredient(baseQuantity: 1, unit: "cup", name: "fresh tomato puree")
            ],
            prePrepInstructions: [
                "Chop onions and garlic."
            ],
            instructions: [
                "Press the sauté button on the Instant Pot, add the oil, and allow it to heat up for a minute.",
                "Once the oil is hot, add the cumin seeds and bay leaf.",
                "When the cumin seeds brown, add the diced onion and stir-fry for 6-7 minutes, or until the onions begin to brown.",
                "Add the minced garlic and ginger, stir, then add all the spices. Mix well.",
                "Add the chicken pieces and stir-fry for 5-6 minutes, or until the chicken is mostly cooked.",
                "Add the fresh tomato puree and mix well.",
                "Secure the lid, close the pressure valve, and cook for 5 minutes at high pressure.",
                "Naturally release pressure.",
                "Garnish with cilantro and serve."
            ],
            notes: "A flavorful and tangy chicken curry, perfect for pairing with naan or rice.",
            imageName: "achari_chicken_curry"
        )
        
        saveRecipe(
            name: "Air Fryer Crispy Chilli Beef",
            category: "Main",
            difficulty: "Intermediate",
            prepTime: "15 minutes",
            cookingTime: "10 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 500, unit: "g", name: "beef steak, sliced into strips"),
                Ingredient(baseQuantity: 3, unit: "tbsp", name: "cornflour"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "soy sauce"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "sweet chilli sauce"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "rice vinegar"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "ketchup"),
                Ingredient(baseQuantity: 1, unit: "", name: "red chilli, finely sliced"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "vegetable oil"),
                Ingredient(baseQuantity: 2, unit: "", name: "spring onions, finely sliced")
            ],
            prePrepInstructions: [
                "Slice the beef into thin strips and pat dry."
            ],
            instructions: [
                "Place the beef strips in a bowl, add cornflour, and toss to coat evenly.",
                "Preheat the air fryer to 200°C.",
                "Lightly spray the air fryer basket with oil and add the beef strips in a single layer.",
                "Cook for 8-10 minutes, shaking halfway through until crispy.",
                "In a separate bowl, mix soy sauce, sweet chilli sauce, rice vinegar, ketchup, and red chilli.",
                "Heat the sauce mixture in a pan until it starts to thicken.",
                "Add the cooked beef to the pan and toss to coat in the sauce.",
                "Garnish with spring onions before serving."
            ],
            notes: "Serve immediately with steamed rice or noodles for a delicious and crispy meal.",
            imageName: "crispy_chilli_beef"
        )
        
        saveRecipe(
            name: "Achari Gosht (Hot & Sour Lamb Curry Instant Pot Version)",
            category: "Main",
            difficulty: "Intermediate",
            prepTime: "25 minutes",
            cookingTime: "40 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 3, unit: "tbsp", name: "mustard oil"),
                Ingredient(baseQuantity: 2, unit: "tsp", name: "fenugreek seeds"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "fennel seeds"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "mustard seeds"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "nigella seeds"),
                Ingredient(baseQuantity: 2, unit: "", name: "large onions, finely sliced"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "minced garlic"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "minced ginger"),
                Ingredient(baseQuantity: 2, unit: "", name: "large tomatoes, pureed"),
                Ingredient(baseQuantity: 1, unit: "cup", name: "yogurt, whisked"),
                Ingredient(baseQuantity: 1.5, unit: "tsp", name: "turmeric powder"),
                Ingredient(baseQuantity: 1.5, unit: "tsp", name: "red chili powder"),
                Ingredient(baseQuantity: 2, unit: "tsp", name: "coriander powder"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "garam masala"),
                Ingredient(baseQuantity: 2, unit: "lbs", name: "lamb pieces, bone-in"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "salt, or to taste"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "vinegar"),
                Ingredient(baseQuantity: 2, unit: "", name: "green chilies, slit"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "fresh cilantro, chopped (for garnish)")
            ],
            prePrepInstructions: [
                "Puree the tomatoes and whisk the yogurt."
            ],
            instructions: [
                "Turn on the sauté function on the Instant Pot and heat mustard oil until it begins to smoke slightly.",
                "Add fenugreek seeds, fennel seeds, mustard seeds, and nigella seeds. Sauté until aromatic.",
                "Add sliced onions and cook until golden brown.",
                "Stir in minced garlic and ginger, cooking for another 2 minutes.",
                "Add pureed tomatoes, yogurt, turmeric, red chili powder, and coriander powder. Mix well.",
                "Add lamb pieces and sauté for 5-7 minutes until coated in the spice mixture.",
                "Pour in 1 cup of water, close the lid, and pressure cook on high for 25 minutes.",
                "Naturally release pressure for 10 minutes before opening the lid.",
                "Add garam masala, vinegar, and slit green chilies. Mix well.",
                "Garnish with chopped cilantro and serve hot."
            ],
            notes: "Pairs well with naan, roti, or steamed basmati rice. Adjust spices to taste for a milder or spicier curry.",
            imageName: "achari_gosht"
        )
        
        saveRecipe(
            name: "Air-Fryer Doughnuts",
            category: "Dessert",
            difficulty: "Intermediate",
            prepTime: "15 minutes",
            cookingTime: "15 minutes",
            baseServings: 12,
            currentServings: 12,
            ingredients: [
                Ingredient(baseQuantity: 2, unit: "cups", name: "all-purpose flour"),
                Ingredient(baseQuantity: 0.25, unit: "cup", name: "sugar"),
                Ingredient(baseQuantity: 2.5, unit: "tsp", name: "baking powder"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "salt"),
                Ingredient(baseQuantity: 0.5, unit: "cup", name: "milk"),
                Ingredient(baseQuantity: 2, unit: "", name: "large eggs"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "unsalted butter, melted"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "vanilla extract"),
                Ingredient(baseQuantity: 1, unit: "cup", name: "powdered sugar (for coating)")
            ],
            prePrepInstructions: [
                "Combine dry ingredients in a bowl."
            ],
            instructions: [
                "In a separate bowl, whisk wet ingredients together.",
                "Combine wet and dry ingredients to form a dough.",
                "Shape into doughnuts.",
                "Air fry at 350°F for 5-6 minutes until golden.",
                "Coat with powdered sugar before serving."
            ],
            notes: "A healthier twist on a classic treat. Best served fresh.",
            imageName: "air_fryer_doughnuts"
        )
        
        saveRecipe(
            name: "Air Fryer Korean Fried Chicken",
            category: "Starter",
            difficulty: "Expert",
            prepTime: "20 minutes",
            cookingTime: "25 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 2, unit: "lbs", name: "chicken wings"),
                Ingredient(baseQuantity: 0.5, unit: "cup", name: "cornstarch"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "soy sauce"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "ginger, grated"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "gochujang (Korean chili paste)"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "honey"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "sesame oil"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "scallions, chopped"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "sesame seeds")
            ],
            prePrepInstructions: [
                "Pat chicken wings dry.",
                "Combine cornstarch, soy sauce, and grated ginger."
            ],
            instructions: [
                "Coat chicken wings with the cornstarch mixture.",
                "Air fry at 375°F for 15 minutes, turning halfway.",
                "Prepare sauce by mixing gochujang, honey, and sesame oil.",
                "Toss cooked wings in sauce and garnish with scallions and sesame seeds."
            ],
            notes: "Crispy, spicy, and savory, these wings pair well with a cold drink.",
            imageName: "air_fryer_korean_fried_chicken"
        )
        
        saveRecipe(
            name: "Air Fryer Southern Fried Chicken",
            category: "Main",
            difficulty: "Intermediate",
            prepTime: "30 minutes",
            cookingTime: "20 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 4, unit: "", name: "chicken drumsticks"),
                Ingredient(baseQuantity: 1, unit: "cup", name: "buttermilk"),
                Ingredient(baseQuantity: 1, unit: "cup", name: "all-purpose flour"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "paprika"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "garlic powder"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "onion powder"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "cayenne pepper"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "salt"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "black pepper")
            ],
            prePrepInstructions: [
                "Marinate chicken in buttermilk for 2 hours or overnight."
            ],
            instructions: [
                "Mix flour and spices in a bowl.",
                "Coat chicken in the flour mixture.",
                "Place chicken in the air fryer and spray lightly with oil.",
                "Air fry at 375°F for 20 minutes, flipping halfway through."
            ],
            notes: "Crispy, flavorful chicken with less grease—perfect for any occasion.",
            imageName: "air_fryer_southern_fried_chicken"
        )
        
        saveRecipe(
            name: "Air Fryer Soy Sauce Chicken Wings",
            category: "Starter",
            difficulty: "Basic",
            prepTime: "10 minutes",
            cookingTime: "20 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 2, unit: "lbs", name: "chicken wings"),
                Ingredient(baseQuantity: 0.25, unit: "cup", name: "soy sauce"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "honey"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "ginger, grated"),
                Ingredient(baseQuantity: 2, unit: "cloves", name: "garlic, minced"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "sesame oil"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "black pepper"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "sesame seeds (optional)")
            ],
            prePrepInstructions: [
                "Mix soy sauce, honey, ginger, garlic, sesame oil, and black pepper in a bowl."
            ],
            instructions: [
                "Marinate chicken wings in the sauce for 30 minutes.",
                "Place wings in air fryer and cook at 375°F for 20 minutes, flipping halfway.",
                "Garnish with sesame seeds before serving."
            ],
            notes: "Juicy and savory wings, perfect for game day.",
            imageName: "air_fryer_soy_sauce_chicken_wings"
        )
        
        saveRecipe(
            name: "Aloo Gosht (Mutton/Lamb and Potato Curry)",
            category: "Main",
            difficulty: "Intermediate",
            prepTime: "20 minutes",
            cookingTime: "1 hour",
            baseServings: 6,
            currentServings: 6,
            ingredients: [
                Ingredient(baseQuantity: 2, unit: "lbs", name: "mutton or lamb, bone-in"),
                Ingredient(baseQuantity: 4, unit: "medium", name: "potatoes, peeled and cubed"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "vegetable oil"),
                Ingredient(baseQuantity: 2, unit: "large", name: "onions, finely sliced"),
                Ingredient(baseQuantity: 2, unit: "tsp", name: "ginger paste"),
                Ingredient(baseQuantity: 2, unit: "tsp", name: "garlic paste"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "turmeric powder"),
                Ingredient(baseQuantity: 2, unit: "tsp", name: "red chili powder"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "coriander powder"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "cumin seeds"),
                Ingredient(baseQuantity: 3, unit: "cups", name: "water"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "cilantro, chopped (for garnish)")
            ],
            prePrepInstructions: [
                "Wash and cut mutton into pieces."
            ],
            instructions: [
                "Heat oil in a large pot and fry onions until golden brown.",
                "Add ginger and garlic paste, followed by spices.",
                "Add mutton and cook until browned.",
                "Add potatoes and water, and simmer until tender.",
                "Garnish with chopped cilantro before serving."
            ],
            notes: "A hearty and comforting curry, best served with naan or rice.",
            imageName: "aloo_gosht"
        )
        
        saveRecipe(
            name: "American Pancakes",
            category: "Breakfast",
            difficulty: "Basic",
            prepTime: "5 minutes",
            cookingTime: "10 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 200, unit: "g", name: "self-raising flour"),
                Ingredient(baseQuantity: 1.5, unit: "tsp", name: "baking powder"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "golden caster sugar"),
                Ingredient(baseQuantity: 3, unit: "large", name: "eggs"),
                Ingredient(baseQuantity: 25, unit: "g", name: "melted butter"),
                Ingredient(baseQuantity: 200, unit: "ml", name: "milk"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "vegetable oil"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "maple syrup"),
                Ingredient(baseQuantity: 1, unit: "assorted", name: "toppings (e.g., bacon, chocolate chips, blueberries, peanut butter, jam)")
            ],
            prePrepInstructions: [
                "Mix self-raising flour, baking powder, golden caster sugar, and a pinch of salt together in a large bowl."
            ],
            instructions: [
                "Create a well in the centre with the back of your spoon, then add eggs, melted butter, and milk.",
                "Whisk together with a balloon whisk or electric hand beaters until smooth, then pour into a jug.",
                "Heat a small knob of butter and vegetable oil in a large, non-stick frying pan over medium heat.",
                "When the butter looks frothy, pour in rounds of the batter, approximately 8cm wide.",
                "Cook pancakes on one side for about 1-2 minutes or until tiny bubbles appear and pop on the surface.",
                "Flip pancakes over and cook for another minute on the other side. Repeat until all batter is used.",
                "Serve pancakes stacked with a drizzle of maple syrup and your favourite toppings."
            ],
            notes: "American pancakes are a classic breakfast dish. Experiment with different toppings like fresh fruits, whipped cream, or savory additions like bacon.",
            imageName: "american_pancakes"
        )
        
        saveRecipe(
            name: "Apam Balik",
            category: "Dessert",
            difficulty: "Intermediate",
            prepTime: "10 minutes",
            cookingTime: "20 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 5, unit: "ml", name: "unsalted butter (for greasing the pan, or substitute with dairy-free butter or neutral oil)"),
                Ingredient(baseQuantity: 135, unit: "g", name: "all-purpose flour"),
                Ingredient(baseQuantity: 63, unit: "g", name: "self-rising flour"),
                Ingredient(baseQuantity: 3, unit: "g", name: "baking soda"),
                Ingredient(baseQuantity: 0.8, unit: "g", name: "salt"),
                Ingredient(baseQuantity: 500, unit: "ml", name: "warm milk (or substitute with plain oat milk for a dairy-free version)"),
                Ingredient(baseQuantity: 4.7, unit: "g", name: "dry active yeast"),
                Ingredient(baseQuantity: 10, unit: "ml", name: "vanilla extract"),
                Ingredient(baseQuantity: 24, unit: "g", name: "white granulated sugar"),
                Ingredient(baseQuantity: 1, unit: "large", name: "egg (room temperature)"),
                Ingredient(baseQuantity: 1, unit: "as desired", name: "white granulated sugar (for topping)"),
                Ingredient(baseQuantity: 1, unit: "as desired", name: "crushed peanuts (for topping)"),
                Ingredient(baseQuantity: 250, unit: "ml", name: "creamed corn (canned)"),
                Ingredient(baseQuantity: 1, unit: "as needed", name: "unsalted butter (or substitute with vegan butter)")
            ],
            prePrepInstructions: [
                "Sift and whisk all-purpose flour, self-rising flour, baking soda, and salt in a large mixing bowl.",
                "In a medium-sized bowl, whisk together warm milk, dry active yeast, vanilla extract, and sugar. Allow the yeast to dissolve completely.",
                "Whisk the milk mixture into the dry ingredients, then crack an egg into the batter and whisk just until combined. Do not overmix.",
                "Cover the bowl and rest the pancake batter for 30 minutes (or 60 minutes if you have extra time)."
            ],
            instructions: [
                "Set a 10-inch pan over medium-low heat and lightly grease it with butter using a clean paper towel.",
                "Ladle the batter into the pan and spread it into an even pancake.",
                "Swirl the batter against the wall of the pan to create a thin crust, then cover the pan with a lid.",
                "Cook until bubbles form all over the pancake (about 2-3 minutes).",
                "Evenly sprinkle sugar, creamed corn, crushed peanuts, and small slices of butter across the pancake.",
                "Cover the pan with a lid for 2 minutes so the creamed corn can warm up.",
                "Remove the lid and fold one side of the pancake over the other to create a semi-circle.",
                "Slide the pancake onto a cutting board, slice it in half with a sharp knife, and repeat for the remaining batter. Enjoy!"
            ],
            notes: "Apam Balik is a popular Malaysian street food pancake filled with sweet and savory fillings. For a dairy-free version, use oat milk and vegan butter. Enjoy it as a dessert, snack, or breakfast.",
            imageName: "apam_balik"
        )
        
        print("✅ Default recipes added!")
    }
}
