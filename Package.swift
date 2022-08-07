// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ObservableProduct",
    platforms: [.iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ObservableProduct",
            targets: ["ObservableProduct"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/mostudiosnz/firebase-logger", branch: "main"),
        .package(url: "https://github.com/mostudiosnz/firebase-swiftui-tracker", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ObservableProduct",
            dependencies: [
                .product(name: "MOFirebaseLogger", package: "firebase-logger"),
                .product(name: "MOFirebaseSwiftUITracker", package: "firebase-swiftui-tracker"),
            ]),
        .testTarget(
            name: "ObservableProductTests",
            dependencies: ["ObservableProduct"]),
    ]
)
