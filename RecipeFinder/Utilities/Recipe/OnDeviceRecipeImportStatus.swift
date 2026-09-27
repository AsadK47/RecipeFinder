import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Human-facing state of the on-device interpreter so the UI can explain why AI import does/doesn't work; Foundation-only + Equatable so copy is testable without the model.
enum OnDeviceRecipeImportStatus: Equatable {
    case available
    case deviceNotEligible
    case appleIntelligenceNotEnabled
    case modelNotReady
    case unsupportedOS
    case unknown

    var isAvailable: Bool { self == .available }

    var title: String {
        switch self {
        case .available: return "Available"
        case .deviceNotEligible: return "Not supported on this device"
        case .appleIntelligenceNotEnabled: return "Apple Intelligence is off"
        case .modelNotReady: return "Preparing…"
        case .unsupportedOS: return "Not available on this iOS version"
        case .unknown: return "Unavailable"
        }
    }

    var detail: String {
        switch self {
        case .available:
            return "Shared recipe text is turned into a recipe on-device — private, free, and offline."
        case .deviceNotEligible:
            return "On-device import needs an iPhone 15 Pro or newer (Apple Intelligence). Sharing still works via manual review."
        case .appleIntelligenceNotEnabled:
            return "Turn on Apple Intelligence in Settings to enable one-tap import. Sharing still works via manual review."
        case .modelNotReady:
            return "The on-device model is still downloading. Import falls back to manual review until it's ready."
        case .unsupportedOS:
            return "On-device import requires iOS 26 or later. Sharing still works via manual review."
        case .unknown:
            return "On-device import isn't available right now. Sharing still works via manual review."
        }
    }
}

/// Reads the on-device model's availability; gated to compile and return a sensible value on older SDKs/OSes.
enum OnDeviceRecipeImport {
    static func currentStatus() -> OnDeviceRecipeImportStatus {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return .available
            case .unavailable(.deviceNotEligible):
                return .deviceNotEligible
            case .unavailable(.appleIntelligenceNotEnabled):
                return .appleIntelligenceNotEnabled
            case .unavailable(.modelNotReady):
                return .modelNotReady
            case .unavailable:
                return .unknown
            }
        } else {
            return .unsupportedOS
        }
        #else
        return .unsupportedOS
        #endif
    }
}
