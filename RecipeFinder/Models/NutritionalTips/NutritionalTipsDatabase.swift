import Foundation

/// Curated, evidence-based nutritional guidance. Query helpers live in `NutritionalTipsDatabase+Queries.swift`.
struct NutritionalTipsDatabase {
    static let allTips: [NutritionalTip] = [
        NutritionalTip(
            title: "Follow the Healthy Plate Method",
            summary: "Fill half your plate with vegetables and fruits, a quarter with whole grains, and a quarter with healthy protein.",
            fullDescription: "Harvard's Healthy Eating Plate provides a science-backed blueprint for creating balanced meals. This approach emphasizes diet quality over quantity, focusing on the types of foods rather than strict calorie counting. Research shows that following this pattern reduces risk of chronic diseases including heart disease, type 2 diabetes, and certain cancers.",
            category: .plateComposition,
            sources: [
                ScientificSource(
                    institution: "Harvard T.H. Chan School of Public Health",
                    publication: "The Nutrition Source - Healthy Eating Plate",
                    year: 2023,
                    url: "https://nutritionsource.hsph.harvard.edu/healthy-eating-plate/"
                )
            ],
            actionableSteps: [
                "Make half your plate colorful vegetables and fruits",
                "Choose whole grains for a quarter of your plate",
                "Include healthy protein sources for the remaining quarter",
                "Add a serving of healthy fats like olive oil or nuts",
                "Drink water, coffee, or tea instead of sugary beverages"
            ],
            icon: "🍽️",
            evidenceLevel: .strong
        ),
        NutritionalTip(
            title: "Choose Whole Over Refined Grains",
            summary: "Whole grains have a milder effect on blood sugar and provide more nutrients than refined grains.",
            fullDescription: "Whole and intact grains—whole wheat, barley, quinoa, oats, brown rice—retain their fiber, vitamins, and minerals. Unlike refined grains (white bread, white rice), whole grains are digested more slowly, helping maintain stable blood sugar levels and providing sustained energy. Studies from Harvard show that replacing refined grains with whole grains significantly reduces the risk of type 2 diabetes and heart disease.",
            category: .wholeGrains,
            sources: [
                ScientificSource(
                    institution: "Harvard T.H. Chan School of Public Health",
                    publication: "Whole Grains",
                    year: 2023,
                    url: "https://nutritionsource.hsph.harvard.edu/what-should-you-eat/whole-grains/"
                ),
                ScientificSource(
                    institution: "Cambridge University Press",
                    publication: "Public Health Nutrition Journal",
                    year: 2024,
                    url: "https://www.cambridge.org/core/journals/public-health-nutrition"
                )
            ],
            actionableSteps: [
                "Replace white rice with brown rice, quinoa, or barley",
                "Choose 100% whole wheat bread instead of white bread",
                "Try oatmeal or whole grain cereals for breakfast",
                "Use whole wheat pasta or experiment with alternatives like buckwheat noodles",
                "Look for 'whole grain' as the first ingredient on labels"
            ],
            icon: "🌾",
            evidenceLevel: .strong
        ),
        NutritionalTip(
            title: "Diversify Your Protein Sources",
            summary: "Choose fish, poultry, beans, and nuts over red and processed meats.",
            fullDescription: "Research consistently shows that protein source matters as much as protein amount. Plant-based proteins (beans, lentils, nuts) and fish provide protein along with healthy fats, fiber, and beneficial micronutrients. Red meat should be limited, and processed meats (bacon, sausage, deli meats) should be avoided due to associations with increased cardiovascular disease and cancer risk.",
            category: .proteins,
            sources: [
                ScientificSource(
                    institution: "Harvard Medical School",
                    publication: "Protein Power - Healthy Eating Plate",
                    year: 2023,
                    url: "https://www.health.harvard.edu/staying-healthy/the-right-plant-based-diet-for-you"
                ),
                ScientificSource(
                    institution: "Oxford University",
                    publication: "European Heart Journal",
                    year: 2022,
                    url: "https://academic.oup.com/eurheartj"
                )
            ],
            actionableSteps: [
                "Include fish (especially fatty fish like salmon) 2-3 times per week",
                "Add beans or lentils to meals several times a week",
                "Choose poultry over red meat when eating animal protein",
                "Snack on unsalted nuts instead of processed snacks",
                "Try plant-based protein sources like tofu, tempeh, or edamame"
            ],
            icon: "🥩",
            evidenceLevel: .strong
        ),
        NutritionalTip(
            title: "Eat a Rainbow of Vegetables and Fruits",
            summary: "Aim for variety and color to get the full spectrum of nutrients and antioxidants.",
            fullDescription: "Different colored vegetables and fruits contain different phytonutrients and antioxidants. Eating a variety ensures you get vitamins A, C, K, folate, potassium, fiber, and hundreds of beneficial plant compounds. Harvard research emphasizes that vegetables and fruits reduce inflammation, support immune function, and decrease risk of chronic diseases. Note: Potatoes don't count as vegetables due to their blood sugar impact.",
            category: .vegetables,
            sources: [
                ScientificSource(
                    institution: "Harvard T.H. Chan School of Public Health",
                    publication: "Vegetables and Fruits",
                    year: 2023,
                    url: "https://nutritionsource.hsph.harvard.edu/what-should-you-eat/vegetables-and-fruits/"
                ),
                ScientificSource(
                    institution: "Cambridge University",
                    publication: "Public Health Nutrition - Diet Quality Studies",
                    year: 2024,
                    url: "https://www.cambridge.org/core/journals/public-health-nutrition"
                )
            ],
            actionableSteps: [
                "Include at least 2 colors of vegetables at every meal",
                "Keep washed, cut vegetables ready for quick snacks",
                "Add vegetables to dishes you already love (pasta, sandwiches, eggs)",
                "Try one new vegetable or fruit each week",
                "Choose whole fruits over fruit juice to get the fiber"
            ],
            icon: "🥗",
            evidenceLevel: .strong
        ),
        NutritionalTip(
            title: "Choose Healthy Oils and Fats",
            summary: "Use olive, canola, and other vegetable oils while avoiding trans fats.",
            fullDescription: "The type of fat matters more than the total amount. Unsaturated fats from plant sources (olive oil, nuts, avocados) improve cholesterol levels and benefit heart health. Trans fats (partially hydrogenated oils) and excessive saturated fats should be avoided. Harvard's research contradicts decades of low-fat diet advice, showing that healthy fats are essential for nutrient absorption and overall health.",
            category: .healthyFats,
            sources: [
                ScientificSource(
                    institution: "Harvard T.H. Chan School of Public Health",
                    publication: "Fats and Cholesterol",
                    year: 2023,
                    url: "https://nutritionsource.hsph.harvard.edu/what-should-you-eat/fats-and-cholesterol/"
                ),
                ScientificSource(
                    institution: "Harvard Medical School",
                    publication: "Ask the Expert: Healthy Fats",
                    year: 2012,
                    url: "https://www.health.harvard.edu/staying-healthy/the-truth-about-fats-bad-and-good"
                )
            ],
            actionableSteps: [
                "Cook with olive, canola, or avocado oil instead of butter",
                "Include a small handful of nuts daily",
                "Add avocado to salads and sandwiches",
                "Choose fatty fish (salmon, mackerel, sardines) for omega-3s",
                "Read labels to avoid 'partially hydrogenated' oils"
            ],
            icon: "🥑",
            evidenceLevel: .strong
        ),
        NutritionalTip(
            title: "Prioritize Water Over Sugary Drinks",
            summary: "Skip sugary beverages and limit juice; choose water, coffee, or tea instead.",
            fullDescription: "Sugary drinks are a major source of empty calories in modern diets, providing little to no nutritional value while significantly impacting blood sugar and contributing to weight gain. Harvard research identifies sugary beverages as one of the primary dietary factors in the obesity epidemic. Water, unsweetened coffee, and tea are the best choices for hydration.",
            category: .hydration,
            sources: [
                ScientificSource(
                    institution: "Harvard T.H. Chan School of Public Health",
                    publication: "Sugary Drinks",
                    year: 2023,
                    url: "https://nutritionsource.hsph.harvard.edu/healthy-drinks/sugary-drinks/"
                ),
                ScientificSource(
                    institution: "Cambridge University Press",
                    publication: "Public Health Nutrition - Fast Food Studies",
                    year: 2024,
                    url: "https://www.cambridge.org/core/journals/public-health-nutrition"
                )
            ],
            actionableSteps: [
                "Replace soda with water, sparkling water, or herbal tea",
                "If you drink juice, limit to a small glass per day",
                "Add lemon, cucumber, or berries to water for flavor",
                "Choose unsweetened coffee or tea (both contain beneficial antioxidants)",
                "Limit milk and dairy products to 1-2 servings per day"
            ],
            icon: "💧",
            evidenceLevel: .strong
        ),
        NutritionalTip(
            title: "Minimize Ultra-Processed Foods",
            summary: "Focus on whole foods and minimize consumption of heavily processed products.",
            fullDescription: "Ultra-processed foods contain industrial ingredients not typically used in home cooking, such as high-fructose corn syrup, hydrogenated oils, and modified starches. Cambridge research published in Public Health Nutrition shows these foods are linked to obesity, metabolic syndrome, and chronic diseases. Ultra-processed foods are engineered to be hyper-palatable, making overconsumption easy.",
            category: .foodQuality,
            sources: [
                ScientificSource(
                    institution: "Cambridge University Press",
                    publication: "Public Health Nutrition - Ultra-processed Foods",
                    year: 2019,
                    url: "https://www.cambridge.org/core/journals/public-health-nutrition"
                ),
                ScientificSource(
                    institution: "Harvard School of Public Health",
                    publication: "Food Processing and Health",
                    year: 2023,
                    url: "https://nutritionsource.hsph.harvard.edu/processed-foods/"
                )
            ],
            actionableSteps: [
                "Cook more meals at home using whole ingredients",
                "Read ingredient lists - fewer ingredients usually means less processing",
                "Choose foods with recognizable ingredients",
                "Prepare batches of whole foods to have throughout the week",
                "When buying packaged foods, look for minimal added sugars and sodium"
            ],
            icon: "✨",
            evidenceLevel: .strong
        ),
        NutritionalTip(
            title: "Practice Mindful Portion Control",
            summary: "Use visual cues and listen to hunger signals rather than eating to fullness.",
            fullDescription: "Research shows that portion sizes have grown dramatically over recent decades, contributing to overconsumption. Using the plate method naturally controls portions by emphasizing vegetables and whole foods while limiting calorie-dense items. Mindful eating - paying attention to hunger and fullness cues - helps prevent overeating.",
            category: .portionControl,
            sources: [
                ScientificSource(
                    institution: "Harvard Medical School",
                    publication: "Healthy Weight and Portion Control",
                    year: 2023,
                    url: "https://www.health.harvard.edu/staying-healthy/managing-your-weight-with-healthy-eating"
                ),
                ScientificSource(
                    institution: "Cambridge University",
                    publication: "Public Health Nutrition - Diet Quality",
                    year: 2024,
                    url: "https://www.cambridge.org/core/journals/public-health-nutrition"
                )
            ],
            actionableSteps: [
                "Use the plate method: half vegetables, quarter grains, quarter protein",
                "Eat slowly and pay attention to fullness signals",
                "Use smaller plates and bowls to naturally reduce portions",
                "Don't eat directly from large packages",
                "Stop eating when you're satisfied, not stuffed"
            ],
            icon: "⚖️",
            evidenceLevel: .strong
        ),
        NutritionalTip(
            title: "Maintain Regular Meal Patterns",
            summary: "Eating at consistent times helps regulate metabolism and prevent overeating.",
            fullDescription: "Emerging research suggests that meal timing and regularity may be as important as what you eat. Regular meal patterns help regulate hunger hormones, stabilize blood sugar, and support healthy metabolism. Skipping meals often leads to overconsumption later and can disrupt metabolic processes.",
            category: .mealTiming,
            sources: [
                ScientificSource(
                    institution: "Harvard Medical School",
                    publication: "Meal Timing and Metabolic Health",
                    year: 2022,
                    url: "https://www.health.harvard.edu/staying-healthy/meal-timing-and-frequency-implications-for-health"
                ),
                ScientificSource(
                    institution: "Cambridge University",
                    publication: "Nutrition and Metabolism Research",
                    year: 2023,
                    url: "https://www.cambridge.org/core/journals/public-health-nutrition"
                )
            ],
            actionableSteps: [
                "Try to eat meals at roughly the same times each day",
                "Don't skip breakfast - it sets your metabolic tone for the day",
                "Plan healthy snacks to avoid extreme hunger between meals",
                "Allow 12-14 hours overnight without eating (overnight fasting)",
                "Eat your largest meals earlier in the day when metabolism is more active"
            ],
            icon: "⏰",
            evidenceLevel: .moderate
        ),
        NutritionalTip(
            title: "Consider Your Plate's Impact on the Planet",
            summary: "Foods that are good for your health often align with environmental sustainability.",
            fullDescription: "Harvard's 'Your Plate and the Planet' initiative highlights that food production is a major contributor to greenhouse gas emissions and environmental resource demand. Plant-forward diets (emphasizing vegetables, fruits, whole grains, beans, and nuts) are both healthiest for humans and most sustainable for the planet. Reducing food waste and choosing sustainably-sourced foods benefit both personal and planetary health.",
            category: .sustainability,
            sources: [
                ScientificSource(
                    institution: "Harvard T.H. Chan School of Public Health",
                    publication: "Your Plate and the Planet",
                    year: 2023,
                    url: "https://nutritionsource.hsph.harvard.edu/sustainability/plate-and-planet/"
                ),
                ScientificSource(
                    institution: "Cambridge University Press",
                    publication: "Public Health Nutrition - Food Environments",
                    year: 2024,
                    url: "https://www.cambridge.org/core/journals/public-health-nutrition"
                )
            ],
            actionableSteps: [
                "Eat more plant-based meals throughout the week",
                "Choose local and seasonal produce when possible",
                "Reduce food waste by planning meals and storing food properly",
                "Choose sustainably-sourced seafood (look for certifications)",
                "Consider the full environmental impact of your food choices"
            ],
            icon: "🌍",
            evidenceLevel: .strong
        )
    ]
}
