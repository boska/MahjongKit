import MahjongKit

enum AIPlayer {

    // MARK: - 出牌：選出打哪張最划算

    static func bestDiscard(hand: [Tile]) -> Tile {
        hand.max { a, b in
            // 移除後分數較低 = 這張比較不重要 = 應該打這張
            effectiveScore(removing: a, from: hand) > effectiveScore(removing: b, from: hand)
        }!
    }

    // MARK: - 吃碰槓胡決策

    static func shouldWin(_ hand: [Tile], drawn: Tile, openMelds: [MeldType]) -> WinResult? {
        WinChecker.canWin(hand: hand, drawn: drawn, openMelds: openMelds)
    }

    static func shouldPong(hand: [Tile], discard: Tile) -> Bool {
        guard ActionValidator.canPong(hand: hand, discard: discard) else { return false }
        // 字牌永遠碰；數牌看分數是否提升
        if discard.isHonor { return true }
        let before = handScore(hand)
        var without = hand
        var removed = 0
        without = without.filter { t in
            guard removed < 2 && t == discard else { return true }
            removed += 1; return false
        }
        return handScore(without) + 3 >= before
    }

    static func shouldChow(hand: [Tile], discard: Tile) -> [Tile]? {
        let options = ActionValidator.canChow(hand: hand, discard: discard)
        guard !options.isEmpty else { return nil }
        // 選對手牌分數幫助最大的吃法
        return options.max { a, b in
            scoreAfterChow(hand: hand, using: a, discard: discard) <
            scoreAfterChow(hand: hand, using: b, discard: discard)
        }.flatMap { option in
            let before = handScore(hand)
            let after  = scoreAfterChow(hand: hand, using: option, discard: discard)
            return after >= before ? option : nil
        }
    }

    // MARK: - Score helpers

    static func handScore(_ tiles: [Tile]) -> Int {
        let sorted = tiles.sorted()
        var best = greedyMeldScore(sorted)
        for candidate in Set(sorted) {
            guard sorted.filter({ $0 == candidate }).count >= 2 else { continue }
            let rest = removing(candidate, count: 2, from: sorted)
            best = max(best, 2 + greedyMeldScore(rest))
        }
        return best
    }

    private static func effectiveScore(removing tile: Tile, from hand: [Tile]) -> Int {
        handScore(removing(tile, count: 1, from: hand))
    }

    private static func scoreAfterChow(hand: [Tile], using pair: [Tile], discard: Tile) -> Int {
        var result = hand
        for t in pair { if let i = result.firstIndex(of: t) { result.remove(at: i) } }
        return handScore(result)
    }

    // 貪心計算 melds + proto-melds 分數
    private static func greedyMeldScore(_ tiles: [Tile]) -> Int {
        var tiles = tiles
        var score = 0
        while !tiles.isEmpty {
            let first = tiles[0]
            // 刻子
            if tiles.filter({ $0 == first }).count >= 3 {
                score += 3
                tiles = removing(first, count: 3, from: tiles)
                continue
            }
            // 順子
            if first.isNumbered, first.value <= 7 {
                let b = Tile(first.suit, first.value + 1)
                let c = Tile(first.suit, first.value + 2)
                if tiles.contains(b) && tiles.contains(c) {
                    score += 3
                    for t in [first, b, c] { if let i = tiles.firstIndex(of: t) { tiles.remove(at: i) } }
                    continue
                }
            }
            // 搭子（兩張相連）
            if first.isNumbered, first.value <= 8 {
                let next = Tile(first.suit, first.value + 1)
                if tiles.contains(next) {
                    score += 1
                    if let i = tiles.firstIndex(of: first) { tiles.remove(at: i) }
                    if let i = tiles.firstIndex(of: next)  { tiles.remove(at: i) }
                    continue
                }
            }
            // 對子
            if tiles.filter({ $0 == first }).count >= 2 {
                score += 1
                tiles = removing(first, count: 2, from: tiles)
                continue
            }
            tiles.removeFirst()
        }
        return score
    }

    private static func removing(_ tile: Tile, count: Int, from tiles: [Tile]) -> [Tile] {
        var result = tiles
        var removed = 0
        result = result.filter { t in
            guard removed < count && t == tile else { return true }
            removed += 1; return false
        }
        return result
    }
}
