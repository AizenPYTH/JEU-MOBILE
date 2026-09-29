#if os(iOS)
import SwiftUI
import CaseEngine

/// PhoneAppIcon (handoff UX V3 §5): a flat square in the app's colour, radius 15 at 62 pt, a white
/// SF Symbol. The seized phone is a real phone: standard, familiar, nothing drawn by hand.
struct PhoneAppIcon: View {
    let app: AppID
    var size: CGFloat = Theme.Size.appTile
    /// Kept for callers (the calendar icon is the `calendar` symbol).
    var calendarDay: Moment? = nil

    /// 15 pt at 62 pt, scaled with the icon.
    private var radius: CGFloat { size * phoneIconRadius / Theme.Size.appTile }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        Image(systemName: Self.symbol(app))
            .font(.system(size: size * Self.scale(app), weight: .semibold))
            .foregroundStyle(Theme.Colors.textOnLight)
            .frame(width: size, height: size)
            .background(shape.fill(Theme.appAccent(app)))
            .accessibilityHidden(true)
    }

    /// The symbol of each app (§5 PhoneAppIcon).
    static func symbol(_ app: AppID) -> String {
        switch app {
        case .messages: "message.fill"
        case .phone: "phone.fill"
        case .photos: "photo.on.rectangle"
        case .location: "map.fill"
        case .calendar: "calendar"
        case .notes: "note.text"
        case .mail: "envelope.fill"
        case .contacts: "person.2.fill"
        case .browser: "globe"
        case .trash: "trash.fill"
        case .settings: "gearshape.fill"
        case .notifications: "bell.fill"
        }
    }

    private static func scale(_ app: AppID) -> CGFloat {
        switch app {
        case .contacts, .photos: 0.40
        default: 0.44
        }
    }
}

/// The former name of the icon.
typealias AppTileGlyph = PhoneAppIcon

/// Corner radius of a 62 pt icon.
private let phoneIconRadius: CGFloat = 15
#endif
