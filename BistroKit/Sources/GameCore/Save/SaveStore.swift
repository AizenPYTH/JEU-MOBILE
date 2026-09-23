import Foundation

/// Where saves live. Local file today; an iCloud-backed store can implement the same protocol.
public protocol SaveStore: Sendable {
    /// Returns nil when there is no save yet (new player).
    func load() throws -> SaveGame?
    func save(_ save: SaveGame) throws
    func delete() throws
}

/// Saves to a JSON file with an atomic write and keeps the previous save as a backup.
/// If the main file is corrupted, the backup is used instead.
public struct FileSaveStore: SaveStore {
    public let directory: URL
    public let fileName: String
    private let migrator: SaveMigrator

    public init(directory: URL, fileName: String = "save.json", migrator: SaveMigrator = SaveMigrator()) {
        self.directory = directory
        self.fileName = fileName
        self.migrator = migrator
    }

    public var fileURL: URL { directory.appendingPathComponent(fileName) }
    public var backupURL: URL { directory.appendingPathComponent(fileName + ".bak") }

    /// Default location: Application Support/Bistro (not visible to the user, backed up by iOS).
    public static func defaultStore() throws -> FileSaveStore {
        let base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                               appropriateFor: nil, create: true)
        return FileSaveStore(directory: base.appendingPathComponent("Bistro", isDirectory: true))
    }

    public func load() throws -> SaveGame? {
        let fm = FileManager.default
        guard fm.fileExists(atPath: fileURL.path) || fm.fileExists(atPath: backupURL.path) else { return nil }
        do {
            return try SaveCodec.decode(Data(contentsOf: fileURL), migrator: migrator)
        } catch let error as SaveError where isNewer(error) {
            throw error
        } catch {
            // Main file unreadable: fall back to the previous save rather than losing progress.
            guard fm.fileExists(atPath: backupURL.path) else { throw error }
            return try SaveCodec.decode(Data(contentsOf: backupURL), migrator: migrator)
        }
    }

    public func save(_ save: SaveGame) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try SaveCodec.encode(save)
        if fm.fileExists(atPath: fileURL.path) {
            try? fm.removeItem(at: backupURL)
            try? fm.copyItem(at: fileURL, to: backupURL)
        }
        try data.write(to: fileURL, options: .atomic)
    }

    public func delete() throws {
        let fm = FileManager.default
        for url in [fileURL, backupURL] where fm.fileExists(atPath: url.path) {
            try fm.removeItem(at: url)
        }
    }

    private func isNewer(_ error: SaveError) -> Bool {
        if case .newerVersion = error { return true }
        return false
    }
}

/// In-memory store for tests and previews.
public final class InMemorySaveStore: SaveStore, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: SaveGame?

    public init(_ save: SaveGame? = nil) {
        stored = save
    }

    public func load() throws -> SaveGame? {
        lock.lock(); defer { lock.unlock() }
        return stored
    }

    public func save(_ save: SaveGame) throws {
        lock.lock(); defer { lock.unlock() }
        stored = save
    }

    public func delete() throws {
        lock.lock(); defer { lock.unlock() }
        stored = nil
    }
}
