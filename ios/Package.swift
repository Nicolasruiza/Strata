// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "StrataCore",
    platforms: [.iOS(.v17), .watchOS(.v10), .macOS(.v14)],
    products: [.library(name: "StrataCore", targets: ["StrataCore"])],
    targets: [
        .target(name: "StrataCore", path: "StrataCore"),
        .testTarget(
            name: "StrataCoreTests",
            dependencies: ["StrataCore"],
            path: "StrataCoreTests",
            resources: [.copy("Fixtures")]
        ),
    ]
)
