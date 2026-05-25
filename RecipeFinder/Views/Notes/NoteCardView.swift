import SwiftUI

struct NoteCardView: View {
    let note: NoteModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    var onPin: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            HStack {
                HStack(spacing: AppTheme.spacing6) {
                    Image(systemName: note.category.icon)
                        .font(.caption)
                    Text(note.category.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(AppTheme.accentColor(for: appTheme))
                .padding(.horizontal, AppTheme.spacing10)
                .padding(.vertical, AppTheme.spacing4)
                .background(
                    Capsule()
                        .fill(AppTheme.accentColor(for: appTheme).opacity(0.15))
                )
                
                Spacer()
                
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.accentColor(for: appTheme))
                }
                
                Text(formatDate(note.modifiedDate))
                    .font(.caption2)
                    .foregroundColor(AppTheme.adaptiveSecondaryIndicator(for: colorScheme))
                
                if let onDelete {
                    Menu {
                        if let onPin {
                            Button(action: onPin) {
                                Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
                            }
                            Divider()
                        }
                        Button(role: .destructive, action: onDelete) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, AppTheme.spacing8)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if !note.title.isEmpty {
                Text(note.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .adaptiveForegroundColor()
                    .lineLimit(2)
            }
            
            if !note.content.isEmpty {
                Text(note.content)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
                    .lineLimit(3)
            }
            
            if !note.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.spacing8) {
                        ForEach(note.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
                                .padding(.horizontal, AppTheme.spacing8)
                                .padding(.vertical, AppTheme.spacing4)
                                .background(
                                    Capsule()
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity))
                                )
                        }
                    }
                }
            }
        }
        .padding(AppTheme.spacing16)
        .background(
            Group {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                        .fill(colorScheme == .dark ? Color(white: AppTheme.cardDarkOpacity) : .white)
                        .shadow(color: .black.opacity(AppTheme.shadowLightOpacity), radius: 4, x: 0, y: 2)
                } else {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(AppTheme.shadowLightOpacity), radius: 4, x: 0, y: 2)
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
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
    VStack(spacing: AppTheme.spacing16) {
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
    .background(AppTheme.secondaryText.opacity(0.2))
    .environment(\.appTheme, .teal)
}
