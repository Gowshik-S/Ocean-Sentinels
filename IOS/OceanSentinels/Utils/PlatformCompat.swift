import SwiftUI

// MARK: - Cross-Platform Compatibility Helpers
// This file provides platform-agnostic wrappers for iOS-only SwiftUI APIs,
// allowing the codebase to compile cleanly on both iOS and macOS (CI).

// MARK: - Color Extensions

extension Color {
    /// UIColor.systemGray on iOS; a comparable gray on macOS.
    static var compatSystemGray: Color {
        #if os(iOS)
        Color(.systemGray)
        #else
        Color(nsColor: .systemGray)
        #endif
    }

    /// UIColor.systemGray4 on iOS; a comparable mid-light gray on macOS.
    static var compatSystemGray4: Color {
        #if os(iOS)
        Color(.systemGray4)
        #else
        Color.gray.opacity(0.48)
        #endif
    }

    /// UIColor.systemGray6 on iOS; a comparable very-light gray on macOS.
    static var compatSystemGray6: Color {
        #if os(iOS)
        Color(.systemGray6)
        #else
        Color.gray.opacity(0.15)
        #endif
    }

    /// UIColor.systemBackground on iOS; windowBackgroundColor on macOS.
    static var compatSystemBackground: Color {
        #if os(iOS)
        Color(.systemBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    /// UIColor.secondarySystemBackground on iOS; controlBackgroundColor on macOS.
    static var compatSecondarySystemBackground: Color {
        #if os(iOS)
        Color(.secondarySystemBackground)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }
}

// MARK: - ToolbarItemPlacement Extension

extension ToolbarItemPlacement {
    /// .topBarTrailing on iOS 16+; .automatic on macOS.
    static var compatTopBarTrailing: ToolbarItemPlacement {
        #if os(iOS)
        .topBarTrailing
        #else
        .automatic
        #endif
    }
}

// MARK: - View Modifier Extensions

extension View {
    /// Applies `.navigationBarTitleDisplayMode(.inline)` on iOS only (no-op on macOS).
    @ViewBuilder
    func compatInlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// Applies `.listStyle(.insetGrouped)` on iOS, `.listStyle(.inset)` on macOS.
    @ViewBuilder
    func compatInsetGroupedListStyle() -> some View {
        #if os(iOS)
        self.listStyle(.insetGrouped)
        #else
        self.listStyle(.inset)
        #endif
    }

    /// Applies iOS-only email keyboard & text-content modifiers (no-op on macOS).
    @ViewBuilder
    func compatEmailInputModifiers() -> some View {
        #if os(iOS)
        self
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .textInputAutocapitalization(.never)
        #else
        self
        #endif
    }

    /// Applies iOS-only phone keyboard & text-content modifiers (no-op on macOS).
    @ViewBuilder
    func compatPhoneInputModifiers() -> some View {
        #if os(iOS)
        self
            .keyboardType(.phonePad)
            .textContentType(.telephoneNumber)
        #else
        self
        #endif
    }
}
