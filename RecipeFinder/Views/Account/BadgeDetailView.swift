import SwiftUI

struct BadgeDetailView: View {
    let badge: Badge
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted

    var badgeColor: Color { Badge.color(for: badge.color) }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: AppTheme.spacing32) {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                    }
                }
                .padding(.horizontal, AppTheme.cardHorizontalPadding)
                .padding(.top, AppTheme.spacing20)

                Spacer()

                ZStack {
                    Circle()
                        .fill(badge.isUnlocked ? badgeColor.opacity(AppTheme.cardDarkMediumOpacity) : AppTheme.secondaryText.opacity(AppTheme.shadowLightOpacity))
                        .frame(width: AppTheme.width120, height: AppTheme.width120)

                    Image(systemName: badge.icon)
                        .font(.system(size: AppTheme.fontSize60))
                        .foregroundStyle(badge.isUnlocked ? badgeColor : .gray.opacity(AppTheme.glassLightOpacity))
                }
                .shadow(color: badge.isUnlocked ? badgeColor.opacity(AppTheme.shadowDarkOpacity) : .clear, radius: 20)

                Text(badge.title)
                    .font(.system(size: AppTheme.fontSize28, weight: .bold))
                    .adaptiveForegroundColor()
                    .multilineTextAlignment(.center)

                Text(badge.description)
                    .font(.title3)
                    .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
                    .multilineTextAlignment(.center)

                if badge.isUnlocked, let date = badge.dateEarned {
                    VStack(spacing: AppTheme.spacing8) {
                        HStack(spacing: AppTheme.spacing8) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            Text("Unlocked!").fontWeight(.semibold).foregroundStyle(.green)
                        }
                        .font(.headline)

                        Text("Earned on \(date.formatted(date: .long, time: .omitted))")
                            .font(.subheadline)
                            .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
                    }
                    .padding()
                    .background {
                        if cardStyle == .solid {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12).fill(AppTheme.adaptiveCard(for: colorScheme))
                        } else {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12).fill(.ultraThinMaterial)
                        }
                    }
                } else {
                    VStack(spacing: AppTheme.spacing8) {
                        HStack(spacing: AppTheme.spacing8) {
                            Image(systemName: "lock.fill").adaptiveSecondaryForeground()
                            Text("Locked").fontWeight(.semibold).adaptiveSecondaryForeground()
                        }
                        .font(.headline)

                        if !badge.howToEarn.isEmpty {
                            Divider().padding(.vertical, AppTheme.spacing4)

                            VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                                Text("How to Earn:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
                                    .textCase(.uppercase)

                                Text(badge.howToEarn)
                                    .font(.subheadline)
                                    .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background {
                        if cardStyle == .solid {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12).fill(AppTheme.adaptiveCard(for: colorScheme))
                        } else {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12).fill(.ultraThinMaterial)
                        }
                    }
                }

                Spacer()
                Spacer()
            }
            .padding(.horizontal, AppTheme.spacing20)
        }
    }
}
