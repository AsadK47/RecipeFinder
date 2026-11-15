import Foundation
import MetricKit

private let logger = AppLogger.logger(category: "Diagnostics")

/// Apple's on-device hang and crash reports (MetricKit), handed over by iOS on a later launch. Each is written to the
/// log with its call stack, so a freeze reported from TestFlight shows where the app hung (issue #16). The reports
/// stay on the device: they hold build numbers, binary names and code addresses, nothing the cook entered.
final class DiagnosticReporter: NSObject, MXMetricManagerSubscriber, Sendable {
    static let shared = DiagnosticReporter()

    func start() {
        MXMetricManager.shared.add(self)
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            for hang in payload.hangDiagnostics ?? [] {
                report(
                    DiagnosticSummary.hang(
                        seconds: hang.hangDuration.converted(to: .seconds).value,
                        build: hang.metaData.applicationBuildVersion,
                        os: hang.metaData.osVersion
                    ),
                    stack: hang.callStackTree
                )
            }
            for crash in payload.crashDiagnostics ?? [] {
                report(
                    DiagnosticSummary.crash(
                        exceptionType: crash.exceptionType?.intValue,
                        signal: crash.signal?.intValue,
                        reason: crash.terminationReason,
                        build: crash.metaData.applicationBuildVersion,
                        os: crash.metaData.osVersion
                    ),
                    stack: crash.callStackTree
                )
            }
        }
    }

    private func report(_ summary: String, stack: MXCallStackTree) {
        logger.error("\(summary, privacy: .public)")
        let parts = DiagnosticSummary.chunks(String(decoding: stack.jsonRepresentation(), as: UTF8.self))
        for (index, part) in parts.enumerated() {
            logger.error("stack \(index + 1)/\(parts.count): \(part, privacy: .public)")
        }
    }
}

/// How a MetricKit report reads in the log; pure so tests can pin it.
enum DiagnosticSummary {
    static func hang(seconds: Double, build: String, os: String) -> String {
        "Hang: main thread blocked \(String(format: "%.1f", seconds)) s (build \(build), \(os))"
    }

    static func crash(exceptionType: Int?, signal: Int?, reason: String?, build: String, os: String) -> String {
        let exception = exceptionType.map { " exception \($0)" } ?? ""
        let signalText = signal.map { " signal \($0)" } ?? ""
        let reasonText = reason.map { " — \($0)" } ?? ""
        return "Crash:\(exception)\(signalText)\(reasonText) (build \(build), \(os))"
    }

    /// The log cuts a single message at about 1 KB, so a call stack is written in numbered parts. At most `limit`
    /// parts: a runaway report must not flood the log; the top of the stack comes first.
    static func chunks(_ text: String, size: Int = 900, limit: Int = 60) -> [String] {
        guard size > 0, limit > 0 else { return [] }
        var parts: [String] = []
        var rest = Substring(text)
        while !rest.isEmpty, parts.count < limit {
            parts.append(String(rest.prefix(size)))
            rest = rest.dropFirst(size)
        }
        return parts
    }
}
