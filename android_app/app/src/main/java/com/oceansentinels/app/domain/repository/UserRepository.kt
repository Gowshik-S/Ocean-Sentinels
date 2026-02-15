package com.oceansentinels.app.domain.repository

import com.oceansentinels.app.domain.model.User
import com.oceansentinels.app.domain.model.UserRole

/**
 * Repository interface for user management operations (Admin only)
 */
interface UserRepository {
    
    /**
     * Get all users
     */
    suspend fun getAllUsers(): Result<List<User>>
    
    /**
     * Get users by role
     */
    suspend fun getUsersByRole(role: UserRole): Result<List<User>>
    
    /**
     * Get a single user by ID
     */
    suspend fun getUser(id: Int): Result<User>
    
    /**
     * Create a new user (Admin only)
     */
    suspend fun createUser(
        username: String,
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        role: UserRole,
        phone: String? = null,
        location: String? = null
    ): Result<User>
    
    /**
     * Update user information
     */
    suspend fun updateUser(
        id: Int,
        firstName: String? = null,
        lastName: String? = null,
        phone: String? = null,
        location: String? = null,
        isActive: Boolean? = null
    ): Result<User>
    
    /**
     * Delete a user (Admin only)
     */
    suspend fun deleteUser(id: Int): Result<Unit>
    
    /**
     * Get rescue teams count
     */
    suspend fun getRescueTeamsCount(): Result<Int>
    
    /**
     * Get authorities count
     */
    suspend fun getAuthoritiesCount(): Result<Int>
}
