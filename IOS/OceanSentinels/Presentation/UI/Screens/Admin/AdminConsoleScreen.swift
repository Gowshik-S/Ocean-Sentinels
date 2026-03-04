import SwiftUI

// MARK: - AdminConsoleScreen

struct AdminConsoleScreen: View {
    @Environment(IncidentViewModel.self) private var incidentVM
    @Environment(AdminViewModel.self) private var adminVM
    @Environment(AuthViewModel.self) private var authVM
    @Environment(NavigationRouter.self) private var router

    @State private var selectedTab = 0
    @State private var selectedFilter = "all"
    @State private var showAssignDialog = false
    @State private var selectedIncidentId = 0
    @State private var showCreateUserDialog = false
    @State private var createUserRole: UserRole = .rescueTeam

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("Tab", selection: $selectedTab) {
                Label("Incidents", systemImage: "exclamationmark.triangle").tag(0)
                Label("Users", systemImage: "person.2").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if selectedTab == 0 {
                adminIncidentsTab
            } else {
                adminUsersTab
            }
        }
        .navigationTitle("Admin Console")
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
        .sheet(isPresented: $showCreateUserDialog) {
            CreateUserSheet(
                role: createUserRole,
                adminVM: adminVM
            )
            .presentationDetents([.large])
        }
    }

    // MARK: - Incidents Tab

    private var filteredIncidents: [Incident] {
        let all = incidentVM.incidents
        switch selectedFilter {
        case "pending": return all.filter { $0.status == .pending }
        case "verified": return all.filter { $0.status == .verified }
        case "in_progress": return all.filter { $0.status == .inProgress }
        case "resolved": return all.filter { $0.status == .resolved }
        case "unassigned": return all.filter { $0.assignedToId == nil && $0.status != .resolved }
        default: return all
        }
    }

    private var adminIncidentsTab: some View {
        VStack(spacing: 0) {
            // Summary stats
            HStack(spacing: 8) {
                let pending = incidentVM.incidents.filter { $0.status == .pending }.count
                let active = incidentVM.incidents.filter { $0.isActive }.count
                let unassigned = incidentVM.incidents.filter { $0.assignedToId == nil && $0.status != .resolved }.count
                AdminStatChip(label: "Pending", count: pending, color: .oceanWarning)
                AdminStatChip(label: "Active", count: active, color: .oceanDanger)
                AdminStatChip(label: "Unassigned", count: unassigned, color: .oceanInfo)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach([("all", "All"), ("unassigned", "Unassigned"), ("pending", "Pending"), ("verified", "Verified"), ("in_progress", "In Progress"), ("resolved", "Resolved")], id: \.0) { key, label in
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

            // Error
            if let error = incidentVM.error {
                Text(error).font(.caption).foregroundStyle(Color.oceanDanger)
                    .padding(.horizontal).padding(.top, 4)
            }

            if incidentVM.isLoading && incidentVM.incidents.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if filteredIncidents.isEmpty {
                Spacer()
                ContentUnavailableView("No incidents found", systemImage: "checkmark.circle.fill")
                Spacer()
            } else {
                List(filteredIncidents, id: \.id) { incident in
                    AdminIncidentCardView(
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
    }

    // MARK: - Users Tab

    private var adminUsersTab: some View {
        List {
            // Quick actions
            Section {
                HStack(spacing: 12) {
                    Button {
                        createUserRole = .rescueTeam
                        showCreateUserDialog = true
                    } label: {
                        Label("Add Rescue Team", systemImage: "person.badge.plus")
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.oceanPrimary)

                    Button {
                        createUserRole = .authority
                        showCreateUserDialog = true
                    } label: {
                        Label("Add Authority", systemImage: "person.badge.plus")
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                }
            }

            // Rescue Teams
            Section("Rescue Teams (\(adminVM.rescueTeams.count))") {
                if adminVM.rescueTeams.isEmpty {
                    Text("No rescue teams created yet").foregroundStyle(.secondary)
                } else {
                    ForEach(adminVM.rescueTeams, id: \.id) { user in
                        UserManagementRow(user: user) {
                            adminVM.deleteUser(userId: user.id)
                        }
                    }
                }
            }

            // Authorities
            Section("Authorities (\(adminVM.authorities.count))") {
                if adminVM.authorities.isEmpty {
                    Text("No authorities created yet").foregroundStyle(.secondary)
                } else {
                    ForEach(adminVM.authorities, id: \.id) { user in
                        UserManagementRow(user: user) {
                            adminVM.deleteUser(userId: user.id)
                        }
                    }
                }
            }
        }
        .compatInsetGroupedListStyle()
        .refreshable { adminVM.loadAllUsers() }
    }
}

// MARK: - Admin Stat Chip

private struct AdminStatChip: View {
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

// MARK: - Admin Incident Card

private struct AdminIncidentCardView: View {
    let incident: Incident
    let rescueTeams: [User]
    let onViewDetail: () -> Void
    let onAssign: () -> Void
    let onVerify: () -> Void
    let onDeploy: () -> Void
    let onResolve: () -> Void

    private var assignedTeamName: String? {
        guard let assignedId = incident.assignedToId else { return nil }
        return rescueTeams.first(where: { $0.id == assignedId }).map { "\($0.firstName) \($0.lastName)" } ?? "Team #\(assignedId)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(incident.referenceId).font(.caption).foregroundStyle(.secondary)
                Spacer()
                StatusBadge(status: incident.status)
            }

            HStack(spacing: 4) {
                HazardTypeBadge(hazardType: incident.hazardType)
                UrgencyBadge(urgency: incident.urgency)
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
                Button("View", action: onViewDetail)
                    .font(.caption2).buttonStyle(.bordered).controlSize(.small)

                if incident.status != .resolved && incident.status != .closed {
                    Button(incident.assignedToId == nil ? "Assign" : "Reassign", action: onAssign)
                        .font(.caption2).buttonStyle(.borderedProminent).tint(Color.oceanPrimary).controlSize(.small)
                }

                Spacer()

                if incident.canBeVerified {
                    Button("Verify", action: onVerify)
                        .font(.caption2).buttonStyle(.borderedProminent).tint(Color.oceanInfo).controlSize(.small)
                } else if incident.canBeDeployed {
                    Button("Deploy", action: onDeploy)
                        .font(.caption2).buttonStyle(.borderedProminent).tint(Color.oceanWarning).controlSize(.small)
                } else if incident.canBeResolved {
                    Button("Resolve", action: onResolve)
                        .font(.caption2).buttonStyle(.borderedProminent).tint(Color.oceanSuccess).controlSize(.small)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - User Management Row

struct UserManagementRow: View {
    let user: User
    let onDelete: () -> Void
    @State private var showDeleteConfirm = false

    var body: some View {
        HStack {
            // Avatar
            Text("\(user.firstName.prefix(1))\(user.lastName.prefix(1))")
                .font(.caption.bold())
                .foregroundStyle(roleColor)
                .frame(width: 40, height: 40)
                .background(roleColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(user.firstName) \(user.lastName)").font(.subheadline.weight(.medium))
                Text(user.email).font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    RoleBadge(role: user.role)
                    if let location = user.location {
                        Text(location).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash").font(.caption)
            }
        }
        .alert("Delete User", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(user.firstName) \(user.lastName)? This action cannot be undone.")
        }
    }

    private var roleColor: Color {
        switch user.role {
        case .rescueTeam: return .oceanPrimary
        case .authority: return .purple
        case .admin: return .oceanDanger
        default: return .gray
        }
    }
}

// MARK: - Assign Incident Sheet

struct AssignIncidentSheet: View {
    let rescueTeams: [User]
    let isLoading: Bool
    let onAssign: (Int) -> Void

    @State private var selectedUserId: Int?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if rescueTeams.isEmpty {
                    Text("No rescue teams available. Create one first.").foregroundStyle(.secondary)
                } else {
                    Section("Select a rescue team member") {
                        ForEach(rescueTeams, id: \.id) { user in
                            Button {
                                selectedUserId = user.id
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("\(user.firstName) \(user.lastName)").font(.subheadline.weight(.medium)).foregroundStyle(.primary)
                                        Text(user.email).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if selectedUserId == user.id {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.oceanPrimary)
                                    }
                                }
                            }
                        }
                    }
                }

                if isLoading {
                    Section { ProgressView() }
                }
            }
            .navigationTitle("Assign to Team")
            .compatInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Assign") {
                        if let id = selectedUserId { onAssign(id) }
                    }
                    .disabled(selectedUserId == nil || isLoading)
                }
            }
        }
    }
}

// MARK: - Create User Sheet

struct CreateUserSheet: View {
    let role: UserRole
    @Bindable var adminVM: AdminViewModel

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var location = ""
    @Environment(\.dismiss) private var dismiss

    private var roleName: String { role == .rescueTeam ? "Rescue Team" : "Authority" }
    private var roleColor: Color { role == .rescueTeam ? .oceanPrimary : .purple }

    private var isFormValid: Bool {
        !username.isEmpty && !email.isEmpty && password.count >= 6 && !firstName.isEmpty && !lastName.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: role == .rescueTeam ? "cross.circle.fill" : "shield.fill")
                            .font(.title).foregroundStyle(roleColor)
                        VStack(alignment: .leading) {
                            Text("\(roleName) Member").font(.headline).foregroundStyle(roleColor)
                            Text(role == .rescueTeam ? "Can verify incidents and deploy responses" : "Can oversee incidents and view analytics")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Account Details") {
                    OceanTextField(label: "First Name", text: $firstName, icon: "person")
                    OceanTextField(label: "Last Name", text: $lastName, icon: "person")
                    OceanTextField(label: "Username", text: $username, icon: "person.circle")
                    OceanEmailField(text: $email, label: "Email")
                    OceanPhoneField(text: $phone, label: "Phone (optional)")
                    OceanLocationField(text: $location, label: "Location (optional)", onGetLocation: { })
                    OceanPasswordField(label: "Password", text: $password)
                }

                if let error = adminVM.createUserError {
                    Section {
                        Label(error, systemImage: "exclamationmark.circle.fill").foregroundStyle(Color.oceanDanger).font(.caption)
                    }
                }
            }
            .navigationTitle("Create \(roleName)")
            .compatInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let p = phone.isEmpty ? nil : phone
                        let l = location.isEmpty ? nil : location
                        if role == .rescueTeam {
                            adminVM.createRescueTeam(username: username, email: email, password: password, firstName: firstName, lastName: lastName, phone: p, location: l)
                        } else {
                            adminVM.createAuthority(username: username, email: email, password: password, firstName: firstName, lastName: lastName, phone: p, location: l)
                        }
                    }
                    .disabled(!isFormValid || adminVM.isCreatingUser)
                }
            }
        }
    }
}
