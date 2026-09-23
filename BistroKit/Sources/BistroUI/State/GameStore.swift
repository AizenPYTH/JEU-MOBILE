import Foundation
import Observation
import GameCore
import GameData

/// Bridge between the engine and SwiftUI.
///
/// Owns the `Game`, runs it ~10 times per second while the app is active, publishes a
/// snapshot of the state for the views, forwards player actions and handles saving.
/// Contains no game rules.
@MainActor
@Observable
public final class GameStore {
    public private(set) var state: GameState
    /// Shown as a banner when something went wrong with the save.
    public private(set) var saveProblem: String?
    public let content: GameContent
    public let index: ContentIndex

    @ObservationIgnored private var game: Game
    @ObservationIgnored private let config: GameConfig
    @ObservationIgnored private let clock: any GameClock
    @ObservationIgnored private let saveStore: any SaveStore
    @ObservationIgnored private let deviceID: String
    @ObservationIgnored private var savingEnabled = true
    @ObservationIgnored private var lastSave: Date
    @ObservationIgnored private var loop: Task<Void, Never>?

    public init(content: GameContent, config: GameConfig, saveStore: any SaveStore,
                clock: any GameClock = SystemClock(), deviceID: String = "preview") {
        self.content = content
        self.index = ContentIndex(content)
        self.config = config
        self.clock = clock
        self.saveStore = saveStore
        self.deviceID = deviceID
        self.lastSave = clock.now

        var restored: GameState?
        var problem: String?
        var canSave = true
        do {
            restored = try saveStore.load()?.state
        } catch SaveError.newerVersion(_, _) {
            // Never overwrite a save made by a newer build (e.g. TestFlight then an older build).
            canSave = false
            problem = L10n.string("error.saveNewer")
        } catch {
            problem = L10n.format("error.saveCorrupted", String(describing: error))
        }
        let game = Game(content: content, config: config, clock: clock, state: restored)
        self.game = game
        self.state = game.state
        self.savingEnabled = canSave
        self.saveProblem = problem
    }

    /// Store for the real app: bundled data + save file in Application Support.
    public static func live() throws -> GameStore {
        GameStore(content: try GameData.loadContent(), config: try GameData.loadConfig(),
                  saveStore: try FileSaveStore.defaultStore(), deviceID: DeviceIdentity.id)
    }

    /// In-memory store for SwiftUI previews.
    public static func preview(playedSeconds: Double = 120) -> GameStore {
        let content = (try? GameData.loadContent()) ?? GameContent()
        let config = try! GameData.loadConfig()
        let store = GameStore(content: content, config: config, saveStore: InMemorySaveStore())
        store.game.simulate(seconds: playedSeconds)
        store.state = store.game.state
        return store
    }

    // MARK: Lifecycle

    public func start() {
        guard loop == nil else { return }
        tick()
        loop = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                self?.tick()
            }
        }
    }

    public func stop() {
        loop?.cancel()
        loop = nil
        tick()
        save()
    }

    public func save() {
        guard savingEnabled else { return }
        do {
            try saveStore.save(SaveGame(state: game.state, savedAt: clock.now, deviceID: deviceID))
            lastSave = clock.now
        } catch {
            saveProblem = L10n.format("error.saveFailed", String(describing: error))
        }
    }

    private func tick() {
        game.update()
        _ = game.drainEvents() // M2: feed animations / sounds / analytics.
        state = game.state
        if clock.now.timeIntervalSince(lastSave) >= config.economy.autosaveIntervalSeconds {
            save()
        }
    }

    // MARK: Player actions

    public func boost(_ station: StationID) {
        try? game.boostStation(station)
        state = game.state
    }

    public func collect(table: Int) {
        _ = try? game.collectCoins(table: table)
        state = game.state
    }

    public func collectAll() {
        game.collectAllCoins()
        state = game.state
    }

    public func toggleMenu(_ recipe: RecipeID) {
        if state.menu.contains(recipe) {
            try? game.removeFromMenu(recipe)
        } else {
            try? game.addToMenu(recipe)
        }
        state = game.state
    }

    /// Debug only: wipes the save and starts over.
    public func resetGame() {
        try? saveStore.delete()
        game = Game(content: content, config: config, clock: clock)
        state = game.state
        save()
    }
}

/// Random id generated once per install, stored in UserDefaults. Used to tell devices apart in saves.
enum DeviceIdentity {
    static var id: String {
        let key = "bistro.deviceID"
        if let existing = UserDefaults.standard.string(forKey: key) { return existing }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: key)
        return new
    }
}
