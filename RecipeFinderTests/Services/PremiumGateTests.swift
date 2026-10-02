import Testing
@testable import RecipeFinder

/// Pure gating logic for the freemium power-feature cap.
@Suite struct PremiumGateTests {

    @Test func launchPosture_isFree() {
        // Guards against accidentally shipping with the cap enforced.
        #expect(PremiumGate.isEnabled == false)
    }

    @Test(arguments: PremiumFeature.allCases)
    func gatingDisabled_everythingUnlocked(_ feature: PremiumFeature) {
        #expect(PremiumGate.isUnlocked(feature, isSubscribed: false, gatingEnabled: false))
        #expect(PremiumGate.isUnlocked(feature, isSubscribed: true, gatingEnabled: false))
    }

    @Test(arguments: PremiumFeature.allCases)
    func gatingEnabled_lockedForNonSubscriber(_ feature: PremiumFeature) {
        #expect(!PremiumGate.isUnlocked(feature, isSubscribed: false, gatingEnabled: true))
    }

    @Test(arguments: PremiumFeature.allCases)
    func gatingEnabled_unlockedForSubscriber(_ feature: PremiumFeature) {
        #expect(PremiumGate.isUnlocked(feature, isSubscribed: true, gatingEnabled: true))
    }
}
