import UIKit
import AudioToolbox

/// Centralized haptic feedback manager for consistent tactile responses throughout the app
final class HapticManager: Sendable {
    static let shared = HapticManager()
    
    private init() {}
    
    // Light tap - for subtle interactions
    func light() {
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    // Medium impact - for standard interactions
    func medium() {
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
    
    // Heavy impact - for important actions
    func heavy() {
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }
    }
    
    // Soft impact - for very gentle feedback
    func soft() {
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
        }
    }
    
    // Rigid impact - for firm, definitive actions
    func rigid() {
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.impactOccurred()
        }
    }
    
    // Success notification - for successful operations
    func success() {
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    // Warning notification - for warnings
    func warning() {
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }
    
    // Error notification - for errors
    func error() {
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
    
    // Selection changed - for picker/selection changes
    func selection() {
        DispatchQueue.main.async {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
    
    // Custom patterns for special interactions
    
    // Double tap pattern - light-light quickly
    func doubleTap() {
        light()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.light()
        }
    }
    
    // Success celebration - uses native vibration pattern
    func celebrate() {
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.light()
        }
    }
    
    // Delete pattern - warning + rigid
    func delete() {
        warning()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.rigid()
        }
    }
    
    // Toggle pattern - soft feedback
    func toggle() {
        soft()
    }
}
