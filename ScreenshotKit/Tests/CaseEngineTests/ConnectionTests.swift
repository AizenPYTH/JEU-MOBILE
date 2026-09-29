import Foundation
import Testing
@testable import CaseEngine

@Suite("Connections and the conclusion threshold")
struct ConnectionTests {
    private let e1 = ItemRef(.message, "e1")
    private let p1 = ItemRef(.photoInfo, "p1")
    private let l3 = ItemRef(.message, "l3")

    @Test func chainsLinkFiledPiecesAndPeople() {
        let (game, _) = Fixtures.investigation()
        game.start()
        #expect(game.connect(.piece(e1), .person("s_emma"), verb: .implicates) == nil, "not filed yet")
        game.togglePin(e1)
        game.togglePin(p1)
        let chain = game.connect(.piece(e1), .piece(p1), verb: .contradicts)
        #expect(chain?.nodes.count == 2 && chain?.verbs == [.contradicts])
        #expect(game.connect(.piece(e1), .piece(e1), verb: .confirms) == nil, "an element with itself")
        let id = chain!.id
        #expect(game.extend(id, with: .person("s_emma"), verb: .implicates))
        #expect(!game.extend(id, with: .piece(e1), verb: .confirms), "already in the chain")
        #expect(!game.extend(id, with: .person("nobody"), verb: .confirms))
        #expect(game.connections.first?.nodes == [.piece(e1), .piece(p1), .person("s_emma")])
        #expect(game.connections.first?.verbs == [.contradicts, .implicates])
        game.togglePin(p1)
        #expect(game.connections.isEmpty, "a piece taken out of the file leaves its chains")
        game.togglePin(p1)
        let other = game.connect(.piece(p1), .person("s_lucas"), verb: .sameTime)!
        game.removeConnection(other.id)
        #expect(game.connections.isEmpty)
    }

    @Test func connectionsSurviveASaveAndDoNotScore() throws {
        let (game, clock) = Fixtures.investigation()
        game.start()
        game.togglePin(e1)
        game.connect(.piece(e1), .person("s_emma"), verb: .implicates)
        let saved = try #require(game.snapshot())
        let data = try JSONEncoder().encode(saved)
        let back = try JSONDecoder().decode(InvestigationSnapshot.self, from: data)
        let resumed = try #require(Investigation(restoring: back, caseFile: Fixtures.caseFile, rules: Fixtures.rules, clock: clock))
        #expect(resumed.connections == game.connections)

        let (plain, _) = Fixtures.investigation()
        plain.start()
        plain.togglePin(e1)
        #expect(plain.accuse("s_emma")?.score == game.accuse("s_emma")?.score)
    }

    @Test func aSaveFromAnEarlierVersionHasNoConnection() throws {
        let (game, clock) = Fixtures.investigation()
        game.start()
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(try #require(game.snapshot()))) as! [String: Any]
        json.removeValue(forKey: "connections")
        let old = try JSONDecoder().decode(InvestigationSnapshot.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(Investigation(restoring: old, caseFile: Fixtures.caseFile, rules: Fixtures.rules, clock: clock)?.connections == [])
    }

    @Test func theConclusionWaitsForThreePiecesUnlessTimeIsUp() {
        var rules = Fixtures.rules
        rules.minPiecesToConclude = 3
        let clock = ManualClock(start: Date(timeIntervalSince1970: 1_000_000))
        let game = Investigation(caseFile: Fixtures.caseFile, rules: rules, clock: clock)
        game.start()
        #expect(game.piecesNeededToConclude == 3)
        game.togglePin(e1)
        game.togglePin(p1)
        #expect(!game.canConclude)
        game.togglePin(l3)
        #expect(game.canConclude)
        game.togglePin(l3)
        for _ in 0..<(400 * 2) { clock.advance(by: 0.5); game.tick() }
        #expect(game.phase == .accusing && game.canConclude, "time is up: the conclusion is always offered")
    }

    @Test func theShippedRulesAskForThreePieces() throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/CaseLibrary/Resources/Rules/rules.json")
        let rules = try JSONDecoder().decode(GameRules.self, from: Data(contentsOf: url))
        #expect(rules.minPiecesToConclude == 3)
    }
}
