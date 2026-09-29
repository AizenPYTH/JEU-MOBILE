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
    /// The EvidenceSheet on screen (UX V3 §6-05): the element just filed (or already in the file),
    /// its piece number and the help line. nil = no sheet.
    private(set) var receipt: FilingReceipt?
    /// The element whose EvidenceSheet is open (kept for callers: `receipt?.ref`).
    var filingCandidate: ItemRef? { receipt?.ref }
    /// The last piece filed: a copy of it flies to the Carnet button (§6-05).
    private(set) var lastFiled: FiledPiece?
    /// The element of the phone the player touched (§6-04): it wears a ben ring and the
    /// EvidenceBadge « + Verser au dossier » (or « ✓ Pièce 03 ») under it. Any element can be
    /// selected: the game never tells which ones matter.
    private(set) var selected: ItemRef?
    /// When `selected` was set: the tap that selects an element also reaches the screen behind it,
    /// which must not clear it at once (see `clearSelectionAfterTap`).
    @ObservationIgnored private var selectedAt = Date.distantPast
    /// When the phone last changed screen: a tap that opened a screen does not also select the
    /// element it started on.
    @ObservationIgnored private var navigatedAt = Date.distantPast
    /// « Voir la pièce » / « Relier »: the Carnet is asked to open on a piece (the shell opens it).
    private(set) var carnetRequest: CarnetRequest?
    /// The clock is stopped (app sent to the background, pause sheet): the investigation bar reads
    /// « En pause » until the player touches the phone again.
    private(set) var isPaused = false
    /// The onboarding tips (UX V3 §7).
    let coach: TutorialCoach

    private let investigation: Investigation
    @ObservationIgnored private var loop: Task<Void, Never>?
    @ObservationIgnored private var ticksSinceSave = 0
    @ObservationIgnored private var bannerTask: Task<Void, Never>?
    @ObservationIgnored private var bannerQueue: [PhoneNotification] = []
    @ObservationIgnored private var costTask: Task<Void, Never>?
    @ObservationIgnored private var toastTask: Task<Void, Never>?
    /// Last whole second announced by the critical-time tick.
    @ObservationIgnored private var lastTickSecond = -1
    /// Last time left announced to VoiceOver (each minute, then 30 s and 10 s).
    @ObservationIgnored private var lastSpokenMark = -1
    private let onFinish: (Verdict) -> Void
    /// The save file of this investigation (the story mode keeps its own).
    let slot: SaveSlot

    /// A piece just put in the file (number = its place in filing order).
    struct FiledPiece: Equatable, Identifiable {
        let id: Int
        let number: Int
        let ref: ItemRef
    }

    /// What the EvidenceSheet shows (§6-05).
    struct FilingReceipt: Equatable, Identifiable {
        let id: Int
        let ref: ItemRef
        /// Its piece number (« PIÈCE 03 »).
        let number: Int?
        /// true: filed by this gesture; false: it was already in the file.
        let isNew: Bool
        /// The one-time tips of §7 (« Retrouvez-la dans le Carnet. »…).
        let help: [String]
    }

    /// The Carnet, opened on a piece (« Voir la pièce ») or to connect it (« Relier »).
    struct CarnetRequest: Equatable, Identifiable {
        let id: Int
        let ref: ItemRef
        let connect: Bool
    }

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

    /// Battery of the seized phone (%): from the level it was handed over with (`Device.batteryPercent`)
    /// down as the timer runs. Display only.
    var batteryLevel: Int {
        let start = Double(investigation.device.batteryPercent ?? 23)
        // A phone handed over nearly empty ends the investigation almost dead; a fuller one loses ~20 %.
        let end = min(start, max(3.0, start - 20))
        return Int((end + (start - end) * timeProgress).rounded())
    }

    /// 0…1 of the case duration still available (status bar track).
    var timeProgress: Double { investigation.durationSeconds > 0 ? remainingSeconds / investigation.durationSeconds : 0 }

    /// `caseFile` is the case as played at `challenge` (see `CaseFile.configured(for:rules:)`).
    convenience init(caseFile: CaseFile, rules: GameRules, challenge: Challenge = .detective,
                     clock: any GameClock = SystemClock(), slot: SaveSlot = .main,
                     onFinish: @escaping (Verdict) -> Void) {
        self.init(investigation: Investigation(caseFile: caseFile, rules: rules, clock: clock, challenge: challenge),
                  path: [], slot: slot, onFinish: onFinish)
    }

    /// Resumes a saved investigation on the screen the player left (opening it again costs nothing).
    convenience init?(restoring saved: SavedInvestigation, caseFile: CaseFile, rules: GameRules,
                      clock: any GameClock = SystemClock(), slot: SaveSlot = .main,
                      onFinish: @escaping (Verdict) -> Void) {
        guard let investigation = Investigation(restoring: saved.snapshot, caseFile: caseFile, rules: rules, clock: clock) else { return nil }
        self.init(investigation: investigation, path: saved.path, slot: slot, onFinish: onFinish)
    }

    private init(investigation: Investigation, path: [PhoneRoute], slot: SaveSlot, onFinish: @escaping (Verdict) -> Void) {
        self.investigation = investigation
        self.slot = slot
        self.remainingSeconds = investigation.remainingSeconds
        self.phase = investigation.phase
        self.phoneTime = Self.minute(of: investigation.phoneNow)
        self.path = path
        self.onFinish = onFinish
        self.coach = TutorialCoach(caseNumber: investigation.caseFile.number)
        coach.remaining = { [weak self] in self?.remainingSeconds ?? 0 }
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
        isPaused = false
        if investigation.phase == .investigating { startLoop() }
        refresh()
    }

    func pause() {
        investigation.pause()
        isPaused = phase == .investigating
        loop?.cancel()
        loop = nil
        save()
    }

    /// Saves the investigation in progress (cleared once the case is over).
    func save() {
        ticksSinceSave = 0
        if let snapshot = investigation.snapshot() {
            SavedInvestigationStore.save(SavedInvestigation(snapshot: snapshot, path: path), slot: slot)
        } else {
            SavedInvestigationStore.clear(slot)
        }
    }

    func resume() {
        guard phase == .investigating else { return }
        investigation.resume()
        isPaused = false
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
        announceCriticalSecond()
        announceTimeForVoiceOver()
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
            if phase != .investigating {
                loop?.cancel(); loop = nil
                // Time up (or concluding): the EvidenceSheet closes with everything else.
                receipt = nil
                selected = nil
                isPaused = false
            }
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

    /// Under 01:00, a discreet tick each second; under 00:10, a light haptic too (§F-05).
    private func announceCriticalSecond() {
        guard phase == .investigating, remainingSeconds > 0, remainingSeconds <= 60 else { return }
        let second = Int(remainingSeconds.rounded(.up))
        guard second != lastTickSecond else { return }
        lastTickSecond = second
        AudioDirector.shared.play(.tick, volume: 0.22)
        if remainingSeconds <= 10 { Haptics.light() }
    }

    /// VoiceOver hears the time left each minute, then at 30 s and at 10 s (§9).
    private func announceTimeForVoiceOver() {
        #if canImport(UIKit)
        guard UIAccessibility.isVoiceOverRunning, phase == .investigating, !isPaused else { return }
        let second = Int(remainingSeconds.rounded(.up))
        let mark: Int
        if second > 30 && second % 60 == 0 { mark = second } else if second == 30 || second == 10 { mark = second } else { return }
        guard mark != lastSpokenMark else { return }
        lastSpokenMark = mark
        UIAccessibility.post(notification: .announcement, argument: L10n.f("a11y.timer", SpokenDuration.text(Double(mark))))
        #endif
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
        // The finger that opened the EvidenceSheet is lifted on the element behind it: its own tap
        // (open a conversation, a photo…) must not fire too.
        if receipt != nil && newPath.count > path.count { return }
        let old = path
        if newPath != old {
            selected = nil
            navigatedAt = Date()
        }
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
        guard receipt == nil else { return }
        path = []
        setPath(route.map { [.app(app), $0] } ?? [.app(app)])
    }

    func goHome() {
        selected = nil
        navigatedAt = Date()
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
        selected = nil
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
        guard receipt == nil else { return } // see `setPath`
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
        if ok { AudioDirector.shared.play(.unlock, volume: 0.8) } else { Haptics.warning() }
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

    // MARK: Selection (§6-04)

    /// A tap on a versable element: it is selected and shows its EvidenceBadge.
    func select(_ ref: ItemRef) {
        guard phase == .investigating, receipt == nil, Date().timeIntervalSince(navigatedAt) > 0.3 else { return }
        selectedAt = Date()
        if selected != ref {
            selected = ref
            Haptics.selection()
        }
        coach.elementSelected()
    }

    func clearSelection() {
        if selected != nil { selected = nil }
    }

    /// A tap somewhere on the phone: it hides the badge, unless it is the very tap that just
    /// selected an element (both gestures see it).
    func clearSelectionAfterTap() {
        guard selected != nil, Date().timeIntervalSince(selectedAt) > 0.35 else { return }
        selected = nil
    }

    // MARK: Filing (§6-05)

    /// « + Verser au dossier » (the EvidenceBadge), the long press shortcut or VoiceOver's action:
    /// the element goes into the file at once and the EvidenceSheet confirms it. An element already
    /// in the file opens the same sheet, which then leads to its piece.
    func requestFiling(_ ref: ItemRef) {
        guard phase == .investigating, !isPaused, receipt == nil else { return }
        selected = nil
        let wasFiled = investigation.isPinned(ref)
        if wasFiled {
            Haptics.selection()
        } else {
            file(ref)
        }
        let help = wasFiled ? [] : coach.filingTips()
        lastReceiptID += 1
        receipt = FilingReceipt(id: lastReceiptID, ref: ref, number: investigation.pieceNumber(of: ref),
                                isNew: !wasFiled, help: help)
    }

    @ObservationIgnored private var lastReceiptID = 0

    /// Closes the EvidenceSheet (« Continuer », the veil, 2.5 s later).
    func cancelFiling() {
        receipt = nil
    }

    /// « Continuer » in the EvidenceSheet. (An element not in the file yet is filed first: the
    /// former confirmation path.)
    func fileCandidate() {
        guard let receipt else { return }
        self.receipt = nil
        if !investigation.isPinned(receipt.ref) { file(receipt.ref) }
    }

    /// Opens the Carnet on a piece (« Voir la pièce ») or to connect it (« Relier »).
    func showInCarnet(_ ref: ItemRef, connect: Bool = false) {
        receipt = nil
        selected = nil
        carnetRequest = CarnetRequest(id: (carnetRequest?.id ?? 0) + 1, ref: ref, connect: connect)
    }

    /// Puts an element in the file (it becomes « PIÈCE 0N »). Filing twice does nothing.
    func file(_ ref: ItemRef) {
        guard !investigation.isPinned(ref) else { return }
        _ = investigation.togglePin(ref)
        AudioDirector.shared.play(.paper, volume: 0.6)
        Haptics.success()
        lastFiled = FiledPiece(id: (lastFiled?.id ?? 0) + 1, number: investigation.notebook.count, ref: ref)
        coach.pieceFiled()
        refresh()
    }

    /// Takes a piece out of the file (Carnet › « Retirer du dossier »). The others are renumbered.
    func togglePin(_ ref: ItemRef) {
        guard investigation.isPinned(ref) else { file(ref); return }
        _ = investigation.togglePin(ref)
        Haptics.selection()
        showToast(L10n.t("toast.unpinned"))
        refresh()
    }

    /// « Reprendre l'enquête » after a wrong conclusion: the new investigation gets back the
    /// pieces the player had filed, with their links and readings, and what had been seen (so a
    /// piece found by crossing several items stays found). Nothing costs time.
    func restoreNotebook(_ entries: [NotebookEntry], seen: Set<ItemRef> = []) {
        for ref in seen { investigation.markSeen(ref) }
        for entry in entries {
            investigation.markSeen(entry.ref)
            if !investigation.isPinned(entry.ref) { _ = investigation.togglePin(entry.ref) }
            if let suspect = entry.linkedTo { investigation.link(entry.ref, to: suspect) }
            if let stance = entry.stance { investigation.setStance(stance, for: entry.ref) }
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

    /// « L'accuse… » / « Le disculpe… » from the phone: files the item (if needed), links it to the
    /// suspect and records the player's reading, in one gesture. Choosing the same again undoes it.
    func annotate(_ ref: ItemRef, suspect: SuspectID, stance: NotebookEntry.Stance) {
        let entry = investigation.notebook.first { $0.ref == ref }
        if entry?.linkedTo == suspect && entry?.stance == stance {
            investigation.setStance(nil, for: ref)
            investigation.link(ref, to: nil)
            Haptics.selection()
            refresh()
            return
        }
        let wasPinned = entry != nil
        investigation.link(ref, to: suspect)
        investigation.setStance(stance, for: ref)
        Haptics.pin()
        coach.linkMade()
        if !wasPinned { AudioDirector.shared.play(.paper, volume: 0.55) }
        if let s = investigation.index.suspect(suspect) {
            showToast(L10n.f(stance == .incriminates ? "toast.accuses" : "toast.clears", investigation.name(of: s.contact)),
                      detail: investigation.pieceNumber(of: ref).map { PieceFormat.title($0) }, kind: .linked)
        }
        refresh()
    }

    /// The player's reading of a linked item (against / in favour of the suspect). Free.
    func setStance(_ stance: NotebookEntry.Stance?, for ref: ItemRef) {
        investigation.setStance(stance, for: ref)
        Haptics.selection()
        refresh()
    }

    private func showToast(_ text: String, detail: String? = nil, kind: Toast.Kind = .neutral, seconds: Double? = nil) {
        let toast = Toast(id: (self.toast?.id ?? 0) + 1, text: text, detail: detail, kind: kind)
        self.toast = toast
        toastTask?.cancel()
        let duration = seconds ?? (detail == nil ? 2 : 2.6)
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
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
        isPaused = false
        if investigation.phase == .investigating { startLoop() }
        refresh()
    }

    func accuse(_ suspect: SuspectID) {
        guard let verdict = investigation.accuse(suspect) else { return }
        finish(verdict)
    }

    /// ALIBI: « alibi confirmé » (true) or « alibi contredit » (false).
    func concludeAlibi(holds: Bool) {
        guard let verdict = investigation.concludeAlibi(holds: holds) else { return }
        finish(verdict)
    }

    private func finish(_ verdict: Verdict) {
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
        AudioDirector.shared.play(.notification, volume: n.level == .urgent ? 0.9 : 0.6)
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

    static func light() {
        guard Preferences.vibrations else { return }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    static func rigid() {
        guard Preferences.vibrations else { return }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        #endif
    }

    static func selection() {
        guard Preferences.vibrations else { return }
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    /// A stamp hitting the paper: heavy (RÉSOLU, a new piece) or a warning (NON RÉSOLU).
    static func stamp(heavy: Bool) {
        guard Preferences.vibrations else { return }
        #if canImport(UIKit)
        if heavy {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
        #endif
    }

    /// Opening a folder, turning a page: a light touch.
    static func paper() {
        guard Preferences.vibrations else { return }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.6)
        #endif
    }
}
#endif
