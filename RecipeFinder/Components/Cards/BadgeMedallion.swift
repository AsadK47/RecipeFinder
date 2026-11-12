import SwiftUI

/// The large badge medallion shared by the full-screen pager and the earn reveal. Earned: tinted disc + coloured
/// icon + glow. Locked: grey silhouette with a progress ring. An optional shine band sits over earned badges.
struct BadgeMedallion: View {
    let icon: String
    let color: Color
    let isUnlocked: Bool
    /// Share done (0…1) toward a locked threshold badge; nil hides the ring.
    var progress: Double?
    /// Shine position per axis (-1…1 sits on the disc; beyond that slides off it). nil = no shine.
    var shine: CGSize?

    init(icon: String, color: Color, isUnlocked: Bool, progress: Double? = nil, shine: CGSize? = nil) {
        self.icon = icon
        self.color = color
        self.isUnlocked = isUnlocked
        self.progress = progress
        self.shine = shine
    }

    init(badge: Badge, progress: Double? = nil, shine: CGSize? = nil) {
        self.init(
            icon: badge.icon,
            color: Badge.color(for: badge.color),
            isUnlocked: badge.isUnlocked,
            progress: badge.isUnlocked ? nil : progress,
            shine: shine
        )
    }

    private let discSize = AppTheme.width140
    private let ringSize: CGFloat = 156

    var body: some View {
        ZStack {
            Circle()
                .fill(isUnlocked ? color.opacity(AppTheme.cardDarkMediumOpacity) : AppTheme.subtleFill)
                .frame(width: discSize, height: discSize)
            if !isUnlocked, let progress {
                Circle()
                    .stroke(AppTheme.subtleStroke, lineWidth: 6)
                    .frame(width: ringSize, height: ringSize)
                Circle()
                    .trim(from: 0, to: max(0.02, min(progress, 1)))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: ringSize, height: ringSize)
            }
            Image(systemName: icon)
                .font(.system(size: AppTheme.fontSize60))
                .foregroundStyle(isUnlocked ? color : AppTheme.secondaryText.opacity(AppTheme.glassLightOpacity))
            if isUnlocked, let shine {
                shineBand(shine)
            }
        }
        .frame(width: 170, height: 170)
        .shadow(color: isUnlocked ? color.opacity(AppTheme.shadowDarkOpacity) : .clear, radius: 20)
        .accessibilityHidden(true)
    }

    /// A diagonal white band clipped to the disc; `offset` slides it across.
    private func shineBand(_ offset: CGSize) -> some View {
        let centreX = 0.5 + offset.width * 0.5
        let centreY = 0.5 + offset.height * 0.5
        return Circle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0), location: 0),
                        .init(color: .white.opacity(0.45), location: 0.5),
                        .init(color: .white.opacity(0), location: 1)
                    ],
                    startPoint: UnitPoint(x: centreX - 0.3, y: centreY - 0.3),
                    endPoint: UnitPoint(x: centreX + 0.3, y: centreY + 0.3)
                )
            )
            .frame(width: discSize, height: discSize)
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
    }
}

#Preview {
    VStack {
        BadgeMedallion(icon: "flame.fill", color: .orange, isUnlocked: true, shine: .zero)
        BadgeMedallion(icon: "flame.fill", color: .orange, isUnlocked: false, progress: 0.4)
    }
}
