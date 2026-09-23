import SwiftUI

// MARK: - QuickSnackSheet

struct QuickSnackSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var recipes: [RecipeModel]
    let onSnackAdded: (RecipeModel) -> Void

    @State private var searchText = ""
    @State private var selectedEmoji = "🍿"
    @State private var servings = 1

    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) var colorScheme

    private var filteredSnacks: [SnackItem] {
        guard !searchText.isEmpty else { return SnackDatabase.allSnacks }
        return SnackDatabase.allSnacks.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var canAdd: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: Header
                ZStack {
                    Text("Add Snack")
                        .font(.title.bold())
                        .adaptiveForegroundColor()
                        .frame(maxWidth: .infinity)

                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.spacing20)
                .padding(.top, AppTheme.spacing32)
                .padding(.bottom, AppTheme.spacing24)

                // MARK: Search / Name Field
                HStack(spacing: AppTheme.spacing12) {
                    Text(selectedEmoji)
                        .font(.title2)
                        .animation(.default, value: selectedEmoji)

                    TextField("Search or type a snack...", text: $searchText)
                        .autocorrectionDisabled()
                        .onChange(of: searchText) { _, newValue in
                            let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                            let exactMatch = SnackDatabase.allSnacks.first {
                                $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame
                            }
                            selectedEmoji = exactMatch?.emoji ?? emojiForName(trimmed)
                        }

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            selectedEmoji = "🍿"
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .adaptiveSecondaryForeground()
                        }
                    }
                }
                .padding(AppTheme.spacing14)
                .appCard(cornerRadius: AppTheme.cornerRadius12)
                .padding(.horizontal, AppTheme.spacing20)
                .padding(.bottom, AppTheme.spacing16)

                // MARK: Snack List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredSnacks) { snack in
                            Button {
                                searchText = snack.name
                                selectedEmoji = snack.emoji
                                HapticManager.shared.light()
                            } label: {
                                HStack(spacing: AppTheme.spacing14) {
                                    Text(snack.emoji)
                                        .font(.title3)
                                        .frame(width: AppTheme.iconSize32)

                                    VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                                        Text(snack.name)
                                            .font(.body)
                                            .adaptiveForegroundColor()
                                        if let cal = snack.calories {
                                            Text("\(cal) cal")
                                                .font(.caption)
                                                .adaptiveSecondaryForeground()
                                        }
                                    }

                                    Spacer()

                                    if searchText.localizedCaseInsensitiveCompare(snack.name) == .orderedSame {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(AppTheme.accentColor(for: selectedTheme))
                                            .font(.callout.weight(.semibold))
                                    }
                                }
                                .padding(.horizontal, AppTheme.spacing20)
                                .padding(.vertical, AppTheme.spacing12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if snack.id != filteredSnacks.last?.id {
                                Divider()
                                    .padding(.leading, AppTheme.spacing20 + AppTheme.iconSize32 + AppTheme.spacing14)
                            }
                        }

                        // Custom row when nothing in DB matches
                        if !searchText.isEmpty && filteredSnacks.isEmpty {
                            HStack(spacing: AppTheme.spacing14) {
                                Text(selectedEmoji)
                                    .font(.title3)
                                    .frame(width: AppTheme.iconSize32)
                                Text(searchText)
                                    .font(.body)
                                    .adaptiveForegroundColor()
                                Spacer()
                                Text("Custom")
                                    .font(.caption)
                                    .adaptiveSecondaryForeground()
                            }
                            .padding(.horizontal, AppTheme.spacing20)
                            .padding(.vertical, AppTheme.spacing12)
                        }
                    }
                    .padding(.bottom, 90)
                }
            }

            // MARK: Bottom Bar
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: AppTheme.spacing16) {

                    HStack(spacing: AppTheme.spacing8) {
                        Button {
                            if servings > 1 {
                                servings -= 1
                                HapticManager.shared.light()
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(servings > 1
                                    ? AppTheme.accentColor(for: selectedTheme)
                                    : .secondary)
                        }
                        .disabled(servings <= 1)

                        Text("\(servings)")
                            .font(.headline)
                            .frame(minWidth: 24)
                            .adaptiveForegroundColor()

                        Button {
                            servings += 1
                            HapticManager.shared.light()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(AppTheme.accentColor(for: selectedTheme))
                        }
                    }

                    Button(action: addSnack) {
                        Text(canAdd ? "Add \(searchText)" : "Add Snack")
                            .font(.headline)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.spacing14)
                            .background(AppTheme.accentColor(for: selectedTheme)
                                .opacity(canAdd ? 1 : 0.4))
                            .adaptiveForegroundColor()
                            .cornerRadius(AppTheme.cornerRadius12)
                    }
                    .disabled(!canAdd)
                }
                .padding(.horizontal, AppTheme.spacing20)
                .padding(.vertical, AppTheme.spacing12)
                .background(.ultraThinMaterial)
            }
        }
    }

    // MARK: - Actions

    private func addSnack() {
        let name = searchText.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let recipe = RecipeModel(
            name: name,
            ingredients: [],
            instructions: "Enjoy your \(name)!",
            prepTime: "0 min",
            category: "Snack",
            difficulty: 1,
            currentServings: servings,
            baseServings: servings,
            defaultServings: servings,
            isFavorite: false,
            imageName: nil,
            notes: "\(selectedEmoji) Quick snack"
        )
        recipes.append(recipe)
        onSnackAdded(recipe)
        HapticManager.shared.success()
        dismiss()
    }

    // MARK: - Emoji Detection

    private func emojiForName(_ name: String) -> String {
        let lower = name.lowercased()
        let keywords: [(String, String)] = [
            ("apple", "\u{1F34E}"), ("banana", "\u{1F34C}"), ("orange", "\u{1F34A}"), ("grape", "\u{1F347}"),
            ("strawberr", "\u{1F353}"), ("blueberr", "\u{1FAD0}"), ("cherry", "\u{1F352}"), ("peach", "\u{1F351}"),
            ("kiwi", "\u{1F95D}"), ("avocado", "\u{1F951}"), ("mango", "\u{1F96D}"),
            ("carrot", "\u{1F955}"), ("cucumber", "\u{1F952}"), ("broccoli", "\u{1F966}"),
            ("corn", "\u{1F33D}"), ("tomato", "\u{1F345}"), ("potato", "\u{1F954}"), ("pepper", "\u{1FAD1}"),
            ("nut", "\u{1F95C}"), ("almond", "\u{1F95C}"), ("walnut", "\u{1F95C}"), ("peanut", "\u{1F95C}"),
            ("cheese", "\u{1F9C0}"), ("egg", "\u{1F95A}"), ("yogurt", "\u{1F95B}"), ("milk", "\u{1F95B}"),
            ("cookie", "\u{1F36A}"), ("cake", "\u{1F370}"), ("muffin", "\u{1F9C1}"), ("donut", "\u{1F369}"),
            ("chocolate", "\u{1F36B}"), ("candy", "\u{1F36C}"), ("ice cream", "\u{1F366}"), ("lolly", "\u{1F36D}"),
            ("chip", "\u{1F961}"), ("pretzel", "\u{1F968}"), ("cracker", "\u{1F35E}"), ("popcorn", "\u{1F37F}"),
            ("granola", "\u{1F33E}"), ("oat", "\u{1F33E}"), ("bar", "\u{1F36B}"),
            ("coffee", "\u{2615}"), ("tea", "\u{1F375}"), ("juice", "\u{1F9C3}"), ("water", "\u{1F4A7}"), ("soda", "\u{1F964}"),
            ("smoothie", "\u{1F964}"), ("shake", "\u{1F964}"), ("protein", "\u{1F4AA}"),
            ("sandwich", "\u{1F96A}"), ("wrap", "\u{1F32F}"), ("salad", "\u{1F957}"),
            ("pizza", "\u{1F355}"), ("sushi", "\u{1F371}"), ("rice", "\u{1F35A}"),
            ("fruit", "\u{1F353}"), ("veggie", "\u{1F966}"), ("vegetable", "\u{1F966}"),
        ]
        for (keyword, emoji) in keywords {
            if lower.contains(keyword) { return emoji }
        }
        return "\u{1F37F}"
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
