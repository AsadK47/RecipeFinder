import Foundation

/// The sheets presentable from the Profile screen.
enum ProfileSheet: Identifiable {
    case privacyPolicy
    case imagePicker
    
    var id: String {
        switch self {
        case .privacyPolicy: return "privacyPolicy"
        case .imagePicker: return "imagePicker"
        }
    }
}
