public enum Suit: Int, Hashable, Comparable, CaseIterable, Sendable {
    case man = 0   // 萬子 1–9
    case pin = 1   // 筒子 1–9
    case sou = 2   // 條子 1–9
    case wind = 3  // 風牌: 1=東 2=南 3=西 4=北
    case dragon = 4 // 箭牌: 1=中 2=發 3=白
    case flower = 5 // 花牌: 1–4=春夏秋冬 5–8=梅蘭菊竹

    public static func < (lhs: Suit, rhs: Suit) -> Bool { lhs.rawValue < rhs.rawValue }

    var isNumbered: Bool { self == .man || self == .pin || self == .sou }
}

public struct Tile: Hashable, Comparable, CustomStringConvertible, Sendable {
    public let suit: Suit
    public let value: Int

    public init(_ suit: Suit, _ value: Int) {
        self.suit = suit
        self.value = value
    }

    public var isHonor: Bool    { suit == .wind || suit == .dragon }
    public var isFlower: Bool   { suit == .flower }
    public var isTerminal: Bool { suit.isNumbered && (value == 1 || value == 9) }
    public var isOrphan: Bool   { isTerminal || isHonor }
    public var isNumbered: Bool { suit.isNumbered }

    public static func < (lhs: Tile, rhs: Tile) -> Bool {
        if lhs.suit != rhs.suit { return lhs.suit < rhs.suit }
        return lhs.value < rhs.value
    }

    public var description: String {
        let suitNames = ["m", "p", "s", "z", "d", "f"]
        return "\(value)\(suitNames[suit.rawValue])"
    }
}

// MARK: - Tile factories

public extension Tile {
    static func man(_ v: Int) -> Tile   { Tile(.man, v) }
    static func pin(_ v: Int) -> Tile   { Tile(.pin, v) }
    static func sou(_ v: Int) -> Tile   { Tile(.sou, v) }
    static func wind(_ v: Int) -> Tile  { Tile(.wind, v) }   // 1=東…4=北
    static func dragon(_ v: Int) -> Tile { Tile(.dragon, v) } // 1=中 2=發 3=白
    static func flower(_ v: Int) -> Tile { Tile(.flower, v) }

    static let east   = wind(1)
    static let south  = wind(2)
    static let west   = wind(3)
    static let north  = wind(4)
    static let chun   = dragon(1) // 中
    static let hatsu  = dragon(2) // 發
    static let haku   = dragon(3) // 白
}
