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

---

## Lesson 3: iOS-only SwiftUI APIs break macOS CI builds (2026-03-04)

**What happened:** After fixing the deployment target, 40+ new errors appeared across 20 UI
files. APIs like `Color(.systemGray6)`, `.topBarTrailing`, `.insetGrouped`,
`.navigationBarTitleDisplayMode(.inline)`, `.keyboardType()`, `.textContentType()`, and
`.textInputAutocapitalization()` are all iOS-only and unavailable on macOS.

**Rule:** In a cross-platform SPM build, NEVER use iOS-only SwiftUI APIs directly.
Create a shared `PlatformCompat.swift` with `#if os(iOS) ... #else ... #endif` wrappers:
- **UIColor system colors** → `Color.compatSystemGray4` (static computed properties)
- **Toolbar placement** → `ToolbarItemPlacement.compatTopBarTrailing`
- **List styles** → `.compatInsetGroupedListStyle()` view modifier
- **Nav bar title mode** → `.compatInlineNavigationTitle()` view modifier
- **Keyboard/text modifiers** → `.compatEmailInputModifiers()` / `.compatPhoneInputModifiers()`

**Pattern:**
```swift
// In PlatformCompat.swift:
extension Color {
    static var compatSystemGray6: Color {
        #if os(iOS)
        Color(.systemGray6)
        #else
        Color.gray.opacity(0.15)
        #endif
    }
}
```

**Prevention:** When converting Android→iOS, run a grep for these iOS-only patterns before
marking conversion complete:
- `Color(.system` / `Color(.secondary`
- `.topBarTrailing` / `.bottomBarTrailing`
- `.insetGrouped`
- `.navigationBarTitleDisplayMode`
- `.keyboardType` / `.textContentType` / `.textInputAutocapitalization`

Always use the `compat*` equivalents from `PlatformCompat.swift` instead.
files.

**Rule:** Before fixing individual files, check if there's a project-level configuration
error (deployment target, platform, Swift version) that's the true root cause.
