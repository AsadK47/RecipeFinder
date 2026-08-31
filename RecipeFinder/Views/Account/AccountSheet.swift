import Foundation

/// The sheets presentable from the Account screen.
enum AccountSheet: Identifiable {
    case privacyPolicy
    case imagePicker
    case passwordVerification
    case badge(Badge)
    
    var id: String {
        switch self {
        case .privacyPolicy: return "privacyPolicy"
        case .imagePicker: return "imagePicker"
        case .passwordVerification: return "passwordVerification"
        case .badge(let badge): return "badge_\(badge.id)"
        }
    }
}
