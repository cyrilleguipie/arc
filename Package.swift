// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Arc",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(name: "Arc", targets: ["Arc"])
    ],
    targets: [
        .target(
            name: "Arc",
            path: "Sources/Arc"
        ),
        .testTarget(
            name: "ArcTests",
            dependencies: ["Arc"],
            path: "Tests/ArcTests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
