// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KursanzeigeKit",
    // macOS listed too so `swift build`/`swift test` run directly on the
    // Mac host during development; the shipped app targets iOS 17+ only.
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "KursanzeigeKit", targets: ["KursanzeigeKit"])
    ],
    targets: [
        .target(
            name: "KursanzeigeKit",
            resources: [.copy("Data/constituents.json")]
        ),
        .testTarget(
            name: "KursanzeigeKitTests",
            dependencies: ["KursanzeigeKit"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
