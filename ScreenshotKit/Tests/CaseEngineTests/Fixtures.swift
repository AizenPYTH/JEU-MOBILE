import Foundation
@testable import CaseEngine

/// A tiny hand-made case so engine tests don't depend on the shipped cases.
enum Fixtures {
    static func m(_ text: String) -> Moment { Moment(text)! }

    static let rules = GameRules(
        schemaVersion: 1,
        timeCosts: .init(openApp: 1, openConversation: 3, loadOlderMessages: 6, search: 8, openPhoto: 2, analyzePhoto: 15,
                         openTrack: 8, openCalendarEvent: 3, openNote: 5, openMail: 5, openBrowserEntry: 3, openContact: 2,
                         recoverMessage: 12, unlockAttempt: 5),
        messagesPageSize: 3, lowTimeWarningSeconds: 60, criticalTimeSeconds: 10, bannerSeconds: 4,
        scoring: .init(correctSuspect: 60, found: 25, timeLeft: 10, notebookPrecision: 5))

    static var caseFile: CaseFile {
        let contacts = [
            Contact(id: "me", name: "Alex Moreau", phone: "1", relation: nil, email: nil, birthday: "16/09/1999", avatarHue: 0.5, isOwner: true),
            Contact(id: "lucas", name: "Lucas Ferrand", phone: "2", relation: "Ami", email: nil, birthday: nil, avatarHue: 0.1, isOwner: nil),
            Contact(id: "emma", name: "Emma Roussel", phone: "3", relation: nil, email: nil, birthday: nil, avatarHue: 0.9, isOwner: nil),
        ]
        let lucasMessages = [
            Message(id: "l1", from: "lucas", at: m("2026-09-01 10:00"), text: "Salut"),
            Message(id: "l2", from: "me", at: m("2026-09-05 12:00"), text: "On se voit à la maison ?"),
            Message(id: "l3", from: "lucas", at: m("2026-09-12 21:38"), text: "T'es parti où ?"),
            Message(id: "l4", from: "me", at: m("2026-09-12 21:39"), text: "Rendez-vous à 22h"),
            Message(id: "l5", from: "lucas", at: m("2026-09-12 22:17"), text: "Je suis rentré", unread: true),
        ]
        let emmaMessages = [
            Message(id: "e1", from: "emma", at: m("2026-09-12 21:40"), text: "Quai 9. 22h. Viens seul.", deletedAt: m("2026-09-12 21:44")),
            Message(id: "e2", from: "emma", at: m("2026-09-12 22:30"), text: "Je suis restée chez moi", photo: "p1"),
        ]
        let device = Device(
            id: "dev", label: "Téléphone d'Alex", model: "iPhone",
            lockedApps: [AppLock(app: .notes, code: "1609", hint: "Anniversaire")],
            contacts: contacts,
            conversations: [
                Conversation(id: "c_lucas", title: nil, participants: ["lucas"], messages: lucasMessages, draft: nil),
                Conversation(id: "c_emma", title: nil, participants: ["emma"], messages: emmaMessages,
                             draft: Draft(id: "d1", text: "Si il m'arrive", at: m("2026-09-12 22:26"))),
            ],
            calls: [Call(id: "k1", contact: "emma", direction: .incoming, at: m("2026-09-12 21:47"), durationSeconds: 38)],
            places: [Place(id: "pl1", name: "Quai 9", kind: .parking, x: 0.8, y: 0.8)],
            tracks: [LocationTrack(id: "t_emma", contact: "emma",
                                   points: [TrackPoint(id: "tp1", at: m("2026-09-12 19:40"), place: "pl1", note: nil)],
                                   sharingStoppedAt: m("2026-09-12 21:31"))],
            photos: [Photo(id: "p1", takenAt: m("2026-09-12 19:42"), source: .received, from: "emma", receivedAt: m("2026-09-12 22:30"),
                           place: "Rue Paradis", device: "iPhone", scene: "bed", caption: "Au lit", details: "Il fait jour.")],
            calendar: [CalendarEvent(id: "cal1", start: m("2026-09-12 22:00"), end: nil, title: "P. Quai 9 — E.", location: nil, notes: nil, allDay: nil)],
            notes: [Note(id: "n1", title: "Comptes", body: "4 300 €", createdAt: m("2026-09-09 23:10"), modifiedAt: m("2026-09-09 23:10"))],
            mails: [],
            browser: [],
            liveEvents: [
                LiveEvent(id: "lv1", afterSeconds: 30, kind: .message, app: .messages, title: "Lucas", body: "Réponds",
                          conversation: "c_lucas", message: Message(id: "l_live", from: "lucas", at: m("2026-09-13 10:00"), text: "Réponds stp"),
                          call: nil, deletesMessage: nil, opens: ItemRef(.message, "l_live")),
                LiveEvent(id: "lv2", afterSeconds: 60, kind: .deletion, app: .messages, title: "Lucas", body: "Message supprimé",
                          conversation: "c_lucas", message: nil, call: nil, deletesMessage: "l5", opens: nil),
            ])
        return CaseFile(
            schemaVersion: 1, id: "case_test", number: 99, title: "TEST", tagline: "", synopsis: ["…"], objective: "…",
            difficulty: 1, durationSeconds: 300, phoneStartTime: m("2026-09-13 10:00"), devices: [device],
            suspects: [
                Suspect(id: "s_lucas", contact: "lucas", role: "Ami", statement: "Chez moi.", verdict: "Lucas n'y est pour rien.",
                        alibi: "Il était reparti.", alibiEvidence: "ev_draft", trap: "Il était au port."),
                Suspect(id: "s_emma", contact: "emma", role: "Asso", statement: "Chez moi.", verdict: "Emma a menti."),
            ],
            evidence: [
                Evidence(id: "ev_rdv", title: "RDV", meaning: "Emma a fixé le rendez-vous.", refs: [ItemRef(.message, "e1")],
                         anyOf: nil, importance: .key, suspects: ["s_emma"]),
                Evidence(id: "ev_photo", title: "Photo", meaning: "Prise à 19:42.", refs: [ItemRef(.photoInfo, "p1")],
                         anyOf: nil, importance: .key, suspects: ["s_emma"]),
                Evidence(id: "ev_lucas", title: "Lucas", meaning: "Il était au port.", refs: [ItemRef(.message, "l3")],
                         anyOf: nil, importance: .falseLead, suspects: ["s_lucas"]),
                Evidence(id: "ev_draft", title: "Brouillon", meaning: "Vivant à 22:26.", refs: [ItemRef(.draft, "d1")],
                         anyOf: nil, importance: .supporting, suspects: ["s_lucas"]),
            ],
            hints: [Hint(id: "h1", text: "La corbeille.", scoreCost: 0),
                    Hint(id: "h2", text: "La photo.", scoreCost: 8),
                    Hint(id: "h3", text: "Le calendrier.", scoreCost: 15, unlockAtRemainingSeconds: 120)],
            solution: Solution(culprit: "s_emma", headline: "Emma", summary: "…",
                               reveal: [RevealStep(at: m("2026-09-12 21:40"), text: "RDV", evidence: "ev_rdv")], story: ["…"]))
    }

    static func investigation() -> (Investigation, ManualClock) {
        let clock = ManualClock(start: Date(timeIntervalSince1970: 1_000_000))
        return (Investigation(caseFile: caseFile, rules: rules, clock: clock), clock)
    }
}
