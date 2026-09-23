import Foundation

/// Source of real "now" for the investigation timer.
///
/// The engine never calls `Date()` itself. Tests and CaseLint inject a `ManualClock` so a whole
/// 8-minute investigation can be simulated in milliseconds.
public protocol GameClock: Sendable {
    var now: Date { get }
}

/// Real wall-clock time, used by the shipping app.
public struct SystemClock: GameClock {
    public init() {}
    public var now: Date { Date() }
}

/// A clock that only moves when told to. Thread-safe.
public final class ManualClock: GameClock, @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date

    public init(start: Date = Date(timeIntervalSinceReferenceDate: 0)) {
        self.current = start
    }

    public var now: Date {
        lock.lock(); defer { lock.unlock() }
        return current
    }

    /// Moves time forward. Negative values are ignored.
    public func advance(by seconds: TimeInterval) {
        guard seconds > 0 else { return }
        lock.lock(); defer { lock.unlock() }
        current = current.addingTimeInterval(seconds)
    }

    /// Jumps to an absolute date (can go backwards, to test clock-tampering protections).
    public func set(_ date: Date) {
        lock.lock(); defer { lock.unlock() }
        current = date
    }
}
