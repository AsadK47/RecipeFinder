import SwiftUI

struct MealPlanningView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var recipes: [RecipeModel]
    @StateObject private var mealPlanningManager = MealPlanningManager()
    @State private var selectedDate: Date = Date()
    @State private var showMealTimeSelector = false
    @State private var selectedMealTimes: Set<MealTime> = []
    @State private var showRecipeWizard = false
    @State private var showRecipeSelector = false
    @State private var currentMealTime: MealTime?
    @State private var viewMode: ViewMode = .calendar
    @State private var showNutritionTips = false
    
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @Environment(\.colorScheme) var colorScheme
    
    enum ViewMode {
        case calendar
        case weeklyView
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                // View Mode Picker
                viewModePicker
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Nutrition Tips Banner
                        nutritionTipsBanner
                        
                        // Main Content
                        if viewMode == .calendar {
                            calendarView
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            weeklyPlanView
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                        if !selectedMealTimes.isEmpty {
                            selectedMealsSection
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else if Calendar.current.isDate(selectedDate, inSameDayAs: Date()) || hasMealPlans(for: selectedDate) || selectedDate > Date().addingTimeInterval(-86400) {
                            // Show empty state for selected day (today or future or recently viewed)
                            selectedDayEmptyState
                                .transition(.opacity)
                        } else {
                            emptyStateView
                                .transition(.opacity)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedMealTimes)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewMode)
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
                    if let mealTime = currentMealTime {
                        saveMealPlan(recipe: recipe, for: selectedDate, mealTime: mealTime)
                    }
                    showRecipeSelector = false
                    currentMealTime = nil
                }
            )
        }
    }
    
    // Meal Plan Management
    
    private func saveMealPlan(recipe: RecipeModel, for date: Date, mealTime: MealTime) {
        let mealPlan = MealPlanModel(
            recipeId: recipe.id,
            recipeName: recipe.name,
            date: date,
            mealTime: mealTime,
            servings: recipe.currentServings
        )
        mealPlanningManager.addMealPlan(mealPlan)
        
        // Add to selected meal times for display
        selectedMealTimes.insert(mealTime)
        
        HapticManager.shared.success()
    }
    
    private func getRecipe(for date: Date, mealTime: MealTime) -> RecipeModel? {
        guard let mealPlan = mealPlanningManager.mealPlan(for: date, mealTime: mealTime) else {
            return nil
        }
        // Find the recipe by ID
        return recipes.first { $0.id == mealPlan.recipeId }
    }
    
    private func removeMealPlan(for date: Date, mealTime: MealTime) {
        mealPlanningManager.removeMealPlan(for: date, mealTime: mealTime)
        
        // Remove from selected meal times if no recipe
        if mealPlanningManager.mealPlan(for: date, mealTime: mealTime) == nil {
            selectedMealTimes.remove(mealTime)
        }
    }
    
    private func hasMealPlans(for date: Date) -> Bool {
        return mealPlanningManager.hasMealPlans(for: date)
    }
    
    private var header: some View {
        VStack(spacing: 12) {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Back button
                    Button(action: {
                        HapticManager.shared.light()
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer(minLength: 8)
                    
                    Text("Meal Planner")
                        .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Spacer(minLength: 8)
                    
                    // Burger menu
                    Menu {
                        Button(action: {
                            HapticManager.shared.light()
                            showMealTimeSelector = true
                        }) {
                            Label("Add Meal", systemImage: "plus.circle")
                        }
                        
                        Button(action: {
                            HapticManager.shared.light()
                            showNutritionTips = true
                        }) {
                            Label("Nutrition Tips", systemImage: "heart.text.square")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            selectedMealTimes.removeAll()
                            mealPlanningManager.clearOldMealPlans()
                            HapticManager.shared.light()
                        }) {
                            Label("Clear Old Plans", systemImage: "trash")
                        }
                    } label: {
                        ModernCircleButton(icon: "line.3.horizontal") {}
                            .allowsHitTesting(false)
                    }
                    .frame(width: max(44, geometry.size.width * 0.15))
                }
            }
            .frame(height: 44)
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .padding(.bottom, 8)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.2),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var viewModePicker: some View {
        HStack(spacing: 12) {
            ForEach([ViewMode.calendar, ViewMode.weeklyView], id: \.self) { mode in
                Button(action: {
                    viewMode = mode
                    HapticManager.shared.light()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: mode == .calendar ? "calendar" : "list.bullet")
                            .font(.system(size: 14, weight: .semibold))
                        Text(mode == .calendar ? "Calendar" : "Weekly")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(viewMode == mode ? .white : .white.opacity(0.6))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background {
                        if viewMode == mode {
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                        } else {
                            Capsule()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
    
    private var nutritionTipsBanner: some View {
        Button(action: {
            showNutritionTips = true
            HapticManager.shared.light()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "heart.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Healthy Eating Tips")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Plan balanced meals for better health")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(16)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.green.opacity(0.15))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
        }
        .sheet(isPresented: $showNutritionTips) {
            NutritionTipsSheet(cardStyle: cardStyle, selectedTheme: selectedTheme, colorScheme: colorScheme)
        }
    }
    
    private var weeklyPlanView: some View {
        VStack(spacing: 16) {
            // Week navigation
            HStack {
                Button(action: previousWeek) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
                
                Spacer()
                
                Text(weekRangeString)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: nextWeek) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
            }
            .padding(.horizontal, 4)
            
            // Weekly meal grid
            VStack(spacing: 12) {
                ForEach(daysInCurrentWeek, id: \.self) { date in
                    WeekDayRow(
                        date: date,
                        isToday: Calendar.current.isDateInToday(date),
                        cardStyle: cardStyle,
                        colorScheme: colorScheme,
                        onAddMeal: {
                            selectedDate = date
                            showMealTimeSelector = true
                            HapticManager.shared.light()
                        }
                    )
                }
            }
        }
        .padding(20)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.15))
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            }
        }
    }
    
    private var calendarView: some View {
        VStack(spacing: 16) {
            // Month/Year header with better styling
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
            }
            .padding(.horizontal, 4)
            
            // Calendar grid - only show actual weeks needed
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                // Weekday headers
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
                
                // Calendar days - only show needed rows
                ForEach(compactDaysInMonth, id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            isToday: Calendar.current.isDateInToday(date),
                            hasPlannedMeals: hasMealPlans(for: date),
                            cardStyle: cardStyle,
                            colorScheme: colorScheme
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDate = date
                                // Load meal times for selected date
                                updateSelectedMealTimes(for: date)
                            }
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
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.15))
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            }
        }
    }
    
    private func updateSelectedMealTimes(for date: Date) {
        let mealsForDate = mealPlanningManager.mealPlans(for: date)
        selectedMealTimes = Set(mealsForDate.map { $0.mealTime })
    }
    
    private var selectedMealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Planned Meals")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(selectedDateString)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 4)
            
            ForEach(Array(selectedMealTimes).sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.self) { mealTime in
                Button(action: {
                    currentMealTime = mealTime
                    showRecipeSelector = true
                    HapticManager.shared.light()
                }) {
                    MealTimeCard(
                        mealTime: mealTime, 
                        recipe: getRecipe(for: selectedDate, mealTime: mealTime),
                        cardStyle: cardStyle, 
                        colorScheme: colorScheme
                    )
                }
                .buttonStyle(.plain)
                .contextMenu {
                    if getRecipe(for: selectedDate, mealTime: mealTime) != nil {
                        Button(role: .destructive) {
                            withAnimation {
                                removeMealPlan(for: selectedDate, mealTime: mealTime)
                            }
                            HapticManager.shared.success()
                        } label: {
                            Label("Remove Recipe", systemImage: "trash")
                        }
                    }
                }
            }
            
            // Add more meals button
            Button(action: {
                showMealTimeSelector = true
                HapticManager.shared.light()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                    
                    Text("Add Another Meal")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(16)
                .background {
                    if cardStyle == .solid {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.15))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [5]))
                )
            }
        }
    }
    
    private var selectedDayEmptyState: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Meals for")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(selectedDateString)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 48))
                    .foregroundColor(.white.opacity(0.3))
                
                Text("No meals planned for this day")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Tap below to add meals for \(shortDateString)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    showMealTimeSelector = true
                    HapticManager.shared.light()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Meal")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(32)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.15))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No meals planned yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.8))
            
            Text("Tap on a date to start planning your meals")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            
            Button(action: {
                showMealTimeSelector = true
                HapticManager.shared.light()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Plan a Meal")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
    
    // Helper Properties
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: selectedDate)
    }
    
    private var weekRangeString: String {
        guard let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate) else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let startString = formatter.string(from: weekInterval.start)
        let endString = formatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: weekInterval.end)!)
        
        return "\(startString) - \(endString)"
    }
    
    private var daysInCurrentWeek: [Date] {
        guard let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate) else {
            return []
        }
        
        var days: [Date] = []
        var currentDate = weekInterval.start
        
        for _ in 0..<7 {
            days.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return days
    }
    
    // Compact calendar that only shows the weeks needed for the current month
    private var compactDaysInMonth: [Date?] {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: selectedDate),
              let monthFirstWeek = Calendar.current.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var days: [Date?] = []
        var currentDate = monthFirstWeek.start
        let monthEnd = monthInterval.end
        
        // Only add weeks that contain days in the current month
        while currentDate < monthEnd {
            if Calendar.current.isDate(currentDate, equalTo: selectedDate, toGranularity: .month) {
                days.append(currentDate)
            } else if !days.isEmpty && days.count % 7 != 0 {
                // Add placeholder for days outside month but in same week row
                days.append(nil)
            } else if days.isEmpty {
                // Add leading placeholders for first week
                days.append(nil)
            }
            
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
            
            // Stop after we've passed the month and completed the week
            if currentDate > monthEnd && days.count % 7 == 0 {
                break
            }
        }
        
        // Fill remaining days in the last week if needed
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
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
    
    // Helper Methods
    
    private func previousMonth() {
        selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
        HapticManager.shared.light()
    }
    
    private func nextMonth() {
        selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
        HapticManager.shared.light()
    }
    
    private func previousWeek() {
        selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
        HapticManager.shared.light()
    }
    
    private func nextWeek() {
        selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
        HapticManager.shared.light()
    }
}

// Supporting Views

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasPlannedMeals: Bool
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: isSelected ? .bold : (isToday ? .semibold : .regular)))
                .foregroundColor(textColor)
            
            // Meal indicator dot
            if hasPlannedMeals {
                Circle()
                    .fill(Color.green)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.white.opacity(0.3), radius: 8, x: 0, y: 4)
            } else if isToday {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
            }
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private var textColor: Color {
        if isSelected {
            return Color.blue
        } else if isToday {
            return .white
        } else {
            return .white.opacity(0.8)
        }
    }
}

struct MealTimeCard: View {
    let mealTime: MealTime
    let recipe: RecipeModel?
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 52, height: 52)
                
                Image(systemName: mealTime.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(mealTime.rawValue)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(mealTime.timeRange)
                        .font(.caption)
                }
                .foregroundColor(.white.opacity(0.6))
                
                if let recipe = recipe {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text(recipe.name)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.white.opacity(0.9))
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "fork.knife")
                            .font(.caption2)
                        Text("Tap to add recipe")
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            Image(systemName: recipe != nil ? "pencil.circle" : "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(16)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.15))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(recipe != nil ? Color.green.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// Sheets

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
                
                VStack(spacing: 0) {
                    // Header section
                    VStack(spacing: 12) {
                        Text("Plan a Meal")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.subheadline)
                            Text(dateString)
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 20)
                    
                    // Meal times list
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(MealTime.allCases, id: \.self) { mealTime in
                                Button(action: {
                                    selectedMealTimes.insert(mealTime)
                                    onContinue(mealTime)
                                    HapticManager.shared.light()
                                }) {
                                    HStack(spacing: 16) {
                                        // Icon with styled background
                                        ZStack {
                                            Circle()
                                                .fill(selectedMealTimes.contains(mealTime) 
                                                      ? Color.green.opacity(0.2) 
                                                      : Color.white.opacity(0.1))
                                                .frame(width: 50, height: 50)
                                            
                                            Image(systemName: mealTime.icon)
                                                .font(.system(size: 22, weight: .semibold))
                                                .foregroundColor(selectedMealTimes.contains(mealTime) ? .green : .white.opacity(0.9))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(mealTime.rawValue)
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.white)
                                            
                                            HStack(spacing: 4) {
                                                Image(systemName: "clock")
                                                    .font(.caption2)
                                                Text(mealTime.timeRange)
                                                    .font(.caption)
                                            }
                                            .foregroundColor(.white.opacity(0.6))
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedMealTimes.contains(mealTime) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title3)
                                                .foregroundColor(.green)
                                        } else {
                                            Image(systemName: "plus.circle")
                                                .font(.title3)
                                                .foregroundColor(.white.opacity(0.4))
                                        }
                                    }
                                    .padding(16)
                                    .background {
                                        if cardStyle == .solid {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.15))
                                        } else {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(.ultraThinMaterial)
                                        }
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(selectedMealTimes.contains(mealTime) 
                                                    ? Color.green.opacity(0.5) 
                                                    : Color.white.opacity(0.1), 
                                                    lineWidth: selectedMealTimes.contains(mealTime) ? 2 : 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Cancel")
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
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

// MARK: - Weekly View Components

struct WeekDayRow: View {
    let date: Date
    let isToday: Bool
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    let onAddMeal: () -> Void
    
    private var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Date
            VStack(alignment: .leading, spacing: 4) {
                Text(dayString)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                if isToday {
                    Text("Today")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            // Meal indicators (placeholder - would show actual planned meals)
            HStack(spacing: 8) {
                ForEach(["☀️", "🍽️", "🌙"], id: \.self) { icon in
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Text(icon)
                                .font(.caption)
                                .opacity(0.5)
                        }
                }
            }
            
            // Add button
            Button(action: onAddMeal) {
                Image(systemName: "plus.circle")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(12)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isToday ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isToday ? Color.white.opacity(0.1) : Color.clear)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isToday ? Color.green.opacity(0.5) : Color.white.opacity(0.1), lineWidth: isToday ? 2 : 1)
        )
    }
}

// MARK: - Nutrition Tips Sheet

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
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "heart.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            
                            Text("Healthy Eating Guide")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("8 tips for planning nutritious meals")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                        
                        // Tips
                        ForEach(tips) { tip in
                            NutritionTipCard(tip: tip, cardStyle: cardStyle, colorScheme: colorScheme)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Close")
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

struct NutritionTip: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let category: String
}

struct NutritionTipCard: View {
    let tip: NutritionTip
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(tip.icon)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tip.category)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .textCase(.uppercase)
                    
                    Text(tip.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            
            Text(tip.description)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.15))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    MealPlanningView(recipes: .constant([]))
}
