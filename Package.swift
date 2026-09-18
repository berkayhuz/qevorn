// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Qevorn",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "qevorn", targets: ["Qevorn"])
    ],
    targets: [
        .executableTarget(
            name: "Qevorn",
            path: "Sources/Qevorn",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
