import SwiftUI

struct NoteCardView: View {
    let note: NoteModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with category and pin
            HStack {
                // Category badge
                HStack(spacing: 6) {
                    Image(systemName: note.category.icon)
                        .font(.caption)
                    Text(note.category.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(AppTheme.accentColor(for: appTheme))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(AppTheme.accentColor(for: appTheme).opacity(0.15))
                )
                
                Spacer()
                
                // Pin indicator
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.accentColor(for: appTheme))
                }
                
                // Date
                Text(formatDate(note.modifiedDate))
                    .font(.caption2)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
            }
            
            // Title
            if !note.title.isEmpty {
                Text(note.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .lineLimit(2)
            }
            
            // Content preview
            if !note.content.isEmpty {
                Text(note.content)
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                    .lineLimit(3)
            }
            
            // Tags
            if !note.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(note.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                                )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            Group {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color(white: 0.15) : .white)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppTheme.accentColor(for: appTheme).opacity(0.3), lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    VStack(spacing: 16) {
        NoteCardView(note: NoteModel(
            title: "Pasta Recipe Ideas",
            content: "Try making carbonara with pancetta instead of bacon. Add extra parmesan for creaminess.",
            category: .recipe,
            tags: ["pasta", "italian"],
            isPinned: true
        ))
        
        NoteCardView(note: NoteModel(
            title: "Grocery List",
            content: "Don't forget to buy tomatoes, basil, mozzarella, and olive oil for the caprese salad.",
            category: .shopping,
            tags: ["urgent"],
            isPinned: false
        ))
    }
    .padding()
    .background(Color.gray.opacity(0.2))
    .environment(\.appTheme, .teal)
}
