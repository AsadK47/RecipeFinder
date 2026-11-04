import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    var onComplete: (() -> Void)? = nil
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) private var colorScheme

    @State private var currentPage = 0

    private let slides = OnboardingContent.slides

    var body: some View {
        ZStack {
            backdrop

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        OnboardingSlideView(
                            slide: slides[index],
                            isLastSlide: index == slides.count - 1,
                            onNext: { advance(from: index) }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                .onChange(of: currentPage) { _, _ in HapticManager.shared.selection() }

                pageIndicator
                    .padding(.bottom, 16)
            }
        }
        .interactiveDismissDisabled()
    }

    private func advance(from index: Int) {
        if index < slides.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) { currentPage = index + 1 }
        } else {
            complete()
        }
    }

    private func complete() {
        if let onComplete {
            onComplete()
        } else {
            dismiss()
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<slides.count, id: \.self) { index in
                Capsule()
                    .fill(Color.white.opacity(currentPage == index ? 0.9 : 0.3))
                    .frame(width: currentPage == index ? 20 : 6, height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
            }
        }
    }

    private var backdrop: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()

            Circle()
                .fill(AppTheme.accentColor(for: selectedTheme).opacity(0.25))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: -120, y: -200)

            Circle()
                .fill(AppTheme.accentColor(for: selectedTheme).opacity(0.15))
                .frame(width: 260, height: 260)
                .blur(radius: 80)
                .offset(x: 130, y: 280)
        }
    }
}

#Preview {
    OnboardingView()
}
