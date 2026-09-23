#if os(iOS)
import SwiftUI
import CaseEngine

public typealias AppKind = AppID

extension AppID {
    /// SF Symbol of the app icon.
    var symbol: String {
        switch self {
        case .messages: "message.fill"
        case .phone: "phone.fill"
        case .photos: "photo.on.rectangle.angled"
        case .location: "location.fill"
        case .calendar: "calendar"
        case .notes: "note.text"
        case .browser: "safari.fill"
        case .mail: "envelope.fill"
        case .contacts: "person.crop.circle.fill"
        case .trash: "trash.fill"
        case .settings: "gearshape.fill"
        case .notifications: "bell.badge.fill"
        }
    }

    /// Symbol colour on the icon background.
    var symbolColor: Color {
        switch self {
        case .photos, .calendar: Color(hex: 0xFF453A)
        case .notes: Color(hex: 0x3A3A3C)
        default: .white
        }
    }

    var title: String { L10n.t("app.\(rawValue)") }

    /// Apps pinned to the dock (handoff: Ct, Ap, Ms, Ph).
    static let dock: [AppID] = [.contacts, .phone, .messages, .photos]
}
#endif
