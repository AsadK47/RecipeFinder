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
                "Prepare fajita seasoning by mixing: ",
                "1 tbsp chili powder",
                "1 tsp smoked paprika", "1 tsp cumin",
                "1/2 tsp garlic powder",
                "1/2 tsp kosher salt",
                "1/4 tsp onion powder",
                "1/8 tsp ground cayenne pepper"
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
            prePrepInstructions: [
                "Drain tofu and pat dry.",
                "Cut tofu into 1-inch cubes."
            ],
            instructions: [
                "Preheat the oven to 400°F (200°C).",
                "Toss tofu cubes with soy sauce, cornstarch, and breadcrumbs until coated.",
                "Bake tofu on a lined tray for 30-35 minutes until golden brown.",
                "Prepare the sauce by sautéing garlic in olive oil until fragrant.",
                "Add soy sauce, honey/maple syrup, rice vinegar, 2 tbsp water, and sesame oil.",
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
        saveRecipe(
            name: "Gochujang Chilli Oil Noodles",
            prepTime: "5 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "1 tbsp toasted sesame seeds",
                "2 spring onions",
                "1 big garlic clove",
                "1 tsp chilli flakes",
                "½ tsp caster sugar",
                "1 tbsp rice wine vinegar",
                "2 tbsp gochujang paste",
                "1 tbsp peanut butter",
                "3 tbsp vegetable oil",
                "2 portions of udon noodles",
                "spring onion (to serve)",
                "roasted peanuts (to serve)",
                "edamame beans (to serve)"
            ],
            prePrepInstructions: [
                "Microplane or garlic crush",
                "Mortar and pestle",
                "Small saucepan",
                "Pan of boiling water"
            ],
            instructions: [
                "Slice the spring onions thinly and peel the garlic.",
                "In a small pan, toast the sesame seeds on a medium to low heat until fragrant.",
                "In a mortar and pestle, grind the sesame seeds until almost a powder.",
                "Grate the garlic and add to the sesame seeds, then add the chilli flakes, sugar, rice wine vinegar, gochujang, peanut butter and a pinch of salt.",
                "In a small saucepan, heat the oil until sizzling.",
                "Once hot, pour it into the mortar and carefully stir everything together so that you have a smooth sauce.",
                "Cook the noodles according to instructions on the pack.",
                "Transfer the cooked noodles to a bowl, then smother them in your sauce, add a generous splash of boiling water for extra creaminess.",
                "Stir through the sliced spring onions, saving some for garnish.",
                "Finish with chopped roasted peanuts, your reserved spring onions, and edamame if you like."
            ],
            notes: """
            Use fresh, high-quality gochujang paste for the best flavor.
            For a spicier dish, increase the amount of chili flakes.
            Edamame beans can be optional but they add extra texture and protein to the dish.
            """
        )
        saveRecipe(
            name: "Grass Jelly Brown Sugar Milk (Easy)",
            prepTime: "5 minutes",
            cookingTime: "5 minutes",
            ingredients: [
                "540 g canned grass jelly",
                "1000 ml milk or plant-based milk",
                "0.5 cup, 111 g brown sugar or coconut sugar",
                "0.5 cup, 125 ml cold water",
                "ice cubes"
            ],
            prePrepInstructions: [
                "Open your canned grass jelly and pop the jelly out onto a cutting board. Slice it into two halves.",
                "Slice one half of the portion into little cubes and the other half into medium size cubes for variety in texture."
            ],
            instructions: [
                "In a small saucepan, whisk brown sugar and cold water. Bring to a boil, then lower to a simmer to make a thick syrup.",
                "Take half of the brown sugar syrup and reserve the other half to garnish the glasses.",
                "Divide the half portion of syrup between the two bowls of grass jelly cubes and gently mix.",
                "In tall glasses, layer a variety of the grass jelly cubes, followed by 3-5 ice cubes, then more jelly cubes.",
                "Spoon and pour the reserved syrup along the walls of the glass to create a marble effect.",
                "Add more grass jelly, then pour 1 cup of milk per glass over the jelly and ice. Serve chilled."
            ],
            notes: """
            If you prefer a thinner syrup, add more water while simmering.
            Make sure to save some syrup for garnish to create a marble effect.
            """
        )
        saveRecipe(
            name: "Green Chutney (Indian Cilantro Mint Chutney)",
            prepTime: "5 minutes",
            cookingTime: "0 minutes",
            ingredients: [
                "1 small white onion (4 ounces), roughly chopped",
                "1 cup packed mint leaves",
                "1 ½ cups packed cilantro",
                "1 Indian green chili or serrano pepper to taste",
                "Juice of 1 lemon (2 tablespoons lemon juice)",
                "½ teaspoon fine sea salt",
                "½ teaspoon sugar or jaggery or coconut sugar, to taste",
                "Small handful of fresh pomegranate seeds (optional)"
            ],
            prePrepInstructions: [],
            instructions: [
                "Blend all ingredients together until well combined. Add 3-4 tablespoons of water if needed to reach desired consistency.",
                "Taste and adjust seasoning with more sugar if desired.",
                "Store chutney in an airtight container in the fridge for up to one week or freeze for longer storage."
            ],
            notes: """
            Add water to thin the chutney if you prefer a runnier consistency.
            Skip the pomegranate seeds if desired, and adjust sugar accordingly.
            Freeze chutney cubes for later use and thaw as needed.
            """
        )
        saveRecipe(
            name: "Grilled Corn on the Cob",
            prepTime: "10 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "2 ears corn",
                "Juice of 1/2 lemon",
                "1/2 teaspoon kosher salt, to taste",
                "3/4 teaspoon sumac",
                "1/4 cup parsley, chopped",
                "1/2 teaspoon cayenne pepper"
            ],
            prePrepInstructions: [
                "Preheat the grill to medium-high heat."
            ],
            instructions: [
                "Place the corn cobs on the grill grates and close the lid.",
                "Grill for about 5 minutes, open the lid and flip the corn. Close the lid again and grill for another 5-8 minutes, turning occasionally, until tender and charred.",
                "Transfer the grilled corn to a platter. Top with lemon juice, sumac, salt, cayenne pepper, and chopped parsley.",
                "Serve immediately and enjoy!"
            ],
            notes: """
            Adjust seasoning like salt and cayenne pepper to your taste preference.
            For an extra burst of flavor, try adding a sprinkle of grated Parmesan cheese or a drizzle of melted butter after grilling.
            """
        )
        saveRecipe(
            name: "Habanero Chili (Instant Pot)",
            prepTime: "10 minutes",
            cookingTime: "35 minutes",
            ingredients: [
                "1 tablespoon avocado oil",
                "1 onion, diced",
                "4-5 cloves garlic, minced",
                "1 habanero, minced (use 2 for extra spice)",
                "1 pound ground beef",
                "1 bell pepper, chopped",
                "5 medium carrots, chopped",
                "3 stalks celery, chopped",
                "2 cans (14.5 ounces each) organic diced tomatoes",
                "1 tablespoon chili powder",
                "2 teaspoons oregano",
                "1 1/2 teaspoons cumin powder",
                "1 teaspoon salt, adjust to taste",
                "1 teaspoon paprika",
                "Bacon, cooked and crumbled (optional)"
            ],
            prePrepInstructions: [
                "Press the 'Sauté' button on the Instant Pot."
            ],
            instructions: [
                "Add the avocado oil, onions, and garlic to the Instant Pot and sauté for 2 minutes.",
                "Add the ground beef and cook until browned.",
                "Add the remaining ingredients and mix well.",
                "Secure the lid, close the pressure valve, and cook for 35 minutes at high pressure."
            ],
            notes: """
            For a milder chili, reduce the number of habaneros or omit them entirely.
            Add crumbled bacon as a topping for extra flavor if desired.
            Serve with toppings like shredded cheese, sour cream, or chopped cilantro for added variety.
            """
        )
        saveRecipe(
            name: "Hakka Noodles (Desi Chow Mein)",
            prepTime: "25 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "210 g chicken breast or thighs, thinly sliced (~½” pieces) (See Note 1)",
                "170 g (6 oz) chow mein stir-fry noodles (uncooked), or Ching’s Hakka Noodles (See Note 2)",
                "2 tbsp + 1 tsp neutral oil (e.g., grapeseed or avocado), divided",
                "3 garlic cloves, minced",
                "1/4 inch fresh ginger, minced",
                "3 (30 g) green onions, thinly sliced (reserve some green parts for garnish)",
                "4 oz (114 g) green cabbage, thinly sliced into 2” strips",
                "1 (~60 g) carrot, julienned",
                "1/2 small (~60 g) red onion, quartered and thinly sliced",
                "1/2 (~100 g) bell pepper (green, red, or combo), thinly sliced (~1/4 inch strips)",
                "1/4 tsp sea salt",
                "1/2 cup low-sodium vegetable stock",
                "Lime wedges (optional, for serving)"
            ],
            prePrepInstructions: [
                "Prepare all ingredients and slice vegetables as directed.",
                "Combine all ingredients listed under ‘Hakka Noodles Sauce’ in a medium bowl and whisk to combine.",
                "Pour 2 tbsp of sauce over the chicken to marinate and set aside.",
                "Prepare noodles according to packet instructions. Drain, rinse with cold water, and toss with 1 tsp oil to prevent sticking."
            ],
            instructions: [
                "Heat remaining 2 tbsp oil in a large nonstick wok or fry pan over high heat.",
                "Add garlic and ginger, stir-frying for 10-15 seconds until golden and starting to brown.",
                "Add marinated chicken and stir-fry until the color changes from pink to pale, about 1-2 minutes.",
                "Add the green onions, cabbage, carrot, red onion, and bell pepper. Sprinkle in 1/4 tsp sea salt.",
                "Stir-fry for 5 minutes until the cabbage is wilted and vegetables are tender.",
                "Add noodles, the prepared sauce, and vegetable stock to the wok.",
                "Toss everything together using tongs or two wooden spoons until well combined and the sauce has dried up, about 2-3 minutes.",
                "Garnish with reserved green onion and serve immediately with lime wedges, chili garlic, or ketchup."
            ],
            notes: """
            To make the chicken extra tender, use the velveting method with baking soda as described in the recipe. Alternatively, omit chicken entirely for a vegetarian version.
            If chow mein, hakka noodles, or lo mein are unavailable, substitute with thin wheat noodles or even spaghetti.
            Inspired by RecipeTin Eats’ Chicken Chow Mein.
            """
        )
        saveRecipe(
            name: "Easy Pakistani Haleem (Instant Pot)",
            prepTime: "30 minutes",
            cookingTime: "40 minutes",
            ingredients: [
                // Lentils and Grains
                "1/4 cup (48 g) chana dal (split desi chickpeas) or yellow split peas",
                "1/4 cup (48 g) maash dal (split urad lentils)",
                "2 tbsp (25 g) masoor dal (red split lentils)",
                "2 tbsp (27 g) split moong dal (yellow lentils)",
                "2 tbsp (24 g) basmati rice",
                "2 tbsp (23 g) pearl barley (optional, see Note 3)",
                // Whole Spices
                "2 small dried bay leaves",
                "1 black cardamom pod",
                "1-2 inch piece cinnamon stick",
                "1 tsp cumin seeds",
                "1-2 green cardamom pods",
                "2 whole cloves",
                // For the Instant Pot
                "1 large (~275-300 g) yellow onion, cut into eighths",
                "6 garlic cloves, peeled",
                "1 inch ginger, peeled and roughly chopped",
                "1/4 cup neutral oil (e.g., grapeseed or canola)",
                "2 tbsp ghee",
                "1 lb beef stew meat, cut into 1 1/2-2 inch cubes",
                "1-2 small tomatoes, quartered",
                "1-2 green chili peppers, stems removed and sliced",
                "1 tbsp haleem masala powder (homemade or store-bought)",
                "1-2 tsp red chili flakes",
                "3/4 tsp turmeric powder",
                "2 1/2 to 2 3/4 tsp sea salt (adjust based on haleem masala type)",
                "2 tbsp whole milk yogurt",
                "3 cups water",
                // After Cooking
                "1/4 cup rolled oats (or instant oats)",
                "1/2 tsp garam masala or chaat masala",
                "1/4 tsp freshly ground black pepper",
                // Tadka (Tempering) – Optional
                "1/2 small (~85 g) yellow onion, thinly sliced",
                "2-3 tbsp ghee or oil",
                // Garnishing
                "1/4 cup cilantro leaves, finely chopped",
                "1 inch ginger, julienned",
                "1-2 green chili peppers, finely chopped",
                "1 lemon or lime, cut into wedges",
                "Crispy fried onions (store-bought or homemade)",
                "Chaat masala or garam masala (optional)",
                "Mint leaves (optional)"
            ],
            prePrepInstructions: [
                "Combine lentils, rice, and barley (if using) in a bowl. Rinse until water runs clear, then soak in warm water.",
                "Finely chop onion in a food processor and set aside. Mince garlic and ginger in the food processor."
            ],
            instructions: [
                "Turn Instant Pot on Sauté mode (More/High). Heat oil and ghee, then sauté chopped onion until lightly golden (~8-10 minutes).",
                "Add garlic, ginger, and whole spices. Deglaze with 1-2 tbsp water if needed.",
                "Add beef and sauté until its color changes (~5 minutes).",
                "Pulse tomatoes and green chilies in the food processor, then add to the pot with spices, yogurt, and 3 cups of water.",
                "Drain soaked lentils and grains, then add to the pot. Stir to prevent sticking. Cancel Sauté mode.",
                "Cover the Instant Pot, set the valve to Sealing, and pressure cook on Meat/Stew for 45 minutes on High.",
                "Let pressure naturally release for 5 minutes, then manually release the rest. Remove and shred beef.",
                "Use an immersion blender to blend dal until smooth. Return shredded beef to the pot with rolled oats.",
                "Turn on Sauté mode (Less/Low) and cook for 3-5 minutes, then switch to Slow Cook (More/High) for 20-30 minutes.",
                "Adjust consistency with boiling water if needed and mix in garam masala or chaat masala."
            ],
            notes: """
            For best texture, alternate between Sauté (Less) and Slow Cook (More) while stirring occasionally.
            Haleem should have a laced, thick consistency with visible shreds of beef.
            Adding pearl barley enhances texture and creaminess; adjust quantity to preference.
            If the beef isn’t tender after 45 minutes, pressure cook for an additional 5-10 minutes.
            """
        )
        saveRecipe(
            name: "Instant Pot Carrot Halwa (Gajar ka Halwa)",
            prepTime: "20 minutes",
            cookingTime: "30 minutes",
            ingredients: [
                "1 lb organic carrots, tops and ends removed, peeled as needed",
                "3 tbsp ghee, divided",
                "4-5 green cardamom pods",
                "1 cup whole milk",
                "1/2 cup heavy whipping cream",
                "3 1/2 – 4 tbsp raw cane sugar (adjust based on carrot sweetness)",
                "1 tbsp slivered pistachios (optional, for garnish)",
                "1 tbsp slivered almonds (optional, for garnish)"
            ],
            prePrepInstructions: [
                "Use the shredder attachment of a food processor to thinly grate the carrots in batches if necessary. Set aside."
            ],
            instructions: [
                "Select the Sauté setting on the Instant Pot and set to More/High.",
                "Add 2 tbsp of ghee, cardamom pods, and shredded carrots. Sauté for 5 minutes, stirring occasionally, until the carrots change color and reduce slightly.",
                "Add the whole milk and heavy whipping cream, stirring to mix.",
                "Cancel the Sauté setting. Secure the lid and set the Pressure Release to Sealing. Pressure Cook on High for 30 minutes.",
                "Allow the pressure to naturally release for 3-5 minutes, then quick release any remaining pressure.",
                "Select the Sauté setting again and set to More/High. Stir occasionally until most moisture evaporates and the carrots stick to the bottom (~10 minutes).",
                "Add the remaining 1 tbsp ghee and sugar. Continue sautéing, scraping the bottom, for 8-10 minutes until the halwa is dry, the ghee separates, and the color deepens to a rich orange-red.",
                "Press the Cancel button to turn off the Instant Pot.",
                "Transfer the halwa to a serving dish and garnish with pistachios and almonds, if desired."
            ],
            notes: """
            For a deeper flavor, ensure the ghee is fully incorporated and the halwa achieves a rich, deep orange or red color.
            Adjust the sugar based on the natural sweetness of the carrots.
            You can substitute raw cane sugar with your preferred sweetener.
            Garnishing with pistachios and almonds is optional but adds a delightful crunch.
            """
        )
        saveRecipe(
            name: "Hanami Dango",
            prepTime: "20 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "105 grams Shiratamako (glutinous rice flour)",
                "80 grams Joshinko (rice flour)",
                "40 grams icing sugar",
                "135 ml hot boiling water",
                "1 drop red food coloring",
                "1 drop green food coloring"
            ],
            prePrepInstructions: [
                "Dust a clean working surface with glutinous rice flour for kneading later."
            ],
            instructions: [
                "In a large mixing bowl, whisk together glutinous rice flour, rice flour, and icing sugar.",
                "Add hot boiling water and whisk until a ball of dough forms. Knead until smooth, even if slightly tacky at first.",
                "Roll the dough into a thick log and divide it into three equal portions, placing each portion in a separate bowl.",
                "Add 1 drop of red food coloring to the first bowl and knead until the color is evenly distributed. Repeat with the second bowl using green food coloring. Leave the third bowl plain.",
                "Roll each portion into a 1-inch-thick log and cut each log into 6 equal pieces. Roll each piece into a smooth ball, yielding 18 balls in total.",
                "Bring a medium-sized pot of water to a boil, then reduce to medium-high heat. Roll each ball quickly before lowering into the water to prevent sticking.",
                "Boil for 7-8 minutes until the balls float and are fully cooked inside, stirring occasionally.",
                "Strain and transfer the cooked balls into an ice bath to cool.",
                "Once cool, skewer 1 ball of each color (green, white, pink) onto a stick, creating 3 balls per skewer.",
                "Serve at room temperature and enjoy!"
            ],
            notes: """
            Store in an airtight container in the fridge for 3-4 days.
            To soften refrigerated dango, re-boil for a few minutes before serving.
            """
        )
        saveRecipe(
            name: "Idli Dosa Batter (Instant Pot)",
            prepTime: "5-6 hours (soaking)",
            cookingTime: "12 hours (fermentation)",
            ingredients: [
                "3 cups idli rice (short-grain parboiled rice), soaked for 5-6 hours",
                "1 cup whole skinless black lentils (urad dal), soaked for 5-6 hours",
                "1 teaspoon fenugreek (methi) seeds, soaked for 5-6 hours",
                "2 cups cold water (adjust as needed)",
                "3 teaspoons salt"
            ],
            prePrepInstructions: [
                "Soak the rice in a bowl of cold water for 5-6 hours.",
                "In a separate bowl, soak the urad dal and fenugreek seeds in cold water for 5-6 hours."
            ],
            instructions: [
                "Drain the water from the soaked rice and lentils.",
                "In a blender, blend the drained rice with 1 cup of cold water until mostly smooth. Pour into the steel pot.",
                "Blend the drained urad dal and fenugreek seeds with 1 cup of cold water until fluffy and foam-like. Add this to the steel pot.",
                "Mix the blended rice and lentils together in the pot.",
                "Press the yogurt button on the Instant Pot and set it to ferment for 12 hours on normal mode. Secure the lid (valve position does not matter).",
                "Once fermented, the batter should double in size and look light and airy. Gently fold in the salt and adjust the consistency with water to resemble cake or thick pancake batter.",
                "Use the batter for idli in the first couple of days and for dosa or savory pancakes later. Store in the fridge for up to a week or freeze for up to a month."
            ],
            notes: """
            To make idlis: Spoon the fermented batter into a greased idli mold. Place 2 cups of water in the Instant Pot, insert the mold, and pressure cook for 1 minute on high pressure. Allow natural release for 10 minutes before serving with sambar.
            To make dosas: Mix 1 cup of batter with 1 tablespoon chickpea flour, 1 teaspoon sugar, and 3-4 tablespoons of water for a runnier consistency. Cook on a hot crepe pan until edges lift, flipping once.
            Add golden raisins and cashews to the idli mold for a sweeter variation.
            For best results, soak the rice and lentils in the morning and ferment overnight.
            """
        )
        saveRecipe(
            name: "Indian Style Pasta",
            prepTime: "25 minutes",
            cookingTime: "20 minutes",
            ingredients: [
                // Roast Peppers
                "1 tbsp olive oil",
                "1 red bell pepper, chopped",
                "1 green bell pepper, chopped",
                "1 yellow bell pepper, chopped",
                "Pinch of salt",
                // Curry
                "2 tbsp rapeseed oil",
                "2 tsp garam masala",
                "1 tsp cumin seeds",
                "1 tsp ground coriander",
                "2 tbsp coriander stalks, finely chopped",
                "1 tsp sea salt",
                "1 tsp turmeric",
                "2 onions, chopped",
                "1/2 tsp fenugreek",
                "1 green chilli, diced",
                "3 garlic cloves, minced",
                "1 piece fresh ginger, peeled and chopped",
                "6 tomatoes, chopped",
                "125 ml water",
                "Pinch of pepper",
                "100 g frozen peas",
                "Cooked penne pasta, enough for 4 people",
                // Toppings
                "Handful of coriander leaves"
            ],
            prePrepInstructions: [
                "Preheat oven for roasting peppers."
            ],
            instructions: [
                "Place chopped bell peppers on a baking tray. Drizzle with olive oil, sprinkle with salt, and roast for 20 minutes.",
                "In a frying pan, heat rapeseed oil and add garam masala, cumin seeds, ground coriander, turmeric, and fenugreek. Simmer for 1-2 minutes until aromatic.",
                "Add onions and fry until soft. Stir in garlic, coriander stalks, ginger, and chillies. Mix to coat with spices.",
                "Add chopped tomatoes to the pan and simmer for 7-10 minutes.",
                "Stir in salt and water, then simmer for 1 minute.",
                "Add roasted peppers and frozen peas to the pan, folding them into the mixture.",
                "Add cooked penne pasta to the sauce and fold to coat evenly."
            ],
            notes: """
            Serve immediately garnished with coriander leaves.
            You can adjust spice levels by varying the amount of green chilli.
            For a richer flavor, try adding a splash of coconut milk to the sauce.
            """
        )
        saveRecipe(
            name: "Basic Microwaved Jacket Potato",
            prepTime: "10 minutes",
            cookingTime: "15-25 minutes",
            ingredients: [
                "2 large baking potatoes",
                "1 tsp olive oil",
                "Pinch of salt",
                "Butter, to taste"
            ],
            prePrepInstructions: [
                "Wash the baking potatoes thoroughly and prick the skins all over with a fork to create steam holes."
            ],
            instructions: [
                "Lay a sheet of kitchen roll on a microwave-safe plate, place the potatoes on top, and cover with another sheet of kitchen roll.",
                "Microwave the potatoes for 4 minutes. Carefully turn them over, re-cover with kitchen roll, and cook for another 4 minutes.",
                "Continue cooking in 1-2 minute bursts until the potatoes are soft all the way through and the skins are wrinkled. Allow them to cool slightly.",
                "Preheat the oven to 220°C/200°C fan/gas mark 7.",
                "Once cool enough to handle, rub the potato skins with olive oil and sprinkle with salt. Place them directly on the oven rack and bake for 10-15 minutes until the skins are crispy.",
                "Split the potatoes open, add butter, and serve with your favorite toppings or alongside a stew or casserole."
            ],
            notes: """
            For best results, cooking the potatoes entirely in the oven is recommended, but starting in the microwave speeds up the process.
            Popular toppings include tuna with sweetcorn and sriracha mayo or other creative fillings of your choice.
            Ensure the potatoes cool enough to handle before applying oil and seasoning to avoid burns.
            """
        )
        saveRecipe(
            name: "Jackfruit Bulgogi Bao Buns",
            prepTime: "90 minutes",
            cookingTime: "40 minutes",
            ingredients: [
                // Bao Buns
                "1/2 tsp fine sea salt",
                "500 g plain flour, plus extra for dusting",
                "1 x 7 g sachet fast-action dried yeast",
                "30 g caster sugar",
                "15 g baking powder",
                "50 ml unsweetened soy milk",
                "250 ml warm water",
                "25 g vegetable oil",
                // Jackfruit Bulgogi
                "1 tbsp soy sauce",
                "1 tbsp light brown sugar",
                "1 tbsp toasted sesame oil",
                "1/2 tbsp freshly grated ginger",
                "1/2 x 400 g can of jackfruit, drained",
                "1/2 pear, peeled and grated",
                "1 garlic clove, finely grated",
                "1/2 tbsp gochujang paste",
                "1 g vegetable oil",
                "Salt and pepper, to taste",
                // Toppings
                "1 tbsp toasted sesame seeds",
                "Kimchi (optional)",
                "2 spring onions, finely sliced",
                "1/2 cucumber, peeled and sliced",
                "1 carrot, peeled and ribboned",
                "1/2 tsp salt",
                "1/2 tbsp sugar"
            ],
            prePrepInstructions: [
                "Preheat the oven to 25°C for the dough to rise.",
                "Prepare a bamboo steamer lined with parchment paper punctured for steam circulation."
            ],
            instructions: [
                "In a bowl, mix flour, salt, yeast, sugar, and baking powder. Gradually add soy milk and warm water, folding the mixture to form a moist, non-sticky dough.",
                "Knead the dough on a floured surface for 2 minutes. Add vegetable oil and knead for another 8 minutes until smooth.",
                "Dust the dough with flour, place it in an oiled bowl, cover with a damp cloth, and let it rise in the warm oven for 60-90 minutes.",
                "Divide the dough into 8 pieces and shape into balls. Roll each ball into a 10 cm disk, fold over a chopstick, and set aside to rest.",
                "Steam the buns in a bamboo steamer over a wok with boiling water for 8-10 minutes. Allow to rest for 1 minute before serving.",
                "Prepare the jackfruit by crushing it between your fingers. Mix it with soy sauce, sesame oil, sugar, garlic, ginger, and gochujang. Marinate for 10 minutes.",
                "Pickle the cucumber slices with salt and sugar. Let sit for 10 minutes, then drain.",
                "Cook the jackfruit in a frying pan with oil on high heat for 5 minutes. Reduce to low heat and cook for another 4 minutes, stirring occasionally.",
                "Serve the buns with jackfruit, sesame seeds, kimchi, spring onions, carrot ribbons, and cucumber slices."
            ],
            notes: """
            Use a bamboo steamer for the best results when steaming the buns. If unavailable, a metal steamer will work.
            Adjust the spiciness of the jackfruit by varying the amount of gochujang paste.
            Store leftover buns in an airtight container and reheat by steaming for a few minutes before serving.
            """
        )
        saveRecipe(
            name: "Japanese Milk Buns",
            prepTime: "30 minutes",
            cookingTime: "25 minutes",
            ingredients: [
                // For the Tangzhong
                "2 tablespoons strong white bread flour",
                "100 ml (1/3 cup plus 1 tablespoon) milk",
                // For the Dough
                "350 g (2 1/3 cups) strong white bread flour",
                "3 g (1 teaspoon) instant dried yeast",
                "1 teaspoon fine salt",
                "55 g (1/4 cup) caster sugar",
                "1 egg",
                "125 ml (1/2 cup) milk, warmed to 37°C/98°F",
                "50 g (1/2 stick) unsalted butter, softened",
                // For the Eggwash
                "1 egg",
                "1 tablespoon milk"
            ],
            prePrepInstructions: [
                "Prepare a small saucepan for the Tangzhong."
            ],
            instructions: [
                // Tangzhong Preparation
                "Whisk flour and milk together in a small saucepan over low heat until a thick paste forms. Transfer to a bowl and let cool.",
                // Dough Preparation
                "In a stand mixer bowl, combine flour, yeast, salt, and sugar. Add the egg and cooled Tangzhong.",
                "Slowly pour in the warmed milk while mixing until a sticky dough forms. Add butter one tablespoon at a time, ensuring full incorporation before adding the next.",
                "Knead on medium speed for 10-15 minutes until the dough passes the windowpane test and pulls away from the sides of the bowl.",
                "Lightly oil a mixing bowl. Shape the dough into a ball, place it in the bowl, and lightly oil the top.",
                "Cover with a tea towel and let rise in a warm place for 1.5 hours or until doubled in size.",
                // Shaping and Baking
                "Divide the dough into 9 equal portions. Shape each portion into a ball by pinching edges underneath.",
                "Place the buns into a lined baking pan and let them proof in a warm place for 30 minutes until doubled in size and touching.",
                "Preheat the oven to 180°C/356°F (without fan). Brush the buns with egg wash and bake for 20-25 minutes. Cover with foil if browning too quickly.",
                "Let the buns cool in the pan for 5 minutes before transferring to a wire rack."
            ],
            notes: """
            Tangzhong must be cooled before adding to the dough to avoid affecting the yeast.
            The dough should stretch thin enough to see light through during the windowpane test to ensure proper gluten development.
            For an overnight proof, refrigerate the dough covered and continue the process the next day.
            Adjust baking time and temperature if using a convection oven by consulting your oven’s manual.
            """
        )
        saveRecipe(
            name: "Japanese Milk Buns 2",
            prepTime: "2 hours 50 minutes",
            cookingTime: "20 minutes",
            ingredients: [
                // For the Tangzhong
                "3 tbsp water",
                "3 tbsp whole milk",
                "2 tbsp all-purpose flour",
                // For the Dough
                "1 tbsp active dry yeast",
                "1/2 cup whole milk, warmed to 105-115°F",
                "2 tbsp whole milk powder",
                "1/4 cup sugar",
                "1 tsp salt",
                "1 large egg",
                "1/4 cup unsalted butter, melted",
                "2 1/2 cups all-purpose flour",
                "1 tbsp milk (for brushing on the buns)"
            ],
            prePrepInstructions: [
                "Prepare a small pot for the Tangzhong and a greased 9-inch baking pan for the dough."
            ],
            instructions: [
                // Tangzhong Preparation
                "Stir milk, water, and flour together in a small pot until lump-free.",
                "Cook over low heat while stirring continuously until the mixture thickens like a paste. Transfer to a small bowl and let cool.",
                // Dough Preparation
                "In a large mixing bowl, combine warm milk and yeast with 1 teaspoon sugar. Let sit for 5 minutes until foamy.",
                "Add the remaining sugar, milk powder, butter, egg, salt, and cooled Tangzhong. Mix with a wooden spoon until combined.",
                "Gradually add flour, stirring until the dough forms a shaggy mass.",
                "Turn the dough onto a floured surface and knead until smooth, elastic, and soft.",
                "Shape the dough into a ball and place it in a lightly greased bowl. Cover and let rise for 60-90 minutes until puffy.",
                // Shaping and Baking
                "Divide the dough into 9 equal portions. Shape each into a ball and place in a greased 9-inch baking pan.",
                "Cover the rolls and let them rise for 50 minutes until puffy.",
                "Preheat the oven to 350°F. Brush the rolls with milk and bake for 15-17 minutes, or until golden on top.",
                "Let cool slightly and serve warm. Store leftovers in a tightly covered container at room temperature for up to 2 days."
            ],
            notes: """
            Tangzhong must be cool before incorporating into the dough to avoid affecting the yeast.
            The dough should be kneaded until elastic and soft for the best texture.
            For longer storage, keep the buns in an airtight container at room temperature for up to 2 days.
            Recipe adapted from King Arthur Flour.
            """
        )
        saveRecipe(
            name: "Japchae (Korean Glass Noodle Stir-Fry)",
            prepTime: "15 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "100 g sweet potato noodles",
                "100 g rib eye beef (or chuck beef), thinly sliced",
                "50 g carrot, thinly sliced",
                "1/4 onion, thinly sliced",
                "1/4 red bell pepper, thinly sliced",
                "30 g baby spinach (packed into the measuring cup)",
                "3 shiitake mushrooms (or dried shiitake mushrooms soaked in hot water)",
                "1 garlic clove, minced",
                "15 ml sesame oil (for cooking)",
                "2 g sesame seeds, toasted",
                // Sauce
                "22 ml regular soy sauce",
                "15 ml sesame oil",
                "24 g brown sugar"
            ],
            prePrepInstructions: [
                "Combine the sauce ingredients (soy sauce, sesame oil, and brown sugar) in a small bowl and set aside.",
                "Soak dried shiitake mushrooms in hot water if using."
            ],
            instructions: [
                "In a pot, bring water to a boil. Boil sweet potato noodles for 5 minutes, then strain and transfer to a large mixing bowl to cool.",
                "In a large non-stick pan over low-medium heat, heat 1/2 tablespoon sesame oil. Add onions, carrots, red bell peppers, and spinach. Fry until softened but still crisp, about 1-2 minutes. Transfer to the mixing bowl.",
                "Add the remaining 1/2 tablespoon sesame oil to the pan. Fry garlic and mushrooms until softened.",
                "Add thinly sliced beef and 2 teaspoons of the prepared sauce to the pan. Mix well and cook until the beef is fully cooked. Transfer to the mixing bowl.",
                "Pour the remaining sauce into the mixing bowl with the noodles. Mix everything together using clean hands or tongs until well combined.",
                "Garnish with toasted sesame seeds and serve. Enjoy!"
            ],
            notes: """
            Substitute rib eye beef with other protein options like chicken, tofu, or shrimp for variety.
            Soak dried shiitake mushrooms in hot water before cooking to soften and enhance their flavor.
            Adjust the level of sweetness in the sauce by varying the amount of brown sugar to your preference.
            """
        )
        saveRecipe(
            name: "Jollof Rice (Nigerian Style) (Long Grain Rice)",
            prepTime: "20 minutes",
            cookingTime: "50 minutes",
            ingredients: [
                "2 cups long grain rice",
                "1 onion, chopped",
                "1 red bell pepper (tatashe)",
                "500 ml chopped tomatoes (or 400 g canned tomatoes)",
                "100 g tomato purée",
                "2 scotch bonnets (or Thai red chilies)",
                "100 ml vegetable oil",
                "2 Maggi cubes (or chicken powder)",
                "Salt to taste",
                "1 teaspoon curry powder",
                "1 teaspoon thyme",
                "1/2 teaspoon garlic powder",
                "1/4 teaspoon ginger powder",
                "2 cups water or stock",
                "1 bay leaf"
            ],
            prePrepInstructions: [
                "Blend together the tomatoes, scotch bonnets, and red bell pepper until smooth. Set aside.",
                "Chop the onions and set aside.",
                "Soak the rice in hot water for 10-15 minutes, then rinse thoroughly with warm water to remove excess starch, or parboil and rinse."
            ],
            instructions: [
                "Heat vegetable oil in a large pot over medium heat.",
                "Add chopped onions and fry until softened, taking care not to burn them.",
                "Season with a pinch of salt and fry for 2-3 minutes. Add the bay leaf, curry powder, thyme, and a pinch of black pepper. Stir-fry for another 3-4 minutes.",
                "Stir in the tomato paste and cook for 2 minutes. Add the blended tomato-pepper mixture, stir, and cook on medium heat with the lid on for 10-12 minutes until reduced by half.",
                "Add Maggi cubes, garlic powder, ginger powder, curry powder, thyme, and salt. Stir well and adjust seasoning as needed.",
                "Pour in the stock or water and mix thoroughly.",
                "Add the rice to the pot, ensuring it is well-coated with the tomato sauce. Stir to combine.",
                "Cook on low-medium heat. After 10 minutes, check the rice and stir gently with a wooden spatula to prevent burning and ensure even cooking.",
                "Continue cooking until the rice is tender but not mushy. Once the rice is soft, reduce the heat and allow it to simmer until the water evaporates completely.",
                "Remove from heat and serve warm."
            ],
            notes: """
            Use long-grain rice for the best texture and flavor. Removing excess starch from the rice helps achieve the desired consistency.
            Adjust the spice level by varying the amount of scotch bonnets or substituting with milder chilies.
            Stir gently to avoid breaking the rice grains during cooking.
            """
        )
        saveRecipe(
            name: "Kathrikai",
            prepTime: "15 minutes",
            cookingTime: "40-50 minutes",
            ingredients: [
                "5-6 Chinese/Japanese aubergines, chopped (not too long or thick)",
                "4 onions, chopped",
                "4 green chillies, slit in half",
                "3 cloves garlic, minced",
                "4 tbsp tamarind paste",
                "800-900 ml warm water",
                "1 tomato, diced",
                "1.5 tbsp fennel seeds (dry roasted and ground)",
                "Handful of curry leaves (dry roasted and ground)",
                "1 tsp hot mustard seeds",
                "1 heaping tsp fennel seeds",
                "1 tsp cumin seeds",
                "1 tsp fenugreek seeds",
                "4 tbsp tomato paste",
                "1 tsp ground turmeric",
                "5-5 1/2 tbsp Jaffna curry powder",
                "Small handful of curry leaves, torn",
                "1 tbsp brown sugar",
                "1 tsp Vasa thool",
                "Salt, to taste",
                "Oil, for frying"
            ],
            prePrepInstructions: [
                "Chop aubergines and onions.",
                "Slit green chillies and mince garlic.",
                "Soak tamarind paste in warm water and strain to remove any solids.",
                "Dry roast fennel seeds and curry leaves, then grind into a powder."
            ],
            instructions: [
                "Deep fry the aubergines in hot oil until browned and cooked thoroughly, starting with high heat and reducing to avoid burning. Drain on kitchen towels.",
                "Heat oil in a pan until hot and pop the mustard seeds.",
                "Add fennel seeds, cumin seeds, and fenugreek seeds. Stir for a few seconds.",
                "Add chopped onions and cook for 3-4 minutes until softened.",
                "Add garlic and green chillies, letting them cook for a few minutes.",
                "Add diced tomato and cook until softened.",
                "Stir in tomato paste and cook until the mixture thickens.",
                "Pour in the strained tamarind water and bring to a boil.",
                "Add ground turmeric and Jaffna curry powder, mixing well.",
                "Gently fold in the fried aubergines, taking care not to tear them.",
                "Season with salt and bring the mixture to a boil, then reduce to medium-low heat.",
                "Add torn curry leaves and Vasa thool, mixing gently.",
                "Let the stew simmer on low heat for 15 minutes with the lid on. For a thicker consistency, cook longer with the lid off.",
                "Stir in brown sugar and cook for an additional 5 minutes.",
                "Taste and adjust salt as needed before serving."
            ],
            notes: """
            Kathrikai kulambu thickens over time, especially overnight, as the aubergines absorb the gravy.
            Avoid reducing the gravy too much during cooking to prevent it from becoming overly thick later.
            Serve with steamed rice or roti for a traditional pairing.
            """
        )
        saveRecipe(
            name: "Kachumber Salad - Cucumber Tomato Onion Salad",
            prepTime: "10 minutes",
            cookingTime: "5 minutes",
            ingredients: [
                "1 small onion, finely chopped",
                "2 medium tomatoes, chopped small",
                "1 large cucumber, chopped small",
                "4-5 red radishes, chopped small (optional)",
                "1 green chili, finely chopped (remove seeds to reduce heat if needed)",
                "4 g packed chopped cilantro",
                "0.25 tsp or more salt",
                "0.25 tsp or more freshly ground black pepper",
                "0.25 tsp or more cayenne or pure red chili powder",
                "1 tsp or more freshly squeezed lime or lemon juice"
            ],
            prePrepInstructions: [
                "Chop the onions, tomatoes, cucumbers, and radishes.",
                "Wash and drain all chopped vegetables well."
            ],
            instructions: [
                "Add all chopped vegetables to a mixing bowl.",
                "Add cilantro, green chili, salt, black pepper, cayenne, and lime or lemon juice.",
                "Mix well and taste. Adjust salt and heat as needed.",
                "Serve fresh as a side or salad."
            ],
            notes: """
            Adjust the heat by adding or reducing green chili or cayenne powder.
            For added crunch, serve immediately after preparation.
            Perfect as a side dish for Indian meals or as a refreshing standalone salad.
            """
        )
        saveRecipe(
            name: "Keema (Instant Pot Ground Beef Curry)",
            prepTime: "10 minutes",
            cookingTime: "30 minutes",
            ingredients: [
                // Main Ingredients
                "1 medium onion, peeled and chopped into eights",
                "5 garlic cloves, peeled",
                "1/2 inch ginger, peeled and cut into a few pieces",
                "1/4 cup neutral oil (such as avocado or grapeseed)",
                "1 tsp cumin seeds",
                "1-2 small green chili peppers, stems removed and roughly chopped",
                "1 small to medium (~150 g) tomato, quartered",
                "1 lb ground beef (lean or regular)",
                // Ground Spices & Salt
                "2 tsp coriander powder",
                "1 tsp cumin powder",
                "1/2 tsp turmeric powder",
                "1/2 tsp red chili powder, or to taste",
                "1/4 tsp red chili flakes (optional)",
                "1/4 tsp freshly ground black pepper",
                "1 1/4 tsp kosher salt, or to taste",
                // After Pressure Cooking
                "2 tbsp whole milk yogurt",
                "2 tbsp cilantro leaves, finely chopped",
                "1/2-1 tsp garam masala",
                "1/2 tsp freshly squeezed lemon juice (optional)"
            ],
            prePrepInstructions: [
                "Place onion, garlic, and ginger in a food processor. Pulse until finely chopped but not blended.",
                "Use the pulse function to roughly chop the tomato and green chili peppers. Set aside."
            ],
            instructions: [
                "Select the Sauté setting on the Instant Pot and set to More/High. When the screen says 'Hot', add oil and cumin seeds. Let them sizzle for a few seconds.",
                "Add the onion mixture and sauté until lightly browned, about 6-8 minutes.",
                "Deglaze the Instant Pot with a splash of water, stirring to remove any bits stuck to the pan.",
                "Add ground beef and cook, stirring to remove lumps, until the meat changes color, about 4-5 minutes.",
                "Add the tomato and green chili mixture, ground spices, and salt. Mix well, deglazing any bits. (No need to add extra water as the beef and tomatoes provide enough moisture.)",
                "Cancel Sauté, close the lid, and seal. Select the Pressure Cook setting on High for 10 minutes.",
                "After cooking, allow pressure to naturally release for 5 minutes, then manually release any remaining pressure.",
                "Select the Sauté setting on More/High. Stir in yogurt and sauté until the meat turns glossy and no excess liquid remains, about 6-7 minutes.",
                "Taste and adjust salt and spices. Sprinkle with garam masala, cilantro, and lemon juice (if desired). Serve warm."
            ],
            notes: """
            The moisture from the tomato and beef is sufficient for pressure cooking; no extra water is needed. If it appears dry, add a small splash of water and mix.
            Keema freezes well. Cool completely before transferring to an airtight container. Reheat in a saucepan or microwave, adding a splash of water if needed.
            """
        )
        saveRecipe(
            name: "Keema Lobia (Instant Pot Ground Beef & Black Eyed Peas Curry)",
            prepTime: "15 minutes",
            cookingTime: "25 minutes",
            ingredients: [
                // To Pressure Cook
                "1 medium to large onion, cut into wedges",
                "2 small tomatoes, cut into wedges",
                "5-6 cloves garlic, cut into a couple of pieces",
                "1 lb ground beef (lean or full-fat)",
                "1 tsp cumin seeds",
                "1 ½-2 tsp mild red chili powder, or to taste",
                "1 tsp coriander powder",
                "1/2 tsp cumin powder",
                "½ tsp turmeric powder",
                "1 1/2 tsp salt, or to taste (use more if using kosher salt)",
                // After Pressure Cooking
                "¼ cup neutral oil",
                "1-1 ½ cups cooked black-eyed peas (or 1 can, 15.8 oz, drained and rinsed)",
                "1/2 tsp freshly ground black pepper",
                "½ tsp garam masala",
                "1 green chili or Serrano pepper, finely chopped",
                "1 inch ginger, chopped or julienned",
                // Garnish
                "2 tbsp cilantro leaves, chopped",
                "½-1 tsp freshly squeezed lemon juice (optional)"
            ],
            prePrepInstructions: [
                "Add onion, tomatoes, and garlic to a food processor and pulse until a coarse mixture forms."
            ],
            instructions: [
                "Heat the Instant Pot to High/More Sauté mode. Once hot, add the onion mixture, ground beef, cumin seeds, spice powders, and salt. Sauté for 2-3 minutes until the mixture starts to release water.",
                "Cover and pressure-cook on High for 15 minutes. No additional water is needed.",
                "Allow the pressure to naturally release for 5 minutes, then manually release any remaining pressure.",
                "Select Sauté mode on High/More and sauté for 5-7 minutes, or until most of the water evaporates.",
                "Add the oil, black-eyed peas, black pepper, garam masala, green chili, and ginger. Continue to sauté for another 3-5 minutes until the oil starts to release.",
                "Taste and adjust salt and spices as needed. Cancel Sauté mode and garnish with cilantro leaves and lemon juice if desired.",
                "Serve warm with naan, roti, or rice."
            ],
            notes: """
            No additional water is required during pressure cooking as the beef and onion mixture releases enough moisture.
            Adjust the level of spiciness by varying the amount of chili powder or green chili.
            Keema Lobia can be refrigerated for up to 3 days and reheated before serving.
            """
        )
        saveRecipe(
            name: "Kerala Ground Meat Coconut Curry (Instant Pot)",
            prepTime: "10 minutes",
            cookingTime: "20 minutes",
            ingredients: [
                "2 tablespoons coconut oil",
                "1 teaspoon black mustard seeds",
                "1 onion, diced",
                "1 Serrano pepper or green chili, minced",
                "20 curry leaves",
                "3 teaspoons minced garlic",
                "1 teaspoon minced ginger",
                // Spices
                "2 teaspoons meat masala",
                "1 ½ teaspoons salt",
                "1 teaspoon coriander powder",
                "½ teaspoon black pepper",
                "½ teaspoon paprika",
                "½ teaspoon turmeric",
                // Main Ingredients
                "1 pound ground beef or ground meat of choice",
                "3 carrots, chopped",
                "1 potato, chopped",
                "¼ cup water",
                "1 (13.5-ounce) can full-fat coconut milk"
            ],
            prePrepInstructions: [
                "Dice onion, mince Serrano pepper or green chili, and prepare garlic and ginger.",
                "Chop carrots and potato into bite-sized pieces."
            ],
            instructions: [
                "Press the Sauté button on the Instant Pot and add coconut oil. Once melted, add mustard seeds and wait for them to pop.",
                "Add onion, Serrano pepper, and curry leaves. Stir-fry for 6-7 minutes, or until onions begin to brown.",
                "Add garlic and ginger, and stir-fry for 30 seconds.",
                "Stir in the spices (meat masala, salt, coriander powder, black pepper, paprika, and turmeric).",
                "Add the ground meat and cook until mostly browned.",
                "Add chopped carrots, potatoes, and ¼ cup of water. Stir well.",
                "Secure the lid, close the pressure valve, and cook for 4 minutes at high pressure.",
                "Quick-release any remaining pressure. Open the lid and stir in the coconut milk until combined.",
                "Serve warm with rice or flatbread."
            ],
            notes: """
            Adjust the spice level by varying the amount of Serrano pepper or green chili.
            For a vegetarian version, substitute the ground meat with lentils or crumbled tofu.
            This curry pairs well with steamed rice, naan, or roti.
            """
        )
        saveRecipe(
            name: "Kheer (Instant Pot Rice Pudding)",
            prepTime: "5 minutes",
            cookingTime: "30 minutes",
            ingredients: [
                "1/3 cup + 1 tbsp basmati rice",
                "3 cups whole milk",
                "2 cups (1 pint) half and half (or sub equal parts milk and heavy whipping cream)",
                "10 green cardamom pods (or 1/8-1/4 tsp cardamom powder)",
                "1/4 cup + 2 tbsp pure cane sugar (or more to taste)",
                "3 tbsp condensed milk (or more to taste; may sub additional sugar)",
                "¼-1/2 tsp kewra essence or rose water (optional)",
                "2-3 tbsp finely chopped or slivered nuts (e.g., almonds, pistachios; optional)"
            ],
            prePrepInstructions: [
                "Pulse the basmati rice in a spice grinder or food processor 10-12 times until it resembles steel-cut oats. Shake the grinder to ensure even grinding, but avoid turning it into powder."
            ],
            instructions: [
                "Select the Sauté (More/High) setting on the Instant Pot. Once hot, add the milk, half and half, and cardamom pods.",
                "Bring the mixture to a simmer, stirring frequently to prevent sticking (about 8-10 minutes). Add the ground rice and stir to combine.",
                "Cancel Sauté, close the lid, and set the Pressure Release Valve to Sealing. Select the Porridge setting and set the timer for 20 minutes on High Pressure.",
                "When the timer is up, allow the pressure to naturally release (~20 minutes).",
                "Remove the lid and press Cancel. Select the Sauté (More/High) setting. Stir in the sugar and condensed milk.",
                "Sauté while stirring constantly until the mixture reduces slightly, depending on your desired consistency (see Notes). Use a wooden spoon to mash the rice against the sides for a smoother texture.",
                "Cancel Sauté and stir in kewra essence or rose water, if using. Remove the kheer from the Instant Pot and transfer it to a serving dish.",
                "Garnish with slivered nuts if desired. Serve hot or chilled."
            ],
            notes: """
            For a richer version, use one part half and half and one part heavy whipping cream.
            Substitute cardamom pods with 1/8-1/4 tsp cardamom powder, adding it along with the sugar.
            The rice will absorb more liquid as it cools, thickening the kheer. If you prefer runnier kheer, sauté for 1-2 minutes and adjust sweetener as needed.
            """
        )
        saveRecipe(
            name: "Kimchi (Halal)",
            prepTime: "4 hours (includes soaking time)",
            cookingTime: "30 minutes",
            ingredients: [
                // Main Ingredients
                "500 g salt",
                "3 napa cabbages",
                "1 radish",
                "500 g spring onion",
                "100 g flour",
                "1 kelp anchovy pack (optional, for broth)",
                "1 large onion",
                "2 Korean pears, peeled and cored",
                "250 g garlic, minced",
                "2.5 cups tuna fish sauce (or substitute with anchovy fish sauce)",
                "600 g chili powder (gochugaru; substitute with chili powder, paprika, cayenne, or crushed red pepper flakes)"
            ],
            prePrepInstructions: [
                "Rip off the outer leaves of the napa cabbages.",
                "Make a cut halfway down the stem of each cabbage, then tear into two halves and repeat for quarter wedges.",
                "Remove the tough stem ends and discard. Cut the napa cabbage into smaller pieces."
            ],
            instructions: [
                // Salting the Napa Cabbage
                "Place the cabbage pieces into storage containers.",
                "Mix rough sea salt with water to make a brine, ensuring all the salt is dissolved.",
                "Pour the brine over the cabbage, ensuring the pieces are fully submerged. Add weighty plates if necessary.",
                "Seal the containers and soak for 2 hours. Test by snapping a piece in half; if it still crunches, soak for an additional 2 hours.",
                // Making the Kelp Stock and Flour Paste
                "Boil dried anchovies and kelp to make a broth (optional but recommended).",
                "Dissolve flour in water, then pour the mixture into a pan of boiling water while stirring constantly. Allow it to cool.",
                // Preparing Fresh Ingredients
                "Wash, trim, and slice the spring onions. Peel and slice the radish into sticks.",
                "Peel and core the pears, then blend them with the garlic and onion to form a paste.",
                // Making the Kimchi Seasoning
                "In a large bowl, mix the spring onions, radish, blended paste, chili powder, flour paste, and tuna fish sauce.",
                "Adjust the seasoning to be saltier and spicier than your usual taste. Add kelp broth as needed to achieve the desired consistency.",
                // Mixing the Cabbage and Seasoning
                "Rinse the cabbage thoroughly and squeeze out any excess water.",
                "Mix the cabbage pieces with the prepared kimchi seasoning until evenly coated."
            ],
            notes: """
            Use gochugaru (Korean chili powder) for authentic flavor, but substitutes like chili powder, paprika, and cayenne can work in a pinch.
            If using gochujang (Korean chili paste), adjust the recipe to account for its rich, fermented flavor.
            Allow the kimchi to ferment in an airtight container at room temperature for 1-2 days before transferring to the fridge. Taste daily to monitor fermentation.
            The longer it ferments, the more tangy and robust the flavor will become.
            """
        )
        saveRecipe(
            name: "Kiwi Mojito Mocktail",
            prepTime: "10 minutes",
            cookingTime: "0 minutes",
            ingredients: [
                "3 kiwi fruits, peeled and diced",
                "10 mint leaves",
                "2 cups lemonade",
                "Ice cubes"
            ],
            prePrepInstructions: [],
            instructions: [
                "Place the kiwi fruits, lemonade, mint leaves, and ice cubes in a high-speed blender.",
                "Blend until smooth.",
                "Divide the mixture between 2 ice-filled glasses.",
                "Garnish with mint leaves or extra kiwi slices and serve immediately."
            ],
            notes: """
            For a tangier flavor, add a splash of lime juice before blending.
            Adjust sweetness by using a lemonade that matches your taste preference.
            Use crushed ice for a more refreshing texture.
            """
        )
        saveRecipe(
            name: "Kofta Curry (Meatball Curry Pakistani Beef)",
            prepTime: "30 minutes",
            cookingTime: "50 minutes",
            ingredients: [
                // For the Meatballs
                "2.25 small (270 g after peeling) onions, roughly chopped",
                "2.25 green chili peppers (e.g., Serrano or Thai), roughly chopped",
                "0.56 cup packed cilantro leaves",
                "2.25 tbsp mint leaves (optional)",
                "3.38 tsp crushed garlic",
                "2.25 tsp crushed ginger",
                "2.25 lb ground beef (preferably full-fat)",
                "4.5 tbsp gram flour (besan) or chickpea flour",
                "2.25 eggs, lightly whisked",
                "2.25 tsp freshly squeezed lemon juice",
                "1.13 tsp cumin powder",
                "1.13 tsp coriander powder",
                "1.13 tsp turmeric powder",
                "1.13 tsp black pepper powder",
                "1.13 tsp red chili powder",
                "1.13 tsp garam masala",
                "2.25 tsp kosher salt",
                // For the Curry
                "2.25 large onions, roughly chopped",
                "4.5 medium (6.75 small) tomatoes, roughly chopped",
                "2.25 green chili peppers (e.g., Serrano or Thai), roughly chopped",
                "0.56 cup neutral oil",
                "2.25 tsp cumin seeds",
                "6.75 whole cloves",
                "2.25-inch cinnamon stick",
                "2.25 bay leaves",
                "2.25-4.5 green cardamom pods",
                "9-11.25 garlic cloves, crushed",
                "1.13-inch piece ginger, crushed",
                "6.75 tbsp plain, whole milk yogurt",
                "2.25 tsp cumin powder",
                "2.25 tsp coriander powder",
                "1.13-2.25 tsp red chili powder",
                "1.13 tsp turmeric powder",
                "0.56 tsp paprika powder or Kashmiri chili powder (optional, for color)",
                "3.38 tsp kosher salt",
                "4.5 cups water",
                "0.56-1.13 tsp garam masala",
                "2.25-4.5 tbsp cilantro leaves, finely chopped"
            ],
            prePrepInstructions: [
                "Combine onions, green chili peppers, cilantro, and mint (if using) in a food processor. Pulse to finely chop but not blend.",
                "Mix the remaining meatball ingredients into the chopped mixture and process until just combined. Form into 1.5-inch meatballs and set aside.",
                "Use the food processor to finely chop onions, then blend tomatoes and green chili peppers separately for the curry."
            ],
            instructions: [
                "Heat oil in a large heavy-bottomed pan over medium-high heat. Add whole spices and let them sizzle for a few seconds.",
                "Add the chopped onions and sauté, stirring often, until golden brown (about 8 minutes). Deglaze the pan with 2 tbsp of water.",
                "Add garlic and ginger and sauté for 2 minutes until deeper in color. Add tomato-chili mixture, yogurt, spices, and salt. Cook for 4-5 minutes until oil separates, deglazing with 2 tbsp water as needed.",
                "Add 2 cups of water and bring to a boil. Lower heat to a simmer and arrange the meatballs in a single layer.",
                "Increase heat to medium, cover, and cook for 10 minutes. Uncover, gently stir the meatballs, reduce heat, and simmer for 35 minutes. Stir once halfway through.",
                "Sauté to evaporate excess water to the desired consistency. Sprinkle with garam masala and cilantro.",
                "Serve hot with roti, naan, paratha, or rice."
            ],
            notes: """
            Reheating: Add 2-3 tbsp of water when reheating to adjust consistency as the curry thickens upon cooling.
            Make-ahead: Prepare and refrigerate or freeze the meatballs for convenience.
            Adjust spice levels to taste by increasing or decreasing chili powder or green chilies.
            """
        )
        saveRecipe(
            name: "Korean Braised Potatoes (Quick & Easy Gamja Jorim)",
            prepTime: "5 minutes",
            cookingTime: "25 minutes",
            ingredients: [
                // Main Ingredients
                "1.5 lbs (680 g) baby potatoes (or quartered Yukon gold potatoes with skin on)",
                "2 tsp (10 ml) vegetable oil or any neutral-tasting oil",
                "1 tbsp (6 g) green onion, finely chopped (for garnish)",
                "0.5 tsp (1 g) sesame seeds, toasted",
                // Braising Sauce
                "4 tbsp (62 ml) regular soy sauce (not light or dark)",
                "5 tbsp (75 ml) honey or brown sugar",
                "1 clove garlic, minced",
                "1 tsp (5 ml) sesame oil (for garnish)",
                // Optional
                "1 tsp (6 g) salt (for seasoning potatoes)",
                "2 tsp (10 ml) vinegar (e.g., white vinegar, rice vinegar, or apple cider vinegar)"
            ],
            prePrepInstructions: [
                "Rinse the baby potatoes under cold water to remove any dirt. Do not peel.",
                "Combine all the braising sauce ingredients in a small bowl and set aside."
            ],
            instructions: [
                "In a large pot filled halfway with water, bring to a boil over medium-high heat. Optionally, add salt and vinegar to season the potatoes and help them retain their shape.",
                "Boil the baby potatoes uncovered for 20 minutes, or until fork-tender.",
                "Once cooked, strain the potatoes in a colander and set aside.",
                "Heat the vegetable oil in a large non-stick pan over medium heat. Add the strained potatoes and fry for 2-4 minutes until slightly browned on both sides.",
                "Pour the braising sauce mixture over the potatoes. Gently toss the potatoes in the sauce for 5 minutes, or until the sauce thickens slightly.",
                "Remove from heat, garnish with green onions, sesame seeds, and a drizzle of sesame oil. Serve warm and enjoy!"
            ],
            notes: """
            Adding vinegar during the boiling process helps the potatoes maintain their shape, while salt enhances their flavor.
            Adjust the sweetness of the sauce by using more or less honey or brown sugar to taste.
            This dish pairs well with rice and other Korean side dishes.
            """
        )
        saveRecipe(
            name: "Korean Bulgogi Chicken Wings",
            prepTime: "10 minutes",
            cookingTime: "16 minutes",
            ingredients: [
                // Main Ingredients
                "771.1 g chicken wings",
                "54.1 g potato starch (or more as needed)",
                "1 green onion, finely chopped (for garnish)",
                // Seasoning
                "1 tbsp regular soy sauce",
                "1/2 tsp black pepper",
                "2 tsp garlic, minced",
                "1/4 tsp ginger powder",
                "1/2 tsp onion powder",
                // Korean Wings Sauce
                "2 tbsp honey",
                "2 tbsp brown sugar",
                "1 tbsp regular soy sauce",
                "1/2 tbsp sesame seeds",
                "1/2 tbsp sesame oil",
                "2 tsp garlic, minced"
            ],
            prePrepInstructions: [
                "Add chicken wings to a large bowl and mix with all the Seasoning ingredients until well-coated.",
                "Spread potato starch on a large tray or place it in a Ziplock bag and coat the wings evenly in starch."
            ],
            instructions: [
                // Air Fryer Method
                "Transfer coated wings into the air fryer basket in a single layer, ensuring enough space between pieces. Work in batches if necessary.",
                "Air fry the wings at 400°F for 8 minutes on each side (16 minutes total).",
                "Remove the cooked wings and transfer them to a large mixing bowl.",
                // Deep Fryer Method
                "Heat 2 cups of neutral oil in a large pan or Dutch oven until it reaches 350°F.",
                "Deep fry the wings for 7-8 minutes until golden brown and cooked to an internal temperature of 165°F.",
                // Sauce and Garnish
                "In a small bowl, combine all ingredients for the Korean wings sauce.",
                "Pour the sauce over the fried or air-fried wings and toss to coat evenly.",
                "Garnish with chopped green onions and serve immediately."
            ],
            notes: """
            Use a meat thermometer to ensure the wings are cooked to an internal temperature of 165°F for safe consumption.
            Adjust the sweetness or spice level of the sauce to your preference by tweaking the honey and garlic.
            Serve with rice or as an appetizer with dipping sauces.
            """
        )
        saveRecipe(
            name: "Korean Chicken Bao",
            prepTime: "1 hour",
            cookingTime: "30 minutes",
            ingredients: [
                // For the Bao Buns
                "450 g (3 3⁄4 cups) plain (all-purpose) flour",
                "2 tbsp caster sugar",
                "1⁄2 tsp salt",
                "2 tsp (7 g) instant dried yeast",
                "3 tbsp whole milk",
                "210 ml (3⁄4 cup + 2 tbsp) warm water",
                "3 tbsp unsalted butter, very soft",
                "1 tbsp olive oil",
                // For the Chicken and Marinade
                "4 chicken breasts, sliced into bite-sized chunks",
                "240 ml (1 cup) buttermilk",
                "1⁄2 tsp salt",
                "1⁄4 tsp white pepper",
                "1⁄4 tsp garlic salt",
                // For the Crispy Coating
                "180 g (1 1⁄2 cups) plain (all-purpose) flour",
                "1 tsp salt",
                "1 tsp ground black pepper",
                "1⁄2 tsp garlic salt",
                "1⁄2 tsp celery salt",
                "1 tsp dried thyme",
                "1 tsp paprika",
                "1 tsp baking powder",
                "1 tsp chili flakes",
                "Vegetable oil for deep frying (at least 1 liter/four cups)",
                // For the Korean Sauce
                "2 tbsp gochujang paste",
                "2 tbsp honey",
                "4 tbsp brown sugar",
                "4 tbsp soy sauce",
                "2 cloves garlic, peeled and minced",
                "2 tsp minced ginger",
                "1 tbsp vegetable oil",
                "1 tbsp sesame oil",
                // For Serving
                "1 small red onion, thinly sliced",
                "1⁄4 cucumber, chopped into small pieces",
                "Small bunch of fresh coriander, roughly chopped",
                "2 tsp black and white sesame seeds"
            ],
            prePrepInstructions: [
                "Mix flour, sugar, salt, and yeast for the bao buns. Combine milk, water, and butter, then add to dry ingredients. Knead into a dough and let prove for 90 minutes to 2 hours.",
                "Marinate chicken in buttermilk, salt, white pepper, and garlic salt for at least 1 hour in the refrigerator.",
                "Prepare crispy coating ingredients by mixing flour, salt, spices, and baking powder in a bowl."
            ],
            instructions: [
                "After proving, divide dough into 20 balls. Roll each ball into an oval, brush with olive oil, fold, and let prove for another hour.",
                "Deep fry the chicken in oil heated to 350°F for 3-5 minutes until golden brown and cooked through.",
                "Steam the bao buns in a steamer for 10 minutes or until puffed.",
                "Prepare the Korean sauce by combining gochujang, honey, sugar, soy sauce, garlic, ginger, vegetable oil, and sesame oil in a saucepan. Simmer for 5 minutes until thickened.",
                "Toss the cooked chicken in the sauce until coated.",
                "Stuff the steamed bao buns with sauced chicken, red onion slices, cucumber, coriander, and sesame seeds. Serve immediately."
            ],
            notes: """
            Make Ahead: Cook and assemble components separately. Reheat chicken, sauce, and buns before serving.
            Freezing Buns: Steam and freeze. Reheat in a steamer for 5-6 minutes or microwave covered for 15-20 seconds each.
            Baking Alternative: Use baked chicken tenders for a healthier option.
            Steam Oven Option: Steam buns at 210°F for 8-10 minutes or use the bread proving function if available.
            Nutritional Information: Approx. 289 calories per bao. Adjust based on the amount of oil absorbed during frying.
            """
        )
        saveRecipe(
            name: "Sri Lankan Chicken Kottu Roti",
            prepTime: "20 minutes",
            cookingTime: "30 minutes",
            ingredients: [
                // Base Ingredients
                "2 tbsp vegetable oil",
                "½ medium onion, sliced",
                "1 tbsp minced garlic (about 3 garlic cloves)",
                "1 tbsp minced ginger",
                "6 large jalapeños or 3 Anaheim peppers, halved and sliced (de-seed for less heat)",
                "1 cup sliced leeks, white part only, washed",
                "¼ cabbage, sliced",
                "½ tsp cayenne pepper (optional, for heat)",
                "2 heaped cups shredded chicken (leftover curry chicken or rotisserie chicken)",
                "½ cup leftover curry sauce (or see curry spices below)",
                "1 cup grated carrots",
                "3 eggs, whisked",
                "1 cup shredded cheese (optional, for chicken and cheese version)",
                "Salt and pepper to taste",
                "1 lb chopped godhamba roti or flour tortillas (substitutes include paratha or roti canai)",
                // Curry Spices (if not using leftover curry sauce)
                "1 tbsp Sri Lankan curry powder",
                "⅓ cup chicken stock",
                "¼ tsp black pepper",
                "½ tsp cayenne pepper (optional, for heat)",
                "½ tsp ground cinnamon"
            ],
            prePrepInstructions: [
                "Chop all vegetables and prepare the shredded chicken.",
                "If not using leftover curry sauce, combine the curry spices into a mixture for later use.",
                "Prepare the roti by chopping it into small pieces or shredding if possible."
            ],
            instructions: [
                "Heat vegetable oil in a large wok or non-stick pan over medium-high heat.",
                "Add the sliced onion and sauté until softened. Add minced garlic and ginger, and sauté for a few seconds, ensuring they don't burn.",
                "Add the peppers, leeks, cabbage, and a pinch of salt. Stir-fry for a few minutes until starting to soften.",
                "Add shredded chicken, cayenne pepper, and curry sauce (or the prepared curry spice mixture) and mix well.",
                "Add grated carrots and stir to combine.",
                "Create a well in the center of the pan, pour in the whisked eggs, and scramble them until almost cooked. Mix the eggs with the rest of the ingredients.",
                "If making chicken and cheese kottu, add shredded cheese and stir until melted and combined.",
                "Add the chopped roti pieces and mix thoroughly to coat them with the spices and curry sauce. Stir frequently and cook for about 5 minutes until heated through.",
                "Serve hot with extra curry sauce, if desired."
            ],
            notes: """
            Adjust spice level by reducing or de-seeding the chili peppers, but keep them for added flavor.
            Substitutes for godhamba roti include roti canai, paratha, or flour tortillas.
            Try alternative proteins like cooked beef, pork, or extra vegetables for variation.
            Additional spices like mustard seeds or fennel seeds can enhance flavor.
            """
        )
        saveRecipe(
            name: "Korean Cucumber Salad (Oi Muchim)",
            prepTime: "5 minutes",
            cookingTime: "0 minutes",
            ingredients: [
                "1 English cucumber",
                // Dressing
                "2 cloves garlic, minced",
                "1 tablespoon regular soy sauce",
                "1 tablespoon sesame oil",
                "2 teaspoons gochugaru or gochujang",
                "2 teaspoons rice vinegar, apple cider vinegar, or white vinegar",
                "1 teaspoon white granulated sugar",
                "1 teaspoon sesame seeds"
            ],
            prePrepInstructions: [
                "Slice the ends off the cucumber and thinly slice into ¼-inch thick pieces."
            ],
            instructions: [
                "Transfer the sliced cucumbers into a large bowl.",
                "In a small bowl, combine all dressing ingredients as listed.",
                "Pour the dressing over the cucumber pieces in the large bowl.",
                "Mix well until the cucumbers are evenly coated in the dressing.",
                "Enjoy immediately or chill in the fridge for 10 minutes for enhanced flavor."
            ],
            notes: """
            For added crunch, chill the cucumber slices before preparing the salad.
            Gochugaru provides a subtle smoky heat, while gochujang adds a richer flavor—use based on your preference.
            Adjust the vinegar and sugar to suit your taste for a balance of tanginess and sweetness.
            """
        )
        saveRecipe(
            name: "Gochujang Chicken (Easy Sweet Spicy)",
            prepTime: "15 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "755 grams boneless skinless chicken thighs, diced",
                "0.83 onion or red onion, diced",
                "83.33 g cornstarch",
                "100 ml vegetable oil or any neutral oil",
                "1.67 green onion, finely sliced (optional garnish)",
                "1.67 g sesame seeds, toasted (optional garnish)",
                // Sauce
                "3.33 cloves garlic, minced",
                "3.33 tbsp (40 g) white granulated sugar, or sub with honey or brown sugar",
                "3.33 tbsp (50 ml) Gochujang",
                "3.33 tbsp (50 ml) regular soy sauce (not dark soy sauce)",
                "3.33 tsp (6.67 g) sesame seeds, toasted",
                "1.67 tsp (8.33 ml) sesame oil, toasted",
                "1.67 tbsp (16.67 g) cornstarch or potato starch",
                "1.67 cup (416.67 ml) water, cold or room temperature"
            ],
            prePrepInstructions: [
                "Dice the chicken thighs into 1.5-inch pieces.",
                "Place the diced chicken in a large mixing bowl and set aside.",
                "In a small bowl, combine all sauce ingredients and set aside."
            ],
            instructions: [
                "Add cornstarch to the bowl of diced chicken. Toss until the chicken is evenly coated in starch.",
                "In a large pan over medium-high heat, heat vegetable oil. Fry the coated chicken until golden brown and crispy, about 5-6 minutes per side.",
                "Remove the chicken from the pan and transfer to a wire rack or paper towel-lined plate to drain off excess oil.",
                "In the same pan on medium-high heat, fry the diced onions until translucent, about 30-45 seconds.",
                "Pour the prepared sauce into the pan and simmer until it thickens.",
                "Once the sauce thickens, reduce the heat to medium. Add the fried chicken to the pan and toss to coat evenly in the sauce.",
                "Garnish with green onions and toasted sesame seeds if desired. Serve and enjoy!"
            ],
            notes: """
            For a sweeter flavor, substitute white sugar with honey or brown sugar.
            Adjust the amount of gochujang to control the level of spiciness.
            Serve with steamed rice or noodles for a complete meal.
            """
        )
        saveRecipe(
            name: "Lamb Stew (Slow Cooker)",
            prepTime: "20 minutes",
            cookingTime: "8 hours",
            ingredients: [
                "907.18 g boneless leg of lamb or lamb shoulder, trimmed of excess fat and cut into 1 1/2\" pieces",
                "1 teaspoon sea salt, or to taste",
                "1 teaspoon ground black pepper",
                "31.25 g all-purpose flour",
                "1 medium yellow onion, diced",
                "4 cloves garlic, minced",
                "840 g beef broth, low sodium",
                "453.59 g baby Bella mushrooms, thickly sliced",
                "2 tablespoons Worcestershire sauce",
                "2 bay leaves",
                "1 teaspoon fresh rosemary, finely chopped",
                "680.39 g red potatoes, halved or quartered",
                "3 medium carrots, peeled and cut into 1/2\" thick pieces",
                "2 celery ribs, chopped",
                "145 g frozen sweet peas",
                // Garnish
                "15 g parsley, finely chopped",
                "Fresh rosemary for garnish"
            ],
            prePrepInstructions: [
                "In a large bowl, toss lamb meat with salt, pepper, and all-purpose flour.",
                "Prepare and dice all vegetables as listed in the ingredients."
            ],
            instructions: [
                "Place a large skillet over medium heat and add olive oil. Once hot, brown the lamb meat on each side for about 3-5 minutes. This step is optional but recommended for enhanced flavor.",
                "Transfer all ingredients, except for the green peas, to the slow cooker.",
                "Cover and cook on LOW heat for 7-8 hours, or HIGH for 3-4 hours.",
                "Add the green peas during the last hour of cooking.",
                "Garnish with freshly chopped parsley and fresh rosemary. Serve warm!"
            ],
            notes: """
            For best results, brown the lamb meat before adding it to the slow cooker to lock in the flavor.
            Adjust salt to your preference as beef broth may already contain sodium.
            This dish pairs perfectly with crusty bread or steamed rice for a hearty meal.
            """
        )
        saveRecipe(
            name: "Lauki Chana Dal (Instant Pot)",
            prepTime: "1 hour (soaking)",
            cookingTime: "10 minutes",
            ingredients: [
                "1 cup chana dal, soaked for 1 hour",
                "1 tablespoon oil or ghee",
                "1 teaspoon cumin seeds",
                "1 bay leaf",
                "2 black cardamom",
                "1 lauki (approx. 1 ½ pounds), peeled and cut into 2-inch pieces",
                "2 cups water",
                "½ cup frozen or thawed onion masala",
                "1 teaspoon salt",
                "½ teaspoon garam masala",
                "¼ teaspoon black pepper",
                "¼ teaspoon cayenne/Indian red chili powder, to taste",
                "Cilantro for garnish"
            ],
            prePrepInstructions: [
                "Soak the chana dal in cold water for 1 hour. Drain, rinse, and set aside."
            ],
            instructions: [
                "Press the sauté button on the Instant Pot and add oil/ghee. Allow it to heat up for a minute.",
                "Add cumin seeds, bay leaf, and black cardamom to the pot. Once the cumin seeds brown, add the remaining ingredients.",
                "Secure the lid, close the pressure valve, and cook for 10 minutes at high pressure.",
                "Naturally release the pressure.",
                "Taste and adjust salt and cayenne if desired.",
                "Garnish with cilantro and serve."
            ],
            notes: """
            Soaking the chana dal for an hour is essential to ensure it becomes tender during cooking.
            This recipe is part of an onion masala series – you can use frozen cubes of onion masala directly without thawing.
            Serve this comforting dish with rice or roti for a wholesome meal.
            """
        )
        saveRecipe(
            name: "Lavender Earl Grey Shortbread Cookies",
            prepTime: "5 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "1 stick unsalted butter, room temperature",
                "32 g cane sugar",
                "1 earl grey tea bag (contents only)",
                "1/4 tsp salt",
                "8 g milk powder",
                "120 g all-purpose flour",
                "1.5 tbsp dried lavender",
                "glazeIngredients:",
                "115 g powdered sugar",
                "45 g milk"
            ],
            
            prePrepInstructions: [
                "Gather all ingredients and ensure butter is at room temperature.",
                "Prepare baking sheet with silicone baking mat or parchment paper.",
                "Tear sheets of plastic wrap for rolling the dough."
            ],
            instructions: [
                "Cream together butter and sugar. Then add in salt, tea leaves, and milk powder. Once incorporated, mix in the flour and 1 tbsp of dried lavender to form a thick batter.",
                "For the 'roll and cut' method: Place cookie dough between two sheets of plastic wrap. Roll out to about 1/4 inch thick and chill in the refrigerator for at least 30 minutes.",
                "Remove dough from the fridge, sprinkle with reserved 1/2 tbsp of lavender, and lightly press it into the dough using a rolling pin. Chill again for another 30 minutes.",
                "Preheat oven to 350°F. Remove dough from fridge and cut into squares or desired shapes using a cookie cutter. Place on prepared baking sheet, spacing cookies 4 inches apart.",
                "Bake for about 15 minutes or until the edges start to turn brown. Remove from oven and let cool completely on the baking sheet to avoid breaking the cookies.",
                "Prepare the glaze by mixing powdered sugar and milk until thick and smooth. Optionally, add some tea leaves to the glaze.",
                "Drizzle the glaze over the cooled cookies and let it dry completely, approximately 1 hour."
            ],
            notes: """
            Ensure the dough is properly chilled before cutting to maintain shape during baking.
            Handle the cookies carefully after baking as they can be fragile when warm.
            For extra flavor, infuse some lavender or tea leaves into the glaze.
            RestingTime: "1 hour 30 minutes",
            """
        )
        saveRecipe(
            name: "Lychee Coconut Jelly",
            prepTime: "30 minutes",
            cookingTime: "4 hours (resting)",
            ingredients: [
                "1.5 cups lychee juice",
                "¾ teaspoon agar agar powder",
                "1.5 cups coconut milk, full fat",
                "¾ teaspoon agar agar powder"
            ],
            prePrepInstructions: [
                "Prepare an 8 x 6 inch rectangle container for layering the jelly.",
                "Ensure you have two small pots ready for cooking each layer.",
                "Gather all ingredients and measure them out for convenience."
            ],
            instructions: [
                "In a small pot, whisk together the lychee juice and agar agar powder. Bring to a boil, then lower to a simmer and keep covered on low heat.",
                "In another small pot, whisk together the coconut milk and agar agar powder. Bring to a boil, then lower to a simmer and keep covered on low heat.",
                "Pour ½ cup of the lychee mixture into the prepared container and let it set for about 5 minutes, or until firm to the touch.",
                "Once the first layer is set, pour ½ cup of the coconut mixture over the lychee layer using the back of a spoon to avoid breaking the set layer. Let it set completely.",
                "Continue alternating layers of lychee and coconut mixtures, allowing each layer to set before adding the next.",
                "Cover the container and refrigerate for at least 4 hours or overnight until fully set.",
                "Slice into pieces and serve with fresh fruit if desired. Enjoy!"
            ],
            notes: """
            For best results, pour each new layer gently over the back of a spoon to avoid disturbing the previous layer.
            Keep both mixtures on low heat and covered to prevent them from setting too quickly while you work.
            Fresh fruit, such as lychee or mango, makes an excellent garnish for serving.
            """
        )
        saveRecipe(
            name: "Lamb Chops",
            prepTime: "30 minutes (marinating time)",
            cookingTime: "10-15 minutes",
            ingredients: [
                "1 kg lamb chops (rib chops)",
                "1 & ½ tsp salt",
                "2 tsp smoked paprika",
                "2 tsp cumin",
                "1 tsp cracked black pepper",
                "2 tsp oregano",
                "4 tbsp olive oil",
                "Optional: juice of 1 lemon",
                "Sliced onions",
                "Sliced bell peppers"
            ],
            prePrepInstructions: [
                "Wash the lamb chops thoroughly.",
                "Place the lamb chops in a mixing bowl and add olive oil. Mix thoroughly to enable the seasoning to be absorbed.",
                "Combine smoked paprika, ground cumin, cracked black pepper, salt, and oregano in a plate.",
                "Add the spice mixture to the lamb and mix in thoroughly.",
                "Marinate for at least 30 minutes to allow the flavors to develop."
            ],
            instructions: [
                "Heat a saucepan over medium-high heat and fry the lamb chops until browned on both sides, flipping frequently to ensure even cooking.",
                "Alternatively, place the lamb chops onto a foil-lined baking tray, spaced apart, and grill in a preheated oven for 5-7 minutes until browning. Flip the chops and grill for another 5-7 minutes. Be careful not to overcook.",
                "In a separate skillet or pan, fry the sliced onions and bell peppers until softened and slightly caramelized.",
                "Place the lamb chops on top of the onions and bell peppers for serving."
            ],
            notes: """
            For added flavor, squeeze the juice of one lemon over the lamb chops before serving.
            Ensure not to overcook the lamb to maintain its tenderness.
            Serve with a side of salad, rice, or flatbread for a complete meal.
            """
        )
        saveRecipe(
            name: "Lemon Drizzle Cake",
            prepTime: "15 minutes",
            cookingTime: "45 minutes",
            ingredients: [
                "225g unsalted butter, softened",
                "225g caster sugar",
                "4 eggs",
                "225g self-raising flour",
                "Finely grated zest of 1 lemon",
                "Juice of 1 ½ lemons (for drizzle topping)",
                "85g caster sugar (for drizzle topping)"
            ],
            prePrepInstructions: [
                "Preheat the oven to 180°C (fan 160°C/gas 4).",
                "Line an 8 x 21cm loaf tin with greaseproof paper."
            ],
            instructions: [
                "Beat together the softened butter and caster sugar until pale and creamy.",
                "Add the eggs one at a time, slowly mixing them into the batter.",
                "Sift in the self-raising flour, then add the finely grated lemon zest and mix until well combined.",
                "Spoon the mixture into the prepared loaf tin and level the top with a spoon.",
                "Bake for 45-50 minutes, or until a thin skewer inserted into the center of the cake comes out clean.",
                "While the cake is cooling in the tin, mix the lemon juice and caster sugar to make the drizzle topping.",
                "Prick the warm cake all over with a skewer or fork, then pour over the drizzle. The juice will sink in and the sugar will form a crisp topping.",
                "Leave the cake in the tin until completely cool, then remove and serve."
            ],
            notes: """
            The cake will keep in an airtight container for 3-4 days or can be frozen for up to 1 month.
            For best results, ensure the butter is fully softened before mixing.
            Serve as is or with a dollop of cream or ice cream for added indulgence.
            """
        )
        saveRecipe(
            name: "Lotus Biscoff Frappe",
            prepTime: "5 minutes",
            cookingTime: "0 minutes",
            ingredients: [
                "1 tsp coffee",
                "2 tsp sugar",
                "30 ml hot water (approximately ⅓ cup)",
                "40-50 ml milk (approximately ⅓ cup)",
                "Handful of ice cubes (approximately 6)",
                "1 tbsp + 1 tsp Lotus Biscoff spread",
                "1 Lotus Biscoff biscuit"
            ],
            prePrepInstructions: [
                "Prepare all ingredients.",
                "Ensure the hot water is ready for dissolving coffee and sugar."
            ],
            instructions: [
                "Stir and dissolve coffee and sugar in hot water.",
                "Add milk and 1 tbsp Lotus Biscoff spread, then stir to combine.",
                "Add ice cubes to the mixture and shake well.",
                "Serve in a glass with additional ice cubes and a Lotus Biscoff biscuit on the side.",
                "Alternate instructions:",
                "Stir and dissolve coffee and sugar in hot water.",
                "Add 1 tbsp Lotus Biscoff spread and stir until dissolved.",
                "Smear 1 tsp Lotus Biscoff spread on the side of the serving glass.",
                "Add ice cubes and milk to the serving glass.",
                "Pour the coffee and Biscoff mixture into the glass.",
                "Serve with a Lotus Biscoff biscuit."
            ],
            notes: """
            Adjust sugar to taste for sweetness preference.
            For a creamier frappe, use whole milk or a milk alternative like oat or almond milk.
            Best enjoyed immediately for maximum flavor and texture.
            """
        )
        saveRecipe(
            name: "Lamb Biryani (Slow Cooker)",
            prepTime: "4 hours (including marination time)",
            cookingTime: "3 hours 30 minutes",
            ingredients: [
                "1 kg lamb pieces (mixture of bone and meat)",
                "1 packet Laziza biryani mix",
                "1 pot full-fat yoghurt (75% for marinade, 25% for raita)",
                "4.5 cups jasmine rice, cooked",
                "2 medium potatoes",
                "2 carrots",
                "1 bag broad beans (or substitute with ½ cauliflower, ½ broccoli, peas, or mushrooms)",
                "3 medium onions",
                "2 inches garlic",
                "Plenty of oil",
                "1.5 tsp turmeric",
                "1/2 tsp chilli powder",
                "Cucumber (for raita)",
                "Mint (for raita)",
                "Coriander (for raita)",
                "1-2 chillies"
            ],
            prePrepInstructions: [
                "Marinate 1 kg lamb with 7 tbsp yoghurt, 1.5 tsp turmeric, 1/2 tsp chilli powder, and ¾ packet of Laziza biryani mix for 4 hours or preferably overnight.",
                "Soak 4.5 cups of jasmine rice in water for cooking later."
            ],
            instructions: [
                "Cook the marinated lamb on high in the slow cooker for 2 hours and 45 minutes, covering it with foil.",
                "Fry sliced onions in plenty of oil until browned, then set aside for garnishing.",
                "Cook the rice with minimal water (use water level suitable for 4.25 cups of rice).",
                "In the leftover onion oil, fry ¼ packet of Laziza biryani mix and add the vegetables (potatoes, carrots, and broad beans or substitutes). Cook until the vegetables are tender.",
                "Add the cooked vegetables to the lamb in the slow cooker and mix.",
                "Layer the cooked rice, fried onions, and fresh chillies on top of the lamb and vegetable mixture.",
                "Cover the slow cooker with the lid and cook on high for an additional 40-45 minutes, stirring gently at the 20-minute mark.",
                "Serve hot once the lamb is tender and fully cooked."
            ],
            notes: """
            For best results, marinate the lamb overnight to allow flavors to develop fully.
            Use high-quality jasmine rice to ensure the perfect texture and flavor.
            Raita can be prepared by mixing the reserved yoghurt with chopped cucumber, mint, coriander, and finely diced chillies.
            Adjust the spice level by varying the amount of chilli powder and fresh chillies.
            """
        )
        saveRecipe(
            name: "Lamb Shanks (Slow Cooker)",
            prepTime: "20 minutes",
            cookingTime: "4 hours",
            ingredients: [
                "1 onion, sliced",
                "2 cloves garlic, finely chopped",
                "1 glug olive oil",
                "2 lamb shanks (approx. 1kg)",
                "1 tsp ground cumin",
                "1/2 tsp ground turmeric",
                "1 tsp ground cinnamon",
                "1 tbsp tomato purée",
                "4 plum tomatoes, chopped",
                "1 pinch saffron",
                "400 ml chicken stock",
                "1 tsp cornflour",
                "2 cups rice",
                "1 egg or 1 tbsp chicken broth (for rice)"
            ],
            prePrepInstructions: [
                "Set your slow cooker to a high heat.",
                "Slice the onion and finely chop the garlic."
            ],
            instructions: [
                "Heat olive oil in an oven-proof saucepan and brown the lamb shanks on all sides.",
                "Remove the lamb shanks and place them into the slow cooker.",
                "Add the onion, garlic, and dry spices (cumin, turmeric, cinnamon) to the slow cooker.",
                "Squeeze in the tomato purée, add the chopped tomatoes, saffron, and chicken stock.",
                "Cover the slow cooker and cook for a minimum of 4 hours.",
                "Prepare the rice in a rice cooker. Once cooked, stir in either a beaten egg or chicken broth. If using egg, fry the rice briefly in a pan with some oil.",
                "After the lamb shanks are cooked, remove them from the slow cooker.",
                "Mix the cornflour with a little cold water and stir it into the remaining sauce in the slow cooker to thicken.",
                "Let the sauce bubble for another minute or two, then serve the lamb shanks over the rice with a generous amount of sauce poured on top."
            ],
            notes: """
            Ensure the lamb shanks are browned evenly to enhance flavor before slow cooking.
            Adjust spices to suit your taste preference for a more or less intense flavor.
            Use saffron sparingly as it has a strong flavor and aroma.
            This dish pairs well with a side of sautéed vegetables or a fresh salad.
            """
        )
        saveRecipe(
            name: "Lactose Free Meat Lasagne",
            prepTime: "1 hour 20 minutes",
            cookingTime: "40 minutes",
            ingredients: [
                // White Sauce
                "25g butter",
                "25g plain flour",
                "500ml hot lactose-free milk",
                "¼ grated onion",
                "1.5 cloves",
                "25g lactose-free cheese, grated",
                "1 pinch salt and ground black pepper",
                // Meat Sauce
                "500g minced lamb or beef",
                "500g Baresa Lasagne ragu sauce",
                "3-5 mushrooms, chopped",
                "1 bell pepper, diced",
                "1 small bowl spinach",
                "1-2 carrots, diced",
                "1 bag lasagne sheets",
                "1 can chopped tomatoes",
                "2 vegetable stock cubes",
                "1 onion, cubed",
                "3-4 garlic cloves, minced",
                "1-1.5 tsp salt",
                "1-1.5 tsp chili flakes",
                "1-1.5 tsp sugar",
                "0.5-1 tsp cumin",
                "0.5-1 tsp hot paprika",
                "0.5-1 tsp oregano",
                "Approx. 1 cup water",
                "1 tbsp tomato paste",
                "1 tbsp olive oil",
                "400g x2 lacto-free grated mature cheddar cheese"
            ],
            prePrepInstructions: [
                "Infuse milk for bechamel sauce: Add thickly sliced onion and cloves to milk in a saucepan, gently bring to a boil, then turn off heat and set aside for 1 hour.",
                "Strain infused milk through a fine sieve into a jug.",
                "If required, prepare lasagne sheets by boiling water in a saucepan, submerging the sheets, and boiling for 2 minutes. Turn off heat and set aside."
            ],
            instructions: [
                "Melt butter in a saucepan for white sauce. Add flour and cook for 1 minute, then gradually whisk in the hot milk until thickened. Add cheese, salt, and pepper to taste.",
                "Cube the onion and sauté it in olive oil. Add minced meat and cook until browned.",
                "Add lasagne ragu sauce, chopped tomatoes, garlic, stock cubes, cumin, hot paprika, oregano, tomato paste, water, and chili flakes to the meat. Stir to combine.",
                "Add salt and sugar to taste, then mix in mushrooms, bell pepper, and carrots. Check if carrots are cooked, then add spinach and bring to a boil.",
                "Preheat oven to 200°C or 180°C fan-assisted.",
                "In an oven tray, spread a spoonful of sauce on the bottom layer. Layer with lasagne sheet, cheese, sauce, and repeat for 3 layers. Top with cheese.",
                "Cover the tray with foil and bake for 40 minutes. Remove foil and bake until cheese is melted and golden.",
                "Remove from oven and let settle for 10 minutes before serving."
            ],
            notes: """
            Ensure milk is infused for the bechamel sauce for the best flavor.
            For gluten-free options, substitute plain flour and lasagne sheets with gluten-free alternatives.
            Add additional vegetables or herbs to customize the recipe to your taste.
            """
        )
        saveRecipe(
            name: "Lotus Biscoff Cupcakes",
            prepTime: "1 hour",
            cookingTime: "20 minutes",
            ingredients: [
                // Buttery Biscoff Base
                "100g crushed Lotus biscuits (or any tasty biscuit)",
                "15g melted butter",
                "1 tsp golden syrup",
                // Sponge
                "125g self-raising flour",
                "100g caster sugar",
                "25g dark brown soft sugar",
                "1/4 tsp bicarbonate of soda",
                "Pinch of salt",
                "125g soft butter",
                "2 large eggs",
                "1.5 tbsp milk",
                // Filling
                "100g double/heavy cream",
                "1 generous tbsp Lotus Biscoff spread or cookie butter",
                // Swiss Meringue Buttercream
                "4 large egg whites",
                "300g caster sugar",
                "400g unsalted butter, chopped and softened",
                "1 tsp vanilla extract",
                "150g slightly warmed Biscoff spread"
            ],
            prePrepInstructions: [
                "Crush Lotus biscuits into crumbs and mix with melted butter and golden syrup for the base.",
                "Preheat oven to 180°C (350°F) and line a cupcake tray with cases.",
                "Slightly warm the Biscoff spread for the buttercream to make it easier to incorporate."
            ],
            instructions: [
                "Combine the crushed biscuits, melted butter, and golden syrup to make the base. Press a small amount into the bottom of each cupcake case and set aside.",
                "In a mixing bowl, combine self-raising flour, caster sugar, dark brown sugar, bicarbonate of soda, and salt.",
                "Add the soft butter, eggs, and milk to the dry ingredients. Mix until smooth.",
                "Spoon the batter over the biscuit base in the cupcake cases, filling each about 2/3 full.",
                "Bake the cupcakes for 20 minutes or until a skewer inserted into the center comes out clean. Let cool completely.",
                "Whip the double/heavy cream until stiff peaks form, then fold in a generous tablespoon of Biscoff spread to make the filling.",
                "Core the center of each cooled cupcake and fill with the Biscoff cream mixture.",
                "To make the Swiss Meringue Buttercream, whisk egg whites and caster sugar over a double boiler until the sugar dissolves. Beat until stiff peaks form and cool to room temperature. Gradually add softened butter and vanilla extract, then mix in the warmed Biscoff spread.",
                "Pipe the buttercream onto the cupcakes and garnish as desired."
            ],
            notes: """
            Use room-temperature ingredients for the best texture in the sponge and buttercream.
            Store cupcakes in an airtight container at room temperature for up to 2 days or refrigerate for longer storage.
            Add crushed biscuits or a drizzle of Biscoff spread on top for extra decoration.
            """
        )
        saveRecipe(
            name: "Lemon Sponge Cake",
            prepTime: "15 minutes",
            cookingTime: "20-25 minutes",
            ingredients: [
                // Cake Ingredients
                "225g self-raising flour + 1 tsp",
                "200g caster sugar",
                "2 tsp baking powder",
                "225g soft unsalted butter",
                "3 eggs",
                "2 tbsp lemon juice (juice of two lemons)",
                "Pinch of salt",
                // Strawberry Filling
                "2 tbsp (43g) strawberry jam",
                "1 pint (241g) fresh strawberries",
                "1 tbsp icing sugar"
            ],
            prePrepInstructions: [
                "Preheat the oven to 190°C (374°F).",
                "Grease two 20cm cake tins, then dust them with flour."
            ],
            instructions: [
                "In a mixing bowl, cream together the sugar and butter until light and fluffy.",
                "Add the eggs one at a time, beating well after each addition.",
                "Mix in the lemon juice.",
                "Gently fold in the self-raising flour and baking powder, being careful not to overmix.",
                "Divide the batter evenly between the two prepared cake tins.",
                "Bake in the preheated oven for 20-25 minutes, or until the cakes are golden and a skewer inserted into the center comes out clean.",
                "Allow the cakes to cool completely in the tins before removing them.",
                "For the filling, spread strawberry jam evenly over one of the cake layers.",
                "Arrange the fresh strawberries on top of the jam layer.",
                "Place the second cake layer on top and dust with icing sugar before serving."
            ],
            notes: """
            To enhance the lemon flavor, add some finely grated lemon zest to the batter.
            Ensure the cakes are fully cooled before assembling to prevent the filling from melting.
            Serve with whipped cream or a dollop of Greek yogurt for added indulgence.
            """
        )
        saveRecipe(
            name: "Mac and Cheese",
            prepTime: "10 minutes",
            cookingTime: "25-30 minutes",
            ingredients: [
                // Pasta
                "1 tsp salt",
                "250g macaroni pasta",
                // Cheese Sauce
                "2 tbsp butter",
                "1 tbsp all-purpose flour",
                "1/2 tsp garlic granules",
                "2 cups (370ml) milk",
                "1/2 tsp salt (or to taste)",
                "1/2 tsp cumin powder",
                "1 tsp paprika powder",
                "1 cup shredded cheddar cheese (add more if desired)",
                "3-5 slices gouda cheese",
                "2 tbsp double cream",
                "Sriracha sauce (optional)",
                // Topping
                "Extra shredded cheddar cheese",
                "Shredded Leicester cheese"
            ],
            prePrepInstructions: [
                "Bring a pot of water to a boil and add 1 tsp of salt.",
                "Add 250g macaroni pasta and boil for 8-10 minutes, or until al dente.",
                "Drain the pasta and rinse with cold water. Set aside."
            ],
            instructions: [
                "In a saucepan, melt the butter over medium heat.",
                "Add paprika powder, garlic granules, cumin powder, and all-purpose flour. Stir thoroughly to form a paste and cook until slightly browned.",
                "Gradually add milk while whisking continuously until the mixture is smooth and thick.",
                "Season with 1/2 tsp of salt (or to taste).",
                "Reduce the heat to low and stir in the shredded cheddar and gouda cheese slices until melted.",
                "Add double cream and whisk until the sauce is thick and smooth.",
                "Combine the cooked pasta with the cheese sauce and mix well.",
                "Transfer the mac and cheese to a large ovenproof dish.",
                "Top with Sriracha sauce (optional) and sprinkle with extra shredded cheddar and Leicester cheese.",
                "Bake at 180°C (350°F) for 15-20 minutes or until the top is crisp and golden."
            ],
            notes: """
            Use your favorite combination of cheeses for the sauce and topping to customize the flavor.
            Serve with a side salad or garlic bread for a complete meal.
            Adjust the amount of Sriracha sauce for desired spiciness.
            """
        )
        saveRecipe(
            name: "Malaysian Curry Puff (Easy & Crispy Karipap)",
            prepTime: "1 hr 20 mins",
            cookingTime: "20 mins",
            ingredients: [
                // For frying
                "500-750 ml vegetable oil for frying",
                // Filling
                "150 grams skinless boneless chicken thighs, finely chopped",
                "430 grams potatoes, peeled & small diced",
                "0.5 small onion, finely diced",
                "2 bay leaves",
                "4 tsp curry powder",
                "0.5 tsp turmeric powder",
                "0.5 tsp salt",
                // Wrapper
                "500 grams all-purpose flour",
                "1.25 cup water, room temperature",
                "1 tsp salt",
                "0.33 cup + 3 tbsp vegetable oil"
            ],
            prePrepInstructions: [
                "Prepare all the ingredients: dice the potatoes, onions, and chicken thighs.",
                "Measure out the flour, salt, curry powder, turmeric powder, and oil."
            ],
            instructions: [
                "Heat 1 teaspoon of vegetable oil in a large pan on medium heat. Fry the chicken until 80% cooked.",
                "Add onions and potatoes to the pan, followed by curry powder, salt, turmeric, and bay leaves. Cover and cook until the potatoes are fork-tender. Remove the filling from the pan and allow it to cool completely.",
                "In a large mixing bowl, whisk together all-purpose flour and salt. Make a well in the center.",
                "In a small saucepan, heat ⅓ cup + 3 tablespoons of vegetable oil on high heat. Once hot, pour the oil carefully into the flour well. Let it bubble for 1 minute, then mix with the flour.",
                "Add water and knead the mixture into a smooth, oiled ball of dough.",
                "On a floured surface, roll the dough into a long log and slice into 26 equal pieces. Roll each piece into a ball.",
                "Use a rolling pin to flatten each ball into a 4-inch wide circular wrapper.",
                "Place 1 tablespoon of the cooled filling onto the center of each wrapper. Fold the wrapper over the filling and pinch the edges to seal completely.",
                "Pleat the edges using your thumb for a decorative finish.",
                "Heat 2 inches of vegetable oil in a large pan over medium heat. Check for readiness by inserting a chopstick or wooden spoon; if bubbles form, the oil is hot enough.",
                "Carefully fry 5-6 curry puffs at a time for 2 minutes per side or until golden brown.",
                "Remove the fried curry puffs from the oil using a slotted spoon and transfer to a wire rack or paper towel-lined baking sheet to cool.",
                "Serve and enjoy your crispy Malaysian curry puffs!"
            ],
            notes: """
            To save time, you can prepare the filling a day ahead and store it in the refrigerator until ready to use.
            Pleating the edges creates a more traditional look but can be skipped if time is limited.
            These curry puffs can be frozen before frying for later use. Fry directly from frozen, adjusting cooking time slightly.
            """
        )
        saveRecipe(
            name: "Malaysian Curry Wings (Easy Baked Crispy)",
            prepTime: "10 mins",
            cookingTime: "35 mins",
            ingredients: [
                "750 g chicken wings (or 15 wings)",
                "1 shallot, peeled and chopped",
                "3 tbsp lemongrass, white bulbous part only, finely sliced",
                "1 tbsp ginger, peeled",
                "1 clove garlic, minced",
                "3 tbsp water, cold",
                "1 tbsp regular soy sauce",
                "1 tbsp curry powder",
                "1/2 tbsp turmeric powder",
                "1/2 tbsp white granulated sugar",
                "2 tsp Shaoxing Cooking Wine",
                "1/2 tsp salt",
                "1/2 cup potato starch",
                // Optional garnish
                "1 green onion, finely diced"
            ],
            prePrepInstructions: [
                "Rinse the chicken wings under cold water and strain them. Transfer the wings to a large mixing bowl.",
                "Preheat your oven to 425°F."
            ],
            instructions: [
                "In a mortar & pestle or food processor, add shallot, lemongrass, garlic, ginger, and salt. Pulverize into a thick paste (it doesn’t need to be completely smooth).",
                "Add the aromatic paste to the bowl of chicken wings.",
                "Add the remaining ingredients, with potato starch being the last addition. Mix well to ensure the wings are evenly coated in a batter-like consistency.",
                "Line a baking sheet with parchment paper. Before placing the wings on the sheet, give them one final mix to ensure even coating.",
                "Lay the wings in a single layer on the baking sheet, leaving enough space between them.",
                "Reduce the oven temperature to 400°F and bake the wings for 35 minutes, flipping them halfway through the cooking time.",
                "Once done, remove from the oven and optionally garnish with finely diced green onions.",
                "Serve and enjoy!"
            ],
            notes: """
            For an even crispier texture, you can broil the wings for 1-2 minutes at the end of the baking time, but watch carefully to avoid burning.
            If you don't have Shaoxing Cooking Wine, you can substitute it with dry sherry or omit it altogether.
            Serve with your favorite dipping sauce for added flavor.
            """
        )
        saveRecipe(
            name: "Mandarin Coconut Sponge Cake",
            prepTime: "15 minutes",
            cookingTime: "20-25 minutes",
            ingredients: [
                "225g self-raising flour + 1 tsp",
                "200g caster sugar",
                "2 tsp baking powder",
                "225g soft unsalted butter",
                "3 eggs",
                "2 tbsp mandarin juice (juice from a can)",
                "Pinch of salt",
                "10ml vegetable oil",
                "600ml double cream (2 x 300ml cans)",
                "600g canned mandarins (2 x 300g cans)",
                "1 tbsp cornstarch or 3 tbsp icing sugar",
                "Dessicated coconut (for toasting)"
            ],
            prePrepInstructions: [
                "Preheat the oven to 190°C (170°C fan/gas 5).",
                "Toast the desiccated coconut on a foil-lined baking sheet for 4-6 minutes or until golden brown.",
                "Grease two 20cm cake tins and dust with flour."
            ],
            instructions: [
                "Cream together the sugar and butter in a mixing bowl.",
                "Add the eggs one at a time, mixing thoroughly after each addition.",
                "Add the mandarin juice and mix until combined.",
                "Gently fold in the self-raising flour and baking powder until the batter is smooth.",
                "Divide the batter evenly between the prepared cake tins.",
                "Bake for 20-25 minutes or until a skewer inserted into the center of the cakes comes out clean.",
                "Cool the cakes in their tins for 10 minutes before transferring them to a wire rack to cool completely.",
                "Brush vegetable oil over the tops of the cooled cakes.",
                "Chill the bowl and whisk attachment of a stand mixer for 7-10 minutes to speed up whipping the cream.",
                "Whip the double cream in the chilled bowl, gradually adding the sugar or cornstarch for stabilization. Whip until firm peaks form.",
                "Layer half the whipped cream onto the base layer of the cake. Sprinkle with toasted coconut and arrange mandarin segments, reserving a few for topping.",
                "Add the second cake layer on top. Spread the remaining cream over the top and sprinkle with more toasted coconut. Garnish with the reserved mandarin segments."
            ],
            notes: """
            Be careful not to over-whip the cream, as it may separate.
            The toasted coconut adds texture and a nutty flavor; toast it lightly for the best results.
            Use the juice from the canned mandarins for extra flavor in the sponge.
            """
        )
        saveRecipe(
            name: "Mango Sago (Quick & Easy 4-ingredient)",
            prepTime: "20 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "3 large mangos, fully ripe (about 750 grams or 1.7 lbs)",
                "115 g small tapioca pearls, uncooked (do not use minute tapioca)",
                "80 ml condensed milk (or condensed coconut milk for a vegan alternative)",
                "400 ml whole fat coconut milk at room temperature"
            ],
            prePrepInstructions: [
                "Peel and slice 2 large mangos, removing the pit. Reserve the remaining mango for topping.",
                "Open canned coconut milk and stir well to combine the fats and water inside the can."
            ],
            instructions: [
                "In a medium-sized pot of water (about 5 cups), bring to a boil on high heat. Once boiling, add tapioca pearls.",
                "Reduce to medium heat or a rolling boil and boil uncovered for 10 minutes, stirring occasionally.",
                "Turn off the heat, cover, and let sit for another 10 minutes until the pearls are completely translucent. If a small white dot remains in the center, let them sit in the hot water covered for another 2-3 minutes.",
                "Strain the cooked pearls in a fine mesh sieve and rinse with cold running water until cool. Strain out excess water and transfer to a large bowl.",
                "Combine the coconut milk with the cooked tapioca pearls and mix well to form the sago mixture.",
                "Place the peeled mango pieces into a blender or food processor with condensed milk. Blend until smooth. If components get stuck, use a spatula or blender stick to loosen them.",
                "Divide the mango mixture evenly among 4 dessert bowls or glasses.",
                "Dice the remaining mango into 1-cm cubes and set aside.",
                "Divide the coconut sago mixture evenly and layer it over the mango mixture in each bowl.",
                "Top with the diced mango cubes and garnish with a fresh mint leaf. Serve cold and enjoy."
            ],
            notes: """
            This dessert can be served as a layered treat for visual appeal or mixed together in a large bowl for a simpler presentation. 
            Ensure the tapioca pearls are fully cooked to achieve the best texture.
            Condensed coconut milk is a great vegan alternative for this recipe.
            """
        )
        saveRecipe(
            name: "Mantou (Steamed Bun)",
            prepTime: "3 hours",
            cookingTime: "10-12 minutes",
            ingredients: [
                "150 g milk or milk of choice or water",
                "25 g granulated sugar",
                "3/4 tsp active dry yeast",
                "15 g vegetable oil",
                "250 g all-purpose flour",
                "1/2 tsp baking powder"
            ],
            prePrepInstructions: [
                "Heat milk in a microwave for 30 seconds until hot but not unbearable to touch.",
                "Dissolve sugar and oil into the warm milk and sprinkle yeast on top. Let rest for 5 minutes or until foamy."
            ],
            instructions: [
                "Combine flour and baking powder in a mixing bowl.",
                "Mix the flour mixture into the yeast mixture and knead until a smooth and elastic dough forms.",
                "Cover and let the dough rest for 1 hour.",
                "Prepare your steamer with parchment paper, steaming cloth, or liner.",
                "Flatten the dough onto your work surface using your hand. Use a rolling pin to roll the dough into a rectangle.",
                "Tightly roll the rectangle into a log and slice into 8 even pieces.",
                "Place the pieces seam side down into the steamer. Cover and let the dough prove for 30-60 minutes.",
                "Add water to a pot and turn your stove on high. Place the steam basket on top and steam for 10-12 minutes.",
                "Turn off the heat and let the buns sit for about 5 minutes before serving."
            ],
            notes: """
            These steamed buns can be stored by freezing once they have cooled. 
            To reheat, place back in the steam basket and repeat the steaming process.
            Shape options include logs, twists, gua bao buns, and filled baos.
            For filled baos, flatten the dough and add your desired filling before sealing.
            """
        )
        saveRecipe(
            name: "Mapo Tofu, the Authentic Way (麻婆豆腐)",
            prepTime: "8 minutes",
            cookingTime: "12 minutes",
            ingredients: [
                "600 g regular tofu (soft or medium firm)",
                "1 teaspoon salt",
                // For the sauce
                "2 tablespoon neutral cooking oil",
                "100 g minced beef or pork",
                "1 teaspoon minced ginger",
                "2 tablespoon Sichuan chilli bean paste",
                "1 tablespoon fermented black beans (rinsed and chopped)",
                "1 tablespoon ground chilli or chilli flakes",
                "1 tablespoon minced garlic",
                "1 tablespoon Shaoxing rice wine",
                "400 ml water or unsalted stock",
                "2 tablespoon cornstarch (mixed with 3 tablespoons water)",
                // Additional
                "½ teaspoon ground Sichuan pepper",
                "1 stalk scallions (finely chopped)"
            ],
            prePrepInstructions: [
                "Cut the tofu into 2.5cm/1inch cubes.",
                "Dissolve salt into a pot of water, bring it to a boil, then simmer the tofu cubes for 1 minute. Drain and set aside.",
                "Prepare the cornstarch slurry by mixing 2 tablespoons of cornstarch with 3 tablespoons of water."
            ],
            instructions: [
                "Heat a wok until hot, then add cooking oil.",
                "Stir fry minced meat with minced ginger over high heat until the meat turns pale.",
                "Add Sichuan chilli bean paste, fermented black beans, ground chilli, and minced garlic. Fry until fragrant.",
                "Pour in Shaoxing rice wine and water or unsalted stock. Bring to a boil.",
                "Gently slide in the tofu and boil uncovered for 5 minutes.",
                "Turn the heat to medium and add half of the cornstarch slurry. Simmer for 10 seconds, then add the remaining slurry. Stir until the sauce thickens enough to coat the spatula.",
                "Add ground Sichuan pepper and chopped scallions. Gently mix everything together and turn off the heat. Serve hot with steamed rice."
            ],
            notes: """
            Classic Mapo tofu traditionally uses regular tofu. 
            Medium-firm or firm silken tofu is an acceptable substitute, but avoid the soft version.
            Adjust the quantity of Sichuan chilli bean paste based on its saltiness, spiciness, and texture.
            For less heat and numbing sensation, reduce the ground chilli and Sichuan pepper.
            Adding a little sugar can balance the spiciness and saltiness if desired.
            """
        )
        saveRecipe(
            name: "Marinated Tofu (The Best Tofu Ever!)",
            prepTime: "1 hour 20 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "454 g block extra-firm tofu",
                "4 tablespoons low sodium soy sauce",
                "3 tablespoons seasoned rice vinegar",
                "1 tablespoon pure maple syrup",
                "1 teaspoon toasted sesame oil",
                "2 garlic cloves, minced",
                "1 tablespoon fresh grated ginger OR 1/2 teaspoon dried ginger",
                "2-3 tablespoons neutral oil, such as canola or avocado"
            ],
            prePrepInstructions: [
                "Quick press the tofu by cutting it into cubes. Place them evenly on a cutting board lined with paper towels or a clean towel. Cover with more paper towels, set a baking sheet on top, and then something heavy, like a large book or skillet. Press for 15 minutes."
            ],
            instructions: [
                "In a small bowl, combine soy sauce, rice vinegar, maple syrup, sesame oil, garlic, and ginger to make the marinade.",
                "Place the pressed tofu cubes in a shallow dish and pour the marinade over them. Cover and refrigerate for at least 1 hour, or overnight for more flavor.",
                "Heat a skillet over medium-high heat with neutral oil. Remove the tofu from the marinade and add to the pan, reserving the marinade.",
                "Fry the tofu until golden brown on all sides.",
                "Pour the leftover marinade into the pan with the tofu and stir to coat. Let the tofu absorb the sauce before removing from heat.",
                "Serve with rice and stir-fried vegetables like baby bok choy, mushrooms, and carrots."
            ],
            notes: """
            For a gluten-free option, use tamari instead of soy sauce.
            You can bake the tofu by placing the pieces on a silicone mat or parchment-lined baking sheet. Bake at 350°F for 20 minutes, flip, and bake for another 20 minutes. 
            To add more flavor, quickly sauté with the leftover marinade sauce.
            Instead of quick pressing, you can press the whole block of tofu for at least an hour.
            This recipe can be doubled or tripled and stored in the refrigerator for 3-4 days.
            Nutrition information is for 1/4 of the tofu using 2 tablespoons of canola oil for frying.
            """
        )
        saveRecipe(
            name: "Masala Chai (Easy Tea)",
            prepTime: "20 minutes",
            cookingTime: "20 minutes",
            ingredients: [
                "2 1/4 cups (532 ml) filtered water",
                "1 3-inch cinnamon stick, ceylon or cassia are both fine",
                "3 whole cloves",
                "4 green cardamom pods, cracked open and deseeded (seeds & pods included)",
                "3 black peppercorns",
                "1/2 tsp fennel seeds, optional",
                "1/2-inch (~4 g) fresh ginger, peeled and thinly sliced",
                "3 black tea bags or 3 tsp loose leaf black tea (depending on strength)",
                "1 cup (8 oz) whole milk or 2% reduced fat milk",
                "4 tsp (20 g) turbinado cane sugar or raw cane sugar"
            ],
            prePrepInstructions: [
                "Gather and prepare all the whole spices by cracking cardamom pods and peeling and slicing ginger."
            ],
            instructions: [
                "Heat a medium saucepan over high heat and add water, cinnamon stick, cloves, cardamom pods, black peppercorns, fennel seeds (if using), and ginger.",
                "Bring the water to a boil and add the tea bags or tea leaves.",
                "Reduce the heat to medium-low and simmer gently for 7-10 minutes, depending on desired strength. The tea should turn a deep burgundy color and reduce slightly.",
                "Add milk and sugar to the saucepan and stir well. Raise the heat to high or allow the milk to come to a boil naturally.",
                "Reduce the heat to medium and simmer for another 5 minutes.",
                "Raise the heat to high again to bring the tea to a rolling boil for 1-2 minutes, depending on how 'cooked' you prefer the milk.",
                "Optionally, use a ladle to aerate the chai for a deeper flavor and creamier texture.",
                "Pour the chai into cups through a strainer and add more sweetener if desired. Serve hot."
            ],
            notes: """
            Use strong black tea bags such as Assam or Darjeeling for best results.
            If using weaker brands, add extra tea bags.
            Whole spices can be used as-is, but crushing them will increase their intensity slightly.
            Allowing the milk to boil enhances the flavor but overboiling can cause bitterness.
            Find a balance to achieve an evaporated, cooked flavor.
            Store leftover chai in an airtight glass jar in the fridge for up to 3 days.
            """
        )
        saveRecipe(
            name: "Matcha Bars (Danielle's No-Bake)",
            prepTime: "30 minutes",
            cookingTime: "1 hour",
            ingredients: [
                "5 dates, pitted and soaked⁣",
                "1/4 cup Matcha Bucks + more for topping⁣",
                "1/2 cup oats",
                "1/2 cup shredded coconut⁣",
                "2 tablespoons tahini",
                "1 1/2 tablespoons coconut oil⁣",
                "1 tablespoon maple syrup⁣",
                "1 tablespoon matcha"
            ],
            prePrepInstructions: [
                "Pit the dates and soak them in water until softened."
            ],
            instructions: [
                "Blend the soaked dates in a food processor until a paste forms.⁣",
                "Add the oats, shredded coconut, tahini, coconut oil, maple syrup, and matcha to the food processor.",
                "Blend until well combined but still slightly textured.⁣",
                "Press the mixture into a parchment-lined baking dish, ensuring the thickness is even throughout.⁣",
                "Sprinkle more Matcha Bucks on top and gently press them into the bar mix.⁣",
                "Freeze the dish for at least an hour to set the bars.⁣",
                "Once set, use a pizza cutter to slice the bars into portions. Enjoy!"
            ],
            notes: """
            Ensure the dates are well-soaked for easier blending.
            Adjust the thickness of the bars to your preference before freezing.
            Store the bars in the freezer for longer shelf life, and let them thaw slightly before serving.
            """
        )
        saveRecipe(
            name: "Matcha Butter Cookies",
            prepTime: "1 hour 20 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "173 g (1 1/2 Cups) Flour",
                "2.5 Tbsp Matcha Tea",
                "180 g (3/4 Cup) Unsalted Butter",
                "150 g (3/4 Cup) Sugar",
                "0.5 Tsp Salt",
                "1 Egg",
                "Icing Sugar to dust"
            ],
            prePrepInstructions: [
                "Prep all your ingredients so that you have them on hand before you start mixing.",
                "Sift your flour and matcha in a small bowl to remove lumps and set aside."
            ],
            instructions: [
                "In the bowl of your standing mixer, beat the sugar and butter on medium speed until creamy and lighter in color.",
                "Add the egg and mix until fully incorporated.",
                "Lower the speed of the mixer and gradually add the flour and matcha mix until just combined. The dough will be firm and not very smooth.",
                "Move the dough to the fridge and let it rest for 10 minutes.",
                "Preheat the oven to 180°C (350°F) and line two large baking trays with parchment paper.",
                "After resting, roll the dough into a cookie press gun and insert the desired disc. Press cookies onto the parchment paper, leaving 2cm of space between each.",
                "If not using a cookie press gun, pipe cookies with a large pastry bag and open-star tip, or roll them into 1.5cm balls.",
                "Bake for roughly 10 minutes or until the tops of the cookies are firm and not browned.",
                "Transfer cookies to a cooling rack and let cool completely.",
                "Once cooled, dust cookies with icing sugar or a mixture of icing sugar and matcha powder for a stronger matcha flavor."
            ],
            notes: """
            Ensure all ingredients are prepped before starting to mix.
            Use a cookie press gun for uniform shapes or alternatively pipe or roll the dough into balls.
            Dust with matcha powder mixed with icing sugar for an enhanced matcha flavor.
            Bake just until the cookies are firm and not browned to maintain their delicate texture.
            """
        )
        saveRecipe(
            name: "Matcha Cookies",
            prepTime: "10 minutes",
            cookingTime: "13 minutes",
            ingredients: [
                "½ cup brown sugar (50 g / 1.75 oz, not packed down)",
                "¼ cup caster sugar (40 g / 1.4 oz, plus 1 – 2 tsp for sprinkling)",
                "¼ cup salted butter (60 g / 2.1 oz, softened)",
                "1 tsp white miso paste",
                "1 tsp matcha green tea powder (heaped)",
                "2 tbsp hot water (Around 80°C / 175°F)",
                "1 tsp vanilla essence",
                "1 egg",
                "1 ½ cups self raising flour (180 g / 6.35 oz)",
                "½ cup macadamia nuts (60 g / 2.1 oz, roughly chopped, sub hazelnut or white chocolate chips)"
            ],
            prePrepInstructions: [
                "Optional: Dry toast the macadamia nuts in a medium frying pan on medium heat for 2-3 minutes until golden with a slight char around the edges.",
                "Allow toasted macadamia nuts to cool before adding to the cookie dough."
            ],
            instructions: [
                "Place matcha powder into a small dish and pour in hot water. Mix well until fully dissolved and frothy.",
                "Cream the brown sugar, caster sugar, and salted butter using a stand mixer or hand-held beaters until pale and fluffy (around 3-5 minutes).",
                "Add the bloomed matcha tea, miso paste, vanilla essence, and egg, then mix together on low speed.",
                "Stir in the self-raising flour and toasted macadamias using a wooden spoon until well combined.",
                "Cover and refrigerate dough for a minimum of 15 minutes.",
                "Preheat the oven to 180°C / 360°F.",
                "Form cookie dough balls around 3 cm / 1.5 inches in diameter, and place them onto baking trays lined with parchment paper or a silicone mat.",
                "Flatten the tops slightly and sprinkle with extra caster sugar.",
                "Bake for around 10 minutes or until lightly browned around the edges and cracks start to form on top.",
                "Transfer cookies to a cooling rack until fully cooled, then serve or store in an airtight container."
            ],
            notes: """
            Toasting the macadamia nuts enhances their flavor and aroma but can be skipped to save time.
            Use a matcha whisk for best results when mixing the matcha powder and hot water.
            Leave space between cookie dough balls on the baking tray as they will expand during baking.
            Store cookies in an airtight container to keep them fresh.
            """
        )
        saveRecipe(
            name: "Matcha Cupcakes",
            prepTime: "10 minutes",
            cookingTime: "17 minutes",
            ingredients: [
                "1 cup + 2 Tbsp cake flour (135 grams)",
                "3/4 cup granulated sugar (150 grams)",
                "4.06 tsp baking powder (18 grams)",
                "1/2 tsp salt (2 grams)",
                "1/2 cup whole milk, room temp (123 grams)",
                "1/2 cup vegetable oil (112 grams)",
                "1 tsp vanilla extract (4 grams)",
                "2 large eggs, room temp (114 grams)",
                "1 Tbsp sifted matcha (9 grams)",
                "1/2 cup unsalted butter, room temperature (113 grams)",
                "1 3/4 cups powdered sugar (220 grams)",
                "1/4 tsp salt (1 grams)",
                "2 Tbsp heavy cream (or whipping cream) (30 grams)",
                "1 tsp vanilla extract (4 grams)"
            ],
            prePrepInstructions: [
                "Preheat the oven to 350°F (175°C) and place cupcake liners in baking pans."
            ],
            instructions: [
                "Sift the flour, sugar, baking powder, baking soda, salt, and matcha into a large bowl.",
                "Pour in the milk and oil, and gently stir until just combined. The batter will be thick.",
                "Add the vanilla and eggs, and mix until the batter comes together.",
                "Fill the cupcake liners about 2/3 full and bake for 12-14 minutes or until a toothpick comes out clean.",
                "Allow the cupcakes to cool for 5 minutes before transferring them to a cooling rack. Accelerate cooling by placing them in the freezer for 30 minutes if desired.",
                "To make the frosting, beat the butter on medium speed for 30 seconds until smooth.",
                "Slowly add the powdered sugar, 1 cup at a time, alternating with small splashes of cream.",
                "Add the vanilla and salt, and beat on low until fully incorporated. Adjust the consistency with additional cream or powdered sugar as needed.",
                "Place the buttercream in a piping bag with your favorite tip and pipe swirls onto the cooled cupcakes.",
                "Garnish with a dusting of matcha powder."
            ],
            notes: """
            This recipe can also be used to make mini cupcakes. It yields about 40 mini cupcakes that bake for 8-9 minutes.
            To ensure fluffy cupcakes, do not overmix the batter.
            Use room temperature ingredients for best results.
            Store cupcakes in an airtight container at room temperature or refrigerate if frosted with buttercream.
            """
        )
        saveRecipe(
            name: "Matcha Frappe",
            prepTime: "5 minutes",
            cookingTime: "0 minutes",
            ingredients: [
                "30 ml Monin Concentrate",
                "1 scoop vanilla powder base for frappé",
                "150 ml milk",
                "Ice, enough to fill a 16 oz glass",
                "Whipped cream for garnish"
            ],
            prePrepInstructions: [
                "Prepare a blender and gather all ingredients."
            ],
            instructions: [
                "Fill a 16 oz glass with ice.",
                "Place the ingredients (Monin Concentrate, vanilla powder base, milk) into the blender in the order listed.",
                "Add the ice from the glass into the blender.",
                "Blend the mixture until smooth.",
                "Pour the blended frappe into the glass.",
                "Top with whipped cream for garnish.",
                "Serve immediately and enjoy."
            ],
            notes: """
            Use a high-powered blender for the best results.
            For a sweeter frappe, adjust the amount of Monin Concentrate to your liking.
            Experiment with different garnishes, such as matcha powder or chocolate shavings.
            """
        )
        saveRecipe(
            name: "Matcha Mochi Cookies",
            prepTime: "30 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "8 frozen glutinous rice balls (sesame flavor)",
                "125 g low gluten flour",
                "60 g butter",
                "45 g sugar",
                "20 g egg",
                "10 ml milk",
                "20 g matcha powder",
                "1/4 tsp baking powder",
                "Sesame (appropriate amount)"
            ],
            prePrepInstructions: [
                "Cook the frozen glutinous rice balls according to the packaging instructions.",
                "Place the cooked rice balls back into the packaging box and refrigerate for 1 hour."
            ],
            instructions: [
                "Allow the butter to soften at room temperature, then beat it with sugar until light yellow.",
                "Slowly add the egg and milk to the butter mixture.",
                "Sift in the flour, matcha powder, and baking powder. Mix gently to form a cookie dough.",
                "Divide the cookie dough into 8 portions. Wrap each portion around a glutinous rice ball, roll into a ball, and gently flatten.",
                "Place sesame seeds on top of the dough and press lightly to secure them.",
                "Bake in a preheated oven at 180°C for 15 minutes.",
                "Let the cookies cool before serving."
            ],
            notes: """
            The combination of matcha and sesame creates a delightful flavor.
            The cookies are crispy, while the glutinous rice balls add a chewy texture.
            For variation, try other flavor combinations such as chocolate cookies with peanut-flavored rice balls.
            """
        )
        saveRecipe(
            name: "Matcha Pancakes",
            prepTime: "5 minutes",
            cookingTime: "25 minutes",
            ingredients: [
                "2 cups all-purpose flour",
                "2 tbsp matcha powder (green tea powder)",
                "2 tbsp sugar (optional)",
                "4 tsp baking powder",
                "1/2 tsp salt",
                "2 cups milk",
                "4 tbsp melted butter",
                "2 large eggs",
                "2 tsp vanilla extract",
                "Vegetable oil for cooking"
            ],
            prePrepInstructions: [
                "Gather all ingredients.",
                "Prepare a large bowl for the dry ingredients and another for the wet ingredients."
            ],
            instructions: [
                "Combine flour, matcha powder, sugar, baking powder, and salt in a large bowl and mix well.",
                "In a blender, mix milk, melted butter, eggs, and vanilla extract until well combined.",
                "Add the dry ingredients to the blender and mix at low speed until just incorporated to form a runny batter. Transfer to a bowl.",
                "Heat a skillet over medium heat and add oil to cover the bottom.",
                "Turn to low heat. Use a 1/4 cup measuring cup to pour batter into the skillet, forming pancakes with gaps in between.",
                "Cook until bubbles form and pop on the surface, about 1-2 minutes, then flip and cook for another 1 minute.",
                "Repeat with the remaining batter, adding oil as needed.",
                "Serve with whipped cream, mixed berries, and/or maple syrup."
            ],
            notes: """
            Adding sugar enhances the flavor and creates a char on the pancake edges.
            Cook over low heat to prevent browning too quickly.
            For a variation, try different toppings such as fruit or flavored syrups.
            """
        )
        saveRecipe(
            name: "Matcha Pound Cake",
            prepTime: "30 minutes",
            cookingTime: "1 hour",
            ingredients: [
                "3 eggs, room temperature",
                "3 yolks, room temperature",
                "3 tbsp water",
                "200 g cake flour",
                "3 tbsp matcha powder",
                "1/2 tsp salt",
                "225 g butter, room temperature",
                "250 g sugar"
            ],
            prePrepInstructions: [
                "Preheat the oven to 350°F (175°C). Grease a 9\"x5\" loaf pan (bottom 8\"x4\").",
                "In a medium bowl, mix eggs, yolks, and water.",
                "Sift cake flour, matcha powder, and salt together into another bowl. Set aside."
            ],
            instructions: [
                "Put softened butter into a stand mixer and beat with the paddle attachment for 2 minutes.",
                "Slowly add sugar in 4-5 parts, beating for 5 minutes until the color turns very light and it becomes fluffy.",
                "Add the egg mixture in 4-5 parts, pouring each part slowly and mixing for another 5 minutes.",
                "Fold in the flour mixture in 4-5 parts by hand.",
                "Pour the batter into the prepared pan, flatten the surface with a spatula.",
                "Bake in the oven for about 1 hour or until a toothpick comes out clean.",
                "Cool slightly and remove the cake from the pan.",
                "Cool the cake completely on a cooling rack."
            ],
            notes: """
            For best results, ensure all ingredients are at room temperature.
            The cake can be topped with powdered sugar or a matcha glaze for added decoration.
            This cake can be stored in an airtight container for up to 3 days.
            """
        )
        saveRecipe(
            name: "Chewy Matcha Rice Cake",
            prepTime: "1 hour",
            cookingTime: "20 minutes",
            ingredients: [
                "155g water",
                "40g sugar",
                "4g gelatin or agar powder",
                "200g strong flour",
                "40g glutinous rice flour",
                "0.5g baking soda",
                "0.3g salt",
                "1 tbsp matcha powder",
                "10g cooking oil",
                "50g nuts (e.g. walnuts, hazelnuts, almonds)",
                "60g brown sugar",
                "1 tbsp ground cinnamon"
            ],
            prePrepInstructions: [
                "Stir warm water and sugar until dissolved.",
                "Add gelatin or agar powder and stir until dissolved.",
                "Let the mixture rise for 10 to 15 minutes."
            ],
            instructions: [
                "Add all-purpose flour, glutinous rice flour, baking soda, salt, matcha powder, and oil. Mix until a dough forms.",
                "Cover the bowl with plastic wrap and let the dough ferment in a warm place for 50 to 60 minutes.",
                "While the dough is rising, mix the filling by combining walnuts, hazelnuts, almonds, brown sugar, and cinnamon powder.",
                "Sprinkle gluten on a cutting board and transfer the risen dough to it.",
                "Divide the dough into six pieces and flatten each piece.",
                "Place a spoonful of the filling in the center of each flattened dough piece.",
                "Gather the ends of the dough together and twist to seal.",
                "Heat oil in a pan and add the dough pieces. Fry them like deep-frying until both sides turn golden brown, about 1-2 minutes per side."
            ],
            notes: """
            You can use any nuts of your choice for the filling, such as roasted hazelnuts, almonds, and walnuts.
            Ensure the dough is properly fermented before frying to achieve the chewy texture.
            You can watch the process on YouTube at https://youtu.be/L_vhGdfUMS8.
            """
        )
        saveRecipe(
            name: "Matcha Rose Flower Cake",
            prepTime: "Not specified",
            cookingTime: "Not specified",
            ingredients: [
                "Wheat flour",
                "Water",
                "Rose petal",
                "Butter (pasteurized cream, water)",
                "Matcha powder",
                "Sugar",
                "Honey",
                "Less than 2% of: Mono and diglycerides",
                "Ascorbic acid",
                "Citric acid"
            ],
            prePrepInstructions: [
                "Not specified"
            ],
            instructions: [
                "Not specified"
            ],
            notes: """
            Contains wheat and milk.
            """
        )
        saveRecipe(
            name: "Matcha Scones",
            prepTime: "30 minutes",
            cookingTime: "25 minutes",
            ingredients: [
                "200g low gluten flour",
                "10g matcha powder",
                "8g baking powder",
                "2g salt",
                "40g sugar",
                "50g butter",
                "90g milk"
            ],
            prePrepInstructions: [
                "Add 200g low-gluten flour, 10g matcha powder, 8g baking powder, 2g salt, and 40g sugar and sift.",
                "Stir in the flour until smooth.",
                "Add 50g of room temperature butter.",
                "Use a spatula to stir in the butter into small pieces.",
                "After stirring to a certain degree, add 90g of milk and form dough."
            ],
            instructions: [
                "Shape the dough into a rough shape and cover with plastic wrap.",
                "Place the dough covered with plastic wrap in the refrigerator to rest for about 1 hour.",
                "Take out the dough and coat it with another layer of flour, also on the chopping board.",
                "Use a rolling pin to roll it over and over again, repeatedly.",
                "Push to a certain extent, and cut into the desired shape after repeated pressure.",
                "Place parchment paper in the oven and position the scones properly.",
                "Apply milk (egg wash is also okay).",
                "Bake in a preheated oven at 180°C for 25 minutes.",
                "Place on a cooling rack to cool. The scones are best when warm and freshly baked."
            ],
            notes: """
            Serve with jam, butter, cream, etc.
            """
        )
        saveRecipe(
            name: "Matcha Shortbread",
            prepTime: "15 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "50 grams of butter",
                "a little salt",
                "30 grams of powdered sugar",
                "2 teaspoons of whole egg liquid",
                "3g matcha powder",
                "65g low flour",
                "25g almonds"
            ],
            prePrepInstructions: [
                "Soften the butter.",
                "Sift the matcha powder in material B once, then mix with low flour and almond powder and sift."
            ],
            instructions: [
                "Preheat oven to 170°C, set top and bottom heat, and position the rack in the middle.",
                "Mix the softened butter with salt and powdered sugar.",
                "Add the whole egg liquid and blend until smooth.",
                "Gradually add the sifted dry ingredients (matcha powder, low flour, and almond powder).",
                "Knead the dough lightly, then shape it into small rounds or desired shapes.",
                "Place on a baking sheet and bake for 13–15 minutes until golden brown."
            ],
            notes: """
            Ensure the dough is not overworked to maintain a tender texture.
            """
        )
        saveRecipe(
            name: "Matcha Snow Cake",
            prepTime: "45 minutes",
            cookingTime: "25 minutes",
            ingredients: [
                "140 g glutinous rice flour",
                "30 g corn starch",
                "20 g tapioca starch",
                "6 g matcha powder",
                "20 g powdered sugar",
                "230 g milk",
                "25 g butter",
                "5 packs Golden Oatmeal",
                "20 g corn starch",
                "270 g milk",
                "8 g powdered sugar"
            ],
            prePrepInstructions: [
                "In a large bowl, sift together milk, glutinous rice flour, corn starch, tapioca starch, powdered sugar, and matcha powder.",
                "Steam the mixture for 25 minutes."
            ],
            instructions: [
                "In a separate bowl, mix corn starch, powdered sugar, and milk. Pour this mixture into a non-stick pan and cook over low heat until it begins to thicken.",
                "Turn off the heat, add the oatmeal, and stir.",
                "Once combined, pour the mixture into a bowl and stir evenly.",
                "Add the butter and stir well. Let the mixture cool.",
                "Prepare disposable gloves and a non-stick cloth for handling the dough. If you don't have a non-stick cloth, use plastic wrap or plastic bags to prevent sticking.",
                "Divide the dough into about 16 small balls, each weighing around 22 grams.",
                "Using a rolling pin covered in plastic wrap, roll the dough into thin discs.",
                "Place the stuffing in the middle of each dough disc, wrap it tightly, and pinch the edges closed."
            ],
            notes: """
            Using gloves makes handling the dough much easier as it helps prevent sticking.
            You can substitute the oatmeal with other fillings if desired.
            """
        )
        saveRecipe(
            name: "Matcha Flavored Steamed Cake (抹茶味蒸蛋糕)",
            prepTime: "10 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "1 tsp matcha powder (3-5g)",
                "4 eggs",
                "60 g sugar",
                "80 g cake flour",
                "1 tbsp sunflower oil (or corn oil)"
            ],
            prePrepInstructions: [
                "Break 4 eggs into a large bowl.",
                "Beat the eggs using an electric blender on high speed for 5 minutes."
            ],
            instructions: [
                "During the beating process, gradually add 60g sugar into the eggs in two stages.",
                "Continue beating until the egg mixture becomes foamy and light.",
                "Sift 80g flour and 1 tsp matcha powder into the beaten egg in two parts, mixing well after each sifting.",
                "Add 1 tbsp of oil and mix everything well.",
                "Pour the cake batter into a 20-24 cm diameter steamer lined with parchment paper at the bottom.",
                "Bring a pot of water to a boil and place the steamer on top.",
                "Steam for 15 minutes.",
                "Turn off the heat and let the cake rest for 3 minutes before removing it from the steamer."
            ],
            notes: """
            Ensure to mix the ingredients well after each sifting to avoid lumps.
            You can use either sunflower oil or corn oil for this recipe.
            The cake should be light and fluffy with a delicate matcha flavor.
            """
        )
        saveRecipe(
            name: "Margarine Cookies",
            prepTime: "10 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "400g margarine",
                "100g caster sugar",
                "400g plain flour",
                "1 tsp almond extract",
                "1 tsp vanilla extract"
            ],
            prePrepInstructions: [
                "Preheat the oven to 180° Celsius or gas mark 4."
            ],
            instructions: [
                "Whisk the margarine first until it rises.",
                "Add in caster sugar and mix until combined.",
                "Sift in the plain flour and mix.",
                "Add in almond and vanilla extracts, and mix well.",
                "Shape the dough into £2 coin-sized discs, avoiding spheres as this can elongate the baking time.",
                "Lay the discs spaced out onto an oven tray lined with greaseproof paper.",
                "Bake for 10 minutes.",
                "Check if baked by breaking one in half to see if any dough remains translucent. Once opaque, remove from the oven and leave to cool."
            ],
            notes: """
            Be careful not to make the dough into spheres, as this will affect the baking time.
            The cookies should be opaque once baked, indicating they are done.
            Enjoy your cookies once they have cooled completely!
            """
        )
        saveRecipe(
            name: "Masoor Dal (Instant Pot Red Lentil)",
            prepTime: "10 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "2 cups masoor dal, red lentils",
                "8 tbsp neutral oil (such as grapeseed or avocado)",
                "2 tsp cumin seeds",
                "2 large yellow onions, thinly sliced",
                "8-12 garlic cloves, crushed",
                "4 tsp crushed ginger",
                "2 small Serrano peppers or Thai chili peppers, sliced (or whole if you prefer less heat)",
                "1 cup chopped tomato, very finely chopped or pureed (200g canned chopped tomatoes)",
                "2 tsp cumin powder",
                "2 tsp coriander powder",
                "1 tsp turmeric powder",
                "0.5 tsp red chili powder or cayenne, or to taste",
                "5 cups filtered water"
            ],
            prePrepInstructions: [
                "Place lentils in a small bowl and fill with water. Use your hand to swirl the dal around until the water becomes murky. Tip the bowl to take out the excess water and repeat until the water runs clear. Remove any debris, strain the dal, and set aside."
            ],
            instructions: [
                "Select the high Sauté setting on the Instant Pot. Once hot, add the oil, cumin seeds, and onions. Sauté until the onions turn lightly golden, about 6-7 minutes.",
                "Add the garlic, ginger, and green chili pepper and continue to sauté for another minute until the raw smell disappears and the color of the onion deepens. Add the tomato and sauté for another 2-3 minutes.",
                "Press the Cancel button to turn off the Instant Pot. Add the spice powders (red chili, turmeric, cumin, coriander) and stir. Add in the rinsed dal and water.",
                "Secure the lid and set the Pressure Release to Sealing. Select the Pressure Cook or Manual setting and set the cooking time for 6 minutes at high pressure.",
                "Let the venting naturally release for 5 minutes, then move the Pressure Release to Venting to release any remaining steam.",
                "Open the pot and turn to Sauté mode again. Add the salt and ghee and sauté for 2-3 minutes, stirring often to smooth out and thicken the dal. Press Cancel to turn off the Instant Pot.",
                "Add chopped cilantro, lemon juice, and garam masala (if using). Give it a stir.",
                "Serve dal hot with rice, roti, naan, or other bread. You can also serve it with some chopped onions, carrots, or cucumber on the side."
            ],
            notes: """
            For a richer flavor, you can use ghee in place of butter.
            This dal pairs well with a side of rice, roti, or naan.
            You can also adjust the spice level by using more or fewer chili peppers.
            """
        )
        saveRecipe(
            name: "Chinese Meat Pies (Xian Bing/馅饼)",
            prepTime: "25 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "// For the dough",
                "300 g all-purpose flour",
                "120 g hot water",
                "45 g room-temperature water",
                "2 tablespoons neutral cooking oil (plus extra for coating)",
                "// For the filling",
                "300 g ground pork (or beef/lamb)",
                "6 stalks scallions, finely chopped",
                "1 tablespoon minced ginger",
                "1 tablespoon light soy sauce",
                "1 tablespoon dark soy sauce",
                "1 teaspoon sesame oil",
                "¼ teaspoon ground Sichuan pepper (or five-spice powder)",
                "¼ teaspoon ground white pepper",
                "4 tablespoons water (or unsalted stock)",
                "// For pan-frying",
                "Neutral cooking oil"
            ],
            prePrepInstructions: [
                "Put flour into a mixing bowl. Pour hot water over then mix with chopsticks. Add room temperature water and cooking oil. Stir well then combine and knead with hands. As soon as a cohesive dough forms (it doesn’t need to look smooth), cover it and let it rest for 20 minutes. Knead the dough again until it becomes smooth. Coat the work surface and your hands with a little oil to prevent sticking. Roll the dough into a log then cut it into 8 equal portions. Shape each piece into a ball, making sure it’s lightly coated with oil from your hands. Cover them with plastic wrap, then leave to rest for a further 10 minutes."
            ],
            instructions: [
                "While waiting for the dough to rest, prepare the filling by adding all the ingredients (meat, scallions, ginger, soy sauce, sesame oil, five-spice, white pepper, and water) into a mixing bowl. Stir with chopsticks in one direction until the mixture becomes sticky.",
                "Put a piece of dough on the work surface. Flatten it into a disc with your fingers, about ⅕ inch (½ cm) thick. Hold the wrapper with your non-dominant hand. Place ⅛ of the filling over the wrapper. Use the thumb and index finger of your dominant hand to pleat the dough to wrap the filling tightly, while using the thumb of your non-dominant hand to push the filling inwards. Seal the dough securely in the middle. Place the assembled pie on an oiled tray. Repeat the procedure to shape other pies.",
                "In a heavy-bottomed skillet/frying pan, heat oil enough to cover the surface. Gently put in the stuffed dough balls and flatten them into discs with your fingers or a spatula, about 1 inch (2½ cm) thick. Leave to fry over low heat until the first side becomes golden. Flip over the pies and cover the skillet with a lid. Fry until the other side browns. Flip again to further crisp the first side for 20 seconds or so."
            ],
            notes: """
            The flour-to-water ratio may vary slightly depending on the brand of your flour and the humidity of your kitchen. Adjust if necessary. Bear in mind that this dough is supposed to be quite soft, but isn’t overly sticky.
            Depending on the size of your cookware, you’ll need to cook all the pies in 2-3 batches.
            """
        )
        saveRecipe(
            name: "Malaysian Char Kway Teow (Quick & Easy)",
            prepTime: "15 mins",
            cookingTime: "15 mins",
            ingredients: [
                "400 g egg noodles (thick kind)",
                "180 g pork belly, sliced into 1-cm wide pieces (or substitute with chicken, beef, pork, shrimp, or tofu)",
                "145 g fish cakes, sliced into ¼-inch thick pieces",
                "145 g jumbo shrimp, peeled and deveined",
                "3 cloves garlic, minced",
                "2 large eggs, beaten",
                "95 g Chinese chives, chopped into 1-inch segments",
                "200 g bean sprouts, washed and strained",
                "// Noodle Sauce",
                "45 ml kecap manis or sweet soy sauce (or substitute with dark soy sauce and add 2 teaspoons of sugar)",
                "10 ml sesame oil",
                "75 ml ketchup",
                "30 ml oyster sauce or vegetarian stir fry sauce"
            ],
            prePrepInstructions: [
                "In a large pot or deep pan filled with boiling hot water, bring to boil and blanch your noodles just until loosened, about 20-30 seconds. Strain immediately."
            ],
            instructions: [
                "In a small bowl, combine noodle sauce ingredients and set aside.",
                "In a large pan on medium heat, fry pork belly until golden crispy brown, about 5 minutes.",
                "Next, add garlic and sauté for 10 seconds or until fragrant.",
                "Toss in shrimp, fish cakes, and cook until the shrimps become mostly pink.",
                "Sweep your ingredients to the side of the pan. Pour in beaten eggs to scramble them and toss with the other ingredients.",
                "Throw in garlic chives and bean sprouts and cook until the veggies have wilted a bit.",
                "Toss in noodles with noodle sauce until it's incorporated with the other ingredients. Remove pan off heat and transfer noodles to a large serving plate and enjoy!"
            ],
            notes: """
            You can substitute the protein with tofu or your preferred meat.
            For a sweeter flavor, adjust the amount of kecap manis.
            This dish can be made ahead and reheated with a splash of water or soy sauce for extra moisture.
            """
        )
        saveRecipe(
            name: "Milk Buns",
            prepTime: "30 mins",
            cookingTime: "30 mins",
            ingredients: [
                "125ml milk, preferably whole milk, plus extra for glazing",
                "7g fast-action dried yeast",
                "350g strong white bread flour, plus extra for dusting",
                "50g caster sugar",
                "1 egg",
                "50g unsalted butter, softened and cut into cubes",
                "Neutral-tasting oil, such as sunflower, for proving",
                "For the tangzhong:",
                "20g strong white bread flour",
                "60ml milk, preferably whole"
            ],
            prePrepInstructions: [
                "Line a high-sided 20 x 30cm baking tin with baking parchment.",
                "To make the tangzhong, put the flour, milk, and 30ml water in a small saucepan. Whisk over a medium heat until it becomes a thick paste, then set aside until it is at room temperature.",
                "Pour the milk into a saucepan and set over low heat until just warm. Alternatively, warm in the microwave in 10-second blasts, but be careful not to boil it. Stir in the yeast to fully combine."
            ],
            instructions: [
                "Mix the flour, sugar, and 1 tsp fine sea salt in the bowl of a stand mixer with a dough hook attachment. With the mixer running, add the egg, tangzhong, and milk mixture.",
                "Knead for 2 minutes, then add the butter, bit by bit. Continue to knead for a further 7-8 minutes until soft, elastic, and slightly sticky.",
                "Form the dough into a ball and put it into a lightly oiled clean bowl. Cover and set aside to rise for around 2 hours until doubled in size.",
                "Lightly dust a clean work surface with flour and knock back the dough for 10 seconds. Divide into eight pieces (around 85g each), and form them into small balls.",
                "Put the balls in the prepared tin and cover. Set aside to rise for 1 hour or until doubled in size.",
                "Heat the oven to 200C/180C fan/gas 6. Generously brush some milk over the buns to glaze and bake for 20-25 minutes until golden and risen.",
                "Leave to cool in the tin for 15-20 minutes before transferring to a wire rack to cool completely."
            ],
            notes: """
            These buns will keep in an airtight container for three days or frozen for two months.
            If making the dough in advance, chill it overnight. Bring it to room temperature, then leave it to rise until doubled in size before continuing.
            """
        )
        saveRecipe(
            name: "Miso Soup",
            prepTime: "5 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "2 cups of water",
                "1 tbsp of dashi powder",
                "1 tbsp of miso paste (adjust to taste)",
                "1 tsp of wakame",
                "1 tbsp of diced tofu (adjust to your liking)",
                "Few slices of mushrooms (adjust to your liking)",
                "Spring onions for garnishing"
            ],
            prePrepInstructions: [
                "Boil water in a medium-sized pot."
            ],
            instructions: [
                "Add 1 tablespoon of dashi powder and cook for a few minutes.",
                "Add wakame, mushrooms, and diced tofu, and continue to cook for a few minutes.",
                "Switch off the stove, and let the mixture sit for 10 minutes.",
                "Add 2 to 3 tablespoons of Halal miso paste – use a strainer to mix to prevent lumps. Mix the miso paste well into the soup.",
                "Garnish with spring onions to your liking."
            ],
            notes: """
            Adjust the amount of miso paste, tofu, mushrooms, and wakame based on personal preference.
            Garnish with spring onions for extra flavor.
            """
        )
        saveRecipe(
            name: "Mocha Ice Cream Cake (No Machine)",
            prepTime: "1 hour",
            cookingTime: "15 minutes",
            ingredients: [
                "// Dark Chocolate Cake",
                "240g all-purpose flour",
                "240g granulated sugar",
                "120ml oil",
                "120ml unsalted butter",
                "240ml water",
                "4 tablespoons cocoa powder (like Hersheys Special Dark)",
                "120ml buttermilk",
                "1 teaspoon baking soda",
                "1 teaspoon vanilla extract",
                "1 teaspoon salt",
                "2 large eggs",
                
                "// Mocha Ice Cream",
                "480ml heavy cream, chilled",
                "1 (14 ounce) can sweetened condensed milk, chilled",
                "1/2 teaspoon vanilla extract",
                "120g cocoa powder (sifted)",
                "2 tablespoons instant espresso powder",
                
                "// Coffee Ice Cream",
                "240ml half and half",
                "240ml heavy cream (divided)",
                "180g granulated sugar",
                "3 tablespoons espresso powder",
                "1/4 teaspoon salt",
                "2 large egg yolks",
                "1 teaspoon vanilla extract",
                
                "// Alternative Coffee Ice Cream",
                "2l vanilla ice cream",
                "2 tablespoons instant coffee granules (grounded)",
                "100ml Double cream",
                
                "// Chocolate Ganache",
                "10 ounces 60% bittersweet chocolate morsels",
                "120ml heavy cream (or half-and-half)",
                
                "// Optional Garnishes",
                "Chocolate sprinkles",
                "Chocolate chips",
                "Whipped cream (optional, ombre colored blue)",
                
                "// Mocha Whipped Cream",
                "2 tablespoons bittersweet chocolate",
                "1 tablespoon water",
                "1 tablespoon instant coffee",
                "240ml cream (super cold)",
                "1/2 teaspoon Vanilla",
                "1 tablespoon sugar"
            ],
            prePrepInstructions: [
                "Preheat the oven to 205°C (400°F). Coat 2x 8\" round tins and 4x 6\" round tins with cooking spray and line with parchment. Set aside."
            ],
            instructions: [
                "In a mixing bowl, sift together flour and sugar. Set aside.",
                "In a small saucepan, combine oil, butter, water, and cocoa powder, stirring until incorporated. Bring to a gentle boil. Pour the chocolate mixture over the flour and sugar mixture and stir to combine. Add buttermilk, baking soda, salt, and vanilla. Stir, then add eggs and mix well.",
                "Pour the batter into the prepared pan and bake for 15-18 minutes until a cake tester or toothpick inserted comes out clean. Let cool.",
                "For the Mocha Ice Cream: Whip the cream until stiff peaks form. Mix in the condensed milk, vanilla, cocoa powder, and espresso powder. Freeze for at least 6 hours.",
                "For the Coffee Ice Cream: Combine half-and-half and 1 ½ cups heavy cream in a saucepan, add sugar, espresso powder, and salt, whisking until sugar dissolves. Whisk egg yolks with the remaining ½ cup cream. Gradually add hot cream mixture to egg yolks to temper, then combine and cook until thickened. Chill, then churn in an ice cream machine for 45 minutes. Freeze until firm.",
                "For the alternative Coffee Ice Cream: Mix instant coffee granules with vanilla ice cream, then whisk in double cream and freeze.",
                "For the Mocha Whipped Cream: Melt chocolate in a microwave-safe bowl. Stir in hot water and coffee until smooth. Cool to room temperature. Whip the cream with vanilla and sugar until soft peaks form, then add chocolate mixture and whip until desired consistency.",
                "Assemble the Ice Cream Cake: Once the cake has cooled, slice into pieces to fit a loaf pan. Freeze for firm layers. Layer cake with ice cream in a 4x8 loaf pan, freeze until firm, and repeat the process. For the ganache, heat cream and pour over chocolate morsels. Stir until smooth and let cool. Pour ganache over the cake and freeze. Garnish with whipped cream, chocolate sprinkles, and chips. Allow ganache to firm up before slicing."
            ],
            notes: """
            Ensure each layer of ice cream is fully frozen before adding another layer of cake.
            The ganache thickens quickly, so be sure to pour it over the cake immediately after removing from the freezer.
            Optional: Garnish with ombre-colored whipped cream and chocolate sprinkles.
            """
        )
        saveRecipe(
            name: "Mooncakes, a Classic Recipe (广式月饼)",
            prepTime: "1 hour",
            cookingTime: "1 hour 30 minutes",
            ingredients: [
                "// For the Paste",
                "75g dried lotus seeds",
                "56.25g sugar, or to taste",
                "37.5g neutral cooking oil (e.g., sunflower, canola, vegetable, peanut, rapeseed oil)",
                
                "// For the Dough",
                "112.5g golden syrup",
                "0.38 tsp lye water (Kansui)",
                "37.5g neutral cooking oil (e.g., sunflower, canola, vegetable, peanut, rapeseed oil)",
                "165g all-purpose flour (plain flour)",
                
                "// Other Ingredients",
                "15 salted egg yolks, ready-to-use",
                "Cornstarch, for dusting",
                "0.75 egg yolk, for brushing"
            ],
            prePrepInstructions: [
                "Soak dried lotus seeds in water overnight. Drain well and remove the green bit in the center if any.",
                "Cook the seeds in simmering water (enough to cover) for about 30-40 minutes until soft. Drain and puree the seeds in a food processor, adding a little water if needed. Transfer to a non-stick pan and cook over medium heat, adding sugar and oil in batches. Stir constantly until the paste becomes dry and holds its shape. Remove from heat and cool."
            ],
            instructions: [
                "For the dough: Mix golden syrup, oil, and lye water until well incorporated. Add flour, combine, and knead briefly to form a soft dough. Cover and rest for 30 minutes.",
                "After resting, knead the dough again until smooth. Divide into 15 equal portions (about 20g each) and shape into balls. Rest again for 10 minutes.",
                "To assemble: Place one salted egg yolk and some lotus seed paste (about 30g) on the scale. Flatten the paste into a round wrapper, place the egg yolk in the center, and seal the paste around it.",
                "Flatten 20g of dough into a wrapper and wrap it around the paste. Shape it into a ball.",
                "Coat the ball with cornstarch, place it in the mooncake mold, and gently press to shape. Release the mooncake by lifting the mold.",
                "Preheat the oven to 375°F (190°C). Bake the mooncakes for 5 minutes. While waiting, mix the egg yolk with 1 tsp of water for brushing.",
                "After 5 minutes, reduce the oven temperature to 320°F (160°C). Brush the mooncakes with a thin layer of egg wash and bake for an additional 5 minutes. Coat with another layer of egg wash and bake for 10-15 minutes until golden brown.",
                "Cool the mooncakes on a wire rack. After they are completely cooled, store them in an airtight container for 1-2 days before serving. The mooncakes are ready when soft to the touch and shiny."
            ],
            notes: """
            You can substitute the lotus seed paste with red bean paste or black sesame paste if preferred.
            Lye water (Kansui) helps to give the dough a slightly crispy texture, but can be omitted if not available.
            To prepare salted duck eggs, follow the instructions in the original post linked above.
            Don't coat the patterned surface of the mooncake with too much egg wash.
            """
        )
        saveRecipe(
            name: "Moroccan Jackfruit 'Lamb' with Lemon Couscous",
            prepTime: "45 minutes",
            cookingTime: "1 hour 30 minutes",
            ingredients: [
                "// For the Jackfruit “Lamb",
                "2 tbsp olive oil",
                "2 tbsp Ras El Hanout - Moroccan spice blend",
                "1 ½ tbsp tomato purée",
                "2 tsp mint sauce",
                "3 x 400g cans of young green jackfruit - in water or brine",
                "2 red onions, peeled and diced",
                "4 garlic cloves, peeled and grated",
                "5cm piece of fresh ginger, peeled and grated",
                "10g fresh coriander, finely chopped",
                "2 cans (400g each) chopped tomatoes",
                "1 can chickpeas, drained and rinsed",
                "½ tsp maple syrup",
                "Juice of 1 lemon",
                "Salt & pepper to taste",
                
                "// For the Lemon Couscous",
                "1 tbsp extra virgin olive oil",
                "1 tsp ground cumin",
                "1 preserved lemon, halved",
                "½ tsp chilli powder",
                "300g couscous",
                "400ml boiling water",
                "Salt & pepper to taste",

                "// To serve",
                "10g parsley leaves",
                "80g pistachios, toasted",
                "50g pomegranate seeds",
                "Hummus (optional)"
            ],
            prePrepInstructions: [
                "Drain, rinse, and pat dry the jackfruit. Cut the jackfruit into 1-inch chunks.",
                "Peel and dice the red onions. Peel and grate the garlic and ginger.",
                "Pick the coriander leaves and finely chop the stalks.",
                "Cut the lemon in half.",
                "Drain, rinse, and pat dry the chickpeas."
            ],
            instructions: [
                "Heat the olive oil in a pan over medium heat, add the onions and a pinch of salt. Stir for 3-4 minutes.",
                "Add the garlic, ginger, and coriander stalks to the pan and stir for 1 minute.",
                "Add the jackfruit to the pan and stir for 3-4 minutes.",
                "Add the Ras El Hanout spice blend to the pan and stir for 2 minutes until the jackfruit is well covered and taking on the colour of the spices.",
                "Add the tomato purée and stir for 30 seconds.",
                "Add the mint sauce and stir for 30 seconds.",
                "Add the chopped tomatoes and stir to combine. Increase the heat and leave to simmer and thicken for 10 minutes.",
                "Add the chickpeas, maple syrup, and lemon juice. Stir and simmer for 15-20 minutes, stirring occasionally to ensure it doesn't catch on the bottom of the pan.",
                
                "While the Moroccan Jackfruit Lamb is simmering, prepare the Lemon Couscous.",
                "Halve the preserved lemon and place it in a mixing bowl.",
                "Add the olive oil, cumin, couscous, and boiling water. Cover with a dinner plate and set aside for 8-10 minutes.",
                "Once the couscous has absorbed the water, fluff it with a fork.",
                
                "Toast the pistachios in a dry pan over high heat for 2 minutes.",
                "Spoon the couscous and Moroccan Jackfruit Lamb into serving bowls.",
                "Garnish with coriander leaves, parsley leaves, toasted pistachios, and pomegranate seeds. Serve immediately."
            ],
            notes: """
            You can substitute the jackfruit with chicken, beef, pork, shrimp, or tofu for variation.
            Adjust the maple syrup and lemon juice to taste for sweetness and acidity balance.
            Hummus is optional but makes a great addition as a side dish.
            """
        )
        saveRecipe(
            name: "Mushroom and Tofu Clay Pot (冬菇豆腐煲)",
            prepTime: "20 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "// Main ingredients",
                "28.3 g dried shiitake mushrooms",
                "85.0 g seafood mushrooms",
                "85.0 g beech mushrooms",
                "56.7 g king oyster mushrooms",
                "56.7 g carrot",
                "28.3 g ginger",
                "3 cloves garlic",
                "14.2 g green onion",
                "454 g tofu (medium firm)",
                "2 tablespoons corn oil",
                "1 tablespoon cooking wine",
                "0.30 cup water",
                
                "// Seasoning ingredients",
                "1 teaspoon salt",
                "1 teaspoon sugar",
                "1 tablespoon oyster sauce (use vegetarian oyster sauce to make this fully vegetarian)",
                "0.50 teaspoon dark soy sauce",
                "1 tablespoon light soy sauce",
                
                "// Slurry ingredients",
                "2 teaspoons cornstarch",
                "1 tablespoon water",
                "1 teaspoon sesame oil"
            ],
            prePrepInstructions: [
                "Clean and rehydrate the dried shiitake mushrooms. Soak them in warm water for 15 minutes and slice them diagonally.",
                "Prepare the seafood mushrooms, beech mushrooms, and king oyster mushrooms by trimming and slicing them.",
                "Peel and slice the carrot, ginger, and garlic.",
                "Cut the green onions in half and dice them.",
                "Cut the tofu into thin slices and pat them dry with a paper towel."
            ],
            instructions: [
                "Heat a wok on high and add 2 tablespoons of oil. Pan-fry the tofu slices for 2-3 minutes on each side until golden brown. Remove from the pan and set aside.",
                "In the same wok, stir fry the ginger and garlic for 40-50 seconds. Add the shiitake mushrooms and cook for 20-30 seconds. Add the carrots and stir-fry for another 20-30 seconds.",
                "Add the other mushrooms and stir-fry for another 30-40 seconds on high heat. Add the cooking wine and cook for 30-40 seconds before turning off the heat.",
                "Transfer the stir-fry ingredients to a clay pot. Add the mushroom soaking liquid and water, cover, and bring to a boil.",
                "Add salt, sugar, oyster sauce, light soy sauce, and dark soy sauce to the pot and stir well. Place the tofu slices on top and gently press them into the sauce.",
                "Cover the pot and simmer for 2-3 minutes. In a small bowl, mix cornstarch and water to make a slurry. Pour the slurry into the pot, stir, and cook for another 3 minutes.",
                "Turn off the heat and mix in the sesame oil. Garnish with green onions and serve immediately."
            ],
            notes: """
            If you don't have a clay pot, use any large pot with a lid.
            For additional vegetables, cabbage and snow peas work well for braising.
            If you'd like a vegetarian version, use vegetarian oyster sauce.
            """
        )
        saveRecipe(
            name: "Mushroom Risotto",
            prepTime: "5 mins",
            cookingTime: "16 mins",
            ingredients: [
                "1 tbsp Olive Oil",
                "1 Onion (peeled and diced)",
                "1 Garlic clove (peeled and chopped)",
                "400g Mixed mushrooms",
                "300g Risotto rice",
                "1L Hot vegetable stock",
                "75g Grated parmesan (optional)"
            ],
            prePrepInstructions: [
                "Peel and dice the onion, chop the garlic, and slice the mushrooms."
            ],
            instructions: [
                "Select SEAR/SAUTÉ on HIGH. Press START/STOP and allow the pot to heat up for 3 minutes.",
                "Add the oil and onions, mix with a wooden spoon, and cook for 2-3 minutes.",
                "Add the garlic and mushrooms, and cook for another 3-4 minutes until the mushrooms have softened.",
                "Add the rice and cook for 1 minute, then add the stock and wine. Bring to a boil. Press START/STOP.",
                "Assemble the pressure lid, making sure the pressure release valve is set to the SEAL position.",
                "Select PRESSURE on HIGH and set the time to 8 minutes. Press START/STOP to begin.",
                "When pressure cooking is complete, allow for a natural release for 2 minutes. After 2 minutes, quick release the pressure by turning the valve to VENT.",
                "Carefully remove the lid once pressure is fully released.",
                "Stir in the parmesan (if using) and serve immediately."
            ],
            notes: """
            You can omit the parmesan for a dairy-free version.
            Stir the risotto to your desired consistency once cooked.
            """
        )
        saveRecipe(
            name: "Naan (Flatbreads or Pizza Base)",
            prepTime: "10 mins",
            cookingTime: "10 mins",
            ingredients: [
                "Yoghurt",
                "Self-raising flour",
                "Pinch of Salt",
                "Garlic butter",
                "100g softened Salted Butter",
                "¼ TSP Garlic granules",
                "2 TSP Parsley",
                "Pinch of Salt (if unsalted butter is used)",
                "Nigella seeds"
            ],
            prePrepInstructions: [
                "Mix equal quantities of natural yogurt and self-raising flour with a pinch of salt and nigella seeds to make a dough."
            ],
            instructions: [
                "Let the dough prove under a tea towel for at least 30 minutes.",
                "Separate the dough into individual dough balls.",
                "Press or roll each dough ball into a flat disc.",
                "Use as a pizza base, or cook for a few minutes on each side in a dry frying pan until puffed and browned.",
                "Brush with garlic butter and serve with curry."
            ],
            notes: """
            If using unsalted butter, add a pinch of salt.
            You can also serve the flatbreads as a side with curries.
            """
        )
        saveRecipe(
            name: "Nian Gao (Chinese New Year Rice Cake)",
            prepTime: "15 minutes",
            cookingTime: "1 hour",
            ingredients: [
                "120 g water (hot)",
                "30 g granulated sugar",
                "30 g brown sugar (or 25g granulated sugar)",
                "90 g glutinous rice flour",
                "30 g rice flour",
                "Red dates to decorate",
                "Blanched peanuts"
            ],
            prePrepInstructions: [
                "This recipe fits in a small bowl about 2 cups in volume. Make sure the bowl you are using can be steamed in– metal, ceramic or glass works well.",
                "Fill a pot with water to steam and place a steam basket on top. Oil the bowl well."
            ],
            instructions: [
                "Dissolve granulated and brown sugar in hot water.",
                "Mix together glutinous rice flour and rice flour, and add it to the sugar mixture until evenly combined.",
                "Pour the mixture into your prepared bowl.",
                "Optionally, cut up a red date and place it cut side down on top of the mixture for decoration.",
                "Transfer the bowl to a steam basket, cover, and turn your stove on high heat until the water is boiling. Then lower to medium heat and steam for 45 minutes to 1 hour.",
                "Serve warm. For pan frying, let the nian gao cool completely and cut it into strips. Grease a frying pan over medium-high heat and cook both sides until browned."
            ],
            notes: """
            This recipe is traditionally served during Chinese New Year.
            If you'd like, you can also decorate the top with red dates.
            """
        )
        saveRecipe(
            name: "Nihari (Easy Instant Pot Pakistani Beef Stew)",
            prepTime: "30 mins",
            cookingTime: "1 hour",
            ingredients: [
                // Whole Spices
                "2.25 star anise (badiyan)",
                "4.5 small bay leaves (tez patta)",
                "2.25 3-4\" cinnamon stick (daarchini)",

                // Ground Spices
                "6.75-9 whole cloves, ground into a powder using a mortar & pestle",
                "6.75 green cardamom pods, seeds removed and ground into a powder",
                "1.13 tsp fennel seeds, ground into a powder",
                "1.13-2.25 tsp paprika powder",
                "1.13 tsp coriander powder",
                "1.13 tsp cumin powder",
                "0.56 tsp turmeric",
                "0.56-1.13 tsp red chili powder or cayenne",
                "0.56 tsp crushed red chili pepper",
                "0.56 tsp ground black pepper",
                "0.28 tsp garlic powder (optional)",
                "Pinch nutmeg",
                "1.13 tbsp store-bought Nihari masala powder or 1 tbsp homemade nihari masala",

                // Nihari
                "2.25 tbsp ghee or butter",
                "2.25 large onion, thinly sliced",
                "2.25 tbsp garlic cloves, crushed",
                "~2.25 tbsp piece ginger, crushed",
                "2.25 lb beef stew or shank pieces, about 1 1⁄2-2 inch cubed",
                "2.81 tsp kosher salt, or to taste",
                "6.75-7.88 cups water",
                "0.56 cup Duram Atta Flour (sub roasted brown rice flour for gluten-free)",
                "0.75-1.13 lb beef bones",

                // Garnishings
                "2.25 inch piece ginger, julienned",
                "2.25 lemon, cut into wedges",
                "0.56 cup fresh cilantro, chopped",
                "2.25-4.5 mild green chillies, finely chopped",
                "Crispy fried onions (optional)"
            ],
            prePrepInstructions: [
                "Soak the whole spices in water for about 15 minutes before use.",
                "Crush garlic, ginger, and fennel seeds using a mortar and pestle.",
                "Cut the beef into 1 1⁄2-2 inch cubes.",
                "Slice the onions, ginger, and garlic for cooking."
            ],
            instructions: [
                "Select the Sauté - More/High setting on the Instant Pot. Once hot, add the oil, ghee, and onion, and sauté until the onion turns golden, about 10-12 minutes.",
                "Add the garlic and ginger and continue to sauté until the raw smell disappears, about 15-20 seconds.",
                "Add beef (along with bones) and sauté for about 4-5 minutes or until it begins to brown.",
                "Press the Cancel button to turn off the Instant Pot. Add the whole spices, powdered spices, and salt and sauté for about 20 seconds.",
                "Pour in the water and stir to deglaze any browned bits from the bottom.",
                "Secure the lid and set the Pressure Release to Sealing. Select the Meat/Stew setting and set the Pressure Level to High. If using Beef Stew meat, pressure cook for 45 minutes. If using Beef Shank meat, increase time to 50 minutes.",
                "Let naturally release for 5 minutes, then move the Pressure Release to Venting to release the remaining pressure. Remove the whole spices, if desired.",
                "Take out a cup of the liquid of the Nihari into a bowl. Let it cool a little by adding an ice cube to it. Place the atta or roasted brown rice flour in another bowl. Bit by bit, whisk in the Nihari liquid to the atta to form a smooth slurry.",
                "Slowly stir this slurry back into the Instant Pot to prevent clumps. Taste and adjust salt & seasoning as desired.",
                "Secure the lid again and set the Pressure Release to Sealing. Select the Pressure Cook setting and set the cooking time for 10 minutes at low pressure. Let naturally release for 5 min. If needed, select Saute - High to reduce down and thicken the nihari to desired consistency.",
                "Sprinkle with cilantro and serve alongside the garnishing with naan."
            ],
            notes: """
            Servings: 9.
            Total Cooking time: 1 hour 30 minutes.
            Traditionally, atta flour is used to thicken the curry.
            For a gluten-free option, dry roast the brown rice flour in a non-stick pan over low-medium heat for 4-5 minutes.
            Stir constantly to ensure even roasting.
            If you do not use pre-made Nihari Masala, increase the spices per taste.
            Ginger powder, onion powder, and garam masala can boost the flavor.
            Doubling the recipe: Double all ingredients except the water.
            Use 5 1/2 cups water instead of 6 or 7.
            """
        )
        saveRecipe(
            name: "Nutty Steamed Buns",
            prepTime: "2 hours",
            cookingTime: "25 minutes",
            ingredients: [
                "300 grams all-purpose flour (*see conversion to cups)",
                "1 teaspoon instant dry yeast",
                "225 milliliters water (room temperature)",
                "1/2 cup Chinese sesame paste or natural peanut butter",
                "1/4 cup sugar"
            ],
            prePrepInstructions: [
                "Clean and prepare all ingredients before starting.",
                "Ensure the dough and sesame paste (or peanut butter) are ready to use."
            ],
            instructions: [
                "Add flour and instant dry yeast to a big bowl. Mix well with a spatula.",
                "Slowly add water and mix with a spatula until fully absorbed and there is no dry flour.",
                "Dust both hands with flour and start kneading. Continue to add flour as needed and knead until dough forms.",
                "Dust a working surface with flour, transfer the dough, and knead until smooth, about 10 minutes.",
                "Transfer dough to a big bowl, cover with a wet kitchen towel, and let rest for 30 minutes.",
                "Dust the working surface and your hands again. Knead dough for another 10 minutes until smooth.",
                "Divide the dough in half and shape each into a ball. Cover with a damp towel and let rest for 1 hour.",
                "Stir the sesame paste (or peanut butter) until smooth. Add sesame paste and sugar to a bowl and mix well.",
                "Dust the working surface and dough with flour. Roll dough into a rectangular sheet, about the thickness of two dollar coins.",
                "Spread half of the sesame paste evenly on the dough, leaving 2cm (0.8 inches) from the edge. Roll the sheet from the short side carefully.",
                "Divide the roll into six equal parts with a sharp knife.",
                "To shape the buns, press the middle of each bun (non-swirl side) and pull the swirl parts towards you. Twist the two ends in opposite directions and pinch the ends together.",
                "If you don’t want to shape the buns, steam them directly.",
                "Prepare the steamer by adding water to the steaming rack. Place a wet dish towel on the rack and let the buns rest for 10 minutes.",
                "Heat the steamer on high heat until the water boils. Turn to medium heat and steam the buns for 12 minutes.",
                "Be careful of the steam when removing the cover. Let the buns cool for a minute before transferring them to a plate.",
                "Serve warm."
            ],
            notes: """
            Servings: 12.
            Prep time: 2 hours.
            Cooking time: 25 minutes.
            If using a cup to measure flour and water, do not add all the water at once.
            The Chinese sesame paste is thick at the bottom. Use the thicker part for best results.
            Spread just a thin layer of sesame paste to avoid spilling when cutting.
            You can use a steamer liner or parchment paper with small holes as an alternative.
            """
        )
        saveRecipe(
            name: "Indian Onion Masala (Instant Pot)",
            prepTime: "10 minutes",
            cookingTime: "30 minutes",
            ingredients: [
                "½ cup neutral oil (like avocado oil)",
                "2 pounds yellow onions (approx. 6, diced)",
                "1 head of garlic (approx. 12 garlic cloves, chopped)",
                "2-inch ginger, chopped",
                "2 pounds roma tomatoes (approx. 9 tomatoes, chopped or 2 cans of diced tomatoes)",
                "¼ cup water",
                "\\ Spices",
                "3 tablespoons ground coriander",
                "1 tablespoon paprika",
                "½ teaspoon ground cumin",
                "½ teaspoon turmeric",
                "¼ teaspoon cayenne"
            ],
            prePrepInstructions: [
                "Dice the onions, chop the garlic, ginger, and tomatoes."
            ],
            instructions: [
                "Press the sauté button on the Instant Pot, adjust the heat to the highest setting, then add the oil to the pot.",
                "Wait for the oil to get hot, then add the onions. Cook for 15-20 minutes, stirring occasionally, until browned.",
                "Add the garlic and ginger and stir-fry for 1-2 minutes.",
                "Add the tomatoes and cook for another 3-5 minutes, scraping the brown bits from the bottom of the pot.",
                "Add water, mix well, then add the spices and stir everything together.",
                "Secure the lid, close the pressure valve, and cook for 5 minutes at high pressure.",
                "Allow the pressure to naturally release.",
                "Blend the masala using a blender or immersion blender until smooth or slightly chunky.",
                "Once the masala cools, store in a silicone mold for future use."
            ],
            notes: """
            Servings: 5.25 cups.
            Prep time: 10 minutes.
            Cooking time: 30 minutes.
            For best results, use Roma tomatoes as they have less water content.
            If using canned tomatoes, use the whole contents of the can.
            Make sure to sauté the onions at the highest setting for even caramelization.
            Store the masala in the fridge before freezing to reduce freezer burn.
            """
        )
        saveRecipe(
            name: "Pad See Ew (Quick & Easy)",
            prepTime: "15 mins",
            cookingTime: "5 mins",
            ingredients: [
                "550 g fresh rice noodles (1-inch wide noodles or rice noodle rolls)",
                "226 g skinless boneless chicken thighs or chicken breast",
                "70 g Chinese broccoli or bok choy, yu choy sum, or broccolini",
                "2 large eggs",
                "4 cloves garlic, minced",
                "1 red chili pepper, sliced",
                "30 ml vegetable oil or any neutral oil",
                "15 ml oyster sauce or vegetarian stir fry sauce to marinate chicken",
                "\\ Noodle sauce ingredients",
                "30 ml dark soy sauce",
                "15 ml regular soy sauce",
                "15 ml oyster sauce or vegetarian stir fry sauce",
                "37 ml white vinegar or rice vinegar/apple cider vinegar",
                "15 ml fish sauce",
                "10 g white granulated sugar or cane sugar/brown sugar/palm sugar"
            ],
            prePrepInstructions: [
                "Marinate sliced chicken with oyster sauce and set aside.",
                "Wash Chinese broccoli in cold water and trim the ends. Cut into 2-inch-long pieces.",
                "In a small bowl, combine noodle sauce ingredients and set aside.",
                "Microwave rice noodles for 2-3 minutes at 60-second intervals until warm. Let cool and gently separate them. If using rice noodle sheets, slice into 1-inch wide noodles. If using rice noodle rolls, split down the middle by hand."
            ],
            instructions: [
                "In a large pan on medium-high heat, add ½ tablespoon of vegetable oil and fry chicken until cooked through, about 2-4 minutes. Remove and set aside.",
                "Reduce heat to low, add ½ tablespoon of vegetable oil and fry minced garlic and red chili for 10 seconds.",
                "Add Chinese broccoli and fry for 1 minute or until softened, then push everything to the side of the pan.",
                "Add ½ tablespoon oil into the empty space, pour in eggs and scramble them, breaking into bite-sized pieces. Toss with other ingredients and push to the side.",
                "Increase heat to high, add remaining vegetable oil into the empty space. Toss in rice noodles and noodle sauce, stirring until most of the sauce has evaporated. Add back in chicken and toss.",
                "Optional: Let the noodles char for 30-60 seconds in the pan for a smoky flavor. Serve and enjoy!"
            ],
            notes: """
            Servings: 4.
            Prep time: 15 minutes.
            Cook time: 5 minutes.
            The marinated chicken should be cooked through and removed before the garlic and vegetables are fried.
            You can substitute any leafy greens for the Chinese broccoli.
            Adjust the amount of rice vinegar based on your taste preference.
            """
        )
        saveRecipe(
            name: "Pan-Fried Pakora (Pakistani)",
            prepTime: "10 mins",
            cookingTime: "20 mins",
            ingredients: [
                "1 small (or 1/2 large) onion, quartered and thinly sliced",
                "1 small (or 1/2 large) russet potato, peeled, quartered lengthwise, and thinly sliced",
                "1/2-1 small Serrano pepper or Thai green chili pepper, finely chopped (remove seeds for less spice)",
                "1 – 2 tbsp cilantro leaves, chopped",
                "1 tbsp mint leaves, chopped (optional)",
                "½ tbsp neutral oil, may omit but this makes them extra moist",
                "1 tsp lemon juice",
                "1 – 1 ½ tsp whole coriander seeds, roughly crushed using a mortar and pestle",
                "1 tsp cumin seeds",
                "1/2 tsp crushed red chili flakes",
                "1 1/8 tsp table salt, or to taste",
                "1/4 tsp baking soda",
                "scant 1 cup chickpea flour, gram flour/besan",
                "2/3 – 3/4 cup water",
                "neutral oil such as grapeseed or avocado, as needed for pan frying",
                "\\ Optional add-ins",
                "1/4 tsp whole carom seeds (ajwain), roughly crushed using a mortar and pestle",
                "½ tbsp dried fenugreek leaves (methi), crushed between the palms of your hands",
                "1/4 tsp red chili powder, for extra spice",
                "simple green chutney, optional – for serving"
            ],
            prePrepInstructions: [
                "Slice the potatoes thin for faster cooking.",
                "Prepare the simple green chutney by adding all ingredients in a spice/coffee grinder or blender and blending until smooth. Add water as needed to thin it out. Put the mixture in a bowl and whisk with yogurt, if desired."
            ],
            instructions: [
                "Combine all the ingredients up until the chickpea flour in a bowl.",
                "In another bowl, add the chickpea flour and 2/3 cup water and stir to combine so that no large lumps remain (small lumps are okay). Add additional water if needed to have a pourable consistency. Pour this mixture into the vegetables and mix well.",
                "Heat a large skillet over medium-high heat. Once hot, add enough oil to thinly coat the bottom of the pan.",
                "Add the pakora mixture a heaped tablespoon at a time, making sure not to overcrowd the pan (I do 4 at a time).",
                "Reduce the heat to medium and cook for 3-4 minutes on each side, adding oil as needed. Repeat until all pakoras are cooked.",
                "Place on a plate topped with paper towels to absorb excess oil. Serve with green chutney (recipe in the notes) and/or ketchup."
            ],
            notes: """
            Yield: 6 servings.
            Prep time: 10 minutes.
            Cook time: 20 minutes.
            Slice potatoes thin for faster cooking.
            For the chutney, you can also double the quantity of cilantro or mint and omit the other.
            """
        )
        saveRecipe(
            name: "Pakora Recipe (Crispy, Simple, Homestyle)",
            prepTime: "20 mins",
            cookingTime: "30 mins",
            ingredients: [
                "1 large (250 g) yellow onion, quartered and thinly sliced",
                "1 medium (220 g) Russet potato, peeled, quartered/cut into wedges lengthwise and thinly sliced",
                "\\ Note 1: There is no right way to cut the potatoes, as long as you get thinly sliced wedges or rectangles. As a general rule, for small potatoes, cut them in quarters lengthwise and then slice each quarter thinly into 1/6-1/4” thick pieces. For medium/large potatoes, cut them into 6-9 wedges (so that each wedge is ~1” thick) and then thinly slice them into 1/6-1/4” inch thick pieces.",
                "1 cup (60 g) red or green cabbage, thinly sliced into 1” pieces (sub 1 cup/30g chopped spinach or your choice of veggie – Note 2)",
                "2 (25 g) Serrano peppers, finely chopped (deseed for less heat)",
                "1/2 cup (14 g) cilantro, stems included, finely chopped",
                "2 tsp red chili flakes",
                "1/2 tsp red chili powder or cayenne pepper",
                "1 tbsp coriander seeds, roughly crushed using a mortar & pestle",
                "2 tsp cumin seeds, roughly crushed using a mortar & pestle",
                "1 tbsp neutral oil, such as grapeseed oil, plus more for frying",
                "1 tbsp lemon juice",
                "2 tsp sea salt/table salt",
                "1 1/4 cup (~190 g) besan (gram flour), Note 3",
                "1/2 cup + 1 tbsp chilled water, Note 4",
                "1/8 tsp baking soda, optional – Note 6",
                "\\ Optional add-ins:",
                "1/4 tsp whole carom seeds (ajwain), roughly crushed using a mortar and pestle",
                "½ tbsp dried fenugreek leaves (methi), crushed between the palms of your hands",
                "1/4 tsp red chili powder, for extra spice",
                "simple green chutney, optional – for serving"
            ],
            prePrepInstructions: [
                "For the chutney, you can double the quantity of cilantro or mint and omit the other.",
                "Cold water helps make crispy pakoras. Use refrigerated water or place ice cubes in room temperature water to chill."
            ],
            instructions: [
                "Make Pakora Mixture: In a medium bowl, combine the ingredients listed under 'Pakora' except besan/gram flour, water, and baking soda. Stir in besan and mix to combine so that the vegetables are lightly coated (okay if besan starts to clump up). Add measured water, bit by bit, until the mixture is coated but not runny. Taste and adjust seasoning, adding salt to taste, cumin/coriander for earthiness, red chili flakes/powder for heat, and lemon for tang. Lastly, mix in the baking soda, if using. Set aside. The vegetables will release their own moisture and the mixture will become thinner. (See Troubleshooting Tips)",
                "Preheat oil: Heat a large frying pan or heavy-bottomed pot over medium heat. Add oil so that it’s about 1.5-2”/4-5 cm deep. It should be deep enough so that the batter doesn’t stick to the bottom. Once the oil is hot, adjust heat level as needed to maintain medium heat (300-320°F/150°-160°C).",
                "Fry Pakoras: Gently lower a generous 1 tbsp of pakora mixture into the hot oil, making sure not to overcrowd the pan. (I like to use tongs to pick up the mixture and lower into the oil.) To make them as crispy as possible, try to shape them flat and uneven instead of round and pudgy. Onion sticking out and uneven/wispy edges is a good thing. Fry, turning often, until crispy and golden brown all over, 8-10 minutes. You want to maintain medium temperature to ensure they have time to fully cook from the inside.",
                "Remove: Use a slotted spoon to transfer the pakoras onto a paper towel-lined plate (if serving immediately) or wire cooling rack (if serving later – Note 5). Repeat until all pakoras are cooked. Sprinkle with chaat masala if you'd like. Serve immediately with Green Chutney (quick recipe in post), Mint Raita, or sauce of choice."
            ],
            notes: """
            Yield: 5 servings.
            Prep time: 20 minutes.
            Cook time: 30 minutes.
            Slice the potatoes thin for faster cooking.
            For the chutney, you can double the quantity of cilantro or mint and omit the other.
            """
        )
        saveRecipe(
            name: "Pandan Custard Cake",
            prepTime: "20 mins",
            cookingTime: "1 hr",
            ingredients: [
                "4 eggs yolks and whites separated",
                "0.75 cup white granulated sugar",
                "0.25 cup water",
                "3 pandan leaves cut into 3 inch pieces",
                "0.5 cup unsalted butter melted",
                "0.75 cup all purpose flour",
                "2 cups milk lukewarm",
                "Icing sugar"
            ],
            prePrepInstructions: [
                "Preheat oven to 325F/160C.",
                "Grease a 8\" x 8\" square cake pan.",
                "In a blender, add chopped pandan leaves and ¼ cup water. Blend on high. Run the pandan liquid through a sieve to remove the pulp to discard. Reserve the liquid for later."
            ],
            instructions: [
                "In a large mixing bowl, add egg yolks and sugar to a bowl and beat until it turns pale yellow.",
                "Then add the melted butter and beat until well combined.",
                "Next add flour and only beat until just combined.",
                "Whisk together your milk and pandan liquid. Microwave for 60 seconds until lukewarm.",
                "Gradually add pandan milk to your egg mixture (about ¼ cup at a time). Beat until well combined.",
                "Now beat egg whites until you reach stiff peaks.",
                "With a spatula, fold ⅓ of the egg whites into the batter at a time until incorporated. The batter will be very runny and there will be lumps, which is fine.",
                "Pour the batter into your square cake pan.",
                "Bake for 60-65 minutes. At the 30 minute mark, cover loosely with aluminum foil. To check if it is cooked, insert a toothpick to check if it comes out clean. If it's clean, then remove it from the oven. If not, leave it in the oven covered for another 10 minutes.",
                "Allow to cool in the cake pan for 10 minutes, then transfer to a cooling rack.",
                "To serve, sprinkle icing sugar over top, slice and enjoy!"
            ],
            notes: """
            Yield: 12 pieces.
            Prep time: 20 minutes.
            Cook time: 1 hour.
            """
        )
        saveRecipe(
            name: "Super Soft Pandan Kaya Milk Buns",
            prepTime: "20 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "135 g whole milk plus more as needed",
                "10 blades pandan leaves",
                "250 g bread flour",
                "50 g all-purpose flour",
                "10 g milk powder",
                "4 g fine sea salt",
                "50 g sugar",
                "4 g instant yeast",
                "30 g egg save the rest for egg wash",
                "30 g butter softened, unsalted",
                "\\ Noodle sauce ingredients",
                "55 g active starter (100% hydration)",
                "165 g bread flour (12.7% protein content)",
                "65 g whole milk",
                "30 g sugar",
                "58 g bread flour (12.7% protein content)",
                "50 g all-purpose flour",
                "20 g milk powder",
                "4 g fine sea salt",
                "50 g sugar",
                "30 g whole milk or more as needed",
                "1 tsp pandan essence",
                "30 g egg",
                "30 g butter softened, unsalted",
                "240 g Easy Authentic 10-minute Kaya Jam or use store-bought kaya jam",
                "Leftover egg from the recipe above"
            ],
            prePrepInstructions: [
                "Grease a 9 x 9 inch square pan and line with parchment paper.",
                "Cut pandan leaves into small pieces. Blend the leaves with milk and strain the mixture, discarding the pulp."
            ],
            instructions: [
                "If using sourdough starter, mix the ingredients for the sweet stiff starter and let rise for 10-12 hours.",
                "To prepare the dough, add all ingredients except for the butter. If using sourdough, tear starter pieces and add pandan essence.",
                "Knead with a dough hook for 2-3 minutes at low speed, increase speed to knead for 6-8 minutes until dough is soft and smooth.",
                "Add softened butter and knead for 2-3 minutes until incorporated. The dough should be soft, smooth, and slightly sticky.",
                "For first proofing, lightly oil the bowl, cover, and let rise for 45 minutes to 1 hour until doubled.",
                "For sourdough, proof for 2 hours at 82°F (28°C).",
                "Once proofed, punch down the dough and divide into 9 equal portions, rolling each into a ball. Let rest for 5 minutes.",
                "Shape each dough piece by rolling into a rectangle, add a tablespoon of kaya filling, and fold the dough to enclose the filling.",
                "Roll the dough and shape into an oval bun, placing them diagonally in the pan. Repeat for remaining dough.",
                "For final proofing, cover the pan and let the buns proof for 45 minutes to 1 hour until puffy. For sourdough, this may take 3-3.5 hours.",
                "Preheat the oven to 375°F (190°C) and apply egg wash to the buns before baking for 15 minutes or until golden brown.",
                "Cool the buns on a wire rack before serving."
            ],
            notes: """
            Yield: 12 buns.
            Prep time: 20 minutes.
            Cook time: 15 minutes.
            Proofing time: 2 hours.
            Total time: 2 hours 35 minutes.
            For sourdough version, use pandan essence and sweet stiff starter.
            """
        )
        saveRecipe(
            name: "Panko-Crusted Cod (Crunchy)",
            prepTime: "6 minutes",
            cookingTime: "4 minutes",
            ingredients: [
                "1/4 cup all-purpose flour",
                "1 egg, beaten",
                "3/4 cup Panko bread crumbs",
                "1/2 cup Olive oil",
                "1 pound Cod fillets",
                "1 teaspoon salt",
                "1 teaspoon pepper"
            ],
            prePrepInstructions: [
                "Set up three separate stations for the ingredients needed to make your breadcrumbs: flour, beaten egg, and Panko breadcrumbs."
            ],
            instructions: [
                "Heat the olive oil in a large frying pan over high heat. Be careful not to burn it. This should only take a few minutes.",
                "Season the fish fillets with salt and pepper. Then, dip them in an egg wash before rolling them in flour. Next, press the breaded fish sticks into Panko breadcrumbs.",
                "Carefully place the fish into a hot pan. Reduce the heat to medium level and let it sizzle, without burning.",
                "The key to cooking fish is to make sure you’ve cooked it on both sides before turning the heat down to low. This will ensure that it doesn’t end up overcooked and dry.",
                "To avoid overcooking or undercooking your fish, you should reduce the heat so it can cook evenly and not burn. Fish is done cooking when it’s browned on both sides."
            ],
            notes: """
            Serve immediately after removing it from the hot oil.
            Complement this dish with sweet and delicious baby carrots and hearty asparagus.
            """
        )
        saveRecipe(
            name: "Panko-Crusted Fish Fillets (Baked)",
            prepTime: "15 minutes",
            cookingTime: "20 minutes",
            ingredients: [
                "1 1/2 pounds fish fillets, such as haddock, cod, catfish, pollock, or similar mild white fish",
                "Kosher salt, to taste",
                "Freshly ground black pepper, to taste",
                "1 cup panko breadcrumbs (unseasoned)",
                "2 tablespoons finely chopped parsley",
                "1/4 cup all-purpose flour",
                "2 large eggs (or 1/2 cup egg substitute)",
                "1 teaspoon Cajun seasoning (or Creole)",
                "2 tablespoons mayonnaise",
                "1 lemon, quartered, for serving, optional",
                "Tartar sauce, for serving, optional",
                "Remoulade sauce, for serving, optional"
            ],
            prePrepInstructions: [
                "Gather the ingredients.",
                "Heat the oven to 425°F.",
                "Line a rimmed baking sheet with aluminum foil or parchment paper and then spray it with nonstick cooking spray."
            ],
            instructions: [
                "Cut 1 1/2 pounds fish fillets into 6-ounce portions.",
                "Sprinkle both sides of the fish pieces with kosher salt and freshly ground black pepper.",
                "In a wide bowl, combine 1 cup unseasoned panko breadcrumbs and 2 tablespoons finely chopped parsley.",
                "Put 1/4 cup all-purpose flour in another wide, shallow bowl.",
                "In a third bowl, whisk 2 large eggs (or egg substitute) with 1 teaspoon Cajun seasoning and 2 tablespoons mayonnaise.",
                "Dip the fish fillets in the plain flour, coating each piece thoroughly.",
                "Dip the flour-coated fillets in the egg mixture and then coat them with the panko crumb mixture, pressing lightly to help the crumbs adhere to the fish. Repeat with the remaining fish.",
                "Arrange the crumb-coated fish on the prepared baking sheet.",
                "Bake for about 16 to 20 minutes or until the fish flakes easily with a fork. The time in the oven depends on thickness, so adjust for very thin or very thick fish fillets.",
                "Serve the baked fish fillets with lemon wedges and tartar sauce or rémoulade sauce."
            ],
            notes: """
            Serve the baked fish fillets with lemon wedges and tartar sauce or rémoulade sauce.
            Any leftovers will keep in the fridge for three to four days. Reheat in the oven at 350°F for 10-15 minutes.
            """
        )
        saveRecipe(
            name: "Paratha Recipe (Easy Lachha Homestyle)",
            prepTime: "15 minutes",
            cookingTime: "30 minutes",
            ingredients: [
                "2 cups (280 g) atta flour, (also called durum wheat flour), plus more for dusting",
                "1/4-1/2 tsp (3 g) sea salt",
                "1 cup (227 g) room temperature water",
                "Salted butter, preferably closer to room temperature so it’s easier to spread – sub ghee or oil"
            ],
            prePrepInstructions: [
                "Combine the atta flour and salt in the bowl of a stand mixer fitted with a dough attachment. Turn on the mixer to medium-low (2) speed to start mixing the atta and salt. Over the course of 3 minutes, slowly pour in the water, letting it mix with the dough before adding more. It will start to form a ball.",
                "Increase the speed to medium (4) and continue to knead on medium speed until a smooth and supple ball of dough forms (~3 min). It should start wrapping itself around the dough attachment."
            ],
            instructions: [
                "Alternatively, knead by hand. Place the atta flour and salt in a medium bowl and mix to combine. Over the course of 4 minutes, slowly pour in the water while using your hands to combine the flour.",
                "Let the water mix with the dough before adding more. Focus on breaking the tough clumps. Using wet or oiled hands, knead for another 4 minutes by gently punching the dough with your knuckles, then folding over.",
                "If the dough seems dry, tough, or unable to form, add an additional 1-2 tbsp of water. If it seems a little too wet, dust it with 1-2 tbsp atta flour.",
                "The final dough should be soft to the touch, supple, and pliable. It will be slightly sticky but will not cling to your fingers if you touch it with wet hands.",
                "Remove the dough and place in an airtight container. Cover and let the dough rest for 10-15 minutes. Refrigerate if not using immediately, up to 3 days.",
                "Once ready to cook, divide the dough into 9 equal portions, shape them into balls, and roll out each piece into a flat disc.",
                "Heat a tawa (or pan) over medium-high heat. Roll each dough ball into a flat 5-6 inch circle and brush butter onto the surface.",
                "Roll the dough up Swiss-roll style, then twist it into a spiral. Roll it out again into an 8-9 inch circle.",
                "Place the paratha on the tawa, cooking both sides until golden brown and crispy, adding butter as needed. Flip the paratha frequently for even cooking.",
                "Once golden and crisp on both sides, remove from the tawa and serve."
            ],
            notes: """
            The dough should rest for 10-15 minutes to allow the gluten to develop. This makes it easier to handle and roll.
            Make sure the butter is soft to spread easily on the dough. You can also substitute with ghee or oil.
            Serve the parathas hot with a side of chutney or yogurt.
            """
        )
        saveRecipe(
            name: "Peanut Butter Chocolate Layer Cake",
            prepTime: "20 minutes",
            cookingTime: "1 hour",
            ingredients: [
                "1 3/4 cups (228g) all purpose flour",
                "2 cups (414g) sugar",
                "3/4 cup (85g) natural unsweetened cocoa powder",
                "2 1/4 tsp baking soda",
                "1/2 tsp baking powder",
                "1 tsp salt",
                "1 cup (240ml) milk",
                "1/2 cup (120ml) vegetable oil",
                "1 1/2 tsp vanilla extract",
                "2 large eggs",
                "1 cup (240ml) hot water",
                "\\ Peanut butter frosting",
                "2 cups (448g) salted butter, room temperature",
                "1 1/4 cups (350g) peanut butter",
                "9 cups (1035g) powdered sugar",
                "6–7 tbsp (90-105ml) water or milk",
                "6 reeses, chopped",
                "\\ Chocolate ganache and topping",
                "6 oz (1 cup) semi-sweet chocolate chips",
                "1/2 cup (120ml) heavy whipping cream",
                "8 reeses, cut in half",
                "Crumbled reeses"
            ],
            prePrepInstructions: [
                "Preheat oven to 350°F (176°C) and prepare three 8-inch cake pans with non-stick baking spray and parchment paper in the bottom."
            ],
            instructions: [
                "In a large mixer bowl, add the flour, sugar, cocoa, baking soda, baking powder, and salt. Combine and set aside.",
                "In a medium-sized bowl, add the milk, vegetable oil, vanilla extract, and eggs. Combine.",
                "Add the wet ingredients to the dry ingredients and beat until well combined.",
                "Slowly add the hot water to the batter and mix on low speed until well combined. Scrape down the sides of the bowl as needed to ensure everything is combined.",
                "Divide the batter evenly between the prepared cake pans and bake for 22-25 minutes, or until a toothpick comes out with a few moist crumbs.",
                "Remove cakes from the oven and allow them to cool for 2-3 minutes, then transfer to a cooling rack to finish cooling.",
                "For the frosting, combine the butter and peanut butter in a large mixer bowl and mix until well combined.",
                "Add half of the powdered sugar and mix until smooth. Add 3 tablespoons of water or milk and mix until smooth.",
                "Add the remaining powdered sugar and mix until smooth. Add remaining water or milk, adjusting the consistency as needed.",
                "To assemble the cake, use a serrated knife to level the tops of the cake layers.",
                "Place the first cake layer on a serving plate or cake board and top with about 1 cup of frosting. Smooth the frosting into an even layer.",
                "Add half of the chopped Reese’s on top of the frosting and press into the frosting. Spread a small amount of frosting on top of the Reese’s to make it sticky for the next cake layer.",
                "Add the next cake layer and top with another 1 cup of frosting. Smooth the frosting into an even layer.",
                "Add the remaining chopped Reese’s on top of the frosting and press into the frosting. Spread a small amount of frosting on top to make it sticky for the next cake layer.",
                "Add the final cake layer to the top of the cake.",
                "Smooth the frosting around the sides of the cake, creating a thin crumb coat. Add 1 cup of frosting to the top of the cake and smooth it into an even layer.",
                "Use an offset spatula to create stripes around the cake.",
                "Set the cake aside and make the chocolate ganache.",
                "Put the chocolate chips in a heatproof bowl.",
                "Microwave the heavy whipping cream until it just begins to boil, then pour it over the chocolate chips. Allow it to sit for 2-3 minutes, then whisk until smooth.",
                "Use a squeeze bottle or spoon to drizzle the ganache around the edges of the cake, then fill in the top and smooth it with an offset spatula.",
                "Allow the ganache to firm up for about 10 minutes, then top the cake with remaining frosting, additional chopped Reese’s, and crumbled Reese’s.",
                "Refrigerate the cake until ready to serve. Serve at room temperature. The cake is best for 3-4 days."
            ],
            notes: """
            Make sure the cake is completely cool before frosting and assembling.
            You can substitute the Reese's with any other candy or topping of choice.
            This cake can be stored in the fridge for 3-4 days.
            """
        )
        saveRecipe(
            name: "Pepper Prawn Paella",
            prepTime: "20 minutes",
            cookingTime: "40 minutes",
            ingredients: [
                "1/2 lb Jumbo Shrimp or prawns (12 cleaned – peeled, tail on)",
                "1 tbsp all purpose seasoning",
                "1 tsp minced garlic",
                "1 tsp black pepper and salt",
                "1 tsp thyme",
                "1/2 scotch bonnet chillies diced",
                "Extra virgin olive oil (Spanish EVOO if you have it)",
                "8 oz calamari rings, chopped",
                "1 teaspoon paprika",
                "4 boneless & skinless chicken thighs, diced",
                "1 onion, diced",
                "1 red bell pepper, diced",
                "4 cloves garlic",
                "250g diced tomatoes",
                "1 tbsp tomato puree",
                "2 bay leaves",
                "1 pinch saffron threads",
                "1/4 cup flat leaf parsley, chopped, divided",
                "400g Spanish rice",
                "1 litre water + 2 chicken stock cubes",
                "125g frozen peas",
                "1/2 lb mussels (about 10-12 cleaned)",
                "1 lemon",
                "Aluminum foil"
            ],
            prePrepInstructions: [
                "Season prawns with all purpose seasoning, garlic, black pepper, salt, thyme, scotch bonnet and mix together."
            ],
            instructions: [
                "In a paella pan (or deep wide pan), sauté calamari in olive oil, put to side of pan, pan fry prawns for 1 minute on each side (do not fully cook).",
                "Remove calamari and prawns. Add more olive oil to the pan, sauté chicken until browned, then move to the edge of the pan and sauté garlic, onion, and bell peppers until soft.",
                "Add bay leaf, salt, black pepper, saffron, tomatoes, tomato puree, and chopped tomatoes. Mix everything.",
                "Add rice and parsley, stir, then boil chicken stock and saffron in a separate pot. Add to the paella pan until the liquid level is above the rice. Cook uncovered for 15-20 minutes.",
                "Add prawns, mussels, and peas, then turn off heat. Cook covered with foil for 10 minutes.",
                "Garnish with lemon and parsley."
            ],
            notes: """
            Make sure not to fully cook the prawns in the initial step to avoid overcooking them during the final cooking stage.
            Use Spanish rice for the best texture and consistency.
            Let the paella cook uncovered for the first 15-20 minutes to allow the rice to absorb the flavors.
            You can substitute mussels with any shellfish of your choice or use additional prawns.
            """
        )
        saveRecipe(
            name: "Pho Ga (Vietnamese Chicken Noodle Soup Instant Pot)",
            prepTime: "30 minutes",
            cookingTime: "55 minutes",
            ingredients: [
                "1 (roughly 1.3kg - 1.8kg) good quality whole free range chicken (or 1.6kg drumsticks + thighs)",
                "2 medium onions (one yellow 241g, one white 249g), peeled and halved",
                "13 grams ginger, unpeeled & cut into long strips",
                "1 (36g) small bunch fresh cilantro",
                "1 garlic clove, crushed",
                "15 grams yellow rock sugar or 1 tablespoon of brown sugar",
                "4 cloves",
                "1/2 (3g) cinnamon stick",
                "1 tablespoon (5g) coriander seeds",
                "8 cups (2L) cold water",
                "2 tablespoons (30ml) fish sauce",
                "1/2 teaspoon fine table salt + more to taste",
                "2 tablespoons (30ml) vegetable oil",
                "\\ Noodles",
                "medium banh pho (flat rice noodles), soaked in lightly salted hot water for 18 - 25 minutes (70g - 80g per person)",
                "\\ Garnishes on noodles",
                "1/2 small white onion, thinly sliced",
                "Fresh cilantro, leafy part",
                "1 - 2 stalks green onion, finely chopped",
                "A touch of freshly ground black pepper",
                "Optional: Hard boiled quail eggs",
                "\\ Herb platter on the side",
                "Bean sprouts (40g per person)",
                "1 lime, cut into 6 wedges",
                "\\ Optional",
                "Mint",
                "Thai chili pepper",
                "Thai basil",
                "Hoisin sauce",
                "Sriracha"
            ],
            prePrepInstructions: [
                "Toast spices: Place 1 tbsp coriander seeds, half a cinnamon stick, and 4 cloves in the pressure cooker. Heat up your pressure cooker over medium heat (Instant Pot: press Saute button). When you smell the fragrance released from the spices (~2mins), remove and set aside.",
                "Char onions and ginger: Make sure your pot is as hot as it can be over medium heat (Instant Pot: wait until the indicator says HOT). Pour in vegetable oil and coat the oil over the bottom of the pot. Carefully place 2 halved medium onions (flat side down) and the ginger pieces in the pressure cooker. Allow them to char for ~5 minutes. At the four-minute mark, add in the crushed garlic clove."
            ],
            instructions: [
                "Pressure cook chicken broth: Pour in 1/2 cup cold water and deglaze the bottom of the pot with a wooden spoon. Add in toasted spices, yellow rock sugar, fresh cilantro, fish sauce, and salt. Pour in 3 1/2 cups cold water. Carefully add in the whole chicken (or chicken drumsticks + thighs). Pour in 4 cups cold water, making sure the chicken is at least 90% submerged.",
                "Close lid and pressure cook at High Pressure for 10 minutes + 20 minutes Natural Release. After 20 minutes, turn the venting knob to release the remaining pressure.",
                "Prepare garnish: While the pressure cooker is cooking, thinly slice the 1/2 small white onion and soak in cold water for 15 minutes to reduce pungency. Prepare the remaining garnishes.",
                "Prepare Banh Pho: While the broth is cooking, place dried Banh Pho in a large bowl. Pour in lightly salted boiling water and stir occasionally. Once cooked (18-25 minutes), drain and run under cold water.",
                "Strain chicken broth: Transfer the whole chicken to a large bowl with cold water to cool and firm the skin. Strain the broth through a fine mesh strainer, and remove the fat with a fat separator or skim off with a ladle.",
                "Season chicken broth: Bring the broth back to a boil. Taste and adjust the seasoning by adding more salt if needed.",
                "Serve: Place cooked Banh Pho and chicken pieces in a bowl. Garnish with white onion slices, chopped green onions, fresh cilantro, hard boiled quail eggs (optional), and freshly ground black pepper. Pour in boiling chicken broth and serve hot."
            ],
            notes: """
            Star Anise is omitted in this recipe to maintain a clean-flavored broth.
            You can adjust the amount of salt and fish sauce in the broth to suit your taste.
            Use freshly ground black pepper to season the soup for enhanced flavor.
            Serve with a side platter of herbs, lime wedges, and chili peppers for an authentic Pho experience.
            """
        )
        saveRecipe(
            name: "Pistachio Sponge Cake",
            prepTime: "15 minutes",
            cookingTime: "1 hour 5 minutes",
            ingredients: [
                "5 egg yolks",
                "60g fine sugar",
                "80g vegetable oil",
                "100ml milk",
                "120g cake flour",
                "30g pistachio nuts (grinded)",
                "5 egg whites",
                "75g fine sugar",
                "½ tsp cream of tartar",
                "\\ Cream Cheese Frosting",
                "100g cream cheese",
                "30g powdered sugar",
                "1 tsp vanilla extract",
                "300g whipped cream",
                "\\ Dust with",
                "Grinded pistachio"
            ],
            prePrepInstructions: [
                "Preheat the oven to 150°C/300°F.",
                "Grind ½ cup pistachio nuts in a food processor and set aside.",
                "Separate the eggs into yolks and whites."
            ],
            instructions: [
                "In a large bowl, add the egg yolks and sugar. Mix well until the sugar almost dissolves. Add the oil, milk, and vanilla extract. Mix until well combined.",
                "Sift the dry ingredients (flour and grinded pistachios) into the mixture. Whisk in a circular motion until the flour disappears.",
                "In another bowl, add cream of tartar to the egg whites and mix until bubbly. Gradually add in the sugar, continuing to mix until stiff peaks form.",
                "Add the egg white mixture into the batter in a few batches. Use a whisk and mix gently in a circular motion. Do not over-mix. Mix just until well combined.",
                "Grease and line a 7x7-inch pan with parchment paper. Pour the batter into the prepared pan. Use a stick or skewer to give a horizontal and vertical movement to prevent holes and release air pockets.",
                "Bake in the preheated oven at 150°C/300°F for 30 minutes, then lower the temperature to 140°C/285°F for 35 minutes. Total bake time is about 65 minutes.",
                "Let the cake cool completely, then slice it into 3 sheets."
            ],
            notes: """
            If you want to achieve a cotton-soft texture, use cake flour.
            Be careful not to over-mix the batter after adding the egg whites, as it can affect the texture of the cake.
            The cream cheese frosting should be stiff but not over-mixed to prevent it from becoming too thick.
            Dust with grinded pistachio for an extra touch of flavor.
            """
        )
        saveRecipe(
            name: "Pomegranate Salad (Turkish Tomato Salad Gavurdagi)",
            prepTime: "15 minutes",
            cookingTime: "0 minutes",
            ingredients: [
                "4 roma tomatoes, chopped",
                "1 Italian green pepper, diced",
                "1 white onion, diced",
                "2 Persian cucumbers, diced",
                "3/4 cup walnuts, chopped",
                "1 cup parsley, chopped",
                "1/4 cup olive oil, extra virgin",
                "4 tbsp pomegranate molasses",
                "1 tsp sumac",
                "1/2 tsp salt",
                "*2 pomegranates, deseeded"
            ],
            prePrepInstructions: [
                "Place the chopped tomatoes, green Italian pepper, onion, cucumbers, walnuts, and parsley in a large bowl and mix well."
            ],
            instructions: [
                "Mix olive oil, pomegranate molasses, sumac, and salt in a small bowl and pour it over the salad.",
                "Mix well and cover the salad with plastic wrap. Refrigerate for 30 minutes before serving."
            ],
            notes: """
            Persian cucumbers have fewer seeds than English cucumbers, making them perfect for this tomato salad.
            Use firm, plump tomatoes as they hold up better and do not release too much juice.
            If pomegranate molasses is not available, a splash of balsamic vinegar can be used as a substitute.
            For extra crunch, add more chopped walnuts to the salad.
            """
        )
        saveRecipe(
            name: "Potato Leek Soup (Instant Pot or Stovetop Vegan)",
            prepTime: "10 minutes",
            cookingTime: "36 minutes",
            ingredients: [
                "1 tablespoon olive oil",
                "3 leeks, chopped",
                "2 garlic cloves, minced",
                "907 grams Russet potatoes (about 6 medium potatoes), scrubbed, peeled, and quartered",
                "1 liter reduced-sodium vegetable broth",
                "500 ml water",
                "1/2 teaspoon dried thyme",
                "1 bay leaf",
                "Fresh chives, diced (optional, for topping)"
            ],
            prePrepInstructions: [
                "Cut off the top and bottom of the leeks. Then, cut a slit into the top of the leek and rinse out any dirt that may have collected in the layers. Slice the leek, using mostly the white part and some of the green part (but not the thick lower green part)."
            ],
            instructions: [
                "Press the Sauté button on a 6-quart or 8-quart Instant Pot. Drizzle in the oil and let it heat up for a few minutes. See notes for stovetop directions.",
                "Add the chopped leeks and garlic. Let them cook for a few minutes, stirring occasionally.",
                "Cancel the sauté function and add the quartered potatoes, vegetable broth, water, thyme, and the bay leaf to the pot.",
                "Lock on the lid and set the time to 6 minutes at high pressure. When the cooking time is up, let the pressure come down naturally for 5-10 minutes.",
                "Use the quick release to get rid of any remaining pressure. Then, remove the lid. Use tongs to remove the bay leaf and discard.",
                "Use a hand immersion blender to blend the soup to the desired consistency. If you don’t have a hand immersion blender, you can use a blender. Use extreme caution when blending hot liquids. Always put a towel on top of the blender to protect your hands in case any hot soup escapes.",
                "Serve hot, topped with fresh chives."
            ],
            notes: """
            STOVETOP DIRECTIONS: In a large pot or Dutch oven, heat the oil over medium heat.
            Add the leeks and garlic and let them cook for a few minutes, stirring occasionally.
            Then, add the quartered potatoes, vegetable broth, water, thyme, and the bay leaf. Turn the heat to high and bring the soup to a simmer.
            Turn the heat to low, cover the pot, and let it simmer for 20-25 minutes, or until the potatoes are fork tender.
            Turn off the heat and use a hand immersion blender to blend the soup to the desired consistency. If you don’t have a hand immersion blender, you can use a blender.
            Use extreme caution when blending hot liquids. Always put a towel on top of the blender to protect your hands in case any hot soup escapes.
            You can use other types of potatoes for this recipe, including red potatoes or gold potatoes.
            You don’t have to peel the potatoes if you don’t want to, but the soup will be silkier if you peel them.
            To prep leeks, cut off the top and bottom. Then, cut a slit into the top of the leek and rinse out any dirt that may have collected in the layers.
            Then, slice the leek, using mostly the white part and some of the green part (but not the thick lower green part).
            If you don’t have leeks on hand, you can use a large onion instead.
            The cook time is for the Instant Pot directions and includes 10 minutes for the pot to come up to pressure, plus the natural release time.
            """
        )
        saveRecipe(
            name: "Potato Leek Soup 2 (Vegan)",
            prepTime: "15 minutes",
            cookingTime: "30 minutes",
            ingredients: [
                "1 tablespoon extra virgin olive oil",
                "2 medium leeks, chopped",
                "1 yellow onion, diced",
                "3 garlic cloves, minced",
                "1 celery stalk, diced",
                "1 carrot, diced",
                "900 g potatoes, cut into bite-size dices",
                "1 liter vegetable broth",
                "1 bay leaf",
                "1 teaspoon dried thyme",
                "Salt and pepper to taste",
                "2 tablespoons chives, chopped",
                "1-2 tablespoons lemon juice, more to taste"
            ],
            prePrepInstructions: [
                "Preheat a pot over medium heat with the olive oil.",
                "Sauté the leeks, onion, garlic, celery, and carrot for 5-10 minutes."
            ],
            instructions: [
                "Add the potatoes, vegetable broth, bay leaf, dried thyme, salt, and pepper.",
                "Bring the soup to a boil, then reduce the heat, cover the pot, and let the soup simmer for 15-20 minutes, until the potatoes are tender.",
                "Lock on the lid and set the time to 6 minutes at high pressure. When the cooking time is up, let the pressure come down naturally for 5-10 minutes.",
                "Use the quick release to get rid of any remaining pressure. Then, remove the lid. Use tongs to remove the bay leaf and discard.",
                "Next, take out the bay leaf and use an immersion blender to blend part of the soup. If you prefer a creamy soup without chunks, blend the soup until creamy. Add more liquid (water or vegetable broth) if needed.",
                "Add the chives and lemon juice. Add more salt and pepper if needed. Enjoy!"
            ],
            notes: """
            You can adjust the amount of lemon juice to taste depending on how tangy you prefer the soup.
            For a thicker soup, blend more of the soup until smooth.
            If you want a chunkier soup, blend only half of it and leave some texture.
            The soup can be stored in an airtight container in the fridge for up to 4 days.
            """
        )
        saveRecipe(
            name: "Puff Pastry",
            prepTime: "10 minutes",
            cookingTime: "20 minutes",
            ingredients: [
                "262 g very cold butter (salted) – If using unsalted butter, add 3⁄4 teaspoon of salt.",
                "118 g very cold water",
                "0.25 teaspoon salt",
                "260 g all-purpose flour",
                "Pear, sliced (not too thick/firm but ripe)",
                "30 g finely chopped walnuts",
                "45 g mini chocolate chips",
                "1 egg",
                "1 tablespoon water",
                "60 g shredded cheese (fontal or gruyere)",
                "25-50 g freshly grated Parmesan Cheese",
                "1-2 tablespoons chopped fresh Italian Parsley",
                "3 tablespoons brown sugar",
                "0.5 teaspoon cinnamon",
                "1 apple peeled, cored, and sliced thin"
            ],
            prePrepInstructions: [
                "Using a food processor, fitted with the metal blade, add flour and salt to the bowl, then add 3/4 cup (170 grams) cold butter cut in cubes and pulse until butter is absorbed (about 10 to 12 one-second pulses), then add the remaining cold butter (cubed) and pulse two or three times (no more) to combine, add the cold water and pulse four or five times just until the dough comes together to form a ball (really important not to over process).",
                "On a lightly floured surface, place dough and knead lightly approximately 10 times. With a lightly floured rolling pin (lightly flour the dough so it doesn't stick) roll into a rectangle approximately 12 x 18 inches (30 x 45 centimeters).",
                "Fold the dough like an envelope (see photos) then fold in half, wrap in plastic and refrigerate for 1 - 2 hours (I left mine in the fridge for two hours).",
                "Pre-heat oven to 375°F (190°C) (for all recipes)."
            ],
            instructions: [
                "Roll the remaining dough into a large circle, make 8-10 triangles. Place 1-2 slices of pear on the large part of the triangle, top with some chopped walnuts and chocolate chips. Roll up from the large part, place on prepared cookie sheet, brush with egg wash, sprinkle with a little sugar and bake for approximately 15 minutes or until golden. Let cool then dust with powdered/icing sugar. Enjoy.",
                "In a small bowl mix together Parmesan cheese and chopped parsley, set aside. Roll (1/2 or 1/3) the dough into an 1/8\" thick oval, sprinkle shredded cheese on the top half of oval, bring up the bottom half to cover the top, brush with the egg wash and sprinkle with parmesan cheese mixture, slice into 1/2 inch strips, twist and place on parchment paper lined cookie sheets. Bake for approximately 20 minutes or until golden. Eat warm. Enjoy!",
                "In a small bowl toss together, sliced apples, brown sugar, and cinnamon.",
                "Roll out the dough into a large rectangle or square 1/8\" thick, then cut into 6-8 squares. Top each square with 2-3 apple slices, brush the edges of the square with egg mixture. Fold over and seal. Brush tops of pastry with the egg wash, sprinkle with sugar and bake for approximately 20 minutes or until golden. Drizzle with a little frosting if desired."
            ],
            notes: """
            ChillingTime: "1 hour 30 minutes",
            You can also leave the dough in the fridge overnight.
            If you find your dough is browning too much, then cover it with foil and continue baking.
            Store the homemade puff pastry in the refrigerator for several days. Be sure it is sealed in plastic wrap.
            You can also freeze it. Wrap it well in plastic wrap and place in a freezer-safe bag or container. It will keep in the freezer for up to a month.
            Before using the frozen dough, leave it folded and wrapped and thaw it in the fridge overnight. Roll the dough out without unfolding it first.
            """
        )
        saveRecipe(
            name: "Raita (Cucumber Mint)",
            prepTime: "10 minutes",
            cookingTime: "0 minutes",
            ingredients: [
                "One large (or two medium) cucumbers, peeled, cut in half lengthwise and seeded, then grated",
                "2 cups (475 ml) plain whole milk yogurt",
                "10 large mint leaves, thinly sliced (can sub cilantro)",
                "1/2 teaspoon ground cumin",
                "Pinch of cayenne",
                "Pinch of paprika",
                "Salt and pepper"
            ],
            prePrepInstructions: [
                "Place grated cucumber in a sieve and press with the back of a spoon to squeeze out as much moisture as you can.",
                "Alternatively, you can place the grated cucumber in the middle of a clean tea towel, wrap the towel around the cucumber, and wring out the excess moisture."
            ],
            instructions: [
                "Stir spices and mint into yogurt in a medium bowl.",
                "Stir in the grated cucumber.",
                "Chill until ready to serve."
            ],
            notes: """
            To slice the mint leaves, chiffonade them by stacking them on top of each other, rolling them up like a cigar, and taking thin slices off the end.
            If whole cumin seeds are available, take one teaspoon and toast the seeds first in a small skillet until just fragrant. Then grind with a mortar and pestle.
            The raita can be stored in the refrigerator for up to 3 days.
            It pairs well with spicy dishes, rice, or as a dip.
            """
        )
        saveRecipe(
            name: "Red Cabbage (Pickled)",
            prepTime: "10 minutes",
            cookingTime: "0 minutes",
            ingredients: [
                "¼ of a red cabbage",
                "½ cup apple cider vinegar or red wine vinegar, 120 mL",
                "½ cup water, 120 mL",
                "1 Tbsp sugar",
                "1 clove garlic, minced",
                "1 tsp salt",
                "¼ tsp ground black pepper"
            ],
            prePrepInstructions: [
                "Remove the core from the cabbage then shred with a mandolin slicer or knife."
            ],
            instructions: [
                "Add cabbage to a large glass jar or bowl, along with all other ingredients. Seal jar and shake, or simply stir bowl and cover.",
                "Set on the counter for at least 2 hours (up to 6), shaking/stirring occasionally.",
                "Store tightly sealed in the refrigerator for 2 to 3 weeks. Serve over salads, wraps, tacos, or burgers!"
            ],
            notes: """
            The pickled cabbage will continue to develop flavor as it sits, so it's best to wait a few hours before using.
            You can adjust the sugar and vinegar ratio based on your taste preferences.
            Store it tightly sealed in the fridge for up to 3 weeks.
            """
        )
        saveRecipe(
            name: "Red Onion Pickle",
            prepTime: "over 2 hours",
            cookingTime: "less than 10 mins",
            ingredients: [
                "3 large red onions (about 500g/1lb 2oz peeled weight)",
                "2 tsp fine sea salt",
                "200ml/7fl oz cider vinegar",
                "50g/1¾oz granulated sugar",
                "1 tsp coarsely ground black pepper",
                "4 bay leaves"
            ],
            prePrepInstructions: [
                "Peel the onions, cut them in half from top to bottom and finely slice into half-moon pieces.",
                "Put in a colander placed over a bowl and sprinkle with salt, lightly turning over the onion pieces with your hands so the surfaces are all covered. Set aside for an hour or so to brine."
            ],
            instructions: [
                "Meanwhile, put the vinegar, 50ml/2fl oz water and the sugar in a saucepan. Bring to a simmer, stirring to help the sugar dissolve, and cook for a couple of minutes. Set aside.",
                "Pack the onions into the sterilised jars, sprinkling in a little pepper as you go.",
                "Cover with the warm vinegar and finish by tucking a couple of bay leaves down the side of the jars. Seal.",
                "The onions are best kept in the fridge and used within 4 weeks."
            ],
            notes: """
            The salt draws out the excess moisture from the vegetables, which will help keep them crisp, intensify their flavour, and improve their preservation by preventing the excess water diluting the vinegar.
            Prepare your jars and lids shortly before you need them. You can do this by putting them through a hot (60C) dishwasher cycle shortly before you need them (don’t try to dry them with a tea towel, let them air dry) or wash them in hot water then place in an oven preheated to 140C/120C Fan/Gas 1 for 15 minutes (switch off the oven and leave the jars inside until needed).
            Alternatively, place the jars in a large stock pot with a clean folded cloth or trivet placed on the base, cover the jars completely with cold water and bring to simmering point (90C) for 10 minutes, next remove the pan from the heat and leave the jars in the hot water until you need them. When your preserve is ready, carefully remove the jars from the pan, tipping out the water as you do so – a pair of bottling tongs makes this job easy, but otherwise, use ordinary tongs.
            """
        )
        saveRecipe(
            name: "Red Velvet Cake",
            prepTime: "10 minutes",
            cookingTime: "35 minutes",
            ingredients: [
                "280 g all-purpose flour (2 1/4 US cups)",
                "1 tsp baking soda",
                "1 tsp baking powder",
                "1 tsp salt",
                "13 g cocoa powder (2 Tbsp)",
                "350 g granulated sugar (1 3/4 US cups)",
                "100 g egg (2 eggs)",
                "172 g oil (3/4 US cup)",
                "120 g milk (1/2 US cup)",
                "30 g white vinegar (2 Tbsp)",
                "10 g vanilla extract (2 tsp)",
                "2 tsp gel paste red food coloring (adjust as needed)",
                "240 g hot milk (1 US cup)",
                "56 g unsalted butter (melted) (1/2 US stick)"
            ],
            prePrepInstructions: [
                "Preheat the oven to 330ºF (165ºC). Grease and line two 8-inch pans with parchment paper.",
                "In a large bowl, mix together all-purpose flour, baking soda, baking powder, salt, and cocoa powder."
            ],
            instructions: [
                "In a separate bowl, combine the granulated sugar, eggs, oil, milk, white vinegar, and vanilla extract.",
                "Add the wet ingredients to the dry ingredients and mix until well combined.",
                "Gradually add the red food coloring and mix until evenly distributed.",
                "Add the hot milk and melted butter, and mix until smooth.",
                "Divide the batter evenly between the two prepared cake pans and smooth the top.",
                "Bake at 330ºF (165ºC) for 35-40 minutes, or until a toothpick comes out clean with a few crumbs attached.",
                "Allow the cakes to cool completely before frosting."
            ],
            notes: """
            Adjust the amount of red food coloring to achieve your desired shade of red.
            Ensure the cake is fully cooled before frosting to prevent the frosting from melting.
            If you're making cupcakes, bake at 330ºF (165ºC) for 15-20 minutes.
            Store the cake in an airtight container at room temperature for up to 3 days.
            """
        )
        saveRecipe(
            name: "Red Velvet Cupcakes",
            prepTime: "15 minutes",
            cookingTime: "20 minutes",
            ingredients: [
                "250 grams plain flour",
                "2 tablespoons cocoa powder (sifted)",
                "2 teaspoons baking powder",
                "1/2 teaspoon bicarbonate of soda",
                "100 grams soft unsalted butter",
                "200 grams caster sugar",
                "1 heaped tablespoon christmas-red paste food colouring",
                "2 teaspoons vanilla extract",
                "2 large eggs",
                "175 millilitres buttermilk",
                "1 teaspoon cider vinegar",
                "500 grams icing sugar",
                "125 grams cream cheese",
                "125 grams soft unsalted butter",
                "1 teaspoon cider vinegar (or lemon juice)",
                "chocolate sprinkles for decoration",
                "red sugar for decoration"
            ],
            prePrepInstructions: [
                "Preheat the oven to 170°C/150°C Fan/gas mark 3/325°F, and line 2 muffin tins with paper cases.",
                "Combine the flour, cocoa, baking powder and bicarbonate of soda in a bowl."
            ],
            instructions: [
                "In another bowl, cream the butter and sugar, beating well, and when you have a soft, pale mixture beat in the food colouring and the vanilla.",
                "Add the dry ingredients into this vividly coloured mixture, alternating with the eggs, beating after each addition.",
                "Add the buttermilk and vinegar and divide this batter between the 24 cases.",
                "Bake in the oven for about 20 minutes or until the top bounces back gently and a toothpick comes out clean.",
                "Leave the cupcakes to cool on a wire rack before frosting.",
                "For the buttery cream-cheese frosting, put the icing sugar into a processor and whizz to remove lumps.",
                "Add the cream cheese and butter and process to mix. Pour in the cider vinegar (or lemon juice) and process again to make a smooth icing.",
                "Ice each cupcake, using a teaspoon or small spatula, and decorate with chocolate sprinkles and red sugar."
            ],
            notes: """
            The cupcakes can be baked 2 days ahead and stored, un-iced, layered with baking parchment in airtight containers.
            The frosting can be made 1 day ahead: cover with clingfilm and refrigerate; remove from fridge 1-2 hours before needed to allow it to come to room temperature then beat briefly before using.
            Best iced and eaten on the same day but iced cupcakes can be kept in the fridge in an airtight container for up to 1 day. Bring to room temperature before serving.
            Un-iced cupcakes can be frozen for up to 2 months. Defrost for 3-4 hours on a wire rack at room temperature.
            """
        )
        saveRecipe(
            name: "Roti (Chapati) Recipe – Puffs Every Time!",
            prepTime: "15 minutes",
            cookingTime: "5 minutes per Roti",
            ingredients: [
                "280 g (2 cups) atta flour, also called durum wheat flour, plus more for dusting",
                "3 g (1/4-1/2 tsp) sea salt, or to taste",
                "227 g (1 cup) room temperature water, more as needed",
                "Unsalted butter or ghee, optional – for brushing on top"
            ],
            prePrepInstructions: [
                "Combine the atta flour and salt in the bowl of a stand mixer fitted with a dough attachment.",
                "Turn on the mixer to medium-low (2) speed to start mixing the atta and salt.",
                "Over the course of 3 minutes, slowly pour in the water, letting it mix with the dough before adding more."
            ],
            instructions: [
                "Increase the heat to medium (4) and continue to knead on medium speed until a smooth and supple ball of dough forms (~3 min).",
                "Alternatively, knead by hand. Combine the atta flour and salt in a medium bowl and slowly pour in the water while using your hands to knead.",
                "Knead until the dough becomes a soft, supple ball. Cover and let the dough rest for 10-15 minutes.",
                "Form the dough into a round ball (peda) and flatten it.",
                "Roll out the dough into a circle about 8-9 inches in diameter.",
                "Heat a tawa or flat pan over medium-high heat. Once hot, place the roti on the tawa for 10-15 seconds.",
                "Flip the roti once the bottom starts to set, then cook until brown specks appear and air pockets form.",
                "Flip again to encourage puffing, either by pressing gently with a cloth (for electric stove) or cooking directly on the flame (for gas).",
                "Repeat for each roti, keeping the cooked ones warm in a cloth-lined hot pot."
            ],
            notes: """
            If the dough feels too tough, add a little more water and knead longer.
            To ensure your roti puffs, ensure that the pan is preheated well.
            For a softer roti, brush with butter or ghee after cooking.
            The dough can be stored in the refrigerator for up to 4 days, but should be allowed to come to room temperature before use.
            """
        )
        saveRecipe(
            name: "Salt and Pepper Chicken (Quick & Easy Chinese)",
            prepTime: "10 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "453 g (1 lb) skinless boneless chicken thighs",
                "4 cloves garlic, minced",
                "1 red chili, sliced",
                "1 tsp ginger, thinly sliced",
                "1 stalk green onion, chopped",
                "1/2 tsp white granulated sugar",
                "3/4 tbsp Shaoxing wine or Dry Sherry wine",
                "80 ml (1/3 cup) vegetable oil or any neutral oil"
            ],
            prePrepInstructions: [
                "Slice chicken thighs into bite-sized pieces, about 6-8 pieces per thigh. Transfer to a bowl.",
                "Season chicken with Shaoxing wine, salt, and black pepper, and mix well with hands.",
                "Add cornstarch to chicken and mix until each piece is coated in starch."
            ],
            instructions: [
                "Over medium heat, add vegetable oil into wok. Once the oil is hot (dip a wooden chopstick and look for bubbles), add chicken.",
                "Fry chicken for 3-4 minutes on each side, a total of 7-8 minutes, until golden and crispy. Remove and transfer to a plate.",
                "Discard most of the oil, leaving enough to moisten the pan. Lower heat to low setting.",
                "Add ginger, garlic, red chili, green onion, and sugar. Sauté for 45 seconds.",
                "Add fried chicken and Shaoxing wine, and mix again. Once mixed, remove off heat. Enjoy!"
            ],
            notes: """
            For air frying the chicken, refer to the Notes section for air fryer instructions.
            The chicken can be seasoned with more pepper to taste, depending on your spice preference.
            Serve with steamed rice or noodles for a complete meal.
            """
        )
        saveRecipe(
            name: "Salt & Pepper Tofu (椒鹽豆腐)",
            prepTime: "10 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "454 g firm tofu",
                "3 stalks green onion (white part only)",
                "56.7 g mini bell pepper (sweet peppers)",
                "2 cloves garlic",
                "4 cups boiling water",
                "1 tsp salt",
                "1/2 egg",
                "6 tbsp cornstarch",
                "454 g oil (for deep-frying)",
                "2 tbsp oil (for stir-frying)"
            ],
            prePrepInstructions: [
                "Cut to separate the green and white parts of the green onions. Dice the white part of the green onion.",
                "Halve the bell peppers, scoop out the core and seeds, and cut into strips. Rotate 90 degrees and dice.",
                "Smash, peel, and finely mince the garlic."
            ],
            instructions: [
                "Cut the tofu into cubes. The smaller the cubes, the more surface area you get for crust. The larger the cubes, the more volume you get for soft tofu.",
                "Boil hot water in a pot with salt. Add tofu cubes and cook for 3 minutes with the lid on, then lower heat to low and uncover. Cook for another 2 minutes.",
                "Carefully drain the tofu and let it cool.",
                "Press the tofu to remove excess moisture. Coat tofu in cornstarch and gently mix in a beaten egg. Coat tofu in more cornstarch.",
                "Heat oil in a large pot to 400°F (200°C). Deep-fry tofu in batches until golden brown, about 5 minutes. Remove and drain excess oil.",
                "Heat oil in a wok. Add dried chili and stir-fry for 8 seconds. Add minced garlic and fry for 15 seconds.",
                "Add diced bell peppers and green onion whites. Stir-fry for 20-25 seconds. Add fried tofu and stir-fry for 10 seconds.",
                "Sprinkle garlic salt and white pepper seasoning mix over tofu and stir well.",
                "Plate and serve. Enjoy!"
            ],
            notes: """
            The smaller the tofu cubes, the more crispy crust you will get.
            For a crispier texture, make sure the oil is hot enough before frying.
            This dish can be served with rice or noodles for a complete meal.
            """
        )
        saveRecipe(
            name: "Salt & Pepper Tofu 2 (椒鹽豆腐)",
            prepTime: "5 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "1 block regular firm tofu, not super soft or firm",
                "3 tbsp vegetable cooking oil",
                "1 scallion, finely chopped",
                "2 garlic cloves, minced",
                "3 fresh chilis, cut into small circles",
                "1/2 cup potato starch",
                "1/2 tbsp salt, or to taste",
                "1 tbsp Sichuan peppercorn"
            ],
            prePrepInstructions: [
                "Cut tofu into small cubes and coat with a thin layer of potato starch."
            ],
            instructions: [
                "Heat oil in a wok and fry tofu blocks slowly until crispy and slightly browned.",
                "Remove excess oil, leaving about 1 tablespoon of oil in the pan. Fry garlic, scallion, and chili peppers until aromatic, then turn off the heat.",
                "Return tofu to the pan and sprinkle with salt and pepper. Toss well to coat."
            ],
            notes: """
            Ensure the tofu is fried until golden and crispy for the best texture.
            Adjust the salt and pepper mix to taste, and feel free to add more chilis for extra heat.
            This dish can be served with steamed rice or vegetables.
            """
        )
        saveRecipe(
            name: "Salted Chocolate Chunk Brownie Cookies",
            prepTime: "15 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "40 g coconut oil or butter/vegetable oil",
                "100 g sugar",
                "1 egg",
                "1/2 tsp vanilla extract",
                "70 g all purpose flour",
                "1/2 tsp baking powder",
                "1/8 tsp salt",
                "20 g cacao powder",
                "1/4 tsp instant coffee (optional)",
                "1/3 milk chocolate bar, chopped",
                "Flakey sea salt (Decoration)"
            ],
            prePrepInstructions: [
                "Cream together sugar and oil. Add your coffee powder, egg, and vanilla extract and beat until light and fluffy."
            ],
            instructions: [
                "Mix together flour, baking powder, cacao powder, chocolate chunks, and salt.",
                "Fold in the flour mixture into the butter mixture until just combined.",
                "Refrigerate for at least 2 hours or freeze dough for about 45 minutes before using. Ideally, refrigerate overnight.",
                "Preheat oven to 350F. Scoop dough and form into balls. Place on a lined baking sheet and sprinkle with flakey sea salt. Repeat.",
                "Bake for about 10-15 minutes. For a crisper, chewier cookie, cook the cookies longer.",
                "Cool for about 15 minutes and serve."
            ],
            notes: """
            Refrigerating the dough helps the cookies hold their shape and results in a better texture.
            For a more intense chocolate flavor, use a higher percentage of cacao in the chocolate chunks.
            These cookies are best served warm right out of the oven, or can be reheated for a few seconds.
            """
        )
        saveRecipe(
            name: "Savory Indian Pancake",
            prepTime: "10 minutes",
            cookingTime: "3-4 minutes per side",
            ingredients: [
                "Oil/fat of choice (use enough to shallow fry)",
                "1/2 cup almond flour",
                "1/2 cup tapioca flour",
                "1 cup coconut milk (canned and full fat)",
                "1 tsp salt (adjust to taste)",
                "1/2 tsp Kashmiri chili powder",
                "1/4 tsp turmeric powder",
                "1/4 tsp freshly ground black pepper",
                "1/2 red onion, chopped",
                "1 handful cilantro leaves, chopped",
                "1 serrano pepper, minced (or adjust to taste)",
                "1/2 inch ginger, grated"
            ],
            prePrepInstructions: [
                "Add almond flour, tapioca flour, coconut milk, and spices to a bowl - mix together.",
                "Then, stir in the onion, cilantro, serrano pepper, and ginger."
            ],
            instructions: [
                "Heat a sauté pan on low-medium heat, add enough oil/fat to coat your pan, then pour 1/4 cup of batter onto the pan.",
                "Spread the mixture out on your pan and fry for about 3-4 minutes per side. Drizzle a bit more oil on top of the pancake before you flip it.",
                "Repeat until batter is done, adding oil as needed. Continue to fry until both sides are golden brown."
            ],
            notes: """
            I like my pancakes to have slightly crispy edges. If you want yours to be crispy, just add more oil and shallow fry.
            These do take a while to fry, so use a large pan to make a few at a time.
            If using chickpea flour, leave out the almond flour, tapioca flour, and coconut milk. Instead, use 1 cup chickpea flour and add water as needed to reach a pancake batter consistency.
            """
        )
        saveRecipe(
            name: "Seafood Laksa",
            prepTime: "10 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "267g Vermicelli Noodles (of 400g bag)",
                "Kettle of boiled water",
                "1 squid (frozen), sliced",
                "180g prawn, frozen, de-shelled",
                "160g sugar snap peas, chopped",
                "185g Yeo’s Laksa Paste",
                "Cornstarch",
                "Flour",
                "Salt",
                "Pepper",
                "Coriander"
            ],
            prePrepInstructions: [
                "Defrost squid and prawn.",
                "Boil vermicelli noodles in a saucepan.",
                "Drain water once cooked by pouring the contents of the pan into the colander. Set aside colander draining."
            ],
            instructions: [
                "Add the sugar snap peas and Laksa Paste into 500ml boiling water. Stir well and bring to the boil.",
                "In a bowl, stir defrosted squid rings and prawns in cornstarch, plain flour, salt, and pepper until evenly coated. Add teaspoon(s) of water as needed.",
                "In a frying pan coated in oil, pan fry the squid and prawns until just cooked. Prawns will become pink and squid rings will have just shrunk in size. Do not overcook.",
                "Add squid and prawns into the laksa soup and stir through. Simmer for 2 minutes then pour over noodles.",
                "Garnish with coriander, serve hot."
            ],
            notes: """
            Make sure to not overcook the squid and prawns, as they can become rubbery.
            Adjust the seasoning and amount of Laksa Paste based on your preferred spice level.
            Serve with extra coriander for garnish and add chili if you like a spicier version.
            """
        )
        saveRecipe(
            name: "Seafood Paella",
            prepTime: "10 minutes",
            cookingTime: "25 minutes",
            ingredients: [
                "Mixed seafood",
                "250g Paella/ Risotto rice",
                "2 medium onions, chopped",
                "3 tbsp Virgin olive oil (plus 3 tbsp more for seafood)",
                "2 minced garlic cloves (plus 2 more for seafood)",
                "1 1/4 tsp granulated garlic",
                "750ml Chicken stock",
                "1/2 tsp Saffron",
                "1/2 tsp Black pepper",
                "1/2 tsp Cayenne pepper",
                "Pinch of Paprika",
                "Salt (optional, as broth may be enough)",
                "1 sliced red pepper",
                "80g Frozen peas",
                "Lemon",
                "Diced chicken (optional)"
            ],
            prePrepInstructions: [
                "Defrost seafood mix."
            ],
            instructions: [
                "Heat 3 tbsp oil in a deep pan and brown the chopped onion and 2 minced garlic cloves.",
                "Add the rice and cook for 3-4 minutes, season with saffron and pepper, and add the stock.",
                "Bring to the boil and cook for approx. 15 minutes. If using chicken, add to the mix.",
                "Heat another 3 tbsp oil in a separate pan, add the seafood mix, sliced red pepper, peas, and 2 minced garlic cloves, and cook for 1 minute.",
                "Add the whole mix to the rice, stir well, and cook for a further 8 minutes.",
                "Season with salt, paprika powder, and cayenne pepper.",
                "Serve with lemon slices. Ensure food is piping hot and cooked throughout before serving. Do not reheat."
            ],
            notes: """
            Ensure the seafood is properly cooked and the rice is tender.
            Adjust salt according to the broth's seasoning.
            Serve immediately for the best flavor and texture.
            """
        )
        saveRecipe(
            name: "Sesame Balls (Jian Dui/煎堆)",
            prepTime: "30 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "230 g glutinous rice flour (divided)",
                "55 g white sugar",
                "160 g hot water (just boiled)",
                "1 tsp neutral cooking oil",
                "180 g red bean paste (or black sesame paste, or lotus paste)",
                "1 tbsp glutinous rice flour",
                "35 g sesame seeds (raw or lightly toasted)",
                "Neutral cooking oil (for deep frying)"
            ],
            prePrepInstructions: [
                "Put about two thirds of the glutinous rice flour into a mixing bowl. Add sugar and mix well.",
                "Pour hot water over and mix with chopsticks until a sticky mass forms.",
                "Add the remaining one third of glutinous rice flour in two batches. Mix with chopsticks, then combine with your hand to form a soft dough.",
                "Add oil and knead it into the dough. It will become smoother and completely sticky-free."
            ],
            instructions: [
                "Roll the dough into a rope then cut it into 12 equal parts. Shape each piece into a ball.",
                "Divide the red bean paste (or the filling of your choice) into 12 equal portions (about 1 tablespoon each). Roll them into balls.",
                "Shape a dough ball into a bowl shape. Place a piece of filling in the middle. Gently push the dough upwards to wrap around the filling tightly. Seal completely at the top, making sure there isn’t any leakage.",
                "In a small bowl, mix 1 tablespoon of glutinous rice flour with about ½ cup (120ml) of water. Put sesame seeds into another bowl.",
                "Briefly roll an assembled ball in the flour-water mixture to wet it all over. Then transfer it to the sesame bowl. Move the bowl in a circular motion so that the ball rolls and gets covered by the seeds.",
                "Gently press the ball all around to make sure all the seeds stick to the dough securely.",
                "Pour oil into a saucepan/wok for deep-frying. Heat it until it reaches 250°F/120°C.",
                "Gently slide in the balls, frying in batches if necessary. Use medium-low heat to fry. Move the balls around to prevent sticking.",
                "Once the balls start floating on the surface, gently press them down with a slotted spoon so they stay submerged.",
                "When the balls expand about 1½ times their size, turn the heat up to high (320°F/160°C) to cook them until the sesame seeds become golden.",
                "Transfer the balls to a plate lined with a paper towel to absorb excess oil. Let them sit for a few minutes before serving."
            ],
            notes: """
            You can use other fillings like black sesame paste or lotus paste instead of red bean paste.
            Make sure to fry the balls in batches to avoid overcrowding.
            Store leftovers in an airtight container in the fridge for up to 3 days or freeze for up to 3 months.
            To reheat, use a preheated oven or air fryer.
            """
        )
        saveRecipe(
            name: "Instant Pot Shalgam ki Sabzi (Indian Spiced Turnips)",
            prepTime: "10 minutes",
            cookingTime: "5 minutes",
            ingredients: [
                "2 tablespoons ghee",
                "1 teaspoon cumin seeds",
                "1 teaspoon black mustard seeds",
                "1 bay leaf",
                "1 onion, diced",
                "1 teaspoon garlic",
                "1 teaspoon ginger",
                "½ Serrano pepper or green chili, minced",
                "1 teaspoon coriander powder",
                "1 teaspoon dried mango powder (amchur)",
                "1 teaspoon garam masala",
                "1 teaspoon salt",
                "½ teaspoon paprika",
                "½ teaspoon turmeric",
                "¼ teaspoon black pepper",
                "¼ teaspoon cayenne",
                "½ cup canned tomato sauce",
                "1 tablespoon sugar (coconut sugar or jaggery)",
                "2 pounds turnips, chopped",
                "2 tablespoons water",
                "Cilantro, for garnish"
            ],
            prePrepInstructions: [
                "Press the sauté button on the Instant Pot and add the ghee.",
                "Once the ghee melts, add cumin seeds, mustard seeds, and bay leaf to the pot.",
                "When the cumin seeds brown and the mustard seeds begin to pop, add the diced onions and stir-fry for 5 minutes or until the onions soften."
            ],
            instructions: [
                "Add the garlic, ginger, Serrano pepper, and spices. Stir-fry for 30 seconds.",
                "Add the tomato sauce, sugar, chopped turnips, water, and mix well.",
                "Secure the lid, close the pressure valve, and cook for 5 minutes at high pressure.",
                "Quick release the remaining pressure and open the lid.",
                "Garnish with cilantro."
            ],
            notes: """
            Make sure to adjust the spice level based on your preference for heat.
            You can use jaggery or coconut sugar as a natural sweetener.
            Serve this dish with roti or rice for a complete meal.
            """
        )
        saveRecipe(
            name: "Shami Kebab (Instant Pot and Stovetop)",
            prepTime: "50 minutes",
            cookingTime: "30 minutes",
            ingredients: [
                "0.75 tbsp coriander seeds",
                "1.5 tsp whole black peppercorns",
                "1.5 inch piece cinnamon stick, broken into a couple pieces",
                "0.75 small black cardamom",
                "1.5 green cardamom pods, seeds removed and pod discarded",
                "6 whole cloves",
                "0.75 tsp toasted or regular cumin seeds",
                "510 g ground beef (preferably full-fat)",
                "146.25 g chana dal (yellow split peas), washed and soaked for at least 1 hour, then drained",
                "0.56 cup water for Instant Pot or 4 1/2 cups water for stovetop",
                "157.5-202.5 g medium to large onion, roughly chopped",
                "6-7.5 garlic cloves, leave whole – will be crushed later",
                "1.13 tbsp ginger, minced or crushed",
                "0.75 medium bay leaf",
                "0.38-0.75 tbsp red chili flakes",
                "0.75 tsp cumin seeds",
                "1.5-2.25 tsp kosher salt",
                "0.38 tsp chaat masala (optional)",
                "~60 g small onion, coarsely chopped",
                "0.75 Thai or Serrano green chili pepper, thinly sliced",
                "0.38-0.25 cup cilantro leaves",
                "1.5 tbsp mint leaves",
                "0.75 egg, whisked",
                "neutral oil, as needed",
                "0.75-1.5 eggs, whisked"
            ],
            prePrepInstructions: [
                "Add all of the ingredients listed under ‘Whole Spices’ to a spice grinder and grind until a powder is formed."
            ],
            instructions: [
                "For Instant Pot: Add all of the ingredients listed under ‘To Cook’ as well as the freshly ground spices to the Instant Pot. Mix well.",
                "Secure the lid, set the Pressure Release to Sealing, and cook on high pressure for 20 minutes.",
                "Let the pressure release naturally for 5 minutes, then use quick release for the remaining pressure.",
                "Select the Sauté – High setting and cook for 20 minutes, stirring often, until the mixture is dry and begins to stick to the bottom.",
                "For Stovetop: Add all ingredients to a pot with freshly ground spices and 4 1/2 cups of water. Bring to a boil, then simmer for 50 minutes to 1 hour until chana dal is completely cooked. Stir frequently during the last 15-20 minutes to evaporate the moisture.",
                "Combine the onion, green chili, cilantro, and mint in a food processor and pulse until finely chopped.",
                "Add the cooled beef and lentil mixture to the food processor and blend until smooth. Combine with the chopped onion mixture and mix well.",
                "Add the whisked egg and mix to combine.",
                "Shape the mixture into 2 3/4 inch patties, dip into the whisked egg, and fry in oil until golden brown on both sides.",
                "Place cooked patties on a paper towel to absorb excess oil."
            ],
            notes: """
            The mixture should be as dry as possible and start to look crumbly before moving to the next step.
            To freeze: Shape the kebabs and freeze for 1.5 to 2 hours before transferring to an airtight container or bag.
            Start with 2 tsp of kosher salt and adjust up to 3 tsp as needed.
            """
        )
        saveRecipe(
            name: "Shepherd's Pie",
            prepTime: "15 minutes",
            cookingTime: "1 hour",
            ingredients: [
                "1 tbsp sunflower oil",
                "1 large onion, chopped",
                "2-3 medium carrots, chopped",
                "500g pack lamb mince",
                "2 tbsp tomato purée",
                "large splash Worcestershire sauce",
                "Replace 1 tbsp with 2 teaspoons soy sauce, 1/4 teaspoon lemon juice, 1/4 teaspoon sugar and a dash of hot sauce",
                "500ml beef stock",
                "900g potato, cut into chunks",
                "85g butter",
                "3 tbsp milk"
            ],
            prePrepInstructions: [
                "Heat 1 tbsp sunflower oil in a medium saucepan, then soften 1 chopped onion and 2-3 chopped carrots for a few minutes.",
                "When soft, turn up the heat, crumble in 500g lamb mince and brown, tipping off any excess fat."
            ],
            instructions: [
                "Add 2 tbsp tomato purée and a large splash of Worcestershire sauce, then fry for a few minutes.",
                "Pour over 500ml beef stock, bring to a simmer, then cover and cook for 40 minutes, uncovering halfway.",
                "Meanwhile, heat the oven to 180C/fan 160C/gas 4, then make the mash. Boil the 900g potato, cut into chunks, in salted water for 10-15 minutes until tender. Drain, then mash with 85g butter and 3 tbsp milk.",
                "Put the mince into an ovenproof dish, top with the mash and ruffle with a fork. The pie can now be chilled and frozen for up to a month.",
                "Bake for 20-25 minutes until the top is starting to colour and the mince is bubbling through at the edges. (To bake from frozen, cook at 160C/fan 140C/gas 3 for 1 hr-1 hr 20 minutes until piping hot in the centre. Flash under the grill to brown, if you like.)",
                "Leave to stand for 5 minutes before serving."
            ],
            notes: """
                The pie can be chilled and frozen for up to a month.
                If baking from frozen, cook at 160C/fan 140C/gas 3 for 1 hr-1 hr 20 mins until piping hot.
                Flash under the grill to brown if desired.
            """
        )
        saveRecipe(
            name: "Simple Healthy Slaw",
            prepTime: "15 minutes",
            cookingTime: "5 minutes",
            ingredients: [
                "2 cups finely sliced purple cabbage",
                "2 cups finely sliced green cabbage",
                "2 cups shredded carrots",
                "¼ cup chopped fresh parsley",
                "Up to ¾ cup mixed seeds (e.g., pepitas, sunflower seeds, sesame seeds, poppy seeds)"
            ],
            prePrepInstructions: [
                "In a medium serving bowl, combine the prepared purple and green cabbage, carrots, and parsley. Set aside.",
                "Measure out your seeds into a small skillet. Toast over medium heat, stirring frequently, until the seeds are fragrant and the pepitas are starting to make little popping noises. Pour the toasted seeds into the mixing bowl and toss to combine."
            ],
            instructions: [
                "To make the dressing, in a small bowl, combine the olive oil with 2 tablespoons lemon juice. Add the garlic, cumin, and salt and whisk until thoroughly blended.",
                "Drizzle the dressing over the slaw and toss until all of the ingredients are lightly coated in dressing. Taste and add an additional tablespoon of lemon juice if the slaw needs a little more zip.",
                "Serve immediately or cover and refrigerate to marinate for up to several hours."
            ],
            notes: """
                Recipe adapted from The Adventurous Vegetarian Cookbook by Jane Hughes.
                This slaw keeps well for several days, covered, in the refrigerator.
            """
        )
        saveRecipe(
            name: "Sichuan Boiled Fish",
            prepTime: "20 minutes",
            cookingTime: "25 minutes",
            ingredients: [
                "1 (2 to 3 lbs / 1 to 1.3 kg) whole fish, or 2 white fish fillets (branzino, sea bass, snapper, or catfish)",
                "1 tablespoon Shaoxing wine (or dry sherry)",
                "1 teaspoon salt",
                "1 teaspoon white pepper",
                "1 egg white",
                "2 teaspoons cornstarch",

                "\\ Topping",
                "1/2 cup Chinese dried chili peppers and extra for garnish",
                "2 tablespoons Sichuan peppercorns, a combo of red and green if possible (*Footnote 1)",
                "1/4 cup + 2 tablespoons canola oil, separated (or other neutral oil)",

                "\\ Soup Base",
                "4 cloves garlic, smashed",
                "1 (2.5 cm) ginger, sliced",
                "3 green onions, cut into 1\" (2.5 cm) pieces",
                "5 Chinese dried chili peppers, sliced",
                "3 tablespoons Doubanjiang",
                "1 tablespoon Shaoxing wine (or dry sherry)",
                "1 tablespoon sugar",
                "1 teaspoon soy sauce",
                "1/2 teaspoon mushroom powder (or chicken powder) (optional)",
                "1/4 teaspoon white pepper",

                "\\ Vegetables",
                "2 cups bean sprouts",
                "1 cup chopped Chinese celery (or regular celery) (cut into 1\" / 2.5 cm sticks)",

                "\\ Slurry",
                "1/2 teaspoon cornstarch",
                "1 teaspoon water"
            ],
            prePrepInstructions: [
                "Check for residual fish scales. If any, remove them.",
                "Slice the fish along the spine and remove the fillets.",
                "Marinate the fish with the marinade ingredients and set aside for 15 minutes."
            ],
            instructions: [
                "Prepare the topping spices by heating oil in a pot. Add dried chilis and Sichuan peppercorns and cook until fragrant.",
                "Pulse the fried spices in a food processor to coarsely chop. Set aside.",
                "Prepare the soup base by sautéing garlic, ginger, green onions, and dried chilis.",
                "Add doubanjiang, stir for a few minutes, and then add Shaoxing wine, water, and seasonings.",
                "Bring the broth to a simmer, then strain and discard solid spices.",
                "Blanch vegetables in the broth for 1 minute, then remove and set aside.",
                "Simmer the broth again, add fish bones and head, cook for 2 minutes, then add fillets.",
                "Poach the fish fillets until cooked, then transfer to the serving bowl with vegetables.",
                "Stir in cornstarch slurry to thicken the broth, pour it over the fish, and top with the prepared spices.",
                "Heat oil in a small pot and drizzle it over the spices for a fragrant finish.",
                "Serve with steamed rice."
            ],
            notes: """
                If you don't have green Sichuan peppercorns, just use red ones, or use green Sichuan pepper oil.
                The leftover broth can be reused for cooking other dishes like meat, tofu, or vegetables.
            """
        )
        saveRecipe(
            name: "Braised Tofu Sichuan Style (家常豆腐)",
            prepTime: "3 minutes",
            cookingTime: "13 minutes",
            ingredients: [
                "400 g tofu (about 14oz)",
                "Neutral cooking oil (for shallow frying or air-frying)",
                "3 cloves garlic, minced",
                "1½ tablespoon Sichuan chili bean paste",
                "4 large dried shiitake mushrooms, rehydrated and sliced",
                "250 ml water (in which shiitake mushrooms are soaked)",
                "½ teaspoon dark soy sauce",
                "½ teaspoon sugar",
                "4 fresh chili peppers, cut into chunks",
                "1 teaspoon tapioca starch/corn starch, mixed with 3 teaspoon water",
                "1 stalk scallions, finely chopped"
            ],
            prePrepInstructions: [
                "Slice the tofu into triangle pieces, about 2 cm (¾ inch) thick. Pat dry the surface with kitchen paper."
            ],
            instructions: [
                "Option 1: Shallow-frying: In a flat-bottomed wok or a frying pan, heat oil enough to cover about half the thickness of the tofu. Test with the tip of a chopstick. If bubbles appear around it, the oil is hot enough. Gently slide in the tofu pieces one by one. Turn down the heat to medium and leave to fry. Flip over once the first side turns golden. When both sides are done, transfer to a plate lined with kitchen paper to absorb excess oil.",
                "Option 2: Air-frying: Preheat the air-fryer at 200°C/390°F for 3 minutes. Spray a thin layer of oil over both sides of the tofu pieces. Then put them in a single layer over the crisper tray inside the air fryer. Leave to fry for about 12 minutes until they become golden (check at 10 minutes).",
                "Pour out most of the oil leaving just a little in the wok/pan. Fry garlic and Sichuan chili bean paste over medium heat until fragrant.",
                "Add shiitake mushroom, the mushroom water, dark soy sauce, and sugar. Bring it to a boil.",
                "Put in the fried tofu and chili pepper. Stir around then cover with a lid. Leave to braise over low heat for 2 minutes. Add a little more water if needed.",
                "Pour in the starch water. Give everything a quick stir then garnish with scallions. Dish out and serve immediately."
            ],
            notes: """
                Firm tofu is preferable for this dish.
                Sichuan chili bean paste (aka spicy Doubanjiang) can be replaced by Pickled Chili Garlic Sauce or Spicy Black Bean Sauce. The taste of the final dish will be different but still nice.
                Fried tofu can be kept in the fridge for up to three days, or in the freezer for up to three months (defrost in the fridge before cooking).
            """
        )
        saveRecipe(
            name: "Smoked Turkey Legs",
            prepTime: "10 minutes",
            cookingTime: "1.5 hours",
            ingredients: [
                "2 x smoked turkey legs",
                "400g butter",
                "Jollof seasoning",
                "Garlic granules",
                "Paprika",
                "Italian seasoning"
            ],
            prePrepInstructions: [
                "Wash and chop turkey legs into large chunks (about satsuma size).",
                "Mix butter with seasoning."
            ],
            instructions: [
                "Preheat oven to gas mark 4.",
                "Cover turkey chunks with butter mix.",
                "Place rack in oven tray.",
                "Lay foil over rack, and place turkey pieces out on the foil.",
                "Cover with foil, sealing it tightly to ensure steam can't escape.",
                "Bake in the oven for 1.5 hours."
            ],
            notes: """
                Ensure the foil is tightly sealed to maintain steam inside for juicy turkey.
                You can adjust the amount of seasoning based on taste.
                For a crisper skin, uncover the turkey in the last 10 minutes of baking.
            """
        )
        saveRecipe(
            name: "Snow Skin Mooncake with Custard Filling (冰皮月饼)",
            prepTime: "30 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "\\ For the filling",
                "37.5 g wheat starch or cornstarch/tapioca starch",
                "41.25 g powdered sugar (icing sugar)",
                "75 g unsalted butter, melted",
                "84.38 g condensed milk",
                "3.75 large eggs",
                
                "\\ For the skin",
                "41.25 g glutinous rice flour",
                "41.25 g regular rice flour",
                "30 g wheat starch or cornstarch/tapioca starch",
                "41.25 g powdered sugar (icing sugar)",
                "225 g milk",
                "41.25 g condensed milk",
                "24.38 g neutral cooking oil",
                "Matcha powder (optional, for coloring)",
                
                "\\ For dusting",
                "30 g glutinous rice flour"
            ],
            prePrepInstructions: [
                "Mix wheat starch (or cornstarch/tapioca starch), powdered sugar, melted butter, and condensed milk until well combined. Add the eggs and lightly beat until fully incorporated.",
                "Pour the mixture into a saucepan. Cook over low heat, stirring constantly. Once it starts to solidify at the bottom of the pan, continue stirring until it becomes evenly solid. Transfer to a bowl and let cool, then refrigerate to firm up.",
                
                "In a separate bowl, combine glutinous rice flour, regular rice flour, wheat starch (or cornstarch/tapioca starch), and powdered sugar. Pour in milk, mix until smooth, and then add condensed milk and oil. Stir to combine.",
                "Cook the mixture either in a microwave for 4 minutes or steam for 20 minutes over medium-high heat. Afterward, scrape the solidified mixture onto another plate to cool faster."
            ],
            instructions: [
                "Once the mixture has cooled enough to handle, knead it until smooth (use food-safe gloves to prevent sticking). If coloring the skin, knead in matcha powder or other colorings as desired.",
                "Toast glutinous rice flour in a pan over low heat for about 4 minutes and set aside to cool.",
                "Take the cooled filling and briefly knead it to make it smoother. Divide into 8 equal pieces and roll into balls.",
                "Shape the skin into 8 equal balls. Flatten one piece into a round wrapper. Place a filling ball in the middle and wrap the skin around the filling tightly, sealing at the top.",
                "Roll the assembled mooncakes in the toasted glutinous rice flour, removing excess flour. Place each ball into a mooncake mold, press the mold to form the mooncake, and release it carefully.",
                "Store the mooncakes in airtight containers in the fridge for up to 72 hours, or freeze for up to 1 month. To reheat, lightly wet them and microwave or steam until softened."
            ],
            notes: """
                Use cornstarch or tapioca starch for a gluten-free version of the recipe.
                If the skin dough seems too oily, knead it back into the mixture.
                You can double the recipe but microwave the skin mixture in two batches or increase steaming time to 30 minutes.
                Dust the mooncake mold before shaping if your mooncakes don’t slide out easily.
            """
        )
        saveRecipe(
            name: "Snow Skin Mooncake with Custard Filling 2 (冰皮月饼)",
            prepTime: "2 hours",
            cookingTime: "30 minutes",
            ingredients: [
                "\\ For the custard",
                "24 grams (6 tablespoons) cornstarch",
                "3 grams (2 teaspoons) all-purpose flour",
                "67.2 grams (1/2 cup) granulated sugar",
                "3 large egg yolks",
                "288 grams (2 cups) whole milk",
                "18 grams (2 tablespoons) butter",
                "0.3 teaspoon vanilla extract",

                "\\ For the wrapper",
                "72 grams (1 cup) glutinous rice flour",
                "72 grams (1 cup) rice flour",
                "72 grams (1 cup) cornstarch, and extra for coating the mooncakes",
                "60 grams (3/4 cup) confectioners sugar",
                "210 grams (1 1/2 cup) whole milk",
                "33 grams (1/3 cup) vegetable oil",
                "0.3 teaspoon vanilla extract",

                "\\ Equipment",
                "A 50-gram mooncake mold"
            ],
            prePrepInstructions: [
                "Mix cornstarch, all-purpose flour, and half of the sugar together in a small bowl.",
                "Place egg yolks in a large bowl and stir a few times to mix.",
                "In a saucepan, add the remaining half of the sugar, milk, and heat over medium. Stir occasionally to dissolve the sugar completely. Cook until the milk reaches about 120°F/49°C.",
                "Once the milk is warm, add the dry ingredients to the egg yolks and whisk until smooth.",
                "Gradually add the warm milk to the egg yolk mixture, whisking constantly. Return the mixture to the saucepan and cook over medium heat until thickened. Let it boil for one minute. Add butter and vanilla extract, stir to combine.",
                "Pour the custard through a fine mesh strainer into a plate lined with plastic wrap. Press the wrap against the custard to prevent skin formation. Chill in the fridge for 2 hours."
            ],
            instructions: [
                "To prepare the dough, sift glutinous rice flour, rice flour, and cornstarch into a large bowl. Sift confectioners sugar into the mixture.",
                "Add the milk, oil, and vanilla extract. Stir to combine. Gradually add 2 to 3 tablespoons of the mixture at a time into the flour, stirring until completely incorporated.",
                "Pour the mixture into a large bowl and strain it through a fine mesh strainer.",
                "Steam the mixture for 25 to 30 minutes, stirring occasionally. Once done, let the dough cool slightly and then knead it until smooth.",
                "Divide the dough into 25-gram portions and form them into balls.",
                "Once the custard is chilled, mix it to soften and form it into 25-gram portions.",
                "Flatten a portion of the dough into a thin wrapper, place the custard ball inside, and seal the wrapper around the custard. Roll the mooncake in cornstarch.",
                "Mold the mooncake using a mooncake mold and repeat for the rest."
            ],
            notes: """
                You can use Gao Fen (cooked glutinous rice flour) for dusting if available. If not, cornstarch works fine.
                If you don't have a mooncake mold, you can shape the mooncakes by hand.
                Store mooncakes in an airtight container in the fridge for 3 to 4 days. To soften, microwave or steam them before serving.
            """
        )
        saveRecipe(
            name: "Sourdough Discard Steamed Cake (aka Huat Kueh or Fa Gao)",
            prepTime: "20 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "\\ Wet ingredients",
                "115 g cane sugar",
                "1 large egg",
                "100 g milk or coconut milk",
                "100 g sourdough discard",
                "100 g melted coconut oil or neutral oil",

                "\\ Dry ingredients",
                "200 g all purpose flour",
                "1/2 tsp salt",
                "2 tsp baking powder",

                "\\ Inclusions (optional)",
                "pandan or ube extract, cacao powder, black sesame powder, etc."
            ],
            prePrepInstructions: [
                "Cream together sugar and eggs until pale and creamy.",
                "Combine in sourdough discard followed by milk."
            ],
            instructions: [
                "Sift together all the dry ingredients.",
                "Mix a third of the dry ingredients into the wet mixture followed by a third of the melted coconut oil. Alternate until everything is mixed and a thick batter forms.",
                "Customize the flavor of the cakes by adding extracts (like pandan or ube), powders (like black sesame or cacao powder), or other inclusions (like chocolate chips or dried fruit).",
                "Fill silicone baking cups 3/4 full with the cake batter. Optionally, pre-line the silicone cups with paper baking cups if steaming in batches.",
                "Prepare a wok or large pot with water and place it on high heat. Once the water starts to simmer, place the prepared steam basket on top.",
                "Let the cakes steam on high for 15 minutes. Turn off the heat and let them rest for 5 minutes.",
                "Uncover the steam baskets and, if using paper baking cups, remove the cakes from the silicone molds. Let them cool completely."
            ],
            notes: """
                Store the cakes in an airtight container or wrap in saran wrap at room temperature for up to 4 days.
                Recipe Adapted from What To Cook Today.
            """
        )
        saveRecipe(
            name: "Soy Sauce Chow Mein (15-min Easy Cantonese)",
            prepTime: "5 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "\\ Main ingredients",
                "453 g Chow Mein Noodles",
                "211 g mung bean sprouts (washed and strained thoroughly)",
                "1 medium size yellow onion (sliced thinly)",
                "3 green onions (sliced into 1-inch-long pieces)",

                "\\ Sauces & oils",
                "2 tbsp regular soy sauce",
                "2 tbsp dark soy sauce",
                "2 tbsp sesame oil",
                "2 tbsp vegetable oil or any neutral oil",

                "\\ Garnish",
                "2 tsp sesame seeds"
            ],
            prePrepInstructions: [
                "Slice green and yellow onion into thin pieces as specified."
            ],
            instructions: [
                "In a large wok or steamer, fill with enough water. Place a wired rack into the steamer and your plate of chow mein noodles on top of the rack. Cover and steam noodles over high heat for 5 minutes.",
                "Remove the wired rack and clean out the wok of its liquids. Set it over medium-high heat. Wait for it to smoke (for non-stick pans, set to medium heat and skip the smoking part).",
                "Add oil and allow it to smoke. Add yellow onions and cook until translucent. Lower heat to medium.",
                "Add green onions and stir for 5 seconds.",
                "Add steamed noodles, regular soy sauce, dark soy sauce, and sesame oil. Mix well.",
                "Toss in mung bean sprouts and mix until well combined with noodles.",
                "Sprinkle sesame seeds over the top and serve."
            ],
            notes: """
                Serve and enjoy the dish immediately. This is a quick and simple Cantonese-style chow mein.
            """
        )
        saveRecipe(
            name: "Spiced Carrot & Lentil Soup",
            prepTime: "10 minutes",
            cookingTime: "45 minutes",
            ingredients: [
                "\\ Vegetables & legumes",
                "1 tbsp olive oil",
                "1 large onion, chopped",
                "2 garlic cloves, chopped",
                "1 thumb-sized piece of fresh ginger, grated",
                "6 medium carrots, chopped",
                "1 tbsp ground cumin",
                "1 tbsp ground coriander",
                "1 tsp ground turmeric",
                "150g red lentils",
                "1.2 liters vegetable stock",

                "\\ Garnish & seasoning",
                "1 tbsp fresh coriander, chopped (optional)",
                "1 tbsp natural yogurt (optional)"
            ],
            prePrepInstructions: [
                "Peel and chop the onion, garlic, ginger, and carrots.",
                "Rinse the lentils under cold water."
            ],
            instructions: [
                "Heat the oil in a large pan and fry the onion for 5 minutes until soft.",
                "Add the garlic, ginger, cumin, coriander, and turmeric, and cook for 1 minute, stirring constantly.",
                "Add the chopped carrots and lentils to the pan and stir everything together.",
                "Pour in the vegetable stock and bring the soup to a boil.",
                "Reduce the heat and simmer for 40 minutes until the carrots are tender and the lentils have cooked through.",
                "Use a hand blender to blend the soup to a smooth consistency (or leave it chunky, depending on preference).",
                "Serve the soup hot, garnished with fresh coriander and a swirl of yogurt, if desired."
            ],
            notes: """
                For a creamier texture, you can add a splash of cream or coconut milk at the end of cooking.
                This soup can be frozen for up to 3 months; just cool completely and store in an airtight container.
            """
        )
        saveRecipe(
            name: "Spicy Gochujang Tofu (Korean Inspired)",
            prepTime: "20 minutes",
            cookingTime: "35 minutes",
            ingredients: [
                "\\ Crispy Tofu",
                "1 block firm or extra-firm tofu",
                "1 tablespoon olive oil or other neutral oil",
                "2 tablespoons cornstarch or potato starch",
                "pinch salt and pepper",

                "\\ Gochujang Sauce",
                "3 tablespoons gochujang",
                "2 tablespoons ketchup",
                "1 tablespoon mirin (or apple cider vinegar)",
                "2 tablespoons soy sauce",
                "1 tablespoon brown sugar",
                "4 cloves garlic, minced",
                "1 tablespoon rice vinegar",
                "1/2 tablespoon toasted sesame oil",
                "2 tablespoons water (or as needed)",

                "\\ Optional Garnishes",
                "Sliced scallions",
                "Toasted sesame seeds"
            ],
            prePrepInstructions: [
                "Drain the tofu and press it for at least 15 minutes to remove excess moisture.",
                "Cut tofu into cubes or tear into bite-sized pieces."
            ],
            instructions: [
                "Drizzle oil over the tofu pieces and sprinkle with salt and pepper. Gently toss to coat.",
                "Sprinkle cornstarch (or potato starch) over the tofu and toss again to coat.",
                "For oven cooking: Preheat oven to 425°F. Arrange tofu pieces on a baking sheet and bake for 15 minutes. Toss the tofu and bake for another 15-20 minutes, until crispy and golden brown.",
                "For air fryer cooking: Preheat air fryer to 400°F. Air fry tofu for 18-20 minutes, shaking the basket halfway through.",
                "For the Gochujang Sauce: In a nonstick skillet, combine all sauce ingredients and whisk together. Heat over medium-high heat until it starts to bubble, then reduce heat to low. Simmer for 3-5 minutes until the sugar dissolves and the sauce thickens. Add water if needed to adjust consistency.",
                "Once tofu is cooked, toss it in the gochujang sauce to coat. Alternatively, serve the sauce on the side.",
                "Serve the tofu with steamed white rice, garnished with sliced scallions and toasted sesame seeds."
            ],
            notes: """
                Mirin is a sweet Japanese cooking wine. If unavailable, increase the rice vinegar to 2 tablespoons.
                Gochujang is a fermented Korean red pepper paste. It is essential for this dish; check your local Asian grocer or order online.
                Leftovers: Keep for up to 5 days in the fridge. Reheat on the stove over medium heat. To re-crisp tofu, store it separately from the sauce and re-crisp in the oven or air fryer at 350°F for 10 minutes.
                Other Uses for the Gochujang Sauce: Great for noodles or homemade bibimbap.
            """
        )
        saveRecipe(
            name: "Spicy Guacamole",
            prepTime: "15 minutes",
            cookingTime: "0 minutes",
            ingredients: [
                "\\ Main Ingredients",
                "3 avocados",
                "1 medium tomato, seeded and diced",
                "1/2 white/red onion, finely chopped",
                "8 g cilantro (1/3 bunch)",
                "8 green finger chillies (or 2 serrano peppers for milder guacamole, or jalapenos)",
                "2 cloves garlic, pressed",
                "3 tbsp lime juice",
                "1/2 tsp sea salt (or to taste)",
                "1/4 tsp ground black pepper (or to taste)",
                "1/2 tsp ground cumin"
            ],
            prePrepInstructions: [
                "Cut the avocados in half, remove the seeds and scrape them into a flat-bottomed bowl.",
                "Smash the avocados with a potato masher or a fork."
            ],
            instructions: [
                "Chop the onion and add it to the bowl.",
                "Remove the seeds from the chillies (or serrano/jalapenos) and finely dice them.",
                "Cut the tomato in half, remove the seeds, dice, and add them to the bowl.",
                "Press the garlic and chop the cilantro, then add both to the bowl.",
                "Add 1/2 tsp dry cumin powder, 1/4 tsp ground black pepper, 1/2 tsp salt, and 3 tbsp lime juice.",
                "Serve immediately."
            ],
            notes: """
                If you want to make this ahead, place plastic wrap directly onto the guacamole and push out any air before refrigerating.
            """
        )
        saveRecipe(
            name: "Mexican Chicken Soup (Instant Pot Spicy Chicken Soup)",
            prepTime: "5 minutes",
            cookingTime: "30 minutes",
            ingredients: [
                "\\ Main Ingredients",
                "450g (1 pound) chicken breast",
                "2 celery stalks, chopped",
                "1 onion, chopped",
                "1 jalapeno, diced",
                "2 tablespoons olive oil",
                "4 garlic cloves, crushed",
                "400g (14 oz) can diced tomatoes with chiles",
                "6 cups chicken broth",
                "1 lime, juiced",
                "1 teaspoon cumin",
                "½ bunch cilantro, chopped",
                "2 tablespoons dried parsley",
                "1 avocado, sliced",
                "1 lime, sliced for garnish",
                "1 can of corn",
                "1 can of kidney beans"
            ],
            prePrepInstructions: [
                "Turn on Instant Pot saute setting.",
                "Sauté 2 chopped celery stalks, 1 chopped onion, 1 diced jalapeño, and 4 crushed garlic cloves in 2 tablespoons olive oil until tender."
            ],
            instructions: [
                "Add 1 pound chicken breasts, 14 oz canned tomatoes, 6 cups chicken broth, and 1 teaspoon cumin.",
                "Cover and lock the lid. Cook on manual High pressure for 10 minutes. Natural release for 15 minutes and then quick release the remaining pressure.",
                "Remove the chicken breasts from the soup and shred the chicken.",
                "Return the shredded chicken to the soup. Add juice from 1 lime and stir.",
                "Add fresh chopped cilantro.",
                "Add a can of corn and kidney beans.",
                "Serve the soup with a slice of avocado."
            ],
            notes: """
                This soup can be garnished with a slice of lime for extra flavor.
            """
        )
        saveRecipe(
            name: "Spicy Mexican Chicken Soup 2",
            prepTime: "5 minutes",
            cookingTime: "30 minutes",
            ingredients: [
                "\\ Main Ingredients",
                "1 tbsp extra virgin olive oil or avocado oil",
                "1 onion, finely diced",
                "3 garlic cloves, minced",
                "1 jalapeño pepper or serrano pepper, minced",
                "450 g chicken breast",
                "1 red bell pepper, diced",
                "1 15-ounce can black beans",
                "1 15-ounce can corn",
                "480 ml chicken broth",
                "480 ml tomato passata",
                "2 tsp chili powder",
                "1 tsp paprika powder",
                "½ tsp ground cumin",
                "½ tsp curry powder",
                "Salt and pepper, to taste",
                "\\ Toppings (optional)",
                "Fresh cilantro",
                "Avocado",
                "Shredded cheese",
                "Tortilla chips",
                "Lime wedges"
            ],
            prePrepInstructions: [
                "Preheat the oil in a pot over medium heat.",
                "Sauté the onion, garlic, and jalapeño pepper until the onion is translucent."
            ],
            instructions: [
                "Add the remaining ingredients to the pot. Bring the soup to a boil, then reduce the heat, cover the pot, and let the soup simmer for 25 minutes.",
                "Take the chicken breast out of the pot and shred it using two forks. Add the shredded chicken back to the pot.",
                "Add more spices if needed. Serve with your favorite toppings and lime wedges. Enjoy!"
            ],
            notes: """
                To make it less spicy: Skip the jalapeño pepper and add chili powder to taste. Serve with lime wedges to help reduce heat.
                To make it spicier: Use serrano pepper instead of jalapeño, or add cayenne pepper and/or more chili powder after cooking.
            """
        )
        saveRecipe(
            name: "Scallion Pancakes (Cong You Bing, 葱油饼)",
            prepTime: "12 minutes",
            cookingTime: "6 minutes",
            ingredients: [
                "\\ For the dough",
                "250 g all-purpose flour (plain flour) - about 2 cups (see note 1 for substitutes)",
                "160 g hot water - about ⅔ cup",
                "Cooking oil - for coating",
                
                "\\ For the filling",
                "2 tablespoon melted lard - or coconut oil, see note 2 for other substitutes",
                "2 tablespoon all-purpose flour (plain flour)",
                "¼ teaspoon ground Sichuan pepper - or Chinese five-spice powder",
                "¼ teaspoon salt",
                "40 g finely chopped scallions (green onion/spring onion) - about ½ cup",
                
                "\\ For frying",
                "1 tablespoon neutral cooking oil",
                
                "\\ For serving (optional)",
                "Homemade chilli oil",
                "Black rice vinegar",
                "Light soy sauce"
            ],
            prePrepInstructions: [
                "Put flour into a heatproof bowl. Pour in hot water. Stir with chopsticks until no more loose flour or water can be seen. Use your hands to combine the mixture into a rough-looking dough (see note 3).",
                "Tightly cover the dough with cling film and leave to rest for 15 mins."
            ],
            instructions: [
                "While waiting, add melted lard (or other oil), flour, Sichuan pepper (or five-spice) and salt to a small bowl. Mix until it becomes a smooth paste.",
                "Uncover the dough then knead until it becomes very smooth. Rub a thin layer of oil around the dough, as well as the work surface.",
                "With a rolling pin, flatten the dough into a thin, rectangular piece. For your reference, mine measures about 43cm(17\") by 33cm (13\").",
                "Brush the filling mixture over the dough, then sprinkle finely chopped scallions on top.",
                "From the shorter side of the dough piece, roll the dough into a rope (don’t make it too tight).",
                "Cut the rope into 4 cylinders. Stand a piece on one end. Press down with your hand, then flatten it with the rolling pin into a pancake that measures around 13cm/5\" in diameter. Alternatively, cut the rope into 3 parts and roll each into a thinner pancake which measures about 23cm/9\".",
                "In a frying pan/skillet, heat oil over high heat until hot. Drop a piece of scallions in to test. If it sizzles, the oil is hot enough.",
                "Turn the heat down to medium and put in the pancakes (the top side facing down). You may cook 4 thick pancakes all at once in a large pan (28cm/11\"), or 1 thin pancake at a time.",
                "Cover with a lid and leave to cook for about 2 minutes until the side facing down becomes golden brown (adjust the cooking time if necessary). Flip over to cook the other side (keep the lid on). Remove them from the pan once the second side turns golden too.",
                "For the best result, rest the pancakes on a wire rack for a minute or two before serving (condensation will form if placed on a plate straightaway). Also, the remaining heat will cook the inside further during the resting time.",
                "Serve warm with homemade chilli oil, black rice vinegar, and light soy sauce (optional)."
            ],
            notes: """
                1. You may also use bread flour. The flour to water ratio may vary slightly depending on the brand and type of your flour. Adjust accordingly. The dough should be on the soft side but not sticky.
                2. Possible substitutes for lard and coconut oil include rendered chicken/duck fat, sesame oil, olive oil, or other regular cooking oils (peanut, canola, sunflower, vegetable, etc.). Since oil has a runny consistency, they tend to leak while you shape the pancakes. Don’t panic! Messy ones still cook well and taste nice.
                3. This dough is very easy to make by hand. However, please feel free to use a stand mixer, especially when making a big batch. Mix flour and hot water on low speed for about 8 minutes.
            """
        )
        saveRecipe(
            name: "Strawberry Cake",
            prepTime: "30 minutes",
            cookingTime: "30 minutes",
            ingredients: [
                "\\ For the cake",
                "140g Egg",
                "100g Sugar",
                "10g Honey (Corn syrup)",
                "2g Vanilla extract",
                "90g Cake flour",
                "25g Melted unsalted butter",
                "40g Milk",
                
                "\\ For the whipped strawberry cream",
                "300g Whipping cream",
                "100g Strawberry jam",
                "Red food coloring (a little)",
                
                "\\ For the decorative whipped cream",
                "60g Whipping cream",
                "6g Sugar",
                
                "\\ For the strawberry filling",
                "Washed, cut, and patted down strawberry pieces (to remove moisture)",
                
                "\\ Optional",
                "Candied mint leaves"
            ],
            prePrepInstructions: [
                "Preheat oven to 180°C (Gas mark 4). Line 6\" cake tin(s).",
                "Place a bowl of eggs on top of a pot of boiled water. Add sugar and honey. When the sugar is melted and the egg is softened, lower the bowl from the pan.",
                "Add vanilla extract. Whip with a hand mixer. Start at high speed (10-12) for 2 minutes 30 seconds. Lower to medium speed (7-8) and whip for another 2 minutes 30 seconds. Finally, clean up the air bubbles at low speed for 1 minute 30 seconds.",
                "Lift the dough and draw a ribbon to check."
            ],
            instructions: [
                "Sift in the flour. Mix the dough by lifting it from the bottom up to avoid overmixing.",
                "Once the dough is mixed, add the melted unsalted butter and milk (pre-heated over hot water) to the bowl. Mix evenly.",
                "Pour the dough into an 18cm mold lined with butter. Tap the tin on the counter to remove bubbles. Bake in a preheated oven at 180°C for 20 minutes (if making 3-4 layers, bake for 15-20 minutes).",
                "Remove the cake and cool on a rack. Once cooled, cut the top side, slice it into 3 layers, and trim the edges to a 15cm mousse size.",
                "Apply a little cream to the turning plate and place the first uncut layer on top. Spread strawberry jam and whipped cream evenly using a spatula.",
                "Whip the cream while adding the strawberry jam gradually. Whip until soft peaks form and apply evenly on the first layer of cake. Press the strawberry pieces lightly into the cream.",
                "Apply more whipped cream and repeat the process for the second and third layers, smoothing the cream on top and sides of the cake.",
                "If there is not enough cream to cover the sides, add more cream to ensure the sides are fully covered.",
                "Smooth the top edge and apply the final layer of cream evenly. Chill the cake in the fridge for a while to set the cream.",
                "Before decorating, add fresh whipped cream to the top, spreading it gently with a spatula so that it slightly flows over the sides.",
                "Once the decoration is complete, refrigerate until ready to serve. Optionally, add candied mint leaves or fresh strawberries for garnish."
            ],
            notes: """
                Ensure the strawberries are well-drained to avoid extra moisture seeping into the cake. You can also use candied mint leaves as an optional garnish.
            """
        )
        saveRecipe(
            name: "Strawberry Mojito Mocktail",
            prepTime: "10 minutes",
            cookingTime: "0 minutes",
            ingredients: [
                "8-10 strawberries, top removed",
                "10 mint leaves",
                "2 cups lemonade",
                "Ice cubes"
            ],
            prePrepInstructions: [],
            instructions: [
                "Place strawberries, lemonade, mint leaves, and ice cubes in a high-speed blender.",
                "Blend until smooth.",
                "Divide between 2 ice-filled glasses and garnish with mint or extra strawberries."
            ],
            notes: "Enjoy!"
        )
        saveRecipe(
            name: "Sticky Asian Wings",
            prepTime: "10 minutes",
            cookingTime: "20 minutes",
            ingredients: [
                "1.1 kg chicken wings",
                "1 tsp salt",
                "1 tsp ground black pepper",
                "Cooking spray",
                "2.5 cloves garlic",
                "1.25 inch ginger, peeled and minced",
                "6.25 tbsp honey",
                "3.75 tbsp soy sauce",
                "1.25 tbsp garlic chilli sauce",
                "1.25 tbsp apple cider vinegar or 1 tsp chopped roasted peanut",
                "2.5 tsp chopped coriander leaves"
            ],
            prePrepInstructions: [
                "Clean and rinse the chicken wings, pat with paper towels. Season with salt and ground black pepper."
            ],
            instructions: [
                "Arrange chicken on a baking sheet lined with aluminum foil and coat with a thin layer of cooking spray.",
                "Broil the chicken for 12-15 minutes on one side until browned and slightly charred, then turn over and broil the other side for 3-5 minutes.",
                "In a small saucepan, combine the garlic, ginger, honey, soy sauce, garlic chili sauce, and vinegar together. Simmer on low heat until thickened and slightly sticky.",
                "Toss the chicken wings and coat well with the sauce. Transfer to a serving platter and top with chopped peanuts and cilantro.",
                "Serve immediately."
            ],
            notes: "Instead of broiling, you may grill the chicken wings on an outdoor grill."
        )
        saveRecipe(
            name: "Stuffed Flatbread (Crispy Guo Kui/锅盔)",
            prepTime: "25 minutes",
            cookingTime: "8 minutes",
            ingredients: [
                "500 g all-purpose flour (plain flour)",
                "300 g water",
                "Cooking oil (for coating the dough)",
                "3 tablespoon all-purpose flour (for flour & oil paste)",
                "1 pinch salt (for flour & oil paste)",
                "3 tablespoon cooking oil (for flour & oil paste)",
                "280 g ground beef (or chicken)",
                "4 tablespoon water (for meat)",
                "1 tablespoon Shaoxing rice wine (for meat)",
                "1 teaspoon salt (for meat)",
                "¼ teaspoon white pepper (for meat)",
                "1 tablespoon ground Sichuan pepper (or other spices)",
                "6 stalks scallions (finely chopped)",
                "Cooking oil (for pan-frying)"
            ],
            prePrepInstructions: [
                "Put flour into a mixing bowl. Add water in batches while mixing with chopsticks. Combine and knead until a soft dough forms. Cover and rest for 10 minutes. Knead again until smooth.",
                "Rub a little oil over the dough, flatten it, and cut into 10 equal pieces. Cover with plastic wrap and rest for 30 minutes."
            ],
            instructions: [
                "Make the flour & oil paste: Mix flour and salt in a small bowl. Heat oil in a pan until it smokes, then pour over the flour and stir to remove lumps.",
                "Prepare the meat: Mix ground beef, water, Shaoxing rice wine, salt, and white pepper. Swirl with chopsticks until the meat becomes sticky. Divide into 10 portions.",
                "Assemble the flatbread: Flatten each dough piece into a tennis racket shape. Brush with flour & oil paste and sprinkle with ground Sichuan pepper. Place meat portion in the center, top with chopped scallions.",
                "Wrap the meat with the dough, then roll it into a cylinder. Stand it on one end and press down to form a disc. Repeat for the other flatbreads.",
                "Pan-fry the flatbread: Heat oil in a large skillet over high heat. Once hot, add the flatbread and fry on medium-low heat until golden on both sides. Transfer to a plate lined with kitchen paper to absorb excess oil."
            ],
            notes: "Adjust the flour-water ratio depending on your flour brand. If the dough is sticky, rub a little oil over the surface instead of using flour. This recipe can also be made with a stand mixer using a dough hook."
        )
        saveRecipe(
            name: "Soft & Chewy Sugar Cookies",
            prepTime: "20 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "50 g unsalted butter (room temperature)",
                "60 g cane sugar",
                "12 g egg (about 1/2 egg)",
                "1/2 tsp vanilla extract",
                "1 tbsp sour cream or Greek yogurt",
                "90 g all purpose flour",
                "1/4 tsp baking soda",
                "pinch salt",
                "coarse sugar (for rolling cookies)"
            ],
            prePrepInstructions: [
                "Preheat the oven to 350ºF.",
                "Cream together butter and sugar, then add egg and beat until light and fluffy. Mix in sour cream and vanilla extract."
            ],
            instructions: [
                "Mix together flour, baking soda, and salt in a separate bowl. Fold into the butter mixture.",
                "Scoop out the dough with a spoon, shape into balls (about 6), and roll in coarse sugar.",
                "Place on a parchment lined baking sheet with about a 4\" gap between each cookie ball.",
                "Bake for about 10 minutes, or until the edges begin to look golden. Let cool before transferring to a cooling rack. Enjoy!"
            ],
            notes: "For fluffier, softer cookies, use sour cream or Greek yogurt. The baking soda reacts more with the sour cream, eliminating the need for baking powder."
        )
        saveRecipe(
            name: "Spring Rolls (Vietnamese Gỏi Cuốn)",
            prepTime: "13 minutes",
            cookingTime: "7 minutes",
            ingredients: [
                "230 grams jumbo shrimp",
                "9 sheets rice paper (8.5 inches wide in diameter)",
                "140 grams rice vermicelli (uncooked)",
                "9 pieces green leaf lettuce (washed, each leaf trimmed to about 5 inches long)",
                "1/2 inch ginger (peeled)",
                "1 shallot (peeled and halved)",
                "27 mint leaves"
            ],
            prePrepInstructions: [
                "In a small saucepan, heat vegetable oil over low heat and sauté garlic for 15-20 seconds until fragrant. Mix in hoisin sauce, peanut butter, and water. Bring to a boil over medium-high heat.",
                "Once the sauce boils, remove from heat and transfer it to a small bowl to cool. Sprinkle crushed peanuts on top. Place peanut sauce in the fridge to chill."
            ],
            instructions: [
                "In a medium pot, bring enough hot water to a boil. Add halved shallot and sliced ginger. Add shrimp (shell on for extra flavor, or peeled shrimp will work). Boil for 2 minutes or until opaque and no longer translucent.",
                "Strain out the shrimp and transfer to an ice bath with cold water to cool completely. Peel off the shells and slice each shrimp in half. Devein shrimp if necessary.",
                "In a large pot, bring water to a boil. Cook rice noodles for 2-3 minutes until al dente. Strain and rinse under cold running water. Shake out excess water and transfer to a large bowl.",
                "Wet a sheet of rice paper with room temperature water for 1 second on all sides. Place wet rice paper onto a clean work surface.",
                "Place a piece of lettuce in the bottom half of the rice paper. Add 3 shrimp halves, pink side down, in the top half. Place mint leaves on top of each shrimp. Then, with wet hands, place about ⅓ cup of cooked vermicelli rice noodles inside the lettuce and spread into a log.",
                "From the end closest to you, roll the rice paper away from you, tucking in the lettuce and noodles. Then, roll and tuck in the shrimp and mint leaves. Tuck in the sides of the rice paper and finish rolling.",
                "Repeat until you have 9 rolls. Slice them in half with a wet sharp knife. Serve with your homemade Vietnamese peanut sauce!"
            ],
            notes: "Be sure not to over-soak the rice paper when wrapping. It should still be firm to the touch. For a delicious dipping experience, serve with the chilled homemade peanut sauce."
        )
        saveRecipe(
            name: "Tandoori Chicken (Smoky, Tender, Super Flavorful!)",
            prepTime: "15 minutes",
            cookingTime: "35 minutes",
            ingredients: [
                "5 (1130 g) chicken leg quarters, skinless (~2.5 lb)",
                "1/3 cup plain, whole-milk Greek yogurt",
                "2 tablespoons neutral oil, such as grapeseed oil",
                "2 tablespoons melted butter",
                "2 tablespoons lemon juice",
                "6-8 garlic cloves, finely chopped/crushed",
                "1 inch piece ginger, finely chopped/crushed",
                "1 tablespoon tomato paste",
                "1 tablespoon Kashmiri chili powder",
                "2 teaspoons coriander powder",
                "2 teaspoons cumin powder",
                "1 1/2 teaspoons red chili powder or cayenne",
                "1 teaspoon garam masala",
                "1/2 teaspoon turmeric powder",
                "1/2 teaspoon ground black pepper",
                "1 tablespoon dried fenugreek leaves (sukhi methi), crushed",
                "2 1/2 teaspoons kosher salt",
                "1/8 teaspoon sugar",
                "pinch deep orange or red food color (optional)"
            ],
            prePrepInstructions: [
                "Use a sharp knife to make 4 (2-3 inch) deep slits across the meat side of the chicken pieces. Turn over and cut another 2-3 slits on the underside.",
                "In a bowl large enough to fit the chicken, combine all the ingredients listed under Tandoori Marinade. Toss the chicken pieces to coat, making sure to get in the cuts and crevices. Cover and refrigerate for at least 6 hours, up to 48 hours. When ready to prepare, take out of the fridge and allow to come closer to room temperature."
            ],
            instructions: [
                "Preheat the oven to 375°F/190°C. Line a large baking sheet with parchment paper or aluminum foil. Place a baking rack on the parchment or aluminum foil-lined baking sheet. Lightly grease the rack with baking spray.",
                "Place the leg quarters meat side up on the baking sheet/rack. Reserve the excess marinade.",
                "Bake for 30 minutes, flipping the pieces midway, until cooked through (165°F/73.9°C). Turn on the Broil Function to High (550°F/288°C). If you don’t have a broil function, turn it to the highest heat setting.",
                "Remove the chicken from the oven and flip the chicken once again so the meaty side is on top. Brush/baste the remaining marinade over the chicken pieces.",
                "Place back in the oven and broil for 4-5 minutes, until lightly charred. If not charred within 6 minutes, move your oven rack on the top shelf so it’s close to the heat source. Continue to broil for another 1-2 minutes. Remove from the oven and allow to rest for 5 minutes.",
                "Garnish with cilantro and serve with lime/lemon, thinly sliced red onion, and Mint Raita or Imli (Tamarind) Chutney."
            ],
            notes: "For a more authentic restaurant-style look, add a pinch of deep orange or red food color. If you're using boneless chicken, bake for a shorter length of time (~20 minutes). Air-fry the chicken at 380°F (193°C) for 18-22 minutes for a crispy, juicy result with minimal effort."
        )
        saveRecipe(
            name: "Tangzhong Bread (Dairy-free)",
            prepTime: "5 hours 25 minutes",
            cookingTime: "25 minutes",
            ingredients: [
                "\\ For Tangzhong Starter Dough:",
                "35 g Bread Flour",
                "175 ml Water",
                
                "\\ Bread Dough:",
                "340 g Bread Flour",
                "3 g Salt",
                "30 g white granulated sugar",
                "5 g Instant Dry Yeast",
                "1 large Egg (room temperature)",
                "140 ml Oat Milk (or sub with an unflavored vegan milk)",
                "40 g Vegan Butter (cubed and softened at room temperature)",
                "Bread flour (to flour working surface)",
                
                "\\ Egg Wash:",
                "1 large Egg",
                "30 ml oat milk"
            ],
            prePrepInstructions: [
                "In a non-stick pan, mix 35 grams of bread flour with 175 ml of water. Mix well. Bring to medium heat and keep stirring until the mixture becomes a smooth thick slurry paste.",
                "It should be smooth enough to slide out of the pan into a bowl. If it is too thick, then it will not incorporate into your dough well. This is your Tangzhong starter. Remove it off heat and transfer to a dish. Allow this to cool down to room temperature while covered.",
                "Warm your oat milk in the microwave for 60 seconds or on the stovetop in a pan until lukewarm. Make sure your butter and egg are also room temperature. Any coldness will stop the yeast from being activated as it requires warmth.",
                "Meanwhile, in a large mixing bowl, add bread flour, sugar, salt, and instant yeast and mix well. Then add egg, lukewarm oat milk, butter along with the 155 grams of Tangzhong starter dough. Mix until everything is incorporated and becomes a small sticky ball of dough."
            ],
            instructions: [
                "Remove the dough from the mixing bowl and knead for 15-30 minutes until it’s smooth and not as tacky by hand or in a stand mixer. The dough should have an elastic stretchy feel with a slight sticky feel. You may use some bread flour here but not too much, about 2-3 tablespoon maximum to make it less tacky. If using a stand mixer, mix on medium speed for 15 minutes and then remove from bowl to knead again on a floured surface for a couple of minutes.",
                "Place dough into a clean greased mixing bowl to proof. Cover and allow this to rest in a warm area for 1.5 hours until it doubles in size. Pro Tip: I rested my bowl in a sink filled with warm water. The warmth helps the dough to rise faster or you may need to let it rest for 2-3 hours until doubled in size.",
                "Once it has doubled, divide dough into 3 equal portions. Roll into balls. You may use bread flour here (4 tablespoon at most) but not too much as the dough needs to remain sticky.",
                "Then with a rolling pin, roll each ball into a long shaped oval. Using your hands, roll the oval shaped dough into a roll. Pat the sides of each roll to make it smaller to fit into your lined or greased bread pan. Repeat this for the remaining two balls of dough.",
                "Cover and allow this to rest in a warm area until it has doubled in size, about 45-60 mins. The dough should have risen to be a bit taller than the height of your bread pan.",
                "In a small bowl, whisk one egg with 2 tablespoon oat milk. Brush dough with egg milk wash before baking.",
                "Bake for 25-27 minutes at 350°F until the top is golden brown on the second lowest rack.",
                "Remove from the bread pan and allow it to cool on a wire rack. Enjoy warm or cold."
            ],
            notes: "For the best texture, ensure your dough remains slightly sticky during the kneading process. You may also substitute oat milk with other plant-based milks."
        )
        saveRecipe(
            name: "Tarka Dhal (Latif's Inspired)",
            prepTime: "20 minutes",
            cookingTime: "30 minutes",
            ingredients: [
                "\\ First Process:",
                "1 cup red lentils",
                "1 medium onion (split in half)",
                "1 diced medium tomato",
                "1 tsp turmeric",
                "1.5 tsp salt",
                "1 heaped tsp minced ginger",
                "1 heaped tsp minced garlic",
                "3 green chillies",
                "2 bay leaves",
                "\\ Second Process:",
                "3-4 tbsp oil",
                "1 heaped tbsp butter",
                "2-3 tsp mustard seeds",
                "4 dried red Kashmiri chillies",
                "2 tsp heaped minced garlic",
                "1 heaped tsp minced ginger",
                "½ onion (remaining from the first process)",
                "1 tsp chilli powder",
                "2 tsp curry powder",
                "1 tsp coriander powder",
                "Cumin seeds",
                "4 cups water"
            ],
            prePrepInstructions: [
                "Wash and drain the red lentils about 5 times until the water is clear.",
                "Add 1 cup lentils into a hot pan on medium heat.",
                "Add 4 cups water, turmeric, salt, minced ginger, and minced garlic. Mix well.",
                "Add 3 tbsp oil, bay leaves, 3 green chillies (top removed and slit in half), 1 diced tomato, and ½ diced onion. Mix and cover.",
                "Cook for about 12-15 minutes. Stir after 5 minutes, and as the lentils start to change, increase to medium-high heat.",
                "Continue cooking until lentils become custard-like in consistency, thick and sticking to the pan, with larger bubbles."
            ],
            instructions: [
                "Once the lentils are thick and bubbling, reduce heat to very low and cook.",
                "Meanwhile, start the second process: heat 3-4 tbsp oil and 1 tbsp butter in a frying pan on medium-high heat.",
                "Add 3 tsp mustard seeds and let them bloom. Then add 3-4 dried Kashmiri chillies, ½ diced onion, 2 tsp garlic ginger paste, and 3 tsp fresh garlic.",
                "Let the onions caramelize, adjusting the heat as needed.",
                "Add this tarka (spiced oil) to the dhal and stir in. Continue cooking for an additional 5 minutes or so until reduced.",
                "Serve hot, garnished with coriander if desired."
            ],
            notes: "This dish can be served with rice or naan. Adjust the heat by modifying the number of green chillies and Kashmiri chillies."
        )
        saveRecipe(
            name: "Texas Beef Chili",
            prepTime: "10 minutes",
            cookingTime: "8 hours (slow cooker) / 35 minutes (Instant Pot)",
            ingredients: [
                "1 lb grass-fed organic beef",
                "1 green bell pepper (seeded and diced)",
                "1 large onion (diced)",
                "4 large carrots (chopped small)",
                "26 oz finely chopped tomatoes",
                "½ teaspoon ground black pepper",
                "1 teaspoon sea salt",
                "1 teaspoon onion powder",
                "1 tablespoon chopped fresh parsley",
                "1 tablespoon Worcestershire sauce",
                "4 teaspoons chili powder",
                "1 teaspoon paprika",
                "1 teaspoon garlic powder",
                "Pinch of cumin",
                "\\ For serving (optional):",
                "Dairy-free sour cream",
                "Diced onions",
                "Sliced jalapeños"
            ],
            prePrepInstructions: [
                "In a medium-size skillet, cook the ground beef over high heat until browned, stirring until no longer pink. Spoon the beef (including the fat) into the slow cooker or Instant Pot.",
                "For slow cooking, add green bell pepper, onion, carrots, and tomatoes to the slow cooker. Stir well and add the remaining spices and seasonings. Stir once more, cover, and cook on low for 8 hours or on high for 5 hours.",
                "For Instant Pot, press the 'Sauté' button and cook the ground beef until browned. Add the remaining ingredients and stir well. Cover, lock the lid, and press the 'Meat/Stew' button to cook on high pressure for 35 minutes."
            ],
            instructions: [
                "Once the chili is done, allow the Instant Pot to switch to 'Keep Warm' mode and release pressure either naturally or with a quick release.",
                "Serve with optional toppings such as dairy-free sour cream, diced onions, and sliced jalapeños."
            ],
            notes: "Adjust the seasoning to taste, and for a spicier kick, consider adding extra chili powder or sliced jalapeños."
        )
        saveRecipe(
            name: "Chinese Tomato Egg Stir Fry (Easy 10-min)",
            prepTime: "3 minutes",
            cookingTime: "7 minutes",
            ingredients: [
                "4 roma tomatoes (sliced into quarters, or 2 large tomatoes)",
                "6 eggs",
                "1 green onion (finely chopped)",
                "60 ml water",
                "1 tsp sesame oil",
                "2 tsp vegetable oil (or any neutral tasting oil)",
                "\\ Sauce ingredients:",
                "3 tbsp ketchup",
                "½ tbsp cornstarch",
                "1 tsp white granulated sugar",
                "½ tsp ginger (thinly sliced)",
                "½ tsp salt",
                "125 ml water",
                "\\ Optional Garnish:",
                "1 green onion (finely chopped)"
            ],
            prePrepInstructions: [
                "In a bowl, mix all sauce ingredients (ketchup, cornstarch, sugar, ginger, salt, and water) and set aside.",
                "In a separate bowl, crack the eggs and add sesame oil. Beat the eggs and sesame oil for 20-30 seconds."
            ],
            instructions: [
                "Heat a nonstick skillet over medium heat. Once the pan is hot, add 1 teaspoon of oil. Add the egg mixture and scramble until the eggs take shape but are still glossy and moist. Remove the eggs from the pan.",
                "Add the remaining oil and green onions to the same pan. Cook for 5 seconds or until fragrant.",
                "Add tomatoes and water. Cook for 2-3 minutes until the tomatoes soften and the skin begins to peel away.",
                "Pour the sauce over the tomatoes. Let it simmer and thicken slightly for about 2 minutes.",
                "Once the sauce thickens, add the eggs back into the pan and gently fold them into the sauce and tomatoes. Remove from heat.",
                "Serve and enjoy. Optionally, garnish with more green onions."
            ],
            notes: "For a slightly sweeter taste, adjust the sugar level in the sauce. Garnish with extra green onions if desired."
        )
        saveRecipe(
            name: "Thai Iced Tea",
            prepTime: "6 minutes",
            cookingTime: "0 minutes",
            ingredients: [
                "500ml (2 cups) water",
                "45g (3 tablespoons) Thai Tea leaves (or substitute with regular black tea leaves or decaf black tea leaves for a decaf version)",
                "30ml (2 tablespoons) condensed milk (or condensed coconut milk for a dairy-free option)",
                "30ml (2 tablespoons) evaporated milk (or evaporated coconut milk for a dairy-free option)",
                "8 ice cubes (or as needed)"
            ],
            prePrepInstructions: [
                "In a tea strainer, line it with a coffee filter to help strain out very tiny tea leaves. Fill the lined tea strainer with the tea leaves. If using black tea bags, skip this step and place the bags into a small pot.",
                "Place the strainer into the small pot and fill the pot with 2 cups of water."
            ],
            instructions: [
                "Bring the water to a boil on medium-high heat. Reduce to low-medium heat to simmer and let the tea steep until it's very dark brown, about 5 minutes.",
                "In two separate glasses, fill each with 1 tablespoon of condensed milk followed by the divided ice cubes. If you prefer the tea hot, pour into a mug and skip the ice cubes.",
                "Once the black tea is steeped, pour it into the tall glasses.",
                "Pour 1 tablespoon of evaporated milk over each glass and mix to enjoy. Add more condensed milk if you prefer it sweeter."
            ],
            notes: "Adjust the sweetness by adding more condensed milk if desired. For a dairy-free version, use coconut milk for both the condensed and evaporated milk."
        )
        saveRecipe(
            name: "Thai Green Chicken Curry (Instant Pot)",
            prepTime: "10 minutes",
            cookingTime: "30 minutes",
            ingredients: [
                "1 tablespoon vegetable oil",
                "1 medium onion, peeled and sliced thin",
                "3 cloves garlic, crushed",
                "1/2 inch piece of ginger, peeled and crushed",
                "Cream from the top of a 13.5-ounce can coconut milk",
                "1/2 cup green curry paste (a whole 4-ounce can)",
                "3 pounds boneless skinless chicken thighs, cut into 2-inch by 1/2-inch strips",
                "1 teaspoon Diamond Crystal kosher salt or 3/4 teaspoon fine sea salt",
                "The rest of the 13.5-ounce can coconut milk",
                "1 cup chicken stock or water",
                "1 tablespoon fish sauce (plus more to taste)",
                "1 tablespoon soy sauce (plus more to taste)",
                "1 tablespoon brown sugar (plus more to taste)",
                "Juice of 1 lime",
                "12 ounces green beans, trimmed and cut into 2-inch pieces"
            ],
            prePrepInstructions: [
                "Heat the vegetable oil over medium-high heat in the pressure cooker pot until shimmering. (Use Sauté mode in an electric pressure cooker.) Stir in the onion, garlic, and ginger, and sauté until the onion starts to soften, about 3 minutes.",
                "Scoop the cream from the top of the can of coconut milk and add it to the pot, then stir in the curry paste. Cook, stirring often, until the curry paste darkens, about 5 minutes."
            ],
            instructions: [
                "Sprinkle the chicken with the kosher salt. Add the chicken to the pot, and stir to coat with curry paste. Stir in the rest of the can of coconut milk, chicken stock, fish sauce, soy sauce, and brown sugar.",
                "Lock the lid and pressure cook on high pressure for 10 minutes in an electric pressure cooker or 8 minutes in a stovetop pressure cooker. Quick release the pressure in the pot.",
                "Remove the lid from the pressure cooker, then set it over medium heat (Sauté mode in an electric pressure cooker). Stir in the lime juice and the green beans, and simmer the curry until the green beans are crisp-tender, about 4 minutes.",
                "Taste the curry for seasoning, adding more soy sauce (to add salt) or brown sugar (to add sweetness) as needed. Ladle the curry into bowls, sprinkle with minced cilantro and basil, and serve with Jasmine rice."
            ],
            notes: "Don’t shake the can of coconut milk—keep the solid cream at the top for frying with the curry paste. Adjust the amount of curry paste depending on how spicy you like your curry. If you prefer less heat, use only 1/4 cup of curry paste."
        )
        saveRecipe(
            name: "Tapioca Thousand Layer Cake (菱粉糍/千層糕)",
            prepTime: "15 minutes",
            cookingTime: "1 hour",
            ingredients: [
                "\\ For the batter:",
                "370 grams brown sugar slabs, can sub with 340 grams/2 cups packed light brown sugar",
                "4 cups (945ml) water, divided",
                "390 grams tapioca flour, 3 1/4 cups measured with the spoon-and-sweep method",
                "1 teaspoon kansui, optional",
                "\\ For garnish:",
                "toasted sesame seeds",
                "shredded unsweetened coconut",
                "\\ Steaming Equipment:",
                "circular pan with a 6 to 7 cup capacity, can use a square or rectangular pan",
                "oil for greasing pan",
                "steaming rack",
                "large wok for steaming"
            ],
            prePrepInstructions: [
                "Snap the brown sugar slabs in half and add them to a saucepan. Pour 2 1/2 cups of water over the sugar slabs and bring to a boil. Simmer until the sugar slabs dissolve completely.",
                "Add the tapioca flour and 1 1/2 cups of room temperature water to a mixing bowl. Stir together, but stop if the flour gets too stuck at the bottom.",
                "Once the sugar has dissolved, turn off the heat. Pour 1/3 of the hot sugar liquid into the bowl with the tapioca flour slurry and stir. Add the remaining sugar liquid and mix well, scraping the bottom of the bowl to ensure no lumps."
            ],
            instructions: [
                "Add a steaming rack into a large wok. Fill the wok with water, leaving about a 1/2-inch gap between the water level and the top of the rack. Bring to a boil.",
                "Grease the pan with oil and place it over the steaming rack. Reduce heat to medium.",
                "Stir the batter before pouring 2/3 cup into the pan, ensuring it covers the bottom completely. Cover the wok and steam for 4 minutes.",
                "Check that the layer is fully translucent. If so, pour another 2/3 cup of batter into the pan, cover, and steam for 4 minutes.",
                "Continue the process layer by layer, stirring the batter before each addition. For layers 3-5, steam for 5 minutes each. For layers 7-9, steam for about 6 minutes. If layers appear opaque, do not add more batter until the layer turns translucent.",
                "Replenish water in the wok by layer 5.",
                "Once all layers are steamed, turn off the heat. Tip the pan carefully to drain excess water.",
                "Sprinkle toasted sesame seeds and shredded coconut over the top of the cake while still warm.",
                "Let the cake cool completely before slicing."
            ],
            notes: "Use light brown sugar for a sweeter taste, and ensure the coconut milk is not shaken so that the cream can be separated for use. Store leftovers in a cool place and consume within 3-4 days, or refrigerate and reheat by steaming."
        )
        saveRecipe(
            name: "Tofu Stir Fry",
            prepTime: "10 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "\\ For the sauce:",
                "180 ml vegetable stock or water",
                "60 ml soy sauce",
                "2 tablespoons brown sugar",
                "2 teaspoons cornstarch",
                "0.13 teaspoon red pepper flakes, optional",
                "\\ For the tofu stir fry:",
                "2 tablespoons oil, divided (canola oil)",
                "400 g firm tofu, drained and cubed",
                "140 g broccoli, chopped",
                "180 g red bell pepper, julienned",
                "140 g carrots, peeled and julienned",
                "1 onion, julienned (yellow onion)",
                "2 cloves garlic, minced",
                "1 tablespoon fresh ginger root, peeled and minced"
            ],
            prePrepInstructions: [
                "Mix all the sauce ingredients in a small container until well combined. Set aside.",
                "Crack the eggs and beat them with sesame oil in a separate bowl for 20-30 seconds."
            ],
            instructions: [
                "Add 1 tablespoon of oil to a wok or skillet. When hot, add the tofu cubes and cook over medium-high heat until all sides are golden brown. Set aside.",
                "Add the remaining tablespoon of oil and when it's hot, add the veggies. Sauté over high heat for 2-3 minutes, stirring frequently.",
                "Add the tofu and sauce to the pan, stir, and cook for 1-2 more minutes until the sauce thickens. Stir frequently.",
                "Taste and add salt if needed. Serve immediately over rice or noodles, or enjoy on its own."
            ],
            notes: "Feel free to use any veggies you have on hand, such as green onions, green beans, cabbage, or mushrooms. For a gluten-free version, substitute tamari for soy sauce. Make it oil-free by using vegetable stock or water to sauté the veggies."
        )
        saveRecipe(
            name: "Tofu Stir Fry 2",
            prepTime: "10 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "\\ Stir Fry:",
                "1 pack extra-firm tofu, cut into cubes",
                "1 tablespoon cornstarch",
                "2–3 tablespoons avocado oil (or vegetable oil)",
                "1/2 red onion, chopped",
                "2 garlic cloves, finely chopped",
                "1 tablespoon minced ginger",
                "91g (1 cup) broccoli florets",
                "1 red bell pepper, chopped",
                "1 yellow bell pepper, chopped",
                "\\ Stir fry Sauce:",
                "63 ml (1/4 cup) vegetable broth",
                "3 tablespoons soy sauce (use gluten-free if needed)",
                "1 tablespoon honey (sub maple syrup for vegan)",
                "1/2 tablespoon rice vinegar",
                "1 teaspoon sesame oil",
                "1/2 teaspoon sriracha",
                "1 tablespoon cornstarch",
                "\\ Other:",
                "Rice or rice noodles for serving"
            ],
            prePrepInstructions: [
                "Drain the tofu and squeeze as much water out as possible using a kitchen towel or paper towel.",
                "Cut the tofu into cubes, then toss the tofu and cornstarch together until evenly coated."
            ],
            instructions: [
                "Heat 2 tablespoons of oil in a non-stick pan. Once hot, add the tofu and cook for 2-3 minutes on each side until golden brown. Remove the tofu from the pan.",
                "Add a touch more oil to the pan, then add the vegetables and sauté for 4-5 minutes until tender.",
                "Mix the tofu back in with the veggies, then add the stir fry sauce to the pan, stirring everything together until evenly coated.",
                "Serve on its own or with rice."
            ],
            notes: "For crispy tofu, use extra-firm tofu. Feel free to use different veggies, such as mushrooms or green beans. For a gluten-free version, use tamari instead of soy sauce."
        )
        saveRecipe(
            name: "Tomato Tofu Soup (番茄豆腐湯)",
            prepTime: "20 minutes",
            cookingTime: "20 minutes",
            ingredients: [
                "\\ Main Ingredients:",
                "496 g medium firm tofu (or firmer tofu, avoid silky or soft tofu)",
                "142 g fresh mushrooms",
                "2.5 eggs",
                "3.8 tomatoes",
                "2.5 slices ginger",
                "3.8 spring onions",
                "\\ Slurry Ingredients:",
                "3.8 tbsp cornstarch",
                "5 tbsp water",
                "\\ Cooking Ingredients:",
                "496 g chicken broth",
                "3.8 cup water",
                "2.5 tbsp ketchup",
                "1.3 tsp salt",
                "2.5 tbsp sugar",
                "1.3 tsp sesame oil",
                "1.3 tbsp cooking oil"
            ],
            prePrepInstructions: [
                "Cut some of the tomatoes into small diced pieces and the rest into larger pieces.",
                "Cut the mushroom into small diced pieces.",
                "Wash and chop the spring onions into medium-sized bits. Separate the white parts from the greens.",
                "Slice and smash the ginger to release its flavor.",
                "Optionally, remove the tomato skins by scoring them and placing them in boiling water for 20 seconds."
            ],
            instructions: [
                "Rinse the tofu and cut into medium pieces (32-40 pieces).",
                "Crack and lightly beat the eggs, setting aside.",
                "Mix cornstarch and water to make the slurry and set aside.",
                "Heat oil in a wok, sauté ginger for flavor, then add the white parts of the spring onions and sauté.",
                "Add smaller diced tomatoes and cook for 20-30 seconds, then add the rest of the tomatoes and mushrooms. Sauté for 20-30 seconds before transferring to a large pot.",
                "In the pot, add chicken broth and water, simmer for 1.5 minutes, then add tofu and cook for 10 minutes.",
                "Add the slurry slowly while stirring, adjust consistency and bring the soup back to high heat.",
                "Pour eggs into the soup while stirring gently, ensuring the heat is high so the eggs cook quickly.",
                "Add ketchup, salt, sugar, and sesame oil. Taste and adjust seasoning.",
                "Garnish with green spring onions and serve."
            ],
            notes: "For extra flavor, ensure the ginger is sautéed well. Adjust the seasoning with additional ketchup or salt if needed. Serve hot with a side of rice for a complete meal."
        )
        saveRecipe(
            name: "Tuna Pasta Bake",
            prepTime: "15 minutes",
            cookingTime: "55 minutes",
            ingredients: [
                "500g bag of Wholewheat brown fusilli pasta",
                "Jar of pasta bake sauce",
                "1.5 tin of chopped tomatoes",
                "1 sliced onion",
                "5 cloves of garlic (minced)",
                "3 tbsp chicken seasoning",
                "3 tbsp chilli flakes",
                "1 leek (sliced)",
                "2 carrots (sliced)",
                "1 box of mushrooms (sliced)",
                "2 chillies (diced)",
                "1 bell pepper (cubed)",
                "Handful of parsley (chopped)",
                "3 tsp Italian seasoning",
                "500g bag of grated cheddar",
                "4 cans of tuna in spring water (drained)",
                "1 can of sweetcorn",
                "2 tbsp tomato paste"
            ],
            prePrepInstructions: [
                "Chop all vegetables.",
                "Boil water in a kettle then add water and 1/2 tsp salt into a saucepan for carrots and beans.",
                "Fry onions, then add in garlic and half the chopped parsley."
            ],
            instructions: [
                "Once onions are fried, add in chopped tomatoes.",
                "Stir in 1 tbsp tomato paste, 3 tsp Italian seasoning, 3 tbsp chilli flakes, 3 tbsp chicken seasoning, and pasta bake sauce.",
                "Taste test and adjust accordingly.",
                "Preheat the oven to 190°C (Gas Mark 5).",
                "Layer pasta in a tray, then add chopped vegetables.",
                "Pour in the cooked sauce and toss until sauce is evenly coated.",
                "Bake in the oven for 25 minutes, covered in foil.",
                "Take out the tray, stir the pasta thoroughly, then sprinkle with grated cheese.",
                "Bake for an additional 30 minutes.",
                "Remove from oven and serve."
            ],
            notes: "Ensure the pasta is well coated with the sauce before baking for even flavor. You can also adjust the spice level with more or less chilli flakes according to your taste."
        )
        saveRecipe(
            name: "Tuna Sriracha Mayo Soy-Baked Potatoes",
            prepTime: "10 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "4 large baking potatoes",
                "3 x 135g cans tuna chunks in brine (drained)",
                "2 tbsp mayonnaise",
                "2 1/2 tbsp natural yogurt",
                "4 spring onions (thinly sliced)",
                "1 thumb-sized piece of ginger (peeled and finely grated)",
                "1 lemon (juiced)",
                "2 tsp sriracha or hot sauce",
                "3 pickled gherkins (finely chopped, optional)",
                "2 tbsp reduced-salt soy sauce",
                "320g spinach"
            ],
            prePrepInstructions: [
                "Prick the potatoes all over using a fork, then microwave on high for 10-15 minutes, or until softened. Heat the oven to 200°C/180°C fan/gas 6, or turn on the air fryer."
            ],
            instructions: [
                "Tip the tuna into a bowl and mix with mayonnaise, yogurt, spring onions, ginger, half the lemon juice, hot sauce, and gherkins (if using).",
                "When the potatoes are tender, score them lightly with a sharp knife, then pour over the soy sauce and toss quickly to coat.",
                "Bake in the oven for 15-20 minutes or in the air fryer at 200°C for 5 minutes to crisp up the skins.",
                "Meanwhile, combine the dressing ingredients with the remaining lemon juice and drizzle over the spinach.",
                "Split the potatoes in half, fill with the tuna mayo mixture, and serve with the spinach."
            ],
            notes: "For a tangier flavor, you can add more lemon juice to the dressing. The pickled gherkins are optional, but they add a nice crunch and flavor to the tuna mix."
        )
        saveRecipe(
            name: "Vanilla Cupcakes",
            prepTime: "5 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "41.67g self-raising flour + 1 tsp",
                "33.33g caster sugar",
                "⅓ tsp baking powder",
                "41⅔g soft unsalted butter",
                "0.5 tbsp milk",
                "0.08 tsp vanilla extract",
                "⅔ eggs",
                "Handful of raisins (optional)"
            ],
            prePrepInstructions: [
                "Preheat oven to 190°C."
            ],
            instructions: [
                "Whisk the flour, sugar, eggs, and butter for 30 seconds.",
                "Add in milk and vanilla extract and whisk for another 30 seconds.",
                "Spoon mixture into cupcake cases.",
                "Add in raisins tossed in 1 tsp flour if preferred.",
                "Bake for 10-15 minutes at 190°C.",
                "Poke to check if it pops up to confirm they are cooked. Once popped up, cool down before serving."
            ],
            notes: "For added texture, toss raisins in a little flour before adding to the batter to prevent them from sinking."
        )
        saveRecipe(
            name: "Vegan Bao Buns with Pulled Jackfruit",
            prepTime: "60 minutes",
            cookingTime: "12 minutes",
            ingredients: [
                "\\ BUNS (can be made 1 day ahead)",
                "300 g / 2½ cups bao flour OR all-purpose flour",
                "2 tsp instant active yeast",
                "1½ tbsp / 20 ml vegetable oil",
                "1 tsp fine sea salt",
                "2 tsp sugar (optional)",
                
                "\\ FILLING",
                "560 g / 20 oz tin of green / young jackfruit (drained)",
                "2 small spring onions, sliced",
                "4 tsp grated ginger",
                "3 garlic cloves, finely chopped",
                "3-4 tsp tamari / soy sauce, adjust to taste",
                "1 tbsp rice vinegar",
                "2 tbsp hoisin sauce (plus extra to serve)",
                "2 tsp brown sugar or maple syrup",
                "2 tbsp vegetable oil, for frying",
                "1 heaped tsp Chinese five spice",
                
                "\\ OTHER CONDIMENTS",
                "sliced fresh chilli or chilli sauce",
                "½ English cucumber, cut into matchsticks",
                "½ daikon or 1 turnip, cut into matchsticks",
                "red cabbage, shredded finely",
                "roasted (unsalted) peanuts, crushed or chopped",
                "spring onion, sliced finely",
                "fresh coriander"
            ],
            prePrepInstructions: [
                "In a mixing bowl, combine flour, instant yeast, sugar, and salt.",
                "Add about 120 ml / ½ cup of warm water and 1½ tbsp of oil. Combine roughly with a wooden spoon, then mix with your hands, adding more water gradually until the dough forms a smooth, elastic consistency.",
                "Knead for 10 minutes, form into a ball, and rub a small amount of oil on the surface. Cover and let rise for 1-2 hours or until doubled in size.",
                "Prepare your steamer by lining it with baking paper circles and small squares to prevent the buns from sticking."
            ],
            instructions: [
                "Once dough has risen, tip it out onto a floured surface and press the air out.",
                "Divide into 8 equal pieces and form into small balls. Let them rest for 30 minutes.",
                "Roll each ball into a ½ cm / ¼” thick oval shape, then fold in half with a square of baking paper inside.",
                "Place in the steamer and let rest for another 30 minutes. Steam on medium-high for 10 minutes. Rest for another 5 minutes before removing the buns from the steamer.",
                
                "For the filling, drain and prepare the jackfruit. Gently squash each piece to separate into strands.",
                "In a pan, heat the oil and fry spring onions, garlic, and ginger until softened. Add Chinese five spice and cook for 1 minute.",
                "Mix in tamari, hoisin sauce, rice vinegar, and sugar. Add jackfruit and stir to coat in the sauce. Cook until heated through.",
                "Assemble the buns by filling each with pulled jackfruit and your choice of condiments like fresh veggies, herbs, chilli, peanuts, and extra hoisin sauce."
            ],
            notes: "For an extra flavorful filling, feel free to experiment with additional herbs and toppings. These buns can be made a day ahead for convenience."
        )
        saveRecipe(
            name: "Vegan Chocolate Chip Cookies",
            prepTime: "20 minutes",
            cookingTime: "12-14 minutes",
            ingredients: [
                "2 tsp vanilla extract",
                "1 tbsp golden syrup",
                "1 tsp baking powder",
                "1 tsp salt",
                "250g plant-based butter",
                "225g caster sugar",
                "300g plain flour",
                "85g dark chocolate"
            ],
            prePrepInstructions: [
                "Preheat the oven to 180°C and line 2 baking sheets with parchment paper.",
                "If using a food processor, set it up. You can also mix everything by hand in a large bowl."
            ],
            instructions: [
                "Put the butter, sugar, vanilla extract, and golden syrup into the food processor and whizz until creamy.",
                "Add the flour, baking powder, and salt to the mixture and whizz everything together. If not using a food processor, use a wooden spoon to mix in a large bowl.",
                "Turn off the food processor and remove the blade. Chop the dark chocolate into small chips and fold them into the dough with a spatula.",
                "Spoon walnut-sized pieces of the dough onto the lined baking sheets, leaving 5cm between each dough ball. Flatten them slightly, but don’t make them as flat as pancakes.",
                "Bake for 12–14 minutes, swapping the baking sheets halfway through for even cooking. The cookies should be golden around the edges and paler in the center.",
                "After baking, leave the cookies on the baking sheets for 5–10 minutes to firm up. Then, carefully transfer them to wire racks to cool."
            ],
            notes: "For the best texture, allow the cookies to cool completely before serving."
        )
        saveRecipe(
            name: "Vegan Croissants",
            prepTime: "25 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "500g white flour",
                "10g salt",
                "50g caster sugar",
                "125g plant-based butter",
                "125g plant-based yoghurt",
                "125ml plant-based milk",
                "25g fresh yeast",
                "50ml maple syrup"
            ],
            prePrepInstructions: [
                "Preheat the oven to 180°C.",
                "Prepare a mixing bowl, standard mixer, and pastry brush. Line a baking tray with baking parchment."
            ],
            instructions: [
                "Put the flour, salt, sugar, yogurt, plant-based butter, and plant-based milk into the bowl of a stand mixer.",
                "Start the mixer at speed 2 or 3 to mix the ingredients for about 3 minutes.",
                "Add the yeast and continue mixing for another 3 minutes. If needed, add a couple of extra spoons of white flour to get the dough to a perfect elastic texture, not too wet or dry.",
                "Let the dough rest for 2 hours.",
                "Once rested, roll the dough out to about 5mm thick. Cut the dough into triangles and roll them into croissant shapes.",
                "Mix the soy milk and maple syrup together. Brush the croissants with the soy-maple mixture.",
                "Place the croissants on a tray lined with baking parchment and bake for 10 minutes, or until golden brown."
            ],
            notes: "For best results, let the dough rest for the full 2 hours to achieve a light and airy texture."
        )
        saveRecipe(
            name: "Vegan Lentil Roast (Mum’s)",
            prepTime: "15 minutes",
            cookingTime: "1 hour",
            ingredients: [
                "1 400g can green lentils",
                "2 tbsp vegetable or extra virgin olive oil",
                "1 medium onion",
                "1 medium carrot",
                "2 cloves garlic or 1 tsp garlic powder",
                "1 stick celery",
                "(optional) 1/2 red & orange bell pepper",
                "1 scotch bonnet",
                "4 medium mushrooms",
                "1 tsp black pepper",
                "1 tsp salt",
                "1 tbsp paprika",
                "1 tsp ginger powder",
                "1 tbsp all-purpose seasoning",
                "2 tbsp chia seeds",
                "1 cup breadcrumbs",
                "1 cup sage & paxo stuffing mix",
                "1 cup mixed nuts & dried fruit"
            ],
            prePrepInstructions: [
                "Heat oil in a pan and add chopped onions, vegetables, and seasoning. Cook until softened, then remove from heat and let it cool.",
                "Mix breadcrumbs, paxo sage & onion stuffing mix with mixed nuts and dried fruit.",
                "Mix chia seeds with 3 tbsp of warm water and leave until it becomes a thick, runny paste."
            ],
            instructions: [
                "Add the chia seed mixture to the dry mixture of nuts and dried fruit. Add more tablespoons of water as necessary if the mixture is too dry.",
                "Add the cooked vegetables to the dry mixture and combine everything together.",
                "Once combined, place the mixture in a loaf tin and bake in the oven for 1 hour at 170°C."
            ],
            notes: "If the mixture feels too dry, add more warm water until the paste reaches a thick, runny consistency. Serve with a side of vegetables or gravy for a complete meal."
        )
        saveRecipe(
            name: "Wild West Wings (Vegan)",
            prepTime: "35 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "1 tsp salt",
                "½ tsp pepper",
                "2 tsp cayenne pepper",
                "1 tsp smoked paprika",
                "1 tsp garlic powder",
                "200ml unsweetened plant-based milk",
                "100g coconut yoghurt",
                "500g oyster mushrooms",
                "175g plain flour",
                "Vegetable oil for frying",
                "2 lemons"
            ],
            prePrepInstructions: [
                "In a large mixing bowl, whisk together the plant-based milk, coconut yoghurt, and salt.",
                "Slice the lemons, squeeze the juice into the mixture, and remove any seeds.",
                "Whisk until there are no lumps and then add the mushrooms, stirring to coat. Leave for 10 minutes to marinate."
            ],
            instructions: [
                "In another mixing bowl, combine the plain flour, pepper, cayenne pepper, smoked paprika, and garlic powder. Mix well with a fork.",
                "For the chili sauce, peel and grate the garlic and ginger. Heat sesame oil in a small pan on medium heat. Add the garlic and ginger, cooking for 3 minutes until softened.",
                "Pour the garlic and ginger into a dish and stir in the maple syrup, soy sauce, and sriracha.",
                "In a large saucepan, pour vegetable oil to a depth of 8cm and heat to 180°C, or until a wooden spoon dipped in the oil sizzles.",
                "Transfer the marinated mushrooms into the dry flour mixture and toss until well coated.",
                "Fry the mushrooms in batches in the hot oil for 4–5 minutes, turning regularly, until golden brown. Transfer to kitchen paper to drain excess oil.",
                "Drizzle the fried mushrooms with the chili sauce and serve the rest in a bowl for dipping. Garnish with finely chopped chives and chili."
            ],
            notes: "For a milder flavor, you can remove the seeds from the chili before chopping. Serve with extra dipping sauce for more flavor."
        )
        saveRecipe(
            name: "Vegetable Lo Mein",
            prepTime: "15 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "283 g fresh egg noodles",
                "99.2 g fresh shiitake mushrooms",
                "85.0 g enoki mushrooms",
                "56.7 g king oyster mushrooms",
                "42.5 g carrots",
                "70.9 g broccoli",
                "70.9 g celery",
                "56.7 g red bell pepper",
                "85.0 g bean sprouts",
                "1 piece green onion",
                "1 clove garlic",
                "1 cup boiling water (for cooking noodles in wok)",
                "1 tbsp cornstarch",
                "3 tbsp water (for cornstarch)",
                "0.50 tbsp light soy sauce",
                "0.50 tbsp dark soy sauce",
                "1 tbsp oyster sauce",
                "1 tsp salt",
                "1 tsp sugar",
                "2 tbsp vegetable oil",
                "1 tsp sesame oil"
            ],
            prePrepInstructions: [
                "In a pot, bring at least 4 cups of water to a boil. Add the fresh egg noodles and stir to prevent sticking. Once boiling, cover and simmer, stirring occasionally for 5 minutes. Drain the noodles and rinse in cold water for 10-15 seconds.",
                "Wash all the vegetables and mushrooms in a bowl of water. For the enoki mushrooms, cut off the roots and separate them.",
                "Slice the shiitake, king oyster mushrooms, carrots, broccoli, celery, and red bell pepper into thin strips, about 1-2 inches long. Chop the green onion into pieces of similar length, and mince the garlic."
            ],
            instructions: [
                "Heat the wok on high heat for 2-5 minutes. Add 2 tbsp vegetable oil and swirl it around.",
                "Add the minced garlic and cook for about 20-30 seconds until fragrant. Then add all the vegetables and cook for 2-3 minutes.",
                "Add 1 cup boiling water to the wok, cover for 2-3 minutes. Mix cornstarch and 3 tbsp water in a bowl to create the slurry.",
                "Uncover the wok and add light soy sauce, dark soy sauce, oyster sauce, sugar, and salt. Stir the ingredients and then add the cooked noodles.",
                "Cover the wok and let it simmer for 3 minutes. Stir the cornstarch slurry and pour it into the wok, mixing well.",
                "Add the bean sprouts, chopped green onions, and sesame oil. Stir everything for another 1-2 minutes.",
                "Plate the noodles and serve!"
            ],
            notes: "You can add protein like tofu or tempeh to make the dish heartier. For a vegan version, substitute the oyster sauce with vegetarian oyster sauce."
        )
        saveRecipe(
            name: "Vietnamese Egg Rolls (Easy Chả Giò)",
            prepTime: "45 minutes",
            cookingTime: "15 minutes",
            ingredients: [
                "25 sheets spring roll wrappers (8.5 x 8.5 inches)",
                "500-750 ml vegetable oil or any neutral oil",
                "453 g ground pork or ground chicken, turkey, beef, or minced shrimp",
                "200 g carrots (peeled and grated)",
                "160 g mung bean noodles (dried)",
                "150 g cabbage (grated)",
                "110 g onion (grated or finely chopped)",
                "4 shiitake mushrooms or wood ear mushrooms (finely chopped)",
                "2 eggs",
                "6 g salt",
                "2 g black pepper",
                "4 g white granulated sugar",
                "11 g all purpose flour or cornstarch",
                "45 ml water",
                "100 g white granulated sugar (for dipping sauce)",
                "125 ml water (for dipping sauce)",
                "80 ml fish sauce",
                "1 bulb garlic (minced for dipping sauce)",
                "4 large red chilies (minced for dipping sauce)"
            ],
            prePrepInstructions: [
                "Grate carrots, cabbage, and onion using a box grater or food processor.",
                "Soak mung bean noodles in hot water for 50 seconds, then strain and cut into smaller pieces with kitchen scissors.",
                "In a large bowl, mix the mung bean noodles, ground pork (or other protein), grated carrots, cabbage, mushrooms, onions, eggs, salt, pepper, and sugar. Taste and adjust seasoning if necessary.",
                "In a separate small bowl, mix the flour and cold water to create the egg roll glue."
            ],
            instructions: [
                "Place a spring roll wrapper on a flat surface in a diamond shape. Fold the bottom corner up about ⅓ of the way.",
                "Add 3 levelled tablespoons of filling and shape it into a log.",
                "Fold the side corners over the filling, lightly brush the top corner with the flour-water mixture, and tightly roll the egg roll upwards.",
                "Repeat the process for the remaining filling, placing finished egg rolls on parchment paper.",
                "Heat 2-3 cups of oil in a wok or large skillet to 350°F. Fry the egg rolls in small batches for 3 minutes, turning halfway, until golden brown. Transfer to a wire rack to drain excess oil.",
                "For the dipping sauce, mix water, sugar, fish sauce, minced garlic, and minced red chilies in a small bowl until sugar dissolves.",
                "Serve the egg rolls with the dipping sauce."
            ],
            notes: "For air frying, lightly spray the air fryer basket with oil, place the egg rolls in a single layer (without overlapping), and air fry at 375°F for 8-10 minutes, flipping halfway through until golden and crispy."
        )
        saveRecipe(
            name: "White Chicken Chili (Instant Pot and Slow Cooker)",
            prepTime: "10 minutes",
            cookingTime: "6 hours",
            ingredients: [
                "2 pounds boneless skinless chicken breasts",
                "2 onions (diced)",
                "4 stalks celery (diced)",
                "1-2 jalapeño peppers (minced, adjust according to taste)",
                "10 cloves garlic (minced)",
                "1 tablespoon chili powder",
                "1 tablespoon salt (adjust to taste)",
                "1 teaspoon cumin",
                "1 teaspoon coriander powder",
                "1 teaspoon oregano",
                "½ teaspoon freshly crushed black pepper (adjust to taste)",
                "4 cups chicken broth",
                "1 pound bag of frozen corn (rinsed, optional if paleo)",
                "1 15-ounce can cannellini beans (rinsed, optional if paleo)",
                "Cilantro, hot sauce, and cheese for serving (optional)"
            ],
            prePrepInstructions: [
                "Dice the onions, celery, and jalapeño peppers.",
                "Mince the garlic.",
                "Rinse the corn and beans (if using)."
            ],
            instructions: [
                "Instant Pot: Add all ingredients except the corn and cannellini beans to the Instant Pot. Secure the lid, close the pressure valve, and cook on high pressure for 15 minutes.",
                "Once done, quick release the pressure. Shred the chicken in the pot, then add the corn and beans. Press the sauté button and cook for an additional 5 minutes or until the beans and corn are heated through.",
                "Slow Cooker: Add all ingredients except the corn and cannellini beans to the slow cooker. Cook for 4 hours on high or 6 hours on low.",
                "About 30 minutes before the cooking time is done, remove the lid, shred the chicken, and stir in the corn and beans."
            ],
            notes: "Serve the chili with cilantro, hot sauce, and cheese for extra flavor, if desired."
        )
        saveRecipe(
            name: "Wholemeal Flatbreads",
            prepTime: "10 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "350g wholemeal flour, plus extra for dusting",
                "4 tsp cold-pressed rapeseed oil",
                "225ml warm water"
            ],
            prePrepInstructions: [
                "Put the flour in a medium bowl and rub in the oil with your fingertips.",
                "Stir in warm water and mix thoroughly."
            ],
            instructions: [
                "Knead the dough until it feels smooth and elastic.",
                "Divide the dough into eight balls and roll each ball out very thinly, about 22cm in diameter.",
                "Sprinkle with extra flour to prevent sticking, then set aside.",
                "Heat a medium non-stick frying pan over high heat.",
                "Once hot, add one flatbread to the pan and cook for about 30 seconds, then turn and cook the other side for another 30 seconds. Press with a spatula to encourage puffing.",
                "Repeat for the remaining flatbreads, keeping them warm by wrapping in a clean tea towel until needed."
            ],
            notes: "You can freeze the flatbreads before cooking if making ahead."
        )
        saveRecipe(
            name: "Yin Yang Fried Rice (鴛鴦炒飯)",
            prepTime: "35 minutes",
            cookingTime: "20 minutes",
            ingredients: [
                "12 oz rice",
                "13 oz water",
                "3 egg",
                "1 tbsp oil",
                "0.50 tsp salt",
                "1 tomato",
                "1 oz onion",
                "5 oz shrimp",
                "15 oz chicken breast",
                "0.50 tsp salt (for marinade)",
                "1 tbsp cornstarch (for marinade)",
                "2 tbsp water (for marinade)",
                "3 tbsp ketchup",
                "2 tbsp sugar",
                "1 tbsp vinegar",
                "1 tsp salt (for red sauce)",
                "1 tbsp oil (for red side)",
                "6 oz chicken broth (for red sauce)",
                "1 tbsp cornstarch (for red sauce)",
                "2 tbsp water (for red sauce)",
                "2 tbsp oil (for white side)",
                "8 oz chicken broth (for white side)",
                "1 tsp salt (for white side)",
                "1 tbsp cornstarch (for white side)",
                "2 tbsp water (for white side)",
                "1 tsp oil (for finishing white sauce)",
                "2 oz peas"
            ],
            prePrepInstructions: [
                "Wash the rice 3 times in clean water, then add 13 oz water to cook the rice.",
                "Separate the egg yolks and whites, and dice the tomato and onion.",
                "Prepare the shrimp by cutting them in half lengthwise, and slice the chicken breast into strips, then marinate the chicken with salt, cornstarch, and water."
            ],
            instructions: [
                "Cook the rice in a rice cooker with 13 oz of water.",
                "Make the red sauce by mixing ketchup, sugar, vinegar, salt, and chicken broth. Adjust the flavor and set aside.",
                "Fold aluminum foil into an S-shape for later use.",
                "Mix egg yolks into the cooked rice and fry the rice with 1 tbsp oil for 3 minutes, then level it out on the serving plate.",
                "For the red side, stir-fry the chicken, onions, and tomatoes, then add the red sauce and slurry, simmer for 1 minute and set aside.",
                "For the white side, stir-fry shrimp, onions, and chicken broth. Add slurry and egg whites, and cook until set. Finish with oil and peas.",
                "Assemble by placing the aluminum mold over the rice, then scoop the red sauce on one side and the white sauce on the other. Carefully remove the mold."
            ],
            notes: "This dish is a visual treat with the red and white sides, and can be adjusted with more or less heat depending on the amount of jalapeño or chili used."
        )
        saveRecipe(
            name: "Yule Log",
            prepTime: "30 minutes",
            cookingTime: "10 minutes",
            ingredients: [
                "6 large eggs (separated)",
                "120g caster sugar (for egg yolks)",
                "30g caster sugar (for egg whites)",
                "50g cocoa powder",
                "pinch of salt",
                "½ tsp vanilla extract",
                "200g 50% chocolate chips",
                "100g unsalted butter",
                "100g double cream (for ganache)",
                "150ml double cream (for ganache)",
                "1 tsp icing sugar"
            ],
            prePrepInstructions: [
                "Grease and line a 43x28 cm tin with greaseproof paper, cutting the corners to fit the paper into the tin. Grease the paper.",
                "Whisk 120g caster sugar into the 6 egg yolks until the mixture is pale and thick.",
                "Sieve in 50g cocoa powder and a pinch of salt, then fold to create a thick paste. Stir in the vanilla extract and set aside.",
                "Whisk the egg whites in a separate bowl until soft peaks form, then gradually add 30g caster sugar and whisk until stiff peaks form."
            ],
            instructions: [
                "Incorporate the two mixtures by adding a scoop of egg whites into the chocolate mixture, stirring vigorously with a large metal spoon to loosen the batter.",
                "Gently fold in the rest of the egg whites in two batches, cutting through the middle and folding in from the sides until no white flecks remain.",
                "Preheat the oven to 190°C (170°C fan-assisted). Pour the mixture into the prepared tin, spreading the batter evenly while being careful not to knock out the air.",
                "Bake for 10 minutes. Check if the sponge is cooked by poking it; it should bounce back.",
                "Allow the sponge to cool for 2 minutes. Dust some icing sugar onto a flat tea towel.",
                "Flip the sponge onto the tea towel, remove the tin, and gently peel off the greaseproof paper.",
                "Roll the sponge with the tea towel while it is still warm and leave to cool completely."
            ],
            notes: "For the ganache, melt 100g butter with 200g chocolate chips in the microwave, then mix in 100g double cream. Let it cool down completely at room temperature or in the fridge, stirring frequently to ensure even cooling."
        )
        print("Default recipes added!")
    }
}
