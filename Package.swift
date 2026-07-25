// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "TaskIsland",
    platforms: [
        .macOS(.v15),
        .iOS(.v17)
    ],
    products: [
        .library(name: "TaskIslandCore", targets: ["TaskIslandCore"]),
        .library(name: "TaskIslandWidgetSupport", targets: ["TaskIslandWidgetSupport"]),
        .executable(name: "TaskIsland", targets: ["TaskIsland"]),
        .executable(name: "TaskIslandWidgets", targets: ["TaskIslandWidgets"]),
        .executable(name: "TaskIslandChecks", targets: ["TaskIslandChecks"])
    ],
    targets: [
        .target(
            name: "TaskIslandCore"
        ),
        .target(
            name: "TaskIslandWidgetSupport"
        ),
        .executableTarget(
            name: "TaskIsland",
            dependencies: ["TaskIslandCore", "TaskIslandWidgetSupport"]
        ),
        .executableTarget(
            name: "TaskIslandWidgets",
            dependencies: ["TaskIslandWidgetSupport"]
        ),
        .executableTarget(
            name: "TaskIslandChecks",
            dependencies: ["TaskIslandCore"]
        )
    ]
)
