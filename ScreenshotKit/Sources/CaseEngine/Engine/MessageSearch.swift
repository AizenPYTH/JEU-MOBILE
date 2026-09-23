import Foundation

/// A message matching a search.
public struct SearchHit: Identifiable, Hashable, Sendable {
    public var conversationID: String
    public var message: VisibleMessage
    /// Why it matched, for the result list ("texte", "heure", "date", "contact").
    public var reasons: Set<Reason>

    public enum Reason: String, Hashable, Sendable {
        case text, time, date, contact
    }

    public var id: String { message.id }
}

/// Search in messages, the way a player expects a phone to search:
/// - words anywhere in the text, ignoring case and accents ("maison", "Tanneurs");
/// - a contact name → their messages and the messages mentioning them ("Lucas");
/// - a time → messages containing it *and* messages sent at that time ("22h", "22:17", "22h17");
/// - a date → messages of that day ("13/09", "13 sept", "13 septembre").
public enum MessageSearch {
    public static func search(_ query: String,
                              in pool: [(Conversation, [VisibleMessage])],
                              contacts: [Contact]) -> [SearchHit] {
        let needle = normalize(query)
        guard !needle.isEmpty else { return [] }
        let time = parseTime(needle)
        let date = parseDate(needle)
        let matchingContacts = Set(contacts.filter { normalize($0.name).contains(needle) }.map(\.id))

        var hits: [SearchHit] = []
        for (conversation, messages) in pool {
            for visible in messages where visible.state != .removedBySender {
                let message = visible.message
                var reasons = Set<SearchHit.Reason>()
                if let text = message.text, normalize(text).contains(needle) { reasons.insert(.text) }
                if let time, message.at.hour == time.hour, time.minute == nil || message.at.minute == time.minute {
                    reasons.insert(.time)
                }
                if let time, let text = message.text, textMentions(time, in: normalize(text)) { reasons.insert(.text) }
                if let date, message.at.day == date.day, date.month == nil || message.at.month == date.month {
                    reasons.insert(.date)
                }
                if matchingContacts.contains(message.from) { reasons.insert(.contact) }
                if !reasons.isEmpty {
                    hits.append(SearchHit(conversationID: conversation.id, message: visible, reasons: reasons))
                }
            }
        }
        return hits.sorted { $0.message.message.at > $1.message.message.at }
    }

    /// Lowercased, accents removed, spaces collapsed.
    public static func normalize(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    struct TimeQuery: Equatable { var hour: Int; var minute: Int? }
    struct DateQuery: Equatable { var day: Int; var month: Int? }

    /// "22h", "22 h", "22h17", "22:17", "9h05".
    static func parseTime(_ text: String) -> TimeQuery? {
        let compact = text.replacingOccurrences(of: " ", with: "")
        let separators: [Character] = ["h", ":"]
        guard let sep = compact.firstIndex(where: { separators.contains($0) }) else { return nil }
        let hourPart = compact[..<sep]
        let minutePart = compact[compact.index(after: sep)...]
        guard (1...2).contains(hourPart.count), let hour = Int(hourPart), (0...23).contains(hour) else { return nil }
        if minutePart.isEmpty { return TimeQuery(hour: hour, minute: nil) }
        guard minutePart.count == 2, let minute = Int(minutePart), (0...59).contains(minute) else { return nil }
        return TimeQuery(hour: hour, minute: minute)
    }

    /// Does a normalized text mention this time in any common spelling?
    static func textMentions(_ time: TimeQuery, in text: String) -> Bool {
        let h = String(time.hour)
        let hh = time.hour < 10 ? "0\(time.hour)" : h
        var forms: [String]
        if let minute = time.minute {
            let mm = minute < 10 ? "0\(minute)" : String(minute)
            forms = ["\(h)h\(mm)", "\(hh)h\(mm)", "\(h):\(mm)", "\(hh):\(mm)", "\(h) h \(mm)"]
        } else {
            forms = ["\(h)h", "\(hh)h", "\(h) h", "\(h):", "\(hh):"]
        }
        return forms.contains { form in
            var searchRange = text.startIndex..<text.endIndex
            while let range = text.range(of: form, range: searchRange) {
                // Avoid matching "122h" for "22h": the character before must not be a digit.
                let before = range.lowerBound > text.startIndex ? text[text.index(before: range.lowerBound)] : " "
                if !before.isNumber { return true }
                searchRange = range.upperBound..<text.endIndex
            }
            return false
        }
    }

    private static let months: [(prefix: String, month: Int)] = [
        ("janv", 1), ("jan", 1), ("fevr", 2), ("fev", 2), ("feb", 2), ("mars", 3), ("mar", 3), ("avr", 4), ("apr", 4),
        ("mai", 5), ("may", 5), ("juin", 6), ("jun", 6), ("juil", 7), ("jul", 7), ("aout", 8), ("aug", 8),
        ("sept", 9), ("sep", 9), ("oct", 10), ("nov", 11), ("dec", 12),
    ]

    /// "13/09", "13-09", "13.09", "13 sept", "13 septembre", "le 13".
    static func parseDate(_ text: String) -> DateQuery? {
        var t = text
        if t.hasPrefix("le ") { t.removeFirst(3) }
        for separator in ["/", "-", "."] where t.contains(separator) {
            let parts = t.split(separator: Character(separator))
            guard parts.count == 2, let d = Int(parts[0]), let m = Int(parts[1]),
                  (1...31).contains(d), (1...12).contains(m) else { return nil }
            return DateQuery(day: d, month: m)
        }
        let words = t.split(separator: " ")
        guard let first = words.first, let day = Int(first), (1...31).contains(day), first.count <= 2 else { return nil }
        if words.count == 1 { return text.hasPrefix("le ") ? DateQuery(day: day, month: nil) : nil }
        guard words.count == 2 else { return nil }
        let word = String(words[1])
        guard let month = months.first(where: { word.hasPrefix($0.prefix) })?.month else { return nil }
        return DateQuery(day: day, month: month)
    }
}
