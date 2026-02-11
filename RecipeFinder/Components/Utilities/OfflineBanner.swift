//
//  OfflineBanner.swift
//  RecipeFinder
//
//  Banner to show network connection status
//

import SwiftUI

/// Shows when the device is offline - useful for recipe import features
/// This explains to users why certain features may not work
struct OfflineBanner: View {
    var body: some View {
        if !NetworkMonitor.shared.isConnected {
            HStack(spacing: AppTheme.spacing8) {
                Image(systemName: "wifi.slash")
                    .font(.subheadline)
                
                Text("No Internet Connection")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.subheadline)
            }
            .adaptiveForegroundColor()
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.orange)
            .cornerRadius(AppTheme.cornerRadius8)
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
