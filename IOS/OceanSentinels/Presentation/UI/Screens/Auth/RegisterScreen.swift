import SwiftUI

// MARK: - RegisterScreen

/// Registration screen with Public/Authority toggle, form fields, coastal region picker.
struct RegisterScreen: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isPublicMode = true
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var location = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreeTerms = false
    @State private var subscribeAlerts = false
    @State private var inviteCode = ""

    private let coastalRegions = [
        "Chennai, Tamil Nadu",
        "Mumbai, Maharashtra",
        "Kochi, Kerala",
        "Visakhapatnam, Andhra Pradesh",
        "Goa",
        "Mangalore, Karnataka",
        "Kolkata, West Bengal",
        "Paradip, Odisha",
        "Tuticorin, Tamil Nadu",
        "Puducherry"
    ]

    private var passwordsMatch: Bool { password == confirmPassword }
    private var isFormValid: Bool {
        !email.isEmpty && !firstName.isEmpty && !lastName.isEmpty &&
        password.count >= 6 && passwordsMatch && agreeTerms &&
        (isPublicMode || !inviteCode.isEmpty)
    }

    var body: some View {
        @Bindable var authVM = authViewModel

        VStack(spacing: 0) {
            // Header
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

            ScrollView {
                VStack(spacing: 16) {
                    Text("Create New Account")
                        .font(.headline)
                        .padding(.top, 20)

                    // Public / Authority toggle
                    HStack(spacing: 16) {
                        registrationTypeCard(
                            title: "Public Registration",
                            subtitle: "For citizens and general public",
                            icon: "person.2.fill",
                            color: Color.oceanPrimary,
                            isSelected: isPublicMode
                        ) { isPublicMode = true }

                        registrationTypeCard(
                            title: "Authority Registration",
                            subtitle: "Contact administrator for access",
                            icon: "gearshape.fill",
                            color: Color.oceanWarning,
                            isSelected: !isPublicMode
                        ) { isPublicMode = false }
                    }

                    // Invite code (authority only)
                    if !isPublicMode {
                        OceanTextField(label: "Invite Code", text: $inviteCode, placeholder: "Enter your invite code", icon: "key.fill")
                    }

                    // Name fields
                    HStack(spacing: 12) {
                        OceanTextField(label: "First Name", text: $firstName, placeholder: "Enter first name", icon: "person.fill")
                        OceanTextField(label: "Last Name", text: $lastName, placeholder: "Enter last name", icon: "person.fill")
                    }

                    OceanEmailField(text: $email)
                    OceanPhoneField(text: $phone)

                    // Location picker
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Location", systemImage: "location.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Picker("Select your coastal region", selection: $location) {
                            Text("Select your coastal region").tag("")
                            ForEach(coastalRegions, id: \.self) { region in
                                Text(region).tag(region)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 6))
                    }

                    // Password fields
                    HStack(spacing: 12) {
                        OceanPasswordField(
                            label: "Password",
                            text: $password,
                            isError: !password.isEmpty && password.count < 6,
                            errorMessage: password.count < 6 && !password.isEmpty ? "Min 6 characters" : nil
                        )
                        OceanPasswordField(
                            label: "Confirm Password",
                            text: $confirmPassword,
                            isError: !confirmPassword.isEmpty && !passwordsMatch,
                            errorMessage: !confirmPassword.isEmpty && !passwordsMatch ? "Passwords don't match" : nil
                        )
                    }

                    // Terms
                    Toggle(isOn: $agreeTerms) {
                        Text("I agree to the **Terms of Service** and **Privacy Policy**")
                            .font(.caption)
                    }
                    .toggleStyle(.switch)
                    .tint(Color.oceanPrimary)

                    Toggle(isOn: $subscribeAlerts) {
                        Text("Subscribe to safety alerts and updates")
                            .font(.caption)
                    }
                    .toggleStyle(.switch)
                    .tint(Color.oceanPrimary)

                    // Error
                    if case .error(let message) = authVM.registerState {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text(message).font(.caption)
                        }
                        .foregroundStyle(Color.oceanDanger)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.oceanDanger.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    }

                    // Sign in link
                    HStack {
                        Text("Already have an account?")
                            .foregroundStyle(.secondary)
                        Button("Sign In") { dismiss() }
                            .foregroundStyle(Color.oceanSecondary)
                    }
                    .font(.subheadline)
                }
                .padding(.horizontal, 26)
            }

            // Create Account button
            OceanPrimaryButton(
                text: "Create Account",
                action: {
                    authViewModel.register(
                        username: email.components(separatedBy: "@").first ?? email,
                        email: email,
                        password: password,
                        firstName: firstName,
                        lastName: lastName,
                        phone: phone.isEmpty ? nil : phone,
                        location: location.isEmpty ? nil : location
                    )
                },
                isEnabled: isFormValid && authVM.registerState != .loading,
                isLoading: authVM.registerState == .loading,
                icon: "person.badge.plus"
            )
            .padding(.horizontal, 26)
            .padding(.vertical, 12)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: authVM.registerState) { _, newState in
            if case .success = newState {
                dismiss()
            }
        }
    }

    @ViewBuilder
    private func registrationTypeCard(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? color : .secondary)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.05) : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? color : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
