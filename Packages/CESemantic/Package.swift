// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "CESemantic",
    platforms: [.iOS(.v26)],
    products: [.library(name: "CESemantic", targets: ["CESemantic"])],
    dependencies: [
        .package(path: "../FlickDomain")
    ],
    targets: [
        .target(
            name: "CESemantic",
            dependencies: [
                .product(name: "FlickDomain", package: "FlickDomain")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
