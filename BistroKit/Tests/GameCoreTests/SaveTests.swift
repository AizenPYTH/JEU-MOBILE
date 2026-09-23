import Foundation
import Testing
@testable import GameCore

@Suite("Save & load")
struct SaveTests {
    private func tempDir() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("bistro-tests-\(UUID().uuidString)")
    }

    private func playedSave() -> SaveGame {
        let (game, clock) = Fixtures.game()
        game.simulate(seconds: 200)
        return SaveGame(state: game.state, savedAt: clock.now, deviceID: "test")
    }

    @Test func roundTripKeepsEverything() throws {
        let save = playedSave()
        let decoded = try SaveCodec.decode(SaveCodec.encode(save))
        #expect(decoded == save)
    }

    @Test func loadedGameContinuesIdentically() throws {
        let (original, clock) = Fixtures.game(seed: 11)
        original.simulate(seconds: 100)
        let restoredState = try SaveCodec.decode(SaveCodec.encode(
            SaveGame(state: original.state, savedAt: clock.now, deviceID: "t"))).state
        let restored = Game(content: Fixtures.content, config: Fixtures.config(), clock: clock, state: restoredState)
        original.simulate(seconds: 300)
        restored.simulate(seconds: 300)
        #expect(original.state == restored.state)
    }

    @Test func fileStoreSavesLoadsAndDeletes() throws {
        let store = FileSaveStore(directory: tempDir())
        #expect(try store.load() == nil)
        let save = playedSave()
        try store.save(save)
        #expect(try store.load() == save)
        try store.delete()
        #expect(try store.load() == nil)
    }

    @Test func corruptedFileFallsBackToBackup() throws {
        let store = FileSaveStore(directory: tempDir())
        let first = playedSave()
        try store.save(first)
        var second = first
        second.state.coins += 1_000
        try store.save(second) // first becomes the backup
        try Data("{ not json".utf8).write(to: store.fileURL)
        #expect(try store.load() == first)
    }

    @Test func newerSaveIsRejectedNotOverwritten() throws {
        let json = #"{"schemaVersion": 99, "savedAt": 0, "deviceID": "x", "state": {}}"#
        #expect(throws: SaveError.newerVersion(found: 99, supported: SaveGame.currentSchemaVersion)) {
            try SaveCodec.decode(Data(json.utf8))
        }
    }

    @Test func migrationsRunInOrder() throws {
        // A pretend v0 save where coins were called "money".
        var v1 = try JSONSerialization.jsonObject(with: SaveCodec.encode(playedSave())) as! [String: Any]
        var state = v1["state"] as! [String: Any]
        state["money"] = state.removeValue(forKey: "coins")
        v1["state"] = state
        v1["schemaVersion"] = 0
        let v0 = try JSONSerialization.data(withJSONObject: v1)

        let migrator = SaveMigrator(currentVersion: 1, migrations: [
            0: { root in
                var state = root["state"] as! [String: Any]
                state["coins"] = state.removeValue(forKey: "money")
                root["state"] = state
            },
        ])
        let save = try SaveCodec.decode(v0, migrator: migrator)
        #expect(save.schemaVersion == 1)
        #expect(save.state.coins == playedSave().state.coins)

        #expect(throws: SaveError.missingMigration(from: 0)) {
            try SaveCodec.decode(v0, migrator: SaveMigrator(currentVersion: 1, migrations: [:]))
        }
    }
}
