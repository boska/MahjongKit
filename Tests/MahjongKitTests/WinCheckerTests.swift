import Testing
@testable import MahjongKit

@Suite("WinChecker")
struct WinCheckerTests {

    // MARK: - Standard win (17 tiles: hand=16, drawn=1)

    @Test func allSequencesWin() {
        let hand: [Tile] = [
            .man(1), .man(2), .man(3),
            .man(4), .man(5), .man(6),
            .man(7), .man(8), .man(9),
            .pin(1), .pin(2), .pin(3),
            .sou(5), .sou(6), .sou(7),
            .east
        ]
        let result = WinChecker.canWin(hand: hand, drawn: .east)
        #expect(result != nil)
        #expect(result?.handType == .standard)
        #expect(result?.pair == .east)
    }

    @Test func allTripletsWin() {
        let hand: [Tile] = [
            .man(1), .man(1), .man(1),
            .man(5), .man(5), .man(5),
            .pin(3), .pin(3), .pin(3),
            .sou(7), .sou(7), .sou(7),
            .east, .east, .east,
            .chun
        ]
        let result = WinChecker.canWin(hand: hand, drawn: .chun)
        #expect(result != nil)
        #expect(result?.handType == .standard)
    }

    @Test func notWin() {
        // 聽 1p，但摸到 2p（不能胡）
        let hand: [Tile] = [
            .man(1), .man(2), .man(3),
            .man(4), .man(5), .man(6),
            .man(7), .man(8), .man(9),
            .pin(3), .pin(4), .pin(5),
            .sou(5), .sou(5), .sou(5),
            .east
        ]
        // 此手牌若配 east pair 需要 east×2，但只有 1 張 → 湊不成
        // drawn = 2p，組不出 5 組
        let result = WinChecker.canWin(hand: hand, drawn: .pin(2))
        #expect(result == nil)
    }

    @Test func honorTripletsWin() {
        let hand: [Tile] = [
            .east, .east, .east,
            .south, .south, .south,
            .west, .west, .west,
            .north, .north, .north,
            .chun, .chun, .chun,
            .hatsu
        ]
        let result = WinChecker.canWin(hand: hand, drawn: .hatsu)
        #expect(result != nil)
    }

    // MARK: - Eight Pairs 八對 (16 tiles: hand=15, drawn=1)

    @Test func eightPairsWin() {
        // 7 pairs already, waiting for man(9) to complete 8th
        let hand: [Tile] = [
            .man(1), .man(1),
            .man(3), .man(3),
            .pin(2), .pin(2),
            .pin(7), .pin(7),
            .sou(4), .sou(4),
            .east, .east,
            .chun, .chun,
            .man(9)  // 15th tile: isolated, waiting for pair
        ]
        let result = WinChecker.canWin(hand: hand, drawn: .man(9))
        #expect(result?.handType == .eightPairs)
    }

    @Test func notEightPairs() {
        // Same-tile quad (4-of-a-kind) doesn't qualify as 2 pairs
        let hand: [Tile] = [
            .man(1), .man(1), .man(1), .man(1),  // quad, not 2 pairs
            .pin(2), .pin(2),
            .pin(7), .pin(7),
            .sou(4), .sou(4),
            .east, .east,
            .chun, .chun,
            .haku
        ]
        let result = WinChecker.canWin(hand: hand, drawn: .haku)
        #expect(result?.handType != .eightPairs)
    }

    // MARK: - Thirteen Orphans 十三么 (14 tiles: hand=13, drawn=1)

    @Test func thirteenOrphansWin() {
        let hand: [Tile] = [
            .man(9), .pin(1), .pin(9), .sou(1), .sou(9),
            .east, .south, .west, .north,
            .chun, .hatsu, .haku,
            .man(1)  // 13 orphans, waiting for 1m pair
        ]
        let result = WinChecker.canWin(hand: hand, drawn: .man(1))
        #expect(result?.handType == .thirteenOrphans)
        #expect(result?.pair == .man(1))
    }

    @Test func thirteenOrphansNotWin() {
        // Missing 一つ孤張
        let hand: [Tile] = [
            .man(9), .pin(1), .pin(9), .sou(1), .sou(9),
            .east, .south, .west, .north,
            .chun, .hatsu,
            .man(1), .man(1)  // only 12 types, missing haku
        ]
        let result = WinChecker.canWin(hand: hand, drawn: .man(1))
        #expect(result?.handType != .thirteenOrphans)
    }

    // MARK: - Wall

    @Test func wallDeckCount() {
        #expect(Wall.fullDeck().count == 144)
    }

    @Test func wallDealHandSizes() {
        var wall = Wall()
        let hands = wall.deal()
        #expect(hands.count == 4)
        #expect(hands[0].count == 17)  // 莊家多 1 張
        #expect(hands[1].count == 16)
        #expect(hands[2].count == 16)
        #expect(hands[3].count == 16)
    }

    @Test func seededRNGIsDeterministic() {
        var rng1 = SeededRNG(seed: 42)
        var rng2 = SeededRNG(seed: 42)
        var wall1 = Wall(rng: &rng1)
        var wall2 = Wall(rng: &rng2)
        #expect(wall1.draw() == wall2.draw())
    }

    @Test func differentSeedsProduceDifferentDecks() {
        var rng1 = SeededRNG(seed: 1)
        var rng2 = SeededRNG(seed: 2)
        var wall1 = Wall(rng: &rng1)
        var wall2 = Wall(rng: &rng2)
        // Very unlikely (1/144!) that two different seeds produce same first tile AND same second
        let draws1 = (0..<5).compactMap { _ in wall1.draw() }
        let draws2 = (0..<5).compactMap { _ in wall2.draw() }
        #expect(draws1 != draws2)
    }
}
