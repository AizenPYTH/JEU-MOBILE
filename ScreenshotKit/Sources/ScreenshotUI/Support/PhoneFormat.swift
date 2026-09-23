#if os(iOS)
import CaseEngine

/// Dates and durations as the seized phone displays them (French phone, like its owner).
enum PhoneFormat {
    private static let weekdays = ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]
    private static let months = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août",
                                 "septembre", "octobre", "novembre", "décembre"]
    private static let shortMonths = ["janv.", "févr.", "mars", "avr.", "mai", "juin", "juil.", "août",
                                      "sept.", "oct.", "nov.", "déc."]

    /// "SAM"
    static func weekdayShort(_ m: Moment) -> String { String(weekdays[m.weekday - 1].prefix(3)).uppercased() }

    /// "SAM. 19 SEPT." — date separators (mono 11, caps).
    static func separatorCaps(_ m: Moment) -> String {
        "\(weekdays[m.weekday - 1].prefix(3)). \(m.day) \(shortMonths[m.month - 1])".uppercased()
    }

    /// "22:17"
    static func time(_ m: Moment) -> String { m.clockText }

    /// "samedi 12 septembre"
    static func longDay(_ m: Moment) -> String { "\(weekdays[m.weekday - 1]) \(m.day) \(months[m.month - 1])" }

    /// "Samedi 12 septembre"
    static func longDayCapitalized(_ m: Moment) -> String {
        let s = longDay(m)
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    /// "12 sept."
    static func shortDay(_ m: Moment) -> String { "\(m.day) \(shortMonths[m.month - 1])" }

    /// "12 sept. à 22:17"
    static func dayAndTime(_ m: Moment) -> String { "\(shortDay(m)) à \(m.clockText)" }

    /// List style, relative to the phone's current time: "22:17" today, "Hier", "samedi", "12/08/2026".
    static func relative(_ m: Moment, now: Moment) -> String {
        let days = now.dayNumber - m.dayNumber
        switch days {
        case 0: return m.clockText
        case 1: return "Hier"
        case 2...6: return weekdays[m.weekday - 1]
        default: return "\(pad(m.day))/\(pad(m.month))/\(m.year)"
        }
    }

    /// Day separator in a conversation: "Aujourd'hui 09:14", "Hier 22:30", "sam. 12 sept. 21:40".
    static func separator(_ m: Moment, now: Moment) -> String {
        let days = now.dayNumber - m.dayNumber
        switch days {
        case 0: return "Aujourd'hui \(m.clockText)"
        case 1: return "Hier \(m.clockText)"
        default: return "\(weekdays[m.weekday - 1].prefix(3)). \(shortDay(m)) \(m.clockText)"
        }
    }

    /// "2:31" / "0:38"
    static func duration(_ seconds: Int) -> String { "\(seconds / 60):\(pad(seconds % 60))" }

    /// Countdown "07:59"
    static func countdown(_ seconds: Double) -> String {
        let s = Int(seconds.rounded(.up))
        return "\(pad(s / 60)):\(pad(s % 60))"
    }

    private static func pad(_ v: Int) -> String { v < 10 ? "0\(v)" : "\(v)" }
}
#endif
