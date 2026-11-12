import Testing
import CoreGraphics
@testable import RecipeFinder

@Suite("Badge reveal")
struct BadgeRevealTests {

    // MARK: - Waiting for other sheets

    @Test func revealWaitsWhileAnotherSheetIsUp() {
        #expect(BadgeReveal.showing(.headChef, isAnotherSheetUp: true) == nil)
    }

    @Test func revealShowsOnceTheOtherSheetHasClosed() {
        #expect(BadgeReveal.showing(.headChef, isAnotherSheetUp: false) == .headChef)
    }

    @Test func nothingPendingShowsNothing() {
        #expect(BadgeReveal.showing(nil, isAnotherSheetUp: false) == nil)
    }

    // MARK: - Motion

    @Test func fullMotionFlipsSweepsCelebratesAndSettles() {
        let motion = BadgeReveal.motion(reduceMotion: false)
        #expect(motion.flipFromDegrees == 90)
        #expect(motion.sweepsShine)
        #expect(motion.firesConfetti)
        #expect(motion.settles)
    }

    @Test func reduceMotionShowsTheBadgeStill() {
        let motion = BadgeReveal.motion(reduceMotion: true)
        #expect(motion.flipFromDegrees == 0)
        #expect(!motion.sweepsShine)
        #expect(!motion.firesConfetti)
        #expect(!motion.settles)
    }

    // MARK: - Tilt to shine

    @Test func holdingThePhoneAsItWasOpenedCentresTheShine() {
        let offset = BadgeShine.offset(roll: 0.2, pitch: 0.8, baselineRoll: 0.2, baselinePitch: 0.8)
        #expect(offset == .zero)
    }

    @Test func tiltingRightMovesTheShineRight() {
        let offset = BadgeShine.offset(roll: 0.3, pitch: 0, baselineRoll: 0, baselinePitch: 0)
        #expect(offset.width == 0.5)
        #expect(offset.height == 0)
    }

    @Test func tiltingTheTopAwayMovesTheShineUp() {
        let offset = BadgeShine.offset(roll: 0, pitch: 1.1, baselineRoll: 0, baselinePitch: 0.8)
        #expect(offset.height < 0)
        #expect(offset.width == 0)
    }

    @Test(arguments: [3.0, -3.0])
    func aBigTiltStopsAtTheEdge(roll: Double) {
        let offset = BadgeShine.offset(roll: roll, pitch: -roll, baselineRoll: 0, baselinePitch: 0)
        #expect(abs(offset.width) == 1)
        #expect(abs(offset.height) == 1)
    }

    @Test func aBadSensorReadingKeepsTheShineCentred() {
        let offset = BadgeShine.offset(roll: .nan, pitch: .infinity, baselineRoll: 0, baselinePitch: 0)
        #expect(offset == .zero)
    }
}
