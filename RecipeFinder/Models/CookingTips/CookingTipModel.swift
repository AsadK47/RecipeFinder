import Foundation

/// Represents a cooking tip with category and practical advice
struct CookingTipModel: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var content: String
    var category: CookingTipCategory
    var difficulty: TipDifficulty
    var isFavorite: Bool
    var tags: [String]
    var createdDate: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        category: CookingTipCategory,
        difficulty: TipDifficulty = .beginner,
        isFavorite: Bool = false,
        tags: [String] = [],
        createdDate: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
        self.difficulty = difficulty
        self.isFavorite = isFavorite
        self.tags = tags
        self.createdDate = createdDate
    }
}

// MARK: - Tip Category

enum CookingTipCategory: String, Codable, CaseIterable, Identifiable {
    case basics = "Cooking Basics"
    case techniques = "Techniques"
    case ingredients = "Ingredients"
    case equipment = "Equipment & Tools"
    case safety = "Food Safety"
    case storage = "Storage & Preservation"
    case substitutions = "Substitutions"
    case timeSaving = "Time-Saving Hacks"
    case presentation = "Plating & Presentation"
    case seasoning = "Seasoning & Flavor"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .basics: return "book.fill"
        case .techniques: return "wand.and.stars"
        case .ingredients: return "carrot.fill"
        case .equipment: return "wrench.and.screwdriver.fill"
        case .safety: return "checkmark.shield.fill"
        case .storage: return "refrigerator.fill"
        case .substitutions: return "arrow.triangle.swap"
        case .timeSaving: return "bolt.fill"
        case .presentation: return "sparkles"
        case .seasoning: return "leaf.fill"
        }
    }
    
    var color: String {
        switch self {
        case .basics: return "blue"
        case .techniques: return "purple"
        case .ingredients: return "green"
        case .equipment: return "orange"
        case .safety: return "red"
        case .storage: return "cyan"
        case .substitutions: return "indigo"
        case .timeSaving: return "yellow"
        case .presentation: return "pink"
        case .seasoning: return "mint"
        }
    }
}

// MARK: - Tip Difficulty

enum TipDifficulty: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var icon: String {
        switch self {
        case .beginner: return "star.fill"
        case .intermediate: return "star.leadinghalf.filled"
        case .advanced: return "star.circle.fill"
        }
    }
}

// MARK: - Sample Data

extension CookingTipModel {
    static let samples: [CookingTipModel] = [
        // Basics
        CookingTipModel(
            title: "Why Do Chef's Kitchens Look So Organized?",
            content: "Before you start cooking, prep all your ingredients. Chop vegetables, measure spices, and have everything ready to go. This French technique means 'everything in its place' and makes cooking so much smoother and less stressful. You'll avoid burning garlic while frantically chopping onions!",
            category: .basics,
            difficulty: .beginner,
            tags: ["preparation", "organization", "essential"]
        ),
        
        CookingTipModel(
            title: "Are You Making This Common Seasoning Mistake?",
            content: "Don't save all your salt for the end! Season at multiple stages: when sautéing onions, after browning meat, when adding liquids. This builds layers of flavor. Each ingredient should taste seasoned on its own. Remember: you can always add more salt, but you can't take it away.",
            category: .seasoning,
            difficulty: .beginner,
            tags: ["salt", "seasoning", "flavor"]
        ),
        
        // Techniques
        CookingTipModel(
            title: "Is Your Knife Actually Putting You in Danger?",
            content: "Keep your knife sharp - a dull knife is more dangerous than a sharp one. Use the 'claw grip' with your guiding hand, tucking fingertips inward. Let the knife do the work with a rocking motion. For herbs, roll them tightly and slice across for a chiffonade cut.",
            category: .techniques,
            difficulty: .intermediate,
            tags: ["knife skills", "safety", "cutting"]
        ),
        
        CookingTipModel(
            title: "Why Does Your Steak Stick to the Pan?",
            content: "Pat meat completely dry with paper towels before searing. Heat your pan until it's smoking hot. Don't move the meat - let it develop a crust for 3-4 minutes. If it's sticking, it's not ready to flip. A proper sear needs high heat and patience.",
            category: .techniques,
            difficulty: .intermediate,
            tags: ["meat", "searing", "high heat"]
        ),
        
        CookingTipModel(
            title: "Are You Throwing Away Liquid Gold?",
            content: "After searing meat, don't wash that pan! Add wine, stock, or even water to lift those brown bits (fond) from the bottom. Use a wooden spoon to scrape them up - they're packed with flavor. This forms the base of incredible pan sauces.",
            category: .techniques,
            difficulty: .intermediate,
            tags: ["sauce", "fond", "flavor"]
        ),
        
        // Ingredients
        CookingTipModel(
            title: "Did You Know Slicing Changes Garlic's Flavor?",
            content: "How you cut garlic affects its intensity. Minced garlic is stronger than sliced. Crushed or grated garlic is the most pungent. For mellow flavor, roast whole cloves. Add garlic near the end of cooking aromatics to prevent burning and bitterness.",
            category: .ingredients,
            difficulty: .beginner,
            tags: ["garlic", "aromatics", "preparation"]
        ),
        
        CookingTipModel(
            title: "When Should You Add Herbs to Your Dish?",
            content: "Use hardy herbs (rosemary, thyme, oregano) early in cooking. Add delicate herbs (basil, cilantro, parsley) at the end. When substituting dried for fresh, use 1/3 of the amount - dried herbs are more concentrated. Crush dried herbs between your fingers to release oils.",
            category: .ingredients,
            difficulty: .beginner,
            tags: ["herbs", "seasoning", "substitution"]
        ),
        
        CookingTipModel(
            title: "Are You Wasting the Best Part of Citrus?",
            content: "Always zest citrus before juicing - it's nearly impossible to zest a squeezed lemon! The zest contains aromatic oils that add bright flavor without acidity. Use a microplane for fine zest, avoiding the bitter white pith underneath.",
            category: .ingredients,
            difficulty: .beginner,
            tags: ["citrus", "zest", "technique"]
        ),
        
        // Equipment
        CookingTipModel(
            title: "Why Does Everything Stick to Your Pan?",
            content: "Give your pan 2-3 minutes to heat up properly. Test it by adding a drop of water - it should sizzle and evaporate immediately. A properly preheated pan prevents sticking and ensures even cooking. This is especially important for searing and stir-frying.",
            category: .equipment,
            difficulty: .beginner,
            tags: ["pan", "heat", "technique"]
        ),
        
        CookingTipModel(
            title: "Should You Really Never Use Soap on Cast Iron?",
            content: "Season cast iron regularly with oil. Clean while still warm using coarse salt as an abrasive - no soap needed! Dry thoroughly and apply a thin layer of oil. If food sticks, your seasoning needs work. A well-maintained cast iron is naturally non-stick.",
            category: .equipment,
            difficulty: .intermediate,
            tags: ["cast iron", "maintenance", "cleaning"]
        ),
        
        // Safety
        CookingTipModel(
            title: "How Do You Know When Meat is Really Done?",
            content: "Use a meat thermometer for safety and perfection. Chicken: 165°F (74°C), Pork: 145°F (63°C), Beef medium-rare: 135°F (57°C). Insert in the thickest part, away from bone. Let meat rest 5-10 minutes - temperature rises 5°F during rest.",
            category: .safety,
            difficulty: .beginner,
            tags: ["temperature", "meat", "food safety"]
        ),
        
        CookingTipModel(
            title: "Are You Making Your Family Sick Without Knowing?",
            content: "Use separate cutting boards for raw meat and vegetables. Never place cooked meat on the same plate that held raw meat. Wash hands with soap for 20 seconds after handling raw meat. Clean surfaces with hot soapy water immediately.",
            category: .safety,
            difficulty: .beginner,
            tags: ["hygiene", "food safety", "essential"]
        ),
        
        // Storage
        CookingTipModel(
            title: "Why Do Your Fresh Herbs Wilt So Fast?",
            content: "Store soft herbs (cilantro, parsley) like flowers in water in the fridge, covered loosely with plastic. Wrap hardy herbs in damp paper towels in the crisper. Freeze herbs in olive oil in ice cube trays for easy cooking additions.",
            category: .storage,
            difficulty: .beginner,
            tags: ["herbs", "storage", "preservation"]
        ),
        
        CookingTipModel(
            title: "Could You Be Storing Leftovers All Wrong?",
            content: "Cool hot food to room temperature quickly before refrigerating - divide into smaller portions in shallow containers. Store leftovers within 2 hours. Use airtight containers to prevent odor transfer. Label with dates and use within 3-4 days.",
            category: .storage,
            difficulty: .beginner,
            tags: ["leftovers", "refrigeration", "food safety"]
        ),
        
        // Substitutions
        CookingTipModel(
            title: "Out of Buttermilk? Try This 5-Minute Trick",
            content: "No buttermilk? Add 1 tablespoon of lemon juice or white vinegar to 1 cup of regular milk. Let it sit for 5-10 minutes until it curdles slightly. This works perfectly in baking recipes that call for buttermilk.",
            category: .substitutions,
            difficulty: .beginner,
            tags: ["buttermilk", "baking", "substitution"]
        ),
        
        CookingTipModel(
            title: "Can You Really Bake Without Eggs?",
            content: "Replace 1 egg with: 1/4 cup applesauce (moist cakes), 1 tbsp ground flaxseed + 3 tbsp water (cookies), or 1/4 cup mashed banana (quick breads). Each works best for specific recipes based on desired texture.",
            category: .substitutions,
            difficulty: .intermediate,
            tags: ["eggs", "baking", "vegan"]
        ),
        
        // Time-Saving
        CookingTipModel(
            title: "What If You Cooked Once and Ate All Week?",
            content: "Cook grains, beans, and proteins in bulk on weekends. Store in portioned containers. Make double batches of sauces and freeze in ice cube trays. Prep vegetables for the week - store cut veggies in water to keep crisp.",
            category: .timeSaving,
            difficulty: .beginner,
            tags: ["meal prep", "organization", "efficiency"]
        ),
        
        CookingTipModel(
            title: "Tired of Waiting Forever for Caramelized Onions?",
            content: "Add a pinch of baking soda to speed up caramelization (cuts time in half). Use medium-high heat instead of low. Add splashes of water to deglaze and prevent burning. Onions can be made ahead and frozen for quick use.",
            category: .timeSaving,
            difficulty: .intermediate,
            tags: ["onions", "shortcuts", "hack"]
        ),
        
        // Presentation
        CookingTipModel(
            title: "Why Do Restaurant Plates Look So Impressive?",
            content: "Plate in odd numbers (3 or 5 pieces) for visual appeal. Use the 'clock method': protein at 6 o'clock, starch at 2 o'clock, vegetables at 10 o'clock. Height adds drama - don't make everything flat. Leave some white space.",
            category: .presentation,
            difficulty: .intermediate,
            tags: ["plating", "presentation", "aesthetics"]
        ),
        
        CookingTipModel(
            title: "Is Your Garnish Actually Doing Its Job?",
            content: "Garnishes should be edible and relate to the dish. Fresh herbs match what's in the dish. A drizzle of good olive oil adds shine. Microgreens add texture and color. Keep it simple - one or two thoughtful touches beat cluttered plates.",
            category: .presentation,
            difficulty: .intermediate,
            tags: ["garnish", "presentation", "finishing"]
        ),
        
        // Seasoning & Flavor
        CookingTipModel(
            title: "Why Does Your Cooking Taste Flat?",
            content: "Great dishes balance sweet, salty, sour, bitter, and umami. Dish taste flat? Add acid (lemon, vinegar). Too acidic? Add sweetness. Too sweet? Add salt or acid. Bitter? Add fat or salt. Learn to taste and adjust.",
            category: .seasoning,
            difficulty: .advanced,
            tags: ["flavor", "balance", "tasting"]
        ),
        
        CookingTipModel(
            title: "Are You Unlocking Your Spices' Full Potential?",
            content: "Heat whole spices in a dry pan for 1-2 minutes until fragrant. This blooms their essential oils and intensifies flavor. Grind immediately after toasting for maximum impact. Works for cumin, coriander, fennel, and more.",
            category: .seasoning,
            difficulty: .intermediate,
            tags: ["spices", "flavor", "technique"]
        ),
        
        CookingTipModel(
            title: "What's Missing from Your Finished Dish?",
            content: "Add a final flourish before serving: a squeeze of fresh lemon, a drizzle of high-quality olive oil, flaky sea salt, or fresh herbs. These bright, fresh elements contrast with cooked flavors and make dishes pop.",
            category: .seasoning,
            difficulty: .beginner,
            tags: ["finishing", "flavor", "technique"]
        )
    ]
}
