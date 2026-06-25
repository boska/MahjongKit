import Testing
@testable import MahjongKit

@Suite("ScoreCalculator")
struct ScoreCalculatorTests {

    // MARK: - Helpers

    private func makeResult(pair: Tile, melds: [MeldType], type: HandType = .standard) -> WinResult {
        WinResult(pair: pair, melds: melds, handType: type)
    }

    // MARK: - Basic

    @Test func pinhuTsumo() {
        // 平胡自摸 = 平胡(1) + 自摸(1) = 2台
        let result = makeResult(pair: .east, melds: [
            .sequence(.man(1), .man(2), .man(3)),
            .sequence(.man(4), .man(5), .man(6)),
            .sequence(.pin(1), .pin(2), .pin(3)),
            .sequence(.sou(7), .sou(8), .sou(9)),
            .sequence(.man(7), .man(8), .man(9)),
        ])
        let ctx = WinContext(isTsumo: true, isClosedHand: true)
        let conds = ScoreCalculator.calculate(result: result, context: ctx)
        #expect(conds.contains(.pinhu))
        #expect(conds.contains(.tsumo))
        #expect(ScoreCalculator.totalTai(conds) >= 2)
    }

    @Test func menzhanRon() {
        // 門前清放炮 = 門前清(1)
        let result = makeResult(pair: .east, melds: [
            .sequence(.man(1), .man(2), .man(3)),
            .sequence(.man(4), .man(5), .man(6)),
            .sequence(.pin(1), .pin(2), .pin(3)),
            .sequence(.sou(7), .sou(8), .sou(9)),
            .sequence(.man(7), .man(8), .man(9)),
        ])
        let ctx = WinContext(isTsumo: false, isClosedHand: true)
        let conds = ScoreCalculator.calculate(result: result, context: ctx)
        #expect(conds.contains(.menzhan))
        #expect(!conds.contains(.tsumo))
    }

    @Test func toitoi() {
        // 碰碰胡 = 4台
        let result = makeResult(pair: .man(5), melds: [
            .triplet(.man(1)),
            .triplet(.pin(3)),
            .triplet(.sou(7)),
            .triplet(.east),
            .triplet(.chun),
        ])
        let ctx = WinContext()
        let conds = ScoreCalculator.calculate(result: result, context: ctx)
        #expect(conds.contains(.toitoi))
        #expect(ScoreCalculator.totalTai(conds) >= 4)
    }

    // MARK: - Flush

    @Test func fullFlush() {
        // 清一色 = 5台
        let result = makeResult(pair: .man(5), melds: [
            .sequence(.man(1), .man(2), .man(3)),
            .triplet(.man(4)),
            .sequence(.man(6), .man(7), .man(8)),
            .triplet(.man(9)),
            .sequence(.man(1), .man(2), .man(3)),
        ])
        let ctx = WinContext()
        let conds = ScoreCalculator.calculate(result: result, context: ctx)
        #expect(conds.contains(.fullFlush))
        #expect(!conds.contains(.halfFlush))
    }

    @Test func halfFlush() {
        // 混一色 = 3台
        let result = makeResult(pair: .east, melds: [
            .sequence(.man(1), .man(2), .man(3)),
            .triplet(.man(4)),
            .triplet(.east),
            .triplet(.chun),
            .sequence(.man(7), .man(8), .man(9)),
        ])
        let ctx = WinContext()
        let conds = ScoreCalculator.calculate(result: result, context: ctx)
        #expect(conds.contains(.halfFlush))
        #expect(!conds.contains(.fullFlush))
    }

    // MARK: - Special hands

    @Test func eightPairsScore() {
        // 八對 = 4台
        let tiles: [Tile] = [
            .man(1), .man(3), .pin(2), .pin(7),
            .sou(4), .sou(9), .east, .chun
        ]
        let result = WinResult(pair: .man(1), melds: [], handType: .eightPairs)
        let ctx = WinContext()
        let conds = ScoreCalculator.calculate(result: result, context: ctx)
        #expect(conds.contains(.eightPairs))
        #expect(ScoreCalculator.totalTai(conds) >= 4)
        _ = tiles
    }

    @Test func thirteenOrphansScore() {
        // 十三么 = 13台
        let result = WinResult(pair: .man(1), melds: [], handType: .thirteenOrphans)
        let ctx = WinContext()
        let conds = ScoreCalculator.calculate(result: result, context: ctx)
        #expect(conds.contains(.thirteenOrphans))
        #expect(ScoreCalculator.totalTai(conds) >= 13)
    }

    @Test func heavenlyHand() {
        // 天胡 = 16台（排他，只有天胡和花牌）
        let result = makeResult(pair: .man(5), melds: [
            .sequence(.man(1), .man(2), .man(3)),
            .triplet(.man(4)),
            .sequence(.pin(1), .pin(2), .pin(3)),
            .triplet(.sou(9)),
            .sequence(.man(7), .man(8), .man(9)),
        ])
        let ctx = WinContext(isHeavenly: true)
        let conds = ScoreCalculator.calculate(result: result, context: ctx)
        #expect(conds.contains(.heavenly))
        #expect(ScoreCalculator.totalTai(conds) >= 16)
        // 天胡排他，不應有平胡/門清等
        #expect(!conds.contains(.pinhu))
        #expect(!conds.contains(.menzhan))
    }

    // MARK: - Dragon conditions

    @Test func bigThreeDragons() {
        // 大三元 = 8台
        let result = makeResult(pair: .man(5), melds: [
            .triplet(.chun),
            .triplet(.hatsu),
            .triplet(.haku),
            .sequence(.man(1), .man(2), .man(3)),
            .sequence(.pin(4), .pin(5), .pin(6)),
        ])
        let ctx = WinContext()
        let conds = ScoreCalculator.calculate(result: result, context: ctx)
        #expect(conds.contains(.bigThreeDragons))
        #expect(ScoreCalculator.totalTai(conds) >= 8)
    }

    @Test func smallThreeDragons() {
        // 小三元 = 4台
        let result = makeResult(pair: .chun, melds: [
            .triplet(.hatsu),
            .triplet(.haku),
            .sequence(.man(1), .man(2), .man(3)),
            .sequence(.pin(4), .pin(5), .pin(6)),
            .sequence(.sou(7), .sou(8), .sou(9)),
        ])
        let ctx = WinContext()
        let conds = ScoreCalculator.calculate(result: result, context: ctx)
        #expect(conds.contains(.smallThreeDragons))
    }

    // MARK: - Flower scoring

    @Test func flowerScore() {
        let result = makeResult(pair: .man(5), melds: [
            .sequence(.man(1), .man(2), .man(3)),
            .sequence(.man(4), .man(5), .man(6)),
            .sequence(.pin(1), .pin(2), .pin(3)),
            .sequence(.sou(7), .sou(8), .sou(9)),
            .sequence(.man(7), .man(8), .man(9)),
        ])
        // 東家（seatWind=1）拿到春花（flower value=1）= 1台 花 + 1台 門前花
        let flowers: [Tile] = [.flower(1)]
        let ctx = WinContext(seatWind: 1, flowers: flowers)
        let conds = ScoreCalculator.calculate(result: result, context: ctx)
        let flowerCount = conds.filter { if case .flower = $0 { return true }; return false }.count
        let ownFlowerCount = conds.filter { if case .ownFlower = $0 { return true }; return false }.count
        #expect(flowerCount == 1)
        #expect(ownFlowerCount == 1)
        #expect(ScoreCalculator.totalTai(conds.filter {
            if case .flower = $0 { return true }
            if case .ownFlower = $0 { return true }
            return false
        }) == 2)
    }

    // MARK: - Total tai

    @Test func fullFlushToitoiTsumo() {
        // 清一色(5) + 碰碰胡(4) + 自摸(1) = 10台
        let result = makeResult(pair: .man(5), melds: [
            .triplet(.man(1)),
            .triplet(.man(3)),
            .triplet(.man(6)),
            .triplet(.man(8)),
            .triplet(.man(9)),
        ])
        let ctx = WinContext(isTsumo: true, isClosedHand: true)
        let conds = ScoreCalculator.calculate(result: result, context: ctx)
        #expect(ScoreCalculator.totalTai(conds) >= 10)
    }

    // MARK: - 門清自摸 (門清一摸三)

    @Test func menzhanTsumoIsThree() {
        // 門清(1) + 自摸(1) + 門清自摸獎勵(1) = 3台
        let result = makeResult(pair: .man(5), melds: [
            .sequence(.man(1), .man(2), .man(3)),
            .triplet(.pin(4)),
            .sequence(.sou(1), .sou(2), .sou(3)),
            .sequence(.pin(6), .pin(7), .pin(8)),
            .triplet(.sou(9)),
        ])
        let ctx = WinContext(isTsumo: true, isClosedHand: true, seatWind: 1, roundWind: 1)
        let conds = ScoreCalculator.calculate(result: result, context: ctx)
        #expect(conds.contains(.tsumo))
        #expect(conds.contains(.menzhan))
        #expect(conds.contains(.menzhanTsumo))
    }

    // MARK: - 字牌刻 (圈風/門風/箭刻)

    @Test func honorPungs() {
        // 南家(seatWind=2) 東場(roundWind=1): 東刻=圈風1台, 南刻=門風1台, 中刻=箭刻1台
        let result = makeResult(pair: .man(5), melds: [
            .triplet(.east),         // 圈風 (round=1)
            .triplet(.south),        // 門風 (seat=2)
            .triplet(.chun),         // 箭刻
            .sequence(.man(1), .man(2), .man(3)),
            .sequence(.pin(4), .pin(5), .pin(6)),
        ])
        let ctx = WinContext(isTsumo: false, isClosedHand: true, seatWind: 2, roundWind: 1)
        let conds = ScoreCalculator.calculate(result: result, context: ctx)
        #expect(conds.contains(.roundWindPung))
        #expect(conds.contains(.seatWindPung))
        #expect(conds.contains(.dragonPung))
    }

    @Test func honorPungsSuppressedByBigThree() {
        // 大三元 already covers the dragons — no individual 箭刻 on top.
        let result = makeResult(pair: .man(5), melds: [
            .triplet(.chun), .triplet(.hatsu), .triplet(.haku),
            .sequence(.man(1), .man(2), .man(3)),
            .sequence(.pin(4), .pin(5), .pin(6)),
        ])
        let ctx = WinContext(seatWind: 2, roundWind: 1)
        let conds = ScoreCalculator.calculate(result: result, context: ctx)
        #expect(conds.contains(.bigThreeDragons))
        #expect(!conds.contains(.dragonPung))
    }

    // MARK: - 三暗刻 / 五暗刻

    @Test func fiveConcealedOnTsumo() {
        let result = makeResult(pair: .man(5), melds: [
            .triplet(.man(1)), .triplet(.pin(3)), .triplet(.sou(6)),
            .triplet(.pin(8)), .triplet(.sou(2)),
        ])
        let ctx = WinContext(isTsumo: true, isClosedHand: true)
        let conds = ScoreCalculator.calculate(result: result, context: ctx)
        #expect(conds.contains(.fiveConcealed))
        #expect(!conds.contains(.threeConcealed))
    }

    @Test func ronnedTripletIsNotConcealed() {
        // 4 concealed triplets but the winning tile completes the 5th → only 4 暗刻.
        // Spec tiers are 3 and 5, so 4 concealed scores 三暗刻 (2台), not 五暗刻.
        let result = makeResult(pair: .man(5), melds: [
            .triplet(.man(1)), .triplet(.pin(3)), .triplet(.sou(6)),
            .triplet(.pin(8)), .triplet(.sou(2)),
        ])
        let ctx = WinContext(isTsumo: false, isClosedHand: true, winningTile: .sou(2))
        let conds = ScoreCalculator.calculate(result: result, context: ctx)
        #expect(conds.contains(.threeConcealed))
        #expect(!conds.contains(.fiveConcealed))
    }

    // MARK: - 全求人

    @Test func allFromOthers() {
        // 5 melds 全吃碰光，單吊放槍胡 = 全求人 2台
        let result = makeResult(pair: .man(5), melds: [])
        let openMelds: [MeldType] = [
            .triplet(.pin(1)), .sequence(.sou(1), .sou(2), .sou(3)),
            .triplet(.east), .sequence(.man(7), .man(8), .man(9)),
            .triplet(.haku),
        ]
        let ctx = WinContext(isTsumo: false, isClosedHand: false, openMelds: openMelds)
        let conds = ScoreCalculator.calculate(result: result, context: ctx)
        #expect(conds.contains(.allFromOthers))
    }

    // MARK: - 人胡

    @Test func humanlyHand() {
        // 人胡 排他 = 8台 + 花
        let result = makeResult(pair: .man(5), melds: [
            .sequence(.man(1), .man(2), .man(3)),
            .triplet(.pin(4)),
            .sequence(.sou(1), .sou(2), .sou(3)),
            .sequence(.pin(6), .pin(7), .pin(8)),
            .triplet(.sou(9)),
        ])
        let ctx = WinContext(isHumanly: true, seatWind: 2, roundWind: 1)
        let conds = ScoreCalculator.calculate(result: result, context: ctx)
        #expect(conds.contains(.humanly))
        #expect(!conds.contains(.menzhan))
        #expect(ScoreCalculator.totalTai(conds) >= 8)
    }
}
