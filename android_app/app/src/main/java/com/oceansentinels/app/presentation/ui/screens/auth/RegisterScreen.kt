package com.oceansentinels.app.presentation.ui.screens.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.oceansentinels.app.presentation.ui.theme.OceanColors
import com.oceansentinels.app.presentation.viewmodel.AuthViewModel
import com.oceansentinels.app.presentation.viewmodel.RegisterState

/**
 * Registration screen - matches Figma design
 * Centered header, Public/Authority tab toggle,
 * form fields, location dropdown, checkboxes, yellow Create Account button
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RegisterScreen(
    onNavigateToLogin: () -> Unit,
    onNavigateToHome: () -> Unit,
    viewModel: AuthViewModel = hiltViewModel()
) {
    val registerState by viewModel.registerState.collectAsState()

    var isPublicMode by remember { mutableStateOf(true) }
    var firstName by remember { mutableStateOf("") }
    var lastName by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    var location by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var passwordVisible by remember { mutableStateOf(false) }
    var agreeTerms by remember { mutableStateOf(false) }
    var subscribeAlerts by remember { mutableStateOf(false) }
    var inviteCode by remember { mutableStateOf("") }
    var locationExpanded by remember { mutableStateOf(false) }

    val coastalRegions = listOf(
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
    )

    val passwordsMatch = password == confirmPassword
    val isFormValid = email.isNotBlank() &&
            firstName.isNotBlank() &&
            lastName.isNotBlank() &&
            password.length >= 6 &&
            passwordsMatch &&
            agreeTerms &&
            (isPublicMode || inviteCode.isNotBlank())

    LaunchedEffect(registerState) {
        if (registerState is RegisterState.Success) {
            onNavigateToHome()
            viewModel.resetRegisterState()
        }
    }

    val scrollState = rememberScrollState()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .navigationBarsPadding()
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            // Yellow header - centered
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(OceanColors.PrimaryDark)
                    .statusBarsPadding()
                    .padding(horizontal = 24.dp, vertical = 20.dp),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "Ocean Sentinels Portal",
                        style = MaterialTheme.typography.headlineSmall,
                        color = OceanColors.TextPrimary,
                        textAlign = TextAlign.Center
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "Secure access to India's coastal safety network",
                        style = MaterialTheme.typography.bodyMedium,
                        color = OceanColors.TextPrimary,
                        textAlign = TextAlign.Center
                    )
                }
            }

            // Main form
            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(scrollState)
                    .padding(horizontal = 26.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Spacer(modifier = Modifier.height(20.dp))

                Text(
                    text = "Create New Account",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onBackground,
                    fontWeight = FontWeight.SemiBold
                )

                Spacer(modifier = Modifier.height(20.dp))

                // Public / Authority toggle tabs
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // Public Registration
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .border(
                                width = if (isPublicMode) 2.dp else 1.dp,
                                color = if (isPublicMode) OceanColors.Primary else OceanColors.PlaceholderGray,
                                shape = RoundedCornerShape(12.dp)
                            )
                            .background(
                                if (isPublicMode) OceanColors.Primary.copy(alpha = 0.05f) else Color.Transparent,
                                RoundedCornerShape(12.dp)
                            )
                            .clickable { isPublicMode = true }
                            .padding(vertical = 16.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Icon(
                                Icons.Default.People,
                                contentDescription = null,
                                modifier = Modifier.size(28.dp),
                                tint = if (isPublicMode) OceanColors.Primary else OceanColors.TextSecondary
                            )
                            Spacer(modifier = Modifier.height(6.dp))
                            Text(
                                text = "Public Registration",
                                style = MaterialTheme.typography.labelMedium,
                                fontWeight = FontWeight.SemiBold,
                                color = if (isPublicMode) MaterialTheme.colorScheme.onBackground else OceanColors.TextSecondary
                            )
                            Text(
                                text = "For citizens and general public",
                                style = MaterialTheme.typography.labelSmall,
                                color = OceanColors.TextSecondary,
                                textAlign = TextAlign.Center
                            )
                        }
                    }

                    // Authority Registration
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .border(
                                width = if (!isPublicMode) 2.dp else 1.dp,
                                color = if (!isPublicMode) OceanColors.Warning else OceanColors.PlaceholderGray,
                                shape = RoundedCornerShape(12.dp)
                            )
                            .background(
                                if (!isPublicMode) OceanColors.Warning.copy(alpha = 0.05f) else Color.Transparent,
                                RoundedCornerShape(12.dp)
                            )
                            .clickable { isPublicMode = false }
                            .padding(vertical = 16.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Icon(
                                Icons.Default.AdminPanelSettings,
                                contentDescription = null,
                                modifier = Modifier.size(28.dp),
                                tint = if (!isPublicMode) OceanColors.Warning else OceanColors.TextSecondary
                            )
                            Spacer(modifier = Modifier.height(6.dp))
                            Text(
                                text = "Authority Registration",
                                style = MaterialTheme.typography.labelMedium,
                                fontWeight = FontWeight.SemiBold,
                                color = if (!isPublicMode) MaterialTheme.colorScheme.onBackground else OceanColors.TextSecondary
                            )
                            Text(
                                text = "Contact administrator for access",
                                style = MaterialTheme.typography.labelSmall,
                                color = OceanColors.TextSecondary,
                                textAlign = TextAlign.Center
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Authority invite code
                if (!isPublicMode) {
                    FieldLabel(icon = Icons.Default.VpnKey, label = "Invite Code", tint = OceanColors.Warning)
                    Spacer(modifier = Modifier.height(6.dp))
                    FormTextField(
                        value = inviteCode,
                        onValueChange = { inviteCode = it },
                        placeholder = "Enter your invite code",
                        focusColor = OceanColors.Warning
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                }

                // First Name / Last Name
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        FieldLabel(icon = Icons.Default.Person, label = "First Name")
                        Spacer(modifier = Modifier.height(6.dp))
                        FormTextField(
                            value = firstName,
                            onValueChange = { firstName = it },
                            placeholder = "Enter first name"
                        )
                    }
                    Column(modifier = Modifier.weight(1f)) {
                        FieldLabel(icon = Icons.Default.Person, label = "Last Name")
                        Spacer(modifier = Modifier.height(6.dp))
                        FormTextField(
                            value = lastName,
                            onValueChange = { lastName = it },
                            placeholder = "Enter last name"
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Email
                FieldLabel(icon = Icons.Default.Email, label = "Email Address")
                Spacer(modifier = Modifier.height(6.dp))
                FormTextField(
                    value = email,
                    onValueChange = { email = it },
                    placeholder = "Enter your email",
                    keyboardType = KeyboardType.Email
                )

                Spacer(modifier = Modifier.height(16.dp))

                // Phone
                FieldLabel(icon = Icons.Default.Phone, label = "Phone Number")
                Spacer(modifier = Modifier.height(6.dp))
                FormTextField(
                    value = phone,
                    onValueChange = { phone = it },
                    placeholder = "Enter your phone number",
                    keyboardType = KeyboardType.Phone
                )

                Spacer(modifier = Modifier.height(16.dp))

                // Location dropdown
                FieldLabel(icon = Icons.Default.LocationOn, label = "Location")
                Spacer(modifier = Modifier.height(6.dp))
                ExposedDropdownMenuBox(
                    expanded = locationExpanded,
                    onExpandedChange = { locationExpanded = !locationExpanded }
                ) {
                    OutlinedTextField(
                        value = location.ifBlank { "Select your coastal region" },
                        onValueChange = {},
                        readOnly = true,
                        singleLine = true,
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = locationExpanded) },
                        modifier = Modifier.fillMaxWidth().menuAnchor(),
                        shape = RoundedCornerShape(6.dp),
                        colors = OutlinedTextFieldDefaults.colors(
                            unfocusedContainerColor = OceanColors.PlaceholderGray,
                            focusedContainerColor = OceanColors.PlaceholderGray,
                            unfocusedBorderColor = Color.Transparent,
                            focusedBorderColor = OceanColors.Primary
                        )
                    )
                    ExposedDropdownMenu(
                        expanded = locationExpanded,
                        onDismissRequest = { locationExpanded = false }
                    ) {
                        coastalRegions.forEach { region ->
                            DropdownMenuItem(
                                text = { Text(region) },
                                onClick = {
                                    location = region
                                    locationExpanded = false
                                }
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Password / Confirm
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        FieldLabel(icon = Icons.Default.Lock, label = "Password")
                        Spacer(modifier = Modifier.height(6.dp))
                        OutlinedTextField(
                            value = password,
                            onValueChange = { password = it },
                            placeholder = { Text("Create password", style = MaterialTheme.typography.bodyMedium, color = OceanColors.TextHint) },
                            visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                            trailingIcon = {
                                IconButton(onClick = { passwordVisible = !passwordVisible }) {
                                    Icon(
                                        if (passwordVisible) Icons.Default.Visibility else Icons.Default.VisibilityOff,
                                        contentDescription = null,
                                        modifier = Modifier.size(18.dp)
                                    )
                                }
                            },
                            singleLine = true,
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(6.dp),
                            isError = password.isNotEmpty() && password.length < 6,
                            colors = OutlinedTextFieldDefaults.colors(
                                unfocusedContainerColor = OceanColors.PlaceholderGray,
                                focusedContainerColor = OceanColors.PlaceholderGray,
                                unfocusedBorderColor = Color.Transparent,
                                focusedBorderColor = OceanColors.Primary
                            )
                        )
                    }
                    Column(modifier = Modifier.weight(1f)) {
                        FieldLabel(icon = Icons.Default.Lock, label = "Confirm Password")
                        Spacer(modifier = Modifier.height(6.dp))
                        OutlinedTextField(
                            value = confirmPassword,
                            onValueChange = { confirmPassword = it },
                            placeholder = { Text("Confirm password", style = MaterialTheme.typography.bodyMedium, color = OceanColors.TextHint) },
                            visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                            singleLine = true,
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(6.dp),
                            isError = confirmPassword.isNotEmpty() && !passwordsMatch,
                            colors = OutlinedTextFieldDefaults.colors(
                                unfocusedContainerColor = OceanColors.PlaceholderGray,
                                focusedContainerColor = OceanColors.PlaceholderGray,
                                unfocusedBorderColor = Color.Transparent,
                                focusedBorderColor = OceanColors.Primary
                            )
                        )
                    }
                }

                if (password.isNotEmpty() && password.length < 6) {
                    Spacer(modifier = Modifier.height(4.dp))
                    Text("Password must be at least 6 characters", style = MaterialTheme.typography.labelSmall, color = OceanColors.Error)
                }
                if (confirmPassword.isNotEmpty() && !passwordsMatch) {
                    Spacer(modifier = Modifier.height(4.dp))
                    Text("Passwords do not match", style = MaterialTheme.typography.labelSmall, color = OceanColors.Error)
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Terms checkbox
                Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Checkbox(
                        checked = agreeTerms,
                        onCheckedChange = { agreeTerms = it },
                        colors = CheckboxDefaults.colors(checkedColor = OceanColors.Primary, uncheckedColor = OceanColors.PlaceholderGray, checkmarkColor = MaterialTheme.colorScheme.onPrimary),
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Text("I agree to the ", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onBackground)
                    Text("Terms of Service", style = MaterialTheme.typography.labelSmall, color = OceanColors.Secondary, fontWeight = FontWeight.SemiBold)
                    Text(" and ", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onBackground)
                    Text("Privacy Policy", style = MaterialTheme.typography.labelSmall, color = OceanColors.Secondary, fontWeight = FontWeight.SemiBold)
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Subscribe checkbox
                Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Checkbox(
                        checked = subscribeAlerts,
                        onCheckedChange = { subscribeAlerts = it },
                        colors = CheckboxDefaults.colors(checkedColor = OceanColors.Primary, uncheckedColor = OceanColors.PlaceholderGray, checkmarkColor = MaterialTheme.colorScheme.onPrimary),
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Text("Subscribe to safety alerts and updates", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onBackground)
                }

                // Error
                if (registerState is RegisterState.Error) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Card(
                        colors = CardDefaults.cardColors(containerColor = OceanColors.Error.copy(alpha = 0.1f)),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(modifier = Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Error, contentDescription = null, tint = OceanColors.Error)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text((registerState as RegisterState.Error).message, color = OceanColors.Error, style = MaterialTheme.typography.bodySmall)
                        }
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Already have an account?", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    TextButton(onClick = onNavigateToLogin) {
                        Text("Sign In", color = OceanColors.Secondary)
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))
            }

            // Bottom Create Account button
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(MaterialTheme.colorScheme.background)
                    .padding(horizontal = 26.dp, vertical = 12.dp)
            ) {
                Button(
                    onClick = {
                        viewModel.register(
                            username = email.substringBefore("@"),
                            email = email,
                            password = password,
                            firstName = firstName,
                            lastName = lastName,
                            phone = phone.takeIf { it.isNotBlank() },
                            location = location.takeIf { it.isNotBlank() }
                        )
                    },
                    modifier = Modifier.fillMaxWidth().height(48.dp),
                    enabled = isFormValid && registerState !is RegisterState.Loading,
                    shape = RoundedCornerShape(8.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = OceanColors.Primary,
                        contentColor = OceanColors.OnPrimary,
                        disabledContainerColor = OceanColors.Primary.copy(alpha = 0.5f),
                        disabledContentColor = OceanColors.OnPrimary.copy(alpha = 0.5f)
                    ),
                    elevation = ButtonDefaults.buttonElevation(defaultElevation = 2.dp)
                ) {
                    if (registerState is RegisterState.Loading) {
                        CircularProgressIndicator(modifier = Modifier.size(20.dp), color = OceanColors.OnPrimary, strokeWidth = 2.dp)
                    } else {
                        Icon(Icons.Default.PersonAdd, contentDescription = null, modifier = Modifier.size(20.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Create Account", style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}

// Helper composables for form fields
@Composable
private fun FieldLabel(
    icon: androidx.compose.ui.graphics.vector.ImageVector? = null,
    emoji: String? = null,
    label: String,
    tint: Color = OceanColors.TextSecondary
) {
    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
        if (emoji != null) {
            Text(emoji, style = MaterialTheme.typography.bodyMedium)
        } else if (icon != null) {
            Icon(icon, contentDescription = null, modifier = Modifier.size(19.dp), tint = tint)
        }
        Spacer(modifier = Modifier.width(6.dp))
        Text(label, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onBackground)
    }
}

@Composable
private fun FormTextField(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    keyboardType: KeyboardType = KeyboardType.Text,
    focusColor: Color = OceanColors.Primary
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        placeholder = { Text(placeholder, style = MaterialTheme.typography.bodyMedium, color = OceanColors.TextHint) },
        singleLine = true,
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(6.dp),
        colors = OutlinedTextFieldDefaults.colors(
            unfocusedContainerColor = OceanColors.PlaceholderGray,
            focusedContainerColor = OceanColors.PlaceholderGray,
            unfocusedBorderColor = Color.Transparent,
            focusedBorderColor = focusColor
        ),
        keyboardOptions = KeyboardOptions(keyboardType = keyboardType)
    )
}
