import Foundation
import LocalAuthentication

/// Face ID / Touch ID authentication.
extension AuthenticationManager {

    func authenticateWithBiometrics() async throws {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw AuthError.biometricsNotAvailable
        }
        
        let reason = "Authenticate to access RecipeFinder"
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            guard success else { return }

            // Load the user first and require one — never flip to authenticated with no user (leaves managers on the wrong scope).
            loadUser()
            guard let user = currentUser else { throw AuthError.biometricsFailed }

            setAuthState(isAuthenticated: true, user: user)
            UserDefaults.standard.set(true, forKey: isAuthenticatedKey)
            updateLastActiveTimestamp()
            UserScopedStorage.shared.currentUserId = user.id
            reloadAllManagers()

            HapticManager.shared.success()
        } catch {
            throw AuthError.biometricsFailed
        }
    }
    
    var biometricsAvailable: Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    var biometricType: String {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return "None"
        }
        
        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Biometrics"
        }
    }
}
