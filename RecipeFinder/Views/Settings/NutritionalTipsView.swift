
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
                VStack(spacing: AppTheme.spacing12) {
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            Button(action: {
                                HapticManager.shared.light()
                                dismiss()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.title3)
                                    .adaptiveForegroundColor()
                                    .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
                            }
                            
                            Spacer()
                            
                            Text("Nutrition Tips")
                                .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                                .adaptiveForegroundColor()
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            
                            Spacer()
                            
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
                                    .adaptiveForegroundColor()
                                    .font(.title3)
                                    .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
                            }
                        }
                    }
                    .frame(height: AppTheme.height44)
                }
                .padding(.horizontal, AppTheme.spacing20)
                .padding(.top, AppTheme.spacing16)
                
                ScrollView {
                    VStack(spacing: AppTheme.spacing24) {
                        tipOfTheDayCard
                        
                        tipsGrid
                    }
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.top, AppTheme.spacing16)
                    .padding(.bottom, AppTheme.spacing100)
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
            HStack(spacing: AppTheme.spacing16) {
                Text(tip.icon)
                    .font(.system(size: AppTheme.fontSize50))
                
                VStack(alignment: .leading, spacing: AppTheme.spacing6) {
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
                        .adaptiveForegroundColor()
                        .multilineTextAlignment(.leading)
                    
                    Text(tip.summary)
                        .font(.caption)
                        .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
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
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
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
        
        return LazyVStack(spacing: AppTheme.spacing16) {
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
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .fill(AppTheme.adaptiveCardMedium(for: colorScheme))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .fill(.ultraThinMaterial)
            }
        }
    }
}

struct NutritionalTipCard: View {
    let tip: NutritionalTip
    let action: () -> Void
    
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.spacing16) {
                Text(tip.icon)
                    .font(.system(size: AppTheme.fontSize42))
                
                VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                    Text(tip.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .adaptiveForegroundColor()
                        .multilineTextAlignment(.leading)
                    
                    Text(tip.summary)
                        .font(.caption)
                        .adaptiveForegroundColor(opacity: AppTheme.disabledEmphasisOpacity)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: AppTheme.spacing8) {
                        Text(tip.category.icon)
                            .font(.caption2)
                        Text(tip.category.rawValue)
                            .font(.caption2)
                            .adaptiveForegroundColor(opacity: AppTheme.glassLightOpacity)
                        
                        Text("•")
                            .adaptiveForegroundColor(opacity: AppTheme.shadowDarkOpacity)
                        
                        Text("\(tip.sources.count) sources")
                            .font(.caption2)
                            .adaptiveForegroundColor(opacity: AppTheme.glassLightOpacity)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .adaptiveForegroundColor(opacity: AppTheme.lowEmphasisOpacity)
            }
            .padding()
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                        .fill(AppTheme.adaptiveCard(for: colorScheme))
                } else {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                        .fill(.ultraThinMaterial)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EvidenceBadge: View {
    let level: EvidenceLevel
    
    var body: some View {
        HStack(spacing: AppTheme.spacing4) {
            Image(systemName: level == .strong ? "checkmark.seal.fill" : level == .moderate ? "checkmark.circle.fill" : "sparkles")
                .font(.caption2)
            Text(level.rawValue)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, AppTheme.spacing8)
        .padding(.vertical, AppTheme.spacing4)
        .background(badgeColor.opacity(AppTheme.overlayLightOpacity))
        .foregroundColor(badgeColor)
        .cornerRadius(AppTheme.cornerRadius8)
    }
    
    private var badgeColor: Color {
        switch level {
        case .strong: return .green
        case .moderate: return .orange
        case .emerging: return .blue
        }
    }
}

struct TipDetailView: View {
    let tip: NutritionalTip
    
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var safariItem: IdentifiableURL?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.spacing32) {
                        HStack {
                            Text(tip.icon)
                                .font(.system(size: AppTheme.fontSize60))
                            
                            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                                Text(tip.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .adaptiveForegroundColor()
                                
                                Text(tip.category.rawValue)
                                    .font(.subheadline)
                                    .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                            }
                            
                            Spacer()
                        }
                        
                        EvidenceBadge(level: tip.evidenceLevel)
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                            Text("What the Science Says")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            Text(tip.fullDescription)
                                .font(.body)
                                .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background {
                            cardBackground()
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                            Text("What You Can Do")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            ForEach(Array(tip.actionableSteps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: AppTheme.spacing12) {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .adaptiveForegroundColor()
                                        .frame(width: 24, height: AppTheme.height24)
                                        .background(AppTheme.accentColor(for: selectedTheme))
                                        .clipShape(Circle())
                                    
                                    Text(step)
                                        .font(.body)
                                        .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background {
                            cardBackground()
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                            HStack {
                                Image(systemName: "graduationcap.fill")
                                Text("Scientific Sources")
                                    .font(.headline)
                            }
                            .adaptiveForegroundColor()
                            
                            ForEach(tip.sources) { source in
                                Button(action: {
                                    if let urlString = source.url, let url = URL(string: urlString) {
                                        safariItem = IdentifiableURL(url: url)
                                        HapticManager.shared.light()
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                                                Text(source.institution)
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .adaptiveForegroundColor()
                                                
                                                if let pub = source.publication {
                                                    Text(pub)
                                                        .font(.caption)
                                                        .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                                                }
                                                
                                                if let year = source.year {
                                                    Text("Published: \(year, format: .number.grouping(.never))")
                                                        .font(.caption2)
                                                        .adaptiveForegroundColor(opacity: AppTheme.glassLightOpacity)
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
                                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                            .fill(source.url != nil ? Color.white.opacity(AppTheme.cardDarkOpacity) : Color.white.opacity(AppTheme.glassSubtleOpacity))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                                    .stroke(source.url != nil ? AppTheme.accentColor(for: selectedTheme).opacity(0.3) : Color.clear, lineWidth: 1)
                                            )
                                    )
                                }
                                .disabled(source.url == nil)
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            Text("Evidence Level: \(tip.evidenceLevel.description)")
                                .font(.caption)
                                .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
                                .italic()
                            
                            Divider()
                                .background(Color.white.opacity(AppTheme.shadowDarkOpacity))
                                .padding(.vertical, AppTheme.spacing8)
                            
                            HStack(spacing: AppTheme.spacing6) {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                Text("Tap any source with a link icon to read the full peer-reviewed research.")
                            }
                            .font(.caption2)
                            .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                        }
                        .padding()
                        .background {
                            cardBackground()
                        }
                    }
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.bottom, AppTheme.spacing100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .adaptiveForegroundColor()
                }
            }
            .fullScreenCover(item: $safariItem) { item in
                SafariView(url: item.url)
                    .ignoresSafeArea()
            }
        }
    }
    
    private func cardBackground() -> some View {
        Group {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .fill(AppTheme.adaptiveCardMedium(for: colorScheme))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .fill(.ultraThinMaterial)
            }
        }
    }
}

private struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        return SFSafariViewController(url: url, configuration: config)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct NutritionalTipsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NutritionalTipsView()
        }
    }
}
