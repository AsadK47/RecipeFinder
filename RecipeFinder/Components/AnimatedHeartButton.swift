//
//  AnimatedHeartButton.swift
//  RecipeFinder
//
//  Created by GitHub Copilot
//  Instagram-style multicolored heart animation
//

import SwiftUI

struct AnimatedHeartButton: View {
    @Binding var isFavorite: Bool
    let action: () -> Void
    
    @State private var isAnimating = false
    @State private var scale: CGFloat = 1.0
    @State private var particlesVisible = false
    
    // Instagram-style gradient colors (pink to red to orange)
    private let heartGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.2, blue: 0.4),      // Pink-red
            Color(red: 0.96, green: 0.26, blue: 0.21),   // Red
            Color(red: 1.0, green: 0.38, blue: 0.27),    // Red-orange
            Color(red: 1.0, green: 0.5, blue: 0.0)       // Orange
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        Button(action: handleTap) {
            ZStack {
                // Particle effects layer
                if particlesVisible && isFavorite {
                    ForEach(0..<8, id: \.self) { index in
                        Circle()
                            .fill(particleColor(for: index))
                            .frame(width: 4, height: 4)
                            .offset(particleOffset(for: index))
                            .opacity(particlesVisible ? 0 : 1)
                            .scaleEffect(particlesVisible ? 0.5 : 1.5)
                    }
                }
                
                // Heart icon
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(isFavorite ? heartGradient : LinearGradient(colors: [.white], startPoint: .top, endPoint: .bottom))
                    .scaleEffect(scale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: scale)
            }
        }
        .onChange(of: isFavorite) { _, newValue in
            if newValue {
                animateHeart()
            }
        }
    }
    
    // MARK: - Actions
    private func handleTap() {
        HapticManager.shared.light()
        action()
    }
    
    private func animateHeart() {
        // Initial bounce
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            scale = 1.4
        }
        
        // Show particles
        withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
            particlesVisible = true
        }
        
        // Return to normal size
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                scale = 1.0
            }
        }
        
        // Hide particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            particlesVisible = false
        }
    }
    
    // MARK: - Particle Helpers
    private func particleColor(for index: Int) -> Color {
        let colors: [Color] = [
            Color(red: 1.0, green: 0.2, blue: 0.4),      // Pink-red
            Color(red: 0.96, green: 0.26, blue: 0.21),   // Red
            Color(red: 1.0, green: 0.38, blue: 0.27),    // Red-orange
            Color(red: 1.0, green: 0.5, blue: 0.0),      // Orange
            Color(red: 1.0, green: 0.65, blue: 0.0),     // Light orange
            Color(red: 1.0, green: 0.75, blue: 0.8),     // Light pink
            Color(red: 0.8, green: 0.2, blue: 0.6),      // Magenta
            Color(red: 1.0, green: 0.4, blue: 0.5)       // Pink
        ]
        return colors[index % colors.count]
    }
    
    private func particleOffset(for index: Int) -> CGSize {
        let angle = Double(index) * .pi / 4.0  // 8 particles, 45° apart
        let radius: CGFloat = 25
        return CGSize(
            width: cos(angle) * radius,
            height: sin(angle) * radius
        )
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        AppTheme.backgroundGradient(for: .teal, colorScheme: .dark)
            .ignoresSafeArea()
        
        VStack(spacing: 40) {
            Text("Tap the heart!")
                .foregroundColor(.white)
                .font(.title2)
            
            AnimatedHeartButton(isFavorite: .constant(false)) {
                debugLog("Heart tapped!")
            }
            
            AnimatedHeartButton(isFavorite: .constant(true)) {
                debugLog("Already favorited!")
            }
        }
    }
}
