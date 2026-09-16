// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "CECapture",
    platforms: [.iOS(.v26)],
    products: [.library(name: "CECapture", targets: ["CECapture"])],
    dependencies: [
        .package(path: "../FlickDomain")
    ],
    targets: [
        .target(
            name: "CECapture",
            dependencies: [
                .product(name: "FlickDomain", package: "FlickDomain")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
