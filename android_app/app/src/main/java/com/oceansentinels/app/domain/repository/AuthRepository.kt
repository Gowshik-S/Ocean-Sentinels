package com.oceansentinels.app.domain.repository

import com.oceansentinels.app.domain.model.*
import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for authentication operations
 */
interface AuthRepository {
    
    /**
     * Get the current user session as a flow
     */
    fun getUserSession(): Flow<UserSession>
    
    /**
     * Login with username and password
     */
    suspend fun login(credentials: LoginCredentials): Result<AuthToken>
    
    /**
     * Register a new user
     */
    suspend fun register(data: RegistrationData): Result<User>
    
    /**
     * Logout the current user
     */
    suspend fun logout()
    
    /**
     * Get the current authenticated user
     */
    suspend fun getCurrentUser(): Result<User>
    
    /**
     * Check if user is authenticated
     */
    suspend fun isAuthenticated(): Boolean
    
    /**
     * Get stored auth token
     */
    suspend fun getStoredToken(): String?
    
    /**
     * Refresh the auth token
     */
    suspend fun refreshToken(): Result<AuthToken>
}
