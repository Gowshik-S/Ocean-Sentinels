import SwiftUI

// MARK: - LoginScreen

/// Login screen with Ocean Sentinels Portal header, demo accounts, and form fields.
struct LoginScreen: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(NavigationRouter.self) private var router

    @State private var username = ""
    @State private var password = ""
    @State private var rememberMe = false
    @State private var showDemoAccounts = false

    var body: some View {
        @Bindable var authVM = authViewModel

        VStack(spacing: 0) {
            // Yellow header
            VStack(spacing: 4) {
                Text("Ocean Sentinels Portal")
                    .font(.title2.weight(.semibold))
                Text("Secure access to India's coastal safety network")
                    .font(.subheadline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 24)
            .background(Color.oceanPrimary)

            // Form content
            ScrollView {
                VStack(spacing: 0) {
                    Text("Sign in to your Account")
                        .font(.headline)
                        .padding(.top, 32)

                    // Username field
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Username or Email", systemImage: "person.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("Enter your username or email", text: $username)
                            #if os(iOS)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            #endif
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color.compatSystemGray6, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .padding(.top, 40)

                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Password", systemImage: "lock.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        OceanPasswordField(label: "Enter your password", text: $password)
                    }
                    .padding(.top, 24)

                    // Remember me row
                    HStack {
                        Toggle(isOn: $rememberMe) {
                            Text("Remember")
                                .font(.subheadline)
                        }
                        .toggleStyle(.switch)
                        .tint(Color.oceanPrimary)

                        Spacer()

                        Button("Forgot Password?") {}
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .padding(.top, 12)

                    // Error
                    if case .error(let message) = authVM.loginState {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text(message)
                                .font(.caption)
                        }
                        .foregroundStyle(Color.oceanDanger)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.oceanDanger.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        .padding(.top, 8)
                    }

                    // Sign In button
                    OceanPrimaryButton(
                        text: "Sign In",
                        action: { authViewModel.login(username: username, password: password) },
                        isEnabled: !username.isEmpty && !password.isEmpty && authVM.loginState != .loading,
                        isLoading: authVM.loginState == .loading
                    )
                    .padding(.top, 28)

                    // Demo accounts toggle
                    Button {
                        withAnimation { showDemoAccounts.toggle() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: showDemoAccounts ? "chevron.up" : "chevron.down")
                            Text("Quick Demo Access")
                        }
                        .font(.subheadline)
                    }
                    .padding(.top, 20)

                    if showDemoAccounts {
                        VStack(spacing: 12) {
                            Text("Demo Accounts")
                                .font(.subheadline.weight(.semibold))

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                DemoRoleButton(text: "Citizen", icon: "person.fill", color: .oceanSuccess) {
                                    authViewModel.demoLogin(role: .public)
                                }
                                DemoRoleButton(text: "Admin", icon: "gearshape.fill", color: .oceanDanger) {
                                    authViewModel.demoLogin(role: .admin)
                                }
                                DemoRoleButton(text: "Rescue", icon: "cross.case.fill", color: .oceanPrimary) {
                                    authViewModel.demoLogin(role: .rescueTeam)
                                }
                                DemoRoleButton(text: "Authority", icon: "shield.fill", color: .orange) {
                                    authViewModel.demoLogin(role: .authority)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.compatSystemGray6.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                        .padding(.top, 8)
                    }

                    // Register link
                    HStack {
                        Text("Don't have an account?")
                            .foregroundStyle(.secondary)
                        Button("Sign Up") {
                            router.authPath.append(AuthRoute.register)
                        }
                        .foregroundStyle(Color.oceanSecondary)
                    }
                    .font(.subheadline)
                    .padding(.top, 32)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 30)
            }
        }
    }
}
