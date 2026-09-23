import Foundation
import Testing
@testable import GameCore

@Suite("Game engine")
struct GameEngineTests {
    @Test func newGameUsesConfig() {
        let (game, _) = Fixtures.game()
        #expect(game.state.coins == 50)
        #expect(game.state.tables.count == 3)
        #expect(game.state.stations.map(\.id) == ["stove", "oven"])
        #expect(game.state.menu == ["omelette"])
        #expect(game.state.discoveredRecipes == ["omelette"])
    }

    @Test func customersArriveOrderGetServedAndPay() {
        let (game, clock) = Fixtures.game()
        clock.advance(by: 120)
        game.update()
        let events = game.drainEvents()
        #expect(events.contains { if case .customerArrived = $0 { true } else { false } })
        #expect(events.contains { if case .orderPlaced = $0 { true } else { false } })
        #expect(events.contains { if case .dishServed = $0 { true } else { false } })
        #expect(events.contains { if case .customerPaid = $0 { true } else { false } })
        #expect(game.state.stats.customersServed > 0)
        #expect(game.state.coins > 50)
        #expect(game.state.stats.dishesServed["omelette", default: 0] == game.state.stats.customersServed)
    }

    @Test func oneHourOfPlayIsFastAndProfitable() {
        let (game, _) = Fixtures.game()
        let start = Date()
        game.simulate(seconds: 3_600)
        #expect(Date().timeIntervalSince(start) < 2)
        // ~1 customer / 5 s with 3 tables → hundreds of customers in an hour.
        #expect(game.state.stats.customersServed > 300)
        #expect(game.state.coins == 50 + game.state.stats.coinsEarned)
    }

    @Test func coinsLeftOnTableAreCollectedByTapOrAutomatically() {
        let (game, _) = Fixtures.game { $0.autoCollectDelaySeconds = 1_000 }
        game.simulate(seconds: 30)
        let pending = game.state.tables.map(\.pendingCoins).reduce(0, +)
        #expect(pending > 0)
        let coinsBefore = game.state.coins
        #expect(game.collectAllCoins() == pending)
        #expect(game.state.coins == coinsBefore + pending)
        #expect(throws: GameActionError.nothingToCollect) { try game.collectCoins(table: 0) }
        #expect(throws: GameActionError.unknownTable(99)) { try game.collectCoins(table: 99) }

        let (auto, _) = Fixtures.game { $0.autoCollectDelaySeconds = 2 }
        auto.simulate(seconds: 60)
        #expect(auto.state.coins > 50)
    }

    @Test func tablesWithCoinsAreNotReusedUntilCollected() {
        let (game, _) = Fixtures.game { $0.autoCollectDelaySeconds = 1_000 }
        game.simulate(seconds: 600)
        // Every table ends up holding coins, so service stalls: tapping coins matters.
        #expect(game.state.tables.allSatisfy { $0.pendingCoins > 0 && $0.customer == nil })
        #expect(game.state.stats.customersServed == 3)
    }

    @Test func tappingAStationSpeedsUpPreparation() throws {
        let (game, _) = Fixtures.game { $0.tapBoostSeconds = 2 }
        #expect(throws: GameActionError.nothingToBoost) { try game.boostStation("stove") }
        #expect(throws: GameActionError.unknownStation("laser")) { try game.boostStation("laser") }
        // Wait until the stove is cooking.
        for _ in 0..<200 where game.state.station("stove")?.current == nil { game.simulate(seconds: 0.25) }
        let before = game.state.station("stove")!.remainingSeconds
        try game.boostStation("stove")
        #expect(game.state.station("stove")!.remainingSeconds == max(0, before - 2))
        #expect(game.state.stats.stationTaps == 1)
    }

    @Test func tipShrinksWithWaitingTime() {
        let (game, _) = Fixtures.game()
        #expect(game.tip(price: 10, waitedSeconds: 0) == 2)
        #expect(game.tip(price: 10, waitedSeconds: 10) == 1)
        #expect(game.tip(price: 10, waitedSeconds: 60) == 0)
    }

    @Test func menuRules() {
        let (game, _) = Fixtures.game()
        #expect(throws: GameActionError.recipeNotDiscovered("bruschetta")) { try game.addToMenu("bruschetta") }
        #expect(throws: GameActionError.unknownRecipe("nope")) { try game.addToMenu("nope") }
        #expect(throws: GameActionError.alreadyOnMenu("omelette")) { try game.addToMenu("omelette") }
        #expect(throws: GameActionError.menuCannotBeEmpty) { try game.removeFromMenu("omelette") }
        #expect(throws: GameActionError.notOnMenu("bruschetta")) { try game.removeFromMenu("bruschetta") }
    }

    @Test func menuRulesWithMoreRecipes() {
        let (game, _) = Fixtures.game {
            $0.startingRecipes = ["omelette", "bruschetta", "honey_lemonade"]
            $0.startingMenuSlots = 1
        }
        #expect(game.state.menu == ["omelette"])
        #expect(throws: GameActionError.menuFull) { try game.addToMenu("bruschetta") }
        #expect(throws: GameActionError.stationNotOwned("drinks_bar")) { try game.addToMenu("honey_lemonade") }
    }

    @Test func clockGoingBackwardsIsHarmless() {
        let (game, clock) = Fixtures.game()
        clock.advance(by: 60)
        game.update()
        let coins = game.state.coins
        clock.set(clock.now.addingTimeInterval(-10_000))
        #expect(game.update() == 0)
        #expect(game.state.coins == coins)
        clock.advance(by: 10)
        #expect(game.update() == 10)
    }

    @Test func longGapsAreCappedToMaxCatchUp() {
        let (game, clock) = Fixtures.game { $0.maxCatchUpSeconds = 300 }
        clock.advance(by: 86_400)
        #expect(game.update() == 300)
        #expect(game.state.lastUpdate == clock.now)
    }

    @Test func sameSeedSameGame() {
        let (a, _) = Fixtures.game(seed: 7)
        let (b, _) = Fixtures.game(seed: 7)
        a.simulate(seconds: 900)
        b.simulate(seconds: 900)
        #expect(a.state == b.state)
    }

    @Test func updateInSmallOrLargeChunksGivesSameResult() {
        let (a, clockA) = Fixtures.game(seed: 3)
        let (b, clockB) = Fixtures.game(seed: 3)
        clockA.advance(by: 600); a.update()
        for _ in 0..<600 { clockB.advance(by: 1); b.update() }
        #expect(a.state.stats.customersServed == b.state.stats.customersServed)
        #expect(a.state.coins == b.state.coins)
    }
}
