#if os(iOS)
import CaseEngine

/// Human description of any item: for the notebook (EvidenceRow: time · label · source app).
enum ItemDescriber {
    struct Item {
        var at: Moment?
        var label: String
        var app: AppID
    }

    static func describe(_ ref: ItemRef, in game: Investigation) -> Item {
        let index = game.index
        switch ref.kind {
        case .message:
            if let m = index.message(ref.id) {
                let app: AppID = m.deletedAt != nil ? .trash : .messages
                return Item(at: m.at, label: "\(game.name(of: m.from)) · « \(m.text ?? L10n.t("item.photo")) »", app: app)
            }
        case .draft:
            if let d = game.device.conversations.compactMap(\.draft).first(where: { $0.id == ref.id }) {
                return Item(at: d.at, label: "\(L10n.t("messages.draft")) · « \(d.text) »", app: .messages)
            }
        case .call:
            if let c = index.call(ref.id) {
                return Item(at: c.at, label: "\(game.name(of: c.contact)) · \(CallsFormat.label(c))", app: .phone)
            }
        case .photo, .photoInfo:
            if let p = index.photo(ref.id) { return Item(at: p.takenAt, label: p.caption, app: .photos) }
        case .track:
            if let t = index.track(ref.id) {
                return Item(at: t.points.map(\.at).max(), label: L10n.f("item.track", game.name(of: t.contact)), app: .location)
            }
        case .calendar:
            if let e = index.calendarEvent(ref.id) { return Item(at: e.start, label: e.title, app: .calendar) }
        case .note:
            if let n = index.note(ref.id) { return Item(at: n.modifiedAt, label: n.title, app: .notes) }
        case .mail:
            if let m = index.mail(ref.id) { return Item(at: m.at, label: "\(m.fromName) — \(m.subject)", app: .mail) }
        case .browser:
            if let b = index.browserEntry(ref.id) { return Item(at: b.at, label: b.kind == .search ? "« \(b.text) »" : b.text, app: .browser) }
        case .contact:
            return Item(at: nil, label: game.name(of: ref.id), app: .contacts)
        case .app:
            break
        }
        return Item(at: nil, label: ref.description, app: ref.kind.app)
    }
}

enum CallsFormat {
    static func label(_ call: Call) -> String {
        switch call.direction {
        case .incoming: L10n.f("calls.incoming", PhoneFormat.duration(call.durationSeconds))
        case .outgoing: call.durationSeconds > 0 ? L10n.f("calls.outgoing", PhoneFormat.duration(call.durationSeconds)) : L10n.t("calls.noAnswer")
        case .missed: L10n.t("calls.missedLabel")
        }
    }

    /// Direction symbol, never colour alone: ↙ incoming, ↗ outgoing, ↙ missed (red).
    static func arrow(_ call: Call) -> String { call.direction == .outgoing ? "↗" : "↙" }
}
#endif
