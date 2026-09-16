// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "CEStorage",
    platforms: [.iOS(.v26), .macOS(.v14)],
    products: [.library(name: "CEStorage", targets: ["CEStorage"])],
    dependencies: [
        .package(path: "../FlickDomain")
    ],
    targets: [
        .target(
            name: "CEStorage",
            dependencies: [
                .product(name: "FlickDomain", package: "FlickDomain")
            ]
        ),
        .testTarget(name: "CEStorageTests", dependencies: ["CEStorage", .product(name: "FlickDomain", package: "FlickDomain")])
    ],
    swiftLanguageModes: [.v6]
)
