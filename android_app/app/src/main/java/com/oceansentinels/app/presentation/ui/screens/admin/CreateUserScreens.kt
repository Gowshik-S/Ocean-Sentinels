package com.oceansentinels.app.presentation.ui.screens.admin

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.oceansentinels.app.presentation.ui.components.*
import com.oceansentinels.app.presentation.ui.theme.OceanColors
import com.oceansentinels.app.presentation.viewmodel.AdminViewModel
import com.oceansentinels.app.presentation.viewmodel.CreateUserState

/**
 * Create Rescue Team screen
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateRescueTeamScreen(
    onNavigateBack: () -> Unit,
    onCreateSuccess: () -> Unit = onNavigateBack,
    viewModel: AdminViewModel = hiltViewModel()
) {
    val createUserState by viewModel.createUserState.collectAsState()
    
    var username by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var firstName by remember { mutableStateOf("") }
    var lastName by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    var location by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var passwordVisible by remember { mutableStateOf(false) }
    
    val passwordsMatch = password == confirmPassword
    val isFormValid = username.isNotBlank() && 
                      email.isNotBlank() && 
                      firstName.isNotBlank() && 
                      lastName.isNotBlank() && 
                      password.length >= 6 && 
                      passwordsMatch
    
    // Handle success
    LaunchedEffect(createUserState) {
        if (createUserState is CreateUserState.Success) {
            onCreateSuccess()
            viewModel.resetCreateUserState()
        }
    }
    
    val scrollState = rememberScrollState()
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Add Rescue Team") },
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
                .padding(horizontal = 16.dp)
                .verticalScroll(scrollState)
        ) {
            Spacer(modifier = Modifier.height(16.dp))
            
            // Info card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = OceanColors.Primary.copy(alpha = 0.1f)
                )
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.LocalHospital,
                        contentDescription = null,
                        tint = OceanColors.Primary,
                        modifier = Modifier.size(32.dp)
                    )
                    Spacer(modifier = Modifier.width(16.dp))
                    Column {
                        Text(
                            text = "Rescue Team Member",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = OceanColors.Primary
                        )
                        Text(
                            text = "Can verify incidents and deploy responses",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Form fields
            CreateUserForm(
                username = username,
                onUsernameChange = { username = it },
                email = email,
                onEmailChange = { email = it },
                firstName = firstName,
                onFirstNameChange = { firstName = it },
                lastName = lastName,
                onLastNameChange = { lastName = it },
                phone = phone,
                onPhoneChange = { phone = it },
                location = location,
                onLocationChange = { location = it },
                password = password,
                onPasswordChange = { password = it },
                confirmPassword = confirmPassword,
                onConfirmPasswordChange = { confirmPassword = it },
                passwordVisible = passwordVisible,
                onPasswordVisibilityChange = { passwordVisible = it },
                passwordsMatch = passwordsMatch
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Error message
            if (createUserState is CreateUserState.Error) {
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = OceanColors.Danger.copy(alpha = 0.1f)
                    ),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier.padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Default.Error, contentDescription = null, tint = OceanColors.Danger)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = (createUserState as CreateUserState.Error).message,
                            color = OceanColors.Danger,
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Submit button
            OceanPrimaryButton(
                text = "Create Rescue Team Member",
                onClick = {
                    viewModel.createRescueTeam(
                        username = username,
                        email = email,
                        password = password,
                        firstName = firstName,
                        lastName = lastName,
                        phone = phone.takeIf { it.isNotBlank() },
                        location = location.takeIf { it.isNotBlank() }
                    )
                },
                isLoading = createUserState is CreateUserState.Loading,
                enabled = isFormValid,
                modifier = Modifier.fillMaxWidth(),
                icon = Icons.Default.PersonAdd
            )
            
            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

/**
 * Create Authority screen
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateAuthorityScreen(
    onNavigateBack: () -> Unit,
    onCreateSuccess: () -> Unit = onNavigateBack,
    viewModel: AdminViewModel = hiltViewModel()
) {
    val createUserState by viewModel.createUserState.collectAsState()
    
    var username by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var firstName by remember { mutableStateOf("") }
    var lastName by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    var location by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var passwordVisible by remember { mutableStateOf(false) }
    
    val passwordsMatch = password == confirmPassword
    val isFormValid = username.isNotBlank() && 
                      email.isNotBlank() && 
                      firstName.isNotBlank() && 
                      lastName.isNotBlank() && 
                      password.length >= 6 && 
                      passwordsMatch
    
    // Handle success
    LaunchedEffect(createUserState) {
        if (createUserState is CreateUserState.Success) {
            onCreateSuccess()
            viewModel.resetCreateUserState()
        }
    }
    
    val scrollState = rememberScrollState()
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Add Authority") },
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
                .padding(horizontal = 16.dp)
                .verticalScroll(scrollState)
        ) {
            Spacer(modifier = Modifier.height(16.dp))
            
            // Info card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = OceanColors.Warning.copy(alpha = 0.1f)
                )
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Shield,
                        contentDescription = null,
                        tint = OceanColors.Warning,
                        modifier = Modifier.size(32.dp)
                    )
                    Spacer(modifier = Modifier.width(16.dp))
                    Column {
                        Text(
                            text = "Authority Member",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = OceanColors.Warning
                        )
                        Text(
                            text = "Can oversee incidents and view analytics",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Form fields
            CreateUserForm(
                username = username,
                onUsernameChange = { username = it },
                email = email,
                onEmailChange = { email = it },
                firstName = firstName,
                onFirstNameChange = { firstName = it },
                lastName = lastName,
                onLastNameChange = { lastName = it },
                phone = phone,
                onPhoneChange = { phone = it },
                location = location,
                onLocationChange = { location = it },
                password = password,
                onPasswordChange = { password = it },
                confirmPassword = confirmPassword,
                onConfirmPasswordChange = { confirmPassword = it },
                passwordVisible = passwordVisible,
                onPasswordVisibilityChange = { passwordVisible = it },
                passwordsMatch = passwordsMatch
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Error message
            if (createUserState is CreateUserState.Error) {
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = OceanColors.Danger.copy(alpha = 0.1f)
                    ),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier.padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Default.Error, contentDescription = null, tint = OceanColors.Danger)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = (createUserState as CreateUserState.Error).message,
                            color = OceanColors.Danger,
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Submit button
            OceanPrimaryButton(
                text = "Create Authority Member",
                onClick = {
                    viewModel.createAuthority(
                        username = username,
                        email = email,
                        password = password,
                        firstName = firstName,
                        lastName = lastName,
                        phone = phone.takeIf { it.isNotBlank() },
                        location = location.takeIf { it.isNotBlank() }
                    )
                },
                isLoading = createUserState is CreateUserState.Loading,
                enabled = isFormValid,
                modifier = Modifier.fillMaxWidth(),
                icon = Icons.Default.PersonAdd
            )
            
            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@Composable
private fun CreateUserForm(
    username: String,
    onUsernameChange: (String) -> Unit,
    email: String,
    onEmailChange: (String) -> Unit,
    firstName: String,
    onFirstNameChange: (String) -> Unit,
    lastName: String,
    onLastNameChange: (String) -> Unit,
    phone: String,
    onPhoneChange: (String) -> Unit,
    location: String,
    onLocationChange: (String) -> Unit,
    password: String,
    onPasswordChange: (String) -> Unit,
    confirmPassword: String,
    onConfirmPasswordChange: (String) -> Unit,
    passwordVisible: Boolean,
    onPasswordVisibilityChange: (Boolean) -> Unit,
    passwordsMatch: Boolean
) {
    // Name row
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        OutlinedTextField(
            value = firstName,
            onValueChange = onFirstNameChange,
            label = { Text("First Name *") },
            leadingIcon = { Icon(Icons.Default.Person, contentDescription = null) },
            singleLine = true,
            modifier = Modifier.weight(1f),
            shape = MaterialTheme.shapes.medium
        )
        
        OutlinedTextField(
            value = lastName,
            onValueChange = onLastNameChange,
            label = { Text("Last Name *") },
            singleLine = true,
            modifier = Modifier.weight(1f),
            shape = MaterialTheme.shapes.medium
        )
    }
    
    Spacer(modifier = Modifier.height(16.dp))
    
    // Username
    OutlinedTextField(
        value = username,
        onValueChange = onUsernameChange,
        label = { Text("Username *") },
        leadingIcon = { Icon(Icons.Default.AccountCircle, contentDescription = null) },
        singleLine = true,
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.medium
    )
    
    Spacer(modifier = Modifier.height(16.dp))
    
    // Email
    OutlinedTextField(
        value = email,
        onValueChange = onEmailChange,
        label = { Text("Email *") },
        leadingIcon = { Icon(Icons.Default.Email, contentDescription = null) },
        singleLine = true,
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.medium,
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email)
    )
    
    Spacer(modifier = Modifier.height(16.dp))
    
    // Phone
    OutlinedTextField(
        value = phone,
        onValueChange = onPhoneChange,
        label = { Text("Phone (Optional)") },
        leadingIcon = { Icon(Icons.Default.Phone, contentDescription = null) },
        singleLine = true,
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.medium,
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone)
    )
    
    Spacer(modifier = Modifier.height(16.dp))
    
    // Location
    OutlinedTextField(
        value = location,
        onValueChange = onLocationChange,
        label = { Text("Location (Optional)") },
        leadingIcon = { Icon(Icons.Default.LocationOn, contentDescription = null) },
        singleLine = true,
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.medium
    )
    
    Spacer(modifier = Modifier.height(16.dp))
    
    // Password
    OutlinedTextField(
        value = password,
        onValueChange = onPasswordChange,
        label = { Text("Password *") },
        leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null) },
        trailingIcon = {
            IconButton(onClick = { onPasswordVisibilityChange(!passwordVisible) }) {
                Icon(
                    imageVector = if (passwordVisible) Icons.Default.Visibility else Icons.Default.VisibilityOff,
                    contentDescription = if (passwordVisible) "Hide" else "Show"
                )
            }
        },
        visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
        singleLine = true,
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.medium,
        isError = password.isNotEmpty() && password.length < 6,
        supportingText = if (password.isNotEmpty() && password.length < 6) {
            { Text("Password must be at least 6 characters") }
        } else null
    )
    
    Spacer(modifier = Modifier.height(16.dp))
    
    // Confirm Password
    OutlinedTextField(
        value = confirmPassword,
        onValueChange = onConfirmPasswordChange,
        label = { Text("Confirm Password *") },
        leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null) },
        visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
        singleLine = true,
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.medium,
        isError = confirmPassword.isNotEmpty() && !passwordsMatch,
        supportingText = if (confirmPassword.isNotEmpty() && !passwordsMatch) {
            { Text("Passwords do not match") }
        } else null
    )
}
