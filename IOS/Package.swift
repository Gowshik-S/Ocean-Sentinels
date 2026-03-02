// swift-tools-version: 5.9
// Package.swift — used for CI compilation checks (GitHub Actions)
// Allows `swift build` without an .xcodeproj file.

import PackageDescription

let package = Package(
    name: "OceanSentinels",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)   // macOS target lets `swift build` run on CI without a simulator
    ],
    products: [
        .library(
            name: "OceanSentinels",
            targets: ["OceanSentinels"]
        )
    ],
    targets: [
        .target(
            name: "OceanSentinels",
            path: "OceanSentinels",
            exclude: [
                // Xcode-only files — not valid Swift sources
                "Info.plist",
                "OceanSentinels.entitlements"
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        )
    ]
)
