// swift-tools-version: 6.0
// Package.swift — used for CI compilation checks (GitHub Actions)
// Allows `swift build` without an .xcodeproj file.
//
// NOTE: This builds the code as a *library* for compile-checking only.
// The actual app is built via Xcode with the .xcodeproj (or xcodegen).
// OceanSentinelsApp.swift (@main) must be excluded here because
// @main is invalid in a library target.

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
                "OceanSentinels.entitlements",
                // @main entry point — invalid in a library target.
                // Only used when Xcode builds the actual .app bundle.
                "OceanSentinelsApp.swift"
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                // Swift 6 strict concurrency produces errors for patterns
                // that are safe in our codebase (e.g. @Published in non-Sendable
                // ObservableObject classes, NSObject subclass delegates).
                // Keep minimal until full Swift 6 migration is complete.
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
