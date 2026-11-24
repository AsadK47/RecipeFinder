import SwiftUI

/// A night in Plan's week with no dinner: from tonight on, a tap plans one; a missed night is history.
struct WeekDinnerEmptyTile<DayLabel: View>: View {
    let night: WeekDinners.Night
    let spokenDay: String
    let dayLabel: DayLabel
    let onPlan: (Date) -> Void

    @ScaledMetric(relativeTo: .body) private var photoHeight: CGFloat = 96

    var body: some View {
        Button {
            HapticManager.shared.light()
            onPlan(night.date)
        } label: {
            content
        }
        .buttonStyle(.plain)
        .disabled(night.isPast)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(spokenDay), no dinner planned")
        .accessibilityHint(night.isPast ? "" : "Plans dinner for this night")
        .accessibilityAddTraits(.isButton)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .strokeBorder(AppTheme.subtleStroke, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                Image(systemName: night.isPast ? "moon.zzz" : "plus")
                    .font(.title2.weight(.semibold))
                    .adaptiveSecondaryForeground()
            }
            // A missed night is history, not a call to action: half height so the nights ahead lead.
            .frame(height: night.isPast ? photoHeight / 2 : photoHeight)
            dayLabel
            Text(night.isPast ? "No dinner planned" : "Plan dinner")
                .font(.subheadline)
                .adaptiveSecondaryForeground()
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppTheme.spacing8)
        .frame(maxHeight: .infinity, alignment: .top)
        .appCard()
        .contentShape(Rectangle())
    }
}
