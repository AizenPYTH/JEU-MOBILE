#if os(iOS)
import Foundation
import Observation
import CaseEngine
#if canImport(UIKit)
import UIKit
#endif

/// Bridge between the investigation engine and SwiftUI.
///
/// Runs the timer (4 ticks per second), turns navigation into timed engine actions, shows
/// notification banners and publishes changes. Contains no game rules.
@MainActor
@Observable
final class GameSession {
    /// Seconds left, updated every tick (the timer view only depends on this).
    private(set) var remainingSeconds: Double
    private(set) var phase: Investigation.Phase
    /// Bumped whenever the phone's content or the investigation state changes.
    private(set) var revision = 0
    /// In-phone navigation (empty = home screen).
    private(set) var path: [PhoneRoute] = []
    /// Notification currently shown as a banner.
    private(set) var banner: PhoneNotification?
    /// Last time cost, flashed next to the timer ("−8 s").
    private(set) var lastCost: TimeCostFlash?

    @ObservationIgnored private let investigation: Investigation
    @ObservationIgnored private var loop: Task<Void, Never>?
    @ObservationIgnored private var bannerTask: Task<Void, Never>?
    @ObservationIgnored private var bannerQueue: [PhoneNotification] = []
    @ObservationIgnored private var costTask: Task<Void, Never>?
    @ObservationIgnored private let onFinish: (Verdict) -> Void

    struct TimeCostFlash: Equatable, Identifiable {
        let id: Int
        let seconds: Int
    }

    init(caseFile: CaseFile, rules: GameRules, clock: any GameClock = SystemClock(), onFinish: @escaping (Verdict) -> Void) {
        let investigation = Investigation(caseFile: caseFile, rules: rules, clock: clock)
        self.investigation = investigation
        self.remainingSeconds = investigation.remainingSeconds
        self.phase = investigation.phase
        self.onFinish = onFinish
    }

    /// The engine. Reading it through this property subscribes the view to `revision`.
    var game: Investigation {
        _ = revision
        return investigation
    }

    var caseFile: CaseFile { investigation.caseFile }
    var rules: GameRules { investigation.rules }

    // MARK: Lifecycle

    func begin() {
        investigation.start()
        startLoop()
        refresh()
    }

    func pause() {
        investigation.pause()
        loop?.cancel()
        loop = nil
    }

    func resume() {
        guard phase == .investigating else { return }
        investigation.resume()
        startLoop()
    }

    private func startLoop() {
        guard loop == nil else { return }
        loop = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                self?.tick()
            }
        }
    }

    private func tick() {
        investigation.tick()
        refresh(contentChanged: false)
    }

    /// Pulls engine state and events into observable properties.
    private func refresh(contentChanged: Bool = true) {
        remainingSeconds = investigation.remainingSeconds
        var changed = contentChanged
        for event in investigation.drainEvents() {
            switch event {
            case .notification(let n):
                enqueueBanner(n)
                Haptics.notification()
                changed = true
            case .timeSpent(let seconds, _):
                flashCost(seconds)
            case .lowTime:
                Haptics.warning()
            case .timeUp:
                Haptics.timeUp()
                changed = true
            }
        }
        if phase != investigation.phase {
            phase = investigation.phase
            changed = true
            if phase != .investigating { loop?.cancel(); loop = nil }
        }
        if changed { revision += 1 }
    }

    private func flashCost(_ seconds: Int) {
        let flash = TimeCostFlash(id: (lastCost?.id ?? 0) + 1, seconds: seconds)
        lastCost = flash
        costTask?.cancel()
        costTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled, self?.lastCost == flash else { return }
            self?.lastCost = nil
        }
    }

    // MARK: Phone navigation (each opened screen costs its time)

    func setPath(_ newPath: [PhoneRoute]) {
        let old = path
        path = newPath
        if newPath.count > old.count {
            for route in newPath[old.count...] { charge(for: route) }
        }
        refresh()
    }

    func open(_ route: PhoneRoute) {
        setPath(path + [route])
    }

    /// Opens an app from the home screen or a notification (replaces the current stack).
    func launch(_ app: AppID, then route: PhoneRoute? = nil) {
        path = []
        setPath(route.map { [.app(app), $0] } ?? [.app(app)])
    }

    func goHome() {
        path = []
        revision += 1
    }

    private func charge(for route: PhoneRoute) {
        switch route {
        case .app(let app): investigation.openApp(app)
        case .conversation(let id, let focus):
            investigation.openConversation(id)
            if let focus { investigation.reveal(messageID: focus) }
        case .contact(let id): investigation.openContact(id)
        case .photo(let id): investigation.openPhoto(id)
        case .track(let id): investigation.openTrack(id)
        case .calendarEvent(let id): investigation.openCalendarEvent(id)
        case .note(let id): investigation.openNote(id)
        case .mail(let id): investigation.openMail(id)
        case .browserEntry(let id): investigation.openBrowserEntry(id)
        }
    }

    /// Opens what a notification points to.
    func open(_ notification: PhoneNotification) {
        dismissBanner()
        guard let ref = notification.opens else { launch(notification.app); return }
        switch ref.kind {
        case .message:
            if let conversation = investigation.index.conversationID(ofMessage: ref.id) {
                launch(.messages, then: .conversation(conversation, focus: ref.id))
            } else {
                launch(.messages)
            }
        case .call: launch(.phone)
        case .calendar: launch(.calendar, then: .calendarEvent(ref.id))
        case .photo, .photoInfo: launch(.photos, then: .photo(ref.id))
        default: launch(notification.app)
        }
    }

    // MARK: Actions

    func perform(_ action: (Investigation) -> Void) {
        action(investigation)
        refresh()
    }

    func search(_ query: String) -> [SearchHit] {
        let hits = investigation.search(query)
        refresh()
        return hits
    }

    func unlock(_ app: AppID, code: String) -> Bool {
        let ok = investigation.unlock(app, code: code)
        if !ok { Haptics.warning() }
        refresh()
        return ok
    }

    func markSeen(_ ref: ItemRef) {
        guard !investigation.seen.contains(ref) else { return }
        investigation.markSeen(ref) // no refresh: seeing is free and silent
    }

    func useHint() -> Hint? {
        let hint = investigation.useHint()
        refresh()
        return hint
    }

    func requestAccusation() {
        investigation.requestAccusation()
        refresh()
    }

    func resumeInvestigation() {
        investigation.cancelAccusation()
        if investigation.phase == .investigating { startLoop() }
        refresh()
    }

    func accuse(_ suspect: SuspectID) {
        guard let verdict = investigation.accuse(suspect) else { return }
        loop?.cancel(); loop = nil
        refresh()
        onFinish(verdict)
    }

    // MARK: Banners

    private func enqueueBanner(_ n: PhoneNotification) {
        if banner == nil { show(n) } else { bannerQueue.append(n) }
    }

    private func show(_ n: PhoneNotification) {
        banner = n
        bannerTask?.cancel()
        let seconds = rules.bannerSeconds
        bannerTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            self?.dismissBanner()
        }
    }

    func dismissBanner() {
        bannerTask?.cancel()
        banner = nil
        if !bannerQueue.isEmpty { show(bannerQueue.removeFirst()) }
    }
}

/// Light, meaningful haptics only: a notification, the last minute, the end.
enum Haptics {
    static func notification() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    static func warning() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }

    static func timeUp() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }

    static func selection() {
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
}
#endif
