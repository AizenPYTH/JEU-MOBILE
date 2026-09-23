/// Number display rules from the design handoff (docs/design, "Format des nombres"):
/// - below 10 000: the full integer with a thin space (FR "9 850") or a comma (EN "9,850");
/// - from 10 000: 3 significant digits (trailing zeros dropped) + unit,
///   FR k, M, Md, Bn, Tn — EN K, M, B, T, Qa; decimal comma in FR, point in EN.
///   Examples: 12,4 k · 1,2 M · 45,7 Md (FR) — 12.4K · 1.2M · 45.7B (EN).
/// Values are rounded *down* so the HUD never shows more than the player owns.
/// Pure Swift so it can be tested on Linux; the UI picks the style from the device language.
public enum CompactNumber {
    public enum Style: Sendable {
        case french, english

        var units: [String] {
            switch self {
            case .french: ["k", "M", "Md", "Bn", "Tn"]
            case .english: ["K", "M", "B", "T", "Qa"]
            }
        }

        var decimalSeparator: String { self == .french ? "," : "." }
        var groupingSeparator: String { self == .french ? "\u{202F}" : "," }
        /// Space between the number and its unit (narrow no-break space in FR, none in EN).
        var unitSeparator: String { self == .french ? "\u{202F}" : "" }
    }

    public static func format(_ value: Int, style: Style) -> String {
        if value < 0 { return "-" + format(-value, style: style) }
        if value < 10_000 { return grouped(value, style: style) }

        var unitIndex = -1
        var scaled = Double(value)
        while scaled >= 1_000, unitIndex < style.units.count - 1 {
            scaled /= 1_000
            unitIndex += 1
        }
        let decimals = scaled >= 100 ? 0 : (scaled >= 10 ? 1 : 2)
        let factor = decimals == 2 ? 100.0 : (decimals == 1 ? 10.0 : 1.0)
        let floored = (scaled * factor + 1e-9).rounded(.down) / factor

        var text = String(Int(floored))
        if decimals > 0 {
            let fraction = Int(((floored - floored.rounded(.down)) * factor).rounded())
            var digits = String(fraction)
            while digits.count < decimals { digits = "0" + digits }
            while digits.hasSuffix("0") { digits.removeLast() }
            if !digits.isEmpty { text += style.decimalSeparator + digits }
        }
        return text + style.unitSeparator + style.units[unitIndex]
    }

    private static func grouped(_ value: Int, style: Style) -> String {
        let digits = String(value)
        guard digits.count > 3 else { return digits }
        var result = ""
        for (i, ch) in digits.enumerated() {
            if i > 0, (digits.count - i) % 3 == 0 { result += style.groupingSeparator }
            result.append(ch)
        }
        return result
    }
}
