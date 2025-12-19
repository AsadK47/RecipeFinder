//
//  NutritionalTipsView.swift
//  RecipeFinder
//
//  Created on 12/19/2025.
//

import SwiftUI

struct NutritionalTipsView: View {
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCategory: NutritionalTipCategory? = nil
    @State private var selectedTip: NutritionalTip? = nil
    @State private var showTipDetail = false
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Tip of the Day
                    tipOfTheDayCard
                    
                    // Category Filters
                    categoryFilters
                    
                    // Tips List
                    tipsGrid
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Nutritional Science")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showTipDetail) {
            if let tip = selectedTip {
                TipDetailView(tip: tip)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Science-Backed Nutrition")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Evidence from Harvard, Cambridge & Oxford")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("All tips cite peer-reviewed sources • Click to verify")
                        .font(.caption2)
                        .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
            
            Text("Nutritional guidance based on peer-reviewed research and white papers from leading institutions.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background {
            cardBackground()
        }
    }
    
    private var tipOfTheDayCard: some View {
        let tip = NutritionalTipsDatabase.tipOfTheDay()
        
        return Button(action: {
            selectedTip = tip
            showTipDetail = true
            HapticManager.shared.light()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("💡 Tip of the Day")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.accentColor(for: selectedTheme).opacity(0.2))
                        .cornerRadius(12)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.5))
                }
                
                HStack {
                    Text(tip.icon)
                        .font(.system(size: 40))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tip.title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(tip.summary)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                }
                
                HStack {
                    EvidenceBadge(level: tip.evidenceLevel)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "link.circle.fill")
                            .font(.caption2)
                        Text("\(tip.sources.count) sources")
                            .font(.caption2)
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding()
            .background {
                cardBackground()
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.accentColor(for: selectedTheme).opacity(0.3), lineWidth: 2)
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var categoryFilters: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse by Category")
                .font(.headline)
                .foregroundColor(.white)
            
            FlowLayout(spacing: 8) {
                // All button
                Button(action: {
                    selectedCategory = nil
                    HapticManager.shared.light()
                }) {
                    HStack(spacing: 4) {
                        Text("All")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        selectedCategory == nil ?
                        AppTheme.accentColor(for: selectedTheme) :
                        Color.white.opacity(0.2)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
                
                ForEach(NutritionalTipCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                        HapticManager.shared.light()
                    }) {
                        HStack(spacing: 4) {
                            Text(category.icon)
                                .font(.caption)
                            Text(category.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedCategory == category ?
                            AppTheme.accentColor(for: selectedTheme) :
                            Color.white.opacity(0.2)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                }
            }
        }
    }
    
    private var tipsGrid: some View {
        let filteredTips = selectedCategory == nil ?
            NutritionalTipsDatabase.allTips :
            NutritionalTipsDatabase.tips(forCategory: selectedCategory!)
        
        return LazyVStack(spacing: 16) {
            ForEach(filteredTips) { tip in
                NutritionalTipCard(tip: tip) {
                    selectedTip = tip
                    showTipDetail = true
                    HapticManager.shared.light()
                }
            }
        }
    }
    
    private func cardBackground() -> some View {
        Group {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(white: 0.2) : Color.white.opacity(0.9))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
        }
    }
}

// MARK: - Tip Card

struct NutritionalTipCard: View {
    let tip: NutritionalTip
    let action: () -> Void
    
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(tip.icon)
                        .font(.system(size: 32))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tip.title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(tip.category.rawValue)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Text(tip.summary)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                
                HStack {
                    EvidenceBadge(level: tip.evidenceLevel)
                    
                    Spacer()
                    
                    Text("\(tip.sources.count) sources")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding()
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color(white: 0.2) : Color.white.opacity(0.9))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Evidence Badge

struct EvidenceBadge: View {
    let level: EvidenceLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level == .strong ? "checkmark.seal.fill" : level == .moderate ? "checkmark.circle.fill" : "sparkles")
                .font(.caption2)
            Text(level.rawValue)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badgeColor.opacity(0.2))
        .foregroundColor(badgeColor)
        .cornerRadius(8)
    }
    
    private var badgeColor: Color {
        switch level {
        case .strong: return .green
        case .moderate: return .orange
        case .emerging: return .blue
        }
    }
}

// MARK: - Tip Detail View

struct TipDetailView: View {
    let tip: NutritionalTip
    
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        HStack {
                            Text(tip.icon)
                                .font(.system(size: 60))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tip.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(tip.category.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                        }
                        
                        EvidenceBadge(level: tip.evidenceLevel)
                        
                        // Description
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What the Science Says")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(tip.fullDescription)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background {
                            cardBackground()
                        }
                        
                        // Actionable Steps
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What You Can Do")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ForEach(Array(tip.actionableSteps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(AppTheme.accentColor(for: selectedTheme))
                                        .clipShape(Circle())
                                    
                                    Text(step)
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background {
                            cardBackground()
                        }
                        
                        // Sources
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "graduationcap.fill")
                                Text("Scientific Sources")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            
                            ForEach(tip.sources) { source in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(source.institution)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    if let pub = source.publication {
                                        Text(pub)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    if let year = source.year {
                                        Text("Published: \(year)")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    
                                    if let urlString = source.url, let url = URL(string: urlString) {
                                        Button(action: {
                                            // Present share sheet so user can choose which app to open URL with
                                            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                               let topController = windowScene.windows.first?.rootViewController {
                                                if let presentedVC = topController.presentedViewController {
                                                    presentedVC.present(activityVC, animated: true)
                                                } else {
                                                    topController.present(activityVC, animated: true)
                                                }
                                            }
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "link.circle.fill")
                                                    .font(.caption)
                                                Text("View Source")
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                            }
                                            .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(AppTheme.accentColor(for: selectedTheme).opacity(0.2))
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            Text("Evidence Level: \(tip.evidenceLevel.description)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                                .italic()
                            
                            Divider()
                                .background(Color.white.opacity(0.3))
                                .padding(.vertical, 8)
                            
                            Text("💡 Tip: Click 'View Source' to read the full peer-reviewed research and verify the information yourself.")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                                .italic()
                        }
                        .padding()
                        .background {
                            cardBackground()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func cardBackground() -> some View {
        Group {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(white: 0.2) : Color.white.opacity(0.9))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
        }
    }
}

// MARK: - Preview

struct NutritionalTipsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NutritionalTipsView()
        }
    }
}
