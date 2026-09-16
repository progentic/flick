// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "CEOutput",
    platforms: [.iOS(.v26)],
    products: [.library(name: "CEOutput", targets: ["CEOutput"])],
    dependencies: [
        .package(path: "../FlickDomain")
    ],
    targets: [
        .target(
            name: "CEOutput",
            dependencies: [
                .product(name: "FlickDomain", package: "FlickDomain")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
