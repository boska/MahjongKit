# MahjongKit

A pure Swift library implementing the core rules of **Taiwan 16-tile Mahjong** (台灣十六張麻將). No UIKit, no SpriteKit — just the game logic, suitable as a reference for porting to other platforms (web, Android, etc.).

## What's inside

| File | Purpose |
|------|---------|
| `Tile.swift` | Tile type: suit (萬/筒/條/風/箭/花) + value |
| `Meld.swift` | Meld types: 順子 / 刻子 / 槓子 / 對子 |
| `Wall.swift` | Tile wall: 136-tile shuffle, dead wall, supplement draws |
| `WinChecker.swift` | Win detection: standard hand, 八對 (eight pairs), 十三么 (thirteen orphans) |
| `WinResult.swift` | Win result: pair + melds + hand type |
| `ScoreCalculator.swift` | Scoring conditions (台數): 門清, 自摸, 清一色, 混一色, 字牌刻, 暗刻, 全求人, 海底 … |
| `ActionValidator.swift` | Validates pong (碰), chi (吃), kong (槓), win (胡) legality |

There is also a CLI demo in `Sources/MahjongGame/` that runs a full 4-player game in the terminal.

## Rules coverage

- **16-tile deal** per player + 8 flower tiles out of a 136-tile wall
- **Flower tiles** drawn immediately with a supplement tile
- **Chi (吃)** from left neighbour only
- **Pong (碰)** and **kong (槓)** from any discard
- **Self-draw kong (暗槓)** and **added kong (加槓)** on drawn tile
- **Win conditions**: standard (4 melds + 1 pair), eight pairs, thirteen orphans
- **Scoring**: MahjongKit scores conditions; Taiwan-specific adjustments (dealer bonus 2N+1, 清一色 8 台, etc.) live in the consuming app

## Usage (Swift Package)

```swift
// Package.swift
.package(url: "https://github.com/boska/MahjongKit", from: "1.0.0")
```

```swift
import MahjongKit

// Check if a hand can win on a discarded tile
let hand: [Tile] = [.man(1), .man(2), .man(3), /* … */]
if let result = WinChecker.canWin(hand: hand, drawn: .man(4), openMelds: []) {
    print(result.handType)  // .standard / .eightPairs / .thirteenOrphans
}

// Score it
let conditions = ScoreCalculator.score(result, seatWind: 1, roundWind: 1)
let tai = ScoreCalculator.totalTai(conditions)
```

## Running the CLI demo

```bash
swift run MahjongGame
```

Plays out a full 4-player game in the terminal with a simple AI.

## Running tests

```bash
swift test
```

## License

MIT
