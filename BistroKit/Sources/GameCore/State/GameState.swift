import Foundation

public typealias CustomerID = Int
public typealias OrderID = Int

/// The whole mutable state of a game. Plain value type: saved as JSON as-is.
///
/// Only `Game` mutates it. The presentation layer reads it and calls `Game` actions.
public struct GameState: Codable, Sendable, Equatable {
    public var coins: Int
    public var createdAt: Date
    /// Game time up to which the simulation has run.
    public var lastUpdate: Date

    public var discoveredRecipes: [RecipeID]
    public var menu: [RecipeID]
    public var menuSlots: Int

    public var stations: [StationState]
    public var tables: [TableState]
    public var waiter: WaiterState
    /// Dishes cooked and waiting for the waiter, oldest first.
    public var readyOrders: [Order]

    public var secondsUntilNextCustomer: Double
    public var nextID: Int
    public var rng: SplitMix64
    public var stats: GameStats

    public func station(_ id: StationID) -> StationState? {
        stations.first { $0.id == id }
    }
}

public struct Order: Codable, Sendable, Equatable, Identifiable {
    public var id: OrderID
    public var customerID: CustomerID
    public var tableIndex: Int
    public var recipe: RecipeID
}

public struct StationState: Codable, Sendable, Equatable, Identifiable {
    public var id: StationID
    public var level: Int
    public var queue: [Order]
    public var current: Order?
    public var remainingSeconds: Double
    public var totalSeconds: Double

    /// 0…1 progress of the dish being prepared (0 when idle).
    public var progress: Double {
        guard current != nil, totalSeconds > 0 else { return 0 }
        return min(1, max(0, 1 - remainingSeconds / totalSeconds))
    }
}

public struct TableState: Codable, Sendable, Equatable, Identifiable {
    public var id: Int
    public var customer: Customer?
    /// Coins left on the table, waiting to be collected (tap or auto-collect).
    public var pendingCoins: Int
    public var pendingCoinsAge: Double
}

public struct Customer: Codable, Sendable, Equatable, Identifiable {
    public enum Phase: String, Codable, Sendable {
        /// Sitting down and reading the menu.
        case choosing
        /// Order placed, waiting for the dish.
        case waitingForFood
        case eating
    }

    public var id: CustomerID
    public var phase: Phase
    public var phaseElapsed: Double
    public var recipe: RecipeID?
    /// Time between ordering and being served (drives the tip).
    public var waitedSeconds: Double
}

public struct WaiterState: Codable, Sendable, Equatable {
    public var delivering: Order?
    public var remainingSeconds: Double
}

public struct GameStats: Codable, Sendable, Equatable {
    public var customersServed: Int = 0
    public var coinsEarned: Int = 0
    public var tipsEarned: Int = 0
    public var dishesServed: [RecipeID: Int] = [:]
    public var stationTaps: Int = 0
    public var playSeconds: Double = 0

    public init() {}
}
