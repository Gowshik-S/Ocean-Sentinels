// swift-tools-version: 6.0
// Package.swift — CI compilation check for OceanSentinels iOS
//
// PURPOSE: Compile-check all Swift sources on macOS (GitHub Actions).
//          This is NOT the runnable app — @main requires an Xcode .xcodeproj.
//
// TO RUN ON iOS SIMULATOR:
//   1. On Mac, open Xcode → File → New → Project → iOS → App
//   2. Name it "OceanSentinels", bundle ID "com.oceansentinels.app"
//   3. Delete the generated ContentView.swift & Assets.xcassets stubs
//   4. File → Add Files → Add every file from the OceanSentinels/ folder
//   5. In Build Settings → INFOPLIST_FILE → set to OceanSentinels/Info.plist
//   6. Set Minimum Deployments → iOS 17.0
//   7. Select an iPhone simulator → ⌘R
//
// CI: swift build -c release (builds library target, catches compile errors)

import PackageDescription

let package = Package(
    name: "OceanSentinels",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)   // needed for CI macOS runners (SwiftData + Logger)
    ],
    products: [
        .library(name: "OceanSentinels", targets: ["OceanSentinels"])
    ],
    targets: [
        .target(
            name: "OceanSentinels",
            path: "OceanSentinels",
            exclude: [
                "Info.plist",
                "OceanSentinels.entitlements",
                "OceanSentinelsApp.swift"    // @main is invalid in a library target
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
