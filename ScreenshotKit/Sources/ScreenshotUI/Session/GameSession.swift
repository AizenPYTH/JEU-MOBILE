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
    /// "◆ Ajouté au carnet · n" / "Retiré du carnet".
    private var lowBatteryWarned = false
    private(set) var toast: Toast?
    /// The phone's clock, to the minute. The only source of phone time is `Investigation.phoneNow`
    /// (case start + everything spent: the same elapsed time as the timer); it is published here so
    /// that screens showing the time redraw when the minute changes.
    private(set) var phoneTime: Moment

    private let investigation: Investigation
    @ObservationIgnored private var loop: Task<Void, Never>?
    @ObservationIgnored private var ticksSinceSave = 0
    @ObservationIgnored private var bannerTask: Task<Void, Never>?
    @ObservationIgnored private var bannerQueue: [PhoneNotification] = []
    @ObservationIgnored private var costTask: Task<Void, Never>?
    @ObservationIgnored private var toastTask: Task<Void, Never>?
    private let onFinish: (Verdict) -> Void

    struct TimeCostFlash: Equatable, Identifiable {
        let id: Int
        let seconds: Int
    }

    struct Toast: Equatable, Identifiable {
        let id: Int
        let text: String
        /// Second line: what was pinned / where to find it.
        var detail: String? = nil
        var kind: Kind = .neutral

        enum Kind: Equatable { case neutral, pinned, linked }
    }

    enum TimerLevel: Equatable {
        case normal, low, critical
    }

    var timerLevel: TimerLevel {
        if remainingSeconds <= Double(rules.criticalTimeSeconds) { return .critical }
        if remainingSeconds <= Double(rules.lowTimeWarningSeconds) { return .low }
        return .normal
    }

    /// 0…1 of the case duration still available (status bar track).
    /// Battery of the seized phone (%): from the case's starting level down to a few percent at the
    /// end of the timer. Display only.
    var batteryLevel: Int {
        let start = 23.0, end = 4.0
        return Int((end + (start - end) * timeProgress).rounded())
    }

    var timeProgress: Double { investigation.durationSeconds > 0 ? remainingSeconds / investigation.durationSeconds : 0 }

    convenience init(caseFile: CaseFile, rules: GameRules, clock: any GameClock = SystemClock(), onFinish: @escaping (Verdict) -> Void) {
        self.init(investigation: Investigation(caseFile: caseFile, rules: rules, clock: clock), path: [], onFinish: onFinish)
    }

    /// Resumes a saved investigation on the screen the player left (opening it again costs nothing).
    convenience init?(restoring saved: SavedInvestigation, caseFile: CaseFile, rules: GameRules,
                      clock: any GameClock = SystemClock(), onFinish: @escaping (Verdict) -> Void) {
        guard let investigation = Investigation(restoring: saved.snapshot, caseFile: caseFile, rules: rules, clock: clock) else { return nil }
        self.init(investigation: investigation, path: saved.path, onFinish: onFinish)
    }

    private init(investigation: Investigation, path: [PhoneRoute], onFinish: @escaping (Verdict) -> Void) {
        self.investigation = investigation
        self.remainingSeconds = investigation.remainingSeconds
        self.phase = investigation.phase
        self.phoneTime = Self.minute(of: investigation.phoneNow)
        self.path = path
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

    /// Starts a new investigation, or carries on with a restored one.
    func begin() {
        if investigation.phase == .briefing { investigation.start() } else { investigation.resume() }
        if investigation.phase == .investigating { startLoop() }
        refresh()
    }

    func pause() {
        investigation.pause()
        loop?.cancel()
        loop = nil
        save()
    }

    /// Saves the investigation in progress (cleared once the case is over).
    func save() {
        ticksSinceSave = 0
        if let snapshot = investigation.snapshot() {
            SavedInvestigationStore.save(SavedInvestigation(snapshot: snapshot, path: path))
        } else {
            SavedInvestigationStore.clear()
        }
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
        warnLowBatteryIfNeeded()
        ticksSinceSave += 1
        if ticksSinceSave >= 20 { save() } // every ~5 s, in case the app is killed without warning
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
        let minute = Self.minute(of: investigation.phoneNow)
        if minute != phoneTime {
            phoneTime = minute
            changed = true // relative times ("il y a 2 min") in the apps move too
        }
        if changed {
            revision += 1
            save()
        }
    }

    /// The seized phone's own "Batterie faible" alert, once, when it reaches 10 % (display only:
    /// not a case notification, not listed in the Notifications app).
    private func warnLowBatteryIfNeeded() {
        guard !lowBatteryWarned, phase == .investigating, batteryLevel <= 10 else { return }
        lowBatteryWarned = true
        enqueueBanner(PhoneNotification(id: "system.lowBattery", app: .settings, title: L10n.t("system.lowBatteryTitle"),
                                        body: L10n.f("system.lowBatteryBody", batteryLevel), at: investigation.phoneNow))
        Haptics.notification()
    }

    private static func minute(of moment: Moment) -> Moment {
        moment.adding(seconds: -Int64(moment.second))
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
        case .search: break // opening the search is free; each query costs time
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

    /// Phone-wide search (screen 11).
    func searchPhone(_ query: String) -> [PhoneSearchResult] {
        let results = investigation.searchPhone(query)
        refresh()
        return results
    }

    /// Opens a search result in its own app (the usual time costs apply).
    func open(_ result: PhoneSearchResult) {
        switch result.ref.kind {
        case .message:
            if let conversation = result.conversationID { launch(.messages, then: .conversation(conversation, focus: result.ref.id)) }
        case .calendar: launch(.calendar, then: .calendarEvent(result.ref.id))
        case .note: launch(.notes, then: .note(result.ref.id))
        case .mail: launch(.mail, then: .mail(result.ref.id))
        case .browser: launch(.browser, then: .browserEntry(result.ref.id))
        case .contact: launch(.contacts, then: .contact(result.ref.id))
        default: break
        }
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

    // MARK: Notebook

    func isPinned(_ ref: ItemRef) -> Bool { game.isPinned(ref) }

    func togglePin(_ ref: ItemRef) {
        let pinned = investigation.togglePin(ref)
        Haptics.pin()
        if pinned {
            let label = ItemDescriber.describe(ref, in: investigation).label
            showToast(L10n.f("toast.pinned", investigation.notebook.count), detail: label, kind: .pinned)
        } else {
            showToast(L10n.t("toast.unpinned"))
        }
        refresh()
    }

    func link(_ ref: ItemRef, to suspect: SuspectID?) {
        investigation.link(ref, to: suspect)
        Haptics.pin()
        if let suspect, let s = investigation.index.suspect(suspect) {
            showToast(L10n.f("toast.linked", investigation.name(of: s.contact)), detail: L10n.t("toast.linkedDetail"), kind: .linked)
        }
        refresh()
    }

    /// The player's reading of a linked item (against / in favour of the suspect). Free.
    func setStance(_ stance: NotebookEntry.Stance?, for ref: ItemRef) {
        investigation.setStance(stance, for: ref)
        Haptics.selection()
        refresh()
    }

    private func showToast(_ text: String, detail: String? = nil, kind: Toast.Kind = .neutral) {
        let toast = Toast(id: (self.toast?.id ?? 0) + 1, text: text, detail: detail, kind: kind)
        self.toast = toast
        toastTask?.cancel()
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(toast.detail == nil ? 2 : 2.6))
            guard !Task.isCancelled, self?.toast == toast else { return }
            self?.toast = nil
        }
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
        refresh() // the case is over: this also clears the saved investigation
        onFinish(verdict)
    }

    // MARK: Banners (1 visible, up to 3 waiting, urgent > important > normal)

    private func enqueueBanner(_ n: PhoneNotification) {
        if n.level == .urgent { Haptics.urgent() }
        guard let current = banner else { show(n); return }
        if n.level > current.level && current.level != .urgent {
            bannerQueue.insert(current, at: 0)
            show(n)
        } else {
            bannerQueue.append(n)
            bannerQueue.sort { $0.level > $1.level }
            if bannerQueue.count > 3 { bannerQueue.removeLast() }
        }
    }

    private func show(_ n: PhoneNotification) {
        banner = n
        bannerTask?.cancel()
        guard n.level != .urgent else { return } // urgent stays until the player acts
        let seconds = n.level == .important ? rules.bannerSeconds + 1.5 : rules.bannerSeconds
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
/// UIKit feedback generators are main-actor isolated.
@MainActor
enum Haptics {
    static func notification() {
        guard Preferences.vibrations else { return }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    static func warning() {
        guard Preferences.vibrations else { return }
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }

    static func timeUp() {
        guard Preferences.vibrations else { return }
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }

    static func pin() {
        guard Preferences.vibrations else { return }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    static func urgent() {
        guard Preferences.vibrations else { return }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        #endif
    }

    static func success() {
        guard Preferences.vibrations else { return }
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    static func selection() {
        guard Preferences.vibrations else { return }
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
}
#endif
