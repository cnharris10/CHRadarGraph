// swift-tools-version:6.3
import PackageDescription

let package = Package(
    name: "CHRadarGraph",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "CHRadarGraph",
            targets: ["CHRadarGraph"]
        )
    ],
    targets: [
        .target(
            name: "CHRadarGraph",
            path: "Sources/CHRadarGraph"
        ),
        .testTarget(
            name: "CHRadarGraphTests",
            dependencies: ["CHRadarGraph"],
            path: "Tests/CHRadarGraphTests"
        )
    ],
    swiftLanguageModes: [.v6]
)
