package com.oceansentinels.app.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.oceansentinels.app.domain.model.User
import com.oceansentinels.app.domain.model.UserRole
import com.oceansentinels.app.domain.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

/**
 * ViewModel for admin user management operations
 */
@HiltViewModel
class AdminViewModel @Inject constructor(
    private val userRepository: UserRepository
) : ViewModel() {

    // All users
    private val _users = MutableStateFlow<List<User>>(emptyList())
    val users: StateFlow<List<User>> = _users.asStateFlow()

    // Rescue teams
    private val _rescueTeams = MutableStateFlow<List<User>>(emptyList())
    val rescueTeams: StateFlow<List<User>> = _rescueTeams.asStateFlow()

    // Authorities
    private val _authorities = MutableStateFlow<List<User>>(emptyList())
    val authorities: StateFlow<List<User>> = _authorities.asStateFlow()

    // Citizens
    private val _citizens = MutableStateFlow<List<User>>(emptyList())
    val citizens: StateFlow<List<User>> = _citizens.asStateFlow()

    // Loading state
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    // Error state
    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    // Create user state
    private val _createUserState = MutableStateFlow<CreateUserState>(CreateUserState.Idle)
    val createUserState: StateFlow<CreateUserState> = _createUserState.asStateFlow()

    // Delete user state
    private val _deleteUserState = MutableStateFlow<DeleteUserState>(DeleteUserState.Idle)
    val deleteUserState: StateFlow<DeleteUserState> = _deleteUserState.asStateFlow()

    // Counts
    private val _rescueTeamsCount = MutableStateFlow(0)
    val rescueTeamsCount: StateFlow<Int> = _rescueTeamsCount.asStateFlow()

    private val _authoritiesCount = MutableStateFlow(0)
    val authoritiesCount: StateFlow<Int> = _authoritiesCount.asStateFlow()

    private val _citizensCount = MutableStateFlow(0)
    val citizensCount: StateFlow<Int> = _citizensCount.asStateFlow()

    /**
     * Load all users
     */
    fun loadAllUsers() {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null

            val result = userRepository.getAllUsers()

            result.fold(
                onSuccess = { userList ->
                    _users.value = userList
                    categorizeUsers(userList)
                    Timber.d("Loaded ${userList.size} users")
                },
                onFailure = { error ->
                    _error.value = error.message
                    Timber.e(error, "Failed to load users")
                }
            )

            _isLoading.value = false
        }
    }

    private fun categorizeUsers(users: List<User>) {
        _rescueTeams.value = users.filter { it.role == UserRole.RESCUE_TEAM }
        _authorities.value = users.filter { it.role == UserRole.AUTHORITY }
        _citizens.value = users.filter { it.role == UserRole.PUBLIC }
        
        _rescueTeamsCount.value = _rescueTeams.value.size
        _authoritiesCount.value = _authorities.value.size
        _citizensCount.value = _citizens.value.size
    }

    /**
     * Create a new rescue team member
     */
    fun createRescueTeam(
        username: String,
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        phone: String? = null,
        location: String? = null
    ) {
        createUser(
            username = username,
            email = email,
            password = password,
            firstName = firstName,
            lastName = lastName,
            role = UserRole.RESCUE_TEAM,
            phone = phone,
            location = location
        )
    }

    /**
     * Create a new authority member
     */
    fun createAuthority(
        username: String,
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        phone: String? = null,
        location: String? = null
    ) {
        createUser(
            username = username,
            email = email,
            password = password,
            firstName = firstName,
            lastName = lastName,
            role = UserRole.AUTHORITY,
            phone = phone,
            location = location
        )
    }

    /**
     * Create a new user with specified role
     */
    private fun createUser(
        username: String,
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        role: UserRole,
        phone: String? = null,
        location: String? = null
    ) {
        viewModelScope.launch {
            _createUserState.value = CreateUserState.Loading

            val result = userRepository.createUser(
                username = username,
                email = email,
                password = password,
                firstName = firstName,
                lastName = lastName,
                role = role,
                phone = phone,
                location = location
            )

            result.fold(
                onSuccess = { user ->
                    _createUserState.value = CreateUserState.Success(user)
                    loadAllUsers() // Refresh the list
                    Timber.d("User created: ${user.username}")
                },
                onFailure = { error ->
                    _createUserState.value = CreateUserState.Error(error.message ?: "Failed to create user")
                    Timber.e(error, "Failed to create user")
                }
            )
        }
    }

    /**
     * Delete a user
     */
    fun deleteUser(userId: Int) {
        viewModelScope.launch {
            _deleteUserState.value = DeleteUserState.Loading

            val result = userRepository.deleteUser(userId)

            result.fold(
                onSuccess = {
                    _deleteUserState.value = DeleteUserState.Success
                    loadAllUsers() // Refresh the list
                    Timber.d("User deleted: $userId")
                },
                onFailure = { error ->
                    _deleteUserState.value = DeleteUserState.Error(error.message ?: "Failed to delete user")
                    Timber.e(error, "Failed to delete user")
                }
            )
        }
    }

    /**
     * Reset create user state
     */
    fun resetCreateUserState() {
        _createUserState.value = CreateUserState.Idle
    }

    /**
     * Reset delete user state
     */
    fun resetDeleteUserState() {
        _deleteUserState.value = DeleteUserState.Idle
    }

    /**
     * Clear error
     */
    fun clearError() {
        _error.value = null
    }
}

/**
 * Create user state
 */
sealed class CreateUserState {
    data object Idle : CreateUserState()
    data object Loading : CreateUserState()
    data class Success(val user: User) : CreateUserState()
    data class Error(val message: String) : CreateUserState()
}

/**
 * Delete user state
 */
sealed class DeleteUserState {
    data object Idle : DeleteUserState()
    data object Loading : DeleteUserState()
    data object Success : DeleteUserState()
    data class Error(val message: String) : DeleteUserState()
}
