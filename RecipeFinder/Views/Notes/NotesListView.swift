import SwiftUI

struct NotesListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var notesManager = NotesManager.shared
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
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
    
    @State private var cachedTags: [String] = []
    @State private var lastNotesCount: Int = 0
    
    var allTags: [String] {
        if notesManager.notes.count != lastNotesCount {
            return Array(Set(notesManager.notes.flatMap { $0.tags })).sorted()
        }
        return cachedTags
    }
    
    var filteredNotes: [NoteModel] {
        var filtered = notesManager.notes
        
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.matches(searchText: searchText) }
        }
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        if let tag = selectedTag {
            filtered = filtered.filter { $0.tags.contains(tag) }
        }
        
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
        NavigationStack {
            ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: AppTheme.spacing12) {
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            HStack(spacing: 0) {
                                Button(action: {
                                    HapticManager.shared.light()
                                    dismiss()
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.title3)
                                        .adaptiveForegroundColor()
                                        .frame(width: 44, height: 44)
                                }
                                Spacer()
                            }
                            .frame(width: 88)
                            
                            Spacer()
                            
                            Text("Notes")
                                .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                                .adaptiveForegroundColor()
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            
                            Spacer()
                            
                            HStack(spacing: 0) {
                                Menu {
                                    Button(
                                        action: {
                                            HapticManager.shared.light()
                                            showFilterMenu.toggle()
                                        },
                                        label: {
                                            Label(activeFilterCount > 0 ? "Filters (\(activeFilterCount))" : "Filters", systemImage: "line.3.horizontal.decrease.circle")
                                        }
                                    )
                                } label: {
                                    Image(systemName: "line.3.horizontal")
                                        .adaptiveForegroundColor()
                                        .font(.title3)
                                }
                                .frame(width: 44, height: 44)
                                
                                Button(action: {
                                    HapticManager.shared.medium()
                                    showNewNoteSheet = true
                                }) {
                                    Image(systemName: "plus")
                                        .adaptiveForegroundColor()
                                        .font(.title3)
                                }
                                .frame(width: 44, height: 44)
                            }
                            .frame(width: 88)
                        }
                    }
                    .frame(height: 44)
                    
                    ModernSearchBar(text: $searchText, placeholder: "Search Notes...")
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                if activeFilterCount > 0 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppTheme.spacing8) {
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
                                    .adaptiveForegroundColor()
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
                }
                
                if filteredNotes.isEmpty {
                    emptyStateView
                } else {
                    notesList
                }
            }
        }
        .navigationBarHidden(true)
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
        .onAppear {
            updateTagCache()
        }
        .onChange(of: notesManager.notes.count) { _, _ in
            updateTagCache()
        }
        }
    }
    
    private func updateTagCache() {
        cachedTags = Array(Set(notesManager.notes.flatMap { $0.tags })).sorted()
        lastNotesCount = notesManager.notes.count
    }
    
    private var notesList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.spacing12) {
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
                            .tint(AppTheme.accentColor(for: selectedTheme))
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
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.spacing24) {
            Image(systemName: searchText.isEmpty ? "note.text" : "magnifyingglass")
                .font(.system(size: AppTheme.fontSize60))
                .adaptiveForegroundColor(opacity: 0.4)
            
            Text(searchText.isEmpty ? "No Notes Yet" : "No Matching Notes")
                .font(.title2)
                .fontWeight(.bold)
                .adaptiveForegroundColor()
            
            Text(searchText.isEmpty ? "Tap the + button at the top to create your first note" : "Try a different search")
                .font(.subheadline)
                .adaptiveForegroundColor(opacity: 0.7)
                .multilineTextAlignment(.center)
            
            if searchText.isEmpty {
                VStack(spacing: AppTheme.spacing12) {
                    Image(systemName: "arrow.up")
                        .font(.title)
                        .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                    
                    Text("Tap the + icon above")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                }
                .padding(.top, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppTheme.spacing48)
    }
}

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
            HStack(spacing: AppTheme.spacing12) {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                    .frame(width: 32)
                
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
                .foregroundColor(selectedTag == tag ? .white : AppTheme.textColor(for: colorScheme))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
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
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(white: AppTheme.cardDarkOpacity) : .white)
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
