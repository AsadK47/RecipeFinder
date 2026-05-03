
import SwiftUI

struct LoadingExampleView: View {
    @State private var isLoading = true
    @State private var showSkeleton = true
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.spacing24) {
                        VStack(spacing: AppTheme.spacing16) {
                            Toggle("Show Loading State", isOn: $isLoading)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(AppTheme.cornerRadius12)
                            
                            Toggle("Show Skeleton Loader", isOn: $showSkeleton)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(AppTheme.cornerRadius12)
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.vertical)
                        
                        if isLoading {
                            LoadingStateView(
                                message: "Loading your recipes...",
                                progress: 0.65
                            )
                            .frame(height: 200)
                        }
                        
                        if showSkeleton {
                            VStack(spacing: AppTheme.spacing24) {
                                Text("Recipe Card Skeleton")
                                    .font(.headline)
                                    .adaptiveForegroundColor()
                                
                                RecipeCardSkeleton()
                                    .padding(.horizontal)
                                
                                Text("List Item Skeleton")
                                    .font(.headline)
                                    .adaptiveForegroundColor()
                                    .padding(.top)
                                
                                ForEach(0..<3) { _ in
                                    ListItemSkeleton()
                                        .padding(.horizontal)
                                }
                            }
                        }
                        
                        if !isLoading && !showSkeleton {
                            VStack(spacing: AppTheme.spacing16) {
                                Text("✨ Content Loaded!")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .adaptiveForegroundColor()
                                
                                Text("This is where your actual content appears")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.vertical, 40)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Loading States")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    LoadingExampleView()
}
