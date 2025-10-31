import SwiftUI

struct DeveloperDocumentationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        ZStack {
            // Beautiful gradient background
            AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero section with seamless header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Developer Documentation")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("RecipeFinder is built with SwiftUI and Core Data, featuring modern iOS development patterns and best practices.")
                            .font(.system(size: 17))
                            .foregroundColor(.white.opacity(0.85))
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                    .padding(.bottom, 32)
                    
                    // Architecture Overview
                    DocSection(
                        title: "Architecture",
                        icon: "building.columns.fill",
                        iconColor: .blue,
                        content: [
                            DocPoint(title: "MVVM Pattern", description: "Model-View-ViewModel architecture for clear separation of concerns"),
                            DocPoint(title: "SwiftUI", description: "Declarative UI framework with state management"),
                            DocPoint(title: "Core Data", description: "Local persistence with background context optimization"),
                            DocPoint(title: "Combine", description: "Reactive programming for state propagation")
                        ],
                        appTheme: appTheme,
                        colorScheme: colorScheme,
                        cardStyle: cardStyle
                    )
                    
                    // Key Features
                    DocSection(
                        title: "Core Components",
                        icon: "gearshape.2.fill",
                        iconColor: .purple,
                        content: [
                            DocPoint(title: "CategoryClassifier", description: "Intelligent ingredient categorization with 500+ keyword database"),
                            DocPoint(title: "Theme System", description: "8 mathematical color themes with gradient backgrounds"),
                            DocPoint(title: "Recipe Importer", description: "Schema.org parser for importing web recipes"),
                            DocPoint(title: "PDF Generator", description: "Export recipes with device-optimized rendering")
                        ],
                        appTheme: appTheme,
                        colorScheme: colorScheme,
                        cardStyle: cardStyle
                    )
                    
                    // Tech Stack
                    DocSection(
                        title: "Tech Stack",
                        icon: "hammer.fill",
                        iconColor: .orange,
                        content: [
                            DocPoint(title: "Swift 5.7+", description: "Modern Swift with async/await support"),
                            DocPoint(title: "iOS 15.0+", description: "Target deployment for modern iOS features"),
                            DocPoint(title: "Xcode 14.0+", description: "Development environment"),
                            DocPoint(title: "XCTest", description: "Unit testing framework with 85% coverage")
                        ],
                        appTheme: appTheme,
                        colorScheme: colorScheme,
                        cardStyle: cardStyle
                    )
                    
                    // Privacy & Security
                    DocSection(
                        title: "Privacy & Security",
                        icon: "lock.shield.fill",
                        iconColor: .green,
                        content: [
                            DocPoint(title: "100% Local Storage", description: "All data stored on device with Core Data"),
                            DocPoint(title: "No Analytics", description: "Zero tracking or telemetry"),
                            DocPoint(title: "No Third-Party SDKs", description: "Built entirely with native frameworks"),
                            DocPoint(title: "iOS Encryption", description: "Protected with Data Protection API")
                        ],
                        appTheme: appTheme,
                        colorScheme: colorScheme,
                        cardStyle: cardStyle
                    )
                    
                    // Project Structure
                    DocSection(
                        title: "Project Structure",
                        icon: "folder.fill",
                        iconColor: .cyan,
                        content: [
                            DocPoint(title: "Components/", description: "Reusable UI components"),
                            DocPoint(title: "Models/", description: "Data models and Core Data schema"),
                            DocPoint(title: "Persistence/", description: "Core Data managers"),
                            DocPoint(title: "Theme/", description: "App theming system"),
                            DocPoint(title: "Utilities/", description: "Helper functions and extensions"),
                            DocPoint(title: "Views/", description: "SwiftUI views organized by feature")
                        ],
                        appTheme: appTheme,
                        colorScheme: colorScheme,
                        cardStyle: cardStyle
                    )
                    
                    // Footer
                    VStack(spacing: 12) {
                        Text("© 2024-2025 Asad Khan")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("Built with ❤️ using SwiftUI and Core Data")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 32)
                    .padding(.bottom, 40)
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // Floating Done button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                    )
                            )
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 12)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Documentation Section
struct DocSection: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: [DocPoint]
    let appTheme: AppTheme.ThemeType
    let colorScheme: ColorScheme
    let cardStyle: CardStyle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 22))
                
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            
            // Content card
            VStack(alignment: .leading, spacing: 16) {
                ForEach(content.indices, id: \.self) { index in
                    DocPointRow(point: content[index], appTheme: appTheme)
                    
                    if index < content.count - 1 {
                        Divider()
                            .background(Color.white.opacity(0.1))
                    }
                }
            }
            .padding(24)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? Color(white: 0.15).opacity(0.6) : Color.white.opacity(0.85))
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial.opacity(0.85))
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 24)
    }
}

// MARK: - Documentation Point
struct DocPoint {
    let title: String
    let description: String
}

// MARK: - Documentation Point Row
struct DocPointRow: View {
    let point: DocPoint
    let appTheme: AppTheme.ThemeType
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(point.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Text(point.description)
                .font(.system(size: 15))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                .lineSpacing(3)
        }
    }
}

#Preview {
    DeveloperDocumentationView()
        .environment(\.appTheme, AppTheme.ThemeType.teal)
}
