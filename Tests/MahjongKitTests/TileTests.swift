import Testing
@testable import MahjongKit

@Suite("Tile")
struct TileTests {

    @Test func isTerminal() {
        #expect(Tile.man(1).isTerminal)
        #expect(Tile.man(9).isTerminal)
        #expect(!Tile.man(5).isTerminal)
        #expect(!Tile.east.isTerminal)
    }

    @Test func isHonor() {
        #expect(Tile.east.isHonor)
        #expect(Tile.chun.isHonor)
        #expect(!Tile.man(1).isHonor)
    }

    @Test func isOrphan() {
        #expect(Tile.man(1).isOrphan)
        #expect(Tile.man(9).isOrphan)
        #expect(Tile.east.isOrphan)
        #expect(Tile.haku.isOrphan)
        #expect(!Tile.man(5).isOrphan)
    }

    @Test func isFlower() {
        #expect(Tile.flower(1).isFlower)
        #expect(!Tile.man(1).isFlower)
    }

    @Test func comparableOrdering() {
        let tiles: [Tile] = [Tile.man(9), Tile.man(1), Tile.east, Tile.pin(3)]
        let sorted = tiles.sorted()
        #expect(sorted[0] == Tile.man(1))
        #expect(sorted[1] == Tile.man(9))
        #expect(sorted[2] == Tile.pin(3))
        #expect(sorted[3] == Tile.east)
    }

    @Test func fullDeckCount() {
        #expect(Wall.fullDeck().count == 144)
    }

    @Test func description() {
        #expect(Tile.man(1).description == "1m")
        #expect(Tile.pin(5).description == "5p")
        #expect(Tile.east.description == "1z")
    }
}
