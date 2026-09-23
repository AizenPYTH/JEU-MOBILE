import Foundation

/// One result of the phone-wide search (screen 11).
public struct PhoneSearchResult: Identifiable, Hashable, Sendable {
    /// App the result lives in (the chip it is filed under).
    public var app: AppID
    /// The item to open.
    public var ref: ItemRef
    /// Conversation of a message result.
    public var conversationID: String?
    /// Name, event, note, page, mail subject or contact.
    public var title: String
    /// The matching text (the UI highlights the query in it).
    public var excerpt: String
    public var at: Moment?

    public var id: String { "\(app.rawValue):\(ref.description)" }
}

/// Search across the phone, the way a player expects a phone to search: words anywhere (case and
/// accents ignored), names, places, times ("22h"), dates ("13 sept", "13/09") and weekdays
/// ("samedi"). Covers Messages, Calendar, Notes, Mail, Browser and Contacts; a locked app is not
/// searched. Results are grouped by app, then by date (oldest first).
public enum PhoneSearch {
    /// Apps searched, in the order results are grouped.
    public static let apps: [AppID] = [.messages, .calendar, .notes, .mail, .browser, .contacts]

    static func search(_ query: String, in game: Investigation) -> [PhoneSearchResult] {
        let needle = MessageSearch.normalize(query)
        guard !needle.isEmpty else { return [] }
        let time = MessageSearch.parseTime(needle)
        let date = MessageSearch.parseDate(needle)
        let weekday = parseWeekday(needle)
        let device = game.device

        func matches(_ fields: [String?], at: Moment?) -> Bool {
            let texts = fields.compactMap { $0 }.map(MessageSearch.normalize)
            if texts.contains(where: { $0.contains(needle) }) { return true }
            if let time {
                if texts.contains(where: { MessageSearch.textMentions(time, in: $0) }) { return true }
                if let at, at.hour == time.hour, time.minute == nil || at.minute == time.minute { return true }
            }
            if let at {
                if let date, at.day == date.day, date.month == nil || at.month == date.month { return true }
                if let weekday, at.weekday == weekday { return true }
            }
            return false
        }

        var results: [PhoneSearchResult] = []
        let open = { (app: AppID) in game.access(to: app) == .open }

        if open(.messages) {
            var found: [String: (Conversation, VisibleMessage)] = [:]
            let pool = device.conversations.map { ($0, game.visibleMessages(in: $0.id)) }
            for hit in MessageSearch.search(query, in: pool, contacts: device.contacts) {
                if let conversation = game.index.conversation(hit.conversationID) { found[hit.id] = (conversation, hit.message) }
            }
            if let weekday {
                for (conversation, messages) in pool {
                    for visible in messages where visible.state != .removedBySender && visible.message.at.weekday == weekday {
                        found[visible.id] = (conversation, visible)
                    }
                }
            }
            for (conversation, visible) in found.values {
                let message = visible.message
                let title = conversation.title ?? game.name(of: conversation.participants.first ?? message.from)
                results.append(PhoneSearchResult(app: .messages, ref: ItemRef(.message, message.id), conversationID: conversation.id,
                                                 title: title, excerpt: message.text.map { "\(game.name(of: message.from)) : \($0)" } ?? game.name(of: message.from),
                                                 at: message.at))
            }
        }
        if open(.calendar) {
            for event in device.calendar where matches([event.title, event.location, event.notes], at: event.start) {
                results.append(PhoneSearchResult(app: .calendar, ref: ItemRef(.calendar, event.id), conversationID: nil,
                                                 title: event.title,
                                                 excerpt: [event.location, event.notes].compactMap { $0 }.joined(separator: " · "),
                                                 at: event.start))
            }
        }
        if open(.notes) {
            for note in device.notes where matches([note.title, note.body], at: note.modifiedAt) {
                results.append(PhoneSearchResult(app: .notes, ref: ItemRef(.note, note.id), conversationID: nil,
                                                 title: note.title, excerpt: excerpt(of: note.body, around: needle), at: note.modifiedAt))
            }
        }
        if open(.mail) {
            for mail in device.mails where matches([mail.subject, mail.body, mail.fromName, mail.to], at: mail.at) {
                results.append(PhoneSearchResult(app: .mail, ref: ItemRef(.mail, mail.id), conversationID: nil,
                                                 title: mail.subject, excerpt: "\(mail.fromName) — \(excerpt(of: mail.body, around: needle))",
                                                 at: mail.at))
            }
        }
        if open(.browser) {
            for entry in device.browser where matches([entry.text, entry.url, entry.summary], at: entry.at) {
                results.append(PhoneSearchResult(app: .browser, ref: ItemRef(.browser, entry.id), conversationID: nil,
                                                 title: entry.text, excerpt: entry.url ?? "", at: entry.at))
            }
        }
        if open(.contacts) {
            for contact in device.contacts where contact.isOwner != true
                && matches([contact.name, contact.phone, contact.relation, contact.email], at: nil) {
                results.append(PhoneSearchResult(app: .contacts, ref: ItemRef(.contact, contact.id), conversationID: nil,
                                                 title: contact.name, excerpt: [contact.relation, contact.phone].compactMap { $0 }.joined(separator: " · "),
                                                 at: nil))
            }
        }

        return results.sorted { a, b in
            let ia = apps.firstIndex(of: a.app) ?? 0, ib = apps.firstIndex(of: b.app) ?? 0
            if ia != ib { return ia < ib }
            switch (a.at, b.at) {
            case let (x?, y?) where x != y: return x < y
            default: return a.title < b.title
            }
        }
    }

    private static let weekdays = ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]

    /// "samedi", "sam." → weekday number (1 = Monday, as `Moment.weekday`).
    static func parseWeekday(_ text: String) -> Int? {
        let t = text.hasPrefix("le ") ? String(text.dropFirst(3)) : text
        let word = t.trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        guard word.count >= 3, !word.contains(" ") else { return nil }
        return weekdays.firstIndex { $0.hasPrefix(word) }.map { $0 + 1 }
    }

    /// A short piece of a long text around the first match (or its beginning).
    static func excerpt(of text: String, around needle: String, radius: Int = 60) -> String {
        let flat = text.split(whereSeparator: \.isNewline).joined(separator: " ")
        guard let range = flat.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive]) else {
            return String(flat.prefix(radius * 2))
        }
        let start = flat.index(range.lowerBound, offsetBy: -radius, limitedBy: flat.startIndex) ?? flat.startIndex
        let end = flat.index(range.upperBound, offsetBy: radius, limitedBy: flat.endIndex) ?? flat.endIndex
        return (start > flat.startIndex ? "…" : "") + flat[start..<end] + (end < flat.endIndex ? "…" : "")
    }
}

extension Investigation {
    /// Searches the whole phone (costs the same time as a search in Messages).
    public func searchPhone(_ query: String) -> [PhoneSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        chargeSearch()
        return PhoneSearch.search(trimmed, in: self)
    }
}
