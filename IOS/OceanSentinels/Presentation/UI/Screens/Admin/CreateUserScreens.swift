import SwiftUI

// MARK: - CreateRescueTeamScreen

struct CreateRescueTeamScreen: View {
    @Environment(AdminViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var username = ""
    @State private var email = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var location = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var passwordVisible = false

    private var passwordsMatch: Bool { password == confirmPassword }
    private var isFormValid: Bool {
        !username.isEmpty && !email.isEmpty && !firstName.isEmpty && !lastName.isEmpty && password.count >= 6 && passwordsMatch
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Info card
                HStack(spacing: 16) {
                    Image(systemName: "cross.circle.fill").font(.largeTitle).foregroundStyle(Color.oceanPrimary)
                    VStack(alignment: .leading) {
                        Text("Rescue Team Member").font(.headline).foregroundStyle(Color.oceanPrimary)
                        Text("Can verify incidents and deploy responses").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.oceanPrimary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

                CreateUserFormFields(
                    username: $username, email: $email, firstName: $firstName, lastName: $lastName,
                    phone: $phone, location: $location, password: $password, confirmPassword: $confirmPassword,
                    passwordVisible: $passwordVisible, passwordsMatch: passwordsMatch
                )

                if let error = viewModel.createUserError {
                    Label(error, systemImage: "exclamationmark.circle.fill")
                        .font(.caption).foregroundStyle(Color.oceanDanger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                OceanPrimaryButton(
                    text: "Create Rescue Team Member",
                    action: {
                        viewModel.createRescueTeam(
                            username: username, email: email, password: password,
                            firstName: firstName, lastName: lastName,
                            phone: phone.isEmpty ? nil : phone,
                            location: location.isEmpty ? nil : location
                        )
                    },
                    isEnabled: isFormValid && !viewModel.isCreatingUser,
                    isLoading: viewModel.isCreatingUser,
                    icon: "person.badge.plus"
                )
            }
            .padding()
        }
        .navigationTitle("Add Rescue Team")
    }
}

// MARK: - CreateAuthorityScreen

struct CreateAuthorityScreen: View {
    @Environment(AdminViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var username = ""
    @State private var email = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var location = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var passwordVisible = false

    private var passwordsMatch: Bool { password == confirmPassword }
    private var isFormValid: Bool {
        !username.isEmpty && !email.isEmpty && !firstName.isEmpty && !lastName.isEmpty && password.count >= 6 && passwordsMatch
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Info card
                HStack(spacing: 16) {
                    Image(systemName: "shield.fill").font(.largeTitle).foregroundStyle(.orange)
                    VStack(alignment: .leading) {
                        Text("Authority Member").font(.headline).foregroundStyle(.orange)
                        Text("Can oversee incidents and view analytics").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

                CreateUserFormFields(
                    username: $username, email: $email, firstName: $firstName, lastName: $lastName,
                    phone: $phone, location: $location, password: $password, confirmPassword: $confirmPassword,
                    passwordVisible: $passwordVisible, passwordsMatch: passwordsMatch
                )

                if let error = viewModel.createUserError {
                    Label(error, systemImage: "exclamationmark.circle.fill")
                        .font(.caption).foregroundStyle(Color.oceanDanger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                OceanPrimaryButton(
                    text: "Create Authority Member",
                    action: {
                        viewModel.createAuthority(
                            username: username, email: email, password: password,
                            firstName: firstName, lastName: lastName,
                            phone: phone.isEmpty ? nil : phone,
                            location: location.isEmpty ? nil : location
                        )
                    },
                    isEnabled: isFormValid && !viewModel.isCreatingUser,
                    isLoading: viewModel.isCreatingUser,
                    icon: "person.badge.plus"
                )
            }
            .padding()
        }
        .navigationTitle("Add Authority")
    }
}

// MARK: - Shared Form Fields

struct CreateUserFormFields: View {
    @Binding var username: String
    @Binding var email: String
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var phone: String
    @Binding var location: String
    @Binding var password: String
    @Binding var confirmPassword: String
    @Binding var passwordVisible: Bool
    let passwordsMatch: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                OceanTextField(label: "First Name *", text: $firstName, icon: "person")
                OceanTextField(label: "Last Name *", text: $lastName, icon: "person")
            }
            OceanTextField(label: "Username *", text: $username, icon: "person.circle")
            OceanEmailField(text: $email, label: "Email *")
            OceanPhoneField(text: $phone, label: "Phone (optional)")
            OceanLocationField(text: $location, label: "Location (optional)", onGetLocation: { })

            OceanPasswordField(label: "Password *", text: $password)
            if !password.isEmpty && password.count < 6 {
                Text("Password must be at least 6 characters")
                    .font(.caption2).foregroundStyle(Color.oceanDanger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            OceanPasswordField(label: "Confirm Password *", text: $confirmPassword)
            if !confirmPassword.isEmpty && !passwordsMatch {
                Text("Passwords do not match")
                    .font(.caption2).foregroundStyle(Color.oceanDanger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
