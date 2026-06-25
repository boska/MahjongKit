import MahjongKit
import Foundation

enum CLIRenderer {

    // MARK: - Tile display

    static func name(_ tile: Tile) -> String {
        switch tile.suit {
        case .man:    return "\(tile.value)萬"
        case .pin:    return "\(tile.value)筒"
        case .sou:    return "\(tile.value)條"
        case .wind:   return ["東","南","西","北"][tile.value - 1]
        case .dragon: return ["中","發","白"][tile.value - 1]
        case .flower: return ["春","夏","秋","冬","梅","蘭","菊","竹"][tile.value - 1]
        }
    }

    static func box(_ tile: Tile) -> String { "[\(name(tile))]" }

    static func hidden(_ count: Int) -> String { String(repeating: "[??]", count: count) }

    static func hand(_ tiles: [Tile], drawn: Tile? = nil) -> String {
        let sorted = tiles.sorted().map { box($0) }.joined()
        if let d = drawn { return sorted + "  摸:\(box(d))" }
        return sorted
    }

    static func melds(_ ms: [MeldType]) -> String {
        ms.map { m in
            switch m {
            case .sequence(let a, let b, let c): return "(\(name(a))\(name(b))\(name(c)))"
            case .triplet(let t):                return "(\(name(t))×3)"
            case .kong(let t, let open):         return open ? "[\(name(t))×4]" : "{\(name(t))×4}"
            }
        }.joined(separator: " ")
    }

    // MARK: - Board

    static func renderBoard(_ engine: GameEngine) {
        let hr = String(repeating: "─", count: 60)
        print("\n\(hr)")
        print("  台灣麻將 ｜ 東一局 ｜ 剩餘牌: \(engine.wall.remaining)")
        print(hr)

        for i in [3, 2, 1] {
            let p = engine.players[i]
            let meldStr = p.openMelds.isEmpty ? "" : "  \(melds(p.openMelds))"
            print("\(p.name)  \(hidden(p.hand.count))\(meldStr)")
            if !p.flowers.isEmpty {
                print("  花: \(p.flowers.map { name($0) }.joined(separator:" "))")
            }
            if !p.discards.isEmpty {
                let discardStr = p.discards.suffix(12).map { name($0) }.joined(separator:" ")
                print("  棄: \(discardStr)")
            }
        }

        print(hr)
        let h = engine.players[0]
        let flowerStr = h.flowers.isEmpty ? "" : "  花: \(h.flowers.map { name($0) }.joined(separator:" "))"
        let meldStr   = h.openMelds.isEmpty ? "" : "  \(melds(h.openMelds))"
        print("--- \(h.name)\(flowerStr)\(meldStr) ---")
        print(hand(h.hand, drawn: engine.drawnTile))
        print(hr)
    }

    // MARK: - Win result

    static func renderWin(player: PlayerState, result: WinResult, conditions: [ScoringCondition], total: Int) {
        let hr = String(repeating: "═", count: 50)
        print("\n\(hr)")
        print("  胡牌！\(player.name)")
        print(hr)
        print("手牌: \(hand(player.hand))")
        if !player.openMelds.isEmpty { print("副露: \(melds(player.openMelds))") }
        if !player.flowers.isEmpty   { print("花牌: \(player.flowers.map { name($0) }.joined(separator:" "))") }
        print(String(repeating: "─", count: 35))
        for c in conditions {
            print("  \(c.description.padding(toLength: 14, withPad: " ", startingAt: 0))  +\(c.taiValue)台")
        }
        print(String(repeating: "─", count: 35))
        print("  合計：\(total) 台")
        print(hr)
    }

    // MARK: - Input

    @discardableResult
    static func prompt(_ msg: String) -> String {
        print(msg, terminator: " ")
        fflush(stdout)
        return readLine() ?? ""
    }

    /// Parse "1m" "5p" "9s" "1z"(東)…"4z"(北) "1d"(中) "2d"(發) "3d"(白)
    static func parseTile(_ input: String) -> Tile? {
        let s = input.lowercased().trimmingCharacters(in: .whitespaces)
        guard s.count >= 2, let suitChar = s.last, let value = Int(s.dropLast()) else { return nil }
        switch suitChar {
        case "m": return (1...9).contains(value) ? Tile(.man, value) : nil
        case "p": return (1...9).contains(value) ? Tile(.pin, value) : nil
        case "s": return (1...9).contains(value) ? Tile(.sou, value) : nil
        case "z": return (1...4).contains(value) ? Tile(.wind, value) : nil
        case "d": return (1...3).contains(value) ? Tile(.dragon, value) : nil
        default:  return nil
        }
    }
}

private extension String {
    func padding(toLength length: Int, withPad pad: String, startingAt: Int) -> String {
        if self.count >= length { return self }
        return self + String(repeating: pad, count: length - self.count)
    }
}
