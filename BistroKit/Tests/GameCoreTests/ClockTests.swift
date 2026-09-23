import Foundation
import Testing
@testable import GameCore

@Suite("Clock")
struct ClockTests {
    @Test func manualClockOnlyMovesWhenAdvanced() {
        let clock = ManualClock(start: Date(timeIntervalSince1970: 1_000))
        #expect(clock.now == Date(timeIntervalSince1970: 1_000))
        clock.advance(by: 3_600)
        #expect(clock.now == Date(timeIntervalSince1970: 4_600))
    }

    @Test func manualClockIgnoresNegativeAdvance() {
        let clock = ManualClock(start: Date(timeIntervalSince1970: 1_000))
        clock.advance(by: -50)
        #expect(clock.now == Date(timeIntervalSince1970: 1_000))
    }

    @Test func simulatingThirtyDaysIsInstant() {
        let clock = ManualClock()
        let start = clock.now
        for _ in 0..<(30 * 24 * 60) { clock.advance(by: 60) }
        #expect(clock.now.timeIntervalSince(start) == 30 * 24 * 3_600)
    }
}
