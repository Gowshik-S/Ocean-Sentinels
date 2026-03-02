import SwiftUI

// MARK: - ProfileScreen

struct ProfileScreen: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(NavigationRouter.self) private var router

    private var currentUser: User? {
        if case .authenticated(let user, _) = authVM.userSession { return user }
        return nil
    }

    var body: some View {
        ScrollView {
            if let user = currentUser {
                VStack(spacing: 0) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Avatar
                        Text("\(user.firstName.prefix(1))\(user.lastName.prefix(1))")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(Color.oceanPrimary)
                            .frame(width: 100, height: 100)
                            .background(Color.oceanPrimary.opacity(0.1), in: Circle())

                        Text("\(user.firstName) \(user.lastName)")
                            .font(.title2.bold())
                        Text("@\(user.username)")
                            .font(.subheadline).foregroundStyle(.secondary)
                        RoleBadge(role: user.role)
                    }
                    .padding(24)

                    Divider().padding(.horizontal)

                    // Profile Details
                    VStack(spacing: 4) {
                        ProfileDetailItem(icon: "envelope.fill", label: "Email", value: user.email)
                        if let phone = user.phone {
                            ProfileDetailItem(icon: "phone.fill", label: "Phone", value: phone)
                        }
                        if let location = user.location {
                            ProfileDetailItem(icon: "location.fill", label: "Location", value: location)
                        }
                        ProfileDetailItem(icon: "number", label: "User ID", value: "#\(user.id)")
                    }
                    .padding()

                    Divider().padding(.horizontal)

                    // Account Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Account").font(.headline)

                        ProfileActionItem(icon: "gearshape.fill", title: "Settings", subtitle: "App preferences and notifications") {
                            router.navigate(to: .settings)
                        }
                        ProfileActionItem(icon: "questionmark.circle.fill", title: "Help & Support", subtitle: "FAQs and contact support") {}
                        ProfileActionItem(icon: "info.circle.fill", title: "About", subtitle: "App version and legal info") {}
                    }
                    .padding()

                    // Logout
                    OceanDangerButton(text: "Sign Out", action: {
                        authVM.logout()
                    }, icon: "rectangle.portrait.and.arrow.right")
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { router.navigate(to: .settings) } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
    }
}

// MARK: - Profile Detail Item

private struct ProfileDetailItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon).foregroundStyle(Color.oceanPrimary).frame(width: 24)
            VStack(alignment: .leading) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.body)
            }
            Spacer()
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Profile Action Item

private struct ProfileActionItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon).foregroundStyle(.secondary).frame(width: 24)
                VStack(alignment: .leading) {
                    Text(title).font(.body).foregroundStyle(.primary)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
        }
    }
}
