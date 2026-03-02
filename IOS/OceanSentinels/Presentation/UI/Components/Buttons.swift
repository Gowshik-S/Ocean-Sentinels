import SwiftUI

// MARK: - OceanPrimaryButton

/// Primary button with Ocean theme.
struct OceanPrimaryButton: View {
    let text: String
    let action: () -> Void
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var icon: String?

    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                HStack(spacing: 8) {
                    if let icon {
                        Image(systemName: icon)
                            .font(.body)
                    }
                    Text(text)
                        .fontWeight(.semibold)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .foregroundStyle(.white)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.oceanPrimary.opacity(isEnabled && !isLoading ? 1 : 0.5))
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        )
        .disabled(!isEnabled || isLoading)
    }
}

// MARK: - OceanSecondaryButton

/// Outlined secondary button.
struct OceanSecondaryButton: View {
    let text: String
    let action: () -> Void
    var isEnabled: Bool = true
    var icon: String?

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(text)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .foregroundStyle(Color.oceanPrimary)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.oceanPrimary, lineWidth: 2)
        )
        .disabled(!isEnabled)
    }
}

// MARK: - OceanDangerButton

/// Danger/delete button.
struct OceanDangerButton: View {
    let text: String
    let action: () -> Void
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var icon: String?

    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                HStack(spacing: 8) {
                    if let icon {
                        Image(systemName: icon)
                    }
                    Text(text)
                        .fontWeight(.semibold)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .foregroundStyle(.white)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.oceanDanger)
        )
        .disabled(!isEnabled || isLoading)
    }
}

// MARK: - OceanTextButton

struct OceanTextButton: View {
    let text: String
    let action: () -> Void
    var color: Color = .oceanPrimary

    var body: some View {
        Button(action: action) {
            Text(text)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }
}

// MARK: - DemoRoleButton

/// Demo role button for quick login.
struct DemoRoleButton: View {
    let text: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(text)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(color)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
