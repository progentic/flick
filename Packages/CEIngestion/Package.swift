// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "CEIngestion",
    platforms: [.iOS(.v26)],
    products: [.library(name: "CEIngestion", targets: ["CEIngestion"])],
    dependencies: [
        .package(path: "../FlickDomain")
    ],
    targets: [
        .target(
            name: "CEIngestion",
            dependencies: [
                .product(name: "FlickDomain", package: "FlickDomain")
            ]
        ),
        .testTarget(name: "CEIngestionTests", dependencies: ["CEIngestion"])
    ],
    swiftLanguageModes: [.v6]
)
