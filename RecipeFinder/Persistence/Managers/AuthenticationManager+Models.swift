import Foundation

extension AuthenticationManager {

    struct User: Codable {
        let id: String
        let email: String?
        let fullName: String?
        let givenName: String?
        let familyName: String?
        let appleUserID: String?
        let createdAt: Date
        var lastLoginAt: Date
        
        var displayName: String {
            if let fullName = fullName, !fullName.isEmpty {
                return fullName
            }
            if let givenName = givenName {
                return givenName
            }
            return email ?? "User"
        }
        
        var initials: String {
            if let givenName = givenName?.first,
               let familyName = familyName?.first {
                return "\(givenName)\(familyName)".uppercased()
            }
            if let name = fullName?.components(separatedBy: " "),
               name.count >= 2 {
                return "\(name[0].first ?? "U")\(name[1].first ?? "U")".uppercased()
            }
            return "U"
        }
    }
    
    enum AuthError: LocalizedError {
        case signInFailed
        case signInCancelled
        case invalidCredentials
        case biometricsNotAvailable
        case biometricsFailed
        case userCreationFailed
        case accountAlreadyExists
        
        var errorDescription: String? {
            switch self {
            case .signInFailed:
                return "Sign in failed. Please try again."
            case .signInCancelled:
                return "Sign in was cancelled."
            case .invalidCredentials:
                return "Invalid email or password."
            case .biometricsNotAvailable:
                return "Biometric authentication is not available on this device."
            case .biometricsFailed:
                return "Biometric authentication failed."
            case .userCreationFailed:
                return "Failed to create user account."
            case .accountAlreadyExists:
                return "An account with this email already exists."
            }
        }
    }
}
