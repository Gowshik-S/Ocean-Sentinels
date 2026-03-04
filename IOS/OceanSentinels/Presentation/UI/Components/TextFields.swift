import SwiftUI

// MARK: - OceanTextField

/// Ocean-themed text field.
struct OceanTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var icon: String?
    var isError: Bool = false
    var errorMessage: String?
    var isEnabled: Bool = true
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                }
                TextField(label, text: $text, prompt: Text(placeholder), axis: axis)
                    .disabled(!isEnabled)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isError ? Color.oceanDanger : Color.compatSystemGray4,
                        lineWidth: 1
                    )
            )

            if isError, let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color.oceanDanger)
            }
        }
    }
}

// MARK: - OceanPasswordField

/// Password field with visibility toggle.
struct OceanPasswordField: View {
    let label: String
    @Binding var text: String
    var isError: Bool = false
    var errorMessage: String?
    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                if isVisible {
                    TextField(label, text: $text)
                } else {
                    SecureField(label, text: $text)
                }

                Button {
                    isVisible.toggle()
                } label: {
                    Image(systemName: isVisible ? "eye.fill" : "eye.slash.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isError ? Color.oceanDanger : Color.compatSystemGray4,
                        lineWidth: 1
                    )
            )

            if isError, let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color.oceanDanger)
            }
        }
    }
}

// MARK: - OceanSearchField

/// Search text field.
struct OceanSearchField: View {
    @Binding var text: String
    var placeholder: String = "Search..."

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color.compatSystemGray6, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - OceanEmailField

struct OceanEmailField: View {
    @Binding var text: String
    var label: String = "Email"
    var isError: Bool = false
    var errorMessage: String?

    var body: some View {
        OceanTextField(
            label: label,
            text: $text,
            placeholder: "email@example.com",
            icon: "envelope.fill",
            isError: isError,
            errorMessage: errorMessage
        )
        .compatEmailInputModifiers()
        .autocorrectionDisabled()
    }
}

// MARK: - OceanPhoneField

struct OceanPhoneField: View {
    @Binding var text: String
    var label: String = "Phone Number"
    var isError: Bool = false
    var errorMessage: String?

    var body: some View {
        OceanTextField(
            label: label,
            text: $text,
            placeholder: "+1 234 567 8900",
            icon: "phone.fill",
            isError: isError,
            errorMessage: errorMessage
        )
        .compatPhoneInputModifiers()
    }
}

// MARK: - OceanTextArea

struct OceanTextArea: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var isError: Bool = false
    var errorMessage: String?

    var body: some View {
        OceanTextField(
            label: label,
            text: $text,
            placeholder: placeholder,
            isError: isError,
            errorMessage: errorMessage,
            axis: .vertical
        )
        .frame(minHeight: 80)
    }
}

// MARK: - OceanLocationField

struct OceanLocationField: View {
    @Binding var text: String
    var label: String = "Location"
    var isLoading: Bool = false
    var onGetLocation: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "location.fill")
                .foregroundStyle(.secondary)
                .frame(width: 20)
            TextField(label, text: $text, prompt: Text("Enter location or use GPS"))
            if isLoading {
                ProgressView()
            } else {
                Button(action: onGetLocation) {
                    Image(systemName: "location.circle.fill")
                        .foregroundStyle(Color.oceanPrimary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.compatSystemGray4, lineWidth: 1)
        )
    }
}
