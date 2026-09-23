#if os(iOS)
import Foundation

/// Interface strings from the String Catalog (`Resources/Localizable.xcstrings`), French first, English too.
/// The *content* of a case (messages, notes…) is written in the language of the seized phone.
enum L10n {
    static func t(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module)
    }

    /// Formatted string. Goes through NSLocalizedString + localizedStringWithFormat so that the
    /// catalog's plural variations ("1 manquée" / "3 manquées") are chosen from the arguments.
    static func f(_ key: String, _ arguments: any CVarArg...) -> String {
        let format = NSLocalizedString(key, bundle: .module, comment: "")
        return withVaList(arguments) { NSString(format: format, locale: Locale.current, arguments: $0) as String }
    }
}
#endif
