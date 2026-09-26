#if os(iOS)
import Foundation
import Observation

/// The three contextual bubbles of the first case (final handoff §D). No rules page: the player
/// learns by doing, in case #001, on the first play only.
///
/// 1 EXPLORER on the phone's home screen · 2 VERSER AU DOSSIER in a conversation that holds a
/// piece · 3 RELIER in the Carnet. One bubble at a time, never modal, each shown once, only while
/// more than 06:30 is left. Filing a piece skips bubble 2, linking one skips bubble 3.
/// Plus one soft nudge after 90 s in the phone without any piece filed.
@MainActor
@Observable
final class TutorialCoach {
    enum Bubble: Int, CaseIterable {
        case explore = 1, file, link
    }

    static let seenKey = "conclude.tutorialSeen"
    private static let nudgeKey = "conclude.tutorial.nudge"
    private static func doneKey(_ bubble: Bubble) -> String { "conclude.tutorial.done\(bubble.rawValue)" }

    /// Bubbles appear only while more than this is left on the timer (06:30).
    static let minimumRemaining: Double = 390
    /// The soft nudge comes after this many seconds without a piece.
    static let nudgeAfter: Double = 90

    /// The tutorial runs in this session (case #001, first play).
    let enabled: Bool
    /// The bubble on screen, if any.
    private(set) var active: Bubble?
    /// Bubble 2 points at this message.
    private(set) var fileTarget: String?

    /// Seconds left on the timer (set by the session).
    @ObservationIgnored var remaining: () -> Double = { .infinity }
    @ObservationIgnored private var pending: Task<Void, Never>?

    init(caseNumber: Int) {
        enabled = caseNumber == 1 && !UserDefaults.standard.bool(forKey: Self.seenKey)
    }

    /// Paramètres › « Revoir le tutoriel »: the bubbles come back on the next play of #001.
    static func replay() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: seenKey)
        defaults.removeObject(forKey: nudgeKey)
        for bubble in Bubble.allCases { defaults.removeObject(forKey: doneKey(bubble)) }
    }

    /// UI tests and returning players: no bubbles.
    static func markSeen() {
        UserDefaults.standard.set(true, forKey: seenKey)
    }

    // MARK: Events from the screens

    /// The phone's home screen is on screen.
    func homeAppeared() { show(.explore) }

    /// An app was opened (bubble 1 is answered by any tap on an app).
    func appOpened() { if active == .explore { done(.explore) } }

    /// A conversation is open; `evidenceMessage` is the first message in it that is a piece.
    func conversationOpened(evidenceMessage: String?) {
        pending?.cancel()
        guard enabled, let evidenceMessage, !isDone(.file) else { return }
        pending = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled, let self else { return }
            self.fileTarget = evidenceMessage
            self.show(.file)
        }
    }

    func conversationClosed() {
        pending?.cancel()
        if active == .file { done(.file) }
    }

    func carnetOpened() { show(.link) }

    func carnetClosed() { if active == .link { done(.link) } }

    /// The close button of a bubble, or a tap outside it.
    func dismiss() { if let active { done(active) } }

    /// A piece was filed: bubble 2 is no longer needed (and bubble 1 is answered).
    func pieceFiled() {
        if active == .explore { done(.explore) }
        done(.file)
    }

    /// A piece was linked to a suspect: bubble 3 is no longer needed.
    func linkMade() { done(.link) }

    /// Once, after 90 s in the phone with no piece filed.
    func shouldNudge(elapsed: Double, pieces: Int) -> Bool {
        guard enabled, pieces == 0, elapsed >= Self.nudgeAfter, !UserDefaults.standard.bool(forKey: Self.nudgeKey) else { return false }
        UserDefaults.standard.set(true, forKey: Self.nudgeKey)
        return true
    }

    // MARK: State

    private func show(_ bubble: Bubble) {
        guard enabled, active == nil, !isDone(bubble), remaining() > Self.minimumRemaining else { return }
        active = bubble
    }

    private func done(_ bubble: Bubble) {
        UserDefaults.standard.set(true, forKey: Self.doneKey(bubble))
        if active == bubble { active = nil }
        if bubble == .file { fileTarget = nil; pending?.cancel() }
        if Bubble.allCases.allSatisfy({ isDone($0) }) { UserDefaults.standard.set(true, forKey: Self.seenKey) }
    }

    private func isDone(_ bubble: Bubble) -> Bool {
        UserDefaults.standard.bool(forKey: Self.doneKey(bubble))
    }
}
#endif
