import Foundation

/// What is written to disk. The envelope stays stable across versions; `state` evolves
/// through migrations. `savedAt` and `deviceID` will let a future iCloud sync pick the
/// most recent save and detect conflicts.
public struct SaveGame: Codable, Sendable, Equatable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var savedAt: Date
    public var deviceID: String
    public var state: GameState

    public init(state: GameState, savedAt: Date, deviceID: String) {
        self.schemaVersion = Self.currentSchemaVersion
        self.savedAt = savedAt
        self.deviceID = deviceID
        self.state = state
    }
}

public enum SaveError: Error, Equatable, Sendable {
    case corrupted(String)
    /// The save was written by a newer version of the game: never overwrite it.
    case newerVersion(found: Int, supported: Int)
    case missingMigration(from: Int)
}

/// Upgrades raw save JSON from older schema versions, one step at a time.
///
/// To change the save format:
/// 1. bump `SaveGame.currentSchemaVersion` to N,
/// 2. add a migration keyed `N - 1` that edits the JSON dictionary (rename/add fields…),
/// 3. add a test that loads a real version N - 1 save.
public struct SaveMigrator: Sendable {
    public typealias Migration = @Sendable (inout [String: Any]) throws -> Void

    public let currentVersion: Int
    /// `migrations[v]` upgrades a save from version v to v + 1.
    public let migrations: [Int: Migration]

    public init(currentVersion: Int = SaveGame.currentSchemaVersion, migrations: [Int: Migration] = SaveMigrator.all) {
        self.currentVersion = currentVersion
        self.migrations = migrations
    }

    /// Registry of all migrations shipped with the game. Empty while the format is at v1.
    public static let all: [Int: Migration] = [:]

    public func migrate(_ data: Data) throws -> Data {
        guard var root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw SaveError.corrupted("not a JSON object")
        }
        guard var version = root["schemaVersion"] as? Int else {
            throw SaveError.corrupted("missing schemaVersion")
        }
        if version > currentVersion {
            throw SaveError.newerVersion(found: version, supported: currentVersion)
        }
        if version == currentVersion { return data }
        while version < currentVersion {
            guard let migration = migrations[version] else { throw SaveError.missingMigration(from: version) }
            try migration(&root)
            version += 1
            root["schemaVersion"] = version
        }
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }
}

/// JSON encoding shared by every save store.
public enum SaveCodec {
    public static func encode(_ save: SaveGame) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(save)
    }

    public static func decode(_ data: Data, migrator: SaveMigrator = SaveMigrator()) throws -> SaveGame {
        let migrated = try migrator.migrate(data)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        do {
            return try decoder.decode(SaveGame.self, from: migrated)
        } catch {
            throw SaveError.corrupted(String(describing: error))
        }
    }
}
