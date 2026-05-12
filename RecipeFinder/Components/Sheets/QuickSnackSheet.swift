
import SwiftUI

// MARK: - Layout Constants

private enum QuickSnackLayout {
    static let headerHorizontalPadding: CGFloat = AppTheme.spacing20
    static let headerTopPadding: CGFloat = AppTheme.spacing20
    static let headerBottomPadding: CGFloat = AppTheme.spacing8
    static let addButtonTopPadding: CGFloat = AppTheme.spacing8
    static let scrollBottomPadding: CGFloat = 100
    static let emojiGridColumnCount = 8
    static let emojiGridItemSize: CGFloat = AppTheme.iconSize40
    static let snackCardWidth: CGFloat = AppTheme.width80
    static let snackCardHeight: CGFloat = 100
    static let maxVisibleSnacks = 20
    static let servingsDisplayMinWidth: CGFloat = 50
    static let minimumServings = 1
}

// MARK: - Card Background Modifier

private struct CardBackgroundModifier: ViewModifier {
    let cardStyle: CardStyle
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        content.background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(AppTheme.adaptiveCardMedium(for: colorScheme))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(.ultraThinMaterial)
            }
        }
    }
}

private extension View {
    func snackCardBackground(cardStyle: CardStyle, colorScheme: ColorScheme) -> some View {
        modifier(CardBackgroundModifier(cardStyle: cardStyle, colorScheme: colorScheme))
    }
}

// MARK: - QuickSnackSheet

struct QuickSnackSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var recipes: [RecipeModel]
    let onSnackAdded: (RecipeModel) -> Void

    @StateObject private var viewModel = QuickSnackViewModel()

    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()

                    Button(action: { dismiss() }) {
                        HStack(spacing: AppTheme.spacing6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                            Text("Cancel")
                                .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                        }
                        .adaptiveForegroundColor(opacity: 0.9)
                        .shadow(color: .black.opacity(AppTheme.shadowDarkOpacity), radius: 2, x: 0, y: 1)
                    }
                }
                .padding(.horizontal, QuickSnackLayout.headerHorizontalPadding)
                .padding(.top, QuickSnackLayout.headerTopPadding)
                .padding(.bottom, QuickSnackLayout.headerBottomPadding)

                ScrollView {
                    VStack(spacing: AppTheme.spacing32) {
                        QuickSnackHeaderView()

                        EmojiSelectorView(
                            selectedEmoji: $viewModel.selectedEmoji,
                            showEmojiPicker: $viewModel.showEmojiPicker,
                            cardStyle: cardStyle,
                            colorScheme: colorScheme,
                            selectedTheme: selectedTheme
                        )
                        .padding(.horizontal)

                        if !viewModel.hasCustomInput {
                            DietaryFilterView(
                                selectedFilters: $viewModel.selectedDietaryFilters,
                                cardStyle: cardStyle,
                                colorScheme: colorScheme
                            )
                            .padding(.horizontal)

                            SnackSuggestionsView(
                                filteredSnacks: viewModel.filteredSnacks,
                                onSnackSelected: { snack in
                                    viewModel.selectSnack(snack)
                                },
                                cardStyle: cardStyle,
                                colorScheme: colorScheme
                            )
                        }

                        SnackNameInputView(
                            snackName: $viewModel.snackName,
                            cardStyle: cardStyle,
                            colorScheme: colorScheme
                        )
                        .padding(.horizontal)

                        ServingsControlView(
                            servings: $viewModel.servings,
                            cardStyle: cardStyle,
                            colorScheme: colorScheme,
                            selectedTheme: selectedTheme
                        )
                        .padding(.horizontal)

                        if let selectedSnack = viewModel.selectedSnack {
                            DietaryTagsDisplayView(
                                tags: selectedSnack.dietaryTags,
                                calories: selectedSnack.calories
                            )
                            .padding(.horizontal)
                        }

                        AddButtonView(
                            isEnabled: viewModel.canAddSnack,
                            selectedTheme: selectedTheme,
                            action: {
                                addSnack()
                            }
                        )
                        .padding(.horizontal)
                        .padding(.top, QuickSnackLayout.addButtonTopPadding)
                    }
                    .padding(.bottom, QuickSnackLayout.scrollBottomPadding)
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showEmojiPicker)
    }

    private func addSnack() {
        let snackRecipe = viewModel.createSnackRecipe()
        recipes.append(snackRecipe)
        onSnackAdded(snackRecipe)
        HapticManager.shared.success()
        dismiss()
    }
}

// MARK: - ViewModel

class QuickSnackViewModel: ObservableObject {
    @Published var snackName: String = ""
    @Published var servings: Int = QuickSnackLayout.minimumServings
    @Published var selectedEmoji: String = "🍎"
    @Published var showEmojiPicker = false
    @Published var selectedDietaryFilters: Set<DietaryTag> = []
    @Published var selectedSnack: SnackItem?

    private static let snackCategory = "Snack"
    private static let snackPrepTime = "0 min"
    private static let snackDifficulty = 1

    var hasCustomInput: Bool {
        !snackName.isEmpty
    }

    var canAddSnack: Bool {
        !snackName.isEmpty
    }

    var filteredSnacks: [SnackItem] {
        SnackDatabase.snacks(matching: selectedDietaryFilters)
    }

    func selectSnack(_ snack: SnackItem) {
        selectedEmoji = snack.emoji
        snackName = snack.name
        selectedSnack = snack
        HapticManager.shared.light()
    }

    func createSnackRecipe() -> RecipeModel {
        var notes = "Quick snack - \(selectedEmoji)"
        if let selectedSnack = selectedSnack {
            let tags = selectedSnack.dietaryTags.map { $0.rawValue }.joined(separator: ", ")
            if !tags.isEmpty {
                notes += "\nDietary: \(tags)"
            }
            if let calories = selectedSnack.calories {
                notes += "\nCalories: ~\(calories) per serving"
            }
        }

        return RecipeModel(
            name: snackName,
            ingredients: [],
            instructions: "Enjoy your \(snackName)!",
            prepTime: QuickSnackViewModel.snackPrepTime,
            category: QuickSnackViewModel.snackCategory,
            difficulty: QuickSnackViewModel.snackDifficulty,
            currentServings: servings,
            baseServings: servings,
            defaultServings: servings,
            isFavorite: false,
            imageName: nil,
            notes: notes
        )
    }
}

// MARK: - Subviews

struct QuickSnackHeaderView: View {
    var body: some View {
        VStack(spacing: AppTheme.spacing8) {
            Text("Quick Add Snack")
                .font(.title2)
                .fontWeight(.bold)
                .adaptiveForegroundColor()
            
            Text("Add a simple snack in seconds")
                .font(.subheadline)
                .adaptiveForegroundColor(opacity: 0.7)
        }
        .padding(.top)
    }
}

struct EmojiSelectorView: View {
    @Binding var selectedEmoji: String
    @Binding var showEmojiPicker: Bool
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    let selectedTheme: AppTheme.ThemeType
    
    let emojiOptions = [
        "🍎", "🍌", "🍊", "🍇", "🍓", "🫐", "🍒", "🍑", "🥝", "🥑",
        "🥕", "🥒", "🥦", "🌽", "🍅", "🥔", "🫑", "🥜", "🌰", "🥐",
        "🥖", "🥯", "🧀", "🥚", "🍗", "🥓", "🌭", "🍕", "🍔", "🌮",
        "🍿", "🧃", "🥤", "🍵", "☕️", "🍪", "🍩", "🍰", "🧁", "🍫",
        "🍬", "🍭", "🥨", "🥪", "🌯", "🥗", "🍜", "🍝", "🍱", "🍙"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Icon")
                .font(.headline)
                .adaptiveForegroundColor()
            
            Button(action: {
                showEmojiPicker.toggle()
                HapticManager.shared.light()
            }) {
                HStack {
                    Text(selectedEmoji)
                        .font(.system(size: AppTheme.fontSize50))

                    Spacer()

                    Image(systemName: "chevron.down")
                        .adaptiveForegroundColor(opacity: AppTheme.glassLightOpacity)
                        .rotationEffect(.degrees(showEmojiPicker ? 180 : 0))
                }
                .padding()
                .snackCardBackground(cardStyle: cardStyle, colorScheme: colorScheme)
            }
            .accessibilityLabel("Selected emoji: \(selectedEmoji)")
            .accessibilityHint("Double tap to choose a different emoji icon")
            .accessibilityAddTraits(.isButton)
            
            if showEmojiPicker {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: AppTheme.spacing8),
                        count: QuickSnackLayout.emojiGridColumnCount
                    ),
                    spacing: AppTheme.spacing8
                ) {
                    ForEach(emojiOptions, id: \.self) { emoji in
                        Button(action: {
                            selectedEmoji = emoji
                            showEmojiPicker = false
                            HapticManager.shared.light()
                        }) {
                            Text(emoji)
                                .font(.system(size: AppTheme.fontSize32))
                                .frame(width: QuickSnackLayout.emojiGridItemSize, height: QuickSnackLayout.emojiGridItemSize)
                                .background {
                                    if selectedEmoji == emoji {
                                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius8)
                                            .fill(AppTheme.accentColor(for: selectedTheme).opacity(0.3))
                                    }
                                }
                        }
                    }
                }
                .padding()
                .background {
                    if cardStyle == .solid {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                            .fill(AppTheme.adaptiveCardHigh(for: colorScheme))
                    } else {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                            .fill(.ultraThinMaterial)
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

struct DietaryFilterView: View {
    @Binding var selectedFilters: Set<DietaryTag>
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    
    let commonFilters: [DietaryTag] = [
        .vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree,
        .keto, .paleo, .lowCarb, .highProtein, .lowCalorie
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Dietary Filters")
                .font(.headline)
                .adaptiveForegroundColor()
            
            FlowLayout(spacing: AppTheme.spacing8) {
                ForEach(commonFilters, id: \.self) { filter in
                    DietaryFilterChip(
                        filter: filter,
                        isSelected: selectedFilters.contains(filter),
                        action: {
                            toggleFilter(filter)
                        }
                    )
                }
            }
        }
    }

    private func toggleFilter(_ filter: DietaryTag) {
        if selectedFilters.contains(filter) {
            selectedFilters.remove(filter)
        } else {
            selectedFilters.insert(filter)
        }
        HapticManager.shared.light()
    }
}

struct DietaryFilterChip: View {
    let filter: DietaryTag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.spacing4) {
                Text(filter.icon)
                    .font(.caption)
                Text(filter.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, AppTheme.spacing12)
            .padding(.vertical, AppTheme.spacing6)
            .background(
                isSelected ?
                Color.green.opacity(0.8) :
                Color.white.opacity(AppTheme.overlayLightOpacity)
            )
            .adaptiveForegroundColor()
            .cornerRadius(AppTheme.cornerRadius16)
        }
    }
}

struct SnackSuggestionsView: View {
    let filteredSnacks: [SnackItem]
    let onSnackSelected: (SnackItem) -> Void
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            HStack {
                Text("Quick Picks")
                    .font(.headline)
                    .adaptiveForegroundColor()
                
                Spacer()
                
                Text("\(filteredSnacks.count) snacks")
                    .font(.caption)
                    .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.spacing12) {
                    ForEach(filteredSnacks.prefix(QuickSnackLayout.maxVisibleSnacks)) { snack in
                        Button(action: {
                            onSnackSelected(snack)
                        }) {
                            VStack(spacing: AppTheme.spacing8) {
                                Text(snack.emoji)
                                    .font(.system(size: AppTheme.fontSize32))
                                Text(snack.name)
                                    .font(.caption)
                                    .adaptiveForegroundColor()
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                
                                if let calories = snack.calories {
                                    Text("\(calories) cal")
                                        .font(.caption2)
                                        .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
                                }
                            }
                            .frame(width: QuickSnackLayout.snackCardWidth, height: QuickSnackLayout.snackCardHeight)
                            .snackCardBackground(cardStyle: cardStyle, colorScheme: colorScheme)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .transition(.opacity)
    }
}

struct SnackNameInputView: View {
    @Binding var snackName: String
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Snack Name")
                .font(.headline)
                .adaptiveForegroundColor()
            
            TextField("E.g., Apple Slices", text: $snackName)
                .textFieldStyle(.plain)
                .padding()
                .snackCardBackground(cardStyle: cardStyle, colorScheme: colorScheme)
                .foregroundColor(AppTheme.adaptiveEmphasis(for: colorScheme))
        }
    }
}

struct ServingsControlView: View {
    @Binding var servings: Int
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    let selectedTheme: AppTheme.ThemeType
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Servings")
                .font(.headline)
                .adaptiveForegroundColor()
            
            HStack(spacing: AppTheme.spacing16) {
                Button(action: {
                    if servings > QuickSnackLayout.minimumServings {
                        servings -= 1
                        HapticManager.shared.light()
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(servings > QuickSnackLayout.minimumServings ? AppTheme.accentColor(for: selectedTheme) : .gray)
                }
                .disabled(servings <= QuickSnackLayout.minimumServings)
                
                Text("\(servings)")
                    .font(.title)
                    .fontWeight(.bold)
                    .adaptiveForegroundColor()
                    .frame(minWidth: QuickSnackLayout.servingsDisplayMinWidth)
                
                Button(action: {
                    servings += 1
                    HapticManager.shared.light()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .snackCardBackground(cardStyle: cardStyle, colorScheme: colorScheme)
        }
    }
}

struct DietaryTagsDisplayView: View {
    let tags: [DietaryTag]
    let calories: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Dietary Info")
                .font(.headline)
                .adaptiveForegroundColor()
            
            VStack(spacing: AppTheme.spacing8) {
                if let calories = calories {
                    HStack {
                        Image(systemName: "flame.fill")
                        Text("\(calories) calories per serving")
                            .font(.subheadline)
                        Spacer()
                    }
                    .adaptiveForegroundColor(opacity: 0.9)
                }
                
                if !tags.isEmpty {
                    FlowLayout(spacing: AppTheme.spacing6) {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: AppTheme.spacing4) {
                                Text(tag.icon)
                                    .font(.caption2)
                                Text(tag.rawValue)
                                    .font(.caption2)
                            }
                            .padding(.horizontal, AppTheme.spacing8)
                            .padding(.vertical, AppTheme.spacing4)
                            .background(Color.white.opacity(AppTheme.overlayLightOpacity))
                            .adaptiveForegroundColor()
                            .cornerRadius(AppTheme.cornerRadius12)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(.ultraThinMaterial)
            }
        }
    }
}

struct AddButtonView: View {
    let isEnabled: Bool
    let selectedTheme: AppTheme.ThemeType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Add Snack")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                AppTheme.accentColor(for: selectedTheme)
                    .opacity(isEnabled ? 1.0 : 0.5)
            )
            .adaptiveForegroundColor()
            .cornerRadius(AppTheme.cornerRadius12)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Previews

struct QuickSnackSheet_Previews: PreviewProvider {
    static var previews: some View {
        QuickSnackSheet(
            recipes: .constant([]),
            onSnackAdded: { _ in }
        )
    }
}
