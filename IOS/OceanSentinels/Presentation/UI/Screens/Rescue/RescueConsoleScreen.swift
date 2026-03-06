import SwiftUI

// MARK: - RescueConsoleScreen

struct RescueConsoleScreen: View {
    @Environment(IncidentViewModel.self) private var incidentVM
    @Environment(AuthViewModel.self) private var authVM
    @Environment(NavigationRouter.self) private var router

    @State private var selectedFilter = "all"

    private var currentUser: User? {
        if case .authenticated(let user, _) = authVM.userSession { return user }
        return nil
    }

    private var assignedIncidents: [Incident] { incidentVM.assignedIncidents }
    private var activeCount: Int { assignedIncidents.filter { $0.status == .inProgress }.count }
    private var pendingCount: Int { assignedIncidents.filter { $0.status == .verified }.count }
    private var completedCount: Int { assignedIncidents.filter { $0.status == .resolved }.count }

    private var filteredIncidents: [Incident] {
        switch selectedFilter {
        case "active": return assignedIncidents.filter { $0.status == .inProgress }
        case "pending": return assignedIncidents.filter { $0.status == .verified }
        case "completed": return assignedIncidents.filter { $0.status == .resolved }
        default: return assignedIncidents
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            rescueStatsRow
            rescueFilterChips

            // Error
            if let error = incidentVM.error {
                Text(error).font(.caption).foregroundStyle(Color.oceanDanger).padding(.horizontal).padding(.top, 4)
            }

            // Content
            if incidentVM.isLoading && assignedIncidents.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if filteredIncidents.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 56)).foregroundStyle(Color.oceanSuccess)
                    Text(selectedFilter == "all" ? "No assigned jobs" : "No jobs in this category")
                        .font(.headline).foregroundStyle(.secondary)
                    Text("Check back later for new assignments")
                        .font(.caption).foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                List(filteredIncidents, id: \.id) { incident in
                    RescueJobCardView(
                        incident: incident,
                        onViewDetail: { router.navigate(to: .incidentDetail(incidentId: incident.id)) },
                        onDeploy: {
                            incidentVM.deployResponse(id: incident.id)
                            incidentVM.loadAssignedIncidents()
                        },
                        onResolve: {
                            incidentVM.resolveIncident(id: incident.id)
                            incidentVM.loadAssignedIncidents()
                        }
                    )
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Rescue Console")
        .toolbar {
            ToolbarItem(placement: .compatTopBarTrailing) {
                Button { incidentVM.loadAssignedIncidents() } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task { incidentVM.loadAssignedIncidents() }
    }

    private var rescueStatsRow: some View {
        HStack(spacing: 8) {
            RescueStatChip(label: "Active", count: activeCount, color: .oceanDanger)
            RescueStatChip(label: "Pending", count: pendingCount, color: .oceanWarning)
            RescueStatChip(label: "Done", count: completedCount, color: .oceanSuccess)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var rescueFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach([
                    ("all", "All (\(assignedIncidents.count))"),
                    ("active", "Active (\(activeCount))"),
                    ("pending", "Pending (\(pendingCount))"),
                    ("completed", "Done (\(completedCount))")
                ], id: \.0) { key, label in
                    Button {
                        selectedFilter = key
                    } label: {
                        Text(label)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedFilter == key ? Color.oceanPrimary : Color.compatSecondarySystemBackground, in: Capsule())
                            .foregroundStyle(selectedFilter == key ? .white : .primary)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Rescue Stat Chip

private struct RescueStatChip: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)").font(.title2.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Rescue Job Card

private struct RescueJobCardView: View {
    let incident: Incident
    let onViewDetail: () -> Void
    let onDeploy: () -> Void
    let onResolve: () -> Void

    private func statusColor(_ status: IncidentStatus) -> Color {
        switch status {
        case .pending: return .oceanWarning
        case .verified: return .oceanInfo
        case .inProgress: return .oceanPrimary
        case .resolved: return .oceanSuccess
        case .closed, .falseAlarm: return .gray
        }
    }

    private func urgencyColor(_ urgency: UrgencyLevel) -> Color {
        switch urgency {
        case .critical: return .oceanDanger
        case .high: return .orange
        case .medium: return .oceanInfo
        case .low: return .oceanSuccess
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                Text(incident.referenceId).font(.caption).foregroundStyle(.secondary)
                Spacer()
                UrgencyBadge(urgency: incident.urgency)
                StatusBadge(status: incident.status)
            }

            // Hazard type
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill").font(.caption).foregroundStyle(statusColor(incident.status))
                Text(incident.hazardType.displayName).font(.subheadline.weight(.semibold))
            }

            // Location
            Label(incident.location, systemImage: "location").font(.caption).foregroundStyle(.secondary)

            // Description
            if !incident.description.isEmpty {
                Text(String(incident.description.prefix(120)) + (incident.description.count > 120 ? "..." : ""))
                    .font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }

            // Coordinates
            if incident.hasLocation {
                Label(String(format: "%.4f, %.4f", incident.latitude ?? 0, incident.longitude ?? 0), systemImage: "location.circle")
                    .font(.caption2).foregroundStyle(Color.oceanInfo)
            }

            Divider()

            // Actions
            HStack(spacing: 6) {
                Button("View", action: onViewDetail)
                    .font(.caption2).buttonStyle(.bordered).controlSize(.small)

                Spacer()

                if incident.canBeDeployed {
                    Button {
                        onDeploy()
                    } label: {
                        Label("Deploy", systemImage: "paperplane.fill")
                    }
                    .font(.caption2).buttonStyle(.borderedProminent).tint(Color.oceanWarning).controlSize(.small)
                }

                if incident.canBeResolved {
                    Button {
                        onResolve()
                    } label: {
                        Label("Resolve", systemImage: "checkmark.circle.fill")
                    }
                    .font(.caption2).buttonStyle(.borderedProminent).tint(Color.oceanSuccess).controlSize(.small)
                }

                if incident.status == .resolved {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .font(.caption2.weight(.semibold)).foregroundStyle(Color.oceanSuccess)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color.oceanSuccess.opacity(0.15), in: Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
}
