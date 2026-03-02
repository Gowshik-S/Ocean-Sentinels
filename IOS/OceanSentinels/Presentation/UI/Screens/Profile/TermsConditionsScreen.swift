import SwiftUI

// MARK: - TermsConditionsScreen

struct TermsConditionsScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Ocean Sentinels")
                    .font(.title.bold())
                    .foregroundStyle(Color.oceanPrimary)

                Text("Terms of Service & Privacy Policy")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("Last Updated: February 14, 2026")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 20)
                    .padding(.bottom, 24)

                TermsSection(
                    title: "1. Acceptance of Terms",
                    content: "By downloading, installing, or using the Ocean Sentinels mobile application (the \"App\"), you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use the App. Ocean Sentinels reserves the right to modify these terms at any time, and your continued use of the App constitutes acceptance of any changes."
                )

                TermsSection(
                    title: "2. Description of Service",
                    content: "Ocean Sentinels is a coastal safety monitoring and incident reporting platform designed to help communities report, track, and respond to ocean-related hazards including but not limited to coastal flooding, cyclones, water pollution, erosion, tsunami warnings, and severe weather events. The App facilitates communication between citizens, rescue teams, and government authorities."
                )

                TermsSection(
                    title: "3. User Accounts",
                    content: "To use certain features of the App, you must create an account. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You agree to provide accurate, current, and complete information during registration. Users under the age of 13 are not permitted to create accounts."
                )

                TermsSection(
                    title: "4. User Roles & Responsibilities",
                    content: """
                    The App supports multiple user roles:

                    - Citizen (Public): Can report incidents, view alerts, and access weather information.
                    - Rescue Team: Can view and respond to assigned incidents, update incident status.
                    - Authority: Can verify and oversee incidents, approve deployments.
                    - Administrator: Has full system access including user management.

                    Each role has specific permissions and responsibilities. Misuse of elevated privileges may result in account suspension.
                    """
                )

                TermsSection(
                    title: "5. Incident Reporting",
                    content: "When reporting an incident, you agree to provide truthful and accurate information. Filing false or misleading reports is strictly prohibited and may result in account termination and potential legal consequences. Reported incidents are reviewed by authorities and rescue teams for verification and response coordination."
                )

                TermsSection(
                    title: "6. Location Data",
                    content: "The App may collect and use your device's location data to provide location-based services such as weather alerts, nearby incident reporting, and mapping features. You can control location access through your device settings. Location data is used solely for the purpose of providing App services and is not shared with third parties for advertising purposes."
                )

                TermsSection(
                    title: "7. Privacy & Data Collection",
                    content: """
                    We collect the following types of information:

                    - Account information (name, email, phone number)
                    - Location data (GPS coordinates when permitted)
                    - Incident reports and associated media
                    - Device information for push notifications
                    - Usage analytics for service improvement

                    We do not sell your personal data. Data is stored securely using industry-standard encryption and is retained only as long as necessary to provide our services.
                    """
                )

                TermsSection(
                    title: "8. Push Notifications",
                    content: "By enabling push notifications, you agree to receive alerts regarding weather warnings, incident updates, assignment notifications, and system announcements. You can disable notifications at any time through the App settings or your device settings."
                )

                TermsSection(
                    title: "9. Limitation of Liability",
                    content: "Ocean Sentinels is provided \"as is\" without warranties of any kind. While we strive for accuracy, we do not guarantee the timeliness, completeness, or accuracy of weather data, incident reports, or other information provided through the App. The App is not a substitute for official emergency services. In case of immediate danger, always contact local emergency services directly."
                )

                TermsSection(
                    title: "10. Intellectual Property",
                    content: "All content, features, and functionality of the App, including but not limited to text, graphics, logos, icons, and software, are the property of Ocean Sentinels and are protected by applicable intellectual property laws. You may not copy, modify, distribute, or create derivative works without prior written consent."
                )

                TermsSection(
                    title: "11. Termination",
                    content: "We reserve the right to suspend or terminate your account at any time for violations of these Terms, abusive behavior, or any other reason at our sole discretion. Upon termination, your right to use the App will immediately cease."
                )

                TermsSection(
                    title: "12. Contact Information",
                    content: """
                    For questions about these Terms & Conditions, please contact us at:

                    Email: support@oceansentinels.com
                    Website: www.oceansentinels.com
                    """
                )

                Text("By using Ocean Sentinels, you acknowledge that you have read, understood, and agree to these Terms & Conditions.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.oceanPrimary)
                    .padding(.top, 16)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("Terms & Conditions")
    }
}

// MARK: - Terms Section

private struct TermsSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.bold())
            Text(content).font(.subheadline).foregroundStyle(.secondary).lineSpacing(4)
        }
        .padding(.bottom, 20)
    }
}
