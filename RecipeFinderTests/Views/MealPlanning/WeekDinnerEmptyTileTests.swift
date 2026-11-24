import Testing
import SwiftUI
import ViewInspector
@testable import RecipeFinder

/// Plan's empty dinner nights. A missed night was drawn as a disabled button inside a tile already dimmed to 0.55,
/// so SwiftUI dimmed it twice and "No dinner planned" was near-invisible (reviewer 2026-11-21, 04-meal-plan).
@MainActor
@Suite struct WeekDinnerEmptyTileTests {

    /// Single-threaded under `@MainActor`; holds the date a tap planned.
    private final class Box: @unchecked Sendable { var planned: Date? }

    private let date = Date(timeIntervalSince1970: 1_795_000_000)

    private func tile(isPast: Bool, _ box: Box = Box()) -> WeekDinnerEmptyTile<Text> {
        WeekDinnerEmptyTile(
            night: WeekDinners.Night(date: date, plan: nil, recipe: nil, isToday: false, isPast: isPast),
            spokenDay: "Sunday 22", dayLabel: Text("Sun 22"), onPlan: { box.planned = $0 }
        )
    }

    @Test func missedNightIsNotADisabledButton() throws {
        let view = try tile(isPast: true).inspect()
        _ = try view.find(text: "No dinner planned")
        #expect(throws: (any Error).self) { try view.find(ViewType.Button.self) }
    }

    @Test func voiceOverNamesAMissedNight() throws {
        let spoken = try tile(isPast: true).inspect().vStack().accessibilityLabel().string()
        #expect(spoken == "Sunday 22, no dinner planned")
    }

    @Test func voiceOverNamesANightAhead() throws {
        let spoken = try tile(isPast: false).inspect().button().accessibilityLabel().string()
        #expect(spoken == "Sunday 22, no dinner planned")
    }

    @Test func nightAheadPlansItsDateOnTap() throws {
        let box = Box()
        let view = try tile(isPast: false, box).inspect()
        _ = try view.find(text: "Plan dinner")
        try view.find(ViewType.Button.self).tap()
        #expect(box.planned == date)
    }
}
