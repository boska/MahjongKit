public struct ActionValidator {

    // MARK: - 吃 Chow（只能吃上家的牌，數牌限定）

    /// 回傳所有合法的吃法（每個元素是手牌中用來配對的兩張）
    public static func canChow(hand: [Tile], discard: Tile) -> [[Tile]] {
        guard discard.isNumbered else { return [] }
        var options: [[Tile]] = []
        let v = discard.value
        let s = discard.suit

        // 三種順子形態：[v-2,v-1]+v, [v-1,v+1]+v, [v]+[v+1,v+2]
        let combinations: [(Int, Int)] = [(v-2, v-1), (v-1, v+1), (v+1, v+2)]
        for (a, b) in combinations {
            guard a >= 1, b >= 1, a <= 9, b <= 9 else { continue }
            let tileA = Tile(s, a)
            let tileB = Tile(s, b)
            var tempHand = hand
            if let i = tempHand.firstIndex(of: tileA) {
                tempHand.remove(at: i)
                if let j = tempHand.firstIndex(of: tileB) {
                    tempHand.remove(at: j)
                    options.append([tileA, tileB])
                }
            }
        }
        return options
    }

    // MARK: - 碰 Pong

    public static func canPong(hand: [Tile], discard: Tile) -> Bool {
        hand.filter { $0 == discard }.count >= 2
    }

    // MARK: - 明槓 Open Kong（拿別人打的牌，手牌需有 3 張）

    public static func canOpenKong(hand: [Tile], discard: Tile) -> Bool {
        hand.filter { $0 == discard }.count >= 3
    }

    // MARK: - 暗槓 Closed Kong（手牌自己有 4 張）

    /// 回傳所有可暗槓的牌
    public static func canClosedKong(hand: [Tile]) -> [Tile] {
        var counts: [Tile: Int] = [:]
        for t in hand { counts[t, default: 0] += 1 }
        return counts.compactMap { $0.value == 4 ? $0.key : nil }
    }

    // MARK: - 加槓 Added Kong（把手牌中的牌接在已碰的刻子上）

    /// pongTiles: 已碰的刻子代表牌（各一張）
    public static func canAddKong(hand: [Tile], pongBaseTiles: [Tile]) -> [Tile] {
        pongBaseTiles.filter { hand.contains($0) }
    }

    // MARK: - 胡 Win（放炮）

    public static func canWin(hand: [Tile], discard: Tile, openMelds: [MeldType] = []) -> WinResult? {
        WinChecker.canWin(hand: hand, drawn: discard, openMelds: openMelds)
    }
}
