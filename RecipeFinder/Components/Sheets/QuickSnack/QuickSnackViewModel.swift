import Foundation

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
