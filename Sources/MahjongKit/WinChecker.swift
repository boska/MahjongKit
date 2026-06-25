public struct WinChecker {

    // MARK: - Public entry point

    /// 判斷手牌是否能胡。
    /// - Parameters:
    ///   - hand: 手牌（不含花牌，16 張立牌 + 已公開的吃碰槓不算在此）
    ///   - drawn: 摸到的那張（自摸）或別人打的那張（放炮）
    ///   - openMelds: 已公開吃碰槓（每組視為從手牌移除）
    /// - Returns: 第一個合法的 WinResult，無法胡則 nil
    public static func canWin(hand: [Tile], drawn: Tile, openMelds: [MeldType] = []) -> WinResult? {
        let nonFlowers = (hand + [drawn]).filter { !$0.isFlower }
        // 八對 / 十三么 只在完全門前（無吃碰槓）時成立
        if openMelds.isEmpty {
            if let r = checkEightPairs(nonFlowers)      { return r }
            if let r = checkThirteenOrphans(nonFlowers) { return r }
        }
        // 標準型：每組已公開的吃碰槓視為一組面子，立牌只需湊滿其餘面子 + 雀頭
        return checkStandard(nonFlowers, openMeldCount: openMelds.count)
    }

    /// 純粹檢查一組牌（含摸張）能否胡，不管吃碰槓。
    public static func isWinningHand(_ tiles: [Tile]) -> Bool {
        canWin(hand: Array(tiles.dropLast()), drawn: tiles.last!) != nil
    }

    // MARK: - Eight Pairs 八對

    private static func checkEightPairs(_ tiles: [Tile]) -> WinResult? {
        guard tiles.count == 16 else { return nil }
        var counts: [Tile: Int] = [:]
        for t in tiles { counts[t, default: 0] += 1 }
        guard counts.values.allSatisfy({ $0 == 2 }) else { return nil }
        // 用第一張牌作為 pair 代表（八對沒有真正的雀頭，給個代表值即可）
        let sorted = tiles.sorted()
        return WinResult(pair: sorted[0], melds: [], handType: .eightPairs)
    }

    // MARK: - Thirteen Orphans 十三么
    // 傳統 14 張版本：13 種孤張各一 + 其中一種重複
    // 在 16 張版遊戲中，玩家須在聽牌狀態（手牌 13 張）等到第 14 張

    private static let orphanTiles: [Tile] = [
        .man(1), .man(9), .pin(1), .pin(9), .sou(1), .sou(9),
        .east, .south, .west, .north, .chun, .hatsu, .haku
    ]

    private static func checkThirteenOrphans(_ tiles: [Tile]) -> WinResult? {
        guard tiles.count == 14 else { return nil }
        var counts: [Tile: Int] = [:]
        for t in tiles { counts[t, default: 0] += 1 }
        let hasAll = orphanTiles.allSatisfy { counts[$0, default: 0] >= 1 }
        guard hasAll else { return nil }
        let pairs = orphanTiles.filter { counts[$0, default: 0] == 2 }
        guard pairs.count == 1 else { return nil }
        return WinResult(pair: pairs[0], melds: [], handType: .thirteenOrphans)
    }

    // MARK: - Standard 標準型

    private static func checkStandard(_ tiles: [Tile], openMeldCount: Int = 0) -> WinResult? {
        // 立牌需湊滿 (5 - 已公開組數) 組面子 + 1 對雀頭
        let neededSets = 5 - openMeldCount
        guard neededSets >= 0, tiles.count == neededSets * 3 + 2 else { return nil }
        let sorted = tiles.sorted()
        let unique = Array(Set(sorted))
        for candidate in unique {
            let cnt = sorted.filter { $0 == candidate }.count
            guard cnt >= 2 else { continue }
            let remaining = removing(tile: candidate, count: 2, from: sorted)
            if let melds = decomposeMelds(remaining) {
                return WinResult(pair: candidate, melds: melds, handType: .standard)
            }
        }
        return nil
    }

    // MARK: - Recursive meld decomposition

    private static func decomposeMelds(_ tiles: [Tile]) -> [MeldType]? {
        if tiles.isEmpty { return [] }
        let first = tiles[0]

        // 嘗試刻子（優先）
        if tiles.filter({ $0 == first }).count >= 3 {
            let rest = removing(tile: first, count: 3, from: tiles)
            if let melds = decomposeMelds(rest) {
                return [.triplet(first)] + melds
            }
        }

        // 嘗試順子（限數牌）
        if first.isNumbered && first.value <= 7 {
            let second = Tile(first.suit, first.value + 1)
            let third  = Tile(first.suit, first.value + 2)
            if tiles.contains(second) && tiles.contains(third) {
                var rest = tiles
                rest.remove(at: rest.firstIndex(of: first)!)
                rest.remove(at: rest.firstIndex(of: second)!)
                rest.remove(at: rest.firstIndex(of: third)!)
                if let melds = decomposeMelds(rest) {
                    return [.sequence(first, second, third)] + melds
                }
            }
        }

        return nil
    }

    // MARK: - Helper

    private static func removing(tile: Tile, count: Int, from tiles: [Tile]) -> [Tile] {
        var result = tiles
        var removed = 0
        result = result.filter { t in
            if removed < count && t == tile { removed += 1; return false }
            return true
        }
        return result
    }
}
