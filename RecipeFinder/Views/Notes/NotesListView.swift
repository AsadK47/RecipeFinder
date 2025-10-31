import SwiftUI

struct NotesListView: View {
    @StateObject private var notesManager = NotesManager()
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    @State private var searchText = ""
    @State private var selectedCategory: NoteCategory?
    @State private var selectedTag: String?
    @State private var showNewNoteSheet = false
    @State private var selectedNote: NoteModel?
    @State private var showPinnedOnly = false
    @State private var showCategoryExpanded = false
    @State private var showFilterMenu = false
    
    // All unique tags from all notes
    var allTags: [String] {
        Array(Set(notesManager.notes.flatMap { $0.tags })).sorted()
    }
    
    var filteredNotes: [NoteModel] {
        var filtered = notesManager.notes
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.matches(searchText: searchText) }
        }
        
        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filter by tag
        if let tag = selectedTag {
            filtered = filtered.filter { $0.tags.contains(tag) }
        }
        
        // Filter by pinned
        if showPinnedOnly {
            filtered = filtered.filter { $0.isPinned }
        }
        
        return filtered
    }
    
    var activeFilterCount: Int {
        var count = 0
        if selectedCategory != nil { count += 1 }
        if selectedTag != nil { count += 1 }
        if showPinnedOnly { count += 1 }
        return count
    }
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header - Blended design like RecipeSearchView
                VStack(spacing: 12) {
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            // Back button (left side)
                            Button(action: {
                                // This will use the environment's dismiss if in a sheet/navigation
                                HapticManager.shared.light()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                            }
                            .opacity(0) // Hidden but maintains layout
                            
                            Spacer(minLength: 8)
                            
                            Text("Notes")
                                .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            
                            Spacer(minLength: 8)
                                
                                // Right menu - burger menu like RecipeSearchView
                                Menu {
                                    // Filter option
                                    Button(
                                        action: {
                                            HapticManager.shared.light()
                                            showFilterMenu.toggle()
                                        },
                                        label: {
                                            Label(activeFilterCount > 0 ? "Filters (\(activeFilterCount))" : "Filters", systemImage: "line.3.horizontal.decrease.circle")
                                        }
                                    )
                                    
                                    Divider()
                                    
                                    // New Note option
                                    Button(
                                        action: {
                                            HapticManager.shared.selection()
                                            showNewNoteSheet = true
                                        },
                                        label: {
                                            Label("New Note", systemImage: "square.and.pencil")
                                        }
                                    )
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
                        
                        // Search Bar
                        ModernSearchBar(text: $searchText, placeholder: "Search notes...")
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)
                    }
                    
                    // Active filters chips
                    if activeFilterCount > 0 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                if showPinnedOnly {
                                    FilterChip(label: "Pinned", icon: "pin.fill") {
                                        HapticManager.shared.light()
                                        showPinnedOnly = false
                                    }
                                }
                                
                                if let category = selectedCategory {
                                    FilterChip(label: category.rawValue, icon: category.icon) {
                                        HapticManager.shared.light()
                                        selectedCategory = nil
                                    }
                                }
                                
                                if let tag = selectedTag {
                                    FilterChip(label: "#\(tag)", icon: "tag.fill") {
                                        HapticManager.shared.light()
                                        selectedTag = nil
                                    }
                                }
                                
                                Button(action: {
                                    HapticManager.shared.light()
                                    selectedCategory = nil
                                    selectedTag = nil
                                    showPinnedOnly = false
                                }, label: {
                                    Text("Clear All")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color.red.opacity(0.8))
                                        )
                                })
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                    }
                    
                    // Notes List
                    if filteredNotes.isEmpty {
                        emptyStateView
                    } else {
                        notesList
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showNewNoteSheet) {
            NoteEditorView(note: nil) { note in
                notesManager.addNote(note)
            }
        }
        .sheet(item: $selectedNote) { note in
            NoteEditorView(note: note) { updatedNote in
                notesManager.updateNote(updatedNote)
            }
        }
        .sheet(isPresented: $showFilterMenu) {
            FilterMenuView(
                selectedCategory: $selectedCategory,
                selectedTag: $selectedTag,
                showPinnedOnly: $showPinnedOnly,
                showCategoryExpanded: $showCategoryExpanded,
                allTags: allTags,
                notesManager: notesManager
            )
        }
    }
    
    // MARK: - Notes List
    private var notesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredNotes) { note in
                    NoteCardView(note: note)
                        .onTapGesture {
                            HapticManager.shared.light()
                            selectedNote = note
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.shared.light()
                                withAnimation {
                                    notesManager.deleteNote(note)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                HapticManager.shared.light()
                                notesManager.togglePin(note)
                            } label: {
                                Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
                            }
                            .tint(AppTheme.accentColor(for: appTheme))
                        }
                        .contextMenu {
                            Button(action: {
                                notesManager.togglePin(note)
                            }) {
                                Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
                            }
                            
                            Button(role: .destructive, action: {
                                HapticManager.shared.light()
                                notesManager.deleteNote(note)
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.3))
            
            Text(searchText.isEmpty ? "No Notes Yet" : "No Matching Notes")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(searchText.isEmpty ? "Tap the menu to create your first note" : "Try a different search")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

// MARK: - Filter Menu View
struct FilterMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) var appTheme
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
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Pinned Filter
                        filterSection(title: "Quick Filters") {
                            Toggle(isOn: $showPinnedOnly) {
                                HStack {
                                    Image(systemName: "pin.fill")
                                        .foregroundColor(AppTheme.accentColor(for: appTheme))
                                    Text("Show Pinned Only")
                                }
                            }
                            .tint(AppTheme.accentColor(for: appTheme))
                        }
                        
                        // Top 3 Categories
                        filterSection(title: "Categories") {
                            ForEach(NoteCategory.topCategories, id: \.self) { category in
                                categoryButton(category)
                            }
                        }
                        
                        // More Categories (Collapsible)
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: {
                                HapticManager.shared.light()
                                withAnimation {
                                    showCategoryExpanded.toggle()
                                }
                            }) {
                                HStack {
                                    Text("More Categories")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: showCategoryExpanded ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            
                            if showCategoryExpanded {
                                cardContainer {
                                    VStack(spacing: 0) {
                                        ForEach(NoteCategory.moreCategories, id: \.self) { category in
                                            categoryButton(category)
                                            
                                            if category != NoteCategory.moreCategories.last {
                                                Divider()
                                                    .padding(.leading, 44)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Tags Filter
                        if !allTags.isEmpty {
                            filterSection(title: "Filter by Tag") {
                                FlowLayout(spacing: 8) {
                                    ForEach(allTags, id: \.self) { tag in
                                        tagButton(tag)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(
                AppTheme.accentColor(for: appTheme).opacity(0.8),
                for: .navigationBar
            )
        }
    }
    
    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            cardContainer {
                VStack(spacing: 0) {
                    content()
                }
                .padding()
            }
            .padding(.horizontal, 20)
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
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(AppTheme.accentColor(for: appTheme))
                    .frame(width: 32)
                
                Text(category.rawValue)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if selectedCategory == category {
                    Image(systemName: "checkmark")
                        .foregroundColor(AppTheme.accentColor(for: appTheme))
                        .fontWeight(.semibold)
                }
                
                Text("\(notesManager.notesCount(for: category))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.1))
                    )
            }
            .padding(.vertical, 8)
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
                .foregroundColor(selectedTag == tag ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(selectedTag == tag ? AppTheme.accentColor(for: appTheme) : Color.secondary.opacity(0.1))
                )
        }
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
}

#Preview {
    NotesListView()
        .environment(\.appTheme, .teal)
}
