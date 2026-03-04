# Ocean Sentinels iOS — Conversion Lessons

## Lesson 1: Always specify ALL target platforms in Package.swift (2026-03-04)

**What happened:** Package.swift only had `.iOS(.v17)`. When Xcode built for macOS (CI or
"My Mac" destination), it defaulted to macOS 10.13 — far too old for SwiftData and os.Logger.

**Rule:** When a Package.swift is used for CI compile-checks (as stated in the comment),
ALWAYS include `.macOS(.v14)` alongside `.iOS(.v17)` if the code uses SwiftData.
SwiftData requires iOS 17+ / macOS 14+, and os.Logger requires iOS 14+ / macOS 11+.
The macOS 14 minimum covers both.

**Pattern:**
```swift
platforms: [
    .iOS(.v17),
    .macOS(.v14)  // REQUIRED for CI builds targeting macOS
]
```

**Prevention:** Before marking any conversion as complete, verify Package.swift platforms
cover all build destinations (iOS, macOS at minimum).

---

## Lesson 2: Build errors can cascade from a single root cause

**What happened:** The build log showed ~100+ errors across 9 source files, but ALL of them
were caused by the single missing `.macOS(.v14)` platform. The compiler reported the same
`@Model` / `Logger` availability errors for every compilation unit that included the affected
files.

**Rule:** Before fixing individual files, check if there's a project-level configuration
error (deployment target, platform, Swift version) that's the true root cause.
