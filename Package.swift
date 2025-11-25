import PackageDescription

let package = Package(
    name: "Ignis",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Ignis",
            targets: ["Ignis"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "Ignis",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestoreSwift", package: "firebase-ios-sdk")
            ]),
        .testTarget(
            name: "IgnisTests",
            dependencies: ["Ignis"]),
    ]
)
