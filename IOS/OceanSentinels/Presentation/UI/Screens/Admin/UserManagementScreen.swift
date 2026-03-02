import SwiftUI

// MARK: - UserManagementScreen

struct UserManagementScreen: View {
    @Environment(AdminViewModel.self) private var viewModel

    @State private var selectedTab = 0
    @State private var searchQuery = ""
    @State private var showDeleteConfirm = false
    @State private var userToDelete: User?

    private let tabs = ["All", "Rescue Teams", "Authorities", "Citizens"]

    private var filteredUsers: [User] {
        let base: [User] = {
            switch selectedTab {
            case 1: return viewModel.rescueTeams
            case 2: return viewModel.authorities
            case 3: return viewModel.citizens
            default: return viewModel.allUsers
            }
        }()

        guard !searchQuery.isEmpty else { return base }
        return base.filter {
            $0.username.localizedCaseInsensitiveContains(searchQuery) ||
            $0.email.localizedCaseInsensitiveContains(searchQuery) ||
            "\($0.firstName) \($0.lastName)".localizedCaseInsensitiveContains(searchQuery)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            OceanSearchField(text: $searchQuery, placeholder: "Search users...")
                .padding(.horizontal)
                .padding(.vertical, 8)

            // Tabs
            Picker("Filter", selection: $selectedTab) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    let count: Int = {
                        switch index {
                        case 1: return viewModel.rescueTeams.count
                        case 2: return viewModel.authorities.count
                        case 3: return viewModel.citizens.count
                        default: return viewModel.allUsers.count
                        }
                    }()
                    Text("\(tabs[index]) (\(count))").tag(index)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Content
            if viewModel.isLoading && viewModel.allUsers.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if let error = viewModel.error {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.circle").font(.system(size: 48)).foregroundStyle(Color.oceanDanger)
                    Text(error).foregroundStyle(Color.oceanDanger)
                    Button("Retry") { viewModel.loadAllUsers() }
                        .buttonStyle(.borderedProminent)
                }
                Spacer()
            } else if filteredUsers.isEmpty {
                Spacer()
                ContentUnavailableView(
                    searchQuery.isEmpty ? "No Users Found" : "No Results",
                    systemImage: "person.slash",
                    description: Text(searchQuery.isEmpty ? "There are no users in this category" : "No users match your search")
                )
                Spacer()
            } else {
                List(filteredUsers, id: \.id) { user in
                    UserManagementCardView(user: user) {
                        userToDelete = user
                        showDeleteConfirm = true
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("User Management")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { viewModel.loadAllUsers() } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task { viewModel.loadAllUsers() }
        .alert("Delete User", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let user = userToDelete {
                    viewModel.deleteUser(userId: user.id)
                }
                userToDelete = nil
            }
            Button("Cancel", role: .cancel) { userToDelete = nil }
        } message: {
            if let user = userToDelete {
                Text("Are you sure you want to delete \(user.firstName) \(user.lastName)?\n\n\(user.email)\n\nThis action cannot be undone.")
            }
        }
    }
}

// MARK: - User Management Card

private struct UserManagementCardView: View {
    let user: User
    let onDelete: () -> Void

    private var roleColor: Color {
        switch user.role {
        case .admin: return .oceanDanger
        case .authority: return .orange
        case .rescueTeam: return .oceanSuccess
        default: return .oceanPrimary
        }
    }

    private var roleIcon: String {
        switch user.role {
        case .admin: return "person.badge.shield.checkmark"
        case .authority: return "shield.fill"
        case .rescueTeam: return "cross.circle.fill"
        default: return "person.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Image(systemName: roleIcon)
                .font(.title3).foregroundStyle(roleColor)
                .frame(width: 48, height: 48)
                .background(roleColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("\(user.firstName) \(user.lastName)").font(.subheadline.weight(.semibold))
                    RoleBadge(role: user.role)
                }
                Text("@\(user.username)").font(.caption).foregroundStyle(.secondary)
                Text(user.email).font(.caption2).foregroundStyle(.secondary)
                if let phone = user.phone {
                    Text(phone).font(.caption2).foregroundStyle(.secondary)
                }
            }

            Spacer()

            if user.role != .admin {
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
            }
        }
        .padding(.vertical, 4)
    }
}
