/// Static checks on a case used by CaseLint and the tests: is it solvable within its duration?
public enum CaseAnalysis {
    public struct Report: Sendable {
        /// Minimum time cost (actions only, no reading time) to see every key evidence.
        public var minimumKeyCost: Int
        /// Same, plus a reading allowance of `readingSecondsPerItem` per item.
        public var estimatedSolveSeconds: Int
        public var duration: Int
        public var keyEvidenceCount: Int
        public var messageCount: Int
        public var photoCount: Int
        /// Share of messages that are referenced by no evidence at all (the "noise" to dig through).
        public var noiseRatio: Double

        public var isComfortablySolvable: Bool { estimatedSolveSeconds <= duration * 3 / 4 }
    }

    public static func analyze(_ file: CaseFile, rules: GameRules, readingSecondsPerItem: Int = 15) -> Report {
        let costs = rules.timeCosts
        let investigation = Investigation(caseFile: file, rules: rules, clock: ManualClock())
        var appsNeeded = Set<AppID>()
        var total = 0
        var items = 0

        func cost(of ref: ItemRef) -> (Int, AppID?) {
            switch ref.kind {
            case .message:
                guard let message = investigation.index.message(ref.id) else { return (0, .messages) }
                if message.deletedAt != nil { return (costs.recoverMessage, .trash) }
                guard let conversationID = investigation.index.conversationID(ofMessage: ref.id) else { return (0, .messages) }
                let all = investigation.visibleMessages(in: conversationID)
                let position = all.count - (all.firstIndex { $0.message.id == ref.id } ?? all.count)
                let pages = max(0, (position - 1) / rules.messagesPageSize)
                return (costs.openConversation + pages * costs.loadOlderMessages, .messages)
            case .draft: return (costs.openConversation, .messages)
            case .call: return (0, .phone)
            case .photo: return (costs.openPhoto, .photos)
            case .photoInfo: return (costs.openPhoto + costs.analyzePhoto, .photos)
            case .track: return (costs.openTrack, .location)
            case .calendar: return (costs.openCalendarEvent, .calendar)
            case .note: return (costs.openNote + costs.unlockAttempt, .notes)
            case .mail: return (costs.openMail, .mail)
            case .browser: return (costs.openBrowserEntry, .browser)
            case .contact: return (costs.openContact, .contacts)
            case .app: return (0, AppID(rawValue: ref.id))
            }
        }

        let key = file.evidence.filter { $0.importance == .key }
        for evidence in key {
            let options = evidence.refs.map(cost(of:))
            if evidence.anyOf == true {
                if let best = options.min(by: { $0.0 < $1.0 }) {
                    total += best.0; items += 1
                    if let app = best.1 { appsNeeded.insert(app) }
                }
            } else {
                for option in options {
                    total += option.0; items += 1
                    if let app = option.1 { appsNeeded.insert(app) }
                }
            }
        }
        total += appsNeeded.count * costs.openApp

        let allMessages = file.devices.flatMap(\.conversations).flatMap(\.messages)
        let referenced = Set(file.evidence.flatMap(\.refs).filter { $0.kind == .message }.map(\.id))
        let noise = allMessages.isEmpty ? 0 : Double(allMessages.filter { !referenced.contains($0.id) }.count) / Double(allMessages.count)

        return Report(minimumKeyCost: total,
                      estimatedSolveSeconds: total + items * readingSecondsPerItem,
                      duration: file.durationSeconds,
                      keyEvidenceCount: key.count,
                      messageCount: allMessages.count,
                      photoCount: file.devices.flatMap(\.photos).count,
                      noiseRatio: noise)
    }
}
