// swift-tools-version: 6.0
import PackageDescription

// ScreenshotKit: everything except the thin iOS app shell.
//
//  CaseEngine   – pure Swift investigation engine (Foundation only): case model, timer, time costs,
//                 search, live notifications, evidence tracking, verdict and score. Builds & tests on Linux.
//  CaseLibrary  – the cases as JSON resources + the game rules (time costs, scoring). No logic.
//  ScreenshotUI – the phone interface (SwiftUI). Apple platforms only.
//  CaseLint     – command-line tool: validates every case (and the story) and checks it is solvable in time.
//  StoryEngine  – pure Swift story engine (Foundation only): characters, rooms, scenes, dialogue,
//                 campaign, director (state machine), versioned save. Builds & tests on Linux.
//  StoryLibrary – the story as JSON resources (characters, NPCs, rooms, campaign, scenes). No logic.

var targets: [Target] = [
    .target(
        name: "CaseEngine",
        swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
    ),
    .target(
        name: "CaseLibrary",
        dependencies: ["CaseEngine"],
        resources: [.copy("Resources/Cases"), .copy("Resources/Rules")]
    ),
    .target(
        name: "StoryEngine",
        swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
    ),
    .target(
        name: "StoryLibrary",
        dependencies: ["StoryEngine"],
        resources: [.copy("Resources/Story")]
    ),
    .executableTarget(
        name: "CaseLint",
        dependencies: ["CaseEngine", "CaseLibrary", "StoryEngine", "StoryLibrary"]
    ),
    .testTarget(name: "CaseEngineTests", dependencies: ["CaseEngine"]),
    .testTarget(name: "CaseLibraryTests", dependencies: ["CaseEngine", "CaseLibrary"]),
    .testTarget(name: "StoryEngineTests", dependencies: ["StoryEngine", "StoryLibrary", "CaseEngine", "CaseLibrary"]),
]

var products: [Product] = [
    .library(name: "CaseEngine", targets: ["CaseEngine"]),
    .library(name: "CaseLibrary", targets: ["CaseLibrary"]),
    .library(name: "StoryEngine", targets: ["StoryEngine"]),
    .library(name: "StoryLibrary", targets: ["StoryLibrary"]),
    .executable(name: "CaseLint", targets: ["CaseLint"]),
]

#if !os(Linux)
targets.append(
    .target(
        name: "ScreenshotUI",
        dependencies: ["CaseEngine", "CaseLibrary", "StoryEngine", "StoryLibrary"],
        resources: [.process("Resources")]
    )
)
products.append(.library(name: "ScreenshotUI", targets: ["ScreenshotUI"]))
#endif

let package = Package(
    name: "ScreenshotKit",
    defaultLocalization: "fr",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: products,
    targets: targets
)
