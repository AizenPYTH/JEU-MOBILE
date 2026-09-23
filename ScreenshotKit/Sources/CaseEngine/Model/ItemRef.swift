/// A reference to any item of a phone, written `"kind:id"` in JSON (e.g. `"photoInfo:p_emma_couch"`).
///
/// Used by evidence (what the player must have seen), pins on suspects, notifications and search.
public struct ItemRef: Codable, Hashable, Sendable, CustomStringConvertible {
    public enum Kind: String, Codable, Sendable, CaseIterable {
        /// A message was on screen (for a deleted one: after recovery).
        case message
        /// The unsent draft of a conversation was on screen.
        case draft
        case call
        /// The photo was opened.
        case photo
        /// The photo's metadata and details were analysed.
        case photoInfo
        /// A location history was opened.
        case track
        case calendar
        case note
        case mail
        case browser
        case contact
        /// An app was opened.
        case app
    }

    public var kind: Kind
    public var id: String

    public init(_ kind: Kind, _ id: String) {
        self.kind = kind
        self.id = id
    }

    public init?(_ text: String) {
        let parts = text.split(separator: ":", maxSplits: 1)
        guard parts.count == 2, let kind = Kind(rawValue: String(parts[0])) else { return nil }
        self.init(kind, String(parts[1]))
    }

    public var description: String { "\(kind.rawValue):\(id)" }

    public init(from decoder: any Decoder) throws {
        let text = try decoder.singleValueContainer().decode(String.self)
        guard let ref = ItemRef(text) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                                                    debugDescription: "Invalid item reference '\(text)'"))
        }
        self = ref
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
