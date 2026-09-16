// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "CECapture",
    platforms: [.iOS(.v26), .macOS(.v14)],
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
        ),
        .testTarget(name: "CECaptureTests", dependencies: ["CECapture"])
    ],
    swiftLanguageModes: [.v6]
)
