// swift-tools-version: 6.3
// Requires Swift tools 6.3; see README.md for observed verification results.
import PackageDescription

let package = Package(
    name: "FlickDomain",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "FlickDomain", targets: ["FlickDomain"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "FlickDomain",
            dependencies: [
            ]
        ),
        .testTarget(
            name: "FlickDomainTests",
            dependencies: ["FlickDomain"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
