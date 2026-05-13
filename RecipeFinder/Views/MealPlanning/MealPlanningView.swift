import SwiftUI

struct MealPlanningView: View {
    @Binding var recipes: [RecipeModel]
    @ObservedObject private var mealPlanningManager = MealPlanningManager.shared
    @State private var selectedDate: Date = Date()
    @State private var showMealTimeSelector = false
    @State private var selectedMealTimes: Set<MealTime> = []
    @State private var showRecipeWizard = false
    @State private var showRecipeSelector = false
    @State private var showQuickSnackSheet = false
    @State private var currentMealTime: MealTime?
    @State private var viewMode: ViewMode = .calendar
    @State private var showNutritionTips = false
    @State private var showMonthYearPicker = false
    
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
                
                viewModePicker
                
                ScrollView {
                    VStack(spacing: AppTheme.spacing32) {
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
                            selectedDayEmptyState
                                .transition(.opacity)
                        } else {
                            emptyStateView
                                .transition(.opacity)
                        }
                    }
                    .padding(.top, AppTheme.spacing16)
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.bottom, AppTheme.spacing100)
                }
            }
        }
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
                recipes: $recipes,
                mealTime: currentMealTime,
                onCreateNew: {
                    showRecipeSelector = false
                    showRecipeWizard = true
                },
                onSelectExisting: { recipe in
                    if let mealTime = currentMealTime {
                        saveMealPlan(recipe: recipe, for: selectedDate, mealTime: mealTime)
                    }
                    showRecipeSelector = false
                    currentMealTime = nil
                },
                onQuickSnack: {
                    showRecipeSelector = false
                    showQuickSnackSheet = true
                }
            )
        }
        .sheet(isPresented: $showQuickSnackSheet) {
            QuickSnackSheet(recipes: $recipes) { snackRecipe in
                if let mealTime = currentMealTime {
                    saveMealPlan(recipe: snackRecipe, for: selectedDate, mealTime: mealTime)
                }
                showQuickSnackSheet = false
                currentMealTime = nil
            }
        }
        .sheet(isPresented: $showMonthYearPicker) {
            MonthYearPickerSheet(selectedDate: $selectedDate)
        }
    }
    
    private func saveMealPlan(recipe: RecipeModel, for date: Date, mealTime: MealTime) {
        let mealPlan = MealPlanModel(
            recipeId: recipe.id,
            recipeName: recipe.name,
            date: date,
            mealTime: mealTime,
            servings: recipe.currentServings
        )
        mealPlanningManager.addMealPlan(mealPlan)
        
        selectedMealTimes.insert(mealTime)
        
        HapticManager.shared.success()
    }
    
    private func getRecipe(for date: Date, mealTime: MealTime) -> RecipeModel? {
        guard let mealPlan = mealPlanningManager.mealPlan(for: date, mealTime: mealTime) else {
            return nil
        }
        return recipes.first { $0.id == mealPlan.recipeId }
    }
    
    private func removeMealPlan(for date: Date, mealTime: MealTime) {
        mealPlanningManager.removeMealPlan(for: date, mealTime: mealTime)
        
        if mealPlanningManager.mealPlan(for: date, mealTime: mealTime) == nil {
            selectedMealTimes.remove(mealTime)
        }
    }
    
    private func hasMealPlans(for date: Date) -> Bool {
        return mealPlanningManager.hasMealPlans(for: date)
    }
    
    private var header: some View {
        GeometryReader { geometry in
            let spacing = AdaptiveSpacing(geometry: geometry)
            
            HStack(spacing: 0) {
                Color.clear
                    .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
                
                Spacer()
                
                Text("Meal Planner")
                    .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                    .adaptiveForegroundColor()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Spacer()
                
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
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: AppTheme.fontSize20))
                        .adaptiveForegroundColor()
                        .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
                }
            }
            .frame(height: spacing.touchTarget)
            .padding(.horizontal, spacing.screenEdge)
            .padding(.top, spacing.lg)
            .padding(.bottom, spacing.xl)
        }
        .frame(height: AppTheme.height80)
    }
    
    private var viewModePicker: some View {
        GeometryReader { geometry in
            HStack(spacing: AppTheme.spacing12) {
                ForEach([ViewMode.calendar, ViewMode.weeklyView], id: \.self) { mode in
                    Button(action: {
                        viewMode = mode
                        HapticManager.shared.light()
                    }) {
                        HStack(spacing: AppTheme.spacing6) {
                            Image(systemName: mode == .calendar ? "calendar" : "list.bullet")
                                .font(.system(size: AppTheme.fontSize14, weight: .semibold))
                            Text(mode == .calendar ? "Calendar" : "Weekly")
                                .font(.system(size: AppTheme.fontSize14, weight: .semibold))
                        }
                        .foregroundColor(viewMode == mode ? AppTheme.textColor(for: colorScheme) : AppTheme.textColor(for: colorScheme, opacity: 0.6))
                        .padding(.horizontal, AppTheme.spacing16)
                        .padding(.vertical, AppTheme.spacing10)
                        .background {
                            if viewMode == mode {
                                Capsule()
                                    .fill(colorScheme == .dark ? Color.white.opacity(AppTheme.overlayLightOpacity) : Color.black.opacity(0.15))
                            } else {
                                Capsule()
                                    .stroke(colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(AppTheme.shadowDarkOpacity), lineWidth: 1)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppTheme.spacing20)
            .padding(.bottom, max(20, geometry.size.height * 0.025))
        }
        .frame(height: AppTheme.height50)
    }
    
    private var weeklyPlanView: some View {
        VStack(spacing: AppTheme.spacing16) {
            HStack {
                Button(action: previousWeek) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                        .adaptiveForegroundColor()
                        .frame(width: 40, height: AppTheme.height40)
                        .background(Circle().fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity)))
                }
                
                Spacer()
                
                Text(weekRangeString)
                    .font(.system(size: AppTheme.fontSize18, weight: .bold))
                    .adaptiveForegroundColor()
                
                Spacer()
                
                Button(action: nextWeek) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                        .adaptiveForegroundColor()
                        .frame(width: 40, height: AppTheme.height40)
                        .background(Circle().fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity)))
                }
            }
            .padding(.horizontal, AppTheme.spacing4)
            
            VStack(spacing: AppTheme.spacing12) {
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
        .padding(AppTheme.spacing24)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius20)
                    .fill(colorScheme == .dark ? Color.white.opacity(AppTheme.glassSubtleOpacity) : Color.white.opacity(AppTheme.cardDarkOpacity))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius20)
                    .fill(.ultraThinMaterial)
            }
        }
    }
    
    private var calendarView: some View {
        VStack(spacing: AppTheme.spacing16) {
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                        .adaptiveForegroundColor()
                        .frame(width: 40, height: AppTheme.height40)
                        .background(Circle().fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity)))
                }
                
                Spacer()
                
                Button(action: {
                    showMonthYearPicker = true
                    HapticManager.shared.light()
                }) {
                    HStack(spacing: AppTheme.spacing6) {
                        Text(monthYearString)
                            .font(.system(size: AppTheme.fontSize22, weight: .bold))
                            .adaptiveForegroundColor()
                        
                        Image(systemName: "calendar.circle")
                            .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                            .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                        .adaptiveForegroundColor()
                        .frame(width: 40, height: AppTheme.height40)
                        .background(Circle().fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity)))
                }
            }
            .padding(.horizontal, AppTheme.spacing4)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppTheme.spacing4), count: 7), spacing: AppTheme.spacing8) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: AppTheme.fontSize12, weight: .semibold))
                        .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                        .frame(maxWidth: .infinity)
                }
                
                ForEach(Array(compactDaysInMonth.enumerated()), id: \.offset) { index, date in
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
                                updateSelectedMealTimes(for: date)
                                showMealTimeSelector = true
                            }
                            HapticManager.shared.light()
                        }
                    } else {
                        Color.clear
                            .frame(height: AppTheme.height50)
                    }
                }
            }
        }
        .padding(AppTheme.spacing24)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius20)
                    .fill(colorScheme == .dark ? Color.white.opacity(AppTheme.glassSubtleOpacity) : Color.white.opacity(AppTheme.cardDarkOpacity))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius20)
                    .fill(.ultraThinMaterial)
            }
        }
    }
    
    private func updateSelectedMealTimes(for date: Date) {
        let mealsForDate = mealPlanningManager.mealPlans(for: date)
        selectedMealTimes = Set(mealsForDate.map { $0.mealTime })
    }
    
    private var selectedMealsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            HStack {
                Text("Planned Meals")
                    .font(.system(size: AppTheme.fontSize20, weight: .bold))
                    .adaptiveForegroundColor()
                
                Spacer()
                
                Text(selectedDateString)
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(AppTheme.subduedEmphasisOpacity) : .black.opacity(AppTheme.subduedEmphasisOpacity))
            }
            .padding(.horizontal, AppTheme.spacing4)
            
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
            
            Button(action: {
                showMealTimeSelector = true
                HapticManager.shared.light()
            }) {
                HStack(spacing: AppTheme.spacing12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                    
                    Text("Add Another Meal")
                        .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                        .adaptiveForegroundColor()
                    
                    Spacer()
                }
                .padding(AppTheme.spacing16)
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
                        .stroke(Color.white.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [5]))
                )
            }
        }
    }
    
    private var selectedDayEmptyState: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing16) {
            HStack {
                Text("Meals for")
                    .font(.system(size: AppTheme.fontSize20, weight: .bold))
                    .adaptiveForegroundColor()
                
                Spacer()
                
                Text(selectedDateString)
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(AppTheme.subduedEmphasisOpacity) : .black.opacity(AppTheme.subduedEmphasisOpacity))
            }
            .padding(.horizontal, AppTheme.spacing4)
            
            VStack(spacing: AppTheme.spacing16) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: AppTheme.fontSize60))
                    .adaptiveForegroundColor(opacity: AppTheme.lowEmphasisOpacity)
                
                Text("No Meals Planned for This Day")
                    .font(.title2)
                    .fontWeight(.bold)
                    .adaptiveForegroundColor()
                
                Text("Tap below to add meals for \(shortDateString)")
                    .font(.subheadline)
                    .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
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
                    .adaptiveForegroundColor()
                    .padding(.horizontal, AppTheme.spacing24)
                    .padding(.vertical, AppTheme.spacing14)
                    .background(
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(AppTheme.overlayLightOpacity) : Color.black.opacity(0.15))
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.spacing40)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                        .fill(colorScheme == .dark ? Color.white.opacity(AppTheme.glassSubtleOpacity) : Color.white.opacity(AppTheme.cardDarkOpacity))
                } else {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                        .fill(.ultraThinMaterial)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.spacing16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: AppTheme.fontSize60))
                .adaptiveForegroundColor(opacity: AppTheme.lowEmphasisOpacity)
            
            Text("No Meals Planned Yet")
                .font(.title2)
                .fontWeight(.bold)
                .adaptiveForegroundColor()
            
            Text("Tap on a date to start planning your meals")
                .font(.subheadline)
                .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
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
                .adaptiveForegroundColor()
                .padding(.horizontal, AppTheme.spacing24)
                .padding(.vertical, AppTheme.spacing14)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(AppTheme.overlayLightOpacity))
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.spacing48)
    }
    
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
        guard let endDate = Calendar.current.date(byAdding: .day, value: -1, to: weekInterval.end) else {
            return startString
        }
        let endString = formatter.string(from: endDate)
        
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
            guard let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return days
    }
    
    private var compactDaysInMonth: [Date?] {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: selectedDate),
              let monthFirstWeek = Calendar.current.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var days: [Date?] = []
        var currentDate = monthFirstWeek.start
        let monthEnd = monthInterval.end
        
        while currentDate < monthEnd {
            if Calendar.current.isDate(currentDate, equalTo: selectedDate, toGranularity: .month) {
                days.append(currentDate)
            } else if !days.isEmpty && days.count % 7 != 0 {
                days.append(nil)
            } else if days.isEmpty {
                days.append(nil)
            }
            
            guard let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
            
            if currentDate > monthEnd && days.count % 7 == 0 {
                break
            }
        }
        
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
        
        while days.count < 42 {
            if Calendar.current.isDate(currentDate, equalTo: selectedDate, toGranularity: .month) {
                days.append(currentDate)
            } else {
                days.append(nil)
            }
            guard let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return days
    }
    
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

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasPlannedMeals: Bool
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: AppTheme.spacing4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: AppTheme.fontSize16, weight: isSelected ? .bold : (isToday ? .semibold : .regular)))
                .foregroundColor(textColor)
            
            if hasPlannedMeals {
                Circle()
                    .fill(Color.green)
                    .frame(width: 4, height: AppTheme.height4)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: AppTheme.height50)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(Color.white)
                    .shadow(color: Color.white.opacity(AppTheme.shadowDarkOpacity), radius: 8, x: 0, y: 4)
            } else if isToday {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .stroke(colorScheme == .dark ? Color.white.opacity(AppTheme.glassLightOpacity) : Color.black.opacity(AppTheme.glassLightOpacity), lineWidth: 2)
            }
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private var textColor: Color {
        if isSelected {
            return Color.blue
        } else if isToday {
            return AppTheme.adaptiveEmphasis(for: colorScheme)
        } else {
            return colorScheme == .dark ? .white.opacity(AppTheme.highEmphasisOpacity) : .black.opacity(AppTheme.highEmphasisOpacity)
        }
    }
}

struct MealTimeCard: View {
    let mealTime: MealTime
    let recipe: RecipeModel?
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: AppTheme.spacing16) {
            ZStack {
                Circle()
                    .fill(colorScheme == .dark ? Color.white.opacity(AppTheme.cardDarkOpacity) : Color.black.opacity(AppTheme.cardDarkOpacity))
                    .frame(width: 52, height: AppTheme.buttonHeightLarge)
                
                Image(systemName: mealTime.icon)
                    .font(.system(size: AppTheme.fontSize22, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(AppTheme.cardLightOpacity) : .black.opacity(0.9))
            }
            
            VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                Text(mealTime.rawValue)
                    .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                    .adaptiveForegroundColor()
                
                HStack(spacing: AppTheme.spacing4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(mealTime.timeRange)
                        .font(.caption)
                }
                .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                
                if let recipe = recipe {
                    HStack(spacing: AppTheme.spacing6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text(recipe.name)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                } else {
                    HStack(spacing: AppTheme.spacing6) {
                        Image(systemName: "fork.knife")
                            .font(.caption2)
                        Text("Tap to add recipe")
                            .font(.caption)
                    }
                    .adaptiveForegroundColor(opacity: AppTheme.glassLightOpacity)
                }
            }
            
            Spacer()
            
            Image(systemName: recipe != nil ? "pencil.circle" : "chevron.right")
                .font(.system(size: AppTheme.fontSize14, weight: .semibold))
                .adaptiveForegroundColor(opacity: AppTheme.lowEmphasisOpacity)
        }
        .padding(AppTheme.spacing16)
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
                .stroke(recipe != nil ? AppTheme.success.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct MealTimeSelectorSheet: View {
    let selectedDate: Date
    @Binding var selectedMealTimes: Set<MealTime>
    let onContinue: (MealTime) -> Void
    
    @Environment(\.dismiss) var dismiss
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: AppTheme.spacing12) {
                    HStack {
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            HStack(spacing: AppTheme.spacing6) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                Text("Cancel")
                                    .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                            }
                            .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                        }
                    }
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.top, AppTheme.spacing20)
                    
                    Text("Plan a Meal")
                        .font(.system(size: AppTheme.fontSize28, weight: .bold))
                        .adaptiveForegroundColor()
                        .shadow(color: .black.opacity(AppTheme.overlayLightOpacity), radius: 2, x: 0, y: 1)
                    
                    HStack(spacing: AppTheme.spacing8) {
                        Image(systemName: "calendar")
                            .font(.subheadline)
                        Text(dateString)
                            .font(.system(size: AppTheme.fontSize16, weight: .medium))
                    }
                    .adaptiveForegroundColor(opacity: AppTheme.nearSolidOpacity)
                }
                .padding(.bottom, AppTheme.spacing20)
                
                ScrollView {
                    VStack(spacing: AppTheme.spacing12) {
                            ForEach(MealTime.allCases, id: \.self) { mealTime in
                                Button(action: {
                                    selectedMealTimes.insert(mealTime)
                                    onContinue(mealTime)
                                    HapticManager.shared.light()
                                }) {
                                    HStack(spacing: AppTheme.spacing16) {
                                        ZStack {
                                            Circle()
                                                .fill(selectedMealTimes.contains(mealTime) 
                                                      ? AppTheme.success.opacity(0.2) 
                                                      : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity)))
                                                .frame(width: 50, height: AppTheme.height50)
                                            
                                            Image(systemName: mealTime.icon)
                                                .font(.system(size: AppTheme.fontSize22, weight: .semibold))
                                                .foregroundColor(selectedMealTimes.contains(mealTime) ? .green : (colorScheme == .dark ? .white.opacity(AppTheme.cardLightOpacity) : .black.opacity(0.9)))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                                            Text(mealTime.rawValue)
                                                .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                                                .adaptiveForegroundColor()
                                            
                                            HStack(spacing: AppTheme.spacing4) {
                                                Image(systemName: "clock")
                                                    .font(.caption2)
                                                Text(mealTime.timeRange)
                                                    .font(.caption)
                                            }
                                            .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedMealTimes.contains(mealTime) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title3)
                                                .foregroundColor(.green)
                                        } else {
                                            Image(systemName: "plus.circle")
                                                .font(.title3)
                                                .foregroundColor(colorScheme == .dark ? .white.opacity(AppTheme.lowEmphasisOpacity) : .black.opacity(AppTheme.lowEmphasisOpacity))
                                        }
                                    }
                                    .padding(AppTheme.spacing16)
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
                                            .stroke(selectedMealTimes.contains(mealTime) 
                                                    ? AppTheme.success.opacity(0.5) 
                                                    : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity)), 
                                                    lineWidth: selectedMealTimes.contains(mealTime) ? 2 : 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, AppTheme.spacing20)
                        .padding(.bottom, AppTheme.spacing100)
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
    @Binding var recipes: [RecipeModel]
    let mealTime: MealTime?
    let onCreateNew: () -> Void
    let onSelectExisting: (RecipeModel) -> Void
    let onQuickSnack: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var showRecipeList = false
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
                
                VStack(spacing: 0) {
                    if showRecipeList {
                        VStack(spacing: AppTheme.spacing12) {
                            HStack {
                                Button(action: {
                                    withAnimation {
                                        showRecipeList = false
                                        searchText = ""
                                    }
                                    HapticManager.shared.light()
                                }) {
                                    HStack(spacing: AppTheme.spacing8) {
                                        Image(systemName: "chevron.left")
                                        Text("Back")
                                    }
                                    .adaptiveForegroundColor()
                                    .padding(.horizontal, AppTheme.spacing20)
                                    .padding(.vertical, AppTheme.spacing12)
                                }
                                Spacer()
                            }
                            
                            SearchBar(text: $searchText, placeholder: "Search Recipes...")
                                .padding(.horizontal)
                            
                            ScrollView {
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: AppTheme.spacing16) {
                                    ForEach(filteredRecipes) { recipe in
                                        Button(action: {
                                            onSelectExisting(recipe)
                                            HapticManager.shared.light()
                                        }) {
                                            CompactRecipeCard(recipe: recipe)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, AppTheme.spacing100)
                            }
                        }
                    } else {
                        VStack(spacing: AppTheme.spacing16) {
                            if mealTime == .snack {
                                Button(action: {
                                    onQuickSnack()
                                    HapticManager.shared.light()
                                }) {
                                    HStack(spacing: AppTheme.spacing12) {
                                        Image(systemName: "star.circle.fill")
                                            .font(.title2)
                                        Text("Add a Snack")
                                            .font(.headline)
                                        Spacer()
                                    }
                                    .adaptiveForegroundColor()
                                    .padding(AppTheme.spacing24)
                                    .background(
                                        LinearGradient(
                                            colors: [
                                                AppTheme.accentColor(for: selectedTheme),
                                                AppTheme.accentColor(for: selectedTheme).opacity(0.8)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(AppTheme.cornerRadius16)
                                }
                            }
                            
                            Button(action: {
                                onCreateNew()
                                HapticManager.shared.light()
                            }) {
                                HStack(spacing: AppTheme.spacing12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                    Text("Create Recipe")
                                        .font(.headline)
                                    Spacer()
                                }
                                .adaptiveForegroundColor()
                                .padding(AppTheme.spacing24)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color.purple,
                                            Color.purple.opacity(AppTheme.highEmphasisOpacity)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(AppTheme.cornerRadius16)
                            }
                            
                            Button(action: {
                                withAnimation {
                                    showRecipeList = true
                                }
                                HapticManager.shared.light()
                            }) {
                                HStack(spacing: AppTheme.spacing12) {
                                    Image(systemName: "list.bullet")
                                        .font(.title2)
                                    Text("Add from Existing")
                                        .font(.headline)
                                    Spacer()
                                }
                                .adaptiveForegroundColor()
                                .padding(AppTheme.spacing24)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color.blue,
                                            Color.blue.opacity(AppTheme.highEmphasisOpacity)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(AppTheme.cornerRadius16)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, AppTheme.spacing24)
                        
                        Spacer()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .adaptiveForegroundColor()
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

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
        HStack(spacing: AppTheme.spacing12) {
            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                Text(dayString)
                    .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                    .adaptiveForegroundColor()
                
                if isToday {
                    Text("Today")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            HStack(spacing: AppTheme.spacing8) {
                ForEach(["☀️", "🍽️", "🌙"], id: \.self) { icon in
                    Button(action: onAddMeal) {
                        Circle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity))
                            .frame(width: AppTheme.iconSize32, height: 32)
                            .overlay {
                                Text(icon)
                                    .font(.caption)
                                    .opacity(AppTheme.glassLightOpacity)
                            }
                    }
                }
            }
            
            Button(action: onAddMeal) {
                Image(systemName: "plus.circle")
                    .font(.title3)
                    .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
            }
        }
        .padding(AppTheme.spacing12)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(isToday ? (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity)) : (colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05)))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(isToday ? (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity)) : Color.clear)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                .stroke(isToday ? AppTheme.success.opacity(0.5) : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity)), lineWidth: isToday ? 2 : 1)
        )
    }
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

struct MonthYearPickerSheet: View {
    @Binding var selectedDate: Date
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
                    DatePicker(
                        "Select Month and Year",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                    .background {
                        if cardStyle == .solid {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                                .fill(colorScheme == .dark ? Color.white.opacity(AppTheme.glassSubtleOpacity) : Color.white.opacity(AppTheme.cardDarkOpacity))
                        } else {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                                .fill(.ultraThinMaterial)
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
                .padding(.top, AppTheme.spacing20)
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
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

#Preview {
    MealPlanningView(recipes: .constant([]))
}
