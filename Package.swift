// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Observer",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Observer",
            targets: ["Observer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/aetherealtech/SwiftCoreExtensions.git", branch: "master"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Observer",
            dependencies: [
                .product(name: "CoreExtensions", package: "SwiftCoreExtensions"),
            ]),
        .testTarget(
            name: "ObserverTests",
            dependencies: ["Observer"]),
    ]
)
