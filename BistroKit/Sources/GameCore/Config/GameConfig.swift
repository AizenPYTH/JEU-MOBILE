import Foundation

// Balance config = *how the game feels*: prices multipliers, timers, curves, caps…
// Every number a designer may want to tune lives in a JSON file under GameData/Resources/Config.
// Sections are filled milestone by milestone (M1 economy, M3 lab, M4 affinity, M5 progression,
// M7 ads). Unknown keys are ignored, so adding a field to JSON before the code is harmless.

/// Common header of every balance file.
public protocol ConfigSection: Codable, Sendable {
    var schemaVersion: Int { get }
}

public struct EconomyConfig: ConfigSection {
    public var schemaVersion: Int
}

public struct LabConfig: ConfigSection {
    public var schemaVersion: Int
}

public struct AffinityConfig: ConfigSection {
    public var schemaVersion: Int
}

public struct ProgressionConfig: ConfigSection {
    public var schemaVersion: Int
}

public struct OfflineConfig: ConfigSection {
    public var schemaVersion: Int
}

public struct AdsConfig: ConfigSection {
    public var schemaVersion: Int
}

public struct GameConfig: Sendable {
    public var economy: EconomyConfig
    public var lab: LabConfig
    public var affinity: AffinityConfig
    public var progression: ProgressionConfig
    public var offline: OfflineConfig
    public var ads: AdsConfig
}

public enum ConfigLoader {
    public static let supportedSchemaVersion = 1

    public enum FileName {
        public static let economy = "economy.json"
        public static let lab = "lab.json"
        public static let affinity = "affinity.json"
        public static let progression = "progression.json"
        public static let offline = "offline.json"
        public static let ads = "ads.json"
    }

    public static func load(from directory: URL) throws -> GameConfig {
        GameConfig(
            economy: try section(FileName.economy, in: directory),
            lab: try section(FileName.lab, in: directory),
            affinity: try section(FileName.affinity, in: directory),
            progression: try section(FileName.progression, in: directory),
            offline: try section(FileName.offline, in: directory),
            ads: try section(FileName.ads, in: directory)
        )
    }

    static func section<T: ConfigSection>(_ file: String, in directory: URL) throws -> T {
        let value: T = try JSONFile.decode(file, in: directory)
        guard value.schemaVersion <= supportedSchemaVersion else {
            throw ContentLoadError.unsupportedSchema(
                file: file, found: value.schemaVersion, supported: supportedSchemaVersion)
        }
        return value
    }
}
