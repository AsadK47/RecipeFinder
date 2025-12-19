import SwiftUI

struct SwipeAction {
    let icon: String
    let backgroundColor: Color
    let action: () -> Void
}

struct SwipeActionModifier: ViewModifier {
    let enabled: Bool
    let leading: SwipeAction?
    
    @State private var offset: CGFloat = 0
    @State private var isPerformingAction = false
    
    private let actionThreshold: CGFloat = 80
    private let maxSwipe: CGFloat = 100
    
    func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            // Background action button
            if let leading = leading, enabled {
                HStack {
                    Button(action: {
                        performAction(leading.action)
                    }) {
                        Image(systemName: leading.icon)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 60)
                    }
                    Spacer()
                }
                .frame(height: 60)
                .background(leading.backgroundColor)
                .opacity(offset > 0 ? 1 : 0)
            }
            
            // Main content
            content
                .background(Color(UIColor.systemBackground))
                .offset(x: offset)
                .gesture(
                    enabled ? DragGesture()
                        .onChanged { value in
                            // Only allow swipe from left to right
                            if value.translation.width > 0 {
                                offset = min(value.translation.width, maxSwipe)
                            }
                        }
                        .onEnded { value in
                            if offset > actionThreshold, let leading = leading {
                                performAction(leading.action)
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    offset = 0
                                }
                            }
                        } : nil
                )
        }
        .clipped()
    }
    
    private func performAction(_ action: () -> Void) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            offset = 0
        }
        HapticManager.shared.success()
        action()
    }
}

extension View {
    func swipe(_ enabled: Bool, leading: SwipeAction? = nil) -> some View {
        modifier(SwipeActionModifier(enabled: enabled, leading: leading))
    }
}
