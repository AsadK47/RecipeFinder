//
//  NutritionalTipsView.swift
//  RecipeFinder
//
//  Created on 12/19/2025.
//

import SwiftUI
import SafariServices

struct NutritionalTipsView: View {
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCategory: NutritionalTipCategory? = nil
    @State private var selectedTip: NutritionalTip? = nil
    @State private var showTipDetail = false
    @State private var showFilterMenu = false
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            // Back button
                            Button(action: {
                                HapticManager.shared.light()
                                dismiss()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                            }
                            
                            Spacer()
                            
                            Text("Nutrition Tips")
                                .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            
                            Spacer()
                            
                            // Menu button
                            Menu {
                                Button(action: {
                                    selectedCategory = nil
                                    HapticManager.shared.light()
                                }) {
                                    HStack {
                                        Text("All Tips")
                                        if selectedCategory == nil {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                
                                Divider()
                                
                                ForEach(NutritionalTipCategory.allCases, id: \.self) { category in
                                    Button(action: {
                                        selectedCategory = category
                                        HapticManager.shared.light()
                                    }) {
                                        HStack {
                                            Text("\(category.icon) \(category.rawValue)")
                                            if selectedCategory == category {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: selectedCategory == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                            }
                        }
                    }
                    .frame(height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Tip of the Day
                        tipOfTheDayCard
                        
                        // Tips List
                        tipsGrid
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showTipDetail) {
            if let tip = selectedTip {
                TipDetailView(tip: tip)
            }
        }
    }
    
    
    private var tipOfTheDayCard: some View {
        let tip = NutritionalTipsDatabase.tipOfTheDay()
        
        return Button(action: {
            selectedTip = tip
            showTipDetail = true
            HapticManager.shared.light()
        }) {
            HStack(spacing: 16) {
                Text(tip.icon)
                    .font(.system(size: 50))
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("💡")
                            .font(.caption2)
                        Text("TIP OF THE DAY")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                    }
                    
                    Text(tip.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text(tip.summary)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
            }
            .padding()
            .background {
                cardBackground()
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.accentColor(for: selectedTheme).opacity(0.5), lineWidth: 2)
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var tipsGrid: some View {
        let filteredTips: [NutritionalTip]
        if let category = selectedCategory {
            filteredTips = NutritionalTipsDatabase.tips(forCategory: category)
        } else {
            filteredTips = NutritionalTipsDatabase.allTips
        }
        
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
            HStack(spacing: 16) {
                Text(tip.icon)
                    .font(.system(size: 40))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(tip.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text(tip.summary)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        Text(tip.category.icon)
                            .font(.caption2)
                        Text(tip.category.rawValue)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("\(tip.sources.count) sources")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding()
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.9))
                } else {
                    RoundedRectangle(cornerRadius: 12)
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
    @State private var safariURL: URL?
    @State private var showSafari = false
    
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
                                Button(action: {
                                    if let urlString = source.url, let url = URL(string: urlString) {
                                        safariURL = url
                                        showSafari = true
                                        HapticManager.shared.light()
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
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
                                                    Text("Published: \(year, format: .number.grouping(.never))")
                                                        .font(.caption2)
                                                        .foregroundColor(.white.opacity(0.5))
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            if source.url != nil {
                                                Image(systemName: "arrow.up.right.circle.fill")
                                                    .font(.title3)
                                                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                            } else {
                                                Image(systemName: "info.circle.fill")
                                                    .font(.title3)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(source.url != nil ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(source.url != nil ? AppTheme.accentColor(for: selectedTheme).opacity(0.3) : Color.clear, lineWidth: 1)
                                            )
                                    )
                                }
                                .disabled(source.url == nil)
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            Text("Evidence Level: \(tip.evidenceLevel.description)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                                .italic()
                            
                            Divider()
                                .background(Color.white.opacity(0.3))
                                .padding(.vertical, 8)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                Text("Tap any source with a link icon to read the full peer-reviewed research.")
                            }
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
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
            .fullScreenCover(isPresented: $showSafari) {
                if let url = safariURL {
                    SafariView(url: url)
                        .ignoresSafeArea()
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

// MARK: - Safari View Wrapper

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        return SFSafariViewController(url: url, configuration: config)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - Preview

struct NutritionalTipsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NutritionalTipsView()
        }
    }
}
