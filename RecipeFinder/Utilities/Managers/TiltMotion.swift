import CoreMotion
import Observation
import CoreGraphics

/// Device tilt for the badge pager's shine. View-owned; started only while the pager is on screen with Reduce Motion
/// off, so the motion sensors are idle the rest of the time. No-op where device motion isn't available (Simulator).
@MainActor
@Observable
final class TiltMotion {
    /// -1…1 per axis; see `BadgeShine.offset`.
    private(set) var shine: CGSize = .zero

    @ObservationIgnored private let manager = CMMotionManager()
    @ObservationIgnored private var baselineRoll: Double?
    @ObservationIgnored private var baselinePitch: Double?

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        baselineRoll = nil
        baselinePitch = nil
        manager.deviceMotionUpdateInterval = 1.0 / 30
        // Delivered on the main queue, so hopping back onto the main actor is safe.
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let attitude = motion?.attitude else { return }
            let roll = attitude.roll
            let pitch = attitude.pitch
            MainActor.assumeIsolated {
                self?.update(roll: roll, pitch: pitch)
            }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        shine = .zero
    }

    private func update(roll: Double, pitch: Double) {
        let baseRoll = baselineRoll ?? roll
        let basePitch = baselinePitch ?? pitch
        baselineRoll = baseRoll
        baselinePitch = basePitch
        shine = BadgeShine.offset(roll: roll, pitch: pitch, baselineRoll: baseRoll, baselinePitch: basePitch)
    }
}
