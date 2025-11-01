import SwiftUI

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    let note: NoteModel?
    let onSave: (NoteModel) -> Void
    
    @State private var title: String
    @State private var content: String
    @State private var selectedCategory: NoteCategory
    @State private var tags: [String]
    @State private var currentTag: String = ""
    @State private var isPinned: Bool
    @State private var showMoreCategories: Bool = false
    @State private var showValidationError: Bool = false
    
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isContentFocused: Bool
    
    init(note: NoteModel?, onSave: @escaping (NoteModel) -> Void) {
        self.note = note
        self.onSave = onSave
        
        _title = State(initialValue: note?.title ?? "")
        _content = State(initialValue: note?.content ?? "")
        _selectedCategory = State(initialValue: note?.category ?? .general)
        _tags = State(initialValue: note?.tags ?? [])
        _isPinned = State(initialValue: note?.isPinned ?? false)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Title Input
                        titleSection
                        
                        // Content Input
                        contentSection
                        
                        // Category Picker
                        categorySection
                        
                        // Tags Input
                        tagsSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle(note == nil ? "New Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Pin Toggle
                        Button(action: {
                            HapticManager.shared.light()
                            isPinned.toggle()
                        }) {
                            Image(systemName: isPinned ? "pin.fill" : "pin")
                                .foregroundColor(isPinned ? AppTheme.accentColor(for: appTheme) : .white)
                        }
                        
                        // Save Button
                        Button("Save") {
                            if canSave {
                                saveNote()
                            } else {
                                HapticManager.shared.warning()
                                showValidationError = true
                            }
                        }
                        .foregroundColor(canSave ? .white : .white.opacity(0.5))
                        .fontWeight(.semibold)
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(
                AppTheme.accentColor(for: appTheme).opacity(0.8),
                for: .navigationBar
            )
            .alert("Cannot Save Empty Note", isPresented: $showValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please add a title or content before saving your note.")
            }
        }
    }
    
    // MARK: - Sections
    
    private var titleSection: some View {
        cardContainer {
            TextField("Note Title", text: $title, axis: .vertical)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .focused($isTitleFocused)
                .lineLimit(2...3)
                .padding()
        }
    }
    
    private var contentSection: some View {
        cardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("CONTENT")
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                    .textCase(.uppercase)
                
                TextField("Write your note here...", text: $content, axis: .vertical)
                    .font(.body)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .focused($isContentFocused)
                    .lineLimit(10...30)
            }
            .padding()
        }
    }
    
    private var categorySection: some View {
        cardContainer {
            VStack(alignment: .leading, spacing: 16) {
                Text("CATEGORY")
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                    .textCase(.uppercase)
                
                // Top 3 Categories (prominent)
                VStack(spacing: 12) {
                    ForEach(NoteCategory.topCategories, id: \.self) { category in
                        categoryRow(category)
                    }
                }
                
                Divider()
                
                // More Categories (collapsible)
                VStack(alignment: .leading, spacing: 12) {
                    Button(action: {
                        HapticManager.shared.light()
                        withAnimation {
                            showMoreCategories.toggle()
                        }
                    }) {
                        HStack {
                            Text("More Categories")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Spacer()
                            
                            Image(systemName: showMoreCategories ? "chevron.up" : "chevron.down")
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                                .font(.caption)
                        }
                    }
                    
                    if showMoreCategories {
                        VStack(spacing: 12) {
                            ForEach(NoteCategory.moreCategories, id: \.self) { category in
                                categoryRow(category)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .padding()
        }
    }
    
    private func categoryRow(_ category: NoteCategory) -> some View {
        let isSelected = selectedCategory == category
        
        return Button(action: {
            HapticManager.shared.selection()
            selectedCategory = category
        }) {
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : AppTheme.accentColor(for: appTheme))
                    .frame(width: 32)
                
                Text(category.rawValue)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : (colorScheme == .dark ? .white : .black))
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppTheme.accentColor(for: appTheme) : Color.secondary.opacity(0.1))
            )
        }
    }
    
    private var tagsSection: some View {
        cardContainer {
            VStack(alignment: .leading, spacing: 12) {
                Text("TAGS")
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                    .textCase(.uppercase)
                
                // Tag input
                HStack {
                    TextField("Add tag...", text: $currentTag)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .onSubmit {
                            addTag()
                        }
                    
                    if !currentTag.isEmpty {
                        Button(action: addTag) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(AppTheme.accentColor(for: appTheme))
                        }
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                )
                
                // Tag list
                if !tags.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            tagChip(tag)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func tagChip(_ tag: String) -> some View {
        HStack(spacing: 6) {
            Text("#\(tag)")
                .font(.subheadline)
            
            Button(action: {
                HapticManager.shared.light()
                tags.removeAll { $0 == tag }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(AppTheme.accentColor(for: appTheme))
        )
    }
    
    private func cardContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        Group {
            if cardStyle == .solid {
                content()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(white: 0.15) : .white)
                    )
            } else {
                content()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
            }
        }
    }
    
    // MARK: - Actions
    
    private func addTag() {
        let trimmed = currentTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        
        HapticManager.shared.light()
        tags.append(trimmed)
        currentTag = ""
    }
    
    private func saveNote() {
        HapticManager.shared.success()
        
        let newNote = NoteModel(
            id: note?.id ?? UUID(),
            title: title,
            content: content,
            category: selectedCategory,
            tags: tags,
            isPinned: isPinned,
            createdDate: note?.createdDate ?? Date(),
            modifiedDate: Date(),
            linkedRecipeID: note?.linkedRecipeID
        )
        
        onSave(newNote)
        dismiss()
    }
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    NoteEditorView(note: nil) { _ in }
        .environment(\.appTheme, .teal)
}
