import SwiftUI

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
                cancelBar
                contentScrollView
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showEmojiPicker)
    }

    // MARK: - Private Views

    private var cancelBar: some View {
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
    }

    private var contentScrollView: some View {
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
                        onSnackSelected: viewModel.selectSnack,
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
                    action: addSnack
                )
                .padding(.horizontal)
                .padding(.top, QuickSnackLayout.addButtonTopPadding)
            }
            .padding(.bottom, QuickSnackLayout.scrollBottomPadding)
        }
    }

    // MARK: - Actions

    private func addSnack() {
        let snackRecipe = viewModel.createSnackRecipe()
        recipes.append(snackRecipe)
        onSnackAdded(snackRecipe)
        HapticManager.shared.success()
        dismiss()
    }
}

// MARK: - Header

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

// MARK: - Previews

struct QuickSnackSheet_Previews: PreviewProvider {
    static var previews: some View {
        QuickSnackSheet(
            recipes: .constant([]),
            onSnackAdded: { _ in }
        )
    }
}
