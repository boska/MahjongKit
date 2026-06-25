public enum HandType: Sendable {
    case standard
    case eightPairs      // 八對
    case thirteenOrphans // 十三么
}

public struct WinResult: Sendable {
    public let pair: Tile
    public let melds: [MeldType]
    public let handType: HandType

    public init(pair: Tile, melds: [MeldType], handType: HandType) {
        self.pair = pair
        self.melds = melds
        self.handType = handType
    }
}

public struct WinContext: Sendable {
    public var isTsumo: Bool       // 自摸
    public var isClosedHand: Bool  // 門前清（沒吃碰槓過）
    public var isHeavenly: Bool    // 天胡（莊家起手）
    public var isEarthly: Bool     // 地胡（第一輪自摸）
    public var isHumanly: Bool     // 人胡（閒家首巡未摸牌前胡別人打的牌）
    public var seatWind: Int       // 自風 1=東…4=北
    public var roundWind: Int      // 場風
    public var flowers: [Tile]     // 本局補到的花牌
    public var openMelds: [MeldType] // 已公開吃碰槓
    public var winningTile: Tile?  // 胡的那張（判斷放槍時哪組刻子非暗刻）

    public init(
        isTsumo: Bool = false,
        isClosedHand: Bool = true,
        isHeavenly: Bool = false,
        isEarthly: Bool = false,
        isHumanly: Bool = false,
        seatWind: Int = 1,
        roundWind: Int = 1,
        flowers: [Tile] = [],
        openMelds: [MeldType] = [],
        winningTile: Tile? = nil
    ) {
        self.isTsumo = isTsumo
        self.isClosedHand = isClosedHand
        self.isHeavenly = isHeavenly
        self.isEarthly = isEarthly
        self.isHumanly = isHumanly
        self.seatWind = seatWind
        self.roundWind = roundWind
        self.flowers = flowers
        self.openMelds = openMelds
        self.winningTile = winningTile
    }
}
