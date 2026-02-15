package com.oceansentinels.app.presentation.ui.screens.profile

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.oceansentinels.app.presentation.ui.theme.OceanColors

/**
 * Terms & Conditions screen
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TermsConditionsScreen(
    onNavigateBack: () -> Unit
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Terms & Conditions") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp, vertical = 16.dp)
        ) {
            Text(
                text = "Ocean Sentinels",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = OceanColors.Primary
            )
            
            Text(
                text = "Terms of Service & Privacy Policy",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Spacer(modifier = Modifier.height(20.dp))
            
            Text(
                text = "Last Updated: February 14, 2026",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Spacer(modifier = Modifier.height(24.dp))
            
            TermsSection(
                title = "1. Acceptance of Terms",
                content = "By downloading, installing, or using the Ocean Sentinels mobile application (the \"App\"), you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use the App. Ocean Sentinels reserves the right to modify these terms at any time, and your continued use of the App constitutes acceptance of any changes."
            )
            
            TermsSection(
                title = "2. Description of Service",
                content = "Ocean Sentinels is a coastal safety monitoring and incident reporting platform designed to help communities report, track, and respond to ocean-related hazards including but not limited to coastal flooding, cyclones, water pollution, erosion, tsunami warnings, and severe weather events. The App facilitates communication between citizens, rescue teams, and government authorities."
            )
            
            TermsSection(
                title = "3. User Accounts",
                content = "To use certain features of the App, you must create an account. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You agree to provide accurate, current, and complete information during registration. Users under the age of 13 are not permitted to create accounts."
            )
            
            TermsSection(
                title = "4. User Roles & Responsibilities",
                content = "The App supports multiple user roles:\n\n" +
                        "- Citizen (Public): Can report incidents, view alerts, and access weather information.\n" +
                        "- Rescue Team: Can view and respond to assigned incidents, update incident status.\n" +
                        "- Authority: Can verify and oversee incidents, approve deployments.\n" +
                        "- Administrator: Has full system access including user management.\n\n" +
                        "Each role has specific permissions and responsibilities. Misuse of elevated privileges may result in account suspension."
            )
            
            TermsSection(
                title = "5. Incident Reporting",
                content = "When reporting an incident, you agree to provide truthful and accurate information. Filing false or misleading reports is strictly prohibited and may result in account termination and potential legal consequences. Reported incidents are reviewed by authorities and rescue teams for verification and response coordination."
            )
            
            TermsSection(
                title = "6. Location Data",
                content = "The App may collect and use your device's location data to provide location-based services such as weather alerts, nearby incident reporting, and mapping features. You can control location access through your device settings. Location data is used solely for the purpose of providing App services and is not shared with third parties for advertising purposes."
            )
            
            TermsSection(
                title = "7. Privacy & Data Collection",
                content = "We collect the following types of information:\n\n" +
                        "- Account information (name, email, phone number)\n" +
                        "- Location data (GPS coordinates when permitted)\n" +
                        "- Incident reports and associated media\n" +
                        "- Device information for push notifications\n" +
                        "- Usage analytics for service improvement\n\n" +
                        "We do not sell your personal data. Data is stored securely using industry-standard encryption and is retained only as long as necessary to provide our services."
            )
            
            TermsSection(
                title = "8. Push Notifications",
                content = "By enabling push notifications, you agree to receive alerts regarding weather warnings, incident updates, assignment notifications, and system announcements. You can disable notifications at any time through the App settings or your device settings."
            )
            
            TermsSection(
                title = "9. Limitation of Liability",
                content = "Ocean Sentinels is provided \"as is\" without warranties of any kind. While we strive for accuracy, we do not guarantee the timeliness, completeness, or accuracy of weather data, incident reports, or other information provided through the App. The App is not a substitute for official emergency services. In case of immediate danger, always contact local emergency services directly."
            )
            
            TermsSection(
                title = "10. Intellectual Property",
                content = "All content, features, and functionality of the App, including but not limited to text, graphics, logos, icons, and software, are the property of Ocean Sentinels and are protected by applicable intellectual property laws. You may not copy, modify, distribute, or create derivative works without prior written consent."
            )
            
            TermsSection(
                title = "11. Termination",
                content = "We reserve the right to suspend or terminate your account at any time for violations of these Terms, abusive behavior, or any other reason at our sole discretion. Upon termination, your right to use the App will immediately cease."
            )
            
            TermsSection(
                title = "12. Contact Information",
                content = "For questions about these Terms & Conditions, please contact us at:\n\n" +
                        "Email: support@oceansentinels.com\n" +
                        "Website: www.oceansentinels.com"
            )
            
            Spacer(modifier = Modifier.height(32.dp))
            
            Text(
                text = "By using Ocean Sentinels, you acknowledge that you have read, understood, and agree to these Terms & Conditions.",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                color = OceanColors.Primary
            )
            
            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@Composable
private fun TermsSection(
    title: String,
    content: String
) {
    Column(
        modifier = Modifier.padding(bottom = 20.dp)
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onBackground
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = content,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            lineHeight = MaterialTheme.typography.bodyMedium.lineHeight
        )
    }
}
