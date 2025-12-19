import SwiftUI

struct SwipeAction {
    let icon: String
    let backgroundColor: Color
    let action: () -> Void
}

struct SwipeActionModifier: ViewModifier {
    let enabled: Bool
    let trailing: SwipeAction?
    
    @State private var offset: CGFloat = 0
    @State private var isPerformingAction = false
    
    private let actionThreshold: CGFloat = 80
    private let maxSwipe: CGFloat = 100
    private let minimumDragDistance: CGFloat = 15
    
    func body(content: Content) -> some View {
        ZStack(alignment: .trailing) {
            // Background action button
            if let trailing = trailing, enabled {
                HStack {
                    Spacer()
                    Button(action: {
                        performAction(trailing.action)
                    }) {
                        Image(systemName: trailing.icon)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 60)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(trailing.backgroundColor)
                .opacity(offset < 0 ? 1 : 0)
            }
            
            // Main content
            content
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.systemBackground).opacity(0.001))
                .compositingGroup()
                .offset(x: offset)
                .gesture(
                    enabled ? DragGesture(minimumDistance: minimumDragDistance)
                        .onChanged { value in
                            // Only allow swipe from right to left (negative offset)
                            // Require horizontal movement to be 2x greater than vertical for swipe
                            let horizontalMovement = abs(value.translation.width)
                            let verticalMovement = abs(value.translation.height)
                            
                            if horizontalMovement > verticalMovement * 2 && value.translation.width < 0 {
                                offset = max(value.translation.width, -maxSwipe)
                            }
                        }
                        .onEnded { value in
                            if abs(offset) > actionThreshold, let trailing = trailing {
                                performAction(trailing.action)
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
    func swipe(_ enabled: Bool, trailing: SwipeAction? = nil) -> some View {
        modifier(SwipeActionModifier(enabled: enabled, trailing: trailing))
    }
}
