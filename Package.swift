// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Razzil",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Razzil",
            targets: ["Razzil"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/mostudiosnz/raigor", from: "1.0.0"),
        .package(url: "https://github.com/mostudiosnz/gondar", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Razzil",
            dependencies: [
                .product(name: "Raigor", package: "raigor"),
                .product(name: "Gondar", package: "gondar"),
            ]),
        .testTarget(
            name: "RazzilTests",
            dependencies: ["Razzil"]),
    ]
)
