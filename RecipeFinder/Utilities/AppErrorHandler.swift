//
//  AppErrorHandler.swift
//  RecipeFinder
//
//  Centralized error handling and user-friendly error messages
//

import Foundation
import SwiftUI

/// Comprehensive error types for the app
enum RecipeFinderError: LocalizedError, Identifiable {
    var id: String { errorDescription ?? "Unknown error" }
    
    // Import Errors
    case importFailed(reason: String)
    case parsingFailed(details: String)
    case invalidURL
    case networkUnavailable
    case unsupportedFormat
    
    // Recipe Errors
    case recipeNotFound
    case invalidRecipeData
    case missingIngredients
    case missingInstructions
    
    // Storage Errors
    case saveFailed
    case deleteFailed
    case loadFailed
    case exportFailed
    
    // Kitchen Inventory Errors
    case inventoryUpdateFailed
    case itemNotFound
    case duplicateItem
    
    // Shopping List Errors
    case shoppingListError(String)
    
    // Authentication Errors
    case biometricAuthFailed
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        // Import Errors
        case .importFailed(let reason):
            return "Failed to import recipe: \(reason)"
        case .parsingFailed(let details):
            return "Could not parse recipe. \(details)"
        case .invalidURL:
            return "The URL provided is not valid"
        case .networkUnavailable:
            return "Network connection is unavailable. Please check your internet connection."
        case .unsupportedFormat:
            return "This recipe format is not supported. Try a different source."
            
        // Recipe Errors
        case .recipeNotFound:
            return "Recipe could not be found"
        case .invalidRecipeData:
            return "Recipe data is incomplete or invalid"
        case .missingIngredients:
            return "Recipe must have at least one ingredient"
        case .missingInstructions:
            return "Recipe must have at least one instruction step"
            
        // Storage Errors
        case .saveFailed:
            return "Failed to save data. Please try again."
        case .deleteFailed:
            return "Failed to delete item. Please try again."
        case .loadFailed:
            return "Failed to load data. The app may need to restart."
        case .exportFailed:
            return "Failed to export data. Check storage permissions."
            
        // Kitchen Inventory Errors
        case .inventoryUpdateFailed:
            return "Failed to update kitchen inventory"
        case .itemNotFound:
            return "Item not found in inventory"
        case .duplicateItem:
            return "This item already exists in your inventory"
            
        // Shopping List Errors
        case .shoppingListError(let message):
            return "Shopping list error: \(message)"
            
        // Authentication Errors
        case .biometricAuthFailed:
            return "Biometric authentication failed. Please try again."
        case .notAuthenticated:
            return "You need to be authenticated to perform this action"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .importFailed:
            return "Make sure the URL is correct and try again. The website may not support recipe imports."
        case .parsingFailed:
            return "Try copying and pasting the recipe manually, or use a different source."
        case .invalidURL:
            return "Check that you've entered a complete URL starting with http:// or https://"
        case .networkUnavailable:
            return "Connect to Wi-Fi or cellular data and try again."
        case .unsupportedFormat:
            return "Try importing from popular recipe sites like AllRecipes, Food Network, or BBC Good Food."
            
        case .missingIngredients, .missingInstructions:
            return "Add at least one item to continue."
            
        case .saveFailed, .deleteFailed:
            return "Check available storage space and try again."
        case .loadFailed:
            return "Try restarting the app. If the problem persists, you may need to reset app data."
        case .exportFailed:
            return "Make sure you have enough storage space and necessary permissions."
            
        case .inventoryUpdateFailed:
            return "Check your internet connection and try again."
        case .duplicateItem:
            return "Update the existing item instead of adding a new one."
            
        case .biometricAuthFailed:
            return "Try using Face ID/Touch ID again, or enter your password."
            
        default:
            return "If this problem continues, try restarting the app."
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .networkUnavailable, .unsupportedFormat, .duplicateItem:
            return .warning
        case .loadFailed, .saveFailed:
            return .critical
        case .biometricAuthFailed, .notAuthenticated:
            return .security
        default:
            return .error
        }
    }
}

enum ErrorSeverity {
    case warning
    case error
    case critical
    case security
    
    var icon: String {
        switch self {
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        case .security: return "lock.shield.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .warning: return .orange
        case .error: return .red
        case .critical: return .red
        case .security: return .blue
        }
    }
}

/// View modifier for handling errors consistently
struct ErrorAlert: ViewModifier {
    @Binding var error: RecipeFinderError?
    
    func body(content: Content) -> some View {
        content
            .alert(item: $error) { error in
                Alert(
                    title: Text(error.severity == .critical ? "Critical Error" : "Error"),
                    message: Text("\(error.errorDescription ?? "An unknown error occurred.")\n\n\(error.recoverySuggestion ?? "")"),
                    dismissButton: .default(Text("OK"))
                )
            }
    }
}

extension View {
    /// Attach error handling to any view
    func handleError(_ error: Binding<RecipeFinderError?>) -> some View {
        modifier(ErrorAlert(error: error))
    }
}

/// Custom error toast for non-blocking notifications
struct ErrorToast: View {
    let error: RecipeFinderError
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            if isShowing {
                HStack(spacing: 12) {
                    Image(systemName: error.severity.icon)
                        .font(.title3)
                        .foregroundColor(error.severity.color)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(error.severity == .warning ? "Warning" : "Error")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text(error.errorDescription ?? "Unknown error")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Button(action: { isShowing = false }) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.3), value: isShowing)
                .onAppear {
                    // Auto-dismiss after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        isShowing = false
                    }
                }
            }
        }
    }
}

extension View {
    /// Show error as a toast notification
    func errorToast(error: RecipeFinderError?, isShowing: Binding<Bool>) -> some View {
        ZStack {
            self
            
            if let error = error {
                ErrorToast(error: error, isShowing: isShowing)
            }
        }
    }
}

/// Error Logger for debugging
@MainActor
class ErrorLogger {
    nonisolated(unsafe) static let shared = ErrorLogger()
    
    private init() {}
    
    func log(_ error: RecipeFinderError, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let filename = (file as NSString).lastPathComponent
        print("❌ ERROR [\(filename):\(line)] \(function)")
        print("   Type: \(error)")
        print("   Description: \(error.errorDescription ?? "No description")")
        print("   Severity: \(error.severity)")
        if let suggestion = error.recoverySuggestion {
            print("   Suggestion: \(suggestion)")
        }
        print("─────────────────────────────────────────")
        #endif
        
        // In production, you might want to send to analytics service
        // Analytics.shared.trackError(error)
    }
    
    func logSuccess(_ message: String) {
        #if DEBUG
        print("✅ SUCCESS: \(message)")
        #endif
    }
}

// MARK: - Usage Examples

/*
 
 // Example 1: Using in a View with Alert
 struct ImportRecipeView: View {
     @State private var error: RecipeFinderError?
     
     var body: some View {
         VStack {
             Button("Import Recipe") {
                 do {
                     try importRecipe()
                 } catch {
                     self.error = .importFailed(reason: error.localizedDescription)
                     ErrorLogger.shared.log(.importFailed(reason: error.localizedDescription))
                 }
             }
         }
         .handleError($error)
     }
 }
 
 // Example 2: Using with Toast
 struct RecipeListView: View {
     @State private var error: RecipeFinderError?
     @State private var showErrorToast = false
     
     var body: some View {
         List {
             // content
         }
         .errorToast(error: error, isShowing: $showErrorToast)
         .onAppear {
             loadRecipes()
         }
     }
     
     func loadRecipes() {
         do {
             try loadData()
             ErrorLogger.shared.logSuccess("Recipes loaded successfully")
         } catch {
             self.error = .loadFailed
             self.showErrorToast = true
             ErrorLogger.shared.log(.loadFailed)
         }
     }
 }
 
 // Example 3: Manual Error Handling
 func deleteRecipe(_ recipe: RecipeModel) {
     guard recipe.id != nil else {
         let error = RecipeFinderError.recipeNotFound
         ErrorLogger.shared.log(error)
         // Show error to user
         return
     }
     
     do {
         try context.delete(recipe)
         ErrorLogger.shared.logSuccess("Recipe deleted: \(recipe.name)")
     } catch {
         let error = RecipeFinderError.deleteFailed
         ErrorLogger.shared.log(error)
         // Show error to user
     }
 }
 
 */
