import UIKit
import AudioToolbox

final class HapticManager: Sendable {
    static let shared = HapticManager()
    
    private init() {}
    
    func light() {
        Task { @MainActor in
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    func medium() {
        Task { @MainActor in
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
    
    func heavy() {
        Task { @MainActor in
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }
    }
    
    func soft() {
        Task { @MainActor in
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
        }
    }
    
    func rigid() {
        Task { @MainActor in
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.impactOccurred()
        }
    }
    
    func success() {
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    func warning() {
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }
    
    func error() {
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
    
    func selection() {
        Task { @MainActor in
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
    
    func doubleTap() {
        light()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: AppTheme.hapticIntervalShort)
            self.light()
        }
    }
    
    func celebrate() {
        Task { @MainActor in
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            
            try? await Task.sleep(nanoseconds: AppTheme.hapticIntervalMedium)
            self.light()
        }
    }
    
    /// A badge reveal's own pattern: a firm tap as the medallion lands, a success buzz, then two sparkles.
    func badgeReveal() {
        Task { @MainActor in
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 1)
            try? await Task.sleep(nanoseconds: AppTheme.hapticIntervalShort)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            try? await Task.sleep(nanoseconds: AppTheme.hapticIntervalMedium)
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
            try? await Task.sleep(nanoseconds: AppTheme.hapticIntervalShort)
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
        }
    }

    func delete() {
        warning()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: AppTheme.hapticIntervalShort)
            self.rigid()
        }
    }
    
    func toggle() {
        soft()
    }
}
