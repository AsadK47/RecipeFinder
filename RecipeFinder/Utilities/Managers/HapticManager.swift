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
            try? await Task.sleep(nanoseconds: 100_000_000)
            self.light()
        }
    }
    
    func celebrate() {
        Task { @MainActor in
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            
            try? await Task.sleep(nanoseconds: 150_000_000)
            self.light()
        }
    }
    
    func delete() {
        warning()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            self.rigid()
        }
    }
    
    func toggle() {
        soft()
    }
}
