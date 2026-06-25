public enum ScoringCondition: Hashable, Sendable, CustomStringConvertible {
    case tsumo              // 自摸 1台
    case menzhan            // 門前清 1台
    case pinhu              // 平胡 1台
    case toitoi             // 碰碰胡 4台
    case halfFlush          // 混一色 3台
    case fullFlush          // 清一色 5台
    case eightPairs         // 八對 4台
    case smallThreeDragons  // 小三元 4台
    case bigThreeDragons    // 大三元 8台
    case smallFourWinds     // 小四喜 5台
    case bigFourWinds       // 大四喜 8台
    case allHonors          // 字一色 8台
    case allTerminals       // 清老頭 8台
    case thirteenOrphans    // 十三么 13台
    case heavenly           // 天胡 16台
    case earthly            // 地胡 16台
    case humanly            // 人胡 8台（閒家首巡未摸牌前胡別人打的牌）
    case flower(Tile)       // 每張花 1台
    case ownFlower(Tile)    // 門前花 +1台（自己位置花）

    // Taiwan additions on top of MahjongKit's base set
    case menzhanTsumo       // 門清自摸（獎勵）1台 → 門清一摸三
    case roundWindPung      // 圈風刻 1台
    case seatWindPung       // 門風刻 1台
    case dragonPung         // 箭刻（中/發/白）1台
    case threeConcealed     // 三暗刻 2台
    case fiveConcealed      // 五暗刻 8台
    case allFromOthers      // 全求人 2台
    case haitei             // 海底撈月 1台
    case kongBloom          // 槓上開花 1台

    public var taiValue: Int {
        switch self {
        case .tsumo, .menzhan, .pinhu:      return 1
        case .toitoi:                        return 4
        case .halfFlush:                     return 3
        case .fullFlush:                     return 5
        case .eightPairs:                    return 4
        case .smallThreeDragons:             return 4
        case .bigThreeDragons:               return 8
        case .smallFourWinds:                return 5
        case .bigFourWinds:                  return 8
        case .allHonors:                     return 8
        case .allTerminals:                  return 8
        case .thirteenOrphans:               return 13
        case .heavenly, .earthly:            return 16
        case .humanly:                       return 8
        case .flower:                        return 1
        case .ownFlower:                     return 1
        case .menzhanTsumo:                  return 1
        case .roundWindPung:                 return 1
        case .seatWindPung:                  return 1
        case .dragonPung:                    return 1
        case .threeConcealed:                return 2
        case .fiveConcealed:                 return 8
        case .allFromOthers:                 return 2
        case .haitei:                        return 1
        case .kongBloom:                     return 1
        }
    }

    public var description: String {
        switch self {
        case .tsumo:             return "自摸"
        case .menzhan:           return "門前清"
        case .pinhu:             return "平胡"
        case .toitoi:            return "碰碰胡"
        case .halfFlush:         return "混一色"
        case .fullFlush:         return "清一色"
        case .eightPairs:        return "八對"
        case .smallThreeDragons: return "小三元"
        case .bigThreeDragons:   return "大三元"
        case .smallFourWinds:    return "小四喜"
        case .bigFourWinds:      return "大四喜"
        case .allHonors:         return "字一色"
        case .allTerminals:      return "清老頭"
        case .thirteenOrphans:   return "十三么"
        case .heavenly:          return "天胡"
        case .earthly:           return "地胡"
        case .humanly:           return "人胡"
        case .flower(let t):     return "花(\(t))"
        case .ownFlower(let t):  return "門前花(\(t))"
        case .menzhanTsumo:      return "門清自摸"
        case .roundWindPung:     return "圈風"
        case .seatWindPung:      return "門風"
        case .dragonPung:        return "箭刻"
        case .threeConcealed:    return "三暗刻"
        case .fiveConcealed:     return "五暗刻"
        case .allFromOthers:     return "全求人"
        case .haitei:            return "海底撈月"
        case .kongBloom:         return "槓上開花"
        }
    }
}

public struct ScoreCalculator {

    public static func calculate(result: WinResult, context: WinContext) -> [ScoringCondition] {
        var conds: [ScoringCondition] = []

        // 天胡/地胡/人胡 排他（直接回傳）
        if context.isHeavenly { return [.heavenly] + flowerConditions(context.flowers, seatWind: context.seatWind) }
        if context.isEarthly  { return [.earthly]  + flowerConditions(context.flowers, seatWind: context.seatWind) }
        if context.isHumanly  { return [.humanly]  + flowerConditions(context.flowers, seatWind: context.seatWind) }

        switch result.handType {
        case .eightPairs:
            conds.append(.eightPairs)
        case .thirteenOrphans:
            conds.append(.thirteenOrphans)
        case .standard:
            if context.isTsumo { conds.append(.tsumo) }
            // 門清 applies on any closed win; a closed self-draw also earns the
            // 門清自摸 bonus → 門清(1)+自摸(1)+門清自摸(1) = 門清一摸三 (3台).
            if context.isClosedHand {
                conds.append(.menzhan)
                if context.isTsumo { conds.append(.menzhanTsumo) }
            }

            let allMelds = result.melds + context.openMelds
            if isPinhu(result: result, allMelds: allMelds) { conds.append(.pinhu) }
            if isToitoi(allMelds: allMelds)                { conds.append(.toitoi) }

            let suitCond = flushCondition(pair: result.pair, allMelds: allMelds)
            if let c = suitCond { conds.append(c) }

            let dragon = dragonCondition(pair: result.pair, allMelds: allMelds)
            if let c = dragon { conds.append(c) }
            let wind = windCondition(pair: result.pair, allMelds: allMelds)
            if let c = wind { conds.append(c) }

            // Single honour triplets (圈風/門風/箭刻) — 1台 each, but suppressed when
            // already subsumed by a 三元/四喜 grouping to avoid double-counting.
            conds += honorPungConditions(
                allMelds: allMelds,
                roundWind: context.roundWind, seatWind: context.seatWind,
                dragonGrouped: dragon != nil, windGrouped: wind != nil)

            if isAllTerminals(pair: result.pair, allMelds: allMelds) { conds.append(.allTerminals) }
            if isAllHonors(pair: result.pair, allMelds: allMelds)    { conds.append(.allHonors) }

            // 三暗刻 / 五暗刻
            if let c = concealedTripletCondition(result: result, context: context) { conds.append(c) }

            // 全求人：五組全部吃碰光，單吊胡別人打的牌（非自摸）
            if !context.isTsumo && context.openMelds.count == 5 { conds.append(.allFromOthers) }
        }

        conds += flowerConditions(context.flowers, seatWind: context.seatWind)
        return conds
    }

    public static func totalTai(_ conditions: [ScoringCondition]) -> Int {
        conditions.reduce(0) { $0 + $1.taiValue }
    }

    // MARK: - Condition checks

    private static func isPinhu(result: WinResult, allMelds: [MeldType]) -> Bool {
        guard result.handType == .standard else { return false }
        return allMelds.allSatisfy {
            if case .sequence = $0 { return true }
            return false
        }
    }

    private static func isToitoi(allMelds: [MeldType]) -> Bool {
        allMelds.allSatisfy {
            if case .sequence = $0 { return false }
            return true
        }
    }

    private static func flushCondition(pair: Tile, allMelds: [MeldType]) -> ScoringCondition? {
        var suits = Set<Suit>()
        suits.insert(pair.suit)
        for meld in allMelds {
            for t in meld.tiles { suits.insert(t.suit) }
        }
        let nonHonor = suits.filter { $0.isNumbered }
        let hasHonor = suits.contains(.wind) || suits.contains(.dragon)
        if nonHonor.count == 1 && !hasHonor { return .fullFlush }
        if nonHonor.count == 1 && hasHonor  { return .halfFlush }
        return nil
    }

    private static func dragonCondition(pair: Tile, allMelds: [MeldType]) -> ScoringCondition? {
        var dragonTriplets = 0
        var dragonPair = false
        if pair.suit == .dragon { dragonPair = true }
        for meld in allMelds {
            if case .triplet(let t) = meld, t.suit == .dragon { dragonTriplets += 1 }
            if case .kong(let t, _) = meld, t.suit == .dragon { dragonTriplets += 1 }
        }
        if dragonTriplets == 3 { return .bigThreeDragons }
        if dragonTriplets == 2 && dragonPair { return .smallThreeDragons }
        return nil
    }

    private static func windCondition(pair: Tile, allMelds: [MeldType]) -> ScoringCondition? {
        var windTriplets = 0
        var windPair = false
        if pair.suit == .wind { windPair = true }
        for meld in allMelds {
            if case .triplet(let t) = meld, t.suit == .wind { windTriplets += 1 }
            if case .kong(let t, _) = meld, t.suit == .wind { windTriplets += 1 }
        }
        if windTriplets == 4 { return .bigFourWinds }
        if windTriplets == 3 && windPair { return .smallFourWinds }
        return nil
    }

    /// 圈風/門風/箭刻 — 1台 per qualifying honour triplet (or kong). A wind matching
    /// both the round and the seat scores twice (圈風 + 門風 = 2台). Suppressed when a
    /// 三元/四喜 grouping already covers those honours.
    private static func honorPungConditions(
        allMelds: [MeldType], roundWind: Int, seatWind: Int,
        dragonGrouped: Bool, windGrouped: Bool
    ) -> [ScoringCondition] {
        var out: [ScoringCondition] = []
        for meld in allMelds {
            let tile: Tile
            switch meld {
            case .triplet(let t):  tile = t
            case .kong(let t, _):  tile = t
            case .sequence:        continue
            }
            if tile.suit == .dragon, !dragonGrouped {
                out.append(.dragonPung)
            }
            if tile.suit == .wind, !windGrouped {
                if tile.value == roundWind { out.append(.roundWindPung) }
                if tile.value == seatWind  { out.append(.seatWindPung) }
            }
        }
        return out
    }

    /// 三暗刻 (2台) / 五暗刻 (8台). A concealed triplet is one formed from the closed
    /// hand; on a discard win (放槍) the triplet completed by the winning tile is
    /// exposed and does not count. 暗槓 counts as concealed.
    private static func concealedTripletCondition(result: WinResult, context: WinContext) -> ScoringCondition? {
        let closedTriplets: [Tile] = result.melds.compactMap {
            if case .triplet(let t) = $0 { return t }
            return nil
        }
        var concealed = closedTriplets.count
        if !context.isTsumo, let win = context.winningTile, closedTriplets.contains(win) {
            concealed -= 1   // the ronned triplet is 明刻
        }
        concealed += context.openMelds.filter {
            if case .kong(_, isOpen: false) = $0 { return true }
            return false
        }.count
        if concealed >= 5 { return .fiveConcealed }
        if concealed >= 3 { return .threeConcealed }
        return nil
    }

    private static func isAllTerminals(pair: Tile, allMelds: [MeldType]) -> Bool {
        guard pair.isTerminal else { return false }
        return allMelds.allSatisfy { $0.tiles.allSatisfy { $0.isTerminal } }
    }

    private static func isAllHonors(pair: Tile, allMelds: [MeldType]) -> Bool {
        guard pair.isHonor else { return false }
        return allMelds.allSatisfy { $0.tiles.allSatisfy { $0.isHonor } }
    }

    // MARK: - Flower scoring

    private static func flowerConditions(_ flowers: [Tile], seatWind: Int) -> [ScoringCondition] {
        flowers.flatMap { flower -> [ScoringCondition] in
            var conds: [ScoringCondition] = [.flower(flower)]
            // 門前花：春夏秋冬 對應 東南西北（value 1-4），梅蘭菊竹也對應（value 5-8 → 1-4）
            let flowerSeat = flower.value <= 4 ? flower.value : flower.value - 4
            if flowerSeat == seatWind { conds.append(.ownFlower(flower)) }
            return conds
        }
    }
}
