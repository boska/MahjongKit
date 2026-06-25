import Foundation

public struct Wall {

    private var tiles: [Tile]
    public private(set) var deadWall: [Tile] = []

    public var remaining: Int { tiles.count }
    public var isEmpty: Bool  { tiles.isEmpty }

    // MARK: - Init

    /// 接受任何符合 Swift.RandomNumberGenerator 的 RNG（測試可傳 SeededRNG）
    public init<RNG: Swift.RandomNumberGenerator>(rng: inout RNG) {
        // Fisher-Yates 由 Swift 標準函式庫實作
        var deck = Wall.fullDeck()
        deck.shuffle(using: &rng)
        // 嶺上牌：最後 14 張（供槓後補牌）
        deadWall = Array(deck.suffix(14))
        tiles = Array(deck.prefix(deck.count - 14))
    }

    /// 使用 SecRandomCopyBytes 作為 OS 提供的高品質亂數源
    public init() {
        var rng = CryptoRNG()
        self.init(rng: &rng)
    }

    // MARK: - Dead zone

    /// Last 16 live tiles are untouchable (海底). Game ends when this many remain.
    public static let deadZone = 16

    /// True when only the untouchable reserve remains — game should end.
    public var isExhausted: Bool { tiles.count <= Self.deadZone }

    /// The 16 tiles held in reserve — never drawn; exposed for tile-accounting tests.
    public var deadZoneTiles: [Tile] { Array(tiles.suffix(Self.deadZone)) }

    // MARK: - Draw

    /// Draw from the front of the live wall. Returns nil once the dead zone is reached.
    public mutating func draw() -> Tile? {
        guard !isExhausted else { return nil }
        return tiles.removeFirst()
    }

    /// Draw from the tail of the live wall for flower replacements (補花).
    /// Takes the tile just before the dead zone, moving the dead zone boundary
    /// forward by one with each call. Returns nil once the dead zone is reached.
    public mutating func drawFromTail() -> Tile? {
        guard !isExhausted else { return nil }
        return tiles.remove(at: tiles.count - Self.deadZone - 1)
    }

    /// 嶺上摸牌（槓後補牌）
    public mutating func drawFromDeadWall() -> Tile? {
        guard !deadWall.isEmpty else { return nil }
        return deadWall.removeFirst()
    }

    // MARK: - Deal

    /// 發牌：4 人各 16 張，莊家（index 0）多 1 張（共 65 張）
    public mutating func deal() -> [[Tile]] {
        var hands: [[Tile]] = [[], [], [], []]
        for i in 0..<64 {
            guard let t = draw() else { break }
            hands[i % 4].append(t)
        }
        if let extra = draw() { hands[0].append(extra) }
        return hands
    }

    // MARK: - Full Deck

    /// 生成完整 144 張（有序）
    public static func fullDeck() -> [Tile] {
        var deck: [Tile] = []
        for suit in [Suit.man, .pin, .sou] {
            for value in 1...9 {
                for _ in 0..<4 { deck.append(Tile(suit, value)) }
            }
        }
        for value in 1...4 { for _ in 0..<4 { deck.append(Tile(.wind, value)) } }
        for value in 1...3 { for _ in 0..<4 { deck.append(Tile(.dragon, value)) } }
        for value in 1...8 { deck.append(Tile(.flower, value)) }
        // 36×3 + 16 + 12 + 8 = 144
        return deck
    }
}

// MARK: - Crypto RNG

/// SecRandomCopyBytes 包裝，提供高品質亂數給 Fisher-Yates shuffle
public struct CryptoRNG: Swift.RandomNumberGenerator {
    public init() {}
    public mutating func next() -> UInt64 {
        var value: UInt64 = 0
        withUnsafeMutableBytes(of: &value) {
            _ = SecRandomCopyBytes(kSecRandomDefault, 8, $0.baseAddress!)
        }
        return value
    }
}

// MARK: - Seeded RNG（for tests）

/// 線性同餘法亂數（可重現，供測試用）
public struct SeededRNG: Swift.RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64) { state = seed }

    public mutating func next() -> UInt64 {
        // Knuth LCG constants
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
