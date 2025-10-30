import UIKit
import AudioToolbox

/// Centralized haptic feedback manager for consistent tactile responses throughout the app
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // Light tap - for subtle interactions
    func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // Medium impact - for standard interactions
    func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    // Heavy impact - for important actions
    func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    // Soft impact - for very gentle feedback
    func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
    
    // Rigid impact - for firm, definitive actions
    func rigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }
    
    // Success notification - for successful operations
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // Warning notification - for warnings
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    // Error notification - for errors
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // Selection changed - for picker/selection changes
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
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
        // Trigger success haptic
        success()
        
        // Add a native vibration for emphasis
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        // Follow up with light haptic
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
