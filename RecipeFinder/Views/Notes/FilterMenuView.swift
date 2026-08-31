import SwiftUI

struct FilterMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted

    @Binding var selectedCategory: NoteCategory?
    @Binding var selectedTag: String?
    @Binding var showPinnedOnly: Bool
    @Binding var showCategoryExpanded: Bool

    let allTags: [String]
    let notesManager: NotesManager

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.spacing32) {
                        filterSection(title: "Quick Filters") {
                            Toggle(isOn: $showPinnedOnly) {
                                HStack {
                                    Image(systemName: "pin.fill")
                                        .adaptiveForegroundColor()
                                    Text("Show Pinned Only")
                                }
                            }
                            .tint(AppTheme.accentColor(for: selectedTheme))
                        }

                        filterSection(title: "Categories") {
                            ForEach(NoteCategory.allCases, id: \.self) { category in
                                categoryButton(category)
                            }
                        }

                        if !allTags.isEmpty {
                            filterSection(title: "Filter by Tag") {
                                FlowLayout(spacing: AppTheme.spacing8) {
                                    ForEach(allTags, id: \.self) { tag in
                                        tagButton(tag)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, AppTheme.spacing20)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .adaptiveForegroundColor()
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(
                AppTheme.accentColor(for: selectedTheme).opacity(0.8),
                for: .navigationBar
            )
        }
    }

    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text(title)
                .font(.headline)
                .adaptiveForegroundColor()
                .padding(.horizontal, AppTheme.spacing20)

            cardContainer {
                VStack(spacing: 0) {
                    content()
                }
                .padding()
            }
            .padding(.horizontal, AppTheme.spacing20)
        }
    }

    private func categoryButton(_ category: NoteCategory) -> some View {
        Button(action: {
            HapticManager.shared.selection()
            if selectedCategory == category {
                selectedCategory = nil
            } else {
                selectedCategory = category
            }
        }) {
            HStack(spacing: AppTheme.spacing12) {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                    .frame(width: AppTheme.iconSize32)

                Text(category.rawValue)
                    .font(.body)
                    .adaptiveForegroundColor()

                Spacer()

                if selectedCategory == category {
                    Image(systemName: "checkmark")
                        .adaptiveForegroundColor()
                        .fontWeight(.semibold)
                }

                Text("\(notesManager.notesCount(for: category))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, AppTheme.spacing8)
                    .padding(.vertical, AppTheme.spacing4)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(AppTheme.shadowLightOpacity))
                    )
            }
            .padding(.vertical, AppTheme.spacing8)
        }
    }

    private func tagButton(_ tag: String) -> some View {
        Button(action: {
            HapticManager.shared.selection()
            if selectedTag == tag {
                selectedTag = nil
            } else {
                selectedTag = tag
            }
        }) {
                Text("#\(tag)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(selectedTag == tag ? .white : AppTheme.textColor(for: colorScheme))
                .padding(.horizontal, AppTheme.spacing12)
                .padding(.vertical, AppTheme.spacing6)
                .background(
                    Capsule()
                        .fill(selectedTag == tag ? AppTheme.accentColor(for: selectedTheme) : Color.secondary.opacity(0.1))
                )
        }
    }

    private func cardContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        Group {
            if cardStyle == .solid {
                content()
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                            .fill(colorScheme == .dark ? Color(white: AppTheme.cardDarkOpacity) : .white)
                    )
            } else {
                content()
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                            .fill(.ultraThinMaterial)
                    )
            }
        }
    }
}
