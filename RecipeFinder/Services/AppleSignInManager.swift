//
//  AppleSignInManager.swift
//  RecipeFinder
//
//  Sign in with Apple implementation
//

import Foundation
import AuthenticationServices
import SwiftUI

final class AppleSignInManager: NSObject, ObservableObject, @unchecked Sendable {
    static let shared = AppleSignInManager()
    
    @Published var isAuthenticated = false
    @Published var userIdentifier: String?
    @Published var userEmail: String?
    @Published var fullName: String?
    @Published var errorMessage: String?
    
    private override init() {
        super.init()
        checkAuthenticationState()
    }
    
    // Check if user is already signed in
    func checkAuthenticationState() {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else {
            isAuthenticated = false
            return
        }
        
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userID) { credentialState, error in
            DispatchQueue.main.async {
                switch credentialState {
                case .authorized:
                    self.isAuthenticated = true
                    self.userIdentifier = userID
                    self.loadUserData()
                case .revoked, .notFound:
                    self.signOut()
                default:
                    self.isAuthenticated = false
                }
            }
        }
    }
    
    // Sign in with Apple
    func signIn() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    // Sign out
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "appleUserIdentifier")
        UserDefaults.standard.removeObject(forKey: "appleUserEmail")
        UserDefaults.standard.removeObject(forKey: "appleUserName")
        
        isAuthenticated = false
        userIdentifier = nil
        userEmail = nil
        fullName = nil
        
        HapticManager.shared.success()
    }
    
    // Load saved user data
    private func loadUserData() {
        userEmail = UserDefaults.standard.string(forKey: "appleUserEmail")
        fullName = UserDefaults.standard.string(forKey: "appleUserName")
    }
    
    // Save user data
    private func saveUserData(identifier: String, email: String?, name: PersonNameComponents?) {
        UserDefaults.standard.set(identifier, forKey: "appleUserIdentifier")
        
        if let email = email {
            UserDefaults.standard.set(email, forKey: "appleUserEmail")
        }
        
        if let name = name {
            let fullName = [name.givenName, name.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            if !fullName.isEmpty {
                UserDefaults.standard.set(fullName, forKey: "appleUserName")
            }
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleSignInManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            errorMessage = "Invalid credentials"
            return
        }
        
        // Save user data
        let userID = credential.user
        let email = credential.email
        let name = credential.fullName
        
        saveUserData(identifier: userID, email: email, name: name)
        
        // Update state
        userIdentifier = userID
        userEmail = email ?? UserDefaults.standard.string(forKey: "appleUserEmail")
        
        if let name = name {
            fullName = [name.givenName, name.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
        } else {
            fullName = UserDefaults.standard.string(forKey: "appleUserName")
        }
        
        isAuthenticated = true
        errorMessage = nil
        
        HapticManager.shared.success()
        
        debugLog("✅ [AppleSignIn] Successfully signed in: \(userID)")
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let authError = error as NSError
        
        // User cancelled
        if authError.code == 1001 {
            errorMessage = nil
            debugLog("ℹ️ [AppleSignIn] User cancelled sign in")
            return
        }
        
        errorMessage = "Sign in failed: \(error.localizedDescription)"
        HapticManager.shared.error()
        
        debugLog("❌ [AppleSignIn] Error: \(error.localizedDescription)")
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleSignInManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Safely find the window scene and window
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first {
            return window
        }
        
        // Fallback: try any connected scene
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            debugLog("Warning: Using fallback window for Apple Sign In presentation")
            return window
        }
        
        // Last resort: create a new window (should never happen in normal circumstances)
        debugLog("Critical: No existing window found for Apple Sign In, creating fallback")
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.windowLevel = .alert
        window.makeKeyAndVisible()
        return window
    }
}
