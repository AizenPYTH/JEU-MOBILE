#if os(iOS)
import Foundation

/// Interface strings from the String Catalog (`Resources/Localizable.xcstrings`), French first, English too.
/// The *content* of a case (messages, notes…) is written in the language of the seized phone.
enum L10n {
    static func t(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module)
    }

    static func f(_ key: String, _ arguments: any CVarArg...) -> String {
        String(format: t(key), locale: Locale.current, arguments: arguments)
    }
}
#endif
