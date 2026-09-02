import Testing
@testable import RecipeFinder

@Suite struct OnDeviceRecipeImportStatusTests {

    @Test func onlyAvailableCaseReportsAvailable() {
        #expect(OnDeviceRecipeImportStatus.available.isAvailable)
        for status: OnDeviceRecipeImportStatus in [.deviceNotEligible, .appleIntelligenceNotEnabled, .modelNotReady, .unsupportedOS, .unknown] {
            #expect(!status.isAvailable)
        }
    }

    @Test(arguments: [
        OnDeviceRecipeImportStatus.available,
        .deviceNotEligible, .appleIntelligenceNotEnabled, .modelNotReady, .unsupportedOS, .unknown
    ])
    func everyCaseHasNonEmptyCopy(_ status: OnDeviceRecipeImportStatus) {
        #expect(!status.title.isEmpty)
        #expect(!status.detail.isEmpty)
    }

    @Test func unavailableCasesReassureThatSharingStillWorks() {
        for status: OnDeviceRecipeImportStatus in [.deviceNotEligible, .appleIntelligenceNotEnabled, .modelNotReady, .unsupportedOS, .unknown] {
            #expect(status.detail.localizedCaseInsensitiveContains("manual review"))
        }
    }
}
