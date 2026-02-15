package com.oceansentinels.app.domain.model

import java.time.LocalDateTime

/**
 * User domain model representing a registered user in the Ocean Sentinels system
 */
data class User(
    val id: Int,
    val username: String,
    val email: String,
    val firstName: String,
    val lastName: String,
    val phone: String? = null,
    val location: String? = null,
    val role: UserRole,
    val isActive: Boolean = true,
    val isVerified: Boolean = false,
    val createdAt: LocalDateTime? = null,
    val lastLogin: LocalDateTime? = null
) {
    val fullName: String
        get() = "$firstName $lastName".trim()
    
    val displayName: String
        get() = fullName.ifEmpty { username }
    
    val isAdmin: Boolean
        get() = role == UserRole.ADMIN
    
    val isAuthority: Boolean
        get() = role == UserRole.AUTHORITY
    
    val isRescueTeam: Boolean
        get() = role == UserRole.RESCUE_TEAM
    
    val isPublic: Boolean
        get() = role == UserRole.PUBLIC
    
    val canVerifyIncidents: Boolean
        get() = role in listOf(UserRole.ADMIN, UserRole.AUTHORITY)
    
    val canDeployResponse: Boolean
        get() = role in listOf(UserRole.ADMIN, UserRole.RESCUE_TEAM)
    
    val canResolveIncidents: Boolean
        get() = role in listOf(UserRole.ADMIN, UserRole.AUTHORITY, UserRole.RESCUE_TEAM)
    
    val canAccessAdminDashboard: Boolean
        get() = role == UserRole.ADMIN
    
    val canAccessIncidentReports: Boolean
        get() = role in listOf(UserRole.ADMIN, UserRole.AUTHORITY, UserRole.RESCUE_TEAM)
}

/**
 * User roles in the system
 */
enum class UserRole(val value: String, val displayName: String) {
    PUBLIC("public", "Citizen"),
    AUTHORITY("authority", "Authority"),
    RESCUE_TEAM("rescue_team", "Rescue Team"),
    ADMIN("admin", "Administrator");
    
    companion object {
        fun fromValue(value: String): UserRole {
            return entries.find { it.value == value.lowercase() } ?: PUBLIC
        }
    }
}

/**
 * User credentials for login
 */
data class LoginCredentials(
    val username: String,
    val password: String
)

/**
 * User registration data
 */
data class RegistrationData(
    val username: String,
    val email: String,
    val password: String,
    val firstName: String,
    val lastName: String,
    val phone: String? = null,
    val location: String? = null,
    val role: UserRole = UserRole.PUBLIC
)

/**
 * Authentication token
 */
data class AuthToken(
    val accessToken: String,
    val tokenType: String = "bearer",
    val user: User
)

/**
 * User session state
 */
sealed class UserSession {
    data object Loading : UserSession()
    data object NotAuthenticated : UserSession()
    data class Authenticated(val user: User, val token: String) : UserSession()
}
