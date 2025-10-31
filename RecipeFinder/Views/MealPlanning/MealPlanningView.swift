import SwiftUI

struct MealPlanningView: View {
    @Binding var recipes: [RecipeModel]
    @State private var selectedDate: Date = Date()
    @State private var showMealTimeSelector = false
    @State private var selectedMealTimes: Set<MealTime> = []
    @State private var showRecipeWizard = false
    @State private var showRecipeSelector = false
    @State private var currentMealTime: MealTime?
    
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                ScrollView {
                    VStack(spacing: 24) {
                        calendarView
                        
                        if !selectedMealTimes.isEmpty {
                            selectedMealsSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showMealTimeSelector) {
            MealTimeSelectorSheet(
                selectedDate: selectedDate,
                selectedMealTimes: $selectedMealTimes,
                onContinue: { mealTime in
                    currentMealTime = mealTime
                    showMealTimeSelector = false
                    // Show options for wizard vs existing recipe
                    showRecipeSelector = true
                }
            )
        }
        .sheet(isPresented: $showRecipeWizard) {
            RecipeWizardView(prefilledData: nil) { newRecipe in
                recipes.append(newRecipe)
                currentMealTime = nil
                showRecipeWizard = false
            }
        }
        .sheet(isPresented: $showRecipeSelector) {
            RecipeSelectionSheet(
                recipes: recipes,
                mealTime: currentMealTime,
                onCreateNew: {
                    showRecipeSelector = false
                    showRecipeWizard = true
                },
                onSelectExisting: { recipe in
                    // Save meal plan entry
                    showRecipeSelector = false
                    currentMealTime = nil
                }
            )
        }
    }
    
    private var header: some View {
        VStack(spacing: 16) {
            HStack {
                // Left spacer for balance
                Color.clear
                    .frame(width: 44)
                
                Spacer()
                
                Text("Meal Planner")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Menu for all options
                Menu {
                    Button(action: {
                        HapticManager.shared.light()
                        showMealTimeSelector = true
                    }) {
                        Label("Add Meal", systemImage: "plus.circle")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: {
                        selectedMealTimes.removeAll()
                        HapticManager.shared.light()
                    }) {
                        Label("Clear All Plans", systemImage: "trash")
                    }
                } label: {
                    ModernCircleButton(icon: "line.3.horizontal") {}
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private var calendarView: some View {
        VStack(spacing: 16) {
            // Month/Year header
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                // Weekday headers
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
                
                // Calendar days
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            isToday: Calendar.current.isDateInToday(date),
                            cardStyle: cardStyle,
                            colorScheme: colorScheme
                        )
                        .onTapGesture {
                            selectedDate = date
                            showMealTimeSelector = true
                            HapticManager.shared.light()
                        }
                    } else {
                        Color.clear
                            .frame(height: 50)
                    }
                }
            }
        }
        .padding(20)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.9))
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
            }
        }
    }
    
    private var selectedMealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meals for \(selectedDateString)")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 4)
            
            ForEach(Array(selectedMealTimes), id: \.self) { mealTime in
                Button(action: {
                    currentMealTime = mealTime
                    showRecipeSelector = true
                    HapticManager.shared.light()
                }) {
                    MealTimeCard(mealTime: mealTime, cardStyle: cardStyle, colorScheme: colorScheme)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: selectedDate),
              let monthFirstWeek = Calendar.current.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var days: [Date?] = []
        var currentDate = monthFirstWeek.start
        
        while days.count < 42 { // 6 weeks
            if Calendar.current.isDate(currentDate, equalTo: selectedDate, toGranularity: .month) {
                days.append(currentDate)
            } else {
                days.append(nil)
            }
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return days
    }
    
    // MARK: - Helper Methods
    
    private func previousMonth() {
        selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
        HapticManager.shared.light()
    }
    
    private func nextMonth() {
        selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
        HapticManager.shared.light()
    }
}

// MARK: - Supporting Views

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.body)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(isSelected ? .white : (isToday ? .white : .white.opacity(0.8)))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue)
            } else if isToday {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
            }
        }
    }
}

struct MealTimeCard: View {
    let mealTime: MealTime
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack {
            Text(mealTime.icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(mealTime.rawValue)
                    .font(.headline)
                    .foregroundColor(cardStyle == .solid && colorScheme == .light ? Color.black : .white)
                
                HStack(spacing: 4) {
                    Text(mealTime.timeRange)
                        .font(.caption2)
                        .foregroundColor((cardStyle == .solid && colorScheme == .light ? Color.black : .white).opacity(0.5))
                    
                Text("•")
                    .font(.caption2)
                    .foregroundColor((cardStyle == .solid && colorScheme == .light ? Color.black : Color.white).opacity(0.5))
                
                Text("No recipe planned")
                    .font(.caption)
                    .foregroundColor((cardStyle == .solid && colorScheme == .light ? Color.black : Color.white).opacity(0.6))
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor((cardStyle == .solid && colorScheme == .light ? Color.black : Color.white).opacity(0.4))
        }
        .padding(16)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.9))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            }
        }
    }
}

// MARK: - Supporting Types

enum MealTime: String, CaseIterable {
    case breakfast = "Breakfast"
    case brunch = "Brunch"
    case lunch = "Lunch"
    case snack = "Snack"
    case dinner = "Dinner"
    case lateNight = "Late Night"
    
    var icon: String {
        switch self {
        case .breakfast: return "☀️"
        case .brunch: return "🥐"
        case .lunch: return "🍽️"
        case .snack: return "🍿"
        case .dinner: return "🌙"
        case .lateNight: return "🌃"
        }
    }
    
    var timeRange: String {
        switch self {
        case .breakfast: return "6:00 AM - 10:00 AM"
        case .brunch: return "10:00 AM - 12:00 PM"
        case .lunch: return "12:00 PM - 2:00 PM"
        case .snack: return "2:00 PM - 5:00 PM"
        case .dinner: return "5:00 PM - 9:00 PM"
        case .lateNight: return "9:00 PM - 12:00 AM"
        }
    }
}

// MARK: - Sheets

struct MealTimeSelectorSheet: View {
    let selectedDate: Date
    @Binding var selectedMealTimes: Set<MealTime>
    let onContinue: (MealTime) -> Void
    
    @Environment(\.dismiss) var dismiss
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Select meal time")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    Text(dateString)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(MealTime.allCases, id: \.self) { mealTime in
                                Button(action: {
                                    selectedMealTimes.insert(mealTime)
                                    onContinue(mealTime)
                                    HapticManager.shared.light()
                                }) {
                                    HStack(spacing: 16) {
                                        Text(mealTime.icon)
                                            .font(.title2)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(mealTime.rawValue)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            
                                            Text(mealTime.timeRange)
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedMealTimes.contains(mealTime) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding(16)
                                    .background {
                                        if cardStyle == .solid {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground)
                                        } else {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(.ultraThinMaterial)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }
}

struct RecipeSelectionSheet: View {
    let recipes: [RecipeModel]
    let mealTime: MealTime?
    let onCreateNew: () -> Void
    let onSelectExisting: (RecipeModel) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) var colorScheme
    
    var filteredRecipes: [RecipeModel] {
        if searchText.isEmpty {
            return recipes
        }
        return recipes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Text("Choose an option")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    if let mealTime = mealTime {
                        HStack {
                            Text(mealTime.icon)
                            Text(mealTime.rawValue)
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    // Create New Recipe button
                    Button(action: {
                        onCreateNew()
                        HapticManager.shared.light()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Create New Recipe")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .padding(20)
                        .background {
                            if cardStyle == .solid {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(colorScheme == .dark ? Color(white: 0.2) : Color.white.opacity(0.9))
                            } else {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                        .padding(.horizontal)
                    
                    // Existing recipes
                    Text("Or choose existing recipe")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    ModernSearchBar(text: $searchText, placeholder: "Search recipes...")
                        .padding(.horizontal)
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredRecipes) { recipe in
                                Button(action: {
                                    onSelectExisting(recipe)
                                    HapticManager.shared.light()
                                }) {
                                    HStack(spacing: 12) {
                                        if let imageName = recipe.imageName,
                                           let uiImage = UIImage(named: imageName) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 50, height: 50)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        } else {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 50, height: 50)
                                                .overlay {
                                                    Image(systemName: "photo")
                                                        .foregroundColor(.white.opacity(0.5))
                                                }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(recipe.name)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            
                                            Text(recipe.prepTime)
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                    .padding(12)
                                    .background {
                                        if cardStyle == .solid {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground)
                                        } else {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.ultraThinMaterial)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    MealPlanningView(recipes: .constant([]))
}
