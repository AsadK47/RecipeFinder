import Testing
@testable import RecipeFinder

/// How MetricKit hang and crash reports read in the log (issue #16). The MetricKit payloads themselves can't be built
/// in a test (Apple framework internals); the reporter only forwards their fields to these.
@Suite struct DiagnosticSummaryTests {
    @Test func aHangSaysHowLongAndWhichBuild() {
        #expect(DiagnosticSummary.hang(seconds: 12.345, build: "412", os: "iPhone OS 26.5.2")
            == "Hang: main thread blocked 12.3 s (build 412, iPhone OS 26.5.2)")
    }

    @Test func aCrashNamesWhatItKnows() {
        #expect(DiagnosticSummary.crash(exceptionType: 1, signal: 11, reason: "Namespace SIGNAL", build: "412", os: "iOS")
            == "Crash: exception 1 signal 11 — Namespace SIGNAL (build 412, iOS)")
        #expect(DiagnosticSummary.crash(exceptionType: nil, signal: nil, reason: nil, build: "412", os: "iOS")
            == "Crash: (build 412, iOS)")
    }

    @Test func aLongStackIsSplitIntoPartsThatJoinBack() {
        let stack = String(repeating: "0123456789", count: 25)

        let parts = DiagnosticSummary.chunks(stack, size: 100)

        #expect(parts.map(\.count) == [100, 100, 50])
        #expect(parts.joined() == stack)
    }

    @Test func aRunawayStackStopsAtTheLimitKeepingItsTop() {
        let parts = DiagnosticSummary.chunks(String(repeating: "a", count: 1_000), size: 10, limit: 3)

        #expect(parts.count == 3)
        #expect(parts.joined() == String(repeating: "a", count: 30))
    }

    @Test(arguments: [(size: 0, limit: 5), (size: 5, limit: 0)])
    func nonsenseLimitsWriteNothing(size: Int, limit: Int) {
        #expect(DiagnosticSummary.chunks("stack", size: size, limit: limit).isEmpty)
    }

    @Test func anEmptyStackWritesNothing() {
        #expect(DiagnosticSummary.chunks("").isEmpty)
    }
}
