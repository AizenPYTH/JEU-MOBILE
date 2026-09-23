/// Small, fast, seedable RNG (SplitMix64). Stored in the save so a loaded game
/// continues exactly as it would have — and tests/simulations are reproducible.
public struct SplitMix64: RandomNumberGenerator, Codable, Sendable, Equatable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    // Encoded as a string: JSON numbers above 2^53 are not safe everywhere.
    public init(from decoder: any Decoder) throws {
        let text = try decoder.singleValueContainer().decode(String.self)
        guard let value = UInt64(text) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "bad rng state"))
        }
        state = value
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(state))
    }
}
