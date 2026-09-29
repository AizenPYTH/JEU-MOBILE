#if os(iOS)
import Foundation
import Observation

/// The onboarding tips (handoff UX V3 §7). No rules page, no other help text: the player learns by
/// doing, and each tip shows once per install (`tip_*` flags in UserDefaults).
///
/// - `tip_messages` (#001 only): on the phone's home screen, the Messages icon pulses and a BEN
///   bubble says « Commencez par les messages. », until the first tap on an app.
/// - `tip_touch_to_file` (#001 only): in the first conversation, the first versable bubble pulses
///   once and a BEN bubble says « Touchez un message pour le verser au dossier. », until the
///   player touches an element (or files one).
/// - `tip_first_piece` (any case): the EvidenceSheet of the very first piece adds « Retrouvez-la
///   dans le Carnet. ».
///
/// `Bubble` keeps its former cases (`.link` is never shown any more) so that older callers compile.
@MainActor
@Observable
final class TutorialCoach {
    enum Bubble: Int, CaseIterable {
        /// « Commencez par les messages. » (home screen).
        case explore = 1
        /// « Touchez un message pour le verser au dossier. » (first conversation).
        case file
        /// Former Carnet bubble: never shown in V3.
        case link
    }

    /// The per-install flags (§7). `replay()` clears them (Paramètres › « Réinitialiser les conseils »).
    enum Tip: String, CaseIterable {
        case messages = "tip_messages"
        case touchToFile = "tip_touch_to_file"
        case firstPiece = "tip_first_piece"
    }

    /// Former flag of the three-bubble tutorial (cleared by `replay()` too).
    static let seenKey = "conclude.tutorialSeen"
    private static let legacyKeys = ["conclude.tutorialSeen", "conclude.tutorial.nudge",
                                     "conclude.tutorial.done1", "conclude.tutorial.done2", "conclude.tutorial.done3"]

    /// Kept for callers; tips no longer depend on the time left.
    static let minimumRemaining: Double = 0

    /// The #001 bubbles run in this session (case #001, tips not seen yet).
    let enabled: Bool
    /// The bubble on screen, if any.
    private(set) var active: Bubble?
    /// Bubble 2 points at this message.
    private(set) var fileTarget: String?

    /// Seconds left on the timer (set by the session; kept for callers).
    @ObservationIgnored var remaining: () -> Double = { .infinity }
    @ObservationIgnored private var pending: Task<Void, Never>?

    init(caseNumber: Int) {
        enabled = caseNumber == 1 && !(Self.isSeen(.messages) && Self.isSeen(.touchToFile))
    }

    /// Paramètres › « Réinitialiser les conseils »: every tip shows again.
    static func replay() {
        let defaults = UserDefaults.standard
        for tip in Tip.allCases { defaults.removeObject(forKey: tip.rawValue) }
        for key in legacyKeys { defaults.removeObject(forKey: key) }
    }

    /// UI tests and returning players: no tips.
    static func markSeen() {
        for tip in Tip.allCases { UserDefaults.standard.set(true, forKey: tip.rawValue) }
    }

    static func isSeen(_ tip: Tip) -> Bool { UserDefaults.standard.bool(forKey: tip.rawValue) }

    private static func setSeen(_ tip: Tip) { UserDefaults.standard.set(true, forKey: tip.rawValue) }

    // MARK: Events from the screens

    /// The phone's home screen is on screen.
    func homeAppeared() { show(.explore) }

    /// An app was opened: the Messages tip is answered.
    func appOpened() { if active == .explore { done(.explore) } }

    /// A conversation is open; `evidenceMessage` is the message the bubble points at.
    func conversationOpened(evidenceMessage: String?) {
        pending?.cancel()
        guard enabled, let evidenceMessage, !isDone(.file) else { return }
        pending = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled, let self else { return }
            self.fileTarget = evidenceMessage
            self.show(.file)
        }
    }

    func conversationClosed() {
        pending?.cancel()
        // Not answered yet: it comes back in the next conversation.
        if active == .file { active = nil; fileTarget = nil }
    }

    /// Former Carnet bubble: nothing in V3.
    func carnetOpened() {}

    func carnetClosed() {}

    /// The close button of a bubble.
    func dismiss() { if let active { done(active) } }

    /// An element of the phone was touched (selected): the « Touchez un message » tip is answered.
    func elementSelected() {
        if active == .explore { done(.explore) }
        if enabled, active == .file || fileTarget != nil { done(.file) }
    }

    /// A piece was filed: both #001 bubbles are answered.
    func pieceFiled() {
        if active == .explore { done(.explore) }
        if enabled { done(.file) }
    }

    /// Kept for callers (the former bubble 3).
    func linkMade() {}

    /// The help lines of the EvidenceSheet for a piece just filed (§7-6), each shown once per install.
    func filingTips() -> [String] {
        guard !Self.isSeen(.firstPiece) else { return [] }
        Self.setSeen(.firstPiece)
        return [L10n.t("tip.firstPiece")]
    }

    /// The former 90 s nudge: gone (V3 §7, « aucun autre texte d'aide »).
    func shouldNudge(elapsed: Double, pieces: Int) -> Bool { false }

    // MARK: State

    private func show(_ bubble: Bubble) {
        guard enabled, bubble != .link, active == nil, !isDone(bubble) else { return }
        active = bubble
    }

    private func done(_ bubble: Bubble) {
        switch bubble {
        case .explore: Self.setSeen(.messages)
        case .file:
            Self.setSeen(.touchToFile)
            fileTarget = nil
            pending?.cancel()
        case .link: break
        }
        if active == bubble { active = nil }
    }

    private func isDone(_ bubble: Bubble) -> Bool {
        switch bubble {
        case .explore: Self.isSeen(.messages)
        case .file: Self.isSeen(.touchToFile)
        case .link: true
        }
    }
}
#endif
