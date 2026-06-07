// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "TaskIsland",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "TaskIsland", targets: ["TaskIsland"]),
        .executable(name: "TaskIslandChecks", targets: ["TaskIslandChecks"])
    ],
    targets: [
        .target(
            name: "TaskIslandCore"
        ),
        .executableTarget(
            name: "TaskIsland",
            dependencies: ["TaskIslandCore"]
        ),
        .executableTarget(
            name: "TaskIslandChecks",
            dependencies: ["TaskIslandCore"]
        )
    ]
)
