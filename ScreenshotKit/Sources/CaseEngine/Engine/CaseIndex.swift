/// Fast id → item lookups across all devices of a case.
public struct CaseIndex: Sendable {
    private let devices: [String: Device]
    private let contacts: [ContactID: Contact]
    private let conversations: [String: Conversation]
    private let messages: [String: Message]
    private let messageConversation: [String: String]
    private let photos: [String: Photo]
    private let tracks: [String: LocationTrack]
    private let places: [String: Place]
    private let calendar: [String: CalendarEvent]
    private let notes: [String: Note]
    private let mails: [String: Mail]
    private let browser: [String: BrowserEntry]
    private let calls: [String: Call]
    private let suspects: [SuspectID: Suspect]
    private let suspectByContact: [ContactID: Suspect]

    public init(_ file: CaseFile) {
        func dict<T>(_ items: [T], _ key: (T) -> String) -> [String: T] {
            Dictionary(items.map { (key($0), $0) }, uniquingKeysWith: { first, _ in first })
        }
        let all = file.devices
        devices = dict(all, \.id)
        contacts = dict(all.flatMap(\.contacts), \.id)
        conversations = dict(all.flatMap(\.conversations), \.id)
        let liveMessages = all.flatMap(\.liveEvents).compactMap { event in event.message.map { (event.conversation ?? "", $0) } }
        let baseMessages = all.flatMap(\.conversations).flatMap { c in c.messages.map { (c.id, $0) } }
        messages = dict((baseMessages + liveMessages).map(\.1), \.id)
        messageConversation = Dictionary((baseMessages + liveMessages).map { ($0.1.id, $0.0) }, uniquingKeysWith: { a, _ in a })
        photos = dict(all.flatMap(\.photos), \.id)
        tracks = dict(all.flatMap(\.tracks), \.id)
        places = dict(all.flatMap(\.places), \.id)
        calendar = dict(all.flatMap(\.calendar), \.id)
        notes = dict(all.flatMap(\.notes), \.id)
        mails = dict(all.flatMap(\.mails), \.id)
        browser = dict(all.flatMap(\.browser), \.id)
        calls = dict(all.flatMap(\.calls) + all.flatMap(\.liveEvents).compactMap(\.call), \.id)
        suspects = dict(file.suspects, \.id)
        suspectByContact = Dictionary(file.suspects.map { ($0.contact, $0) }, uniquingKeysWith: { a, _ in a })
    }

    public func device(_ id: String) -> Device? { devices[id] }
    public func contact(_ id: ContactID) -> Contact? { contacts[id] }
    public func conversation(_ id: String) -> Conversation? { conversations[id] }
    public func message(_ id: String) -> Message? { messages[id] }
    public func conversationID(ofMessage id: String) -> String? { messageConversation[id] }
    public func photo(_ id: String) -> Photo? { photos[id] }
    public func track(_ id: String) -> LocationTrack? { tracks[id] }
    public func place(_ id: String) -> Place? { places[id] }
    public func calendarEvent(_ id: String) -> CalendarEvent? { calendar[id] }
    public func note(_ id: String) -> Note? { notes[id] }
    public func mail(_ id: String) -> Mail? { mails[id] }
    public func browserEntry(_ id: String) -> BrowserEntry? { browser[id] }
    public func call(_ id: String) -> Call? { calls[id] }
    public func suspect(_ id: SuspectID) -> Suspect? { suspects[id] }
    public func suspect(forContact id: ContactID) -> Suspect? { suspectByContact[id] }
}
