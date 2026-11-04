import Foundation

/// The sheets presentable from the Profile screen.
enum ProfileSheet: Identifiable {
    case privacyPolicy
    case imagePicker
    case badge(Badge)
    
    var id: String {
        switch self {
        case .privacyPolicy: return "privacyPolicy"
        case .imagePicker: return "imagePicker"
        case .badge(let badge): return "badge_\(badge.id)"
        }
    }
}
