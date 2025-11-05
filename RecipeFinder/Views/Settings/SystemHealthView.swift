//
//  SystemHealthView.swift
//  RecipeFinder
//
//  System health monitoring for admin
//

import SwiftUI

struct SystemHealthView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @ObservedObject var healthMonitor = BrokenFeatureLogger.shared
    
    private var isAdmin: Bool {
        healthMonitor.isAdmin(email: authManager.currentUser?.email)
    }
    
    var body: some View {
        Group {
            if isAdmin {
                // Full diagnostics for admin
                SystemHealthDiagnosticsView()
            } else {
                // Limited public view
                publicStatusView
            }
        }
    }
    
    // MARK: - Public View
    
    private var publicStatusView: some View {
        List {
            Section {
                HStack {
                    Circle()
                        .fill(healthMonitor.getPublicStatusColor())
                        .frame(width: 12, height: 12)
                    
                    Text(healthMonitor.getPublicStatusMessage())
                        .fontWeight(.medium)
                }
                .padding(.vertical, 8)
            } header: {
                Text("System Status")
            } footer: {
                if healthMonitor.systemHealth != .operational {
                    Text("We're working to resolve any issues as quickly as possible.")
                        .font(.caption)
                }
            }
        }
        .navigationTitle("System Status")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview("Admin View") {
    NavigationStack {
        SystemHealthDiagnosticsView()
    }
}

#Preview("Public View") {
    NavigationStack {
        SystemHealthView()
            .environmentObject(AuthenticationManager.shared)
    }
}
