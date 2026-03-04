import SwiftUI

// MARK: - AdminDashboardScreen

struct AdminDashboardScreen: View {
    @Environment(AdminViewModel.self) private var viewModel
    @Environment(NavigationRouter.self) private var router

    @State private var showDeleteConfirm = false
    @State private var userToDelete: User?

    var body: some View {
        List {
            // Stats Overview
            Section("User Management") {
                HStack(spacing: 12) {
                    StatsCard(title: "Rescue Teams", value: "\(viewModel.rescueTeams.count)", icon: "cross.circle.fill", iconColor: .oceanPrimary)
                    StatsCard(title: "Authorities", value: "\(viewModel.authorities.count)", icon: "shield.fill", iconColor: .oceanWarning)
                    StatsCard(title: "Citizens", value: "\(viewModel.citizens.count)", icon: "person.2.fill", iconColor: .oceanSuccess)
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            // Quick Actions
            Section("Quick Actions") {
                HStack(spacing: 12) {
                    Button {
                        router.navigate(to: .createRescueTeam)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "person.badge.plus").font(.title2).foregroundStyle(Color.oceanPrimary)
                            Text("Add Rescue Team").font(.caption.weight(.medium)).foregroundStyle(Color.oceanPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.oceanPrimary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        router.navigate(to: .createAuthority)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "person.badge.plus").font(.title2).foregroundStyle(.orange)
                            Text("Add Authority").font(.caption.weight(.medium)).foregroundStyle(.orange)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            // Rescue Teams Section
            Section {
                if viewModel.isLoading && viewModel.rescueTeams.isEmpty {
                    ProgressView().frame(maxWidth: .infinity)
                } else if viewModel.rescueTeams.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2").font(.system(size: 48)).foregroundStyle(.tertiary)
                        Text("No rescue teams yet").foregroundStyle(.secondary)
                        Button("Add First Team") { router.navigate(to: .createRescueTeam) }
                            .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity).padding()
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.rescueTeams.prefix(5), id: \.id) { user in
                                UserCardCompact(user: user) {
                                    userToDelete = user
                                    showDeleteConfirm = true
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            } header: {
                HStack {
                    Text("Rescue Teams")
                    Spacer()
                    Button("View All") { router.navigate(to: .userManagement) }
                        .font(.caption)
                }
            }

            // Authorities Section
            Section {
                if viewModel.isLoading && viewModel.authorities.isEmpty {
                    ProgressView().frame(maxWidth: .infinity)
                } else if viewModel.authorities.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "shield").font(.system(size: 48)).foregroundStyle(.tertiary)
                        Text("No authorities yet").foregroundStyle(.secondary)
                        Button("Add First Authority") { router.navigate(to: .createAuthority) }
                            .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity).padding()
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.authorities.prefix(5), id: \.id) { user in
                                UserCardCompact(user: user) {
                                    userToDelete = user
                                    showDeleteConfirm = true
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            } header: {
                HStack {
                    Text("Authorities")
                    Spacer()
                    Button("View All") { router.navigate(to: .userManagement) }
                        .font(.caption)
                }
            }
        }
        .compatInsetGroupedListStyle()
        .navigationTitle("Admin Dashboard")
        .toolbar {
            ToolbarItem(placement: .compatTopBarTrailing) {
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
                Text("Are you sure you want to delete \(user.firstName) \(user.lastName)? This action cannot be undone.")
            }
        }
    }
}

// MARK: - User Card Compact

private struct UserCardCompact: View {
    let user: User
    let onDelete: () -> Void

    private var roleColor: Color {
        switch user.role {
        case .rescueTeam: return .oceanPrimary
        case .authority: return .orange
        default: return .oceanSuccess
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(user.firstName.prefix(1))\(user.lastName.prefix(1))")
                    .font(.headline.bold()).foregroundStyle(roleColor)
                    .frame(width: 40, height: 40)
                    .background(roleColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                Spacer()
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash").font(.caption)
                }
            }

            Text("\(user.firstName) \(user.lastName)").font(.subheadline.weight(.semibold)).lineLimit(1)
            Text(user.email).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            RoleBadge(role: user.role)
        }
        .padding()
        .frame(width: 200)
        .background(Color.compatSecondarySystemBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}
