import Foundation

/// A notification shown by the seized phone during the investigation.
public struct PhoneNotification: Identifiable, Hashable, Sendable {
    public var id: String
    public var app: AppID
    public var title: String
    public var body: String
    /// Phone time when it arrived.
    public var at: Moment
    public var opens: ItemRef?
    public var level: LiveEvent.Level = .normal
}

/// Something the UI should react to (banner, "-12 s" flash, haptics…). Drained with `drainEvents()`.
public enum InvestigationEvent: Hashable, Sendable {
    case notification(PhoneNotification)
    case timeSpent(seconds: Int, action: TimedAction)
    case lowTime
    case timeUp
}

/// Actions that cost investigation time (amounts in `rules.json`).
public enum TimedAction: String, Hashable, Sendable {
    case openApp, openConversation, loadOlderMessages, search, openPhoto, analyzePhoto, openTrack,
         openCalendarEvent, openNote, openMail, openBrowserEntry, openContact, recoverMessage, unlockAttempt
}

/// Something the player pinned to the notebook ("◆ Épinglé"), optionally linked to a suspect.
public struct NotebookEntry: Codable, Hashable, Sendable, Identifiable {
    public var ref: ItemRef
    public var linkedTo: SuspectID?
    /// Investigation time when it was pinned.
    public var pinnedAtElapsed: Double

    public var id: ItemRef { ref }
}

/// Manual marks the player can tick on a suspect's file.
public enum SuspectMark: String, Codable, CaseIterable, Hashable, Sendable {
    case nearTheScene, liedAboutAlibi, hasMotive, hasAlibi
}

public enum AppAccess: Equatable, Sendable {
    case open
    case locked
}

/// One play of a case: owns the timer and everything the player did.
///
/// Time model: `elapsed = real time while investigating + time costs of actions`.
/// Reading, searching and analysing all cost seconds, so every tap is a decision.
/// Not thread-safe by design: the UI keeps it on the main actor.
public final class Investigation {
    public enum Phase: String, Codable, Sendable {
        case briefing, investigating, accusing, finished
    }

    public let caseFile: CaseFile
    public let rules: GameRules
    public let clock: any GameClock
    public let index: CaseIndex

    public private(set) var phase: Phase = .briefing
    public private(set) var isPaused = false
    /// Real seconds spent investigating (while not paused).
    public private(set) var activeSeconds: Double = 0
    /// Seconds consumed by actions.
    public private(set) var penaltySeconds: Double = 0

    public private(set) var currentDeviceID: String
    public private(set) var seen: Set<ItemRef> = []
    public private(set) var openedApps: Set<AppID> = []
    public private(set) var unlockedApps: Set<AppID> = []
    public private(set) var recoveredMessages: Set<String> = []
    public private(set) var readConversations: Set<String> = []
    public private(set) var loadedPages: [String: Int] = [:]
    public private(set) var deliveredEvents: [LiveEvent] = []
    public private(set) var notifications: [PhoneNotification] = []
    /// The notebook, in pinning order.
    public private(set) var notebook: [NotebookEntry] = []
    public private(set) var marks: [SuspectID: Set<SuspectMark>] = [:]
    public private(set) var usedHints: [Hint] = []
    public private(set) var searchCount = 0
    public private(set) var readNotifications: Set<String> = []
    public private(set) var verdict: Verdict?

    private var lastTick: Date?
    private var warnedLowTime = false
    private var pendingEvents: [InvestigationEvent] = []

    public init(caseFile: CaseFile, rules: GameRules, clock: any GameClock) {
        self.caseFile = caseFile
        self.rules = rules
        self.clock = clock
        self.index = CaseIndex(caseFile)
        self.currentDeviceID = caseFile.devices.first?.id ?? ""
    }

    /// Resumes a saved investigation. Live events and notifications are recomputed from the saved
    /// elapsed time (same timeline as before). It comes back paused: call `resume()` once the phone
    /// is on screen. Returns nil for a snapshot of another case or version.
    public convenience init?(restoring saved: InvestigationSnapshot, caseFile: CaseFile, rules: GameRules, clock: any GameClock) {
        guard saved.schemaVersion == InvestigationSnapshot.currentSchemaVersion, saved.caseID == caseFile.id,
              saved.phase == .investigating || saved.phase == .accusing,
              caseFile.devices.contains(where: { $0.id == saved.currentDeviceID }) else { return nil }
        var file = caseFile
        file.durationSeconds = saved.durationSeconds
        self.init(caseFile: file, rules: rules, clock: clock)
        phase = saved.phase
        activeSeconds = saved.activeSeconds
        penaltySeconds = saved.penaltySeconds
        currentDeviceID = saved.currentDeviceID
        seen = saved.seen
        openedApps = saved.openedApps
        unlockedApps = saved.unlockedApps
        recoveredMessages = saved.recoveredMessages
        readConversations = saved.readConversations
        loadedPages = saved.loadedPages
        notebook = saved.notebook
        marks = saved.marks
        usedHints = saved.usedHintIDs.compactMap { id in caseFile.hints.first { $0.id == id } }
        searchCount = saved.searchCount
        deliverDueEvents()
        readNotifications = saved.readNotifications
        warnedLowTime = isLowOnTime
        pendingEvents.removeAll() // the player already saw these before leaving
        isPaused = true
    }

    // MARK: - Timer

    public var durationSeconds: Double { Double(caseFile.durationSeconds) }
    public var elapsedSeconds: Double { min(durationSeconds, activeSeconds + penaltySeconds) }
    public var remainingSeconds: Double { max(0, durationSeconds - activeSeconds - penaltySeconds) }
    public var isLowOnTime: Bool { remainingSeconds <= Double(rules.lowTimeWarningSeconds) }
    /// The phone's own clock: case start time + everything spent so far.
    public var phoneNow: Moment { caseFile.phoneStartTime.adding(seconds: Int64(elapsedSeconds)) }

    /// Starts the countdown (after the briefing).
    public func start() {
        guard phase == .briefing else { return }
        phase = .investigating
        lastTick = clock.now
        deliverDueEvents()
    }

    /// Advances the timer to the clock's current time. Call it regularly (the UI does ~4×/s).
    /// A clock going backwards or a huge jump (app suspended without `pause`) never punishes the player.
    public func tick() {
        guard phase == .investigating, !isPaused else { return }
        let now = clock.now
        let delta = lastTick.map { now.timeIntervalSince($0) } ?? 0
        lastTick = now
        if delta > 0 { activeSeconds += min(delta, 2) }
        afterTimeChange()
    }

    /// Stops the countdown (app in background, system interruption).
    public func pause() {
        guard !isPaused else { return }
        tick()
        isPaused = true
    }

    public func resume() {
        guard isPaused else { return }
        isPaused = false
        lastTick = clock.now
    }

    /// Ends the investigation early: the player is ready to accuse.
    public func requestAccusation() {
        guard phase == .investigating else { return }
        tick()
        phase = .accusing
    }

    /// Back to the phone from the accusation screen — only while time remains.
    public func cancelAccusation() {
        guard phase == .accusing, remainingSeconds > 0 else { return }
        phase = .investigating
        lastTick = clock.now
    }

    public func drainEvents() -> [InvestigationEvent] {
        defer { pendingEvents.removeAll() }
        return pendingEvents
    }

    private func spend(_ action: TimedAction, seconds: Int) {
        guard phase == .investigating, seconds > 0 else { return }
        penaltySeconds += Double(seconds)
        pendingEvents.append(.timeSpent(seconds: seconds, action: action))
        afterTimeChange()
    }

    private func afterTimeChange() {
        deliverDueEvents()
        if isLowOnTime && !warnedLowTime && remainingSeconds > 0 {
            warnedLowTime = true
            pendingEvents.append(.lowTime)
        }
        if remainingSeconds <= 0 && phase == .investigating {
            phase = .accusing
            pendingEvents.append(.timeUp)
        }
    }

    // MARK: - Live events

    private func deliverDueEvents() {
        let done = Set(deliveredEvents.map(\.id))
        let due = caseFile.devices.flatMap(\.liveEvents)
            .filter { !done.contains($0.id) && Double($0.afterSeconds) <= elapsedSeconds }
            .sorted { $0.afterSeconds < $1.afterSeconds }
        for var event in due {
            let at = caseFile.phoneStartTime.adding(seconds: Int64(event.afterSeconds))
            // A live message is timestamped when it arrives.
            event.message?.at = at
            event.call?.at = at
            deliveredEvents.append(event)
            let notification = PhoneNotification(id: event.id, app: event.app, title: event.title,
                                                 body: event.body, at: at, opens: event.opens, level: event.level ?? .normal)
            notifications.insert(notification, at: 0)
            pendingEvents.append(.notification(notification))
        }
    }

    // MARK: - Phone data (what the player can see right now)

    public var device: Device { index.device(currentDeviceID) ?? caseFile.devices[0] }

    /// Switches to another seized phone (cases with several devices).
    public func selectDevice(_ id: String) {
        guard index.device(id) != nil else { return }
        currentDeviceID = id
    }

    public func contact(_ id: ContactID) -> Contact? { index.contact(id) }

    /// Display name of a sender: the contact's name, or the owner's.
    public func name(of id: ContactID) -> String {
        if id == ownerContactID { return device.contacts.first { $0.isOwner == true }?.name ?? id }
        return contact(id)?.name ?? id
    }

    public func title(of conversation: Conversation) -> String {
        conversation.title ?? conversation.participants.map { name(of: $0) }.joined(separator: ", ")
    }

    /// Every message of a conversation the phone currently shows, oldest first
    /// (deleted ones only once recovered; live ones once arrived; sender deletions as tombstones).
    public func visibleMessages(in conversationID: String) -> [VisibleMessage] {
        guard let conversation = index.conversation(conversationID) else { return [] }
        let deletedBySender = Set(deliveredEvents.filter { $0.kind == .deletion }.compactMap(\.deletesMessage))
        var result: [VisibleMessage] = []
        for message in conversation.messages {
            if message.deletedAt != nil {
                if recoveredMessages.contains(message.id) { result.append(VisibleMessage(message: message, state: .recovered)) }
                continue
            }
            result.append(VisibleMessage(message: message, state: deletedBySender.contains(message.id) ? .removedBySender : .normal))
        }
        for event in deliveredEvents where event.kind == .message && event.conversation == conversationID {
            if let message = event.message {
                result.append(VisibleMessage(message: message,
                                             state: deletedBySender.contains(message.id) ? .removedBySender : .normal,
                                             isLive: true))
            }
        }
        return result.sorted { $0.message.at < $1.message.at }
    }

    /// The part of the conversation already loaded on screen (the most recent pages).
    public func loadedMessages(in conversationID: String) -> [VisibleMessage] {
        let all = visibleMessages(in: conversationID)
        let count = max(1, loadedPages[conversationID] ?? 1) * rules.messagesPageSize
        return Array(all.suffix(count))
    }

    public func hasOlderMessages(in conversationID: String) -> Bool {
        visibleMessages(in: conversationID).count > loadedMessages(in: conversationID).count
    }

    public func unreadCount(in conversationID: String) -> Int {
        guard !readConversations.contains(conversationID) else {
            // Messages that arrived after the conversation was read.
            return deliveredEvents.filter { $0.kind == .message && $0.conversation == conversationID
                && !seen.contains(ItemRef(.message, $0.message?.id ?? "")) }.count
        }
        return visibleMessages(in: conversationID).filter { $0.message.unread == true || $0.isLive }.count
    }

    /// Conversations, most recent activity first.
    public var conversations: [ConversationSummary] {
        device.conversations.map { conversation in
            let messages = visibleMessages(in: conversation.id)
            return ConversationSummary(conversation: conversation, last: messages.last, unread: unreadCount(in: conversation.id))
        }
        .sorted { ($0.last?.message.at ?? Moment(seconds: 0)) > ($1.last?.message.at ?? Moment(seconds: 0)) }
    }

    /// "Récemment supprimés": messages deleted before the investigation.
    public var trash: [TrashItem] {
        device.conversations.flatMap { conversation in
            conversation.messages.compactMap { message -> TrashItem? in
                guard let deletedAt = message.deletedAt else { return nil }
                return TrashItem(message: message, conversationID: conversation.id, deletedAt: deletedAt,
                                 isRecovered: recoveredMessages.contains(message.id))
            }
        }
        .sorted { $0.deletedAt > $1.deletedAt }
    }

    /// Call history, most recent first (includes calls received during the investigation).
    public var calls: [Call] {
        let live = deliveredEvents.compactMap(\.call)
        return (device.calls + live).sorted { $0.at > $1.at }
    }

    /// Photo library in the order of the metadata date — like a real library.
    public var photos: [Photo] { device.photos.sorted { $0.takenAt > $1.takenAt } }

    public var unreadNotificationsCount: Int { notifications.filter { !readNotifications.contains($0.id) }.count }

    public func access(to app: AppID) -> AppAccess {
        let locked = device.lockedApps.contains { $0.app == app }
        return locked && !unlockedApps.contains(app) ? .locked : .open
    }

    // MARK: - Actions (they cost time)

    /// Opens an app. Returns `.locked` if it needs a code first (no time spent then).
    @discardableResult
    public func openApp(_ app: AppID) -> AppAccess {
        guard access(to: app) == .open else { return .locked }
        openedApps.insert(app)
        seen.insert(ItemRef(.app, app.rawValue))
        spend(.openApp, seconds: rules.timeCosts.openApp)
        return .open
    }

    /// Tries a code on a locked app. Every attempt costs time.
    @discardableResult
    public func unlock(_ app: AppID, code: String) -> Bool {
        spend(.unlockAttempt, seconds: rules.timeCosts.unlockAttempt)
        guard let lock = device.lockedApps.first(where: { $0.app == app }) else { return true }
        guard lock.code == code.trimmingCharacters(in: .whitespaces) else { return false }
        unlockedApps.insert(app)
        return true
    }

    public func openConversation(_ id: String) {
        guard index.conversation(id) != nil else { return }
        readConversations.insert(id)
        if loadedPages[id] == nil { loadedPages[id] = 1 }
        spend(.openConversation, seconds: rules.timeCosts.openConversation)
    }

    /// Scrolls further back in time: loads one more page of older messages.
    public func loadOlderMessages(in id: String) {
        guard hasOlderMessages(in: id) else { return }
        loadedPages[id, default: 1] += 1
        spend(.loadOlderMessages, seconds: rules.timeCosts.loadOlderMessages)
    }

    /// Makes sure a message is loaded on screen (used when jumping to it from search or a
    /// notification — the search itself already cost time).
    public func reveal(messageID: String) {
        guard let conversationID = index.conversationID(ofMessage: messageID) else { return }
        let all = visibleMessages(in: conversationID)
        guard let position = all.firstIndex(where: { $0.message.id == messageID }) else { return }
        let fromEnd = all.count - position
        let pages = (fromEnd + rules.messagesPageSize - 1) / rules.messagesPageSize
        loadedPages[conversationID] = max(loadedPages[conversationID] ?? 1, pages)
        readConversations.insert(conversationID)
    }

    /// Searches every message of the current phone. Costs time, even with no result.
    public func search(_ query: String) -> [SearchHit] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        searchCount += 1
        spend(.search, seconds: rules.timeCosts.search)
        let pool = device.conversations.map { ($0, visibleMessages(in: $0.id)) }
        return MessageSearch.search(trimmed, in: pool, contacts: device.contacts)
    }

    public func openPhoto(_ id: String) {
        guard index.photo(id) != nil else { return }
        seen.insert(ItemRef(.photo, id))
        spend(.openPhoto, seconds: rules.timeCosts.openPhoto)
    }

    /// Looks closely: metadata (real date taken, place, device) and details.
    public func analyzePhoto(_ id: String) {
        guard index.photo(id) != nil, !seen.contains(ItemRef(.photoInfo, id)) else { return }
        seen.insert(ItemRef(.photoInfo, id))
        spend(.analyzePhoto, seconds: rules.timeCosts.analyzePhoto)
    }

    public func isAnalyzed(_ photoID: String) -> Bool { seen.contains(ItemRef(.photoInfo, photoID)) }

    public func openTrack(_ id: String) {
        guard index.track(id) != nil else { return }
        seen.insert(ItemRef(.track, id))
        spend(.openTrack, seconds: rules.timeCosts.openTrack)
    }

    public func openCalendarEvent(_ id: String) {
        seen.insert(ItemRef(.calendar, id))
        spend(.openCalendarEvent, seconds: rules.timeCosts.openCalendarEvent)
    }

    public func openNote(_ id: String) {
        seen.insert(ItemRef(.note, id))
        spend(.openNote, seconds: rules.timeCosts.openNote)
    }

    public func openMail(_ id: String) {
        seen.insert(ItemRef(.mail, id))
        spend(.openMail, seconds: rules.timeCosts.openMail)
    }

    public func openBrowserEntry(_ id: String) {
        seen.insert(ItemRef(.browser, id))
        spend(.openBrowserEntry, seconds: rules.timeCosts.openBrowserEntry)
    }

    public func openContact(_ id: ContactID) {
        seen.insert(ItemRef(.contact, id))
        spend(.openContact, seconds: rules.timeCosts.openContact)
    }

    /// Restores a deleted message from the Trash back into its conversation.
    public func recoverMessage(_ id: String) {
        guard let message = index.message(id), message.deletedAt != nil, !recoveredMessages.contains(id) else { return }
        recoveredMessages.insert(id)
        seen.insert(ItemRef(.message, id))
        spend(.recoverMessage, seconds: rules.timeCosts.recoverMessage)
    }

    /// The UI reports what actually appeared on screen (free): messages, calls, drafts, notifications…
    public func markSeen(_ ref: ItemRef) {
        seen.insert(ref)
    }

    public func markNotificationsRead() {
        for n in notifications { readNotifications.insert(n.id) }
    }

    // MARK: - Notebook (free: organising is not investigating)

    public func isPinned(_ ref: ItemRef) -> Bool { notebook.contains { $0.ref == ref } }

    /// Pins an item to the notebook, or removes it if already pinned. Returns the new state.
    @discardableResult
    public func togglePin(_ ref: ItemRef) -> Bool {
        if let i = notebook.firstIndex(where: { $0.ref == ref }) {
            notebook.remove(at: i)
            return false
        }
        notebook.append(NotebookEntry(ref: ref, linkedTo: nil, pinnedAtElapsed: elapsedSeconds))
        seen.insert(ref)
        return true
    }

    /// Links an item to a suspect (pins it if needed); `nil` unlinks it.
    public func link(_ ref: ItemRef, to suspect: SuspectID?) {
        if let suspect, index.suspect(suspect) == nil { return }
        if let i = notebook.firstIndex(where: { $0.ref == ref }) {
            notebook[i].linkedTo = suspect
        } else {
            notebook.append(NotebookEntry(ref: ref, linkedTo: suspect, pinnedAtElapsed: elapsedSeconds))
            seen.insert(ref)
        }
    }

    public func linkedEntries(for suspect: SuspectID) -> [NotebookEntry] {
        notebook.filter { $0.linkedTo == suspect }
    }

    public func toggle(_ mark: SuspectMark, for suspect: SuspectID) {
        if marks[suspect, default: []].contains(mark) {
            marks[suspect]?.remove(mark)
        } else {
            marks[suspect, default: []].insert(mark)
        }
    }

    // MARK: - Hints (tiers; they cost score, never the answer)

    public enum HintState: Equatable, Sendable {
        case revealed, available, locked(untilRemaining: Int)
    }

    public func state(of hint: Hint) -> HintState {
        if usedHints.contains(where: { $0.id == hint.id }) { return .revealed }
        if let unlock = hint.unlockAtRemainingSeconds, remainingSeconds > Double(unlock) { return .locked(untilRemaining: unlock) }
        // Tiers are revealed in order.
        let position = caseFile.hints.firstIndex { $0.id == hint.id } ?? 0
        let previous = caseFile.hints.prefix(position)
        return previous.allSatisfy { p in usedHints.contains { $0.id == p.id } } ? .available : .locked(untilRemaining: hint.unlockAtRemainingSeconds ?? 0)
    }

    public var nextHint: Hint? {
        caseFile.hints.first { state(of: $0) == .available }
    }

    /// Reveals the next available hint (its cost is taken from the final score).
    @discardableResult
    public func useHint() -> Hint? {
        guard phase == .investigating, let hint = nextHint else { return nil }
        usedHints.append(hint)
        return hint
    }

    public var hintScoreCost: Int { usedHints.reduce(0) { $0 + $1.scoreCost } }

    // MARK: - Accusation

    /// Final answer. Possible while investigating or once the time is up.
    @discardableResult
    public func accuse(_ suspect: SuspectID) -> Verdict? {
        guard phase == .investigating || phase == .accusing, index.suspect(suspect) != nil else { return nil }
        tick()
        let verdict = Verdict.make(for: self, accused: suspect)
        self.verdict = verdict
        phase = .finished
        return verdict
    }

    // MARK: - Evidence

    /// Everything the evidence needs has been on screen (or any one item, for `anyOf`).
    public func isSeen(_ evidence: Evidence) -> Bool {
        evidence.anyOf == true ? evidence.refs.contains { seen.contains($0) } : evidence.refs.allSatisfy { seen.contains($0) }
    }

    /// Officially found: seen, and at least one of its items pinned in the notebook.
    /// Looking at something is not enough — the player has to recognise it as evidence.
    public func isFound(_ evidence: Evidence) -> Bool {
        isSeen(evidence) && evidence.refs.contains(where: pinCovers)
    }

    /// A pinned photo counts for its analysis and the other way round (same picture).
    private func pinCovers(_ ref: ItemRef) -> Bool {
        if isPinned(ref) { return true }
        switch ref.kind {
        case .photoInfo: return isPinned(ItemRef(.photo, ref.id))
        case .photo: return isPinned(ItemRef(.photoInfo, ref.id))
        default: return false
        }
    }

    public var foundEvidence: [Evidence] { caseFile.evidence.filter(isFound) }
}

public struct VisibleMessage: Hashable, Sendable, Identifiable {
    public enum State: Hashable, Sendable {
        case normal
        /// Restored from the Trash by the player.
        case recovered
        /// The sender deleted it during the investigation ("Ce message a été supprimé").
        case removedBySender
    }

    public var message: Message
    public var state: State
    public var isLive = false

    public var id: String { message.id }
}

public struct ConversationSummary: Identifiable, Sendable {
    public var conversation: Conversation
    public var last: VisibleMessage?
    public var unread: Int

    public var id: String { conversation.id }
}

public struct TrashItem: Identifiable, Hashable, Sendable {
    public var message: Message
    public var conversationID: String
    public var deletedAt: Moment
    public var isRecovered: Bool

    public var id: String { message.id }
}
