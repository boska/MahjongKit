// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MahjongKit",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "MahjongKit", targets: ["MahjongKit"]),
    ],
    targets: [
        .target(name: "MahjongKit"),
        .testTarget(name: "MahjongKitTests", dependencies: ["MahjongKit"]),
        .executableTarget(name: "MahjongGame", dependencies: ["MahjongKit"],
                          path: "Sources/MahjongGame"),
    ]
)
