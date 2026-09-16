// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "CEPipelines",
    platforms: [.iOS(.v26), .macOS(.v14)],
    products: [.library(name: "CEPipelines", targets: ["CEPipelines"])],
    dependencies: [
        .package(path: "../FlickDomain"),
        .package(path: "../CEIngestion"),
        .package(path: "../CESemantic"),
        .package(path: "../CEStorage"),
        .package(path: "../CEOutput")
    ],
    targets: [
        .target(
            name: "CEPipelines",
            dependencies: [
                .product(name: "FlickDomain", package: "FlickDomain"),
                .product(name: "CEIngestion", package: "CEIngestion"),
                .product(name: "CESemantic", package: "CESemantic"),
                .product(name: "CEStorage", package: "CEStorage"),
                .product(name: "CEOutput", package: "CEOutput")
            ]
        ),
        .testTarget(name: "CEPipelinesTests", dependencies: ["CEPipelines"])
    ],
    swiftLanguageModes: [.v6]
)
