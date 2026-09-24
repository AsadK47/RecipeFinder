import SwiftUI

/// A left-to-right light sweep that signals "content is loading" on skeleton
/// placeholders. Extracted so the recipe image placeholder and the list
/// skeleton share one implementation instead of each hand-rolling the sweep.
extension View {
    func shimmering(active: Bool = true) -> some View {
        modifier(ShimmerModifier(active: active))
    }
}

private struct ShimmerModifier: ViewModifier {
    let active: Bool
    @State private var offset: CGFloat = -1

    func body(content: Content) -> some View {
        content.overlay {
            if active {
                GeometryReader { geo in
                    let w = geo.size.width
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .white.opacity(0.20), location: 0.45),
                            .init(color: .white.opacity(0.40), location: 0.50),
                            .init(color: .white.opacity(0.20), location: 0.55),
                            .init(color: .clear, location: 1.0),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: w * 2.5)
                    .offset(x: offset * w * 2.5)
                    .onAppear {
                        withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                            offset = 1
                        }
                    }
                }
                .clipped()
                .allowsHitTesting(false)
            }
        }
    }
}
