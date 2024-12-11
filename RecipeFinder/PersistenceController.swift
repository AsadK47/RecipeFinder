//
//  PersistenceController.swift
//  RecipeFinder
//
//  Created by asad.e.khan on 11/12/2024.
//

import CoreData

struct RecipeModel: Identifiable {
    let id = UUID()
    let name: String
    let prepTime: String
    let cookingTime: String
    let ingredients: [String]
    let prePrepInstructions: [String]
    let instructions: [String]
    let notes: String
}

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "RecipeModel")
        
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        if let storeURL = container.persistentStoreDescriptions.first?.url {
            try? FileManager.default.removeItem(at: storeURL)
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("Failed to load persistent store: \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
    
    func clearDatabase() {
        if let storeURL = container.persistentStoreDescriptions.first?.url {
            do {
                try FileManager.default.removeItem(at: storeURL)
                print("Database cleared successfully.")
            } catch {
                print("Failed to clear database: \(error)")
            }
        }
    }
    
    func saveRecipe(name: String, prepTime: String, cookingTime: String, ingredients: [String], prePrepInstructions: [String], instructions: [String], notes: String) {
        let context = container.viewContext
        let entity = NSEntityDescription.insertNewObject(forEntityName: "Recipe", into: context)
        
        entity.setValue(name, forKey: "name")
        entity.setValue(prepTime, forKey: "prepTime")
        entity.setValue(cookingTime, forKey: "cookingTime")
        entity.setValue(ingredients, forKey: "ingredients")
        entity.setValue(prePrepInstructions, forKey: "prePrepInstructions")
        entity.setValue(instructions, forKey: "instructions")
        entity.setValue(notes, forKey: "notes")
        
        do {
            try context.save()
            print("Recipe saved successfully!")
        } catch {
            print("Failed to save recipe: \(error)")
        }
    }
    
    func fetchRecipes() -> [RecipeModel] {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Recipe")
        
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.map { result in
                RecipeModel(
                    name: result.value(forKey: "name") as? String ?? "",
                    prepTime: result.value(forKey: "prepTime") as? String ?? "",
                    cookingTime: result.value(forKey: "cookingTime") as? String ?? "",
                    ingredients: result.value(forKey: "ingredients") as? [String] ?? [],
                    prePrepInstructions: result.value(forKey: "prePrepInstructions") as? [String] ?? [],
                    instructions: result.value(forKey: "instructions") as? [String] ?? [],
                    notes: result.value(forKey: "notes") as? String ?? ""
                )
            }
        } catch {
            print("Failed to fetch recipes: \(error)")
            return []
        }
    }
}

extension PersistenceController {
    func populateDatabaseIfNeeded() {
        let context = container.viewContext
        
        let fetchRequest : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Recipe")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print("Failed to clear existing data: \(error)")
        }
        
        saveRecipe(
            name: "Achari Chicken Curry (Instant Pot Version)",
            prepTime: "20 minutes",
            cookingTime: "20 min",
            ingredients: [
                "3 tablespoons oil of choice",
                "1 teaspoon cumin seeds",
                "1 bay leaf",
                "1 onion, diced",
                "1 teaspoon minced garlic",
                "1 teaspoon minced ginger",
                "1 teaspoon coriander powder",
                "1 teaspoon fennel seeds",
                "1 teaspoon paprika",
                "1 teaspoon salt",
                "1 teaspoon turmeric",
                "½ teaspoon amchur (dried mango powder)",
                "½ teaspoon fenugreek (methi) seeds",
                "½ teaspoon garam masala",
                "½ teaspoon kalonji (nigella seeds)",
                "¼ teaspoon black pepper",
                "¼ teaspoon cayenne",
                "2 pounds skinless and boneless chicken thighs, cut into bite-sized pieces",
                "1 cup fresh tomato puree"
            ],
            prePrepInstructions: [
                "Chop onions and garlic"
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
            notes: "Classic Italian dish."
        )
        saveRecipe(
            name: "Air Fryer Crispy Chilli Beef",
            prepTime: "15 mins",
            cookingTime: "15 mins",
            ingredients: [
                "250g thin-cut minute steak, thinly sliced into strips",
                "2 tbsp cornflour",
                "2 tbsp vegetable oil, plus a drizzle",
                "2 garlic cloves, crushed",
                "Thumb-sized piece of ginger, peeled and cut into matchsticks",
                "1 red chilli, thinly sliced",
                "1 red pepper, cut into chunks",
                "4 spring onions, sliced, green and white parts separated",
                "4 tbsp rice wine vinegar or white wine vinegar",
                "1 tbsp soy sauce",
                "2 tbsp sweet chilli sauce",
                "2 tbsp tomato ketchup",
                "1 tsp Chinese five-spice powder (for marinade)",
                "1 tbsp soy sauce (for marinade)",
                "1 tsp sesame oil (for marinade)",
                "1 tsp caster sugar (for marinade)"
            ],
            prePrepInstructions: [
                "Prepare the marinade by combining Chinese five-spice powder, soy sauce, sesame oil, and caster sugar in a bowl.",
                "Add the steak strips to the marinade and toss to coat. Leave in the fridge for up to 24 hours for best results, or proceed immediately to cooking if short on time.",
                "Thinly slice all vegetables and separate the green and white parts of the spring onions."
            ],
            instructions: [
                "Sprinkle the cornflour over the marinated steak and mix until each piece is coated in a floury paste. Pull the strips apart and arrange them on a plate. Drizzle each piece with a little oil. Preheat the air fryer to 220°C if it has a preheat setting.",
                "Place the beef strips on the cooking rack in the air fryer. Cook for 6 minutes, then turn and cook for another 4-6 minutes until crispy.",
                "While the beef is cooking, heat 2 tablespoons of vegetable oil in a wok over high heat. Stir-fry the garlic, ginger, chilli, red pepper, and the white parts of the spring onions for 2-3 minutes until the pepper softens. Be careful not to burn the garlic and ginger.",
                "Add the rice wine vinegar, soy sauce, sweet chilli sauce, and tomato ketchup to the wok. Mix well and cook for another minute until bubbling.",
                "Tip the cooked beef into the wok and toss it through the sauce. Continue cooking for another minute until piping hot.",
                "Serve immediately, garnished with the green parts of the spring onions and a drizzle of extra sauce."
            ],
            notes: "Crispy chilli beef is a delicious fusion of Chinese-inspired flavors. For an extra kick, use additional red chilli slices when garnishing. Don't forget to enjoy the crunch that makes this dish so special!"
        )
        saveRecipe(
            name: "Achari Gosht (Hot & Sour Lamb Curry Instant Pot Version)",
            prepTime: "10 mins",
            cookingTime: "30 mins",
            ingredients: [
                "2 lbs bone-in lamb, cut into 1-inch pieces",
                "1/2 cup plain yogurt",
                "1/4 tsp turmeric powder",
                "2 tbsp light cooking oil",
                "1 tbsp panch phoron spice mix",
                "1 large onion, finely chopped",
                "1 tbsp finely chopped ginger",
                "1 tbsp finely chopped garlic",
                "1 tsp red chilli powder",
                "2 tbsp coriander powder",
                "1 tsp garam masala powder",
                "1 tsp amchoor powder",
                "Salt to taste",
                "2 tbsp tomato paste",
                "2 medium-sized tomatoes, finely chopped",
                "Water as needed",
                "Finely chopped fresh cilantro leaves for garnish",
                "2 tbsp fresh lemon juice"
            ],
            prePrepInstructions: [
                "Marinate the lamb pieces with yogurt and turmeric powder. Let it sit for at least 30 minutes."
            ],
            instructions: [
                "Set the Instant Pot to sauté mode, and add in the oil to heat. Add the panch phoron and let it start to sizzle.",
                "Add the onions, ginger, and garlic. Sauté, stirring occasionally, until they soften and turn slightly brown.",
                "Mix in the spices, salt, and tomato paste. Fry for 1-2 minutes to blend well.",
                "Add the chopped tomatoes and cook for a couple of minutes until they soften and turn pulpy.",
                "Slowly stir in the lamb with all the leftover marinade. Add enough water to cover the meat.",
                "Put on the lid and set the Instant Pot to Manual Pressure mode, ensuring the valve is in the sealing position.",
                "Set the pressure timer to 25 minutes and let it cook.",
                "Once the timer goes off, let the pressure release naturally. Give it a final stir, garnish with fresh cilantro leaves and lemon juice, and serve hot."
            ],
            notes: "Achari Gosht is a tangy and flavorful lamb curry inspired by Indian cuisine. The use of panch phoron (a blend of five spices) gives it a unique aroma. This recipe is perfect for a 6 Quart Instant Pot Duo 7-in-1 but can be adapted to other electric pressure cookers."
        )
        saveRecipe(
            name: "Air-Fryer Doughnuts",
            prepTime: "30 mins",
            cookingTime: "25 mins (plus overnight proving)",
            ingredients: [
                "125ml milk, lukewarm",
                "50g unsalted butter, melted and cooled to lukewarm",
                "7g sachet dried fast-action yeast",
                "60g caster sugar",
                "1 tsp vanilla extract",
                "275g plain flour, plus extra for dusting",
                "½ tsp ground cinnamon (optional)",
                "1 egg, beaten",
                "125g icing sugar (for the glaze)",
                "3 tbsp milk (for the glaze)",
                "¼ tsp vanilla extract (for the glaze)",
                "Flavourless oil, for proving"
            ],
            prePrepInstructions: [
                "Activate the yeast: Combine the milk, melted butter, yeast, 1 tsp sugar, and vanilla extract in the bowl of a stand mixer. Let sit for 8-10 minutes for the yeast to activate.",
                "Mix dry ingredients: In a separate bowl, combine the remaining sugar, flour, salt, and cinnamon (if using)."
            ],
            instructions: [
                "Mix the beaten egg into the milk mixture, then fold in the dry ingredients. Knead with a dough hook on medium speed for 5-8 minutes until the dough is smooth and elastic, or knead by hand for 10-12 minutes (note: the dough is very sticky).",
                "Transfer the dough to a lightly oiled bowl, cover with a clean tea towel, and leave in a warm place for 1 hour 30 minutes until it has doubled in size.",
                "Roll out the dough on a lightly floured surface to around 1.5cm thick. Cut out doughnuts using a doughnut cutter or two cutters (7.5cm for the outer circle and 2.5cm for the middle).",
                "Place the doughnuts (and their centres, if keeping) on a lined baking sheet. Cover with a clean tea towel and let them rise for 40 minutes, or leave overnight in the fridge for better shape retention.",
                "Preheat the air fryer to 180°C. Place 2-3 doughnuts in the air fryer basket and cook for 5-6 minutes, following the manufacturer's instructions, until golden. Check periodically to avoid burning.",
                "Cool the cooked doughnuts on a wire rack while frying the remaining batches. To prevent sticking or indents, you can use a sheet of baking parchment in the air fryer basket.",
                "Prepare the glaze by sifting icing sugar into a bowl and mixing in the milk and vanilla extract. Dip the cooled doughnuts in the glaze and let the glaze set on a wire rack."
            ],
            notes: "These doughnuts are best eaten fresh on the day they are made but can be stored in an airtight container for up to 24 hours. Fun fact: Doughnuts have origins in early Dutch settlers’ fried cakes, called ‘olykoeks,’ and have evolved into a beloved treat worldwide. Try experimenting with different glazes for variety!"
        )
        saveRecipe(
            name: "Air Fryer Korean Fried Chicken",
            prepTime: "10 mins",
            cookingTime: "20 mins",
            ingredients: [
                "6 chicken drumsticks",
                "125 ml cold water",
                "30 ml vegetable oil or any neutral oil",
                "15 ml white wine or rice vinegar (marinade)",
                "3 cloves garlic, minced (marinade)",
                "10 ml regular soy sauce (marinade)",
                "0.5 g black pepper (marinade)",
                "3 g salt (marinade)",
                "180 g potato starch or substitute with tapioca starch or cornstarch (dry batter)",
                "4 g curry powder, Japanese kind recommended (dry batter)",
                "3 g garlic powder (dry batter)",
                "4 g baking powder (dry batter)",
                "1 g onion powder (dry batter)",
                "3 g salt (dry batter)",
                "0.5 g black pepper (dry batter)",
                "Lemon juice to serve (optional)"
            ],
            prePrepInstructions: [
                "Season chicken drumsticks with marinade ingredients and massage into drumsticks. Let marinate for 10 minutes.",
                "In a large bowl, whisk together dry batter ingredients. Transfer 1 measuring cup of dry batter to a separate bowl and set aside.",
                "Whisk ½ cup cold water into the remaining dry batter to create a wet batter. Ensure you have one bowl for wet batter and one for dry batter."
            ],
            instructions: [
                "Dredge drumsticks into the dry batter, ensuring all spots are coated.",
                "Whisk the wet batter again and dredge chicken into wet batter, then back into the dry batter. If the wet batter becomes too thick, add ¼ cup cold water to loosen.",
                "Lightly spray the air fryer basket with oil and place the coated drumsticks in the basket, ensuring they have enough space. You may need to cook in batches.",
                "Spray or drizzle 1 tablespoon vegetable oil over the drumsticks. Air fry at 375°F for 11 minutes until crispy and golden.",
                "Gently flip the drumsticks using tongs to avoid tearing the coating. Spray or drizzle the remaining oil over the flipped side and air fry for another 11 minutes.",
                "Carefully remove the drumsticks with tongs and serve with fresh lemon juice if desired."
            ],
            notes: "Korean Fried Chicken is known for its light, crispy coating and flavorful marinade. Using an air fryer makes it healthier while maintaining the delicious crunch. This recipe is perfect for entertaining or family dinners!"
        )
        saveRecipe(
            name: "Air Fryer Southern Fried Chicken",
            prepTime: "20 minutes",
            cookingTime: "20 minutes",
            ingredients: [
                "2 lbs chicken (6 legs)",
                "2 teaspoons sea salt (spice mix)",
                "1 1/2 teaspoons black pepper (spice mix)",
                "1 1/2 teaspoons garlic powder (spice mix)",
                "1 1/2 teaspoons paprika (spice mix)",
                "1 teaspoon onion powder (spice mix)",
                "1 teaspoon Italian seasoning (spice mix)",
                "1 cup self-rising flour",
                "1/4 cup cornstarch",
                "2 eggs, room temperature",
                "1 tablespoon hot sauce",
                "2 tablespoons milk or buttermilk",
                "1/4 cup water",
                "Olive oil for coating"
            ],
            prePrepInstructions: [
                "Wash and dry the chicken, then set it aside.",
                "Combine all the seasoning ingredients to create the spice mix.",
                "Generously coat the chicken with about a tablespoon of the spice mixture. Add a splash of olive oil to help distribute the spices evenly, and rub it in well. Set aside."
            ],
            instructions: [
                "In a gallon-size plastic bag, mix together flour, cornstarch, and the remaining spice mix. Taste and adjust seasoning if needed.",
                "In a large dish, whisk together eggs, hot sauce, milk, and water.",
                "Lightly coat the chicken in the flour mixture, shaking off any excess, and place it on a tray to rest so the flour absorbs slightly.",
                "Coat the chicken in the egg mixture, then immediately coat it again in the flour mixture, shaking off any excess. Let the chicken rest for 15 minutes to absorb the flour.",
                "Lightly coat the chicken all over with olive oil using an oil mister or brush.",
                "Place the chicken in a greased air fryer basket, ensuring there is space around each piece for airflow.",
                "Cook at 350°F for about 18 minutes, flipping halfway through and brushing with more olive oil if needed to prevent visible flour.",
                "Remove the chicken from the air fryer and let it rest for 5 minutes before serving."
            ],
            notes: "Southern fried chicken is a beloved classic, and this air-fried version captures the crisp, golden texture without deep frying. Best enjoyed immediately as the crispy coating won't stay crunchy for long."
        )
        saveRecipe(
            name: "Air Fryer Soy Sauce Chicken Wings",
            prepTime: "18 min",
            cookingTime: "12 min",
            ingredients: [
                "680 g chicken wings and drumettes",
                "15 ml vegetable oil or any neutral tasting oil (for spraying air fryer basket)",
                "22 ml regular soy sauce (wing marinade)",
                "7.5 ml dark soy sauce (wing marinade)",
                "22 ml oyster sauce (or vegetarian stir fry sauce, wing marinade)",
                "22 ml honey (or maple syrup, brown or white sugar, wing marinade)",
                "7.5 ml sesame oil (wing marinade)",
                "7.5 ml Shaoxing wine (or dry sherry wine or white wine, wing marinade)",
                "2 g ginger, peeled and grated (wing marinade)",
                "3 g garlic powder (wing marinade)",
                "1 green onion, chopped finely (optional garnish)"
            ],
            prePrepInstructions: [
                "Pat chicken wings dry with paper towels to remove excess moisture.",
                "Transfer chicken wings into a large mixing bowl.",
                "Add all marinade ingredients to the bowl and massage into the chicken until well coated.",
                "Marinate for at least 15 minutes or overnight for best flavor."
            ],
            instructions: [
                "Spray the air fryer basket with vegetable oil or any neutral tasting oil to prevent the wings from sticking.",
                "Place the chicken wings in a single layer without overlapping. Depending on the size of your air fryer basket, air fry in batches to avoid overlapping.",
                "Air fry at 400°F for 8 minutes on one side.",
                "Flip the wings over and air fry for another 4-5 minutes on the other side until an internal temperature of 165°F is reached, or the juices run clear, and the meat is cooked through.",
                "If not fully cooked, air fry for an additional minute as needed."
            ],
            notes: "These soy sauce chicken wings are a flavorful and quick dish perfect for any occasion. Garnish with chopped green onions for added color and flavor!"
        )
        saveRecipe(
            name: "Aloo Gosht (Mutton/Lamb and Potato Curry)",
            prepTime: "30 mins",
            cookingTime: "30 mins (Instant Pot)",
            ingredients: [
                "0.5 cup neutral oil, such as grapeseed or avocado oil",
                "2 tbsp ghee, sub butter",
                "2-2.4 lb (~1,090 g) bone-in goat or lamb meat (cut into ~2\" pieces, cleaned and excess fat removed, then patted dry)",
                "3.5 tsp kosher salt (use less if using regular/table salt), divided",
                "12-14 (~2 tbsp) garlic cloves, crushed or finely chopped",
                "2-inch (~2 tbsp) ginger, crushed or finely chopped",
                "2 medium (~450-500 g) yellow onions, finely chopped",
                "4 small (~400 g) Roma tomatoes, roughly puréed or finely chopped",
                "2-4 small green chili peppers (Thai chili or 1/2 Serrano), chopped or sliced",
                "4 green cardamom pods",
                "6 whole cloves",
                "1 tsp cumin seeds",
                "3-4 tsp coriander powder (adjust to taste)",
                "1-2 tsp cumin powder (adjust to taste)",
                "1 tsp red chili powder (or to taste, substitute Kashmiri chili powder for less heat)",
                "1 tsp turmeric powder",
                "0.5 tsp ground black pepper",
                "2 tbsp plain whole-milk yogurt, whisked (omit for dairy-free)",
                "4 (~640-700 g) small russet potatoes, peeled and cut into 1.5-2\" cubes"
            ],
            prePrepInstructions: [
                "Clean and pat dry the goat or lamb meat, removing excess fat.",
                "Peel and cube the potatoes.",
                "Puree or finely chop the onions and tomatoes."
            ],
            instructions: [
                "Select 'Sauté – More/High' on the Instant Pot and add oil, ghee, meat, and 3/4 tsp salt. Sauté for 5 minutes, stirring occasionally, until meat is seared on some edges.",
                "Add garlic and ginger and sauté for a minute until aromatic.",
                "Mix in onions, tomatoes, green chili peppers, whole spices, ground spices (except garam masala), and remaining salt. Stir well.",
                "Add up to 1/4 cup water if needed (moisture should cover at least 1/3 of the meat). Cancel Sauté.",
                "Select 'Pressure Cook – High' and set timer for 20 minutes. Allow pressure to naturally release for 10 minutes. If meat isn’t tender, pressure cook again for 3-5 minutes.",
                "Select 'Sauté – More/High' and stir occasionally to sauté out water content (~5-7 minutes). Continue to sauté for another 5-6 minutes to thicken the masala and separate oil.",
                "Cancel Sauté, stir in yogurt, and add potatoes with 2 – 2 ¼ cups water depending on desired curry consistency.",
                "Select 'Pressure Cook – High' for 5-6 minutes depending on potato size. Allow pressure to naturally release for 5 minutes.",
                "Taste and adjust salt. Garnish with garam masala and chopped cilantro before serving."
            ],
            notes: "A classic South Asian curry perfect for pairing with roti, naan, or basmati rice. This dish is flavorful and hearty, a staple in many households."
        )
        saveRecipe(
            name: "American Pancakes",
            prepTime: "5 mins",
            cookingTime: "10 mins",
            ingredients: [
                "200g self-raising flour",
                "1 ½ tsp baking powder",
                "1 tbsp golden caster sugar",
                "3 large eggs",
                "25g melted butter, plus extra for cooking",
                "200ml milk",
                "vegetable oil, for cooking",
                "maple syrup",
                "toppings of your choice, such as cooked bacon, chocolate chips, blueberries or peanut butter and jam"
            ],
            prePrepInstructions: [
                "Mix 200g self-raising flour, 1 ½ tsp baking powder, 1 tbsp golden caster sugar, and a pinch of salt together in a large bowl."
            ],
            instructions: [
                "Create a well in the centre with the back of your spoon then add 3 large eggs, 25g melted butter and 200ml milk.",
                "Whisk together either with a balloon whisk or electric hand beaters until smooth then pour into a jug.",
                "Heat a small knob of butter and 1 tsp of oil in a large, non-stick frying pan over a medium heat.",
                "When the butter looks frothy, pour in rounds of the batter, approximately 8cm wide. Make sure you don’t put the pancakes too close together as they will spread during cooking.",
                "Cook the pancakes on one side for about 1-2 mins or until lots of tiny bubbles start to appear and pop on the surface.",
                "Flip the pancakes over and cook for a further minute on the other side. Repeat until all the batter is used up.",
                "Serve your pancakes stacked up on a plate with a drizzle of maple syrup and any of your favourite toppings."
            ],
            notes: "American pancakes are a classic breakfast dish. Experiment with different toppings like fresh fruits, whipped cream, or savory additions like bacon."
        )
        saveRecipe(
            name: "Apam Balik",
            prepTime: "10 mins",
            cookingTime: "20 mins",
            ingredients: [
                "5 ml unsalted butter for greasing the pan (or substitute with a dairy-free butter or neutral oil)",
                "135 g all-purpose flour",
                "63 g self-rising flour",
                "3 g baking soda",
                "0.8 g salt",
                "500 ml warm milk (or substitute with plain oat milk for a dairy-free version)",
                "4.7 g dry active yeast",
                "10 ml vanilla extract",
                "24 g white granulated sugar",
                "1 large egg (room temperature)",
                "white granulated sugar (as much as desired)",
                "crushed peanuts (as much as desired)",
                "250 ml creamed corn (canned)",
                "unsalted butter (or substitute with a vegan butter)"
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
            notes: "Apam Balik is a popular Malaysian street food pancake filled with sweet and savory fillings. For a dairy-free version, use oat milk and vegan butter. Enjoy it as a dessert, snack, or breakfast."
        )
        saveRecipe(
            name: "Apple Crumble",
            prepTime: "10 mins",
            cookingTime: "25-30 mins",
            ingredients: [
                "350g (approx. 4-5) Bramley apples",
                "100g Demerara sugar (for filling)",
                "1/2 teaspoon ground nutmeg",
                "1/2 teaspoon ground cinnamon",
                "Box of shortcrust pastry",
                "Water",
                "112.5g Demerara sugar (for crumble)",
                "45g oats",
                "75g plain flour",
                "90g cold butter",
                "1/2 teaspoon ground cinnamon (for crumble)",
                "Custard (to serve)"
            ],
            prePrepInstructions: [
                "Defrost the butter and pastry.",
                "Peel and chop the apples into cubes."
            ],
            instructions: [
                "Sprinkle 100g Demerara sugar evenly over the chopped apples in a saucepan.",
                "Add 1/2 teaspoon nutmeg, 1/2 teaspoon cinnamon, and water to the apples. Cover and cook until translucent.",
                "In a bowl, mix 90g butter, 112.5g sugar, 75g flour, and 45g oats until a crumble forms. Add 1/2 teaspoon cinnamon to the crumble mix.",
                "Preheat the oven to Gas Mark 5/375°F/190°C.",
                "Grease the two tins and blind bake the pastry for about 6 minutes.",
                "Remove the cooked apple from the stove and set aside.",
                "Arrange the shortcrust pastry in the oven dish and add the cooked apple.",
                "Distribute the crumble mix over the apples and pat it down with a spatula.",
                "Bake for 25 minutes or until the crumble is toasted golden.",
                "Sprinkle cinnamon sugar and serve with custard."
            ],
            notes: "Apple crumble is a versatile dessert that pairs well with custard, vanilla ice cream, or chilled double cream. For added flavor, consider adding 1 tsp of cinnamon to the apples before cooking. You can substitute Hob Nobs for digestive biscuits in the crumble for a different texture."
        )
        saveRecipe(
            name: "Apple Jalebi (Gluten Free, Paleo, Vegan)",
            prepTime: "10 hours (fermentation) + 15 mins",
            cookingTime: "15 mins",
            ingredients: [
                "Avocado oil or fat of choice, enough to fry",
                "½ cup almond flour",
                "½ cup arrowroot flour (for batter)",
                "½ cup full-fat canned coconut milk",
                "Probiotic capsules totaling 40 to 50 billion cultures",
                "¼ cup water (for batter)",
                "¼ cup arrowroot flour (for coating)",
                "2 apples, peeled, cored, and sliced",
                "½ cup coconut sugar",
                "¼ cup water (for syrup)",
                "¼ teaspoon ground cardamom",
                "Crushed pistachios, for garnish"
            ],
            prePrepInstructions: [
                "Prepare the batter by combining almond flour, arrowroot flour, and coconut milk in a bowl.",
                "Empty the contents of the probiotic capsules into the bowl and mix well.",
                "Loosely cover the bowl with a lid and place it in an oven with only the oven light on (do not turn on the oven) for at least 10 hours to ferment the batter."
            ],
            instructions: [
                "Add ¼ cup water to the fermented batter and mix well.",
                "Heat oil in a wok or a deep, wide-bottomed pot to 360°F or until a small drop of the batter sizzles and floats to the top.",
                "While the oil is heating, add ¼ cup arrowroot flour to a plate. Dip the apple slices on both sides into the arrowroot flour.",
                "Dip the apple slices into the fermented batter, then place them into the hot oil. Fry 2-3 apple slices at a time until both sides are light golden brown.",
                "Remove the fried apple slices and set them aside on a paper-towel-lined plate.",
                "Dip the fried apple slices into the cooled syrup, garnish with crushed pistachios, and serve."
            ],
            notes: "This delicious Malaysian-inspired dessert uses probiotics to ferment the batter, resulting in a light and flavorful dish. The syrup can be prepared ahead of time and cooled for dipping. Experiment with different oils or vegan butter substitutes for frying. Adjust the number of probiotic capsules based on the culture count (40-50 billion)."
        )
        saveRecipe(
            name: "Apple Crisp with Oat Topping",
            prepTime: "10 mins",
            cookingTime: "35-40 mins",
            ingredients: [
                "6 apples - peeled, cored, and sliced",
                "2 tablespoons white sugar",
                "1 ½ teaspoons ground cinnamon, divided",
                "1 cup brown sugar",
                "¾ cup old-fashioned oats",
                "¾ cup all-purpose flour",
                "½ cup cold butter"
            ],
            prePrepInstructions: [
                "Preheat the oven to 350°F (175°C)."
            ],
            instructions: [
                "Toss apples with white sugar and ½ teaspoon cinnamon in a medium bowl to coat. Pour into a 9-inch square baking dish.",
                "Mix brown sugar, oats, flour, and 1 teaspoon cinnamon in a separate bowl.",
                "Cut in cold butter with two knives or a pastry blender until the mixture resembles coarse crumbs.",
                "Spread over apples and pat down gently until even.",
                "Bake in the preheated oven until golden brown and sides are bubbling, about 35-40 minutes."
            ],
            notes: "Use high-quality cinnamon for a richer flavor. Serve with ice cream or whipped cream for an extra treat."
        )
        saveRecipe(
            name: "Apple Oat Crumble",
            prepTime: "20 mins",
            cookingTime: "30 mins",
            ingredients: [
                "700g apples, peeled, cored, and sliced finely",
                "3 tablespoons brown sugar",
                "2 teaspoons plain white flour",
                "2 tablespoons lemon juice (or water)",
                "½ teaspoon ground cinnamon",
                "¾ cup plain white flour (112g)",
                "¾ cup rolled oats (63g)",
                "½ cup brown sugar (100g)",
                "½ teaspoon ground cinnamon",
                "¼ teaspoon salt",
                "120g cold butter, cubed"
            ],
            prePrepInstructions: [
                "Preheat the oven to 190°C (375°F)."
            ],
            instructions: [
                "Peel and core the apples, then slice finely and place in a medium bowl.",
                "Add the first measure of brown sugar, flour, lemon juice, and cinnamon. Mix to coat the apples.",
                "Pour into a baking dish and press the apples flat in the dish to remove gaps.",
                "In a medium bowl, combine the flour, oats, second measure of brown sugar, cinnamon, and salt. Mix well.",
                "Rub in the cubed butter into the flour and oats mixture until it forms moist breadcrumbs.",
                "Sprinkle the crumble mixture evenly over the apples.",
                "Bake for at least 30 minutes until golden brown and bubbling.",
                "Let sit for 20 minutes before serving."
            ],
            notes: "Serve with ice cream, custard, or cream. This dish can be reheated or frozen for later use."
        )
        saveRecipe(
            name: "Apple Crumble",
            prepTime: "10 mins",
            cookingTime: "30 mins",
            ingredients: [
                "1kg (2lb 3½oz) Bramley apples",
                "Pinch of sugar, to taste",
                "1 tablespoon water or apple juice",
                "100g (3½oz) plain flour",
                "75g (2½oz) butter",
                "50g (2oz) rolled oats",
                "100g (3½oz) demerara sugar"
            ],
            prePrepInstructions: [
                "Preheat the oven to 200°C (180°C Fan)/Gas 6."
            ],
            instructions: [
                "Wipe the apples and cut them into quarters. Remove the cores and slice each piece in two.",
                "Put the apples into a pan. Taste a slice for sweetness and add sugar accordingly. Add a tablespoon of water or apple juice and cook over medium heat for about 5 minutes until softened.",
                "Transfer the apple mixture to a shallow ovenproof dish.",
                "Blend the flour and butter in a food processor until the mixture resembles breadcrumbs.",
                "Stir in the oats and brown sugar, then sprinkle over the cooked apples in the dish.",
                "Bake for 30 minutes or until crisp and golden brown on top."
            ],
            notes: "Serve warm with custard or vanilla ice cream. Adjust sugar based on the sweetness of the apples used."
        )
        saveRecipe(
            name: "Apple Crumble with Spiced Filling",
            prepTime: "15 mins",
            cookingTime: "18-22 mins",
            ingredients: [
                "5 apples, peeled and cut into 1-inch pieces",
                "1 tablespoon apple cider vinegar",
                "2 tablespoons water",
                "1 teaspoon cinnamon",
                "¼ teaspoon ground ginger",
                "¼ teaspoon nutmeg",
                "Pinch of sea salt",
                "½ cup almond flour",
                "⅓ cup all-purpose flour",
                "⅓ cup whole rolled oats",
                "⅓ cup crushed walnuts",
                "⅓ cup brown sugar or coconut sugar",
                "⅓ cup melted coconut oil",
                "½ teaspoon cinnamon",
                "Heaping ¼ teaspoon sea salt",
                "1 teaspoon water, if needed"
            ],
            prePrepInstructions: [
                "Preheat the oven to 400°F and grease an 8x8-inch baking dish."
            ],
            instructions: [
                "Combine the apples, apple cider vinegar, and water in a saucepan. Simmer over very low heat, covered, for 15 minutes, stirring occasionally.",
                "Uncover, add cinnamon, ginger, nutmeg, and salt. Stir well. The apples should be tender, and the juices should thicken.",
                "In a food processor, pulse the almond flour, all-purpose flour, oats, walnuts, sugar, coconut oil, cinnamon, and salt until crumbly. Add water if needed.",
                "Scoop the apple filling into the prepared baking dish. Sprinkle the topping evenly over the filling.",
                "Bake for 18-22 minutes or until lightly crisp on top."
            ],
            notes: "This recipe has a delightful spiced twist. Garnish with additional walnuts or a dollop of whipped cream for extra flavor."
        )
        saveRecipe(
            name: "Asian Lemon Wings",
            prepTime: "20 mins",
            cookingTime: "16 mins (air fry) or 8 mins (deep fry)",
            ingredients: [
                "907g chicken wings (about 22 wings)",
                "120g corn starch or potato starch/tapioca starch (add another ¼ cup if needed)",
                "30ml vegetable oil or any neutral oil",
                "30ml regular soy sauce (for marinade)",
                "4g chicken bouillon powder (for marinade)",
                "1g ginger powder (for marinade)",
                "4.5g garlic powder (for marinade)",
                "18g white granulated sugar (for sweet lemon sauce, or substitute with honey or brown sugar)",
                "45ml lemon juice (for sweet lemon sauce)",
                "3g salt (for sweet lemon sauce)"
            ],
            prePrepInstructions: [
                "Marinate chicken wings with soy sauce, chicken bouillon powder, ginger powder, and garlic powder for 10 minutes at room temperature.",
                "Mix lemon juice, sugar, and salt in a small bowl to prepare the sweet lemon sauce. Microwave for 30 seconds to dissolve the sugar if needed. Set aside."
            ],
            instructions: [
                "In a medium bowl or Ziplock bag, coat marinated wings with cornstarch or potato starch, shaking off excess starch. Place coated wings on a parchment-lined baking sheet to prevent sticking.",
                "For air frying: Lightly spray air fryer basket with oil. Place wings in a single layer, leaving space between pieces. Air fry at 400°F for 16 minutes, flipping halfway and spraying lightly with oil. For subsequent batches, reduce cooking time to 6-7 minutes per side as the air fryer heats up. Ensure the internal temperature reaches 165°F.",
                "For deep frying: Heat 2 cups neutral oil to 350°F in a large pot or pan. Carefully lower coated wings into the hot oil one at a time. Fry in small batches for 8 minutes total, flipping halfway. Transfer fried wings to a wire rack or paper towel-lined baking sheet to drain excess oil.",
                "Toss hot wings in sweet lemon sauce. Garnish with green onions, if desired."
            ],
            notes: "Asian Lemon Wings are a perfect mix of crispy texture and tangy flavor. Air frying is a healthier alternative to deep frying, yet both methods yield excellent results. Serve as an appetizer or a main dish!"
        )
        saveRecipe(
            name: "Baingan ka Bharta (Indian Eggplant)",
            prepTime: "10 mins",
            cookingTime: "50 mins",
            ingredients: [
                "2 large eggplants",
                "4 tablespoons oil, divided",
                "1 teaspoon cumin seeds",
                "1 large white onion, finely chopped",
                "5 garlic cloves, minced",
                "1-inch knob ginger, minced",
                "1-2 Serrano peppers, minced (adjust according to preference)",
                "2 teaspoons coriander powder",
                "2 teaspoons salt",
                "½ teaspoon black pepper",
                "½ teaspoon garam masala",
                "½ teaspoon paprika",
                "½ teaspoon turmeric powder",
                "3 medium tomatoes, chopped",
                "Cilantro, chopped (for garnish)"
            ],
            prePrepInstructions: [
                "Preheat the oven to 500°F.",
                "Make four slits in each eggplant and coat them with 1 tablespoon of oil each.",
                "Place eggplants on a baking sheet and roast in the oven for 40 minutes, flipping halfway through.",
                "Turn the oven to broil for the last 5 minutes. Remove the eggplants and allow them to cool.",
                "Peel off the skin from the eggplants and chop the flesh. Set aside."
            ],
            instructions: [
                "While the eggplants are roasting, heat 2 tablespoons of oil in a Dutch oven or heavy pot over medium heat.",
                "Add cumin seeds and wait for them to splutter.",
                "Add onions and sauté for 10 minutes until golden brown.",
                "Stir in garlic, ginger, Serrano pepper, and spices. Stir-fry for 1 minute.",
                "Add chopped tomatoes, mix well, cover the pot, and cook for 10 minutes.",
                "Uncover and stir-fry for another 5 minutes.",
                "Add the roasted and chopped eggplant, mix, and cook for an additional 5 minutes.",
                "Garnish with chopped cilantro and serve hot."
            ],
            notes: "Baingan ka Bharta is a traditional Indian dish known for its smoky flavor, thanks to the roasted eggplant. Serve it with naan, roti, or steamed rice for a comforting meal. This dish originates from North India and is a staple in many households."
        )
        saveRecipe(
            name: "Baked Cajun Garlic Butter Cod",
            prepTime: "5 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "3 cod filets, cut in half",
                "Salt and pepper, to taste",
                "1/4 cup butter, melted",
                "1 tablespoon olive oil",
                "3 garlic cloves, minced",
                "1 tablespoon Cajun seasoning"
            ],
            prePrepInstructions: [
                "Preheat oven to 400°F (200°C).",
                "Cut cod filets in half and place in a 9x13 inch baking dish."
            ],
            instructions: [
                "Sprinkle cod with salt and pepper.",
                "In a small bowl, whisk together melted butter, olive oil, garlic, and Cajun seasoning to make the Cajun Garlic Butter Sauce.",
                "Spread the sauce evenly over the fish.",
                "Bake for about 15 minutes or until the fish is opaque and flakes easily."
            ],
            notes: "This dish pairs wonderfully with steamed vegetables or a side of rice. Cajun seasoning adds a spicy kick, but feel free to adjust based on your spice tolerance!"
        )
        saveRecipe(
            name: "Crispy Chicken Goujons",
            prepTime: "15 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                // Chicken Strips
                "3 large chicken breasts, cut into finger-width strips",
                "2 eggs, gently whisked",
                "3/4 cup (90g) plain (all-purpose) flour",
                "Good pinch of salt and pepper",
                "3 cups (150g) panko breadcrumbs",
                "1 tsp paprika",
                "2 tbsp olive oil",
                "Good pinch of salt and pepper",
                // Chimichurri
                "6 tbsp olive oil",
                "2 cloves garlic, peeled and minced",
                "1 large bunch of flat-leaf parsley, chopped very finely",
                "1/4 tsp salt",
                "1/4 tsp pepper",
                "1/4 tsp dried oregano",
                "2 tbsp lemon juice",
                "1 tsp red wine vinegar",
                "1 red chili, finely chopped (optional, discard seeds for less heat)"
            ],
            prePrepInstructions: [
                "Preheat the oven to 200°C/400°F (fan).",
                "Prepare three bowls: one for whisked eggs, one for flour mixed with salt and pepper, and one for breadcrumbs mixed with paprika, olive oil, salt, and pepper."
            ],
            instructions: [
                "Dip chicken strips into the flour, then into the egg, and finally into the breadcrumb mixture. Place on a baking sheet, ensuring strips are spaced apart.",
                "Bake in the oven for 15 minutes, or until golden brown and cooked through.",
                "Serve with your favorite sauce or Chimichurri."
            ],
            notes: """
            This recipe pairs wonderfully with potato wedges. To make wedges:
            - Slice 3 large potatoes into wedges, coat with 2 tbsp olive oil, 1/2 tsp paprika, 1/4 tsp cumin, and a pinch of salt and pepper.
            - Bake at 200°C/400°F for 25-30 minutes, turning once or twice.
            Cooking tip: Start the potato wedges before preparing the chicken, so they finish together!
            """
        )
        saveRecipe(
            name: "Peri Peri Chicken",
            prepTime: "4+ hours (including marination time)",
            cookingTime: "40 minutes",
            ingredients: [
                "1 kg chicken, preferably with bones in",
                "3 tbsp ketchup",
                "2 tsp chicken seasoning",
                "2 tsp chili powder/flakes",
                "2 tsp peri peri seasoning",
                "2 tsp oil",
                "Optional: sliced onions, sliced bell peppers, sliced carrots, cubed potatoes, cubed sweet potatoes"
            ],
            prePrepInstructions: [
                "Wash and drain chicken thoroughly.",
                "Mix ketchup, chicken seasoning, chili, peri peri seasoning, and oil in a separate dish.",
                "Coat chicken thoroughly with the seasoning mix.",
                "Cover and marinate for 4 hours or overnight if possible."
            ],
            instructions: [
                "Preheat oven to 225°C.",
                "Grease an oven tray and optionally lay out vegetables first.",
                "Spread chicken evenly on the tray and bake for 20 minutes.",
                "Flip chicken and bake for another 20 minutes.",
                "Check if chicken is cooked (opaque white meat and no blood). Serve once done."
            ],
            notes: "This dish pairs well with a side of rice or roasted vegetables."
        )
        saveRecipe(
            name: "Cajun Chicken",
            prepTime: "4+ hours (including marination time)",
            cookingTime: "40 minutes",
            ingredients: [
                "1 kg chicken, preferably with bones in",
                "3 tbsp ketchup",
                "2 tsp chicken seasoning",
                "2 tsp chili powder/flakes",
                "2 tsp Cajun seasoning",
                "2 tsp oil",
                "Optional: sliced onions, sliced bell peppers, sliced carrots, cubed potatoes, cubed sweet potatoes"
            ],
            prePrepInstructions: [
                "Wash and drain chicken thoroughly.",
                "Mix ketchup, chicken seasoning, chili, Cajun seasoning, and oil in a separate dish.",
                "Coat chicken thoroughly with the seasoning mix.",
                "Cover and marinate for 4 hours or overnight if possible."
            ],
            instructions: [
                "Preheat oven to 225°C.",
                "Grease an oven tray and optionally lay out vegetables first.",
                "Spread chicken evenly on the tray and bake for 20 minutes.",
                "Flip chicken and bake for another 20 minutes.",
                "Check if chicken is cooked (opaque white meat and no blood). Serve once done."
            ],
            notes: "For extra flavor, garnish with freshly chopped parsley before serving."
        )
        saveRecipe(
            name: "Jerk Chicken",
            prepTime: "4+ hours (including marination time)",
            cookingTime: "40 minutes",
            ingredients: [
                "1 kg chicken, preferably with bones in",
                "3 tbsp ketchup",
                "2 tsp chicken seasoning",
                "2 tsp chili powder/flakes",
                "2 tsp jerk chicken seasoning",
                "2 tsp black pepper powder",
                "2 tsp oil",
                "Optional: sliced onions, sliced bell peppers, sliced carrots, cubed potatoes, cubed sweet potatoes"
            ],
            prePrepInstructions: [
                "Wash and drain chicken thoroughly.",
                "Mix ketchup, chicken seasoning, chili, jerk chicken seasoning, black pepper, and oil in a separate dish.",
                "Coat chicken thoroughly with the seasoning mix.",
                "Cover and marinate for 4 hours or overnight if possible."
            ],
            instructions: [
                "Preheat oven to 225°C.",
                "Grease an oven tray and optionally lay out vegetables first.",
                "Spread chicken evenly on the tray and bake for 20 minutes.",
                "Flip chicken and bake for another 20 minutes.",
                "Check if chicken is cooked (opaque white meat and no blood). Serve once done."
            ],
            notes: "Serve with a side of coleslaw or rice and peas for a true Caribbean experience."
        )
        saveRecipe(
            name: "BBQ Chicken",
            prepTime: "4+ hours (including marination time)",
            cookingTime: "40 minutes",
            ingredients: [
                "1 kg chicken, preferably with bones in",
                "3 tbsp BBQ sauce",
                "3 tbsp brown sauce",
                "2 tsp chicken seasoning",
                "2 tsp chili powder/flakes",
                "2 tsp honey",
                "2 tsp oil",
                "Optional: sliced onions, sliced bell peppers, sliced carrots, cubed potatoes, cubed sweet potatoes"
            ],
            prePrepInstructions: [
                "Wash and drain chicken thoroughly.",
                "Mix BBQ sauce, brown sauce, chicken seasoning, chili, honey, and oil in a separate dish.",
                "Coat chicken thoroughly with the seasoning mix. Taste test the marinade to ensure it’s mildly salty before coating.",
                "Cover and marinate for 4 hours or overnight if possible."
            ],
            instructions: [
                "Preheat oven to 225°C.",
                "Grease an oven tray and optionally lay out vegetables first.",
                "Spread chicken evenly on the tray and bake for 20 minutes.",
                "Flip chicken and bake for another 20 minutes.",
                "Check if chicken is cooked (opaque white meat and no blood). Serve once done."
            ],
            notes: "This BBQ chicken is perfect for family gatherings and pairs well with a crisp green salad."
        )
        saveRecipe(
            name: "Thai Banana Pancakes (Banana Roti)",
            prepTime: "3+ hours (including resting time for dough)",
            cookingTime: "20 minutes",
            ingredients: [
                "1 ½ tsp salt",
                "1 Tbsp sweetened condensed milk (or substitute with 1 Tbsp sugar)",
                "1 large egg",
                "260 ml water",
                "500 g all-purpose flour",
                "55 g unsalted butter, room temp",
                "1½ Tbsp unsalted butter (for coating the dough)",
                "1 Tbsp neutral-flavored oil (for coating the dough)",
                "Neutral-flavored oil for cooking",
                "Extra unsalted butter for cooking (optional)",
                "Filling and toppings: banana, sweetened condensed milk, Nutella or chocolate sauce, granulated sugar"
            ],
            prePrepInstructions: [
                "In a large bowl, mix salt and water until dissolved. Add condensed milk and egg, and whisk to combine.",
                "In another bowl, combine flour and butter. Rub butter into the flour until no large chunks remain.",
                "Add the flour mixture to the wet ingredients and knead until the dry flour is absorbed. Let rest for 15-30 minutes.",
                "Knead the dough for 5 minutes until moist but not sticky. Let rest for 10-15 minutes.",
                "Cut dough into 80g pieces and form into balls. Brush with a butter-oil mixture and store in a container, allowing to rest for at least 3 hours (or refrigerate overnight)."
            ],
            instructions: [
                "Preheat a flat skillet over medium heat and generously coat with oil.",
                "Stretch each dough ball into a very thin sheet. Transfer stretched dough carefully to the pan.",
                "Place banana slices or other filling in the center and fold the edges of the dough over to seal.",
                "Cook until both sides are golden and crispy, flipping every minute (about 4-5 minutes total).",
                "Optionally, add a small piece of butter to the pan, let it melt, and coat the roti.",
                "Cut the roti into pieces, drizzle with condensed milk or chocolate sauce, and sprinkle with granulated sugar before serving."
            ],
            notes: "This street-food favorite is perfect for dessert or a snack. Adjust toppings to suit your taste and be cautious of hot filling when serving!"
        )
        saveRecipe(
            name: "Banana Bread",
            prepTime: "15 minutes",
            cookingTime: "50 minutes to 1 hour",
            ingredients: [
                "270g Plain (All Purpose) Flour",
                "200g Caster (Granulated) Sugar",
                "1 tsp Bicarbonate of Soda",
                "1/2 tsp Salt",
                "3 Small-Medium or 2 Large Bananas (ripe)",
                "1 Egg",
                "1 Egg Yolk",
                "60g Plain Yogurt (or Sour Cream or Buttermilk)",
                "110g Melted Unsalted Butter (cooled)",
                "100g Chocolate Chips (mix of Milk and Dark recommended)",
                "60g Chopped Walnuts",
                "20g Chopped Pecans"
            ],
            prePrepInstructions: [
                "Preheat oven to Gas Mark 4.5 or 165°C (fan-assisted).",
                "Grease a 2lb loaf tin and line it with parchment paper, leaving an overhang on the long sides."
            ],
            instructions: [
                "In a large bowl, mix together the dry ingredients: flour, sugar, bicarbonate of soda, and salt.",
                "Mash the bananas in a separate bowl using a fork or potato masher.",
                "In another bowl, whisk together the whole egg and egg yolk. Add yogurt, melted butter, and the mashed bananas. Mix until combined.",
                "Pour the wet mixture into the bowl with the dry ingredients. Mix just until combined; avoid overmixing.",
                "Fold in 90% of the chocolate chips, walnuts, and pecans. Save the remaining 10% for topping.",
                "Pour the batter into the prepared loaf tin and sprinkle the reserved chocolate chips and nuts on top.",
                "Bake for 50 minutes to 1 hour. Check doneness with a skewer inserted into the middle; if it comes out clean, it's cooked. If the top browns too quickly and the skewer comes out unclean, cover the loaf loosely with foil and bake for additional time until fully cooked."
            ],
            notes: "This banana bread is rich and moist, perfect for breakfast or dessert. Use overly ripe bananas for the best flavor. Customize with different nuts or chocolate types!"
        )
        saveRecipe(
            name: "Bao Buns (A Foolproof Recipe)",
            prepTime: "20 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "300 g all-purpose flour (see notes for substitutes)",
                "1¼ teaspoon instant yeast (see notes for substitutes)",
                "1 teaspoon baking powder",
                "1 teaspoon white sugar",
                "165 g lukewarm water or milk (see notes)",
                "Oil (for brushing)"
            ],
            prePrepInstructions: [
                "Ensure all ingredients are measured and ready.",
                "Prepare necessary tools: mixing bowl, steamer with liners, rolling pin, and biscuit cutter (optional)."
            ],
            instructions: [
                "To prepare the dough (manual method): In a large bowl, mix flour, instant yeast, baking powder, and sugar. Gradually add water or milk while stirring. Knead by hand until a rough dough forms. Rest for 10 minutes, then knead for 2-3 minutes until smooth.",
                "For the stand-mixer method: Combine all ingredients in the mixing bowl and knead with a dough hook on low speed for 8-10 minutes until smooth.",
                "To shape the buns: Roll the dough into a rope and divide into 8-12 pieces. Roll each piece into a ball and flatten with a rolling pin into an oval shape (dust with flour to prevent sticking). Brush a thin layer of oil over half the oval, then fold over lengthways.",
                "Alternatively, flatten the dough into a rectangle and use a round cutter to cut out circles. Roll each circle into an oval shape and fold as above.",
                "Line the steamer basket with parchment paper or silicone liners. Place the buns in the basket, leaving space for expansion.",
                "Let the buns proof for about 30 minutes or until they are plump and feel lighter in weight.",
                "To steam the buns: Add 500 ml of water to the steaming pot. Once boiling, reduce heat to medium-low and steam the buns for 10 minutes.",
                "Allow buns to cool completely if storing or freeze for later use. Reheat by steaming for 5 minutes if chilled or 7 minutes if frozen."
            ],
            notes: "Bao buns are soft and fluffy, perfect for filling with meats, vegetables, or sweet spreads. Adjust proofing time based on room temperature and ensure proper steaming for best results!"
        )
        saveRecipe(
            name: "Beijing Beef",
            prepTime: "30 minutes",
            cookingTime: "20 minutes",
            ingredients: [
                "800g (1¾ lb) beef strips (beef fillet or any tender beef strips will work)",
                "2 tbsp Shaoxing cooking wine",
                "2 tbsp soy sauce",
                "1 red capsicum, diced",
                "1 brown onion, diced",
                "3 cloves garlic, finely diced",
                "3 tbsp oyster sauce",
                "2 tbsp black vinegar",
                "3 tbsp tomato sauce (ketchup)",
                "3 tsp sambal (chilli paste)",
                "200g (7 oz) cornflour (cornstarch)",
                "400ml (14 fl oz) beef tallow or neutral-flavoured oil",
                "Rice, to serve"
            ],
            prePrepInstructions: [
                "Mix beef strips with Shaoxing cooking wine and soy sauce in a bowl. Marinate for 30 minutes to 1 hour.",
                "Prepare the sauce by mixing oyster sauce, black vinegar, tomato sauce, and sambal in a small bowl.",
                "Chop all vegetables and ensure the rice is cooked and kept warm."
            ],
            instructions: [
                "Heat oil in a wok to 180°C (350°F).",
                "Dust the marinated beef strips in cornflour, shaking off excess.",
                "Fry the beef in batches until crispy. Remove from the oil and set aside.",
                "Drain 99% of the oil from the wok and return it to high heat.",
                "Add diced onion and capsicum to the wok. Sauté for 2-3 minutes until slightly softened.",
                "Add diced garlic and toss well.",
                "Return the crispy beef to the wok and add the prepared sauce. Stir-fry over high heat for 2-3 minutes until the beef is well coated.",
                "Serve hot with steamed rice and optional wok-fried greens."
            ],
            notes: "Beijing Beef is a quick and flavorful dish that pairs perfectly with rice and stir-fried vegetables. Customize the spice level by adjusting the sambal quantity to taste!"
        )
        saveRecipe(
            name: "Beef Chow Fun",
            prepTime: "20 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "550 g fresh rice noodles (or see Notes for using dried rice noodles)",
                "226 g flank steak (or see Notes for beef substitutes)",
                "30 ml vegetable oil (or any neutral oil)",
                "4 scallions, chopped into 1-inch segments (green and white parts separated)",
                "100 g mung bean sprouts or soy bean sprouts, washed and strained",
                "3 cloves garlic, minced"
            ],
            prePrepInstructions: [
                "Thinly slice flank steak against the grain on an angle into ¼-inch-thick pieces and transfer to a bowl.",
                "Add marinade ingredients (4 g cornstarch, 7.5 ml soy sauce, 5 ml Shaoxing wine, 1 g baking soda, 0.3 g white pepper, and 15 ml vegetable oil) to the beef and mix well. Marinate for 15 minutes.",
                "Combine noodle sauce ingredients (22 ml soy sauce, 15 ml oyster sauce, 15 ml dark soy sauce, 10 ml sesame oil, and 8 g sugar) in a small bowl and set aside.",
                "If using fresh rice noodles, microwave for 2-3 intervals of 60 seconds until soft and pliable. Gently separate them by hand once cooled."
            ],
            instructions: [
                "Heat vegetable oil in a large pan over medium-high heat.",
                "Fry marinated beef in a single layer until cooked and slightly browned on the edges. Remove and set aside.",
                "Using the residual oil, fry the scallion whites and garlic for 10 seconds.",
                "Add remaining oil, rice noodles, and noodle sauce to the pan. Toss gently with two spatulas, lifting from the bottom.",
                "Return the cooked beef, bean sprouts, and scallion greens to the pan. Toss gently until everything is mixed.",
                "Remove from heat and serve hot."
            ],
            notes: "For best results, freeze the flank steak for 45-60 minutes before slicing for easier handling. If using dried rice noodles, soak them in warm water according to package instructions before cooking. Customize with extra vegetables or adjust sauce levels for a richer flavor."
        )
        saveRecipe(
            name: "Beef in Black Bean",
            prepTime: "10 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "500 g Beef steak (ribeye, sirloin, rump, chuck, etc.), cut into thin slices",
                "0.83 Green pepper (bell pepper/capsicum), cut into small squares",
                "0.83 Red pepper (bell pepper/capsicum), cut into small squares",
                "1.67 Onion, cut into small cubes",
                "2.5 tbsp Garlic, finely chopped",
                "1.67 tsp Ginger paste or finely grated",
                "1.67 tbsp Black bean (fermented black beans or black bean sauce)",
                "3.33 tbsp Oil (vegetable, sunflower, canola, or neutral flavour oil)"
            ],
            prePrepInstructions: [
                "Cut the beef steak into thin slices against the grain.",
                "Marinate the beef with 1.67 tbsp light soy sauce, 1.67 tbsp sugar, 1.67 tbsp Shao Xing wine (optional), 1.67 tsp corn starch, and 0.83 tsp baking soda. Mix well and let sit for 10-15 minutes.",
                "Mix all the stir fry sauce ingredients (5 tbsp oyster sauce, 1.67 tsp dark soy sauce, 5 tbsp water, 0.83 tsp corn starch, 3.33 tsp Shao Xing wine, and 3.33 tsp sugar) in a small bowl and set aside.",
                "Roughly chop the black beans or leave them whole if preferred."
            ],
            instructions: [
                "Heat a wok or pan over medium-high heat and drizzle in oil. Add the marinated beef slices.",
                "Flatten the beef and sear for 2-3 minutes, then flip and stir fry for another 2-3 minutes.",
                "Add the diced onions and stir fry for 1 minute, then add the bell peppers and stir for a few seconds. Remove from the pan and set aside.",
                "In the same pan, drizzle a bit more oil. Sauté the chopped garlic over medium heat for 1 minute.",
                "Add the ginger and stir for a few seconds. Then add the black beans and stir fry for 1-2 minutes.",
                "Pour in the sauce mixture and stir until the sauce thickens.",
                "Add the fried beef, onions, and peppers back into the pan. Toss well over medium-high heat to combine evenly for 1-2 minutes.",
                "Remove from heat and transfer to a serving plate. Serve hot with plain rice, egg fried rice, or noodles."
            ],
            notes: "Fermented Chinese black soybeans (black beans) have a salty, savory, umami flavor. Substitute with black bean garlic sauce if needed. Shao Xing wine can be replaced with dry sherry or Japanese mirin, or omitted for a non-alcoholic version."
        )
        saveRecipe(
            name: "Beef Lo Mein (Easy)",
            prepTime: "23 mins",
            cookingTime: "7 mins",
            ingredients: [
                "400 g fresh lo mein noodles or substitute with thick wheat noodles like udon",
                "225 g flank steak *See notes for substitutes",
                "60 ml water to cook veggies",
                "15 ml vegetable oil or any neutral oil for frying",
                "120 g cabbage, thinly sliced",
                "40 g carrot, julienned",
                "75 g bell pepper, julienned",
                "4 green onions, chopped into 1.5-inch-long pieces",
                "Beef Marinade:",
                "7.5 ml regular soy sauce",
                "7.5 ml Shaoxing Wine -> Sub with Chicken broth",
                "4 g cornstarch",
                "1 g baking soda",
                "15 ml vegetable oil or any neutral oil",
                "Sauce:",
                "3 cloves garlic, minced",
                "22 ml regular soy sauce",
                "15 ml dark soy sauce",
                "15 ml oyster sauce",
                "10 ml sesame oil, toasted",
                "5 ml white granulated sugar or brown sugar",
                "2 g cornstarch",
                "60 ml chicken stock unsalted (or substitute with beef stock or vegetable stock)"
            ],
            prePrepInstructions: [
                "Thinly slice flank steak against the grain into ¼-inch-thick pieces.",
                "Add marinade ingredients to sliced beef and mix well. Set aside to marinate for 15 minutes at room temperature.",
                "To thinly slice beef, freeze it for 45-60 minutes until the exterior is hardened, then slice with a sharp knife.",
                "In a small bowl, combine Sauce ingredients as listed above and set aside."
            ],
            instructions: [
                "Bring a large wok or pot of water to a boil. Blanch fresh egg noodles in boiling water for 20-30 seconds until loosened.",
                "Strain noodles, rinse under cold running water, and remove excess water. Set aside.",
                "Heat 1 tablespoon vegetable oil in a large pan over medium-high heat. Fry marinated beef until cooked. Remove and set aside.",
                "Add carrots, red bell pepper, cabbage, and ¼ cup water to the pan. Cook for 30-60 seconds until vegetables are vibrant.",
                "Add blanched noodles to the pan followed by the prepared sauce mixture. Toss until noodles are evenly coated, and the sauce thickens slightly.",
                "Return cooked beef and add green onions. Toss everything together until well combined. Remove from heat and serve immediately."
            ],
            notes: "A quick and flavorful noodle dish that pairs perfectly with a variety of vegetables. Recipe adapted from a classic Chinese dish. For more details, visit: https://khinskitchen.com/beef-black-bean-sauce/"
        )
        saveRecipe(
            name: "Beef Ragu Sauce (Classic)",
            prepTime: "15 mins",
            cookingTime: "3 hrs",
            ingredients: [
                "1 lb stewing beef",
                "2 Tablespoons extra virgin olive oil",
                "1/3 cup onions, diced",
                "1/3 cup carrots, diced (about 1/4-inch dice)",
                "1/4 teaspoon crushed red chili pepper flakes",
                "4 cloves garlic, roughly chopped",
                "2 Tablespoons tomato paste",
                "1/2 cup red wine",
                "28 oz whole canned tomatoes (San Marzano recommended)",
                "1 cup beef broth",
                "2 Tablespoons salted butter",
                "1/2 teaspoon dried rosemary",
                "1/2 teaspoon dried thyme",
                "1/2 teaspoon dried oregano",
                "1/2 teaspoon dried basil (or about 6 torn fresh basil leaves)",
                "1/4 teaspoon salt",
                "1 bay leaf",
                "To finish:",
                "1 teaspoon red wine vinegar or balsamic vinegar",
                "Salt and pepper, as needed",
                "To serve:",
                "Pappardelle, tagliatelle, or fettucine pasta (or polenta)",
                "Freshly grated Parmesan cheese",
                "Torn fresh basil leaves for garnish"
            ],
            prePrepInstructions: [
                "Pat the beef cubes dry and season with salt and freshly ground pepper.",
                "Prepare the vegetables: dice onions and carrots, chop garlic, and measure out the remaining ingredients.",
                "Set aside pasta or polenta for serving."
            ],
            instructions: [
                "Heat olive oil in a large heavy-bottomed pot over medium-high heat. Brown the beef in small batches to develop flavor, then remove and set aside.",
                "In the same pot, cook onions and carrots for 3-4 minutes until softened. Add red chili pepper flakes and garlic, cooking for another minute.",
                "Stir in tomato paste and cook for 30 seconds. Deglaze the pot with red wine and reduce by half, about 3 minutes.",
                "Add canned tomatoes (breaking them up slightly), beef broth, butter, herbs, and salt. Stir until the butter melts, then add the bay leaf and reserved beef.",
                "Bring to a boil, reduce to low heat, cover, and simmer for about 2 1/2 hours, stirring occasionally.",
                "Once the beef is fork-tender, remove the bay leaf and shred the beef using a potato masher.",
                "Add vinegar and simmer uncovered for an additional 30 minutes to thicken the sauce. Adjust seasoning with salt and pepper to taste.",
                "Cook pasta in salted water until al dente. Drain and toss with ragu. Let the pasta stand for a few minutes to meld with the sauce before serving.",
                "Garnish with Parmesan cheese and fresh basil."
            ],
            notes: "This hearty, flavorful sauce pairs perfectly with pasta or polenta. For more details, visit: https://www.seasonsandsuppers.ca/beef-ragu/"
        )
        saveRecipe(
            name: "Beef Stew with Potatoes",
            prepTime: "20 minutes",
            cookingTime: "2 hours",
            ingredients: [
                "2.5 lbs beef chuck roast, cut into 1-inch cubes",
                "Freshly ground black pepper",
                "2 tbsp olive oil",
                "4 large carrots, peeled and cut into 1-inch pieces",
                "3 stalks celery, cut into 1-inch pieces",
                "1 large onion, roughly chopped",
                "8 garlic cloves, roughly chopped",
                "4 tbsp vinegar (substitute for 1.5 cups red wine)",
                "2 tbsp flour",
                "4 cups beef broth",
                "1 tbsp sugar",
                "12 oz baby potatoes, peeled and cut into 1-inch pieces",
                "2 tbsp whole grain mustard",
                "Fresh parsley for garnish"
            ],
            prePrepInstructions: [
                "Trim and cut beef into cubes.",
                "Chop vegetables into specified sizes.",
                "Mix vinegar if using instead of red wine."
            ],
            instructions: [
                "Dry beef cubes and sprinkle with pepper.",
                "Heat oil in a Dutch oven and brown beef in batches. Set aside.",
                "Add a splash of broth to the pot to deglaze, then sauté carrots, celery, and onions for 5 minutes.",
                "Add garlic and stir for 1 minute. Add vinegar and reduce liquid by half.",
                "Whisk flour with broth and add to pot. Return beef and bring to a boil.",
                "Reduce heat, cover, and simmer for 2 hours, adding potatoes and mustard in the last 20 minutes.",
                "Season with salt and pepper to taste. Garnish with parsley and serve."
            ],
            notes: "Serve with rice or rustic bread."
        )
        saveRecipe(
            name: "Beef Stroganoff (Instant Pot)",
            prepTime: "15 minutes",
            cookingTime: "25 minutes",
            ingredients: [
                "2.5 lbs stew meat",
                "Salt and pepper to taste",
                "1.25 cups sliced mushrooms",
                "3.75 tsp minced garlic",
                "3.75 tbsp butter",
                "2.5 tbsp flour",
                "3.75 cups beef broth",
                "5 tbsp Worcestershire sauce",
                "12.5 oz egg noodles",
                "0.63 cup sour cream",
                "2.5 tbsp corn starch + 1/4 cup broth (optional)"
            ],
            prePrepInstructions: [
                "Slice mushrooms and mince garlic.",
                "Measure all ingredients and have them ready."
            ],
            instructions: [
                "Set Instant Pot to SAUTE mode and melt butter.",
                "Add garlic and mushrooms, then stir in flour.",
                "Add 3 cups of broth, Worcestershire sauce, and stew meat.",
                "Cover and pressure cook for 15 minutes, then do a quick release.",
                "Stir in egg noodles and pressure cook for another 3 minutes. Do another quick release.",
                "Stir in sour cream and adjust seasoning with salt and pepper."
            ],
            notes: "Serve over noodles, mashed potatoes, or rice."
        )
        saveRecipe(
            name: "Chinese Beef Tomato Stir-fry (Quick and Easy)",
            prepTime: "15 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "226 g flank steak",
                "2 large tomatoes, sliced into wedges",
                "1 small onion, diced",
                "2 green onions, chopped (optional)",
                "3.5 g ginger, thinly sliced",
                "1 clove garlic, minced",
                "60 ml ketchup",
                "12 g sugar",
                "15 ml vegetable oil"
            ],
            prePrepInstructions: [
                "Slice flank steak against the grain and marinate with soy sauce, cornstarch, baking soda, garlic powder, and water for 15 minutes.",
                "Slice tomatoes and onions.",
                "Mix cornstarch with cold water to prepare slurry."
            ],
            instructions: [
                "Heat oil in a wok and stir-fry marinated beef until 75% cooked.",
                "Add garlic, onions, ginger, and ketchup, and stir-fry until onions are softened.",
                "Add cornstarch slurry, followed by tomatoes. Simmer until sauce thickens.",
                "Garnish with green onions and serve."
            ],
            notes: "Pairs well with steamed rice."
        )
        saveRecipe(
            name: "Biang Biang Noodles",
            prepTime: "25 minutes",
            cookingTime: "5 minutes",
            ingredients: [
                "400 grams all-purpose flour",
                "200 grams water, room temperature",
                "8 grams salt",
                "Oil, as much as needed for greasing",
                "20 milliliters Chinese black vinegar (per serving)",
                "20 milliliters soy sauce (per serving)",
                "0.33 teaspoon granulated sugar (per serving)",
                "8 grams Chinese chili pepper flakes (per serving)",
                "0.67 teaspoon Sichuan peppercorn, grounded (per serving)",
                "10.67 grams garlic, minced (per serving)",
                "1.33 stalk green onion, thinly sliced (per serving)",
                "60 milliliters oil (per serving)",
                "1.33 head baby bok choy, quartered (optional, per serving)"
            ],
            prePrepInstructions: [
                "Mix flour and salt in a bowl. Add water slowly, kneading until a rough dough forms. Rest for 20–30 minutes.",
                "Knead the dough until smooth. Divide into 6 equal pieces, roll into slabs, and coat with oil. Cover and rest for 2 hours."
            ],
            instructions: [
                "Prepare black vinegar sauce by mixing vinegar, soy sauce, and sugar. Set aside.",
                "Pull the dough into long, thin noodles and tear in the middle to create strands.",
                "Cook noodles and bok choy in boiling water for 45–90 seconds.",
                "Arrange noodles in a bowl with sauce and toppings: chili flakes, garlic, Sichuan pepper, and green onion.",
                "Heat oil until smoking, pour over the toppings, and mix until combined. Serve immediately."
            ],
            notes: "Adjust spice level by modifying chili and Sichuan pepper amounts."
        )
        saveRecipe(
            name: "Black Sesame Lady Fingers",
            prepTime: "15 minutes",
            cookingTime: "12-15 minutes",
            ingredients: [
                "3 large eggs, separated",
                "100 g cane sugar",
                "100 g all-purpose flour",
                "1/2 tsp vanilla extract",
                "1/4 tsp salt",
                "25 g black sesame powder",
                "40 g cornstarch",
                "Powdered sugar (for dusting)",
                "Black sesame seeds (optional, for decoration)"
            ],
            prePrepInstructions: [
                "Preheat oven to 350°F and line a baking sheet with parchment paper.",
                "Prepare a piping bag with a suitable tip."
            ],
            instructions: [
                "Beat egg yolks with half the sugar, vanilla, and salt until pale and fluffy.",
                "In another bowl, beat egg whites to soft peaks. Gradually add remaining sugar and beat to stiff peaks.",
                "Fold egg whites into yolk mixture. Sift in flour, black sesame powder, and cornstarch. Gently fold to combine.",
                "Pipe 4-inch logs onto prepared baking sheet, dust with powdered sugar, and sprinkle with sesame seeds.",
                "Bake for 12–15 minutes until golden. Cool completely before storing."
            ],
            notes: "Pairs well with coffee or as a base for desserts like tiramisu."
        )
        saveRecipe(
            name: "Black Sesame Matcha Tiramisu",
            prepTime: "20 minutes",
            cookingTime: "20 minutes",
            ingredients: [
                "5-8 Black Sesame Lady Fingers",
                "60 g hot water",
                "2 g quality matcha",
                "150 g heavy cream",
                "15 g powdered sugar",
                "8 g black sesame powder",
                "Matcha (for dusting)"
            ],
            prePrepInstructions: [
                "Prepare Black Sesame Lady Fingers as per recipe.",
                "Mix matcha powder with hot water and set aside to cool.",
                "Whip heavy cream with powdered sugar and black sesame powder to stiff peaks. Transfer to a piping bag."
            ],
            instructions: [
                "Layer lady fingers soaked in matcha at the base of a dish.",
                "Pipe a layer of black sesame whipped cream on top. Repeat for a second layer of lady fingers and cream.",
                "Cover and refrigerate for at least 4 hours or overnight.",
                "Before serving, decorate with whipped cream and dust with matcha."
            ],
            notes: "Store leftovers in the fridge for up to 5 days."
        )
        saveRecipe(
            name: "Black Sesame Rugelach",
            prepTime: "2 hours 30 minutes (includes chilling time)",
            cookingTime: "20-25 minutes",
            ingredients: [
                "40 g cream cheese, chilled",
                "40 g unsalted butter, chilled",
                "45 g all-purpose flour",
                "1/8 tsp salt",
                "3-4 tbsp black sesame paste (homemade or store-bought) OR red bean paste (homemade or store-bought)",
                "1 egg + 1 tsp water (for egg wash)",
                "Coarse sugar (for sprinkling)"
            ],
            prePrepInstructions: [
                "Combine flour and salt in a mixing bowl. Cut cold butter and cream cheese into the mixture until a crumbly texture forms.",
                "Form the mixture into a dough ball, wrap in plastic, and chill for at least 2 hours.",
                "Roll out the dough into a thin disk, approximately 10 inches wide. Wrap and chill for at least 30 minutes."
            ],
            instructions: [
                "Spread black sesame or red bean paste evenly over the chilled dough.",
                "Cut the dough like a pizza into 12 triangles: first in half vertically, then horizontally to create 4 pieces, then each piece into thirds.",
                "Roll up each triangle from the wide edge (outer edge) to form rugelach shapes. Place on a plastic-lined plate and chill for at least 30 minutes.",
                "Preheat the oven to 350°F (175°C).",
                "Transfer rugelach to a lined baking sheet. Prepare the egg wash by beating 1 egg with 1 tsp water. Brush the tops of the cookies with egg wash and sprinkle generously with coarse sugar.",
                "Bake for 20–25 minutes or until golden brown."
            ],
            notes: "You can substitute black sesame paste with red bean paste for a different flavor. Ensure the dough is thoroughly chilled at each step to maintain its texture during baking."
        )
        saveRecipe(
            name: "Black Sesame Tangyuan With Plain Skins And Matcha Skins",
            prepTime: "2 hours",
            cookingTime: "15 minutes",
            ingredients: [
                "1 stick (1/2 cup) butter",
                "1 cup granulated sugar",
                "1 ½ cups finely ground black sesame seeds",
                "½ cup finely ground white sesame seeds",
                "1 ¾ cups glutinous rice flour (plain skins)",
                "¾ cups water (plain skins)",
                "1 ¾ cups glutinous rice flour (matcha skins)",
                "1 tbsp matcha powder (matcha skins)",
                "1 tbsp granulated sugar (optional, for matcha skins)",
                "¾ cups water (matcha skins)"
            ],
            prePrepInstructions: [
                "Heat butter until just melted, then stir in sugar and sesame seeds until incorporated. Chill until solidified (about 2 hours).",
                "Roll teaspoon-sized amounts of the sesame mixture into balls and freeze for 1 hour.",
                "For plain skins: Gradually mix water into rice flour, stirring, and knead into a smooth dough.",
                "For matcha skins: Mix rice flour, matcha, and sugar (if using), then add water gradually and knead into a smooth dough."
            ],
            instructions: [
                "Take a tablespoon-sized amount of dough and flatten into a thin disk.",
                "Place a frozen sesame ball in the center and wrap the dough around it, sealing the edges. Roll between your palms to form a smooth ball.",
                "Boil water in a pot. Add tangyuan and cook for 15 minutes, stirring occasionally to prevent sticking.",
                "Serve warm, optionally with sweet ginger syrup or osmanthus broth."
            ],
            notes: "Ensure the dough is smooth and pliable to avoid cracks during cooking. Use a mix of black and white sesame seeds for a balanced flavor."
        )
        saveRecipe(
            name: "Blueberry Cupcake with Streusel Topping",
            prepTime: "15 minutes",
            cookingTime: "35-40 minutes",
            ingredients: [
                "2 large eggs",
                "320g buttermilk (or yogurt, sour cream, or crème fraîche)",
                "70g vegetable oil",
                "70g melted butter",
                "275g plain flour",
                "135g caster sugar",
                "65g soft brown sugar",
                "1 ½ tsp baking powder",
                "Zest of ½ a lemon or orange (optional)",
                "150g frozen blueberries",
                "Streusel topping:",
                "30g melted butter",
                "45g plain flour",
                "¼ tsp cinnamon",
                "Pinch of salt",
                "2 tbsp Demerara sugar"
            ],
            prePrepInstructions: [
                "Prepare the streusel topping by mixing melted butter, plain flour, cinnamon, salt, and Demerara sugar in a bowl until crumbly.",
                "Set the streusel aside.",
                "Preheat the oven to 185°C (170°C fan assisted)."
            ],
            instructions: [
                "In a large bowl, whisk eggs, buttermilk, vegetable oil, and melted butter together.",
                "In a separate bowl, mix plain flour, caster sugar, soft brown sugar, baking powder, zest (if using), and blueberries.",
                "Fold the dry mixture into the wet ingredients until just combined. Avoid overmixing.",
                "Spoon the batter into cupcake cases, filling to the edges.",
                "Sprinkle streusel topping over the batter.",
                "Bake for 35-40 minutes or until a skewer inserted into the center comes out clean."
            ],
            notes: "Use approximately six blueberries per cupcake to avoid sogginess. Adjust baking time for smaller or larger cupcake sizes."
        )
        saveRecipe(
            name: "Brown Butter Chocolate Chip Cookies",
            prepTime: "1 hour (includes chilling time)",
            cookingTime: "18 minutes",
            ingredients: [
                "100g unsalted butter",
                "1 tsp instant coffee",
                "75g granulated sugar",
                "150g dark brown sugar",
                "1 egg",
                "1 tsp vanilla extract",
                "1 tsp kosher salt",
                "1/8 tsp cream of tartar",
                "1/4 tsp baking soda",
                "150g bread flour",
                "Chocolate chips or chunks",
                "Flaky salt (optional)"
            ],
            prePrepInstructions: [
                "Brown the butter over medium-high heat until golden and nutty. Stir in instant coffee and let cool.",
                "Combine granulated sugar, dark brown sugar, egg, and vanilla with the cooled butter and mix until glossy."
            ],
            instructions: [
                "Combine dry ingredients: bread flour, salt, cream of tartar, and baking soda.",
                "Fold dry ingredients and chocolate chips into the butter mixture until evenly combined.",
                "Form dough into balls and chill for at least overnight or up to three days.",
                "Preheat oven to 325°F. Bake cookies on a parchment-lined baking sheet for 18 minutes.",
                "Sprinkle with flaky salt after baking, if desired."
            ],
            notes: "Chilling the dough minimizes spreading and enhances flavor. Store baked cookies in an airtight container for up to a week."
        )
        saveRecipe(
            name: "Best Ever Classic Chocolate Brownies",
            prepTime: "15 minutes",
            cookingTime: "25-30 minutes",
            ingredients: [
                "100g butter, chopped",
                "200g dark chocolate, chopped",
                "4 eggs",
                "250g golden caster sugar (for fudgy texture) or 200g (for cakey texture)",
                "100g plain flour",
                "1 tsp baking powder",
                "30g cocoa powder",
                "Optional: 100g white/milk chocolate chunks, toasted nuts, or marshmallows"
            ],
            prePrepInstructions: [
                "Preheat oven to 180°C (160°C fan/gas mark 4). Line a 22cm square tin with parchment.",
                "Melt butter and chocolate together, then cool to room temperature."
            ],
            instructions: [
                "Whisk eggs and sugar until light and fluffy.",
                "Fold in melted chocolate mixture.",
                "Sift in plain flour, baking powder, and cocoa powder. Fold to combine.",
                "Add optional mix-ins like chocolate chunks, nuts, or marshmallows, if desired.",
                "Pour batter into the prepared tin and bake for 25-30 minutes, or until the top is cracked but the center is just set.",
                "Cool completely before slicing."
            ],
            notes: "Adjust sugar quantity for desired fudginess. For a richer flavor, use high-quality dark chocolate."
        )
        saveRecipe(
            name: "Brown Sugar Boba Matcha Latte",
            prepTime: "25 minutes",
            cookingTime: "20 minutes",
            ingredients: [
                "⅓ cup bobas",
                "¼ cup brown sugar",
                "¼ cup cold water",
                "2 teaspoons matcha powder",
                "½ cup hot boiling water",
                "¼ cup milk of choice",
                "Ice cubes as much as needed"
            ],
            prePrepInstructions: [
                "Prepare the bobas by boiling them for 25 minutes uncovered over medium flame, stirring occasionally.",
                "After boiling, turn off the heat and allow the bobas to sit in the pot of water for another 20 minutes, covered.",
                "Strain the bobas and rinse them with cold water to retain their bounciness."
            ],
            instructions: [
                "In a small pot, combine brown sugar and ¼ cup cold water. Bring to a boil and simmer over medium heat until it becomes a thick syrup. Remove from heat and cover to keep warm.",
                "In a large measuring cup, whisk together matcha powder and ½ cup hot boiling water until smooth.",
                "Spoon the cooked bobas into the base of a glass.",
                "Drizzle the brown sugar syrup along the walls of the glass for a decorative effect.",
                "Fill the glass with ice as much as desired.",
                "Pour the matcha tea into the glass, followed by the milk of your choice.",
                "Stir gently and enjoy your homemade brown sugar boba matcha latte!"
            ],
            notes: "For best results, use fresh, high-quality matcha powder and adjust the sweetness by adding more or less brown sugar syrup. Serve immediately for the freshest taste."
        )
        saveRecipe(
            name: "Bulgur Pilaf",
            prepTime: "20 minutes",
            cookingTime: "15-20 minutes",
            ingredients: [
                "2 cups coarsely ground bulgur",
                "2 onions, diced",
                "1 small carrot, grated",
                "4 cloves of garlic, sliced",
                "2 tablespoons olive oil",
                "1 heaped tablespoon + 1 teaspoon butter",
                "2 tablespoons hot red pepper paste",
                "2 tablespoons tomato paste (or 200 ml tomato puree)",
                "400 g boiled chickpeas",
                "1 tablespoon dried mint",
                "1 teaspoon dried thyme (or oregano)",
                "1 teaspoon salt",
                "1 teaspoon black pepper",
                "1 teaspoon red chili flakes",
                "4 cups boiling water"
            ],
            prePrepInstructions: [
                "Prepare and dice the onions, grate the carrot, and slice the garlic.",
                "Boil the chickpeas if not using pre-cooked ones.",
                "Have boiling water ready to pour into the pilaf."
            ],
            instructions: [
                "Brown 1 tablespoon butter and olive oil in a pot over medium heat.",
                "Add the diced onions and sauté for a couple of minutes until softened.",
                "Stir in the garlic and continue sautéing for another minute.",
                "Add the tomato and pepper paste, mixing evenly with the onions and garlic.",
                "Add the bulgur, grated carrot, and chickpeas, stirring after each addition to combine.",
                "Season with dried mint, thyme, salt, black pepper, and red chili flakes.",
                "Pour in boiling water up to 2 cm above the level of the bulgur (approximately 4 cups, depending on the pan size).",
                "Add 1 teaspoon butter and simmer on low heat for 10-15 minutes until the bulgur is tender, leaving a little water at the bottom of the pan.",
                "Turn off the heat, cover the pot with a kitchen cloth, and let the pilaf rest for 10 minutes.",
                "Fluff the pilaf with a fork and serve with savory yogurt and pickles."
            ],
            notes: "Unlike rice pilaf, leaving some liquid at the bottom of the pan enhances the texture and flavor of the bulgur. Pair with yogurt and pickles for a complete meal."
        )
        saveRecipe(
            name: "Butter Chicken (Instant Pot - Quick & Easy)",
            prepTime: "20 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "1.02kg (2.25 lb) chicken tenderloin, thighs, or breast, cut into 1” cubes",
                "6.75 tbsp plain yogurt",
                "2.25-4.5 tbsp tandoori masala powder (adjust to spice preference)",
                "1.13-2.25 tsp lemon juice",
                "1.13 tsp salt",
                "4.5 tbsp ghee or butter",
                "2.25 tbsp neutral oil",
                "2.25 small to medium yellow onions",
                "11.25 garlic cloves",
                "1.13 inch piece ginger, roughly chopped",
                "6.75 medium ripe tomatoes or 1 8-oz can tomato sauce",
                "4.5 tsp tomato paste (optional)",
                "2.25 small Serrano pepper, chopped",
                "2.25 tsp kashmiri chili powder or paprika",
                "2.25 tsp cumin powder",
                "2.25 tsp coriander powder",
                "1.13 tsp turmeric",
                "0.56-1.13 tsp red chili powder or cayenne",
                "0.56 tsp black pepper powder",
                "2.25 tsp salt (or more to taste)",
                "0.56-1.13 tsp sugar (or more to taste)",
                "0.56 cup water",
                "2.25-4.5 tbsp butter, roughly chopped (after cooking)",
                "0.75 cup heavy whipping cream",
                "2.25 tsp dried fenugreek leaves (optional)",
                "0.56 tsp garam masala (optional)",
                "2.25-4.5 tbsp cilantro, chopped (for garnish)"
            ],
            prePrepInstructions: [
                "Combine chicken with yogurt, tandoori masala, lemon juice, and salt. Mix well and set aside to marinate.",
                "Place onion, garlic, and ginger in a food processor. Chop finely until garlic and ginger are properly minced.",
                "Blend tomatoes in the food processor until smooth, if using fresh tomatoes."
            ],
            instructions: [
                "Turn Instant Pot to sauté mode. Once hot, add ghee, oil, and the chopped onion mixture. Sauté until golden (8-10 minutes).",
                "Deglaze with 1-2 tablespoons of water if needed, ensuring the onions brown evenly.",
                "Add blended tomatoes, tomato paste (if using), Serrano pepper, spices, salt, and sugar. Sauté until the tomatoes break down and the mixture thickens (6-7 minutes).",
                "Add water and marinated chicken, mixing well to coat. Close the lid and pressure-cook on high for 8 minutes.",
                "Allow pressure to release naturally for 5-7 minutes, then manually release the remaining pressure.",
                "Select Sauté – More/High. Cook until the sauce reaches the desired consistency, then cancel Sauté.",
                "Stir in butter, heavy cream, and dried fenugreek leaves (if using). Adjust salt and sugar to taste.",
                "Garnish with garam masala and cilantro. Serve hot with naan or rice."
            ],
            notes: "You can substitute fresh tomatoes with 1 8-oz can of tomato sauce or tomato purée. Adjust salt if using canned products. For a milder flavor, reduce the amount of red chili powder."
        )
        saveRecipe(
            name: "Butter Cookies",
            prepTime: "1 hour 15 minutes (includes chilling time)",
            cookingTime: "12-15 minutes",
            ingredients: [
                "230g (1 cup) butter, softened",
                "85g (2/3 cup) powdered sugar, sifted",
                "250g (2 cups) plain flour"
            ],
            prePrepInstructions: [
                "Soften butter to room temperature before starting.",
                "Sift powdered sugar to remove lumps."
            ],
            instructions: [
                "Add softened butter cubes into a mixing bowl.",
                "Sieve in powdered sugar and beat until light and fluffy.",
                "Add half of the flour and mix until well combined.",
                "Add the remaining flour and mix until a smooth dough forms.",
                "Shape the dough into a disk, wrap in clingfilm, and refrigerate for 1 hour.",
                "Sprinkle flour onto a sheet of baking paper, place the dough on top, and sprinkle more flour.",
                "Roll out the dough to the desired thickness and cut out shapes using cookie cutters.",
                "Preheat the oven to 350°F (180°C or 160°C fan).",
                "Transfer the cookies to a baking tray lined with parchment paper.",
                "Bake for 12-15 minutes, or until slightly golden. Allow to cool completely."
            ],
            notes: "Ensure butter is softened but not melted. Use cookie cutters for uniform shapes. Adjust baking time slightly based on cookie thickness."
        )
        saveRecipe(
            name: "Cabbage Dolmas",
            prepTime: "15 minutes",
            cookingTime: "50 minutes",
            ingredients: [
                "12 large cabbage leaves",
                "1 tablespoon butter, ghee, or coconut oil",
                "1 pound beef stew meat",
                "1 medium white onion, chopped",
                "2 cinnamon sticks",
                "Fine sea salt and black pepper, to taste",
                "4 cups beef broth",
                "1/4 cup chopped fresh cilantro (for garnish)",
                "For the Stuffing:",
                "1 pound ground beef",
                "1/4 cup chopped fresh parsley",
                "2 teaspoons ground cumin",
                "2 tablespoons ground cinnamon"
            ],
            prePrepInstructions: [
                "Steam cabbage leaves for 3 to 5 minutes until softened. Set aside.",
                "Chop onion and parsley for the stuffing and broth mixture."
            ],
            instructions: [
                "In a large sauté pan, melt the butter or oil over medium heat. Brown the stew meat on all sides, about 5 minutes.",
                "Add the chopped onion, cinnamon sticks, and a pinch of salt and pepper. Cook for 3 minutes until onion is translucent.",
                "Pour in beef broth, bring to a boil, then simmer uncovered for 30 minutes.",
                "While the stew meat cooks, combine the stuffing ingredients (ground beef, parsley, cumin, and cinnamon) in a large bowl.",
                "Place 1/4 cup of the stuffing mixture onto a steamed cabbage leaf. Roll halfway, tuck in the sides, and finish rolling. Place seam-side down on a plate.",
                "Repeat until all stuffing is used.",
                "Using tongs, add the cabbage rolls to the sauté pan. Cover and simmer for 15-20 minutes.",
                "Remove the cinnamon sticks, garnish with fresh cilantro, and serve warm."
            ],
            notes: "For a richer flavor, use ghee for sautéing. Adjust seasoning of the stuffing to taste before rolling. Serve with a side of yogurt or fresh salad."
        )
        saveRecipe(
            name: "Carrot Ginger Lentil Soup (Instant Pot or Stovetop)",
            prepTime: "45 minutes",
            cookingTime: "6 minutes (plus pressure release time)",
            ingredients: [
                "454g (1 pound) carrots, rinsed, patted dry, and cut into large chunks (about 6 medium carrots)",
                "1 medium onion, diced",
                "192g (1 cup) red lentils, rinsed",
                "1-inch piece of fresh ginger, skin removed and minced",
                "1 teaspoon curry powder",
                "1 liter (4 cups) reduced-sodium vegetable broth",
                "125ml (1/2 cup) full-fat canned coconut milk",
                "1 lemon, juiced"
            ],
            prePrepInstructions: [
                "Rinse and pat dry carrots. Cut into large chunks.",
                "Dice the onion and rinse the red lentils.",
                "Peel and mince the ginger."
            ],
            instructions: [
                "Combine carrots, onion, lentils, ginger, curry powder, and vegetable broth in the base of a 6-quart or 8-quart Instant Pot pressure cooker.",
                "Lock on the lid and set the timer to 6 minutes at high pressure.",
                "Once cooking is complete, allow the pressure to release naturally for about 10 minutes.",
                "Carefully remove the lid and stir in the coconut milk and lemon juice.",
                "Use a hand-immersion blender to blend the soup until smooth.",
                "Serve the soup hot."
            ],
            notes: "For stovetop cooking, combine all ingredients except coconut milk and lemon juice in a large pot. Bring to a boil, then reduce heat to simmer for 25-30 minutes, until the lentils are soft. Stir in coconut milk and lemon juice, then blend until smooth."
        )
        saveRecipe(
            name: "Authentic Pakistani Chai",
            prepTime: "10 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "1 1/4 cups water",
                "1 cup whole milk or 2% reduced-fat milk (use whole milk for creamier chai)",
                "1 1/2 tsp loose tea leaves (e.g., Tapal Danedar or Ahmad Tea) or 2 black tea bags, or more to taste",
                "1-2 cardamom pods, slightly broken, or a pinch of cardamom powder (optional)",
                "Sweetener, to taste (sugar or honey)"
            ],
            prePrepInstructions: [
                "Slightly break the cardamom pods if using.",
                "Prepare a small strainer for pouring the chai."
            ],
            instructions: [
                "Place water in a saucepan over high heat. Once boiling, add tea leaves or tea bags and cardamom. Reduce the heat to medium and simmer for 1-2 minutes.",
                "Add the milk and raise the heat back to high, allowing the milk to simmer on its own or bring to a boil.",
                "As the chai rises in the saucepan, remove from heat before it overflows. Repeat this process a few times to develop the flavor. Alternatively, lower the heat and simmer for 3-5 minutes to desired strength.",
                "Strain the chai into cups using a small sieve.",
                "Sweeten with sugar or honey to taste."
            ],
            notes: "Adjust the ratio of milk to water for a thinner or creamier chai. For a more robust flavor, allow the chai to simmer longer. Serve hot for the best experience."
        )
        saveRecipe(
            name: "Homemade Chai Concentrate",
            prepTime: "5 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "5 cups water",
                "10 black tea bags",
                "10 cardamom pods",
                "10 whole cloves",
                "1 tablespoon fennel seeds",
                "3-inch piece ginger, cut into pieces"
            ],
            prePrepInstructions: [
                "Lightly crush the cardamom pods and cloves using a mortar and pestle.",
                "Prepare a large saucepan for boiling and a strainer for filtering the chai concentrate."
            ],
            instructions: [
                "Add the ginger, crushed spices, and water to a large saucepan. Bring to a full boil.",
                "Boil for 3-4 minutes, then add the tea bags and reduce the heat to low-medium.",
                "Cover the saucepan and let it simmer for 10-15 minutes.",
                "Strain the chai concentrate into a mason jar or glass container.",
                "Store in the fridge and use within a week. For a cup of chai, mix the concentrate with hot water and steamed milk to taste."
            ],
            notes: "This concentrate can be frozen into cubes for longer storage. After boiling, expect 3-4 cups of concentrate. Customize your chai by adjusting the ratio of concentrate, water, and milk."
        )
        saveRecipe(
            name: "Chai Tea Financiers",
            prepTime: "10 minutes",
            cookingTime: "12 minutes",
            ingredients: [
                "150 g unsalted butter",
                "125 g cane sugar",
                "1 chai tea bag (or any tea of choice)",
                "140 g egg whites",
                "30 g honey",
                "60 g all-purpose flour",
                "100 g almond flour"
            ],
            prePrepInstructions: [
                "Brown the butter in a saucepan. Once browned, cut open the chai tea bag and steep the tea in the butter. Set aside to cool completely.",
                "Prepare a baking dish or mold for financiers by greasing or lining as needed."
            ],
            instructions: [
                "Mix together egg whites, cane sugar, and honey in a mixing bowl.",
                "Add the almond flour and all-purpose flour to the mixture and stir to combine.",
                "Gradually pour the cooled melted butter into the batter while mixing until fully incorporated.",
                "Preheat the oven to 375°F (190°C).",
                "Pour the batter into the prepared molds, filling each about 2/3 full.",
                "Bake for 10-15 minutes or until the financiers are golden brown around the edges.",
                "Allow to cool before serving."
            ],
            notes: "This recipe is adapted from 'Dishes from my kitchen.' You can substitute the chai tea bag with another tea of your choice for a different flavor profile."
        )
        saveRecipe(
            name: "Instant Pot Chana Dal",
            prepTime: "30 minutes (including soaking time)",
            cookingTime: "12-15 minutes (pressure cooking)",
            ingredients: [
                "1 cup Split Chickpeas (Chana Dal), 6.7 ounces",
                "2 cups Water, for soaking",
                "1 tablespoon Oil",
                "1 teaspoon Cumin seeds (Jeera)",
                "1/4 teaspoon Asafoetida (Hing), optional (skip for gluten-free)",
                "3/4 cup Onion, diced",
                "1/2 tablespoon Ginger, minced",
                "3 cloves Garlic, minced",
                "3/4 cup Tomato, chopped",
                "2 cups Water, for cooking (increase to 2.5 cups if not soaking)",
                "1 tablespoon Lime juice",
                "Cilantro, for garnish",
                "Spices:",
                "1 teaspoon Salt",
                "1/4 teaspoon Ground Turmeric (Haldi powder)",
                "1/2 teaspoon Red Chili powder (Mirchi powder)",
                "1 teaspoon Coriander powder (Dhaniya powder)"
            ],
            prePrepInstructions: [
                "Soak Chana Dal in 2 cups of water for 30 minutes. Then drain the soaking water."
            ],
            instructions: [
                "Start the Instant Pot in sauté mode and heat oil. Add cumin seeds and asafoetida.",
                "Once the cumin seeds change color, add diced onions, garlic, and ginger. Sauté for 2 minutes.",
                "Add chopped tomatoes and spices, stirring well.",
                "Add the soaked chana dal and 2 cups of water for cooking. Stir to combine.",
                "Cancel sauté mode, close the lid, and set the Instant Pot to manual or pressure cook mode at high pressure for 12 minutes (15 minutes if skipping soaking).",
                "Once cooking is complete, let the pressure release naturally.",
                "Open the lid, add lime juice, and stir well.",
                "Garnish with cilantro and serve over rice."
            ],
            notes: "To make this recipe vegan, avoid using ghee. For a gluten-free variation, use gluten-free asafoetida or skip it. Adding spinach after pressure cooking can make a delicious variation. If doubling the recipe, ensure the pot is not more than half full due to foaming."
        )
        saveRecipe(
            name: "Chana Dal (Instant Pot Pakistani)",
            prepTime: "10 minutes",
            cookingTime: "25 minutes (pressure cooking) + 10 minutes (tadka)",
            ingredients: [
                "To Pressure Cook:",
                "1.5 cups (320-330 g) chana dal (yellow split chickpeas), rinsed and drained",
                "4 cups water",
                "2 small to medium tomatoes (~150-170 g), finely chopped",
                "2 tsp kosher salt, or to taste",
                "1 tsp coriander powder",
                "0.5 tsp turmeric powder",
                "0.5 tsp cumin powder",
                "0.5 tsp red chili powder, or more to taste",
                "0.25 tsp ground black pepper",
                "For the Tadka (Tempering):",
                "4 tbsp ghee (or sub butter)",
                "2 tbsp oil",
                "2 tsp cumin seeds",
                "2 small yellow onions (~200 g), thinly sliced",
                "6 garlic cloves, crushed or finely chopped",
                "2 small green chili peppers (or sub 4-5 whole red chili peppers), chopped",
                "For Garnishing:",
                "0.5 tsp garam masala",
                "0.5 tsp freshly squeezed lemon juice",
                "1 inch ginger, julienned",
                "4 tbsp cilantro leaves, chopped"
            ],
            prePrepInstructions: [
                "Rinse and drain chana dal several times to remove excess starch.",
                "Prepare all ingredients by chopping the tomatoes, onions, garlic, and green chili peppers."
            ],
            instructions: [
                "Add all 'To Pressure Cook' ingredients to the Instant Pot and mix to combine.",
                "Secure the lid and set the valve to Sealing. Select Manual/Pressure Cook on High Pressure and set the time to 22 minutes (adjust if dal is pre-soaked or older).",
                "Once the cooking time is complete, allow pressure to release naturally for 5 minutes, then manually release any remaining pressure.",
                "For the tadka, heat oil and ghee in a sauté pan over medium-high heat. Add cumin seeds and allow them to sizzle for a few seconds.",
                "Add sliced onions to the pan and sauté until golden brown (~5-6 minutes).",
                "Add garlic to the pan and sauté until the raw smell disappears (~1 minute). Add green chili peppers and sauté for another minute.",
                "Select Sauté mode on the Instant Pot (set to Less) to warm the dal.",
                "Transfer the prepared tadka to the dal in the Instant Pot. Simmer on low Sauté for 3-4 minutes, mashing some of the dal against the sides of the pot for texture.",
                "Cancel Sauté mode, taste, and adjust salt if needed. Stir in garam masala and lemon juice.",
                "Garnish with chopped cilantro and julienned ginger. Serve hot with achaar and kachumber salad."
            ],
            notes: "Pre-soaking chana dal reduces cooking time. Adjust pressure cook timing based on the type and age of dal. If dal remains tough after 22 minutes, pressure cook for an additional 3-4 minutes. For a vegan version, use oil instead of ghee. Serve with naan, rice, or your favorite side dishes."
        )
        saveRecipe(
            name: "Chapati",
            prepTime: "15 minutes",
            cookingTime: "1 minute per chapati",
            ingredients: [
                "2 cups whole wheat flour or drum-wheat 'Atta'",
                "1 teaspoon salt",
                "1 cup lukewarm water",
                "2 tablespoons wheat flour, for rolling and dusting"
            ],
            prePrepInstructions: [
                "Sieve the whole wheat flour to remove any lumps.",
                "Add salt to the sieved flour and mix well.",
                "Gradually add 3/4 cup lukewarm water to the flour, stirring gently until the dough starts to gather.",
                "Adjust the water or flour as needed to achieve a soft and pliable dough.",
                "Knead the dough for 5-7 minutes until smooth. Apply a little oil to your hands to help with kneading.",
                "Cover the dough with plastic wrap and let it rest at room temperature for at least 1 hour. If storing in the refrigerator, bring the dough back to room temperature before use."
            ],
            instructions: [
                "Heat a griddle over medium-high heat.",
                "Divide the dough into 10-12 equal-sized balls.",
                "Lightly dust a flat surface with flour and roll each dough ball into a 6-7 inch disc.",
                "Place the chapati on the hot griddle and cook for about 30 seconds, or until tiny golden dots appear on the surface.",
                "Flip the chapati and cook the other side for another 30 seconds.",
                "Flip again and gently press with a folded kitchen towel to encourage puffing. Alternatively, you can puff the chapati directly over an open flame.",
                "Transfer the cooked chapati to a serving platter. Optionally, baste with butter or ghee for added flavor.",
                "Serve immediately."
            ],
            notes: "Perfectly puffed chapatis may take some practice but will still taste delicious even if they don't puff up completely. Direct flame puffing can enhance the texture. Best served fresh and warm."
        )
        saveRecipe(
            name: "Char Kway Teow (Quick & Easy Malaysian)",
            prepTime: "10 minutes",
            cookingTime: "20 minutes",
            ingredients: [
                "907.2 g fresh rice noodles (or substitute with dried rice noodles)",
                "226 g pork belly, diced (or substitute with chicken, beef, shrimp, or tofu)",
                "2.5 cups bean sprouts, rinsed under cold water",
                "2 cups garlic chives, chopped",
                "2 eggs",
                "4 cloves garlic, minced",
                "2-3 tsp chili garlic sauce (optional)",
                "1 tsp vegetable oil or any neutral oil",
                "2 tbsp dark soy sauce (adjust for saltiness)",
                "1 tbsp sweet soy sauce (Kecap Manis or substitute with dark soy sauce + 1 tsp sugar)",
                "3 tbsp oyster sauce"
            ],
            prePrepInstructions: [
                "If using fresh rice noodles, microwave in intervals of 2-3 minutes until warm and pliable. Allow to cool slightly, then gently peel them apart. Repeat if necessary.",
                "If using dried rice noodles, soak in hot boiling water for 1 minute until firm but limp. Strain immediately.",
                "Combine noodle sauce ingredients (dark soy sauce, sweet soy sauce, and oyster sauce) in a small bowl and set aside."
            ],
            instructions: [
                "Heat a large pan on medium-high heat. Add vegetable oil, pork belly, and garlic. Fry until the pork is crispy brown, about 5-7 minutes.",
                "Reduce heat to medium. Add strained noodles and gently toss to allow the noodles to absorb the oil for flavor.",
                "Toss in garlic chives and bean sprouts, mixing well.",
                "Push the ingredients to one side of the pan. Crack the eggs into the empty side and scramble them until fully cooked. Toss scrambled eggs with the noodles.",
                "Pour the prepared noodle sauce over the noodles and gently toss everything together until the noodles are well coated.",
                "If desired, add chili garlic sauce for extra heat. Use two spatulas to help toss the noodles to avoid breaking them.",
                "Serve hot with additional chili sauce as desired."
            ],
            notes: "Microwaving fresh rice noodles helps separate them without breaking. For dried rice noodles, avoid over-soaking to maintain their firmness. Adjust the sweetness or saltiness of the sauce to your preference by modifying the soy sauce quantities."
        )
        saveRecipe(
            name: "Cheung Fun (Rice Noodle Rolls)",
            prepTime: "10 minutes",
            cookingTime: "20 minutes",
            ingredients: [
                "20 ml vegetable oil or any neutral oil",
                "162 g rice flour (not glutinous)",
                "8 g glutinous rice flour (or substitute with cornstarch, tapioca starch, or potato starch)",
                "1.5 g salt",
                "500 ml cold water",
                "45 ml sweet soy sauce or dark soy sauce mixed with 2 tsp white sugar",
                "1 scallion, finely chopped",
                "2 g sesame seeds"
            ],
            prePrepInstructions: [
                "In a large bowl or measuring cup with a spout, whisk together rice flour, glutinous rice flour, and salt until well combined.",
                "Gradually pour in cold water, whisking continuously to create a smooth batter. Set aside.",
                "Prepare a large wok filled one-third of the way with water. Place a wire rack or bamboo steamer on top of the water and ensure it is perfectly leveled to avoid uneven batter pooling.",
                "Brush a 10 x 8-inch baking tray with 1 teaspoon vegetable oil and place it on the wire rack or bamboo steamer. Bring the water to a boil over medium-high heat."
            ],
            instructions: [
                "Stir the batter again to ensure it is well mixed. Pour ½ cup (approximately 250 ml) of batter into the center of the prepared tray to create a thin layer.",
                "Cover the wok with a lid and steam for 4 minutes until large bubbles form under the rice noodle sheet. Do not open the lid during this process.",
                "Turn off the heat and remove the lid. Use two spatulas or a dough cutter to lift the edge of the rice noodle sheet and roll it away from you into a 1-inch-thick roll.",
                "Slice the roll in half using a thin spatula or dough cutter and transfer to a serving plate.",
                "Repeat the process until all batter is used, creating 4 rolls in total.",
                "Garnish the rice noodle rolls with sweet soy sauce, chopped scallions, and sesame seeds. Serve and enjoy!"
            ],
            notes: "Ensure the wok or steamer is perfectly level to create evenly cooked rice noodle sheets. Stir the batter each time before pouring to avoid settling of the flour. Adjust sweet soy sauce to your taste by modifying sugar levels."
        )
        saveRecipe(
            name: "Chicken 65 (Saucy, Fiery, Irresistible!)",
            prepTime: "15 minutes",
            cookingTime: "30 minutes",
            ingredients: [
                "1 lb (454 g) boneless chicken breast, cut into ¾-1 inch cubes (or chicken thighs, see notes)",
                "1-1 ½ tsp red chili powder or Kashmiri chili powder",
                "1 tsp freshly ground black pepper",
                "1 1/2 tsp sea salt",
                "1/4 tsp baking soda",
                "1 small egg, whisked",
                "¼ cup + 1 tbsp (40 g) cornstarch",
                "2 tbsp (18 g) all-purpose flour",
                "1 tbsp water, if needed",
                "Neutral oil for frying",
                "1/4 cup water (for food color prep)",
                "1/8 tsp red or deep orange food color powder",
                "1/4 cup neutral oil (for tarka)",
                "1 1/2 tsp cumin seeds",
                "2 garlic cloves, thinly sliced",
                "2-3 small mild green chili peppers (or Serrano), stemmed and halved",
                "5 whole dried red chili peppers",
                "1 tsp garlic paste",
                "1 tsp ginger paste",
                "3 sprigs (6 g) fresh curry leaves",
                "1/3 cup (90 g) South Asian-style chili garlic sauce (e.g., National or Mitchell's)",
                "1/3 cup (82 g) plain whole milk yogurt, whisked",
                "1/8 heaping tsp sea salt",
                "Lemon wedges for serving (optional)"
            ],
            prePrepInstructions: [
                "Rinse chicken cubes under cold water and pat dry.",
                "In a medium bowl, toss chicken with red chili powder, black pepper, salt, and baking soda.",
                "Mix in the whisked egg to coat chicken, followed by cornstarch and all-purpose flour. Add water if the mixture feels clumpy.",
                "Mix water with food color in a small bowl for later use. Set aside."
            ],
            instructions: [
                "Heat a large frying pan with neutral oil, about ½ inch deep, over medium-high heat to 325-350°F (113-175°C).",
                "Fry chicken pieces in batches, turning often, until crispy and golden brown, about 4-5 minutes. Remove and drain on a wire rack or paper towels.",
                "For the tarka, heat oil in a large pan over medium heat. Add cumin seeds, sliced garlic, green chili peppers, and dried red chilies. Sauté for 2 minutes.",
                "Deglaze the pan with 2 tbsp water and let it evaporate.",
                "Add garlic paste, ginger paste, and curry leaves. Sauté until aromatic, about 2 minutes.",
                "Add chili garlic sauce, whisked yogurt, and salt. Simmer on medium-high heat for 4-5 minutes until thickened.",
                "Pour in the prepared food color water and simmer for 2 more minutes.",
                "Add fried chicken to the sauce and toss to coat. Simmer for 1-2 minutes until the sauce thickens.",
                "Serve hot with basmati rice or as an appetizer. Garnish with lemon wedges, if desired."
            ],
            notes: "Use South Asian-style chili garlic sauce for authentic flavor. Air frying is an alternative method; instructions are in the recipe. Chicken thighs can replace breast, and baking soda may be omitted in that case."
        )
        saveRecipe(
            name: "Chicken & Chickpea Curry",
            prepTime: "15 minutes",
            cookingTime: "45 minutes",
            ingredients: [
                "1/3 cup oil",
                "600 grams (2 chicken breast fillets), cubed into medium pieces",
                "2 cans pre-cooked chickpeas, drained",
                "2 medium onions, blitzed",
                "1 can chopped tinned tomatoes, pureed",
                "Jug of water",
                "2 teaspoons each: salt, chili powder, coriander powder, garam masala, cumin seeds, and dried fenugreek leaves",
                "1 teaspoon turmeric",
                "1 teaspoon Kashmiri chili powder",
                "1 cinnamon stick",
                "3 bay leaves",
                "2 black cardamom pods",
                "1 piece each of frozen ginger and garlic (or fresh, minced)",
                "3 green chilies, sliced halfway up",
                "Fresh coriander for garnish (optional)"
            ],
            prePrepInstructions: [
                "Blitz the onions in a food processor until finely pureed.",
                "Puree the chopped tinned tomatoes in a jug or blender.",
                "Cube the chicken breast fillets into medium-sized pieces."
            ],
            instructions: [
                "Heat oil in a large pan over medium heat.",
                "Add cinnamon stick, bay leaves, and black cardamom pods to the oil. Sauté for 1-2 minutes until aromatic.",
                "Stir in the blitzed onions and cook until golden brown, stirring occasionally.",
                "Add the frozen ginger and garlic pieces (or minced), and cook for 1-2 minutes until fragrant.",
                "Add the pureed tomatoes, salt, chili powder, coriander powder, garam masala, cumin seeds, turmeric, and Kashmiri chili powder. Mix well and cook for 5-7 minutes.",
                "Add the cubed chicken pieces and stir to coat in the masala. Cook for 5-7 minutes until the chicken is no longer pink.",
                "Stir in the drained chickpeas and a jug of water (adjust for desired consistency). Bring to a boil, then reduce to a simmer and cook for 20-25 minutes.",
                "Add dried fenugreek leaves and green chilies. Simmer for another 5 minutes.",
                "Garnish with fresh coriander, if desired, and serve hot with rice or naan."
            ],
            notes: "This curry is a versatile dish with a rich flavor profile. Adjust the amount of green chilies for desired heat. Fresh coriander adds a vibrant finish but is optional."
        )
        saveRecipe(
            name: "Chicken Biryani (Instant Pot)",
            prepTime: "1 hour (plus marination time)",
            cookingTime: "1.5 hours",
            ingredients: [
                "1kg chicken drumsticks",
                "1.5 tsp turmeric",
                "1/2 tsp chili powder",
                "1 packet Laziza biryani mix",
                "1 pot full-fat yogurt (75% for marinade, 25% for raita)",
                "4.5 cups jasmine rice, cooked",
                "1 cup oil",
                "3 medium onions, sliced",
                "3 medium potatoes, cubed",
                "1/2 large cauliflower or 1 small cauliflower, chopped",
                "2 small carrots or 1 large carrot, chopped",
                "Bag of broad beans (or substitute with 1/2 broccoli, peas)",
                "1 cup coriander leaves (for garnish)",
                "8 chillies (for garnish)",
                "1 tbsp rose water",
                "1 tbsp kewra water"
            ],
            prePrepInstructions: [
                "Marinate chicken drumsticks with 7 tbsp yogurt, turmeric, and chili powder for 1 hour or overnight.",
                "Soak 4.5 cups jasmine rice in water.",
                "Cook rice in a rice cooker with minimal water (water level to 4.25 cups for 4.5 cups rice)."
            ],
            instructions: [
                "For Instant Pot: Set to sauté mode and heat 1 cup oil.",
                "Fry sliced onions until golden brown (12-24 minutes) and remove for garnishing.",
                "Fry marinated chicken in the onion oil with Laziza biryani mix for 3-4 minutes on high.",
                "Turn off sauté mode and pressure cook chicken with vegetables for 6-8 minutes on high with natural release.",
                "Boil potatoes separately in salted water (takes up to 40 minutes).",
                "For slow cooker: Add chicken curry to the bottom of the slow cooker and layer sauce, boiled potatoes, and cooked rice repeatedly.",
                "Top with mint, coriander, chillies, kewra water, and rose water.",
                "Cook on high for 1.5 hours, mixing halfway through at 45 minutes.",
                "Serve once chicken is fully cooked."
            ],
            notes: "This biryani pairs perfectly with raita. Adjust the spice level to taste by modifying the chili powder or green chillies."
        )
        saveRecipe(
            name: "Raita",
            prepTime: "10 minutes",
            cookingTime: "None",
            ingredients: [
                "1 large cucumber (or 2 medium), peeled, halved, seeded, and grated",
                "2 cups plain whole milk yogurt",
                "10 large mint leaves, thinly sliced (can substitute with cilantro)",
                "1/2 teaspoon ground cumin (toast whole seeds and grind if possible)",
                "Pinch of cayenne",
                "Pinch of paprika",
                "Salt and pepper to taste"
            ],
            prePrepInstructions: [
                "Grate cucumber and press out excess moisture using a sieve or tea towel.",
                "Toast cumin seeds (if using whole) until fragrant and grind."
            ],
            instructions: [
                "Mix yogurt with ground cumin, cayenne, paprika, salt, pepper, and mint in a medium bowl.",
                "Stir in the grated cucumber until evenly combined.",
                "Chill in the refrigerator until ready to serve."
            ],
            notes: "Raita adds a refreshing and cooling element to biryani or spicy dishes. Adjust seasoning to taste."
        )
        saveRecipe(
            name: "Chicken Chow Mein",
            prepTime: "15 minutes",
            cookingTime: "35 minutes",
            ingredients: [
                "225 g dried medium egg noodles",
                "2.63 tbsp oil",
                "0.75 onion, sliced",
                "450 g chicken breast, cut into 1cm strips",
                "0.75 jalapeno chili, finely chopped",
                "15 g fresh ginger, peeled and grated",
                "2.25 garlic cloves, finely chopped",
                "60 g cabbage, shredded",
                "0.75 carrot, julienned",
                "1.5 tsp Chinese five spice powder",
                "0.75 tsp ground black pepper powder",
                "0.75 tsp chili powder",
                "3.75 tbsp dark soy sauce",
                "0.75 tsp white/rice vinegar",
                "0.38 red pepper, thinly sliced",
                "0.38 green pepper, thinly sliced",
                "5.25 tbsp chili and garlic sauce",
                "1.5 tbsp sriracha sauce",
                "0.75 tsp salt"
            ],
            prePrepInstructions: [
                "Cook the noodles according to the packet instructions, drain, and set aside."
            ],
            instructions: [
                "Heat the oil in a wok or large frying pan on medium heat and stir-fry the onion until soft and translucent.",
                "Add the chicken, fresh chili, ginger, and garlic. Cook for about 25 minutes until the chicken is cooked through and only a little moisture is left.",
                "Add the cabbage and carrot and stir for 3 minutes until the cabbage has almost wilted but still has a bite to it.",
                "Add the five spice powder, black pepper, chili powder, soy sauce, vinegar, and red and green peppers. Season with salt.",
                "Add the chili and garlic sauce and sriracha for an extra kick and stir-fry for another 2-3 minutes.",
                "Add the noodles and toss everything together to coat them in the sauce.",
                "Serve garnished with spring onions, nigella seeds, and sesame seeds."
            ],
            notes: "Feel free to adjust the spices and sauces to your liking. Add more sauce for a wetter dish or extra chili powder/sriracha for more heat. You can substitute chicken with sliced beef or raw king prawns for variation."
        )
        saveRecipe(
            name: "Chicken Clay Pot (啫啫雞煲)",
            prepTime: "20 minutes",
            cookingTime: "30 minutes",
            ingredients: [
                "7.1 g cloud ear fungus, soaked in warm water",
                "28.3 g dried shiitake mushrooms, soaked in warm water",
                "28.3 g green onion whites, cut lengthwise into thin strips",
                "907 g chicken drumsticks, deboned and cut into large chunks",
                "28.3 g ginger, cut into small triangular pieces",
                "28.3 g shallots, cut into small triangular pieces",
                "14.2 g garlic, trimmed and cut into small triangular pieces",
                "1 link Chinese sausage, sliced diagonally into thin pieces",
                "1 tbsp Kikkoman® oyster sauce (marinade)",
                "1 tbsp Kikkoman® light soy sauce (marinade)",
                "1 tbsp cooking wine (marinade)",
                "1 tbsp cornstarch (marinade)",
                "0.33 tsp white pepper (marinade)",
                "1 tbsp Kikkoman® oyster sauce (sauce)",
                "2 tsp Kikkoman® light soy sauce (sauce)",
                "0.50 tsp Kikkoman® dark soy sauce (sauce)",
                "1 tbsp cooking wine (sauce)",
                "1 tsp salt (sauce)",
                "1 tsp sugar (sauce)",
                "1 tsp cornstarch (slurry)",
                "3 tsp water (slurry)",
                "3 tbsp oil, divided",
                "0.50 cup hot water",
                "0.50 tsp sugar (for finishing)",
                "1 tsp Kikkoman® sesame oil (for finishing)",
                "1 tbsp cooking wine (for finishing)"
            ],
            prePrepInstructions: [
                "Soak cloud ear fungus in warm water. Soak dried shiitake mushrooms in warm water until softened. Drain and prepare both.",
                "Cut green onion whites lengthwise into thin strips.",
                "Cut ginger, shallots, and garlic into small triangular pieces.",
                "Slice Chinese sausage diagonally into thin pieces.",
                "Combine marinade ingredients and coat chicken thoroughly. Let marinate."
            ],
            instructions: [
                "Heat a wok on high. Add oil and reduce heat to low.",
                "Sauté ginger for 10-15 seconds, then add garlic and shallots and cook until fragrant.",
                "Increase heat to medium, add chicken, and sear for 1 minute without stirring. Flip and cook for another 30-40 seconds.",
                "Add shiitake mushrooms and stir fry until fragrant. Add Chinese sausage, cloud ear fungus, and cooking wine. Stir fry briefly.",
                "Pour sauce into the wok while stirring, then add hot water. Bring to a boil and cover to cook for 1.5-2 minutes.",
                "Uncover, taste, and adjust with more sugar if needed. Stir in slurry to thicken sauce. Add sesame oil and green onion whites.",
                "Heat a clay pot over low heat. Add remaining oil and transfer contents of the wok into the clay pot. Cover with lid.",
                "Cook on high until steaming, drizzle cooking wine around lid edges, then cook for another 30 seconds until bubbling. Serve directly from the clay pot."
            ],
            notes: "For added flavor, use the bones from the chicken to make stock. The clay pot enhances the aroma and presentation of this dish."
        )
        saveRecipe(
            name: "Instant Pot Pakistani Chicken Curry with Potatoes",
            prepTime: "30 minutes",
            cookingTime: "12 minutes",
            ingredients: [
                "2.25 medium (~405 g) yellow onion, roughly chopped",
                "2.25 medium (~315 g) tomato, roughly chopped",
                "0.56 cup neutral oil (e.g., avocado or grapeseed oil)",
                "2.25 lb bone-in, cut-up, skinless chicken (or see Note 1 for boneless)",
                "6.75-9 cloves garlic, crushed",
                "0.75 inch ginger, crushed",
                "2.25 small green chili pepper, thinly sliced",
                "2.81 tsp kosher salt",
                "4.5 small (~720 g) Russet potatoes, peeled and cut into large chunks",
                "1 tsp whole coriander seeds, roughly crushed (optional)",
                "3 tsp cumin seeds",
                "15 whole black peppercorns",
                "5 whole cloves",
                "3 tsp Kashmiri chili or mild red chili powder",
                "1.13 tsp turmeric powder",
                "1 tsp cumin powder",
                "3 tsp coriander powder",
                "4.5 tbsp cilantro leaves, chopped",
                "0.56 tsp garam masala"
            ],
            prePrepInstructions: [
                "Finely chop the onion in a food processor, being careful not to blend into a paste.",
                "Roughly purée the tomatoes in the same food processor and set aside."
            ],
            instructions: [
                "Select the Sauté – More setting on the Instant Pot and heat the oil.",
                "Add onions and sauté until lightly golden, about 8 minutes.",
                "Add garlic and ginger and sauté until the raw smell disappears, about 30 seconds.",
                "Deglaze the pan with 2 tbsp of water. Add chicken and fry until it changes color, about 5 minutes.",
                "Deglaze the pan if it starts to stick. Add whole spices, ground spices, salt, green chili pepper, and tomato purée.",
                "Sauté for 1-2 minutes. Add potatoes and 1 cup of water (adjust depending on desired curry consistency). Mix well.",
                "Cancel Sauté. Secure the lid and set Pressure Cook to High Pressure for 12 minutes for bone-in chicken, or 6 minutes for boneless (with 3/4 cup water).",
                "Allow pressure to release naturally for 5 minutes, then manually release any remaining pressure.",
                "Open the lid, adjust salt to taste, and garnish with garam masala and cilantro. Stir gently as potatoes will be very tender.",
                "Serve hot with rice, roti, or naan."
            ],
            notes: "For boneless chicken, reduce pressure cook time to 6 minutes and use 3/4 cup water. Adjust spice levels and water to customize curry consistency."
        )
        saveRecipe(
            name: "Chicken Dumplings",
            prepTime: "30 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "1/2 cabbage, shredded (1 bowl full)",
                "3-4 carrots, shredded/chopped (1/2 bowl full)",
                "500g minced chicken",
                "1 onion, sliced",
                "A few chives, chopped",
                "1 clove garlic, minced",
                "2 spring onions, chopped",
                "284g gyoza wrappers",
                "Black pepper",
                "Light soy sauce",
                "Fish sauce",
                "Oil",
                "Salt",
                "Extra hot chili powder"
            ],
            prePrepInstructions: [
                "Shred the cabbage and carrots.",
                "Slice the onion, chop the chives, and spring onions.",
                "Prepare and measure out all other ingredients."
            ],
            instructions: [
                "Heat oil in a pan and fry the onions until softened.",
                "Add minced garlic, 1 tsp salt, and 1 tsp black pepper. Stir and cook until aromatic.",
                "Add the minced chicken and cook for 5 minutes until no longer pink.",
                "Add the cabbage and mix well, cooking until softened.",
                "Stir in the carrots and continue cooking until vegetables are soft, stirring frequently to avoid sticking or burning.",
                "Mix in fish sauce and extra hot chili powder.",
                "Add the chives, spring onions, and light soy sauce. Cook for another 5 minutes.",
                "Use the filling to stuff the gyoza wrappers, sealing the edges to form dumplings.",
                "Fry the gyoza in shallow oil until golden brown on one side, then flip.",
                "Add a small amount of water to the pan and cover to steam until translucent."
            ],
            notes: "Serve the dumplings hot with your choice of dipping sauce. Adjust spice levels by adding more or less chili powder."
        )
        saveRecipe(
            name: "Chicken Kothu Roti",
            prepTime: "6 hours (including marination time)",
            cookingTime: "1 hour",
            ingredients: [
                "1 bulb garlic + 2 cloves",
                "1 inch ginger + equal amount to 2 cloves garlic",
                "6 green chilies + 1 chopped",
                "1 chicken breast, cubed",
                "1.5 tbsp tikka curry paste",
                "1 vegetable stock cube (optional)",
                "2 tbsp fennel seeds + 1 tbsp",
                "30 + 20 + 15 curry leaves (divided)",
                "13-15 black peppercorns",
                "8 green cardamom pods",
                "8-10 cloves",
                "2 dried red chili peppers",
                "1 inch cinnamon stick",
                "1.5 tbsp cumin seeds",
                "1 tbsp hot mustard seeds",
                "40-50 small red onions or 3 medium onions, roughly chopped",
                "2 heaped tbsp tomato paste",
                "1.5 tbsp Jaffna curry powder + 3 tbsp",
                "1/4 tsp turmeric",
                "Salt",
                "Juice of 1 lime",
                "400ml water",
                "Few pieces of pandan leaves",
                "4 eggs",
                "Roti, shredded",
                "Black pepper",
                "1 leek, chopped"
            ],
            prePrepInstructions: [
                "Marinate chicken with tomato paste, curry powder, garlic, ginger, green chili, curry leaves, turmeric, salt, lime juice, and cornflour for 6 hours.",
                "Chop garlic, ginger, and onions. Prepare all spices and vegetables."
            ],
            instructions: [
                "In a frying pan, temper fennel seeds, curry leaves, black peppercorns, cardamom, cloves, red chilies, cinnamon, and pandan leaves until aromatic.",
                "Grind tempered spices into powder ('Vaasa Thool') and set aside.",
                "In a pan, fry mustard seeds in hot oil, then add cumin seeds, fennel seeds, and curry leaves. Add garlic, ginger, onions, and green chilies. Cook for 5-7 minutes.",
                "Set aside the sautéed mixture. Place the marinated chicken in a pot without oil, add salt, and cook over medium heat.",
                "Add 400ml water, bring to a boil, and mix in additional curry powder and reserved sautéed mixture.",
                "Simmer on medium-low heat for 20-30 minutes. Add 'Vaasa Thool' and parboiled potatoes. Cook for 10 minutes.",
                "In a separate pan, fry onions, leeks, curry leaves, and eggs. Add shredded roti and mix.",
                "Add the fried roti mixture to the chicken curry. Add pandan leaves and remaining curry leaves.",
                "Finish with lime juice, adjust seasoning, and mix gently to avoid breaking the chicken."
            ],
            notes: "Kothu roti is a complete meal and can be made spicier by adding more green chilies. Adjust seasonings to your preference."
        )
        saveRecipe(
            name: "Chicken Mei Fun",
            prepTime: "15 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "390g dried thin rice vermicelli noodles (yields 450g after soaking)",
                "624g boneless skinless chicken breast, thinly sliced",
                "5.5 eggs, beaten with a pinch of salt",
                "5.5 teaspoons Shaoxing wine (marinade)",
                "0.69 teaspoon salt (marinade)",
                "2.75 teaspoons cornstarch (marinade)",
                "5.5 tablespoons oyster sauce (sauce)",
                "2.75 tablespoons Shaoxing wine (sauce)",
                "2.75 tablespoons light soy sauce (sauce)",
                "2.75 teaspoons dark soy sauce (sauce)",
                "2.75 teaspoons sesame oil (sauce)",
                "0.69 teaspoon white pepper (sauce)",
                "0.69 teaspoon sugar (sauce)",
                "8.25 tablespoons peanut oil or vegetable oil",
                "2.75 thumb ginger, minced",
                "5.5 cloves garlic, minced",
                "1.38 white onion, sliced",
                "2.75 medium carrots, julienned",
                "5.5 cups cabbage, shredded",
                "8.25 green onions, sliced into 2-inch pieces"
            ],
            prePrepInstructions: [
                "Slice chicken thinly and marinate with Shaoxing wine, salt, and cornstarch. Mix well and set aside.",
                "Soak or cook vermicelli noodles per package instructions until al dente. Drain and cut into short strands for easy stir-frying.",
                "Combine all sauce ingredients in a small bowl and set aside."
            ],
            instructions: [
                "Heat 1 tablespoon oil in a skillet over medium-high heat. Cook the chicken until lightly browned and cooked through, then set aside.",
                "In the same skillet, scramble the eggs lightly until just cooked. Transfer to the plate with the chicken.",
                "Add remaining oil to the skillet and sauté ginger, garlic, and onion for 1 minute.",
                "Add carrot and cabbage, cooking until the carrot softens slightly.",
                "Add noodles, cooked chicken, green onions, and sauce mixture. Toss until evenly combined.",
                "Return the eggs to the skillet, toss again, and serve hot."
            ],
            notes: "Cutting the noodles into shorter strands makes them easier to stir fry and serve. Adjust sauce seasoning to taste."
        )
        saveRecipe(
            name: "Chicken Pad Thai",
            prepTime: "15 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "115g dried thin flat rice noodles",
                "180g skinless boneless chicken thighs, sliced thinly",
                "115g extra-firm tofu, diced",
                "2 large eggs",
                "105g mung bean sprouts, washed and strained",
                "20g garlic chives, chopped into 2-inch segments",
                "12.5g shallot, diced (or substitute with 2 tablespoons red onion)",
                "2 cloves garlic, finely chopped",
                "30ml vegetable oil or neutral oil",
                "1.5g salt (to season chicken)",
                "60ml water (for cooking noodles)",
                "1 lime, cut into wedges (optional garnish)",
                "1/4 cup roasted peanuts, crushed (optional garnish)",
                "37.5g palm sugar (or substitute with brown sugar or coconut sugar, for noodle sauce)",
                "22ml fish sauce (for noodle sauce)",
                "70g tamarind pulp (for noodle sauce)",
                "80ml hot boiling water (to soak tamarind pulp)"
            ],
            prePrepInstructions: [
                "Season sliced chicken thighs with salt and set aside.",
                "Make tamarind concentrate by soaking tamarind pulp in hot water, then squeezing and straining to extract paste.",
                "Prepare noodle sauce by caramelizing palm sugar in a pan, mixing in tamarind paste and fish sauce. Set aside."
            ],
            instructions: [
                "Soak rice noodles in hot water until limp but firm. Strain and set aside.",
                "Heat oil in a pan over medium heat. Cook the chicken until no longer pink and set aside.",
                "In the same pan, sauté shallots and garlic briefly. Add tofu and stir-fry for 1-2 minutes.",
                "Toss in strained rice noodles and noodle sauce. Add water incrementally to cook noodles to desired texture.",
                "Push noodles aside and scramble eggs in the empty part of the pan. Mix eggs into noodles.",
                "Add bean sprouts and garlic chives. Stir briefly and remove from heat.",
                "Garnish with lime wedges and crushed peanuts. Serve hot."
            ],
            notes: "For an authentic flavor, ensure the tamarind paste is freshly prepared. Adjust the noodle sauce for sweetness or tanginess based on preference."
        )
        saveRecipe(
            name: "Chicken Pot Pie",
            prepTime: "30 minutes",
            cookingTime: "35 minutes",
            ingredients: [
                "FOR THE PUFF PASTRY:",
                "262g very cold butter (salted or unsalted; adjust salt)",
                "118g very cold water",
                "260g all-purpose flour",
                "¼ teaspoon salt (increase to ¾ teaspoon for unsalted butter)",
                "EGG WASH:",
                "1 egg",
                "1 tablespoon water",
                "FILLING:",
                "500g chicken breast, cubed",
                "220g mushrooms, sliced",
                "1 medium onion, diced",
                "1 celery stalk, sliced",
                "2 carrots, sliced",
                "1 cup frozen peas (250g)",
                "500ml chicken stock (1 stock cube)",
                "6 tablespoons (85g) unsalted butter",
                "½ cup (118ml) double cream",
                "⅓ cup (72g) plain flour",
                "3 cloves garlic, minced",
                "2 tsp salt",
                "2 tsp ground black pepper",
                "1 tbsp chili powder",
                "1 tsp dried mixed herbs",
                "1 tsp dried oregano"
            ],
            prePrepInstructions: [
                "For the pastry: Using a food processor, pulse together flour, salt, and 170g cold butter until absorbed. Add the remaining butter and pulse briefly to combine.",
                "Add cold water and pulse until dough forms a ball. Avoid over-processing.",
                "On a floured surface, knead dough lightly 10 times, roll into a rectangle, fold like an envelope, then in half. Wrap in plastic and refrigerate for 1-2 hours."
            ],
            instructions: [
                "Preheat oven to 190°C (170°C fan).",
                "Melt butter in a medium-high heat pan and cook chicken cubes for 10 minutes.",
                "Add onions, carrots, and celery, cooking for 10 minutes until softened.",
                "Add mushrooms, then stir in salt, black pepper, chili powder, mixed herbs, and oregano.",
                "Lower heat and mix in flour until paste consistency forms, about 2 minutes.",
                "Add stock and double cream, bringing to a boil to thicken, then simmer.",
                "Add frozen peas, mix, and let cool.",
                "Pour filling into an oven tray and cover with rolled puff pastry. Score a hole in the center for air to escape.",
                "Brush with egg wash and bake for 20-25 minutes until golden brown.",
                "Cool for 10-15 minutes before serving."
            ],
            notes: "Ensure the filling cools slightly before assembling the pie to avoid soggy pastry. Adjust seasoning to your taste."
        )
        saveRecipe(
            name: "Chicken Pot Pie Soup (Paleo)",
            prepTime: "10 minutes",
            cookingTime: "35 minutes",
            ingredients: [
                "3 cups cooked chicken (white and dark meat)",
                "2 tablespoons butter, ghee, or fat of choice",
                "1 onion, diced",
                "5 cloves garlic, minced",
                "1 pound peeled potatoes, roughly chopped",
                "1 pound peeled potatoes, diced",
                "2 cups chicken broth",
                "1 cup full-fat canned coconut milk",
                "3 carrots, chopped",
                "2 celery ribs, diced",
                "1 cup frozen peas",
                "1 teaspoon salt",
                "½ teaspoon black pepper",
                "½ teaspoon cayenne (optional)",
                "1 tablespoon fresh sage, chopped",
                "2 teaspoons fresh thyme, chopped",
                "2 teaspoons fresh rosemary, chopped"
            ],
            prePrepInstructions: [
                "Cook chicken by boiling in water with desired seasonings for 30 minutes. Cool, shred, and reserve broth.",
                "Peel and chop all vegetables as listed."
            ],
            instructions: [
                "Melt butter in a Dutch oven or heavy-bottomed pot over medium heat. Sauté onion and garlic for 5 minutes until softened.",
                "Add roughly chopped potatoes and chicken broth. Bring to a boil, cover, and simmer for 10 minutes until potatoes are fork-tender.",
                "Scoop out boiled potatoes and blend with coconut milk until smooth. Set aside.",
                "Add diced potatoes and carrots to the pot. Bring to a boil, cover, and simmer for 9-10 minutes until tender.",
                "Stir in celery, peas, shredded chicken, spices, and pureed potatoes. Mix well and cook for 5 minutes on medium-low heat.",
                "Serve hot."
            ],
            notes: "For a dairy-free option, use ghee or coconut oil. Adjust seasoning to your preferred taste and garnish with additional herbs if desired."
        )
        saveRecipe(
            name: "Chicken Pulao (Instant Pot)",
            prepTime: "25 minutes",
            cookingTime: "6 minutes",
            ingredients: [
                "3.38 cups (641.25 g) aged, long-grain basmati rice",
                "4.5 tbsp neutral oil (e.g., grapeseed or avocado)",
                "2.25 tbsp ghee",
                "2.25 medium yellow onion, thinly sliced",
                "4.5 small (2.25 large) bay leaves",
                "1.13 tsp whole black peppercorns",
                "2.25 2-inch piece cinnamon stick",
                "2.25 small black cardamom, optional",
                "11.25 whole cloves",
                "2.25 tsp cumin seeds",
                "1.13 tsp coriander seeds, crushed",
                "9 cloves garlic, crushed",
                "1.69 inch piece ginger, crushed",
                "2.25 lb boneless chicken (cubed into 1” pieces)",
                "2.25 small (112.5 g) tomato, finely chopped",
                "2.25-4.5 green chili peppers, whole or chopped",
                "3.38 cups water",
                "5.06 tsp kosher salt, divided",
                "Small handful chopped cilantro and/or mint"
            ],
            prePrepInstructions: [
                "Wash the basmati rice thoroughly and soak it in water for 15 minutes. Drain and set aside.",
                "Prepare all ingredients (chop onions, tomatoes, and garlic, crush ginger, and measure spices)."
            ],
            instructions: [
                "Select the high Sauté setting on the Instant Pot. Add oil, ghee, and onions. Sauté until onions are golden brown (~8-10 minutes), deglazing with a tablespoon of water as needed.",
                "Add whole spices, garlic, and ginger. Sauté for 1 minute.",
                "Add chicken and ¼ tsp salt. Sauté until chicken changes color (~2-3 minutes).",
                "Add tomato and green chili peppers. Sauté until tomato softens (~2 minutes).",
                "Add rice, remaining salt, and water. Stir to combine, ensuring rice is submerged.",
                "Cancel Sauté setting. Secure the lid and pressure cook on high for 6 minutes.",
                "Allow natural pressure release for 15 minutes. Manually release remaining pressure.",
                "Garnish with cilantro/mint and gently transfer rice to a serving platter using a rice paddle. Serve with raita or yogurt."
            ],
            notes: "For fluffy, separated rice, use aged basmati rice and follow soaking and washing guidelines. Avoid watery tomatoes, and pat chicken dry if rinsed."
        )
        saveRecipe(
            name: "Cozy Chicken Soup",
            prepTime: "15 minutes",
            cookingTime: "30 minutes",
            ingredients: [
                "600 g chicken drumsticks or thighs (with bones and skin)",
                "1 medium onion, diced",
                "3 medium to large carrots, chopped",
                "450 g potatoes, chopped",
                "200 g leeks, sliced",
                "3 celery sticks, sliced",
                "1 ⅓ liters chicken bone broth (5 cups)",
                "1 bay leaf",
                "1 tbsp avocado oil"
            ],
            prePrepInstructions: [
                "Peel and chop all vegetables as listed.",
                "Prepare chicken drumsticks or thighs by removing excess fat if needed."
            ],
            instructions: [
                "Heat a large soup pot over medium heat and add avocado oil.",
                "Sauté onions for about 1 minute. Add chicken along with salt and pepper, and sauté for 5 minutes until chicken gains some color.",
                "Add all chopped vegetables, bay leaf, and chicken bone broth to the pot.",
                "Bring the soup to a boil, then reduce heat and let it simmer for approximately 20 minutes.",
                "Remove chicken from the pot and shred the meat, discarding bones and skin.",
                "Return shredded chicken to the soup. Taste and adjust seasoning with salt and pepper as needed.",
                "Serve hot with optional garnishes or bread."
            ],
            notes: "For added flavor, you can use homemade bone broth. Adjust the consistency by adding more broth or water as needed."
        )
        saveRecipe(
            name: "Chicken Corn Soup (雞肉玉米湯)",
            prepTime: "15 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "85 g chicken breast, diced",
                "4 cups water, for boiling",
                "0.5 carrot, diced",
                "227 g unsweetened corn",
                "227 g water, for blending corn",
                "1 egg, beaten",
                "1 tsp cornstarch",
                "0.5 tsp salt (for chicken marinade and soup)",
                "1 tbsp water (for chicken marinade and slurry)",
                "6 tsp cornstarch (for slurry)",
                "2 tbsp water (for slurry)",
                "1 tsp chicken powder",
                "1 tsp white pepper (to taste)",
                "0.25 tsp sesame oil",
                "0.5 cup cilantro, optional (for garnish)"
            ],
            prePrepInstructions: [
                "Dice the chicken breast into small pieces. Mix with cornstarch, salt, and water for the marinade. Stir until chicken absorbs the mixture.",
                "Blend the corn and water into a smooth puree (about 15-30 seconds).",
                "Dice the carrot into small cubes.",
                "Prepare a cornstarch slurry by mixing cornstarch and water until fully dissolved.",
                "Beat the egg in a bowl until smooth.",
                "Chop cilantro if using as garnish."
            ],
            instructions: [
                "Bring 4 cups of water to a boil in a large pot.",
                "Add the corn puree and diced carrots to the pot. Stir to combine.",
                "Once the mixture boils again, slowly add the cornstarch slurry while stirring constantly to thicken the soup.",
                "Slowly add the marinated chicken while stirring to prevent clumping. Cook until the chicken is done.",
                "Gradually pour in the beaten egg in 2-3 batches while stirring constantly to create 'egg flowers'.",
                "Add salt, chicken powder, white pepper, and sesame oil. Stir to combine.",
                "Garnish with chopped cilantro, if desired, and serve hot."
            ],
            notes: "This comforting soup is versatile. Adjust seasoning to your preference. Garnishing with cilantro adds a fresh touch but is optional."
        )
        saveRecipe(
            name: "Chicken Vindaloo (Instant Pot)",
            prepTime: "10 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "2 pounds skinless and boneless chicken thighs, cut into quarters",
                "2 tablespoons oil of choice",
                "1 teaspoon cumin seeds",
                "1/2 teaspoon black mustard seeds",
                "1 Serrano pepper or green chili, minced (adjust to taste)",
                "2 teaspoons paprika",
                "1 1/4 teaspoons salt (to taste)",
                "1/4 teaspoon cinnamon",
                "1/4 teaspoon ground cardamom",
                "1/4 teaspoon black pepper",
                "1/4–1/2 teaspoon cayenne (adjust to taste)",
                "3 tablespoons white vinegar",
                "1 cup frozen onion masala",
                "Cilantro, for garnish"
            ],
            prePrepInstructions: [
                "Cut chicken thighs into quarters and set aside.",
                "Mince the Serrano pepper or green chili.",
                "Measure and prepare all spices."
            ],
            instructions: [
                "Press the sauté button on the Instant Pot and add oil. Allow it to heat up for a minute.",
                "Add cumin seeds, mustard seeds, and Serrano pepper to the pot. Sauté until the cumin seeds brown.",
                "Add the chicken and all the spices. Stir-fry for 2-3 minutes to coat the chicken evenly.",
                "Add the white vinegar and frozen onion masala. Mix well.",
                "Secure the lid of the Instant Pot and close the pressure valve. Cook for 5 minutes at high pressure.",
                "Let the pressure naturally release or perform a quick release after 10 minutes.",
                "Garnish with cilantro and serve hot."
            ],
            notes: "Adjust the amount of Serrano pepper and cayenne to suit your spice preference. Serve with basmati rice, naan, or roti for a complete meal."
        )
        saveRecipe(
            name: "Chilli Chicken (Spicy, Super Crispy!)",
            prepTime: "15 minutes",
            cookingTime: "40 minutes",
            ingredients: [
                "1 lb (454 g) boneless chicken breast, cut into 3/4” cubes",
                "3/4 tsp freshly ground black pepper",
                "3/4 + 1/8 tsp sea salt",
                "1 tsp soy sauce",
                "1/4 tsp sesame oil",
                "1/2 tsp garlic paste",
                "1/2 tsp ginger paste",
                "1/4 tsp baking soda",
                "1 small egg, whisked",
                "1/2 cup (64 g) cornstarch",
                "1/4 cup (32 g) all-purpose flour",
                "3 tbsp ketchup",
                "1 tbsp Desi-style chili garlic sauce",
                "1 tbsp Asian-style chili garlic sauce",
                "2 tbsp soy sauce",
                "1 1/2 tsp Worcestershire sauce",
                "1 tsp rice vinegar",
                "1/2 tsp red chili flakes",
                "1/4 tsp sea salt",
                "1 1/2 tsp honey",
                "1 tsp sesame oil",
                "1/8 tsp ground white pepper",
                "1/3 cup vegetable stock",
                "1/2 tsp cornstarch",
                "3 tbsp neutral oil, plus more for frying",
                "4-5 garlic cloves, finely chopped",
                "1\" piece ginger, finely chopped",
                "5 green onions, white/light parts finely chopped (reserve green parts for garnish)",
                "1 small yellow onion, chopped into 1\" squares",
                "1/2 small green bell pepper, chopped into 1\" squares",
                "3 Thai/bird’s eye green chili peppers, left whole",
                "8 whole dried red chili peppers"
            ],
            prePrepInstructions: [
                "Cut chicken breast into 3/4” cubes.",
                "Prepare the marinade by mixing black pepper, salt, soy sauce, sesame oil, garlic paste, ginger paste, baking soda, whisked egg, cornstarch, and flour. Coat the chicken and set aside.",
                "Mix the sauce ingredients: ketchup, Desi-style chili garlic sauce, Asian-style chili garlic sauce, soy sauce, Worcestershire sauce, rice vinegar, red chili flakes, sea salt, honey, sesame oil, white pepper, vegetable stock, and cornstarch. Whisk well and set aside."
            ],
            instructions: [
                "Heat oil in a frying pan to about 325-350°F (113-175°C). Fry marinated chicken pieces until golden and crispy, about 4 minutes per batch. Remove and set aside.",
                "Heat oil in a wok over medium heat. Sauté garlic and ginger until golden brown.",
                "Add the white/light parts of the green onion, yellow onion, bell pepper, green chili peppers, and whole dried red chili peppers. Increase the heat to high and stir-fry for 2-3 minutes.",
                "Pour in the prepared sauce and simmer for 2 minutes while stirring.",
                "Add the fried chicken and toss to coat in the sauce. Garnish with green parts of the green onions.",
                "Serve hot with fried rice, jasmine rice, basmati rice, or chow mein."
            ],
            notes: "For less heat, adjust the chili garlic sauce and red chili flakes. Air-frying instructions are available for a lighter option. This dish pairs well with steamed or fried rice for a complete meal."
        )
        saveRecipe(
            name: "Chilli Chicken (Spicy, Super Crispy!)",
            prepTime: "15 minutes",
            cookingTime: "40 minutes",
            ingredients: [
                "1 lb (454 g) boneless chicken breast, cut into 3/4” cubes",
                "3/4 tsp freshly ground black pepper",
                "3/4 + 1/8 tsp sea salt",
                "1 tsp soy sauce",
                "1/4 tsp sesame oil",
                "1/2 tsp garlic paste",
                "1/2 tsp ginger paste",
                "1/4 tsp baking soda",
                "1 small egg, whisked",
                "1/2 cup (64 g) cornstarch",
                "1/4 cup (32 g) all-purpose flour",
                "3 tbsp ketchup",
                "1 tbsp Desi-style chili garlic sauce",
                "1 tbsp Asian-style chili garlic sauce",
                "2 tbsp soy sauce",
                "1 1/2 tsp Worcestershire sauce",
                "1 tsp rice vinegar",
                "1/2 tsp red chili flakes",
                "1/4 tsp sea salt",
                "1 1/2 tsp honey",
                "1 tsp sesame oil",
                "1/8 tsp ground white pepper",
                "1/3 cup vegetable stock",
                "1/2 tsp cornstarch",
                "3 tbsp neutral oil, plus more for frying",
                "4-5 garlic cloves, finely chopped",
                "1\" piece ginger, finely chopped",
                "5 green onions, white/light parts finely chopped (reserve green parts for garnish)",
                "1 small yellow onion, chopped into 1\" squares",
                "1/2 small green bell pepper, chopped into 1\" squares",
                "3 Thai green chili peppers, left whole",
                "8 whole dried red chili peppers"
            ],
            prePrepInstructions: [
                "Cut chicken breast into 3/4\" cubes.",
                "Prepare the marinade by mixing black pepper, salt, soy sauce, sesame oil, garlic paste, ginger paste, and baking soda. Add whisked egg, cornstarch, and flour. Coat the chicken evenly and set aside.",
                "Prepare the sauce by mixing ketchup, Desi-style chili garlic sauce, Asian-style chili garlic sauce, soy sauce, Worcestershire sauce, rice vinegar, red chili flakes, salt, honey, sesame oil, white pepper, vegetable stock, and cornstarch. Whisk well and set aside."
            ],
            instructions: [
                "Heat oil in a frying pan to around 325-350°F (113-175°C). Fry marinated chicken pieces in batches until golden and crispy, about 4 minutes per batch. Remove and set aside.",
                "In a wok, heat oil over medium heat. Add garlic and ginger, and sauté until golden brown.",
                "Add the white/light parts of green onions, yellow onion, bell pepper, green chili peppers, and whole dried red chili peppers. Increase the heat to high and stir-fry for 2-3 minutes until softened.",
                "Pour in the prepared sauce and simmer for 2 minutes while stirring.",
                "Add the fried chicken and toss to coat evenly in the sauce. Garnish with the green parts of the green onions.",
                "Serve hot with fried rice, jasmine rice, basmati rice, or chow mein."
            ],
            notes: "Adjust the heat level by modifying the chili garlic sauces and red chili flakes. Frying yields the crispiest chicken, but air-frying is a lighter alternative. Serve immediately for the best texture and flavor."
        )
        saveRecipe(
            name: "Chimney Cake (Kürtöskalács)",
            prepTime: "20 minutes (plus 60 minutes for dough rise)",
            cookingTime: "25 minutes",
            ingredients: [
                "1 3/4 cups (240 g) all-purpose flour",
                "2 1/4 teaspoons active dry yeast (or 2 teaspoons instant yeast)",
                "2 tablespoons (30 g) sugar",
                "1/8 teaspoon salt",
                "1 large egg, room temperature",
                "3 tablespoons (45 g) melted butter",
                "1/2 cup (120 ml) lukewarm milk",
                "Melted butter for brushing",
                "Sugar for coating",
                "1 cup (115 g) ground walnuts",
                "1/2 cup (100 g) sugar",
                "2 teaspoons (6 g) cinnamon"
            ],
            prePrepInstructions: [
                "If using active dry yeast, proof it by mixing with lukewarm milk and a pinch of sugar. Let it foam for 5-10 minutes.",
                "In a large bowl, combine flour, sugar, and salt. Add egg, melted butter, and yeast mixture. Knead into a sticky dough.",
                "Transfer dough to a greased container, cover, and allow it to rise for 60 minutes until doubled in size.",
                "Prepare rolling pins by wrapping in aluminum foil (2-3 layers) and brushing with melted butter to prevent sticking."
            ],
            instructions: [
                "Punch down the risen dough and divide into 4 equal parts (about 115 g each).",
                "Roll each portion into a square sheet about 1/6 inch (4 mm) thick. Cut into long ribbons about 1/2 inch (13 mm) wide.",
                "Wrap each ribbon tightly around the rolling pin, keeping the dough thin and overlapping slightly. Roll gently to press the layers together.",
                "Brush the dough with melted butter and roll in sugar.",
                "Bake at 375°F (190°C) for 20-25 minutes, rotating the rolling pins occasionally for even baking.",
                "Remove from the oven and roll in the walnut-sugar-cinnamon mixture while still warm.",
                "Tap the rolling pin gently to release the cake and set upright to cool before serving."
            ],
            notes: "For extra flavor, use the roast function of your oven for even caramelization. Experiment with different toppings like cocoa powder or shredded coconut."
        )
        saveRecipe(
            name: "Chinese Beef Stew with Potatoes",
            prepTime: "10 minutes",
            cookingTime: "1 hour 40 minutes",
            ingredients: [
                "700 g beef chunks (about 1.5 lb)",
                "2 tablespoons neutral cooking oil",
                "2 onions, sliced",
                "1 thumb-sized piece of ginger, smashed",
                "2 star anises",
                "1 piece cassia cinnamon",
                "2 bay leaves",
                "2 cloves",
                "2 dried chilies (optional)",
                "2 tablespoons light soy sauce",
                "1 tablespoon dark soy sauce",
                "1 tablespoon Shaoxing rice wine",
                "600 ml hot water (2.5 cups)",
                "1/4 teaspoon salt (to taste)",
                "3 medium potatoes (350 g), peeled and chunked",
                "1 medium carrot (120 g), chunked",
                "Chopped coriander (optional)"
            ],
            prePrepInstructions: [
                "Boil the beef in cold water until fully frothy, then skim off froth and drain.",
                "Prepare the vegetables: slice onions, smash ginger, and chunk the potatoes and carrots."
            ],
            instructions: [
                "Heat oil in a pot over medium-low heat. Fry onions until lightly browned.",
                "Add ginger and spices (star anise, cassia cinnamon, bay leaves, cloves, dried chilies) and stir until fragrant.",
                "Add beef, soy sauces, Shaoxing wine, and hot water. Bring to a boil, reduce heat, cover, and simmer for 1 hour 30 minutes until the beef is tender.",
                "Add potatoes and carrots. If needed, add more water. Simmer uncovered for 10-15 minutes until vegetables are tender.",
                "Optional: Turn heat to high to reduce broth for a thicker consistency.",
                "Garnish with chopped coriander before serving."
            ],
            notes: "For a quicker version, use an Instant Pot: pressure cook beef for 20 minutes on high, then sauté vegetables uncovered until tender."
        )
        saveRecipe(
            name: "Chinese Steamed Meat Doughnuts (Ravioli)",
            prepTime: "2 hours",
            cookingTime: "20 minutes",
            ingredients: [
                "450 g minced pork",
                "100 g shrimps, chopped",
                "2 teaspoons grated ginger",
                "1 spring onion, chopped",
                "1 daikon, peeled and grated",
                "2 teaspoons Sichuan pepper powder",
                "1 teaspoon five spice powder",
                "3 teaspoons salt",
                "6 tablespoons soy sauce",
                "2 tablespoons oyster sauce",
                "4 tablespoons water",
                "2 tablespoons sesame oil",
                "500 g wheat flour (type 00)",
                "240 g water (for dough)",
                "1 teaspoon salt (for dough)"
            ],
            prePrepInstructions: [
                "In a large bowl, combine wheat flour and salt. Gradually add water and knead into a dough.",
                "Cover the dough with plastic wrap and let it rest for 20 minutes.",
                "Prepare the filling: mix pork, shrimp, ginger, spring onion, Sichuan pepper, five spice powder, salt, soy sauce, and oyster sauce in a bowl.",
                "Add water to the filling mixture, stirring in one direction until liquid is absorbed. Add sesame oil and mix until compact.",
                "Blanch grated daikon in boiling water, then squeeze out excess water and mix it into the filling."
            ],
            instructions: [
                "After the dough has rested, knead it until smooth and divide it into small portions.",
                "Roll each portion into a flat, round disk.",
                "Place a small amount of filling in the center of each disk. Fold and seal the edges using your preferred method.",
                "Arrange the filled ravioli in a steamer, leaving space between them.",
                "Fill a wok or pot with water up to 1/3 of its capacity. Place the steamer on top and bring the water to a boil.",
                "Once boiling, reduce heat to medium and steam the ravioli for 15 minutes.",
                "Turn off the heat and let the ravioli cool for 3-5 minutes before serving.",
                "Serve with your preferred dipping sauce (e.g., vinegar, hot sauce)."
            ],
            notes: "To store, freeze ravioli in a single layer for at least 6 hours before transferring to a food bag. Steam frozen ravioli directly using the same cooking instructions."
        )
        saveRecipe(
            name: "Chocolate (Dark) and Almond Butter Vegan Cookie",
            prepTime: "20 minutes",
            cookingTime: "25 minutes (includes cooling time)",
            ingredients: [
                "205 g plain flour or fine wholemeal flour (chapatti flour works well)",
                "20 g cocoa powder",
                "1/2 tsp bicarbonate of soda (baking soda)",
                "1/2 tsp salt",
                "43 g golden caster sugar",
                "112 g soft light brown sugar",
                "40 g flaked almonds, lightly crushed and toasted",
                "112 g dark chocolate pieces",
                "65 g coconut oil or vegan butter",
                "72 g almond butter (or peanut butter as an alternative)",
                "100 g golden syrup",
                "40 g water"
            ],
            prePrepInstructions: [
                "Toast flaked almonds in a large frying pan over medium heat, stirring continuously until fragrant and browned. Remove from heat and let cool.",
                "Preheat the oven to 180°C (fan). Line two baking sheets with non-stick baking paper."
            ],
            instructions: [
                "Sieve flour, cocoa powder, bicarbonate of soda, and salt into a large mixing bowl. Stir in the caster sugar, light brown sugar, toasted almonds, and dark chocolate pieces.",
                "In a saucepan over low heat, gently melt the coconut oil and almond butter. Once melted, remove from heat and stir in the golden syrup and water.",
                "Pour the wet mixture into the bowl of dry ingredients. Stir until thoroughly combined into a dough.",
                "Divide the dough into ten equal pieces (weighing the dough helps with even portions). Roll each piece into a ball and place on the prepared baking sheets. Flatten slightly with your fingers.",
                "Bake in the preheated oven for 8–10 minutes, or until the edges are firm and the surface is dry to the touch. Cookies will be soft initially.",
                "Allow the cookies to cool on the tray for 15 minutes to firm up, then transfer to a wire rack to cool completely."
            ],
            notes: "Toasted chopped hazelnuts can be used instead of flaked almonds for a variation. Store cookies in an airtight container for up to a week."
        )
        saveRecipe(
            name: "Chocolate Aquafaba Mousse",
            prepTime: "20 minutes",
            cookingTime: "2 hours (includes chilling time)",
            ingredients: [
                "200g dark chocolate",
                "130ml aquafaba (liquid from 1 x 400g can of chickpeas)",
                "2 ½ tbsp sugar",
                "1 tsp vanilla extract",
                "1 pinch of salt",
                "1 handful of blueberries (optional, for garnish)"
            ],
            prePrepInstructions: [
                "Heat water in a medium saucepan until about 3cm deep and bring to a simmer.",
                "Place a heatproof bowl over the saucepan, ensuring the water doesn't touch the bowl. Break 85g of the dark chocolate into the bowl and allow it to melt. Once melted, remove from heat and set aside to cool slightly."
            ],
            instructions: [
                "Pour aquafaba into a large bowl. Using an electric beater, whisk the liquid for 10–15 minutes until it forms stiff peaks. (A hand whisk is not recommended.)",
                "Gently fold in the melted chocolate, sugar, vanilla extract, and salt into the aquafaba using a large metal spoon or spatula. Be careful not to deflate the mixture.",
                "Spoon the mousse into serving glasses or bowls and chill in the fridge for at least 2 hours.",
                "Before serving, grate the remaining 15g dark chocolate and garnish the mousse with grated chocolate and a handful of blueberries, if desired."
            ],
            notes: "Ensure the aquafaba is whipped to stiff peaks to achieve the best texture. Serve chilled for optimal taste and presentation."
        )
        saveRecipe(
            name: "Chocolate Cake with Ganache and Buttercream Frosting",
            prepTime: "45 minutes",
            cookingTime: "22 minutes per layer",
            ingredients: [
                "167 g unsalted butter",
                "167 g 70% chocolate",
                "120 ml brewed coffee (120 ml hot water with 1⅓ tbsp instant coffee granules)",
                "3 eggs",
                "100 ml buttermilk* (100 ml milk + 1 tsp lemon juice)",
                "2 tbsp vegetable or sunflower oil",
                "287 g caster sugar",
                "100 g plain flour",
                "100 g self-raising flour",
                "40 g cocoa powder",
                "0.5 tsp bicarbonate of soda",
                "0.33 tsp salt",
                "67 g butter (for ganache)",
                "133 g chocolate (for ganache)",
                "67 g double cream",
                "83 g soft unsalted butter (for buttercream)",
                "150 g icing sugar (for buttercream)",
                "53 g melted chocolate (for buttercream)"
            ],
            prePrepInstructions: [
                "Preheat oven to gas mark 5, 170°C fan, or 190°C conventional oven.",
                "Grease and line two 8-inch cake tins.",
                "Prepare buttermilk by combining milk and lemon juice, letting it sit for 5 minutes.",
                "Toast hazelnuts or other decorations if using."
            ],
            instructions: [
                "In a saucepan, melt butter, chocolate, and brewed coffee over low heat, stirring constantly. Let cool slightly.",
                "In a large bowl, whisk eggs, then add buttermilk and oil. Mix well.",
                "Add the cooled chocolate mixture to the egg mixture and whisk until combined.",
                "Whisk in caster sugar.",
                "Sift plain flour, self-raising flour, cocoa powder, bicarbonate of soda, and salt into the bowl. Stir gently until smooth, avoiding overmixing.",
                "Distribute batter evenly between prepared tins and level the tops. Bake for 22 minutes or until a skewer comes out clean.",
                "Cool cakes in the tins for 5 minutes, then transfer to a wire rack to cool completely.",
                "To make ganache, melt butter and chocolate in the microwave in 30-second intervals. Stir in double cream and let sit to thicken.",
                "For buttercream, whisk soft butter until pale and fluffy. Gradually add icing sugar, mixing well. Fold in melted chocolate.",
                "Level cake layers with a serrated knife. Assemble by spreading buttercream between layers, ensuring it doesn’t spill over.",
                "Cover the cake with ganache, spreading evenly on the top and sides with a palette knife or smoother.",
                "Decorate as desired with nuts, gold paint, or other toppings."
            ],
            notes: "Allow ganache to cool to a spreadable consistency before using. Store the finished cake in an airtight container at room temperature or in the fridge for up to 3 days."
        )
        saveRecipe(
            name: "Chocolate Chip Shortbread",
            prepTime: "20 mins",
            cookingTime: "20 mins",
            ingredients: [
                "300g plain flour",
                "200g cold salted butter, cubed",
                "1 large egg yolk",
                "100g caster sugar, plus extra to sprinkle",
                "80g milk or dark chocolate chips"
            ],
            prePrepInstructions: [
                "Sieve the flour into a large mixing bowl and add the butter.",
                "Rub the butter and flour between your fingers until the mixture resembles crumbs.",
                "Stir through the egg yolk and sugar, squishing everything together in the bowl to create a dough.",
                "Add the chocolate chips and spread them evenly throughout the dough.",
                "Form the dough into a flattened puck shape, wrap it in plastic wrap, and chill for 30 minutes."
            ],
            instructions: [
                "Preheat the oven to 170C/150C fan/gas 3. Line two baking sheets with baking parchment.",
                "Roll out the dough between two sheets of baking parchment until it’s 1cm thick.",
                "Cut into 14 rounds using a 7cm biscuit cutter.",
                "Re-roll any offcuts to maximize the dough.",
                "Transfer the rounds carefully to the prepared baking sheets, leaving space between them.",
                "Sprinkle with a little sugar.",
                "Bake in the oven for 15-20 minutes or until lightly golden.",
                "Cool for 10 minutes on the tray before transferring to a wire rack to cool completely."
            ],
            notes: "The dough may take a little work from the crumb stage to come together. Ensure the chocolate chips are evenly distributed for balanced flavor. Chilling the dough helps it firm up and makes it easier to roll and cut."
        )
        saveRecipe(
            name: "Chocolate Cheesecake (Instant Pot)",
            prepTime: "20 minutes",
            cookingTime: "30 minutes (plus 6-8 hours chilling time)",
            ingredients: [
                "10 chocolate sandwich cookies (e.g., Oreos or gluten-free Goodie Girl cookies)",
                "4 tablespoons butter, melted",
                "1 (14-ounce) can condensed milk",
                "1 cup (8 ounces) whole milk unsweetened Greek yogurt (full-fat)",
                "3 tablespoons cocoa powder",
                "1 teaspoon vanilla extract",
                "4 ounces chocolate chips",
                "1 tablespoon butter, room temperature",
                "1/2 cup (4 ounces) heavy cream",
                "Raspberries (optional, for topping)"
            ],
            prePrepInstructions: [
                "Grease a 6-inch cheesecake pan with a removable bottom.",
                "Ensure the pressure cooker is ready with the trivet or wire rack."
            ],
            instructions: [
                "Process the cookies in a food processor until fine crumbs form. Add melted butter and pulse until the mixture is moist.",
                "Press the cookie mixture into the bottom of the greased cheesecake pan to form the crust.",
                "In a bowl, whisk together the condensed milk, Greek yogurt, cocoa powder, and vanilla extract.",
                "Use an immersion blender to blend the mixture to ensure the cocoa is fully incorporated.",
                "Pour the cheesecake filling over the crust and cover the pan with foil.",
                "Add 2 cups of water to the pressure cooker’s steel inner pot. Place the trivet inside and set the cheesecake pan on top.",
                "Secure the lid, close the pressure valve, and cook for 30 minutes on high pressure. Naturally release pressure for 20 minutes, then release any remaining pressure.",
                "Remove the cheesecake from the pot and cool on a wire rack for 1 hour. Once slightly warm, unmold the cheesecake. Place it in the fridge to chill for 4-6 hours or overnight.",
                "For the ganache, place chocolate chips and butter in a small bowl. Bring the heavy cream to a simmer in a small saucepan, then pour it over the chocolate and butter. Whisk until smooth.",
                "Cool the ganache for 5-8 minutes until it thickens slightly, then pour it over the chilled cheesecake. Refrigerate for 1 hour to set the ganache.",
                "Top with raspberries before serving, if desired."
            ],
            notes: """
            Ensure the cheesecake chills thoroughly before adding the ganache.
            Store any leftovers in the fridge for up to 5 days.
            """
        )
        saveRecipe(
            name: "Chocolate Chip Cookies (Best Chewy)",
            prepTime: "10 minutes",
            cookingTime: "10 minutes (plus optional chill time)",
            ingredients: [
                "150g butter, softened",
                "150g soft brown sugar, golden caster sugar, or ideally half of each",
                "1 egg",
                "1 tsp vanilla extract",
                "180-200g plain flour (see recipe tips)",
                "1/2 tsp baking powder",
                "200g chocolate chips or chopped chocolate",
                "1/4 tsp salt"
            ],
            prePrepInstructions: [
                "For best flavor, prepare the dough the day before and chill overnight in the fridge, either as a whole or rolled into balls."
            ],
            instructions: [
                "Mix the butter and sugar together using an electric whisk or hand whisk until very light and fluffy.",
                "Beat in the egg and vanilla extract.",
                "Fold in the flour, baking powder, chocolate, and salt as quickly as possible without overworking the dough to avoid tough cookies.",
                "Chill the dough: Cover the bowl and refrigerate, or roll the dough into balls and chill overnight.",
                "Preheat the oven to 180°C (160°C fan) or gas mark 4. Line two baking sheets with parchment paper.",
                "Divide the dough into balls. For added texture, tear the balls in half and gently press them back together.",
                "Space the dough balls evenly on the baking sheets, leaving room for spreading.",
                "Bake fresh dough for 8–10 minutes or chilled dough for 10–12 minutes, until the edges are browned and crisp but the centers remain soft.",
                "Cool the cookies on the tray for a few minutes before transferring to a wire rack to cool completely."
            ],
            notes: """
            Adjust the flour amount based on desired texture: use 180g for thinner cookies and 200g for more cakey ones.
            Store cookies in an airtight container for up to three days.
            """
        )
        saveRecipe(
            name: "Chocolate Chip Cookies (Best Big Fat Chewy)",
            prepTime: "15 minutes",
            cookingTime: "15 minutes (plus optional chill time)",
            ingredients: [
                "240g (2 cups) all-purpose flour",
                "1/2 teaspoon baking soda",
                "1/2 teaspoon salt",
                "180g (1 cup) packed brown sugar",
                "180g (3/4 cup) unsalted butter, melted",
                "100g (1/2 cup) white sugar",
                "1 egg",
                "1 egg yolk",
                "1 tablespoon vanilla extract",
                "2 cups semisweet chocolate chips"
            ],
            prePrepInstructions: [
                "For best flavor, prepare the dough the day before and chill overnight in the fridge, either as a whole or rolled into balls."
            ],
            instructions: [
                "Preheat the oven to 325°F (165°C). Grease cookie sheets or line with parchment paper.",
                "Sift together the flour, baking soda, and salt. Set aside.",
                "In a large bowl, beat the brown sugar, melted butter, and white sugar with an electric mixer until smooth.",
                "Beat in the egg, egg yolk, and vanilla extract until the mixture is light and creamy.",
                "Gradually add the flour mixture to the wet ingredients and stir until just combined. Fold in the chocolate chips.",
                "Drop spoonfuls of dough about 3 inches apart onto the prepared baking sheets.",
                "Bake in the preheated oven for 15–17 minutes, or until the edges are golden.",
                "Allow cookies to cool briefly on the baking sheets before transferring to a wire rack to cool completely."
            ],
            notes: """
            Chilling the dough overnight enhances the flavor and texture.
            Store cookies in an airtight container for up to a week.
            """
        )
        saveRecipe(
            name: "Chocolate Cornflake Clusters",
            prepTime: "10 mins",
            cookingTime: "30 mins (chilling time)",
            ingredients: [
                "200g milk chocolate chips",
                "200g dark chocolate chips",
                "18.2g honey",
                "36.4g sugar",
                "145.5g cornflakes"
            ],
            prePrepInstructions: [
                "Line two baking sheets with parchment paper.",
                "Crush the cornflakes lightly in a bowl, leaving some pieces intact."
            ],
            instructions: [
                "Melt the milk and dark chocolate chips gently in a microwave-safe bowl by microwaving in 30-second intervals.",
                "Stir until smooth, then mix in the honey and sugar.",
                "Pour the chocolate mixture over the cornflakes and stir quickly to coat evenly.",
                "Scoop up 1 tablespoon of the mixture onto the parchment-lined baking sheets, shaping into clusters.",
                "Chill in the fridge for 30 minutes until set."
            ],
            notes: "Use any type of chocolate you like, such as chocolate chips, chopped chocolate bars, or buttons. Peanut butter can be added to create chocolate peanut butter bites. Store in the fridge for up to 2 weeks or freeze for up to 3 months."
        )
        saveRecipe(
            name: "Chocolate Cupcakes (Cupcake Jemma)",
            prepTime: "20 minutes",
            cookingTime: "24 minutes",
            ingredients: [
                "140g plain flour",
                "185g caster sugar",
                "0.5 tsp bicarbonate of soda",
                "0.25 tsp salt",
                "30g cocoa powder",
                "35g chocolate chips",
                "2 large eggs",
                "125ml cold coffee (2 tsp coffee mixed with hot water)",
                "125ml buttermilk (125ml whole milk + ½ tbsp lemon juice)",
                "105ml vegetable oil",
                "200g soft unsalted butter",
                "320g icing sugar",
                "3 tbsp whole milk",
                "95g chocolate (70% is best) or replace with Nutella"
            ],
            prePrepInstructions: [
                "Preheat the oven to 160°C (fan-assisted), 180°C (conventional), or Gas Mark 4.",
                "Prepare 125ml of buttermilk by mixing whole milk with lemon juice and let it sit for 5 minutes.",
                "Melt the chocolate or prepare Nutella for the buttercream."
            ],
            instructions: [
                "Combine cold coffee, buttermilk, eggs, and vegetable oil in a large bowl and whisk for about 30 seconds.",
                "Sieve in plain flour, cocoa powder, caster sugar, bicarbonate of soda, and salt. Mix well for another 30 seconds.",
                "Divide the batter evenly into cupcake cases using a jug and spoon.",
                "Sprinkle chocolate chips evenly over the batter in each case.",
                "Bake in the preheated oven for 22-24 minutes. Check for doneness by gently pressing the cupcake top to see if it springs back.",
                "Cool cupcakes for 15-20 minutes before adding buttercream."
            ],
            notes: """
            Ensure the coffee is cool before mixing it with other ingredients to avoid cooking the eggs prematurely.
            For the buttercream, whisk the butter for 5 minutes until pale and fluffy before adding the icing sugar in two batches.
            Replace chocolate with Nutella for a nuttier buttercream flavor.
            Store the cupcakes in an airtight container at room temperature for up to 3 days.
            """
        )
        saveRecipe(
            name: "Chocolate Mud Cake",
            prepTime: "20 minutes",
            cookingTime: "2 hours",
            ingredients: [
                "220g butter",
                "2 tbsp instant coffee powder",
                "220g dark chocolate, chopped",
                "160ml water",
                "125g plain flour",
                "125g self-raising flour",
                "50g cocoa powder",
                "480g caster sugar",
                "4 eggs, lightly beaten",
                "35ml vegetable oil",
                "100ml milk"
            ],
            prePrepInstructions: [
                "Preheat the oven to 140°C.",
                "Grease and line an 8\" (20cm) round or 7\" (17.5cm) square tin with baking paper. Ensure the paper forms a collar extending 2cm above the tin."
            ],
            instructions: [
                "In a saucepan over low heat, melt the butter, coffee powder, and water. Stir until combined, then remove from heat.",
                "Add the chopped dark chocolate to the saucepan and stir until completely melted.",
                "In a separate bowl or jug, whisk together the eggs, vegetable oil, and milk.",
                "In a large mixing bowl, sift together the plain flour, self-raising flour, cocoa powder, and caster sugar.",
                "Make a well in the center of the dry ingredients. Pour in the egg mixture, followed by the melted chocolate mixture. Mix by hand with a wooden spoon or silicone spatula until just combined.",
                "Pour the batter into the prepared tin. Use a flower nail at the bottom of the tin for even baking, if desired.",
                "Bake for approximately 2 hours or until a skewer inserted in the center comes out clean.",
                "Leave the cake to cool completely in the tin before removing."
            ],
            notes: """
            Mud cakes are dense and ideal for cake decorating due to their long shelf life.
            For even baking, use baking strips around the tin, place a flower nail in the bottom, and cover with a foil lid.
            Storage: Wrap the cooled cake twice in cling film and store at room temperature if using soon or in the fridge for up to 3 weeks.
            Freezing: Add a layer of foil over the cling film and freeze for up to 6 months. Defrost at room temperature while still wrapped.
            Recipe adapted from Planet Cake, Paris Cutler, Murdoch Books, 2009.
            """
        )
        saveRecipe(
            name: "Chocolate Mousse",
            prepTime: "15 minutes",
            cookingTime: "Chill for a minimum of 3 hours",
            ingredients: [
                "160 grams Dark Chocolate, melted",
                "Ice",
                "Cold water",
                "290 ml Double Cream",
                "3 Large Egg Whites",
                "50 grams granulated sugar (around 1 cup)",
                "Some Cocoa Powder for serving"
            ],
            prePrepInstructions: [
                "Melt 160 grams of dark chocolate and allow it to cool to room temperature.",
                "Prepare a bowl filled with ice and cold water, and place a smaller mixing bowl inside to keep cream chilled while whisking."
            ],
            instructions: [
                "Pour 290 ml of double cream into the chilled small mixing bowl and whisk until soft peaks form.",
                "In another mixing bowl, whisk 3 large egg whites and gradually add 50 grams of granulated sugar until fluffy, forming a foam-like consistency.",
                "Gently fold the room-temperature melted dark chocolate into the whisked egg whites until incorporated.",
                "Carefully fold the whipped cream into the chocolate and egg white mixture.",
                "Refrigerate the mousse for a minimum of 3 hours before serving.",
                "Sprinkle cocoa powder over the mousse when serving."
            ],
            notes: """
            For smaller servings:
            Use 106.67 grams of dark chocolate.
            Reduce double cream to 193.34 ml.
            Use 2 large egg whites and 33.34 grams (around ⅔ cup) of granulated sugar.
            """
        )
        saveRecipe(
            name: "Chocolate Kunafa",
            prepTime: "10 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "100g kunafa (shredded kataifi or phyllo dough), thawed (about 1 heaped cup)",
                "2 tablespoons butter, melted (30g)",
                "1/2 cup pistachio spread",
                "200g chocolate of choice (milk chocolate recommended), chopped into chunks or pieces (1 heaped cup)"
            ],
            prePrepInstructions: [
                "Thaw the kunafa dough if frozen and chop into 1/2 inch thick pieces.",
                "Line the basket of the air fryer with parchment paper or prepare a large skillet if using the stovetop."
            ],
            instructions: [
                "In a medium-sized bowl, mix the chopped kunafa with melted butter until well coated.",
                "Toast the kunafa: Either air fry at 350°F (180°C) for 10 minutes, stirring every few minutes, or toast in a large skillet over medium heat, stirring constantly, until golden brown.",
                "Transfer the toasted kunafa to a large bowl, add the pistachio spread, and stir well to combine. Set aside.",
                "Melt the chocolate: Place the chopped chocolate in a microwave-safe bowl and microwave for 30 seconds, stir, then continue in 10-second bursts until just melted. Stir to smooth out any remaining chunks.",
                "Line a 9×5 inch loaf pan with parchment paper, leaving an overhang for easy removal.",
                "Pour half the melted chocolate into the loaf pan and smooth it into an even layer. Place in the fridge to set for 5 minutes or until hardened.",
                "Spread the pistachio kunafa mixture evenly over the chocolate layer in the loaf pan.",
                "Pour the remaining melted chocolate on top, smoothing it out to cover the kunafa layer. Place in the fridge to set for another 5-10 minutes.",
                "Once set, remove from the loaf pan and break into pieces like chocolate bark. Serve immediately or store as needed."
            ],
            notes: """
            Ingredient Notes:
            Use any type of chocolate or a combination of chocolates for this recipe.
            Pistachio spread can be substituted with Lotus Biscoff Spread or homemade pistachio spread.

            Tips and Tricks:
            Keep an eye on the kunafa while toasting to ensure it doesn’t burn. It should be evenly golden brown.
            Melt the chocolate carefully to avoid burning; stop microwaving even if small chunks remain intact.
            Spread the chocolate evenly in the loaf pan for consistent thickness.
            Chocolate molds can be used for a prettier presentation. You can also drizzle white chocolate on top for decoration.

            Storage:
            Store leftover pieces in a tightly covered container in the fridge for up to 5-7 days.
            """
        )
        saveRecipe(
            name: "Chocolate Chip Oat Cookies",
            prepTime: "15 minutes",
            cookingTime: "20 minutes",
            ingredients: [
                "1/2 cup butter",
                "1/2 cup soft light brown sugar",
                "1/2 cup caster sugar",
                "1 cup plain flour",
                "1 1/4 cups oats",
                "1 egg",
                "1/2 tsp baking powder",
                "1/2 tsp bicarbonate of soda",
                "100g chocolate (any type you like)",
                "1 tsp vanilla extract"
            ],
            prePrepInstructions: [
                "Preheat the oven to 180°C and line two baking trays with baking paper."
            ],
            instructions: [
                "Cream the butter and sugars together until smooth.",
                "Add the egg and beat vigorously until combined.",
                "In a separate bowl, combine the plain flour, oats, baking powder, and bicarbonate of soda.",
                "Add the chocolate to the dry ingredients, then mix into the butter and egg mixture.",
                "Beat the mixture together until well combined.",
                "Roll the dough into 2cm balls and place on the prepared baking trays, spacing about 5cm apart.",
                "Bake in the preheated oven for 8-10 minutes.",
                "Remove the trays from the oven and let the cookies cool on the tray for 2 minutes before transferring to a cooling rack.",
                "Enjoy!"
            ],
            notes: """
            Use any chocolate of your choice, such as milk, dark, or white chocolate.
            The cookies can be stored in an airtight container for up to a week.
            """
        )
        saveRecipe(
            name: "Chow Mein (A Chinese Chef's Masterclass)",
            prepTime: "20 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "510g thick chow mein noodles",
                "56.7g red onion, sliced",
                "56.7g carrot, thinly sliced into strips",
                "170g cabbage, thinly sliced",
                "28.3g green onion, cut into 1-inch pieces",
                "113g bean sprouts",
                "340g chicken thigh, thinly sliced",
                "4 tbsp corn oil"
            ],
            prePrepInstructions: [
                "Prepare all vegetables by slicing into thin strips to match the shape of the noodles.",
                "Debone and thinly slice chicken thighs.",
                "Marinate chicken with 1 tbsp oyster sauce, 3 tsp cornstarch, 3 tbsp water, and 0.25 tsp white pepper."
            ],
            instructions: [
                "Create the sauce by combining 2 tbsp oyster sauce, 2 tbsp light soy sauce, 2 tsp dark soy sauce, 1 tsp sugar, 1 tsp chicken bouillon powder, and 1 tbsp sesame oil.",
                "Steam the noodles for 12-15 minutes over high heat, then boil for 5-6 minutes until cooked through. Drain and set aside.",
                "Add 1 tbsp oil to the marinated chicken and mix. Heat a wok over high heat until smoking, then add 2 tbsp oil. Stir-fry the chicken for 1-2 minutes until nearly cooked. Remove and set aside.",
                "Stir-fry red onion for 30 seconds, then add cabbage and carrots. Stir-fry for another 30 seconds and set aside.",
                "Add 1 tbsp oil to the wok, then pan-fry the noodles on high heat for 2 minutes on each side to develop golden-brown edges.",
                "Lower the heat and add the sauce to the noodles, stirring until evenly coated.",
                "Return the chicken and vegetables to the wok and stir-fry together for 1 minute.",
                "Add bean sprouts and stir-fry on high heat for 1 minute. Drizzle with sesame oil, stir, and serve immediately."
            ],
            notes: """
            Use a wok for the best results, but a large frying pan works too.
            Keep the wok hot and dry before adding oil to prevent noodles from sticking.
            To make vegetarian chow mein, substitute chicken with mushrooms or tofu and use vegetarian alternatives for oyster sauce and chicken bouillon.
            """
        )
        saveRecipe(
            name: "Citrus Bars",
            prepTime: "20 minutes",
            cookingTime: "35–45 minutes",
            ingredients: [
                "For the base:",
                "250g plain flour",
                "85g icing sugar, plus extra for dusting",
                "175g butter, cut into small pieces",
                "For the topping:",
                "2 lemons",
                "1 large orange",
                "4 large eggs",
                "400g caster sugar",
                "50g plain flour"
            ],
            prePrepInstructions: [
                "Heat the oven to 180°C (160°C fan/gas 4).",
                "Line the base and sides of a shallow rectangular tin (about 23 x 33cm) with baking parchment, snipping the corners to fit the sides."
            ],
            instructions: [
                "To prepare the base, tip the flour, sugar, and butter into a food processor and blend until fine crumbs form.",
                "Press the crumb mixture into the prepared tin, smoothing it with the back of a metal spoon.",
                "Bake the base for 20-25 minutes until pale golden. Remove and set aside.",
                "For the topping, finely grate the zest of the lemons and orange, then squeeze out their juice. Measure 120ml of juice.",
                "Using an electric whisk, whisk together the eggs and caster sugar for 1 minute. Add the citrus zest and juice, then whisk briefly.",
                "Sift in the flour and whisk until the mixture is smooth.",
                "Pour the topping over the baked base and return to the oven. Bake for 15-20 minutes until the topping is just set.",
                "Allow the bars to cool completely in the tin. Lift them out using the parchment paper.",
                "Dust the cooled bars thickly with icing sugar and cut into 18 pieces by slicing lengthwise into 3 rows and across into 6 columns."
            ],
            notes: """
            The bars are best stored in an airtight container and can last for up to 3 days.
            Make sure the citrus topping has just set before removing from the oven for a soft, slightly gooey texture.
            """
        )
        saveRecipe(
            name: "Classic Victoria Sponge",
            prepTime: "40 minutes",
            cookingTime: "30–35 minutes",
            ingredients: [
                "For the cake:",
                "2 tsp baking powder",
                "2 tsp bicarbonate of soda",
                "1 ½ tsp salt",
                "3 tbsp vanilla extract",
                "2 tsp apple cider vinegar",
                "550g plain flour",
                "350g golden caster sugar",
                "150ml light olive oil",
                "400ml plant-based milk",
                "For the buttercream and filling:",
                "2 tsp vanilla paste or extract",
                "5 tbsp raspberry jam",
                "75g plant-based shortening (aka Trex)",
                "300g icing sugar",
                "Large pinch sea salt",
                "To serve:",
                "50g raspberries",
                "Icing sugar to dust",
                "75g plant-based butter"
            ],
            prePrepInstructions: [
                "Preheat the oven to 180°C.",
                "Line 2 x 20cm cake tins with parchment paper.",
                "Prepare a cooling rack and stand mixer or electric hand-held beaters."
            ],
            instructions: [
                "For the cake batter, mix the flour, sugar, baking powder, bicarbonate of soda, and salt in a bowl.",
                "In a separate bowl, mix the oil, milk, vanilla extract, and vinegar.",
                "Combine the wet ingredients with the dry ingredients and mix well.",
                "Divide the batter evenly between the two prepared cake tins.",
                "Bake in the oven for 30–35 minutes, or until a skewer inserted into the center comes out clean.",
                "Cool the cakes in the tins on a cooling rack until they reach room temperature.",
                "To make the buttercream, beat the dairy-free butter and vegetable shortening until smooth.",
                "Gradually add the icing sugar while continuing to beat.",
                "Mix in the vanilla paste and salt, then refrigerate the buttercream to chill.",
                "To assemble, level the top of one cake with a knife to create a flat surface.",
                "Place the levelled cake on a serving plate and spread a thick layer of buttercream over the top.",
                "Spoon the raspberry jam over the buttercream layer.",
                "Place the second cake on top and dust with icing sugar.",
                "Decorate with raspberries, cut into slices, and serve."
            ],
            notes: """
            For best results, ensure the cakes are completely cooled before assembling to prevent the buttercream from melting.
            Store the cake in an airtight container for up to 3 days at room temperature or refrigerate for longer freshness.
            You can substitute raspberry jam with strawberry jam or another fruit jam of choice.
            """
        )
        saveRecipe(
            name: "Clay Pot Rice (煲仔飯)",
            prepTime: "20 minutes",
            cookingTime: "35 minutes",
            ingredients: [
                "Main Ingredients:",
                "283g (10 oz) long grain rice (such as Thai jasmine, or your preferred long grain rice)",
                "2 links Chinese sausage",
                "28.3g (1 oz) dried shiitake mushroom",
                "1 piece chicken breast",
                "1 piece bone-in chicken thigh",
                "1 shallot",
                "1 tbsp ginger",
                "2 stalks scallions",
                "Chicken Marinade:",
                "1 tbsp Kikkoman® Soy Sauce",
                "2 tbsp Kikkoman® Oyster Sauce",
                "0.50 tsp salt",
                "1 tsp sugar",
                "1 tbsp cornstarch",
                "3 tbsp water",
                "1 tsp cooking wine",
                "0.25 tsp white pepper",
                "1 tbsp oil",
                "1 tbsp Kikkoman® Sesame Oil",
                "Shiitake Mushroom Marinade:",
                "0.50 tbsp Kikkoman® Oyster Sauce",
                "1 tsp sugar",
                "0.50 tsp cornstarch",
                "Serving Sauce:",
                "1 tbsp Kikkoman® Oyster Sauce",
                "1 tsp Kikkoman® Soy Sauce",
                "1 tsp Kikkoman® Tamari Soy Sauce",
                "1 tsp sugar",
                "Cooking Ingredients:",
                "1 tsp oil",
                "11 oz boiling water",
                "2 tbsp oil"
            ],
            prePrepInstructions: [
                "Wash the rice three times to remove excess starch and soak in boiling water for 10 minutes.",
                "Rinse the Chinese sausage in boiling water to remove any debris.",
                "Rehydrate the dried shiitake mushrooms in boiling water for about 10 minutes until soft.",
                "Cut the chicken thigh and breast into small pieces, rinsing the thigh pieces to remove any bone shards.",
                "Mince the shallot, ginger, and scallions. Keep scallions separate for garnish."
            ],
            instructions: [
                "Combine chicken marinade ingredients and mix with the chicken. Add minced shallot and ginger to marinate.",
                "Mix the mushroom marinade ingredients with the rehydrated shiitake mushrooms.",
                "Prepare the sauce by mixing the serving sauce ingredients in a small bowl.",
                "In a clay pot, add the soaked rice (without soaking liquid), 1 tsp oil, and 312 g boiling water. Stir to combine.",
                "Cook rice over medium heat until water starts to boil, then layer chicken, mushrooms, and sausages evenly on top.",
                "Reduce heat to low and cook for another 5-10 minutes until you hear crackling sounds.",
                "Increase heat to medium and scorch the rice by tilting the clay pot to expose sides to the flame for 2 minutes on each side. Spoon 2 tbsp oil around the lid edge to seep into the pot and cook for an additional 2 minutes.",
                "Turn off heat, add diced green onions as garnish, and serve with prepared sauce poured over the rice."
            ],
            notes: """
            Use Thai jasmine rice or any preferred long-grain rice for authentic results.
            The clay pot stays hot for a long time; handle carefully to avoid burns.
            For an aromatic crust, be patient with the scorching process, but avoid burning the rice.
            If you don't have a clay pot, a stainless steel or non-stick pot can work, but the aroma and texture may differ.
            Leftovers can be stored in the fridge and reheated, but the crispy rice texture may not retain fully.
            """
        )
        saveRecipe(
            name: "Coconut Mochi (糯米滋, Lo Mai Chi)",
            prepTime: "40 minutes",
            cookingTime: "25 minutes",
            ingredients: [
                "120 g (1 cup + 2 tablespoons) glutinous rice flour",
                "3 tablespoons (30 g) cornstarch",
                "50 g (1/4 cup) white sugar",
                "1 cup coconut milk (or other plant milk)",
                "28 g (2 tablespoons) coconut oil (or butter)",
                "200 g (3/4 cup) red bean paste",
                "1/2 cup coconut, shredded"
            ],
            prePrepInstructions: [
                "Sift the glutinous rice flour, cornstarch, and sugar into a bowl.",
                "Drizzle coconut milk while stirring until the batter is smooth. Run through a sieve multiple times to remove clumps.",
                "Divide red bean paste into 10 portions and shape into balls."
            ],
            instructions: [
                "Steam the batter for 25 minutes over medium-high heat.",
                "Add coconut oil to the steamed dough and fold until incorporated.",
                "Cool dough for 20 minutes in the fridge, then divide into 10 portions.",
                "Flatten each dough portion into a disk, wrap around red bean paste, and seal.",
                "Roll completed mochi in shredded coconut.",
                "Serve immediately or store in the fridge for 3-4 days."
            ],
            notes: """
            Cover the steamer with a towel to prevent water droplets from falling onto the dough.
            Handle the dough gently to avoid over-kneading for softer texture.
            Heat treat flour to make it safe for consumption.
            For chewy texture, beat the dough with a wooden spatula before folding.
            """
        )
        saveRecipe(
            name: "Congee (Ninja Foodi)",
            prepTime: "5 minutes",
            cookingTime: "10 minutes (natural release)",
            ingredients: [
                "1 ½ cup boiled rice",
                "1 tsp chopped ginger",
                "1.5L stock liquid",
                "Sesame oil (for garnish)",
                "Chopped spring onions (for garnish)",
                "White pepper (for garnish)",
                "Optional: cubed swede"
            ],
            prePrepInstructions: [
                "Boil rice if not already prepared.",
                "Chop ginger and optional cubed swede."
            ],
            instructions: [
                "Add boiled rice, chopped ginger, stock liquid, and optional swede into the Ninja Foodi.",
                "Cook under pressure for 10 minutes with natural release.",
                "Stir thoroughly to prevent sticking.",
                "Serve in bowls, garnished with sesame oil, white pepper, and chopped spring onions."
            ],
            notes: """
            Ensure the rice is pre-cooked for smooth consistency.
            Stirring after cooking prevents clumps at the bottom.
            Use vegetable or chicken stock for enhanced flavor.
            """
        )
        saveRecipe(
            name: "Cookie Dough (Edible)",
            prepTime: "15 minutes",
            cookingTime: "7 minutes (heat-treating flour)",
            ingredients: [
                "1 cup (136g) all-purpose flour, heat-treated",
                "1/2 cup (113g) unsalted butter, softened",
                "1/2 cup (110g) packed light brown sugar",
                "3 Tbsp (40g) granulated sugar",
                "1/4 tsp salt",
                "1 1/2 Tbsp milk (plus more if needed)",
                "1/2 tsp vanilla extract",
                "1/2 cup (82g) mini semi-sweet chocolate chips"
            ],
            prePrepInstructions: [
                "Heat-treat flour by baking at 177°C for 7 minutes until it registers 160°F on a thermometer.",
                "Cool heat-treated flour completely."
            ],
            instructions: [
                "Cream butter, brown sugar, granulated sugar, and salt until light and fluffy.",
                "Mix in milk and vanilla extract.",
                "Blend in heat-treated flour until combined, adding more milk if needed.",
                "Fold in chocolate chips.",
                "Store in the refrigerator until ready to serve."
            ],
            notes: """
            Heat-treated flour ensures the dough is safe for consumption.
            The cookie dough will harden in the fridge; let it rest at room temperature before serving.
            For variations: replace part of the flour with cocoa powder for chocolate dough or add sprinkles for Funfetti dough.
            """
        )
        saveRecipe(
            name: "Coriander Chickpea Bowl",
            prepTime: "25 minutes",
            cookingTime: "20 minutes",
            ingredients: [
                "2 tbsp olive oil (for broccoli)",
                "1 head of broccoli",
                "1 tsp fennel seeds",
                "½ tsp mustard powder",
                "50g fresh coriander",
                "150g spinach",
                "200g silken tofu",
                "½ tbsp white miso paste",
                "1 tbsp tamari",
                "1 lime",
                "1 onion",
                "1 leek",
                "2 cloves of garlic",
                "15g fresh ginger",
                "½ tsp chilli flakes",
                "2 400g tins of chickpeas",
                "Olive oil for drizzling",
                "Salt and pepper to taste",
                "Coconut yoghurt (to serve)",
                "Chilli flakes (to serve)",
                "Flatbread (to serve)"
            ],
            prePrepInstructions: [
                "Preheat oven to 220°C fan and line a baking tray with baking paper.",
                "Slice broccoli into small florets.",
                "Juice the lime and drain the silken tofu.",
                "Dice the onion and finely slice the leek.",
                "Peel and grate garlic and ginger.",
                "Drain the chickpeas."
            ],
            instructions: [
                "Arrange the broccoli florets on the lined baking tray, drizzle with olive oil, fennel seeds, mustard powder, and season with salt and pepper. Roast for 8-10 minutes until cooked and lightly charred.",
                "In a blender, combine the coriander leaves (saving a few for garnish), half of the spinach, miso paste, tamari, lime juice, and silken tofu. Blend until smooth and set aside.",
                "Heat a drizzle of oil in a large frying pan over low heat. Add diced onion, grated garlic, grated ginger, and chopped coriander stems. Cook for around 5 minutes until softened.",
                "Add the chickpeas, sliced leek, coconut cream, and remaining spinach to the pan. Stir until the spinach wilts.",
                "Mix the coriander cream into the chickpea mixture in the pan. Warm everything together and adjust seasoning to taste.",
                "Spoon the chickpea mixture into bowls. Top with the roasted broccoli, coconut yoghurt, and chilli flakes.",
                "Serve with flatbread."
            ],
            notes: """
            Save some coriander leaves for garnishing the finished dish.
            Adjust chilli flakes based on spice preference.
            The dish can be stored in an airtight container for up to 3 days.
            """
        )
        saveRecipe(
            name: "Cream Cheese Dip (Light and Tasty)",
            prepTime: "4 minutes",
            cookingTime: "N/A",
            ingredients: [
                "1 tablespoon low-fat cream cheese",
                "3 tablespoons low-fat yogurt (fat-free might work, too, 0.3%)",
                "1/8 teaspoon garlic powder",
                "1/8 teaspoon rosemary, dried and crushed",
                "1/8 teaspoon chili powder",
                "1/8 teaspoon dill weed, dried",
                "1/8 teaspoon mixed Italian herbs, dried",
                "1 pinch salt (to taste)",
                "1/16 teaspoon hot red pepper flakes (more to taste)",
                "Black pepper (to taste)"
            ],
            prePrepInstructions: [
                "Ensure all ingredients are at room temperature for easier mixing."
            ],
            instructions: [
                "In a medium bowl, combine cream cheese and yogurt. Mix until well blended and no longer lumpy.",
                "Add garlic powder, rosemary, chili powder, dill weed, mixed Italian herbs, salt, hot red pepper flakes, and black pepper.",
                "Stir thoroughly to combine.",
                "Taste and adjust seasoning to your liking."
            ],
            notes: """
            For a spicier dip, increase the amount of red pepper flakes.
            This dip pairs well with vegetable sticks, crackers, or as a spread on bread.
            Leftovers can be stored in an airtight container in the fridge for up to 3 days.
            """
        )
        saveRecipe(
            name: "Crispy Bing Bread (家常饼)",
            prepTime: "2 hours",
            cookingTime: "30 minutes",
            ingredients: [
                "500 grams all-purpose flour",
                "1 cup boiling water",
                "1/2 cup room temperature water",
                "4 tablespoons peanut oil (or lard or chicken grease)",
                "1 1/2 teaspoons salt"
            ],
            prePrepInstructions: [
                "Prepare a clean working surface and utensils.",
                "Measure out all ingredients accurately."
            ],
            instructions: [
                "Add flour into a large bowl. Slowly add boiling water, mixing with chopsticks or a spatula until absorbed.",
                "Gradually add room temperature water and mix until no dry flour remains.",
                "Dust hands with flour and knead the mixture until dough forms. Knead for another 5 minutes on a floured surface.",
                "Place dough back in the bowl, cover with a wet kitchen towel, and let rest for 1 hour.",
                "Divide dough into 8 equal pieces. Roll each piece into a thin rectangular sheet and brush with oil. Sprinkle salt evenly on top.",
                "Fold dough accordion-style, then roll into a snail-shell shape. Press into a disk about 0.6mm thick before cooking.",
                "Heat oil in a nonstick skillet over medium heat. Grill each disk for about 2 minutes per side until golden brown.",
                "Serve warm as a side."
            ],
            notes: """
            For fluffier, crispier bread, work with a slightly wetter dough and grease the surface with oil instead of flour during rolling.
            Store leftovers in an airtight container in the fridge for up to 3 days, or freeze for up to a month.
            Reheat in a skillet with a tablespoon of water to preserve moisture.
            """
        )
        saveRecipe(
            name: "Custard Buns (Steamed) (Nai Wong Bao, 奶黄包)",
            prepTime: "30 minutes",
            cookingTime: "8 minutes",
            ingredients: [
                "3 yolks of hard-boiled eggs (or cooked salted duck egg yolks, see note 1)",
                "50 g unsalted butter, softened",
                "30 g sugar (or 40 g if using salted egg yolks)",
                "30 g full-fat milk powder (see note 2 for substitutes)",
                "175 g bao flour/cake flour (or all-purpose flour, see note 3)",
                "1 teaspoon instant dry yeast (see note 4)",
                "1 teaspoon baking powder",
                "1 tablespoon sugar",
                "1 tablespoon neutral cooking oil",
                "90 g lukewarm water (see note 5)"
            ],
            prePrepInstructions: [
                "Cook the egg yolks if using salted duck eggs: Boil or steam for 8 minutes as per note 1.",
                "Ensure butter is softened for the filling.",
                "Prepare steaming equipment and line steamer basket with parchment paper or cupcake molds."
            ],
            instructions: [
                "Mash the yolks to a fine texture while still warm. Mix with sugar, butter, and milk powder until a smooth paste forms. Refrigerate to harden slightly.",
                "For the dough, mix flour, yeast, baking powder, sugar, and oil in a bowl. Gradually add water and combine to form a rough dough. Knead until smooth.",
                "Divide the dough into 8 equal parts. Roll each piece into a disc, thinner on the edges and thicker in the center.",
                "Place a spoonful of filling in the center of each wrapper. Seal the buns completely using your preferred method.",
                "With the sealed side down, place the buns in the steamer basket and rest for 30 minutes until light and plump.",
                "Steam buns over medium-high heat for 8 minutes. Serve warm."
            ],
            notes: """
            To cook salted duck egg yolks: Boil in the shell for 8 minutes or steam for the same duration.
            Milk powder can be replaced with custard powder containing egg and milk, but not cornstarch-based powders like Bird’s custard powder.
            Use low gluten flour like bao or cake flour for a softer texture, or all-purpose flour as an alternative.
            Instant dry yeast can be added directly to the flour, while active dry yeast should be dissolved in water first.
            Adjust water quantity slightly depending on the flour type to achieve a soft but not sticky dough.
            Store cooked buns in the freezer for up to 3 months. Reheat by steaming for 3 minutes after defrosting, or 6 minutes directly from frozen.
            """
        )
        saveRecipe(
            name: "Eggless Chocolate Chip Cookies",
            prepTime: "10 minutes",
            cookingTime: "12-15 minutes",
            ingredients: [
                "114 grams salted butter, softened",
                "50 grams white sugar",
                "150 grams brown sugar, lightly packed",
                "59 ml water, room temperature",
                "2 teaspoons vanilla extract",
                "219 grams all-purpose flour, spooned and leveled",
                "¾ teaspoon baking soda",
                "¼ teaspoon baking powder",
                "½ teaspoon salt",
                "224 grams chocolate chips (½ cup dark and ½ cup semi-sweet)"
            ],
            prePrepInstructions: [
                "Ensure butter is softened.",
                "Line a baking sheet with parchment paper."
            ],
            instructions: [
                "Cream together softened butter and sugars for several minutes until light and fluffy, scraping down the sides.",
                "Gradually add in water and vanilla extract and beat to combine. The mixture may appear curdled; continue mixing on medium-high to bring it back together.",
                "In a separate mixing bowl, combine dry ingredients: flour, baking soda, baking powder, and salt.",
                "Stir the dry ingredients into the wet mixture, then fold in the chocolate chips.",
                "Chill the cookie dough in the fridge for 30 minutes or more.",
                "Use a cookie scoop or spoon to portion out dough into 2-inch balls.",
                "Place cookie dough balls on the prepared baking sheet and bake at 350°F (175°C) on the center rack for about 12 minutes, until the edges are golden brown.",
                "Let the cookies cool for 5 minutes to set before transferring them to a wire rack."
            ],
            notes: """
            The water in the recipe will initially make the mixture appear curdled, but mixing thoroughly will resolve this.
            Chilling the dough helps to enhance flavor and prevent spreading during baking.
            The cookie centers may appear under-baked when removed from the oven but will set as they cool.
            Store baked cookies in an airtight container for up to 5 days.
            """
        )
        saveRecipe(
            name: "Eggless Gelatin Free Double Chocolate Mousse Cake with Mirror Glaze",
            prepTime: "10 minutes",
            cookingTime: "35-45 minutes for cake, 5-6 hours chilling time",
            ingredients: [
                "For White Chocolate Mousse:",
                "1/2 + 1/2 + 1/4 cup heavy cream (dairy or non-dairy)",
                "100 g white chocolate",
                "1 tsp vegetable gelatin (agar agar)",
                "",
                "For Dark Chocolate Mousse:",
                "1/2 + 1/2 + 1/4 cup heavy cream (dairy or non-dairy)",
                "100 g dark chocolate",
                "1 tsp vegetable gelatin (agar agar)",
                "",
                "For Chocolate Cake:",
                "1 cup all-purpose flour (maida)",
                "1/2 tsp baking powder",
                "1 tsp baking soda",
                "4 1/2 tbsp cocoa powder",
                "3/4 cup sugar",
                "1/2 cup milk",
                "1/2 cup oil",
                "1/2 cup curd",
                "1/4 cup unsweetened hot coffee",
                "1 tsp vanilla extract",
                "",
                "For Mirror Glaze:",
                "80 g water",
                "120 g sugar",
                "140 g dark chocolate",
                "80 g condensed milk",
                "1/4 tsp vanilla extract",
                "1/2 tsp vegetable gelatin (agar agar)",
                "20 g cocoa powder",
                "3 tbsp water (for blooming gelatin)"
            ],
            prePrepInstructions: [
                "Prepare cling film to line 7-inch cake tins for mousse layers.",
                "Preheat oven to 180°C for cake baking.",
                "Prepare 7-inch pans by greasing and dusting with flour."
            ],
            instructions: [
                "Mix 1/4 cup cream with gelatin and let bloom for 5 minutes.",
                "Heat 1/2 cup cream with white chocolate until smooth.",
                "Mix bloomed gelatin into chocolate mixture. Cool.",
                "Whip remaining 1/2 cup cream to stiff peaks. Fold into chocolate mixture.",
                "Pour into prepared tin, freeze for 5-6 hours.",
                "Follow the same process for the dark chocolate mousse using dark chocolate.",
                "Mix dry ingredients: flour, sugar, cocoa powder, baking powder, and baking soda.",
                "Combine wet ingredients: oil, curd, milk, vanilla, and coffee.",
                "Add wet ingredients to dry ingredients and mix until combined.",
                "Divide batter into prepared pans. Bake for 35-45 minutes or until a skewer comes out clean.",
                "Cool cakes on a wire rack, then wrap in cling film and freeze until assembly.",
                "Bloom gelatin in 3 tbsp water for 5 minutes.",
                "Heat water, sugar, and condensed milk until boiling. Stir in gelatin until dissolved.",
                "Pour hot mixture over chocolate and cocoa powder. Blend until smooth.",
                "Cool glaze to 32°C before using.",
                "Place one cake layer on a cake board and soak with simple syrup.",
                "Spread a thin layer of whipped cream and place white chocolate mousse layer on top.",
                "Add another thin layer of cream and top with dark chocolate mousse layer.",
                "Frost entire cake with whipped cream. Freeze for 5-6 hours.",
                "Pour mirror glaze over the frozen cake, smoothing sides with a spatula.",
                "Decorate as desired and freeze for 2 hours before serving."
            ],
            notes: """
            Agar agar is used instead of gelatin for a vegetarian option.
            Ensure mousse layers are completely frozen before assembling the cake.
            Glaze the cake while it is frozen for best results.
            Store leftover cake in the fridge for up to 3 days or freeze for longer storage.
            """
        )
        saveRecipe(
            name: "Egg Fried Rice",
            prepTime: "5 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "397 g uncooked jasmine rice",
                "397 g water",
                "28.3 g green onion (green parts only)",
                "56.7 g carrot",
                "113 g frozen corn and peas",
                "4 large eggs",
                "0.5 tsp salt",
                "71 ml water",
                "2 tbsp oil",
                "Rice Seasoning:",
                "1 tbsp light soy sauce",
                "1 tsp dark soy sauce",
                "0.5 tsp salt",
                "0.5 tsp sugar",
                "1 tsp chicken bouillon powder (optional)",
                "1 tbsp oil"
            ],
            prePrepInstructions: [
                "Wash rice three times to remove excess starch and drain thoroughly.",
                "Cook rice in a rice cooker following the manufacturer's instructions.",
                "Dice green onions (green parts only) and carrots into small pieces.",
                "Combine carrots with frozen corn and peas in a bowl.",
                "Crack eggs into a bowl and season with 0.5 tsp salt."
            ],
            instructions: [
                "Microwave the mixed vegetables with 71 ml water for 2 minutes, then drain excess water.",
                "Fluff cooked rice with chopsticks for 1 to 2 minutes to release excess steam and prevent clumping.",
                "Heat a wok on high heat, then reduce to low. Add 2 tbsp oil to coat the wok surface.",
                "Beat eggs and pour into the wok, cooking gently for 20-30 seconds.",
                "Add fluffed rice on top of the eggs. Stir fry constantly, breaking clumps of rice and eggs with a spatula for 2 minutes.",
                "Add microwaved veggies, increase heat to high, and stir fry for 2-3 minutes.",
                "Lower heat to low, then add the seasoning mix (light soy sauce, dark soy sauce, salt, sugar, chicken bouillon powder) and mix well.",
                "Increase heat to high again, stir fry for another 2-3 minutes. Add 1 tbsp oil and diced green onions, stir fry for 1 minute, then turn off the heat.",
                "Taste and adjust seasoning if needed."
            ],
            notes: """
            Fluff the rice immediately after cooking to prevent clumping.
            For additional flavor, add 1 tsp light soy sauce just before plating.
            Use the bowl method to create a visually appealing presentation by compressing rice in a bowl and flipping it onto a plate.
            """
        )
        saveRecipe(
            name: "Ermine Frosting",
            prepTime: "10 minutes",
            cookingTime: "30 minutes",
            ingredients: [
                "278 g granulated sugar",
                "59.5 g all-purpose flour",
                "317.8 g whole milk",
                "317.8 g unsalted butter, room temperature",
                "1.4 tsp vanilla extract",
                "0.17 tsp salt"
            ],
            prePrepInstructions: [
                "Ensure the butter is softened to room temperature before starting.",
                "Prepare a heat-proof bowl and plastic wrap for chilling the flour mixture."
            ],
            instructions: [
                "Whisk together flour and sugar in a medium saucepan over medium heat. Toast for 2 minutes, stirring constantly, being careful not to burn the mixture.",
                "Gradually add the milk, whisking continuously to combine. Bring the mixture to a simmer over medium-high heat, whisking until it thickens to a pudding-like consistency. Simmer for an additional minute.",
                "Optional: Strain the mixture through a colander into a heat-proof bowl to remove any lumps.",
                "Cover the surface of the mixture with plastic wrap, ensuring it touches the surface to prevent a skin from forming. Chill in the refrigerator for several hours or overnight. For faster cooling, spread the mixture onto a sheet pan, cover with plastic wrap, and freeze for 30 minutes.",
                "Once the mixture is completely cool, whip the softened butter in a stand mixer on high until light and fluffy, about 2-3 minutes.",
                "Pipe the cooled flour mixture slowly into the whipped butter while continuing to whip. This ensures a smooth buttercream.",
                "Add vanilla extract and salt, then mix until creamy. Use immediately to frost cooled cakes."
            ],
            notes: """
            To make chocolate ermine frosting, whip in 1/4 cup sifted cocoa powder after the frosting is fluffy.
            Ensure the flour mixture is completely cool before incorporating it into the butter to prevent melting.
            Ermine frosting sets quickly and is best used immediately after preparation. It does not store well overnight.
            This frosting is not ideal for use under fondant but works well as a filling between cake layers.
            """
        )
        saveRecipe(
            name: "Espresso Brown Butter Chocolate Chip Cookies",
            prepTime: "10 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "50 g butter",
                "65 g brown sugar",
                "3/4 tsp espresso powder or 1 tsp coffee powder",
                "35 g granulated sugar",
                "1/4 tsp salt",
                "25 g egg (~1/2 egg)",
                "1/8 tsp cream of tartar",
                "1/4 tsp baking soda",
                "75 g bread flour",
                "~30 g chocolate bar, chopped",
                "Flaky salt (optional)"
            ],
            prePrepInstructions: [
                "Prepare plastic wrap and a baking sheet for chilling and baking the cookies."
            ],
            instructions: [
                "Brown the butter in a pan over medium-high heat, stirring occasionally until it turns honey-colored and fragrant. Remove from heat.",
                "Dissolve espresso or coffee powder into the browned butter, followed by granulated sugar, brown sugar, and salt. Allow the mixture to cool slightly before adding the egg.",
                "Beat the egg into the butter mixture until light and fluffy.",
                "Combine chocolate chips, cream of tartar, baking soda, and bread flour. Fold this dry mixture into the butter mixture.",
                "Scoop the cookie dough into balls and place them on the plastic-lined plate. Chill uncovered in the fridge overnight or for up to two days.",
                "Preheat the oven to 350°F (180°C). Line a baking sheet with parchment paper.",
                "Space the chilled cookie dough balls evenly on the baking sheet and bake for about 15 minutes, or until the centers are just set. Flatten the cookies midway through baking to create ripples by lifting and dropping the baking sheet.",
                "Let the cookies cool on the baking sheet for 5 minutes before transferring them to a cooling rack. Sprinkle with flaky salt and enjoy."
            ],
            notes: """
            Chilling the dough for at least 2 days develops the best flavor and reduces spreading.
            If short on time, a 30-minute chill can work, but the cookies may spread more.
            For optimal ripples, flatten the cookies while baking by lifting and dropping the sheet.
            """
        )
        saveRecipe(
            name: "Ground Beef Fajitas",
            prepTime: "12 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "1 lb lean ground beef",
                "1 can (127 ml) chopped green chilies (optional)",
                "1/2 large green bell pepper, cut into 1/2-inch slices",
                "1/2 large red bell pepper, cut into 1/2-inch slices",
                "1/2 large yellow bell pepper, cut into 1/2-inch slices",
                "1/2 large red onion, cut into 1/2-inch slices",
                "8 flour tortillas",
                "Optional toppings: sour cream, salsa, cheese, avocado slices, guacamole, sliced jalapeños, lime wedges, chopped cilantro"
            ],
            prePrepInstructions: [
                "Prepare fajita seasoning by mixing: 1 tbsp chili powder, 1 tsp smoked paprika, 1 tsp cumin, 1/2 tsp garlic powder, 1/2 tsp kosher salt, 1/4 tsp onion powder, 1/8 tsp ground cayenne pepper."
            ],
            instructions: [
                "Heat a skillet over medium heat and add the ground beef with fajita seasoning. Brown the beef, breaking it apart into smaller pieces while cooking. Stir in green chilies, if using, and set aside once cooked.",
                "In a second skillet, heat oil over high heat. Add the bell peppers and onions, sautéing until softened and slightly charred.",
                "Warm the tortillas and serve with the cooked ground beef, peppers, onions, and your choice of toppings."
            ],
            notes: """
            Avoid overcooking the ground beef to prevent it from becoming tough.
            Use a hot skillet to quickly char the peppers and onions without overcooking.
            If sensitive to spice, omit green chilies and reduce fajita seasoning, adding more to taste after cooking.
            """
        )
        saveRecipe(
            name: "Hotteok (Sweet Korean Pancakes)",
            prepTime: "15 minutes",
            cookingTime: "3-4 minutes per pancake",
            ingredients: [
                "2 tsp instant yeast",
                "3/4 cup lukewarm water",
                "1/2 cup lukewarm whole milk",
                "1 1/2 tbsp white sugar",
                "1 tsp salt",
                "2 1/3 cups all-purpose flour",
                "1/3 cup mochiko flour (sweet rice flour)",
                "1 tbsp unsalted butter, melted",
                "For filling: 1/2 cup brown sugar, 2 tsp cinnamon, 1/4 cup chopped peanuts (optional)"
            ],
            prePrepInstructions: [
                "Prepare a warm place for the dough to rise.",
                "Set aside the filling ingredients in a bowl, mixed and ready."
            ],
            instructions: [
                "Dissolve yeast, sugar, and salt in lukewarm water and milk. Gradually add all-purpose flour and mochiko flour, mixing to form a dough.",
                "Add melted butter and knead for 5-7 minutes until smooth. Cover the bowl and let the dough rise in a warm place until doubled in size.",
                "Punch down the risen dough and divide it into 8 equal pieces. Flatten each piece into a disk and place 1-2 tbsp of filling in the center. Pinch the edges to seal.",
                "Heat oil in a skillet over medium heat. Flatten each filled dough ball slightly in the skillet and cook for 3-4 minutes per side until golden brown.",
                "Serve warm."
            ],
            notes: """
            Ensure the liquid for the dough is lukewarm to activate the yeast effectively.
            Avoid overstuffing the pancakes to prevent the filling from leaking.
            These pancakes are best enjoyed fresh but can be reheated in a skillet or microwave.
            """
        )
        saveRecipe(
            name: "Ferrero Rocher Milkshake",
            prepTime: "5 minutes",
            cookingTime: "0 minutes",
            ingredients: [
                "1 tbsp Nutella per person",
                "1 tbsp crunchy peanut butter per person",
                "100 ml milk per person",
                "1.5 scoops vanilla ice cream per person"
            ],
            prePrepInstructions: [
                "Ensure all ingredients are measured for each serving."
            ],
            instructions: [
                "Add Nutella, peanut butter, milk, and vanilla ice cream to a blender.",
                "Blend until smooth and creamy."
            ],
            notes: """
            Serve immediately for the best texture.
            Adjust the amount of Nutella and peanut butter to suit personal taste.
            """
        )
        saveRecipe(
            name: "Easy 15-Minute Fish Ball Noodle Soup",
            prepTime: "5 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "10 pieces store-bought fish balls (or desired amount)",
                "1,000 g udon noodles (reduce to 2 servings if preferred)",
                "1 green onion, finely sliced (optional garnish)",
                "2-3 cups bok choy, sliced in half",
                "1 cup bean sprouts, rinsed",
                "150 g seafood mushrooms, ends trimmed, washed, and divided",
                "Soup Base:",
                "2 cups chicken broth (low sodium)",
                "2 cups cold water",
                "0.5 tbsp regular soy sauce",
                "2 tbsp oyster sauce",
                "1 tsp mirin",
                "0.5 tsp sesame oil",
                "1 tsp garlic, minced",
                "1 stalk green onion, finely sliced"
            ],
            prePrepInstructions: [
                "Rinse and trim vegetables and mushrooms.",
                "Prepare the soup base ingredients."
            ],
            instructions: [
                "Boil water in a medium pot and blanch frozen udon noodles for 30 seconds until loosened. Drain and divide into serving bowls.",
                "In the same pot, add soup base ingredients and stir. Cover and bring to a boil.",
                "Add fish balls and boil for 5-8 minutes until they float.",
                "Blanch bok choy, seafood mushrooms, and bean sprouts in the soup until cooked.",
                "Divide vegetables, fish balls, and broth between bowls.",
                "Garnish with green onions (optional) and serve hot."
            ],
            notes: """
            Adjust the saltiness of the soup by adding 1 tablespoon more oyster sauce if desired.
            Avoid overcooking udon noodles to maintain texture.
            """
        )
        saveRecipe(
            name: "Fish Curry (Fish Masala)",
            prepTime: "5 minutes",
            cookingTime: "45 minutes",
            ingredients: [
                "Marinated Fish:",
                "1 tsp carom seeds (ajwain) – optional but recommended",
                "0.5 tsp red chili powder or cayenne pepper",
                "0.25 tsp turmeric powder",
                "0.75 tsp kosher salt",
                "1 lb firm-fleshed white fish (e.g., cod, halibut, or tilapia), patted dry and cut into 2-3\" pieces",
                "1 tsp lemon juice",
                "Fish Curry:",
                "0.33 cup + 2 tbsp avocado oil (or other neutral oil)",
                "2 medium yellow onions (~380 g), finely chopped",
                "7 garlic cloves, finely chopped",
                "1-inch piece ginger, finely chopped",
                "1 tsp coriander powder",
                "1 tsp cumin powder",
                "1 tsp Kashmiri chili powder (or paprika)",
                "0.5 tsp red chili powder (optional)",
                "0.5 tsp turmeric powder",
                "1.5 tsp kosher salt",
                "2 ripe tomatoes (~250 g, Roma/plum), finely chopped",
                "To Finish:",
                "3-5 Thai or bird's eye green chili peppers, whole or sliced vertically",
                "0.25 tsp freshly ground black pepper",
                "1-2 tbsp julienned ginger",
                "3 tbsp cilantro leaves, finely chopped",
                "1-2 tsp lemon juice"
            ],
            prePrepInstructions: [
                "Prepare fish marinade and set aside for at least 10 minutes.",
                "Chop vegetables and measure spices."
            ],
            instructions: [
                "Marinate fish with carom seeds, chili powder, turmeric, salt, and lemon juice.",
                "Heat 0.33 cup oil in a large pan over medium-high heat. Sauté onions until golden, about 18 minutes, deglazing with water as needed.",
                "Add garlic and ginger, sauté for 2 minutes, then add spices and stir to bloom flavors.",
                "Add chopped tomatoes and cook until they meld into the masala and oil separates.",
                "Add 1 cup water, bring to a simmer, and reduce heat to medium. Cover and cook while preparing the fish.",
                "Pan-fry fish in a nonstick skillet with 2 tbsp oil for 4 minutes per side until golden and cooked through.",
                "Uncover the curry, sauté out excess water, and add 0.25-0.5 cup water for desired consistency. Add cooked fish to the curry.",
                "Simmer on low for 2-3 minutes. Top with green chilies, black pepper, julienned ginger, cilantro, and lemon juice."
            ],
            notes: """
            Serve with naan, roti, or steamed rice.
            Adjust spice levels by reducing or omitting chili powder.
            For added depth, use ghee instead of oil during preparation.
            """
        )
        saveRecipe(
            name: "Garlic Butter (Simple)",
            prepTime: "10 minutes",
            cookingTime: "None",
            ingredients: [
                "120 g (8 tbsp) unsalted butter, softened",
                "1 tsp salt (use 0.5 tsp if using salted butter)",
                "3 cloves garlic, minced",
                "2 tsp dried parsley"
            ],
            prePrepInstructions: [],
            instructions: [
                "Mix butter, salt, garlic, and parsley in a bowl until combined.",
                "For storage, shape the butter into a sausage on clingfilm, roll tightly, and refrigerate until firm.",
                "Slice into discs when ready to serve."
            ],
            notes: """
            Use immediately if soft butter is needed, such as for spreading on bread.
            Store in the fridge for up to two weeks, covered.
            For variations, add chili flakes, curry powder, or cold-smoke the butter.
            """
        )
        saveRecipe(
            name: "Garlic Sesame Tofu",
            prepTime: "10 minutes",
            cookingTime: "30 minutes",
            ingredients: [
                "1 tbsp soy sauce or tamari",
                "1 block (14 oz) extra firm tofu",
                "1 tbsp corn starch",
                "3 tbsp breadcrumbs (use gluten-free if needed)",
                "Sauce:",
                "⅓ cup (8 ml) low sodium soy sauce or tamari",
                "2 tsp toasted sesame oil",
                "1 tbsp rice vinegar",
                "2-3 tbsp honey or maple syrup",
                "1 tbsp corn starch",
                "4 tbsp water, divided",
                "5 cloves garlic, minced",
                "1 tbsp olive oil"
            ],
            prePrepInstructions: [],
            instructions: [
                "Preheat the oven to 400°F (200°C).",
                "Drain tofu and pat dry. Cut into 1-inch cubes and toss with soy sauce, cornstarch, and breadcrumbs until coated.",
                "Bake tofu on a lined tray for 30-35 minutes until golden brown.",
                "Prepare the sauce by sautéing garlic in olive oil until fragrant. Add soy sauce, honey/maple syrup, rice vinegar, 2 tbsp water, and sesame oil.",
                "Mix 1 tbsp cornstarch with 2 tbsp water and whisk into the sauce. Heat until thickened.",
                "Toss baked tofu in the sauce and serve over rice or as desired."
            ],
            notes: """
            Pressing the tofu will make it crispier but is optional.
            Use low sodium soy sauce to avoid excessive saltiness.
            """
        )
        saveRecipe(
            name: "Goat & Bell Pepper Curry (Instant Pot)",
            prepTime: "30 minutes",
            cookingTime: "20 minutes",
            ingredients: [
                "1 medium onion, roughly chopped",
                "5 cloves garlic",
                "½ inch piece ginger",
                "2-3 tbsp neutral oil",
                "1 tbsp ghee",
                "1-1.3 lbs (~600 g) bone-in goat meat",
                "1 large tomato",
                "1 green chili pepper (e.g., Serrano)",
                "1 tbsp + 1 tsp apple cider vinegar",
                "1 tsp kosher salt",
                "½ tsp turmeric powder",
                "1 green bell pepper, cubed",
                "1 tsp freshly ground black pepper",
                "0.5-1 tsp chaat masala",
                "1 tsp lemon juice"
            ],
            prePrepInstructions: [
                "Finely chop onion, garlic, and ginger in a food processor.",
                "Chop tomato and green chili pepper."
            ],
            instructions: [
                "Set the Instant Pot to Sauté mode. Heat oil and ghee, then sauté onion mixture until golden.",
                "Add goat meat and sauté for 4-5 minutes until browned.",
                "Add tomato mixture, apple cider vinegar, salt, and turmeric powder. Mix well.",
                "Pressure cook on Meat/Stew mode for 25 minutes, then manually release pressure.",
                "Sauté the curry to evaporate moisture. Add bell pepper and sauté for 5 minutes.",
                "Mix in black pepper, chaat masala, and lemon juice. Serve with naan, roti, or rice."
            ],
            notes: """
            Cooking time may vary based on the cut of goat meat.
            Pressure cook for an additional 5 minutes if needed.
            """
        )
        print("Default recipes added!")
    }
}
