import SwiftUI

// MARK: - IncidentsDashboardScreen

struct IncidentsDashboardScreen: View {
    @Environment(IncidentViewModel.self) private var viewModel
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(AdminViewModel.self) private var adminViewModel

    @State private var showFilterSheet = false
    @State private var showAssignDialog = false
    @State private var selectedIncidentId = 0

    private var currentUser: User? {
        if case .authenticated(let user, _) = authViewModel.userSession { return user }
        return nil
    }
    private var userRole: UserRole { currentUser?.role ?? .`public` }
    private var isCitizen: Bool { userRole == .`public` }
    private var canAssign: Bool { userRole == .admin || userRole == .authority }

    var body: some View {
        @Bindable var vm = viewModel

        Group {
            if viewModel.isLoading && viewModel.incidents.isEmpty {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error, viewModel.incidents.isEmpty {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Try Again") { viewModel.loadIncidents(filters: nil) }
                }
            } else if viewModel.incidents.isEmpty {
                ContentUnavailableView {
                    Label("No Incidents", systemImage: "magnifyingglass")
                } description: {
                    Text("No incidents match your current filters.")
                } actions: {
                    if viewModel.filters.status != nil || viewModel.filters.hazardType != nil {
                        Button("Clear Filters") { viewModel.clearFilters() }
                    }
                }
            } else {
                incidentList
            }
        }
        .navigationTitle(isCitizen ? "My Incidents" : "Incidents Dashboard")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 8) {
                    Button { showFilterSheet = true } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                    Button { viewModel.loadIncidents() } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheet(
                currentFilters: viewModel.filters,
                onApply: { filters in
                    viewModel.loadIncidents(filters: filters)
                    showFilterSheet = false
                },
                onClear: {
                    viewModel.clearFilters()
                    showFilterSheet = false
                }
            )
        }
        .alert("Assign to Rescue Team", isPresented: $showAssignDialog) {
            ForEach(adminViewModel.rescueTeams, id: \.id) { team in
                Button(team.fullName) { viewModel.assignIncident(incidentId: selectedIncidentId, rescueTeamUserId: team.id) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Select a rescue team to assign this incident to.")
        }
        .task {
            viewModel.loadIncidents(filters: nil)
            if canAssign { adminViewModel.loadAllUsers() }
        }
        .onChange(of: viewModel.assignState) { _, newState in
            if case .success = newState {
                showAssignDialog = false
                viewModel.resetAssignState()
                viewModel.loadIncidents()
            }
        }
    }

    private var incidentList: some View {
        List {
            ForEach(viewModel.incidents, id: \.id) { incident in
                NavigationLink(value: AppRoute.incidentDetail(incidentId: incident.id)) {
                    IncidentCardView(
                        incident: incident,
                        canAssign: canAssign && incident.assignedToId == nil && incident.status != .resolved,
                        onVerify: incident.status == .pending ? { viewModel.verifyIncident(id: incident.id) } : nil,
                        onDeploy: incident.status == .verified ? { viewModel.deployResponse(id: incident.id) } : nil,
                        onResolve: incident.status == .inProgress ? { viewModel.resolveIncident(id: incident.id) } : nil,
                        onAssign: {
                            selectedIncidentId = incident.id
                            showAssignDialog = true
                        }
                    )
                }
            }

            if viewModel.hasMorePages {
                Button {
                    viewModel.loadMoreIncidents()
                } label: {
                    if viewModel.isLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Load More").frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - IncidentCardView

struct IncidentCardView: View {
    let incident: Incident
    var canAssign: Bool = false
    var onVerify: (() -> Void)?
    var onDeploy: (() -> Void)?
    var onResolve: (() -> Void)?
    var onAssign: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(incident.hazardType.displayName).font(.subheadline.weight(.semibold)).lineLimit(2)
                    Text("ID: \(incident.referenceId)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(status: incident.status)
            }

            Text(incident.description).font(.caption).foregroundStyle(.secondary).lineLimit(2)

            HStack(spacing: 8) {
                HazardTypeBadge(hazardType: incident.hazardType)
                UrgencyBadge(urgency: incident.urgency)
            }

            HStack {
                Label(incident.location.isEmpty ? "\(String(format: "%.4f", incident.latitude ?? 0)), \(String(format: "%.4f", incident.longitude ?? 0))" : incident.location, systemImage: "location")
                    .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                Spacer()
                Label(incident.createdAt.relativeDisplay, systemImage: "clock")
                    .font(.caption2).foregroundStyle(.secondary)
            }

            // Action buttons
            if onVerify != nil || onDeploy != nil || onResolve != nil || canAssign {
                Divider()
                HStack(spacing: 8) {
                    if canAssign, let onAssign {
                        Button(action: onAssign) {
                            Label("Assign", systemImage: "person.badge.plus").font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        .tint(.oceanWarning)
                    }
                    if let onVerify {
                        Button(action: onVerify) {
                            Label("Verify", systemImage: "checkmark.seal").font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        .tint(.oceanInfo)
                    }
                    if let onDeploy {
                        Button(action: onDeploy) {
                            Label("Deploy", systemImage: "shippingbox").font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        .tint(.oceanPrimary)
                    }
                    if let onResolve {
                        Button(action: onResolve) {
                            Label("Resolve", systemImage: "checkmark.circle").font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        .tint(.oceanSuccess)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - FilterSheet

private struct FilterSheet: View {
    let currentFilters: IncidentFilters
    let onApply: (IncidentFilters) -> Void
    let onClear: () -> Void

    @State private var selectedStatus: IncidentStatus?
    @State private var selectedUrgency: UrgencyLevel?
    @State private var searchQuery = ""
    @Environment(\.dismiss) private var dismiss

    init(currentFilters: IncidentFilters, onApply: @escaping (IncidentFilters) -> Void, onClear: @escaping () -> Void) {
        self.currentFilters = currentFilters
        self.onApply = onApply
        self.onClear = onClear
        _selectedStatus = State(initialValue: currentFilters.status)
        _selectedUrgency = State(initialValue: currentFilters.urgency)
        _searchQuery = State(initialValue: currentFilters.searchQuery ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Search") {
                    TextField("Search incidents...", text: $searchQuery)
                }
                Section("Status") {
                    ForEach(IncidentStatus.allCases, id: \.self) { status in
                        Button {
                            selectedStatus = selectedStatus == status ? nil : status
                        } label: {
                            HStack {
                                Text(status.value.replacingOccurrences(of: "_", with: " ").capitalized)
                                Spacer()
                                if selectedStatus == status {
                                    Image(systemName: "checkmark").foregroundStyle(Color.oceanPrimary)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
                Section("Urgency") {
                    ForEach(UrgencyLevel.allCases, id: \.self) { urgency in
                        Button {
                            selectedUrgency = selectedUrgency == urgency ? nil : urgency
                        } label: {
                            HStack {
                                Text(urgency.value.capitalized)
                                Spacer()
                                if selectedUrgency == urgency {
                                    Image(systemName: "checkmark").foregroundStyle(Color.oceanPrimary)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("Filter Incidents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") { onClear() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply(IncidentFilters(
                            status: selectedStatus,
                            hazardType: nil,
                            urgency: selectedUrgency,
                            searchQuery: searchQuery.isEmpty ? nil : searchQuery
                        ))
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Date Helper

extension Date {
    var relativeDisplay: String {
        let diff = Date().timeIntervalSince(self)
        let minutes = diff / 60
        let hours = minutes / 60
        let days = hours / 24
        switch true {
        case days > 30: return self.formatted(.dateTime.month(.abbreviated).day().year())
        case days > 1: return "\(Int(days)) days ago"
        case days >= 1: return "Yesterday"
        case hours > 1: return "\(Int(hours)) hours ago"
        case hours >= 1: return "1 hour ago"
        case minutes > 1: return "\(Int(minutes)) minutes ago"
        default: return "Just now"
        }
    }
}
