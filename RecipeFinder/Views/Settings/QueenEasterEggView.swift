//
//  QueenEasterEggView.swift
//  RecipeFinder
//
//  A special tribute to the one and only 👑 
//

import SwiftUI
import ConfettiSwiftUI

struct QueenEasterEggView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) var colorScheme
    
    @State private var crownScale: CGFloat = 0.3
    @State private var crownRotation: Double = 0
    @State private var heartScale: CGFloat = 0
    @State private var contentOpacity: Double = 0
    @State private var confettiCounter = 0
    @State private var glowIntensity: Double = 0.3
    @State private var particlesOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200
    
    // Particle data for romantic effect
    private let particleData: [(icon: String, size: CGFloat, x: CGFloat, y: CGFloat)] = {
        let icons = ["heart.fill", "sparkles", "star.fill", "crown.fill"]
        return (0..<15).map { _ in
            let selectedIcon = icons.randomElement() ?? "heart.fill"
            let particleSize = CGFloat.random(in: 10...25)
            let xPosition = CGFloat.random(in: 50...350)
            let yPosition = CGFloat.random(in: 100...700)
            return (icon: selectedIcon, size: particleSize, x: xPosition, y: yPosition)
        }
    }()
    
    // MARK: - Helper Views
    private var floatingParticles: some View {
        ForEach(Array(particleData.enumerated()), id: \.offset) { index, particle in
            Image(systemName: particle.icon)
                .font(.system(size: particle.size))
                .foregroundColor(.white.opacity(0.15))
                .position(x: particle.x, y: particle.y)
                .opacity(particlesOpacity)
                .animation(
                    .easeInOut(duration: Double.random(in: 3...6))
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.2),
                    value: particlesOpacity
                )
        }
    }
    
    private var crownSection: some View {
        ZStack {
            glowRings
            glowGradient
            crownWithHearts
        }
    }
    
    private var glowRings: some View {
        ForEach(0..<3) { index in
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.yellow.opacity(0.6 - Double(index) * 0.2),
                            Color.orange.opacity(0.0)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 180 + CGFloat(index * 40), height: 180 + CGFloat(index * 40))
                .scaleEffect(crownScale + CGFloat(index) * 0.15)
                .opacity(1.0 - Double(index) * 0.3)
                .animation(
                    .easeInOut(duration: 2.5)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.4),
                    value: crownScale
                )
        }
    }
    
    private var crownWithHearts: some View {
        ZStack {
            crownIcon
            heartsAroundCrown
        }
    }
    
    private var heartsAroundCrown: some View {
        ForEach(0..<5) { index in
            Image(systemName: "heart.fill")
                .font(.system(size: 20))
                .foregroundColor(.pink)
                .offset(
                    x: cos(Double(index) * .pi * 2 / 5) * 70,
                    y: sin(Double(index) * .pi * 2 / 5) * 70
                )
                .scaleEffect(heartScale)
                .opacity(contentOpacity)
        }
    }
    
    private var textContent: some View {
        VStack(spacing: 20) {
            titleText
            
            VStack(spacing: 12) {
                nameText
                
                Text("Queen of My Heart")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("❤️")
                    .font(.system(size: 40))
                    .scaleEffect(heartScale)
            }
            
            romanticQuote
            easterEggHint
        }
        .opacity(contentOpacity)
    }
    
    private var romanticQuote: some View {
        Text("\"In every recipe of life,\nyou're the secret ingredient\nthat makes everything perfect\"")
            .font(.system(size: 16, weight: .medium, design: .serif))
            .italic()
            .foregroundColor(.white.opacity(0.85))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .padding(.top, 20)
    }
    
    private var easterEggHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.caption)
            Text("You found the secret! 🎉")
                .font(.caption)
                .fontWeight(.semibold)
            Image(systemName: "sparkles")
                .font(.caption)
        }
        .foregroundColor(.yellow)
        .padding(.top, 12)
    }
    
    // MARK: - Actions
    private func closeAction() {
        HapticManager.shared.success()
        withAnimation(.easeOut(duration: 0.3)) {
            contentOpacity = 0
            crownScale = 0.3
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
    
    // MARK: - Computed Properties
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.purple.opacity(0.8),
                Color.pink.opacity(0.6),
                Color.red.opacity(0.5)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var glowGradient: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.yellow.opacity(glowIntensity),
                        Color.orange.opacity(glowIntensity * 0.6),
                        Color.clear
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 120
                )
            )
            .frame(width: 240, height: 240)
            .blur(radius: 30)
    }
    
    private var crownIcon: some View {
        Image(systemName: "crown.fill")
            .font(.system(size: 90))
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.yellow,
                        Color.orange,
                        Color.yellow
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: .yellow.opacity(0.6), radius: 20, x: 0, y: 10)
            .scaleEffect(crownScale)
            .rotationEffect(.degrees(crownRotation))
    }
    
    private var titleText: some View {
        Text("👑 The Queen 👑")
            .font(.system(size: 38, weight: .bold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .white,
                        .yellow,
                        .white
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    private var nameText: some View {
        Text("Kelly")
            .font(.system(size: 32, weight: .bold, design: .serif))
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .pink,
                        .red
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
    
    private var closeButton: some View {
        Button(action: closeAction) {
            HStack(spacing: 12) {
                Image(systemName: "heart.fill")
                Text("Close")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(closeButtonBackground)
            .overlay(closeButtonShimmer)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 40)
        .opacity(contentOpacity)
    }
    
    private var closeButtonBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.pink.opacity(0.8),
                        Color.red.opacity(0.8)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(color: .pink.opacity(0.5), radius: 20, x: 0, y: 10)
    }
    
    private var closeButtonShimmer: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.3),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .offset(x: shimmerOffset)
    }
    
    var body: some View {
        ZStack {
            // Romantic gradient background
            backgroundGradient
            
            // Floating romantic particles
            floatingParticles
            
            VStack(spacing: 32) {
                Spacer()
                
                // Crown Icon
                crownSection
                    .confettiCannon(trigger: $confettiCounter, num: 50, colors: [.yellow, .orange, .pink, .red, .purple], confettiSize: 15, radius: 400)
                
                // Text content
                textContent
                
                Spacer()
                
                // Close button
                closeButton
            }
        }
        .onAppear {
            // Entrance animations
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                crownScale = 1.1
                contentOpacity = 1.0
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                heartScale = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                particlesOpacity = 1.0
            }
            
            // Pulsing glow
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowIntensity = 0.8
            }
            
            // Shimmer effect
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
            
            // Trigger confetti after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                confettiCounter += 1
                HapticManager.shared.celebrate()
            }
        }
    }
}

#Preview {
    QueenEasterEggView()
}
