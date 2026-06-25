import MahjongKit
import Foundation

// MARK: - Player state

struct PlayerState {
    var hand: [Tile]
    var flowers: [Tile] = []
    var openMelds: [MeldType] = []
    var discards: [Tile] = []
    let isHuman: Bool
    let seatWind: Int
    let name: String
}

// MARK: - Game engine

final class GameEngine {

    var wall: Wall
    var players: [PlayerState]
    var currentPlayer: Int = 0
    let roundWind: Int = 1
    var drawnTile: Tile? = nil
    var gameOver = false

    init() {
        wall = Wall()
        let hands = wall.deal()
        players = [
            PlayerState(hand: Array(hands[0].dropLast()), isHuman: true,  seatWind: 1, name: "你[東]"),
            PlayerState(hand: hands[1], isHuman: false, seatWind: 2, name: "南AI"),
            PlayerState(hand: hands[2], isHuman: false, seatWind: 3, name: "西AI"),
            PlayerState(hand: hands[3], isHuman: false, seatWind: 4, name: "北AI"),
        ]
        // 莊家（你）的第 17 張算作第一次摸牌
        drawnTile = hands[0].last

        // 發牌後：分離花牌並補摸替換牌
        for i in 0..<4 {
            separateFlowers(for: i)
            var needed = players[i].flowers.count
            while needed > 0 {
                guard let t = wall.draw() else { break }
                if t.isFlower { players[i].flowers.append(t) }
                else { players[i].hand.append(t); needed -= 1 }
            }
        }
    }

    // MARK: - Main loop

    func run() {
        // 莊家先出牌（不用再摸）
        CLIRenderer.renderBoard(self)
        humanDiscard()
        if !gameOver { nextTurn() }

        while !gameOver {
            if wall.remaining == 0 {
                print("\n=== 流局 — 牌山摸完 ===")
                break
            }
            playTurn()
            if !gameOver { nextTurn() }
        }
    }

    // MARK: - Turn flow

    private func playTurn() {
        let p = players[currentPlayer]

        if p.isHuman {
            guard let drawn = drawTile(for: currentPlayer) else { return }
            drawnTile = drawn
            CLIRenderer.renderBoard(self)
            humanAction()
        } else {
            guard let drawn = drawTile(for: currentPlayer) else { return }
            aiAction(player: currentPlayer, drawn: drawn)
        }
    }

    // MARK: - Human actions

    private func humanAction() {
        let p = players[currentPlayer]
        guard let drawn = drawnTile else { return }

        var actions = ["輸入牌名打牌 (如 1m 5p 9s 1z 1d)"]

        // 能胡
        if WinChecker.canWin(hand: p.hand, drawn: drawn, openMelds: p.openMelds) != nil {
            actions.insert("W = 自摸胡", at: 0)
        }
        // 能暗槓
        let kongCandidates = ActionValidator.canClosedKong(hand: p.hand + [drawn])
        if !kongCandidates.isEmpty {
            actions.insert("K \(kongCandidates.map { CLIRenderer.name($0) }.joined(separator:"/")) = 暗槓", at: 0)
        }

        print("動作: \(actions.joined(separator: "  |  "))")

        while true {
            let input = CLIRenderer.prompt(">").trimmingCharacters(in: .whitespaces)
            let upper = input.uppercased()

            if upper == "W" {
                if let result = WinChecker.canWin(hand: p.hand, drawn: drawn, openMelds: p.openMelds) {
                    let ctx = WinContext(isTsumo: true, isClosedHand: p.openMelds.isEmpty, seatWind: p.seatWind, roundWind: roundWind, flowers: p.flowers)
                    let conds = ScoreCalculator.calculate(result: result, context: ctx)
                    players[currentPlayer].hand.append(drawn)
                    drawnTile = nil
                    CLIRenderer.renderWin(player: players[currentPlayer], result: result, conditions: conds, total: ScoreCalculator.totalTai(conds))
                    gameOver = true
                }
                return
            }

            if upper.hasPrefix("K"), let tile = kongCandidates.first {
                performClosedKong(tile: tile)
                return
            }

            if let tile = CLIRenderer.parseTile(input) {
                let allTiles = p.hand + [drawn]
                if allTiles.contains(tile) {
                    discard(tile: tile, drawnTile: drawn)
                    return
                }
                print("手牌中沒有 \(CLIRenderer.name(tile))，請重新輸入。")
            } else {
                print("無法識別，請輸入如 1m、5p、1z 格式的牌名。")
            }
        }
    }

    private func humanDiscard() {
        let p = players[0]
        guard let drawn = drawnTile else { return }

        var actions = ["輸入牌名打牌 (如 1m 5p 9s 1z 1d)"]
        if WinChecker.canWin(hand: p.hand, drawn: drawn, openMelds: p.openMelds) != nil {
            actions.insert("W = 天胡", at: 0)
        }
        print("動作: \(actions.joined(separator: "  |  "))")

        while true {
            let input = CLIRenderer.prompt(">").trimmingCharacters(in: .whitespaces)
            if input.uppercased() == "W" {
                if let result = WinChecker.canWin(hand: p.hand, drawn: drawn, openMelds: p.openMelds) {
                    let ctx = WinContext(isTsumo: true, isClosedHand: true, isHeavenly: true, seatWind: p.seatWind, roundWind: roundWind, flowers: p.flowers)
                    let conds = ScoreCalculator.calculate(result: result, context: ctx)
                    players[0].hand.append(drawn)
                    drawnTile = nil
                    CLIRenderer.renderWin(player: players[0], result: result, conditions: conds, total: ScoreCalculator.totalTai(conds))
                    gameOver = true
                }
                return
            }
            if let tile = CLIRenderer.parseTile(input) {
                let allTiles = p.hand + [drawn]
                if allTiles.contains(tile) {
                    discard(tile: tile, drawnTile: drawn)
                    return
                }
                print("手牌中沒有 \(CLIRenderer.name(tile))，請重新輸入。")
            } else {
                print("無法識別，請輸入如 1m、5p、1z 格式的牌名。")
            }
        }
    }

    // MARK: - AI actions

    private func aiAction(player i: Int, drawn: Tile) {
        let p = players[i]
        // 自摸胡
        if let result = AIPlayer.shouldWin(p.hand, drawn: drawn, openMelds: p.openMelds) {
            players[i].hand.append(drawn)
            let ctx = WinContext(isTsumo: true, isClosedHand: p.openMelds.isEmpty, seatWind: p.seatWind, roundWind: roundWind, flowers: p.flowers)
            let conds = ScoreCalculator.calculate(result: result, context: ctx)
            print("\n\(p.name) 自摸！")
            CLIRenderer.renderWin(player: players[i], result: result, conditions: conds, total: ScoreCalculator.totalTai(conds))
            gameOver = true
            return
        }
        // 暗槓
        let kongs = ActionValidator.canClosedKong(hand: p.hand + [drawn])
        if !kongs.isEmpty {
            let tile = kongs[0]
            print("\(p.name) 暗槓 \(CLIRenderer.name(tile))")
            players[i].hand = (p.hand + [drawn]).filter { t in
                var found = false
                if t == tile && !found { found = true; return false }
                return true
            }
            // Actually remove 4 of tile
            var count = 0
            var newHand = p.hand + [drawn]
            newHand = newHand.filter { t in
                if t == tile && count < 4 { count += 1; return false }
                return true
            }
            players[i].hand = newHand
            players[i].openMelds.append(.kong(tile, isOpen: false))
            if let extra = drawTile(for: i) {
                aiAction(player: i, drawn: extra)
            }
            return
        }
        // 出牌
        var allTiles = p.hand + [drawn]
        let best = AIPlayer.bestDiscard(hand: allTiles)
        if let idx = allTiles.firstIndex(of: best) { allTiles.remove(at: idx) }
        players[i].hand = allTiles
        players[i].discards.append(best)
        print("\(p.name) 打出: \(CLIRenderer.box(best))")
        handleReactions(discard: best, from: i)
    }

    // MARK: - Discard

    private func discard(tile: Tile, drawnTile drawn: Tile) {
        var allTiles = players[currentPlayer].hand + [drawn]
        if let idx = allTiles.firstIndex(of: tile) { allTiles.remove(at: idx) }
        players[currentPlayer].hand = allTiles
        players[currentPlayer].discards.append(tile)
        drawnTile = nil
        print("\n你打出: \(CLIRenderer.box(tile))")
        handleReactions(discard: tile, from: currentPlayer)
    }

    // MARK: - Reactions after discard

    private func handleReactions(discard: Tile, from discarder: Int) {
        guard !gameOver else { return }

        // 1. 胡 (任何人)
        for offset in 1...3 {
            let i = (discarder + offset) % 4
            let p = players[i]
            guard let result = WinChecker.canWin(hand: p.hand, drawn: discard, openMelds: p.openMelds) else { continue }

            if p.isHuman {
                print("你可以胡！")
                let choice = CLIRenderer.prompt("要胡嗎？(W=胡 / Enter=跳過)").uppercased()
                if choice == "W" {
                    players[i].hand.append(discard)
                    let ctx = WinContext(isTsumo: false, isClosedHand: p.openMelds.isEmpty, seatWind: p.seatWind, roundWind: roundWind, flowers: p.flowers)
                    let conds = ScoreCalculator.calculate(result: result, context: ctx)
                    CLIRenderer.renderWin(player: players[i], result: result, conditions: conds, total: ScoreCalculator.totalTai(conds))
                    gameOver = true
                    return
                }
            } else {
                players[i].hand.append(discard)
                let ctx = WinContext(isTsumo: false, isClosedHand: p.openMelds.isEmpty, seatWind: p.seatWind, roundWind: roundWind, flowers: p.flowers)
                let conds = ScoreCalculator.calculate(result: result, context: ctx)
                print("\n\(p.name) 胡了！")
                CLIRenderer.renderWin(player: players[i], result: result, conditions: conds, total: ScoreCalculator.totalTai(conds))
                gameOver = true
                return
            }
        }

        // 2. 碰/明槓 (任何人，優先順序從下家起)
        for offset in 1...3 {
            let i = (discarder + offset) % 4
            let p = players[i]

            if ActionValidator.canOpenKong(hand: p.hand, discard: discard) {
                let should = p.isHuman ? askHuman(i, action: "明槓 \(CLIRenderer.name(discard))", key: "K") : true
                if should {
                    var count = 0
                    players[i].hand = p.hand.filter { t in
                        if t == discard && count < 3 { count += 1; return false }
                        return true
                    }
                    players[i].openMelds.append(.kong(discard, isOpen: true))
                    print("\(p.name) 明槓 \(CLIRenderer.box(discard))")
                    if let extra = drawTile(for: i) {
                        if p.isHuman {
                            drawnTile = extra
                            CLIRenderer.renderBoard(self)
                            humanAction()
                        } else {
                            aiAction(player: i, drawn: extra)
                        }
                    }
                    currentPlayer = i
                    return
                }
            }

            if ActionValidator.canPong(hand: p.hand, discard: discard) {
                let should = p.isHuman
                    ? askHuman(i, action: "碰 \(CLIRenderer.name(discard))", key: "P")
                    : AIPlayer.shouldPong(hand: p.hand, discard: discard)
                if should {
                    var count = 0
                    players[i].hand = p.hand.filter { t in
                        if t == discard && count < 2 { count += 1; return false }
                        return true
                    }
                    players[i].openMelds.append(.triplet(discard))
                    print("\(p.name) 碰 \(CLIRenderer.box(discard))")
                    currentPlayer = i
                    if p.isHuman {
                        drawnTile = nil
                        CLIRenderer.renderBoard(self)
                        // Human needs to discard (no new draw after pong)
                        humanPostPong()
                    } else {
                        let best = AIPlayer.bestDiscard(hand: players[i].hand)
                        if let idx = players[i].hand.firstIndex(of: best) { players[i].hand.remove(at: idx) }
                        players[i].discards.append(best)
                        print("\(p.name) 打出: \(CLIRenderer.box(best))")
                        handleReactions(discard: best, from: i)
                    }
                    return
                }
            }
        }

        // 3. 吃 (只有下家)
        let next = (discarder + 1) % 4
        let np = players[next]
        let chowOptions = ActionValidator.canChow(hand: np.hand, discard: discard)
        if !chowOptions.isEmpty {
            var chosenTiles: [Tile]? = nil
            if np.isHuman {
                let optStr = chowOptions.map { $0.map { CLIRenderer.name($0) }.joined(separator:"+") }.joined(separator: " 或 ")
                print("你可以吃！可選: \(optStr)")
                let choice = CLIRenderer.prompt("(C=吃 / Enter=跳過)").uppercased()
                if choice == "C" { chosenTiles = chowOptions[0] }
            } else {
                chosenTiles = AIPlayer.shouldChow(hand: np.hand, discard: discard)
            }
            if let tiles = chosenTiles {
                var hand = players[next].hand
                for t in tiles { if let idx = hand.firstIndex(of: t) { hand.remove(at: idx) } }
                players[next].hand = hand
                let sorted = ([tiles[0], tiles[1], discard]).sorted()
                players[next].openMelds.append(.sequence(sorted[0], sorted[1], sorted[2]))
                print("\(np.name) 吃 \(CLIRenderer.box(discard))")
                currentPlayer = next
                if np.isHuman {
                    drawnTile = nil
                    CLIRenderer.renderBoard(self)
                    humanPostPong()
                } else {
                    let best = AIPlayer.bestDiscard(hand: players[next].hand)
                    if let idx = players[next].hand.firstIndex(of: best) { players[next].hand.remove(at: idx) }
                    players[next].discards.append(best)
                    print("\(np.name) 打出: \(CLIRenderer.box(best))")
                    handleReactions(discard: best, from: next)
                }
                return
            }
        }
    }

    // 碰/吃後人類打牌（沒有摸牌）
    private func humanPostPong() {
        let p = players[currentPlayer]
        print("動作: 輸入牌名打牌")
        while true {
            let input = CLIRenderer.prompt(">").trimmingCharacters(in: .whitespaces)
            if let tile = CLIRenderer.parseTile(input), p.hand.contains(tile) {
                var hand = players[currentPlayer].hand
                if let idx = hand.firstIndex(of: tile) { hand.remove(at: idx) }
                players[currentPlayer].hand = hand
                players[currentPlayer].discards.append(tile)
                print("你打出: \(CLIRenderer.box(tile))")
                handleReactions(discard: tile, from: currentPlayer)
                return
            }
            print("無效輸入，請重試。")
        }
    }

    // MARK: - Closed kong

    private func performClosedKong(tile: Tile) {
        guard let drawn = drawnTile else { return }
        var all = players[currentPlayer].hand + [drawn]
        var count = 0
        all = all.filter { t in
            if t == tile && count < 4 { count += 1; return false }
            return true
        }
        players[currentPlayer].hand = all
        players[currentPlayer].openMelds.append(.kong(tile, isOpen: false))
        drawnTile = nil
        print("你暗槓 \(CLIRenderer.box(tile))")
        if let extra = drawTile(for: currentPlayer) {
            drawnTile = extra
            CLIRenderer.renderBoard(self)
            humanAction()
        }
    }

    // MARK: - Helpers

    private func askHuman(_ player: Int, action: String, key: String) -> Bool {
        let choice = CLIRenderer.prompt("你可以\(action)！(\(key)=確認 / Enter=跳過)").uppercased()
        return choice == key
    }

    /// 摸牌，自動處理花牌（補摸）
    private func drawTile(for i: Int) -> Tile? {
        while let t = wall.draw() {
            if t.isFlower {
                players[i].flowers.append(t)
            } else {
                return t
            }
        }
        return nil
    }

    /// 從初始手牌中分離花牌（不補摸，遊戲開始時用）
    private func separateFlowers(for i: Int) {
        let flowers = players[i].hand.filter { $0.isFlower }
        players[i].hand = players[i].hand.filter { !$0.isFlower }
        players[i].flowers = flowers
    }

    private func nextTurn() {
        currentPlayer = (currentPlayer + 1) % 4
    }
}
