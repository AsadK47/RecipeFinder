import ConfettiSwiftUI
import SwiftUI

struct RecipeDetailView: View {
    @State private var recipe: RecipeModel
    @State private var ingredientsState: [Bool]
    @State private var instructionsState: [Bool]
    @State private var prePrepState: [Bool]
    @State private var expandedSections: Set<String> = ["Ingredients", "Pre-Prep", "Instructions", "Notes"]
    @ObservedObject var shoppingListManager: ShoppingListManager
    @State private var addedIngredients: Set<String> = []
    @State private var showAddedFeedback: String?
    @State private var confettiCounter = 0
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var isGeneratingPDF = false
    @AppStorage("measurementSystem") private var measurementSystem: MeasurementSystem = .metric
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    
    // Performance: Pre-compute expensive checks
    private let hasPrePrep: Bool
    private let hasNotes: Bool
    private let notesSentences: [Substring]
    
    // Callback to refresh recipes list when favorite is toggled
    var onFavoriteToggle: (() -> Void)?
    
    init(recipe: RecipeModel, shoppingListManager: ShoppingListManager, onFavoriteToggle: (() -> Void)? = nil) {
        _recipe = State(initialValue: recipe)
        self.shoppingListManager = shoppingListManager
        self.onFavoriteToggle = onFavoriteToggle
        
        // Pre-compute state arrays
        _ingredientsState = State(initialValue: Array(repeating: false, count: recipe.ingredients.count))
        _instructionsState = State(initialValue: Array(repeating: false, count: recipe.instructions.count))
        _prePrepState = State(initialValue: Array(repeating: false, count: recipe.prePrepInstructions.count))
        
        // Pre-compute expensive checks
        self.hasPrePrep = !recipe.prePrepInstructions.isEmpty
        self.hasNotes = !recipe.notes.isEmpty
        self.notesSentences = recipe.notes.split(separator: ".")
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 0) {
                        // Title directly on gradient
                        Text(recipe.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 20)
                    
                    // All info cards with consistent spacing
                    VStack(spacing: 16) {
                        GlassCard {
                            InfoPairView(
                                label1: "Prep time", value1: recipe.prepTime, icon1: "clock",
                                label2: "Cook time", value2: recipe.cookingTime, icon2: "flame"
                            )
                            .padding()
                        }
                        
                        GlassCard {
                            InfoPairView(
                                label1: "Difficulty", value1: recipe.difficulty, icon1: "chart.bar",
                                label2: "Category", value2: recipe.category, icon2: "fork.knife"
                            )
                            .padding()
                        }
                        
                        // Updated Servings Card with Icon
                        GlassCard {
                            HStack {
                                VStack(spacing: 8) {
                                    Image(systemName: "person.2.fill")
                                        .font(.title2)
                                        .foregroundColor(.cyan)
                                    Text("Servings")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(recipe.currentServings)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                
                                Divider()
                                    .frame(height: 60)
                                    .padding(.horizontal)
                                
                                HStack(spacing: 12) {
                                    Button(
                                        action: {
                                            if recipe.currentServings > 1 {
                                                HapticManager.shared.light()
                                                recipe.currentServings -= 1
                                            }
                                        },
                                        label: {
                                            Image(systemName: "minus")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.white)
                                                .frame(width: 44, height: 44)
                                                .background(
                                                    Circle()
                                                        .fill(AppTheme.accentColor)
                                                )
                                        }
                                    )
                                    
                                    Button(
                                        action: {
                                            HapticManager.shared.light()
                                            recipe.currentServings += 1
                                        },
                                        label: {
                                            Image(systemName: "plus")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.white)
                                                .frame(width: 44, height: 44)
                                                .background(
                                                    Circle()
                                                        .fill(AppTheme.accentColor)
                                                )
                                        }
                                    )
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding()
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Collapsible Ingredients section with unit toggle
                    VStack(alignment: .leading, spacing: 12) {
                        // Custom header with unit toggle
                        HStack(spacing: 8) {
                            Button(
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        if expandedSections.contains("Ingredients") {
                                            expandedSections.remove("Ingredients")
                                        } else {
                                            expandedSections.insert("Ingredients")
                                        }
                                    }
                                },
                                label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "leaf.fill")
                                            .foregroundColor(.white)
                                            .font(.title3)
                                        Text("Ingredients")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                }
                            )
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                            
                            // Unit toggle
                            Button(
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        measurementSystem = measurementSystem == .metric ? .imperial : .metric
                                        HapticManager.shared.selection()
                                    }
                                },
                                label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: measurementSystem.icon)
                                            .font(.caption)
                                        Text(measurementSystem.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.2))
                                    )
                                }
                            )
                            .buttonStyle(PlainButtonStyle())
                            
                            // Chevron indicator
                            Button(
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        if expandedSections.contains("Ingredients") {
                                            expandedSections.remove("Ingredients")
                                        } else {
                                            expandedSections.insert("Ingredients")
                                        }
                                    }
                                },
                                label: {
                                    Image(systemName: "chevron.down")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white.opacity(0.8))
                                        .rotationEffect(.degrees(expandedSections.contains("Ingredients") ? 0 : -90))
                                        .animation(.spring(response: 0.3), value: expandedSections.contains("Ingredients"))
                                }
                            )
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.top, 24)
                        
                        // Collapsible content
                        if expandedSections.contains("Ingredients") {
                            GlassCard {
                                VStack(spacing: 12) {
                                    ForEach(recipe.ingredients.indices, id: \.self) { index in
                                        IngredientRowView(
                                            ingredient: recipe.ingredients[index],
                                            isChecked: ingredientsState[index],
                                            toggle: { 
                                                HapticManager.shared.light()
                                                ingredientsState[index].toggle()
                                            },
                                            scaleFactor: recipe.scaleFactor,
                                            measurementSystem: measurementSystem,
                                            onAddToShopping: {
                                                addIngredientToShoppingList(recipe.ingredients[index])
                                            },
                                            isInShoppingList: isIngredientInShoppingList(recipe.ingredients[index])
                                        )
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                            }
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.95).combined(with: .opacity),
                                removal: .scale(scale: 0.95).combined(with: .opacity)
                            ))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    
                    // Collapsible Pre-prep section
                    if hasPrePrep {
                        collapsibleSection(title: "Pre-Prep", icon: "list.clipboard") {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(recipe.prePrepInstructions.indices, id: \.self) { index in
                                    instructionRow(
                                        number: index + 1,
                                        text: recipe.prePrepInstructions[index],
                                        isChecked: prePrepState[index],
                                        toggle: { 
                                            HapticManager.shared.light()
                                            prePrepState[index].toggle()
                                        }
                                    )
                                }
                            }
                        }
                    }
                    
                    // Collapsible Instructions section
                    collapsibleSection(title: "Instructions", icon: "text.alignleft") {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(recipe.instructions.indices, id: \.self) { index in
                                instructionRow(
                                    number: index + 1,
                                    text: recipe.instructions[index],
                                    isChecked: instructionsState[index],
                                    toggle: { 
                                        HapticManager.shared.light()
                                        instructionsState[index].toggle()
                                    }
                                )
                            }
                        }
                    }
                    
                    // Collapsible Notes section
                    if hasNotes {
                        collapsibleSection(title: "Notes", icon: "note.text") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(notesSentences, id: \.self) { sentence in
                                    let trimmed = sentence.trimmingCharacters(in: .whitespaces)
                                    if !trimmed.isEmpty {
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "circle.fill")
                                                .font(.system(size: 6))
                                                .foregroundColor(.orange)
                                                .padding(.top, 6)
                                            Text(trimmed)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 100)
                .frame(width: geometry.size.width)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Favorite button
                    // TODO: Replace with AnimatedHeartButton once added to Xcode target
                    Button(action: toggleFavorite, label: {
                        Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundColor(recipe.isFavorite ? .red : .white)
                    })
                    
                    // Share button
                    Menu {
                        Button(action: { shareAsText() }, label: {
                            Label("Share as Text", systemImage: "doc.text")
                        })
                        
                        Button(action: { shareAsPDF() }, label: {
                            Label("Share as PDF", systemImage: "doc.richtext")
                        })
                        
                        Button(action: { copyToClipboard() }, label: {
                            Label("Copy to Clipboard", systemImage: "doc.on.clipboard")
                        })
                    } label: {
                        ZStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3)
                                .foregroundColor(.white)
                                .opacity(isGeneratingPDF ? 0 : 1)
                            
                            if isGeneratingPDF {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isGeneratingPDF)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if #available(iOS 16.0, *) {
                RecipeShareSheet(items: shareItems)
            } else {
                RecipeShareSheet(items: shareItems)
            }
        }
        .overlay(alignment: .bottom) {
            if let feedback = showAddedFeedback {
                HStack(spacing: 12) {
                    Image(systemName: "basket.fill")
                        .foregroundColor(.white)
                    Text("\(feedback) added to shopping list")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(AppTheme.accentColor)
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                )
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .opacity(showAddedFeedback != nil ? 1 : 0)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showAddedFeedback)
        .confettiCannon(
            trigger: $confettiCounter,
            num: 50,
            radius: 500.0
        )
        .onChange(of: instructionsState) { _, newValue in
            // Trigger confetti when all instructions are complete (not counting pre-prep)
            if !recipe.instructions.isEmpty && newValue.allSatisfy({ $0 }) {
                HapticManager.shared.success()
                confettiCounter += 1
            }
        }
    }
    
    // COLLAPSIBLE section view with expand/collapse animation
    private func collapsibleSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        let isExpanded = expandedSections.contains(title)
        
        return VStack(alignment: .leading, spacing: 12) {
            // Tappable header
            Button(
                action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        if isExpanded {
                            expandedSections.remove(title)
                        } else {
                            expandedSections.insert(title)
                        }
                    }
                },
                label: {
                    HStack(spacing: 8) {
                        Image(systemName: icon)
                            .foregroundColor(.white)
                            .font(.title3)
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Chevron indicator
                        Image(systemName: "chevron.down")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.8))
                            .rotationEffect(.degrees(isExpanded ? 0 : -90))
                            .animation(.spring(response: 0.3), value: isExpanded)
                    }
                    .padding(.top, 24)
                }
            )
            .buttonStyle(PlainButtonStyle())
            
            // Collapsible content
            if isExpanded {
                GlassCard {
                    content()
                        .frame(maxWidth: .infinity, alignment: .leading) // Force full width
                        .padding(20)
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
            }
        }
        .frame(maxWidth: .infinity) // Ensure container fills width
        .padding(.horizontal, 20)
    }
    
    private func instructionRow(number: Int, text: String, isChecked: Bool, toggle: @escaping () -> Void) -> some View {
        Button(action: toggle, label: {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accentColor)
                        .frame(width: 32, height: 32)
                    
                    Text("\(number)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .strikethrough(isChecked, color: .primary)
                    .opacity(isChecked ? 0.5 : 1.0)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isChecked ? .green : .gray.opacity(0.3))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        })
        .buttonStyle(.plain)
    }
    
    private func addIngredientToShoppingList(_ ingredient: Ingredient) {
        // Haptic feedback
        HapticManager.shared.light()
        
        // Normalize ingredient name to USDA standard (e.g., "beef slices" -> "Beef Steak")
        let normalizedName = IngredientNormalizer.normalize(ingredient.name)
        
        // Create item with normalized name and measurements
        let formattedWithUnit = ingredient.formattedWithUnit(for: recipe.scaleFactor, system: measurementSystem)
        let fullName = "\(normalizedName) (\(formattedWithUnit))"
        shoppingListManager.addItem(name: fullName, quantity: 1, category: nil)
        
        // Mark as added immediately for UI update
        addedIngredients.insert(ingredient.name)
        
        // Show feedback with normalized name
        showAddedFeedback = normalizedName
        
        // Keep basket purple and start fading after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.8)) {
                showAddedFeedback = nil
            }
        }
        
        // Clear the added state after 2 seconds (basket returns to normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                _ = addedIngredients.remove(ingredient.name)
            }
        }
    }
    
    private func isIngredientInShoppingList(_ ingredient: Ingredient) -> Bool {
        // Check if recently added (basket stays purple temporarily)
        if addedIngredients.contains(ingredient.name) {
            return true
        }
        // Don't check actual shopping list - let user add multiple times if needed
        return false
    }
    
    // Favorites
    
    private func toggleFavorite() {
        HapticManager.shared.light()
        recipe.isFavorite.toggle()
        
        // Update in Core Data
        PersistenceController.shared.toggleFavorite(withId: recipe.id)
        
        // Trigger callback if provided
        onFavoriteToggle?()
    }
    
    // Sharing
    
    private func shareAsText() {
        HapticManager.shared.light()
        
        // Generate text format
        let text = RecipeShareUtility.generateTextFormat(recipe: recipe, measurementSystem: measurementSystem)
        
        // Create a temporary text file for better sharing compatibility
        let fileName = "\(recipe.name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")).txt"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            // Write to temporary file
            try text.write(to: tempURL, atomically: true, encoding: .utf8)
            
            debugLog("✅ Created temp file for sharing: \(tempURL.path)")
            
            // Important: Set shareItems BEFORE showing the sheet
            // Add a small delay to ensure state is properly set
            DispatchQueue.main.async {
                self.shareItems = [tempURL]
                // Use another async to ensure shareItems is fully set before showing sheet
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.showShareSheet = true
                    HapticManager.shared.success()
                }
            }
        } catch {
            debugLog("❌ Failed to create text file: \(error.localizedDescription)")
            // Fallback: share as plain text string
            DispatchQueue.main.async {
                self.shareItems = [text as NSString]
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.showShareSheet = true
                    HapticManager.shared.success()
                }
            }
        }
    }
    
    private func shareAsPDF() {
        guard !isGeneratingPDF else { return }
        
        HapticManager.shared.light()
        isGeneratingPDF = true
        
        // Generate PDF on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            if let pdfData = RecipeShareUtility.generatePDF(
                recipe: recipe, 
                measurementSystem: measurementSystem,
                theme: appTheme
            ) {
                // Create temporary file
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(recipe.name.replacingOccurrences(of: "/", with: "-")).pdf")
                
                do {
                    try pdfData.write(to: tempURL)
                    
                    DispatchQueue.main.async {
                        shareItems = [tempURL]
                        showShareSheet = true
                        isGeneratingPDF = false
                        HapticManager.shared.success()
                    }
                } catch {
                    debugLog("❌ Failed to save PDF: \(error)")
                    DispatchQueue.main.async {
                        isGeneratingPDF = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    isGeneratingPDF = false
                }
            }
        }
    }
    
    private func copyToClipboard() {
        HapticManager.shared.light()
        
        // Generate and copy immediately
        let text = RecipeShareUtility.generateTextFormat(recipe: recipe, measurementSystem: measurementSystem)
        UIPasteboard.general.string = text
        HapticManager.shared.success()
        
        // Show feedback
        showAddedFeedback = "Recipe copied"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.8)) {
                showAddedFeedback = nil
            }
        }
    }
}

// Share Sheet
struct RecipeShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // Configure for iPad if needed
        if let popover = controller.popoverPresentationController,
           let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Update items if needed
        uiViewController.setValue(items, forKey: "activityItems")
    }
}
