package com.oceansentinels.app.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.oceansentinels.app.domain.model.*
import com.oceansentinels.app.domain.repository.AuthRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

/**
 * ViewModel for authentication-related operations
 */
@HiltViewModel
class AuthViewModel @Inject constructor(
    private val authRepository: AuthRepository
) : ViewModel() {

    // User session state
    val userSession: StateFlow<UserSession> = authRepository.getUserSession()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = UserSession.Loading
        )

    // Login state
    private val _loginState = MutableStateFlow<LoginState>(LoginState.Idle)
    val loginState: StateFlow<LoginState> = _loginState.asStateFlow()

    // Register state
    private val _registerState = MutableStateFlow<RegisterState>(RegisterState.Idle)
    val registerState: StateFlow<RegisterState> = _registerState.asStateFlow()

    // Current user
    private val _currentUser = MutableStateFlow<User?>(null)
    val currentUser: StateFlow<User?> = _currentUser.asStateFlow()

    init {
        observeUserSession()
    }

    private fun observeUserSession() {
        viewModelScope.launch {
            userSession.collect { session ->
                when (session) {
                    is UserSession.Authenticated -> {
                        _currentUser.value = session.user
                    }
                    else -> {
                        _currentUser.value = null
                    }
                }
            }
        }
    }

    /**
     * Login with username and password
     */
    fun login(username: String, password: String) {
        viewModelScope.launch {
            _loginState.value = LoginState.Loading
            
            val result = authRepository.login(
                LoginCredentials(username = username, password = password)
            )
            
            result.fold(
                onSuccess = { authToken ->
                    Timber.d("Login successful for user: ${authToken.user.username}")
                    _loginState.value = LoginState.Success(authToken.user)
                },
                onFailure = { error ->
                    Timber.e(error, "Login failed")
                    _loginState.value = LoginState.Error(error.message ?: "Login failed")
                }
            )
        }
    }

    /**
     * Demo login for testing
     */
    fun demoLogin(role: UserRole) {
        viewModelScope.launch {
            _loginState.value = LoginState.Loading
            
            val demoUser = when (role) {
                UserRole.PUBLIC -> LoginCredentials("sihcitizen@vi.com", "SIH@2025")
                UserRole.ADMIN -> LoginCredentials("OceanAdmin1", "admin")
                UserRole.RESCUE_TEAM -> LoginCredentials("sihrescue@vi.com", "Ocean@123")
                UserRole.AUTHORITY -> LoginCredentials("sihauthority@vi.com", "Ocean@123")
            }
            
            login(demoUser.username, demoUser.password)
        }
    }

    /**
     * Register a new user
     */
    fun register(
        username: String,
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        phone: String? = null,
        location: String? = null
    ) {
        viewModelScope.launch {
            _registerState.value = RegisterState.Loading
            
            val result = authRepository.register(
                RegistrationData(
                    username = username,
                    email = email,
                    password = password,
                    firstName = firstName,
                    lastName = lastName,
                    phone = phone,
                    location = location,
                    role = UserRole.PUBLIC
                )
            )
            
            result.fold(
                onSuccess = { user ->
                    Timber.d("Registration successful for user: ${user.username}")
                    _registerState.value = RegisterState.Success(user)
                },
                onFailure = { error ->
                    Timber.e(error, "Registration failed")
                    _registerState.value = RegisterState.Error(error.message ?: "Registration failed")
                }
            )
        }
    }

    /**
     * Logout the current user
     */
    fun logout() {
        viewModelScope.launch {
            authRepository.logout()
            _currentUser.value = null
            _loginState.value = LoginState.Idle
        }
    }

    /**
     * Reset login state
     */
    fun resetLoginState() {
        _loginState.value = LoginState.Idle
    }

    /**
     * Reset register state
     */
    fun resetRegisterState() {
        _registerState.value = RegisterState.Idle
    }

    /**
     * Check if user is authenticated
     */
    suspend fun isAuthenticated(): Boolean {
        return authRepository.isAuthenticated()
    }
}

/**
 * Login state sealed class
 */
sealed class LoginState {
    data object Idle : LoginState()
    data object Loading : LoginState()
    data class Success(val user: User) : LoginState()
    data class Error(val message: String) : LoginState()
}

/**
 * Register state sealed class
 */
sealed class RegisterState {
    data object Idle : RegisterState()
    data object Loading : RegisterState()
    data class Success(val user: User) : RegisterState()
    data class Error(val message: String) : RegisterState()
}
