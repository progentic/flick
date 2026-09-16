// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "CEUI",
    platforms: [.iOS(.v26), .macOS(.v14)],
    products: [.library(name: "CEUI", targets: ["CEUI"])],
    dependencies: [
        .package(path: "../FlickDomain"),
        .package(path: "../CECapture")
    ],
    targets: [
        .target(
            name: "CEUI",
            dependencies: [
                .product(name: "FlickDomain", package: "FlickDomain"),
                .product(name: "CECapture", package: "CECapture")
            ]
        ),
        .testTarget(name: "CEUITests", dependencies: ["CEUI"])
    ],
    swiftLanguageModes: [.v6]
)
