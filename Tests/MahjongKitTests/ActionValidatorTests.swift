import Testing
@testable import MahjongKit

@Suite("ActionValidator")
struct ActionValidatorTests {

    // MARK: - Chow 吃

    @Test func chowValidSequences() {
        let hand: [Tile] = [.man(2), .man(3), .man(5), .pin(1)]
        let options = ActionValidator.canChow(hand: hand, discard: .man(4))
        // 2-3-4 and 3-4-5 are possible
        #expect(options.contains([.man(2), .man(3)]))
        #expect(options.contains([.man(3), .man(5)]))
    }

    @Test func chowHonorTileInvalid() {
        let hand: [Tile] = [.east, .south, .west]
        #expect(ActionValidator.canChow(hand: hand, discard: .east).isEmpty)
    }

    @Test func chowEdgeLow() {
        // Discard = 1m, hand has 2m, 3m
        let hand: [Tile] = [.man(2), .man(3)]
        let options = ActionValidator.canChow(hand: hand, discard: .man(1))
        #expect(options.contains([.man(2), .man(3)]))
    }

    @Test func chowEdgeHigh() {
        // Discard = 9m, hand has 7m, 8m
        let hand: [Tile] = [.man(7), .man(8)]
        let options = ActionValidator.canChow(hand: hand, discard: .man(9))
        #expect(options.contains([.man(7), .man(8)]))
    }

    // MARK: - Pong 碰

    @Test func pongValid() {
        let hand: [Tile] = [.man(5), .man(5), .pin(1)]
        #expect(ActionValidator.canPong(hand: hand, discard: .man(5)))
    }

    @Test func pongInvalidNotEnough() {
        let hand: [Tile] = [.man(5), .pin(1)]
        #expect(!ActionValidator.canPong(hand: hand, discard: .man(5)))
    }

    // MARK: - Kong 槓

    @Test func openKongValid() {
        let hand: [Tile] = [.east, .east, .east, .pin(1)]
        #expect(ActionValidator.canOpenKong(hand: hand, discard: .east))
    }

    @Test func openKongInvalid() {
        let hand: [Tile] = [.east, .east, .pin(1)]
        #expect(!ActionValidator.canOpenKong(hand: hand, discard: .east))
    }

    @Test func closedKongValid() {
        let hand: [Tile] = [.man(3), .man(3), .man(3), .man(3), .pin(1)]
        #expect(ActionValidator.canClosedKong(hand: hand).contains(.man(3)))
    }

    @Test func closedKongNone() {
        let hand: [Tile] = [.man(3), .man(3), .man(3), .pin(1)]
        #expect(ActionValidator.canClosedKong(hand: hand).isEmpty)
    }

    @Test func addKongValid() {
        let hand: [Tile] = [.chun, .pin(1)]
        let pongs: [Tile] = [.chun]
        #expect(ActionValidator.canAddKong(hand: hand, pongBaseTiles: pongs).contains(.chun))
    }

    @Test func addKongInvalid() {
        let hand: [Tile] = [.pin(1), .pin(2)]
        let pongs: [Tile] = [.chun]
        #expect(ActionValidator.canAddKong(hand: hand, pongBaseTiles: pongs).isEmpty)
    }
}
