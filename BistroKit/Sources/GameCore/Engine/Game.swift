import Foundation

/// Errors returned by player actions. They are expected (UI shows a message), not bugs.
public enum GameActionError: Error, Equatable, Sendable {
    case unknownRecipe(RecipeID)
    case recipeNotDiscovered(RecipeID)
    case stationNotOwned(StationID)
    case alreadyOnMenu(RecipeID)
    case notOnMenu(RecipeID)
    case menuFull
    case menuCannotBeEmpty
    case unknownTable(Int)
    case unknownStation(StationID)
    case nothingToBoost
    case nothingToCollect
}

/// The game engine: owns the state, advances the simulation, applies player actions.
///
/// Not thread-safe by design: use it from one actor (the UI keeps it on the main actor).
public final class Game {
    public private(set) var state: GameState
    public let index: ContentIndex
    public let config: GameConfig
    public let clock: any GameClock
    private var pendingEvents: [GameEvent] = []

    private var economy: EconomyConfig { config.economy }

    /// Resumes `state`, or starts a new game when `state` is nil.
    public init(content: GameContent, config: GameConfig, clock: any GameClock, state: GameState? = nil, seed: UInt64? = nil) {
        self.index = ContentIndex(content)
        self.config = config
        self.clock = clock
        self.state = state ?? Game.newState(content: content, config: config, now: clock.now,
                                            seed: seed ?? UInt64(clock.now.timeIntervalSince1970 * 1000))
    }

    public static func newState(content: GameContent, config: GameConfig, now: Date, seed: UInt64) -> GameState {
        let economy = config.economy
        let recipes = Set(content.recipes.map(\.id))
        let startingRecipes = economy.startingRecipes.filter { recipes.contains($0) }
        return GameState(
            coins: economy.startingCoins,
            createdAt: now,
            lastUpdate: now,
            discoveredRecipes: startingRecipes,
            menu: Array(startingRecipes.prefix(economy.startingMenuSlots)),
            menuSlots: economy.startingMenuSlots,
            stations: economy.startingStations.map {
                StationState(id: $0, level: 1, queue: [], current: nil, remainingSeconds: 0, totalSeconds: 0)
            },
            tables: (0..<economy.startingTables).map {
                TableState(id: $0, customer: nil, pendingCoins: 0, pendingCoinsAge: 0)
            },
            waiter: WaiterState(delivering: nil, remainingSeconds: 0),
            readyOrders: [],
            secondsUntilNextCustomer: economy.orderDelaySeconds,
            nextID: 1,
            rng: SplitMix64(seed: seed),
            stats: GameStats()
        )
    }

    // MARK: - Time

    /// Runs the simulation up to the clock's current time.
    ///
    /// - A clock going backwards (device time changed) is ignored: no progress, no penalty.
    /// - Gaps longer than `maxCatchUpSeconds` are only simulated up to that limit (offline income is M5).
    /// - Returns the number of seconds actually simulated.
    @discardableResult
    public func update() -> Double {
        let now = clock.now
        let elapsed = now.timeIntervalSince(state.lastUpdate)
        guard elapsed > 0 else {
            state.lastUpdate = now
            return 0
        }
        let simulated = min(elapsed, economy.maxCatchUpSeconds)
        simulate(seconds: simulated)
        state.lastUpdate = now
        return simulated
    }

    /// Simulates `seconds` of play in fixed steps, regardless of the clock.
    public func simulate(seconds: Double) {
        let step = max(0.01, economy.simulationStepSeconds)
        var remaining = seconds
        while remaining > 1e-9 {
            let dt = min(step, remaining)
            tick(dt)
            remaining -= dt
        }
    }

    /// Returns and clears the events produced since the last call.
    public func drainEvents() -> [GameEvent] {
        defer { pendingEvents.removeAll() }
        return pendingEvents
    }

    // MARK: - Player actions

    /// Tapping a station speeds up the dish being prepared.
    public func boostStation(_ id: StationID) throws(GameActionError) {
        guard let i = state.stations.firstIndex(where: { $0.id == id }) else { throw .unknownStation(id) }
        guard state.stations[i].current != nil else { throw .nothingToBoost }
        state.stations[i].remainingSeconds = max(0, state.stations[i].remainingSeconds - economy.tapBoostSeconds)
        state.stats.stationTaps += 1
        emit(.stationBoosted(id))
            }

    /// Picks up the coins left on a table.
    @discardableResult
    public func collectCoins(table: Int) throws(GameActionError) -> Int {
        guard state.tables.indices.contains(table) else { throw .unknownTable(table) }
        let amount = state.tables[table].pendingCoins
        guard amount > 0 else { throw .nothingToCollect }
        collect(table: table, automatic: false)
        return amount
    }

    /// Picks up the coins on every table.
    @discardableResult
    public func collectAllCoins() -> Int {
        var total = 0
        for i in state.tables.indices where state.tables[i].pendingCoins > 0 {
            total += state.tables[i].pendingCoins
            collect(table: i, automatic: false)
        }
        return total
    }

    public func addToMenu(_ recipeID: RecipeID) throws(GameActionError) {
        guard let recipe = index.recipes[recipeID] else { throw .unknownRecipe(recipeID) }
        guard state.discoveredRecipes.contains(recipeID) else { throw .recipeNotDiscovered(recipeID) }
        guard state.station(recipe.station) != nil else { throw .stationNotOwned(recipe.station) }
        guard !state.menu.contains(recipeID) else { throw .alreadyOnMenu(recipeID) }
        guard state.menu.count < state.menuSlots else { throw .menuFull }
        state.menu.append(recipeID)
        emit(.menuChanged)
            }

    /// Orders already placed for this dish are still served.
    public func removeFromMenu(_ recipeID: RecipeID) throws(GameActionError) {
        guard let i = state.menu.firstIndex(of: recipeID) else { throw .notOnMenu(recipeID) }
        guard state.menu.count > 1 else { throw .menuCannotBeEmpty }
        state.menu.remove(at: i)
        emit(.menuChanged)
            }

    // MARK: - Rules (pure helpers, public so tests and the simulator can check them)

    public func salePrice(of recipe: Recipe) -> Int {
        max(1, Int((Double(recipe.basePrice) * economy.priceMultiplier).rounded()))
    }

    public func prepSeconds(of recipe: Recipe) -> Double {
        max(0.1, recipe.prepSeconds * economy.prepTimeMultiplier)
    }

    /// Tip shrinks linearly with waiting time and never goes negative.
    public func tip(price: Int, waitedSeconds: Double) -> Int {
        guard economy.tipDecaySeconds > 0 else { return 0 }
        let freshness = max(0, 1 - waitedSeconds / economy.tipDecaySeconds)
        return Int((Double(price) * economy.baseTipFraction * freshness).rounded(.down))
    }

    // MARK: - Simulation step

    private func tick(_ dt: Double) {
        state.stats.playSeconds += dt
        spawnCustomers(dt)
        updateCustomers(dt)
        updateStations(dt)
        updateWaiter(dt)
        updateCoins(dt)
    }

    private func spawnCustomers(_ dt: Double) {
        state.secondsUntilNextCustomer -= dt
        guard state.secondsUntilNextCustomer <= 0, !state.menu.isEmpty else { return }
        let free = state.tables.indices.filter { state.tables[$0].customer == nil && state.tables[$0].pendingCoins == 0 }
        guard let table = free.randomElement(using: &state.rng) else {
            state.secondsUntilNextCustomer = 0 // someone is waiting at the door
            return
        }
        let id = makeID()
        state.tables[table].customer = Customer(id: id, phase: .choosing, phaseElapsed: 0, recipe: nil, waitedSeconds: 0)
        let jitter = economy.customerSpawnJitterSeconds
        let offset = jitter > 0 ? Double.random(in: -jitter...jitter, using: &state.rng) : 0
        state.secondsUntilNextCustomer = max(0.5, economy.customerSpawnIntervalSeconds + offset)
        emit(.customerArrived(tableIndex: table, customerID: id))
    }

    private func updateCustomers(_ dt: Double) {
        for t in state.tables.indices {
            guard var customer = state.tables[t].customer else { continue }
            customer.phaseElapsed += dt
            switch customer.phase {
            case .choosing:
                if customer.phaseElapsed >= economy.orderDelaySeconds, let recipe = pickDish() {
                    customer.recipe = recipe.id
                    customer.phase = .waitingForFood
                    customer.phaseElapsed = 0
                    let order = Order(id: makeID(), customerID: customer.id, tableIndex: t, recipe: recipe.id)
                    if let s = state.stations.firstIndex(where: { $0.id == recipe.station }) {
                        state.stations[s].queue.append(order)
                    }
                    emit(.orderPlaced(order))
                }
            case .waitingForFood:
                customer.waitedSeconds += dt
            case .eating:
                if customer.phaseElapsed >= economy.eatSeconds {
                    pay(customer, table: t)
                    state.tables[t].customer = nil
                    continue
                }
            }
            state.tables[t].customer = customer
        }
    }

    /// Only dishes whose station exists can be ordered (the menu rules already enforce it).
    private func pickDish() -> Recipe? {
        let options = state.menu.compactMap { index.recipes[$0] }.filter { state.station($0.station) != nil }
        return options.randomElement(using: &state.rng)
    }

    private func updateStations(_ dt: Double) {
        for s in state.stations.indices {
            if state.stations[s].current == nil {
                guard !state.stations[s].queue.isEmpty else { continue }
                let order = state.stations[s].queue.removeFirst()
                let seconds = index.recipes[order.recipe].map(prepSeconds(of:)) ?? 1
                state.stations[s].current = order
                state.stations[s].totalSeconds = seconds
                state.stations[s].remainingSeconds = seconds
                emit(.preparationStarted(station: state.stations[s].id, order: order))
            }
            state.stations[s].remainingSeconds -= dt
            if state.stations[s].remainingSeconds <= 0, let order = state.stations[s].current {
                state.stations[s].current = nil
                state.stations[s].remainingSeconds = 0
                state.stations[s].totalSeconds = 0
                state.readyOrders.append(order)
                emit(.dishReady(station: state.stations[s].id, order: order))
            }
        }
    }

    private func updateWaiter(_ dt: Double) {
        if state.waiter.delivering == nil {
            guard !state.readyOrders.isEmpty else { return }
            state.waiter.delivering = state.readyOrders.removeFirst()
            state.waiter.remainingSeconds = economy.waiterDeliverySeconds
        }
        state.waiter.remainingSeconds -= dt
        guard state.waiter.remainingSeconds <= 0, let order = state.waiter.delivering else { return }
        state.waiter.delivering = nil
        state.waiter.remainingSeconds = 0
        if var customer = state.tables[order.tableIndex].customer, customer.id == order.customerID {
            customer.phase = .eating
            customer.phaseElapsed = 0
            state.tables[order.tableIndex].customer = customer
            emit(.dishServed(order))
        }
    }

    private func pay(_ customer: Customer, table: Int) {
        guard let recipeID = customer.recipe, let recipe = index.recipes[recipeID] else { return }
        let price = salePrice(of: recipe)
        let tip = tip(price: price, waitedSeconds: customer.waitedSeconds)
        state.tables[table].pendingCoins += price + tip
        state.tables[table].pendingCoinsAge = 0
        state.stats.customersServed += 1
        state.stats.tipsEarned += tip
        state.stats.dishesServed[recipeID, default: 0] += 1
        emit(.customerPaid(tableIndex: table, price: price, tip: tip))
    }

    private func updateCoins(_ dt: Double) {
        for t in state.tables.indices where state.tables[t].pendingCoins > 0 {
            state.tables[t].pendingCoinsAge += dt
            if state.tables[t].pendingCoinsAge >= economy.autoCollectDelaySeconds {
                collect(table: t, automatic: true)
            }
        }
    }

    private func collect(table: Int, automatic: Bool) {
        let amount = state.tables[table].pendingCoins
        state.coins += amount
        state.stats.coinsEarned += amount
        state.tables[table].pendingCoins = 0
        state.tables[table].pendingCoinsAge = 0
        emit(.coinsCollected(tableIndex: table, amount: amount, automatic: automatic))
    }

    private func makeID() -> Int {
        defer { state.nextID += 1 }
        return state.nextID
    }

    private func emit(_ event: GameEvent) {
        pendingEvents.append(event)
    }
}
