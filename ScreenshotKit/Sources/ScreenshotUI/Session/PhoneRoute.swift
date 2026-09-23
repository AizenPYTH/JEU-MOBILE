#if os(iOS)
import CaseEngine

/// Navigation inside the seized phone. The home screen is the empty path.
enum PhoneRoute: Hashable, Codable {
    case app(AppID)
    /// Screen 11 — search across the whole phone.
    case search
    case conversation(String, focus: String? = nil)
    case contact(ContactID)
    case photo(String)
    case track(String)
    case calendarEvent(String)
    case note(String)
    case mail(String)
    case browserEntry(String)
}
#endif
