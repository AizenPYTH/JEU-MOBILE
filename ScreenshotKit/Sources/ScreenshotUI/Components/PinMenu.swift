#if os(iOS)
import SwiftUI
import CaseEngine

/// Long-press menu on any item: attach it to a suspect's file. Free (organising is not investigating).
struct PinMenu: ViewModifier {
    let ref: ItemRef
    let session: GameSession

    func body(content: Content) -> some View {
        content.contextMenu {
            Section(L10n.t("pin.title")) {
                ForEach(session.caseFile.suspects) { suspect in
                    let pinned = (session.game.pins[suspect.id] ?? []).contains(ref)
                    Button {
                        session.perform { game in
                            if pinned { game.unpin(ref, from: suspect.id) } else { game.pin(ref, to: suspect.id) }
                        }
                        Haptics.selection()
                    } label: {
                        Label(session.game.name(of: suspect.contact),
                              systemImage: pinned ? "checkmark.circle.fill" : "person.crop.circle.badge.plus")
                    }
                }
            }
        }
    }
}

extension View {
    func pinnable(_ ref: ItemRef, session: GameSession) -> some View {
        modifier(PinMenu(ref: ref, session: session))
    }
}

/// One-line human description of any item, for suspect files and results.
enum ItemDescriber {
    static func describe(_ ref: ItemRef, in game: Investigation) -> (icon: String, text: String) {
        let index = game.index
        switch ref.kind {
        case .message:
            guard let m = index.message(ref.id) else { break }
            return ("message.fill", "\(game.name(of: m.from)) · \(PhoneFormat.dayAndTime(m.at)) — « \(m.text ?? L10n.t("item.photo")) »")
        case .draft:
            if let c = game.device.conversations.first(where: { $0.draft?.id == ref.id }), let d = c.draft {
                return ("square.and.pencil", "\(L10n.t("messages.draft")) · \(PhoneFormat.dayAndTime(d.at)) — « \(d.text) »")
            }
        case .call:
            guard let c = index.call(ref.id) else { break }
            return ("phone.fill", "\(game.name(of: c.contact)) · \(PhoneFormat.dayAndTime(c.at)) · \(PhoneFormat.duration(c.durationSeconds))")
        case .photo, .photoInfo:
            guard let p = index.photo(ref.id) else { break }
            return ("photo", "\(p.caption) · \(PhoneFormat.dayAndTime(p.takenAt))")
        case .track:
            guard let t = index.track(ref.id) else { break }
            return ("location.fill", L10n.f("item.track", game.name(of: t.contact)))
        case .calendar:
            guard let e = index.calendarEvent(ref.id) else { break }
            return ("calendar", "\(e.title) · \(PhoneFormat.dayAndTime(e.start))")
        case .note:
            guard let n = index.note(ref.id) else { break }
            return ("note.text", n.title)
        case .mail:
            guard let m = index.mail(ref.id) else { break }
            return ("envelope.fill", "\(m.fromName) — \(m.subject)")
        case .browser:
            guard let b = index.browserEntry(ref.id) else { break }
            return ("safari.fill", "\(PhoneFormat.dayAndTime(b.at)) — \(b.text)")
        case .contact:
            return ("person.fill", game.name(of: ref.id))
        case .app:
            break
        }
        return ("questionmark.circle", ref.description)
    }
}
#endif
