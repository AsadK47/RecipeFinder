import SwiftUI

struct NutritionTip: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let category: String
}

struct NutritionTipsSheet: View {
    @Environment(\.dismiss) var dismiss
    let cardStyle: CardStyle
    let selectedTheme: AppTheme.ThemeType
    let colorScheme: ColorScheme
    
    private let tips = [
        NutritionTip(
            icon: "🥗",
            title: "Eat 5 A Day",
            description: "Aim for at least 5 portions of fruit and vegetables daily. They can be fresh, frozen, canned, or dried.",
            category: "Fruits & Vegetables"
        ),
        NutritionTip(
            icon: "🍞",
            title: "Choose Whole Grains",
            description: "Base meals on starchy carbohydrates like brown rice, whole wheat pasta, and potatoes with skins on.",
            category: "Carbohydrates"
        ),
        NutritionTip(
            icon: "🐟",
            title: "Eat More Fish",
            description: "Have at least 2 portions of fish weekly, including 1 portion of oily fish like salmon or mackerel.",
            category: "Protein"
        ),
        NutritionTip(
            icon: "🥤",
            title: "Stay Hydrated",
            description: "Drink 6-8 glasses of fluid daily. Water, milk, and unsweetened tea are healthier choices.",
            category: "Hydration"
        ),
        NutritionTip(
            icon: "🧂",
            title: "Reduce Salt",
            description: "Adults should eat no more than 6g of salt daily. Check food labels and cook from scratch.",
            category: "Salt & Sugar"
        ),
        NutritionTip(
            icon: "🍯",
            title: "Cut Down on Sugar",
            description: "Reduce sugary drinks, snacks, and desserts. They're high in calories and can cause tooth decay.",
            category: "Salt & Sugar"
        ),
        NutritionTip(
            icon: "🥑",
            title: "Choose Healthy Fats",
            description: "Use unsaturated fats like olive oil and avocado. Limit saturated fats from butter and cream.",
            category: "Fats"
        ),
        NutritionTip(
            icon: "🍳",
            title: "Don't Skip Breakfast",
            description: "A healthy breakfast with fiber and protein helps you start the day right and manage your weight.",
            category: "Meal Timing"
        )
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.spacing24) {
                        VStack(spacing: AppTheme.spacing12) {
                            Image(systemName: "heart.circle.fill")
                                .font(.system(size: AppTheme.fontSize60))
                                .foregroundColor(.green)
                            
                            Text("Healthy Eating Guide")
                                .font(.system(size: AppTheme.fontSize28, weight: .bold))
                                .adaptiveForegroundColor()
                            
                            Text("8 tips for planning nutritious meals")
                                .font(.subheadline)
                                .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                        }
                        .padding(.top, AppTheme.spacing20)
                        .padding(.bottom, AppTheme.spacing10)
                        
                        ForEach(tips) { tip in
                            NutritionTipCard(tip: tip, cardStyle: cardStyle, colorScheme: colorScheme)
                        }
                    }
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.bottom, AppTheme.spacing100)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: AppTheme.spacing6) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Close")
                        }
                        .adaptiveForegroundColor()
                    }
                }
            }
        }
    }
}

struct NutritionTipCard: View {
    let tip: NutritionTip
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            HStack(spacing: AppTheme.spacing12) {
                Text(tip.icon)
                    .font(.system(size: AppTheme.fontSize32))
                
                VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                    Text(tip.category)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .textCase(.uppercase)
                    
                    Text(tip.title)
                        .font(.system(size: AppTheme.fontSize18, weight: .bold))
                        .adaptiveForegroundColor()
                }
                
                Spacer()
            }
            
            Text(tip.description)
                .font(.system(size: AppTheme.fontSize15))
                .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppTheme.spacing24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .fill(colorScheme == .dark ? Color.white.opacity(AppTheme.glassSubtleOpacity) : Color.white.opacity(AppTheme.cardDarkOpacity))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .fill(.ultraThinMaterial)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                .stroke(AppTheme.success.opacity(0.2), lineWidth: 1)
        )
    }
}
