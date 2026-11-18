import SwiftUI

/// Me's "Your cooking story": a timeline of the cook's moments, newest first — first cook, meal and streak milestones,
/// badges. The newest few show; "Show all" opens the rest in place. A badge moment opens that badge on the shelf.
struct CookingStoryCard: View {
    let moments: [StoryMoment]
    /// "14 meals cooked in 2026"; nil hides the line.
    let yearLine: String?
    let onOpenBadge: (String) -> Void

    @State private var showsAll = false

    private var visible: [StoryMoment] {
        showsAll ? moments : Array(moments.prefix(CookingStory.previewCount))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                Label("Your cooking story", systemImage: "book.pages")
                    .font(.headline)
                    .adaptiveForegroundColor()
                    .accessibilityAddTraits(.isHeader)
                if let yearLine {
                    Text(yearLine)
                        .font(.subheadline.weight(.semibold))
                        .adaptiveSecondaryForeground()
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("story.year")
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(visible.enumerated()), id: \.element.id) { index, moment in
                    row(moment, isLast: index == visible.count - 1)
                }
            }

            if moments.count > CookingStory.previewCount {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { showsAll.toggle() }
                } label: {
                    Text(showsAll ? "Show less" : "Show all \(moments.count) moments")
                        .font(.subheadline.weight(.semibold))
                        .adaptiveForegroundColor()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.spacing8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("story.showAll")
            }
        }
        .padding(AppTheme.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(cornerRadius: AppTheme.cornerRadius16)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("story.card")
    }

    @ViewBuilder
    private func row(_ moment: StoryMoment, isLast: Bool) -> some View {
        if let badgeID = moment.badgeID {
            Button { onOpenBadge(badgeID) } label: {
                StoryRow(moment: moment, isLast: isLast, opens: true)
            }
            .buttonStyle(.plain)
            .storyRowAccessibility(moment)
            .accessibilityHint("Opens the badge")
        } else {
            StoryRow(moment: moment, isLast: isLast, opens: false)
                .accessibilityElement(children: .ignore)
                .storyRowAccessibility(moment)
        }
    }
}

/// One moment: a dot on the timeline's line, the title, and its date + detail.
private struct StoryRow: View {
    let moment: StoryMoment
    let isLast: Bool
    let opens: Bool

    private let iconSize: CGFloat = 32

    private var tint: Color {
        moment.colorName.map(Badge.color(for:)) ?? AppTheme.accentColor
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacing12) {
            IconBadge(systemName: moment.icon, tint: tint, diameter: iconSize)
            VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                Text(moment.title)
                    .font(.subheadline.weight(.semibold))
                    .adaptiveForegroundColor()
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(moment.date.formatted(date: .abbreviated, time: .omitted)) · \(moment.detail)")
                    .font(.caption)
                    .adaptiveSecondaryForeground()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, AppTheme.spacing4)
            .padding(.bottom, isLast ? 0 : AppTheme.spacing16)
            Spacer(minLength: AppTheme.spacing8)
            if opens {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .adaptiveSecondaryForeground()
                    .padding(.top, AppTheme.spacing8)
            }
        }
        // The timeline's line runs from under this dot to the next one; a background takes the row's full height,
        // which a flexible shape inside the scroll view wouldn't.
        .background(alignment: .topLeading) {
            if !isLast {
                Rectangle()
                    .fill(AppTheme.subtleStroke)
                    .frame(width: 2)
                    .padding(.top, iconSize)
                    .padding(.leading, iconSize / 2 - 1)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
    }
}

private extension View {
    func storyRowAccessibility(_ moment: StoryMoment) -> some View {
        accessibilityLabel(moment.title)
            .accessibilityValue("\(moment.date.formatted(date: .long, time: .omitted)), \(moment.detail)")
            .accessibilityIdentifier("story.row.\(moment.id)")
    }
}
