/// A wall-clock moment inside a case ("2026-09-13 22:30"), with no time zone.
///
/// Everything in a case happens in the same local time, so moments are stored as seconds since
/// 1970-01-01 00:00 *wall time* and never converted. Written in JSON as `"yyyy-MM-dd HH:mm"`
/// or `"yyyy-MM-dd HH:mm:ss"`. Pure arithmetic: identical on iOS and Linux.
public struct Moment: Codable, Hashable, Comparable, Sendable, CustomStringConvertible {
    public let seconds: Int64

    public init(seconds: Int64) {
        self.seconds = seconds
    }

    public init(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0, second: Int = 0) {
        let days = Moment.daysFromCivil(year: year, month: month, day: day)
        seconds = days * 86_400 + Int64(hour * 3_600 + minute * 60 + second)
    }

    /// Parses `yyyy-MM-dd HH:mm[:ss]`. Returns nil on any malformed input.
    public init?(_ text: String) {
        let parts = text.split(separator: " ")
        guard parts.count == 2 else { return nil }
        let date = parts[0].split(separator: "-").compactMap { Int($0) }
        let time = parts[1].split(separator: ":").compactMap { Int($0) }
        guard date.count == 3, (2...3).contains(time.count),
              (1...12).contains(date[1]), (1...31).contains(date[2]),
              (0...23).contains(time[0]), (0...59).contains(time[1]) else { return nil }
        let second = time.count == 3 ? time[2] : 0
        guard (0...59).contains(second) else { return nil }
        self.init(year: date[0], month: date[1], day: date[2], hour: time[0], minute: time[1], second: second)
    }

    public init(from decoder: any Decoder) throws {
        let text = try decoder.singleValueContainer().decode(String.self)
        guard let moment = Moment(text) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                                                    debugDescription: "Invalid moment '\(text)', expected yyyy-MM-dd HH:mm"))
        }
        self = moment
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }

    public static func < (lhs: Moment, rhs: Moment) -> Bool { lhs.seconds < rhs.seconds }

    public func adding(seconds delta: Int64) -> Moment { Moment(seconds: seconds + delta) }

    // MARK: Components

    public var dayNumber: Int64 { seconds >= 0 ? seconds / 86_400 : (seconds - 86_399) / 86_400 }
    private var secondOfDay: Int { Int(seconds - dayNumber * 86_400) }

    public var hour: Int { secondOfDay / 3_600 }
    public var minute: Int { (secondOfDay % 3_600) / 60 }
    public var second: Int { secondOfDay % 60 }
    public var year: Int { Moment.civil(fromDays: dayNumber).year }
    public var month: Int { Moment.civil(fromDays: dayNumber).month }
    public var day: Int { Moment.civil(fromDays: dayNumber).day }
    /// 1 = Monday … 7 = Sunday (ISO 8601).
    public var weekday: Int { Int(((dayNumber % 7) + 7 + 3) % 7) + 1 }

    /// Same calendar day?
    public func isSameDay(as other: Moment) -> Bool { dayNumber == other.dayNumber }

    public var description: String {
        let c = Moment.civil(fromDays: dayNumber)
        return "\(c.year)-\(Moment.pad(c.month))-\(Moment.pad(c.day)) \(Moment.pad(hour)):\(Moment.pad(minute))"
            + (second == 0 ? "" : ":\(Moment.pad(second))")
    }

    /// "22:17"
    public var clockText: String { "\(Moment.pad(hour)):\(Moment.pad(minute))" }

    static func pad(_ value: Int) -> String { value < 10 ? "0\(value)" : "\(value)" }

    // Howard Hinnant's civil-date algorithms (proleptic Gregorian calendar).
    static func daysFromCivil(year: Int, month: Int, day: Int) -> Int64 {
        let y = Int64(month <= 2 ? year - 1 : year)
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let m = Int64(month)
        let doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + Int64(day) - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146_097 + doe - 719_468
    }

    static func civil(fromDays days: Int64) -> (year: Int, month: Int, day: Int) {
        let z = days + 719_468
        let era = (z >= 0 ? z : z - 146_096) / 146_097
        let doe = z - era * 146_097
        let yoe = (doe - doe / 1_460 + doe / 36_524 - doe / 146_096) / 365
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
        let mp = (5 * doy + 2) / 153
        let d = doy - (153 * mp + 2) / 5 + 1
        let m = mp < 10 ? mp + 3 : mp - 9
        return (Int(yoe + era * 400 + (m <= 2 ? 1 : 0)), Int(m), Int(d))
    }
}
