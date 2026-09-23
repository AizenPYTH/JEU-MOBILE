// swift-tools-version: 6.0
import PackageDescription

// BistroKit: everything except the thin iOS app shell.
//
//  GameCore   – pure Swift engine (Foundation only). No SwiftUI/SpriteKit. Builds & tests on Linux.
//  GameData   – bundled JSON content + balance config (resources only, no logic).
//  BistroUI   – presentation layer (SwiftUI + SpriteKit). Apple platforms only.
//  BalanceSim – command-line balance simulator (`swift run BalanceSim`).

var targets: [Target] = [
    .target(
        name: "GameCore",
        swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
    ),
    .target(
        name: "GameData",
        dependencies: ["GameCore"],
        resources: [.copy("Resources/Content"), .copy("Resources/Config")]
    ),
    .executableTarget(
        name: "BalanceSim",
        dependencies: ["GameCore", "GameData"]
    ),
    .testTarget(name: "GameCoreTests", dependencies: ["GameCore"]),
    .testTarget(name: "GameDataTests", dependencies: ["GameCore", "GameData"]),
]

var products: [Product] = [
    .library(name: "GameCore", targets: ["GameCore"]),
    .library(name: "GameData", targets: ["GameData"]),
    .executable(name: "BalanceSim", targets: ["BalanceSim"]),
]

#if !os(Linux)
targets.append(
    .target(
        name: "BistroUI",
        dependencies: ["GameCore", "GameData"],
        resources: [.process("Resources")]
    )
)
products.append(.library(name: "BistroUI", targets: ["BistroUI"]))
#endif

let package = Package(
    name: "BistroKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: products,
    targets: targets
)
