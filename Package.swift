// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QuickRead",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "QuickRead", targets: ["QuickRead"])
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.0")
    ],
    targets: [
        .executableTarget(
            name: "QuickRead",
            dependencies: ["HotKey"],
            path: "Sources/QuickRead"
        )
    ]
)
