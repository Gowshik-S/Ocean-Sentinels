import SwiftUI

// MARK: - Status Badge

/// Badge for incident status.
struct StatusBadge: View {
    let status: IncidentStatus

    private var config: (color: Color, text: String, icon: String) {
        switch status {
        case .pending: (Color.oceanWarning, "Pending", "hourglass")
        case .verified: (Color.oceanInfo, "Verified", "checkmark.seal.fill")
        case .inProgress: (Color.oceanPrimary, "In Progress", "shippingbox.fill")
        case .resolved: (Color.oceanSuccess, "Resolved", "checkmark.circle.fill")
        case .closed: (Color.gray, "Closed", "xmark.circle.fill")
        }
    }

    var body: some View {
        Label(config.text, systemImage: config.icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(config.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(config.color.opacity(0.1), in: Capsule())
    }
}

// MARK: - Urgency Badge

/// Badge for urgency level.
struct UrgencyBadge: View {
    let urgency: UrgencyLevel

    private var config: (color: Color, text: String, icon: String) {
        switch urgency {
        case .low: (Color.oceanSuccess, "Low", "arrow.down")
        case .medium: (Color.oceanWarning, "Medium", "minus")
        case .high: (Color.orange, "High", "arrow.up")
        case .critical: (Color.oceanDanger, "Critical", "exclamationmark.2")
        }
    }

    var body: some View {
        Label(config.text, systemImage: config.icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(config.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(config.color.opacity(0.1), in: Capsule())
    }
}

// MARK: - Hazard Type Badge

/// Badge for hazard type.
struct HazardTypeBadge: View {
    let hazardType: HazardType
    var compact: Bool = false

    var body: some View {
        let info = Self.hazardInfo(for: hazardType)
        if compact {
            Image(systemName: info.icon)
                .font(.caption2)
                .foregroundStyle(info.color)
                .padding(6)
                .background(info.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
        } else {
            Label(info.text, systemImage: info.icon)
                .font(.caption.weight(.medium))
                .foregroundStyle(info.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(info.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    static func hazardInfo(for type: HazardType) -> (color: Color, text: String, icon: String) {
        switch type {
        case .highWaves: (Color(hex: 0x1976D2), "High Waves", "water.waves")
        case .strongCurrents: (Color(hex: 0x0288D1), "Strong Currents", "wind")
        case .flooding: (Color(hex: 0x00897B), "Coastal Flooding", "drop.fill")
        case .tsunami: (Color(hex: 0xD32F2F), "Tsunami Warning", "exclamationmark.triangle.fill")
        case .lostVessel: (Color(hex: 0xF57C00), "Lost Vessel", "figure.open.water.swim")
        case .debris: (Color(hex: 0x607D8B), "Debris/Pollution", "trash.fill")
        case .erosion: (Color(hex: 0x795548), "Coastal Erosion", "mountain.2.fill")
        case .storm: (Color(hex: 0x5E35B1), "Storm Alert", "cloud.bolt.fill")
        case .oilSpill: (Color(hex: 0x33691E), "Oil Spill", "drop.triangle.fill")
        case .other: (Color(hex: 0x9E9E9E), "Other Hazard", "ellipsis.circle.fill")
        }
    }
}

// MARK: - Role Badge

/// Badge for user role.
struct RoleBadge: View {
    let role: UserRole

    private var config: (color: Color, text: String, icon: String) {
        switch role {
        case .admin: (Color.oceanDanger, "Admin", "gearshape.fill")
        case .rescueTeam: (Color.oceanPrimary, "Rescue Team", "cross.case.fill")
        case .authority: (Color.oceanWarning, "Authority", "shield.fill")
        case .public: (Color.oceanSuccess, "Citizen", "person.fill")
        }
    }

    var body: some View {
        Label(config.text, systemImage: config.icon)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(config.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(config.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Count Badge

struct CountBadge: View {
    let count: Int
    var color: Color = .oceanDanger

    var body: some View {
        if count > 0 {
            Text(count > 99 ? "99+" : "\(count)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(color, in: Circle())
        }
    }
}

// MARK: - Status Dot

struct StatusDot: View {
    let isActive: Bool

    var body: some View {
        Circle()
            .fill(isActive ? Color.oceanSuccess : Color.gray)
            .frame(width: 10, height: 10)
    }
}

// MARK: - Priority Indicator

struct PriorityIndicator: View {
    let urgency: UrgencyLevel

    private var color: Color {
        switch urgency {
        case .low: .oceanSuccess
        case .medium: .oceanWarning
        case .high: .orange
        case .critical: .oceanDanger
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 4)
    }
}
