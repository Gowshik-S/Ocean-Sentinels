import SwiftUI

// MARK: - AuthorityConsoleScreen

struct AuthorityConsoleScreen: View {
    @Environment(IncidentViewModel.self) private var incidentVM
    @Environment(AdminViewModel.self) private var adminVM
    @Environment(AuthViewModel.self) private var authVM
    @Environment(NavigationRouter.self) private var router

    @State private var selectedFilter = "all"
    @State private var showAssignDialog = false
    @State private var selectedIncidentId = 0

    private var currentUser: User? {
        if case .authenticated(let user, _) = authVM.userSession { return user }
        return nil
    }

    private var pendingVerification: Int { incidentVM.incidents.filter { $0.status == .pending }.count }
    private var activeOperations: Int { incidentVM.incidents.filter { $0.isActive }.count }
    private var criticalCount: Int { incidentVM.incidents.filter { $0.urgency == .critical }.count }
    private var resolvedCount: Int { incidentVM.incidents.filter { $0.status == .resolved }.count }

    private var filteredIncidents: [Incident] {
        switch selectedFilter {
        case "pending": return incidentVM.incidents.filter { $0.status == .pending }
        case "verified": return incidentVM.incidents.filter { $0.status == .verified }
        case "in_progress": return incidentVM.incidents.filter { $0.status == .inProgress }
        case "resolved": return incidentVM.incidents.filter { $0.status == .resolved }
        case "critical": return incidentVM.incidents.filter { $0.urgency == .critical || $0.urgency == .high }
        default: return incidentVM.incidents
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Stats row
            HStack(spacing: 6) {
                AuthorityStatChip(label: "Verify", count: pendingVerification, color: .oceanWarning)
                AuthorityStatChip(label: "Active", count: activeOperations, color: .oceanDanger)
                AuthorityStatChip(label: "Critical", count: criticalCount, color: .oceanDanger)
                AuthorityStatChip(label: "Resolved", count: resolvedCount, color: .oceanSuccess)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach([("all", "All"), ("pending", "Pending"), ("verified", "Verified"), ("in_progress", "In Progress"), ("critical", "Critical"), ("resolved", "Resolved")], id: \.0) { key, label in
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

            // Errors
            if let error = incidentVM.error {
                Text(error).font(.caption).foregroundStyle(Color.oceanDanger).padding(.horizontal)
            }

            // Content
            if incidentVM.isLoading && incidentVM.incidents.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if filteredIncidents.isEmpty {
                Spacer()
                ContentUnavailableView("No incidents found", systemImage: "checkmark.shield.fill")
                Spacer()
            } else {
                List(filteredIncidents, id: \.id) { incident in
                    AuthorityIncidentCardView(
                        incident: incident,
                        rescueTeams: adminVM.rescueTeams,
                        onViewDetail: { router.navigate(to: .incidentDetail(incidentId: incident.id)) },
                        onAssign: { selectedIncidentId = incident.id; showAssignDialog = true },
                        onVerify: { incidentVM.verifyIncident(id: incident.id) },
                        onDeploy: { incidentVM.deployResponse(id: incident.id) },
                        onResolve: { incidentVM.resolveIncident(id: incident.id) }
                    )
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Authority Console")
        .toolbar {
            ToolbarItem(placement: .compatTopBarTrailing) {
                Button { incidentVM.loadIncidents(filters: nil); adminVM.loadAllUsers() } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            incidentVM.loadIncidents(filters: nil)
            adminVM.loadAllUsers()
        }
        .sheet(isPresented: $showAssignDialog) {
            AssignIncidentSheet(
                rescueTeams: adminVM.rescueTeams,
                isLoading: incidentVM.assignState == .loading,
                onAssign: { userId in
                    incidentVM.assignIncident(incidentId: selectedIncidentId, rescueTeamUserId: userId)
                    showAssignDialog = false
                    incidentVM.loadIncidents(filters: nil)
                }
            )
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Authority Stat Chip

private struct AuthorityStatChip: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)").font(.title3.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Authority Incident Card

private struct AuthorityIncidentCardView: View {
    let incident: Incident
    let rescueTeams: [User]
    let onViewDetail: () -> Void
    let onAssign: () -> Void
    let onVerify: () -> Void
    let onDeploy: () -> Void
    let onResolve: () -> Void

    private var assignedTeamName: String? {
        guard let assignedId = incident.assignedToId else { return nil }
        return rescueTeams.first(where: { $0.id == assignedId }).map { $0.fullName } ?? "Team #\(assignedId)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(incident.referenceId).font(.caption).foregroundStyle(.secondary)
                Spacer()
                UrgencyBadge(urgency: incident.urgency)
                StatusBadge(status: incident.status)
            }

            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill").font(.caption).foregroundStyle(statusColor(incident.status))
                Text(incident.hazardType.displayName).font(.subheadline.weight(.semibold))
            }

            Label(incident.location, systemImage: "location").font(.caption).foregroundStyle(.secondary)

            if !incident.description.isEmpty {
                Text(String(incident.description.prefix(100)) + (incident.description.count > 100 ? "..." : ""))
                    .font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }

            if let team = assignedTeamName {
                Label("Assigned to: \(team)", systemImage: "person.fill.checkmark")
                    .font(.caption2.weight(.medium)).foregroundStyle(Color.oceanInfo)
            }

            Divider()

            HStack(spacing: 6) {
                Button("View", action: onViewDetail).font(.caption2).buttonStyle(.bordered).controlSize(.small)

                if incident.status != .resolved && incident.status != .closed {
                    Button(incident.assignedToId == nil ? "Assign" : "Reassign", action: onAssign)
                        .font(.caption2).buttonStyle(.borderedProminent).tint(Color.oceanPrimary).controlSize(.small)
                }

                Spacer()

                if incident.canBeVerified {
                    Button("Verify", action: onVerify).font(.caption2).buttonStyle(.borderedProminent).tint(Color.oceanInfo).controlSize(.small)
                } else if incident.canBeDeployed {
                    Button("Deploy", action: onDeploy).font(.caption2).buttonStyle(.borderedProminent).tint(Color.oceanWarning).controlSize(.small)
                } else if incident.canBeResolved {
                    Button("Resolve", action: onResolve).font(.caption2).buttonStyle(.borderedProminent).tint(Color.oceanSuccess).controlSize(.small)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func statusColor(_ status: IncidentStatus) -> Color {
        switch status {
        case .pending: return .oceanWarning
        case .verified: return .oceanInfo
        case .inProgress: return .oceanPrimary
        case .resolved: return .oceanSuccess
        case .closed: return .gray
        }
    }
}
