// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Observer",
    platforms: [.macOS(.v10_13), .iOS(.v12), .tvOS(.v12), .watchOS(.v4)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Observer",
            targets: ["Observer"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/aetherealtech/swift-assertions", branch: "master"),
        .package(url: "https://github.com/aetherealtech/swift-synchronization", branch: "master"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Observer",
            dependencies: [
                .product(name: "Synchronization", package: "swift-synchronization"),
            ],
            swiftSettings: [.concurrencyChecking(.complete)]
        ),
        .testTarget(
            name: "ObserverTests",
            dependencies: [
                "Observer",
                .product(name: "Assertions", package: "swift-assertions"),
                .product(name: "Synchronization", package: "swift-synchronization"),
            ],
            swiftSettings: [.concurrencyChecking(.complete)]
        ),
    ]
)

extension SwiftSetting {
    enum ConcurrencyChecking: String {
        case complete
        case minimal
        case targeted
    }
    
    static func concurrencyChecking(_ setting: ConcurrencyChecking = .minimal) -> Self {
        unsafeFlags([
            "-Xfrontend", "-strict-concurrency=\(setting)",
            "-Xfrontend", "-warn-concurrency",
            "-Xfrontend", "-enable-actor-data-race-checks",
        ])
    }
}
