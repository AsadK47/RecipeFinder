//
//  LoadingExampleView.swift
//  RecipeFinder
//
//  Example showing how to use loading states with skeleton loaders
//

import SwiftUI

/// Example view showing loading state implementations
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
                    VStack(spacing: 20) {
                        // Toggle controls
                        VStack(spacing: 16) {
                            Toggle("Show Loading State", isOn: $isLoading)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                            
                            Toggle("Show Skeleton Loader", isOn: $showSkeleton)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.vertical)
                        
                        // Loading State Example
                        if isLoading {
                            LoadingStateView(
                                message: "Loading your recipes...",
                                progress: 0.65
                            )
                            .frame(height: 200)
                        }
                        
                        // Skeleton Loader Examples
                        if showSkeleton {
                            VStack(spacing: 20) {
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
                        
                        // Actual Content Example (when not loading)
                        if !isLoading && !showSkeleton {
                            VStack(spacing: 16) {
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
