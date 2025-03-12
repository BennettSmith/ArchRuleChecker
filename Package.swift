// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "arch-rule-checker",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .executable(name: "ArchRuleChecker", targets: ["ArchRuleChecker"]),
        .plugin(name: "ArchRuleCheckerPlugin", targets: ["ArchRuleCheckerPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "ArchRuleChecker",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .plugin(
            name: "ArchRuleCheckerPlugin",
            capability: .command(
                intent: .custom(
                    verb: "check-architecture",
                    description: "Verifies code adheres to architectural rules"
                ),
                permissions: [.writeToPackageDirectory(reason: "To output report files")]
            ),
            dependencies: [
                .target(name: "ArchRuleChecker")
            ]
        ),
        .testTarget(
            name: "ArchRuleCheckerTests",
            dependencies: [
                "ArchRuleChecker",
            ]
        ),
    ]
)
