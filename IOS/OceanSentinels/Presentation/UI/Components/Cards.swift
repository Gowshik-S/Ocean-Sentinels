import SwiftUI

// MARK: - StatsCard

/// Stats card for dashboard.
struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    var iconColor: Color = .oceanPrimary
    var subtitle: String?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 56, height: 56)
                .background(iconColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))

            Text(value)
                .font(.title2.weight(.bold))

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - InfoCard

/// General-purpose info card.
struct InfoCard<Content: View>: View {
    let title: String
    var subtitle: String?
    var icon: String?
    var iconColor: Color = .oceanPrimary
    var onTap: (() -> Void)?
    @ViewBuilder let content: () -> Content

    var body: some View {
        let cardContent = VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                if let icon {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(iconColor)
                        .frame(width: 40, height: 40)
                        .background(iconColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(16)

            content()
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)

        if let onTap {
            Button(action: onTap) { cardContent }
                .buttonStyle(.plain)
        } else {
            cardContent
        }
    }
}

// MARK: - FeatureCard

/// Feature card for home screen.
struct FeatureCard: View {
    let title: String
    let description: String
    let icon: String
    var iconColor: Color = .oceanPrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                    .frame(width: 56, height: 56)
                    .background(iconColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - UserCard

/// User card for admin management.
struct UserCard: View {
    let name: String
    let email: String
    let role: String
    let roleColor: Color
    let action: () -> Void
    var onDelete: (() -> Void)?

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Avatar
                Text(name.prefix(1).uppercased())
                    .font(.title3.weight(.bold))
                    .foregroundStyle(roleColor)
                    .frame(width: 48, height: 48)
                    .background(roleColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(role)
                        .font(.caption2)
                        .foregroundStyle(roleColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(roleColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                }

                Spacer()
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SectionCard

/// Section header card.
struct SectionCard<Content: View, Action: View>: View {
    let title: String
    var action: (() -> Action)?
    @ViewBuilder let content: () -> Content

    init(title: String, @ViewBuilder content: @escaping () -> Content) where Action == EmptyView {
        self.title = title
        self.action = nil
        self.content = content
    }

    init(title: String, @ViewBuilder action: @escaping () -> Action, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.action = action
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.title3.weight(.bold))
                Spacer()
                action?()
            }

            content()
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

// MARK: - EmptyStateCard

/// Empty state placeholder.
struct EmptyStateCard<ActionContent: View>: View {
    let title: String
    let description: String
    let icon: String
    var action: (() -> ActionContent)?

    init(title: String, description: String, icon: String) where ActionContent == EmptyView {
        self.title = title
        self.description = description
        self.icon = icon
        self.action = nil
    }

    init(title: String, description: String, icon: String, @ViewBuilder action: @escaping () -> ActionContent) {
        self.title = title
        self.description = description
        self.icon = icon
        self.action = action
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            action?()
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.compatSystemGray6.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.compatSystemGray4.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
