//
//  QueenEasterEggView.swift
//  RecipeFinder
//
//  A special tribute 👑❤️
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
        (0..<15).map { _ in
            (
                icon: ["heart.fill", "sparkles", "star.fill", "crown.fill"].randomElement()!,
                size: CGFloat.random(in: 10...25),
                x: CGFloat.random(in: 50...350),
                y: CGFloat.random(in: 100...700)
            )
        }
    }()
    
    var body: some View {
        ZStack {
            // Romantic gradient background
            let backgroundGradient = LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.8),
                    Color.pink.opacity(0.6),
                    Color.red.opacity(0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            backgroundGradient
                .ignoresSafeArea()
            
            // Floating romantic particles
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
            
            VStack(spacing: 32) {
                Spacer()
                
                // Crown Icon
                ZStack {
                    // Pulsing glow rings
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
                    
                    // Glow background
                    let glowGradient = RadialGradient(
                        gradient: Gradient(colors: [
                            Color.yellow.opacity(glowIntensity),
                            Color.orange.opacity(glowIntensity * 0.6),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                    
                    Circle()
                        .fill(glowGradient)
                        .frame(width: 240, height: 240)
                        .blur(radius: 30)
                    
                    // Crown
                    ZStack {
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
                        
                        // Small hearts around crown
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
                }
                .confettiCannon(counter: $confettiCounter, num: 50, colors: [.yellow, .orange, .pink, .red, .purple], confettiSize: 15, radius: 400)
                
                // Text content
                VStack(spacing: 20) {
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
                    
                    VStack(spacing: 12) {
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
                        
                        Text("Queen of My Heart")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("❤️")
                            .font(.system(size: 40))
                            .scaleEffect(heartScale)
                    }
                    
                    // Romantic quote
                    Text("\"In every recipe of life,\nyou're the secret ingredient\nthat makes everything perfect\"")
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .italic()
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                    
                    // Easter egg hint
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
                .opacity(contentOpacity)
                
                Spacer()
                
                // Close button
                Button(action: {
                    HapticManager.shared.success()
                    withAnimation(.easeOut(duration: 0.3)) {
                        contentOpacity = 0
                        crownScale = 0.3
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dismiss()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "heart.fill")
                        Text("Close")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
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
                    )
                    .overlay(
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
                    )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .opacity(contentOpacity)
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
