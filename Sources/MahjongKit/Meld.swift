public enum MeldType: Hashable, Sendable {
    case sequence(Tile, Tile, Tile) // 順子（由小到大）
    case triplet(Tile)              // 刻子
    case kong(Tile, isOpen: Bool)   // 槓（明/暗）

    public var tiles: [Tile] {
        switch self {
        case .sequence(let a, let b, let c): return [a, b, c]
        case .triplet(let t):               return [t, t, t]
        case .kong(let t, _):               return [t, t, t, t]
        }
    }

    public var isKong: Bool {
        if case .kong = self { return true }
        return false
    }

    public var isOpen: Bool {
        if case .kong(_, let open) = self { return open }
        return false
    }

    public var baseTile: Tile {
        switch self {
        case .sequence(let a, _, _): return a
        case .triplet(let t):        return t
        case .kong(let t, _):        return t
        }
    }
}
