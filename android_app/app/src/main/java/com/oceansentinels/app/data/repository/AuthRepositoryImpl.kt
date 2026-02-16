package com.oceansentinels.app.data.repository

import com.oceansentinels.app.data.local.database.dao.UserDao
import com.oceansentinels.app.data.local.database.entity.UserEntity
import com.oceansentinels.app.data.local.preferences.PreferencesManager
import com.oceansentinels.app.data.remote.api.OceanSentinelsApi
import com.oceansentinels.app.data.remote.dto.LoginRequestDto
import com.oceansentinels.app.data.remote.dto.RegisterRequestDto
import com.oceansentinels.app.domain.model.*
import com.oceansentinels.app.domain.repository.AuthRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Implementation of AuthRepository
 */
@Singleton
class AuthRepositoryImpl @Inject constructor(
    private val api: OceanSentinelsApi,
    private val preferencesManager: PreferencesManager,
    private val userDao: UserDao
) : AuthRepository {

    override fun getUserSession(): Flow<UserSession> {
        return preferencesManager.isLoggedIn.map { isLoggedIn ->
            if (isLoggedIn) {
                val user = preferencesManager.userData.first()
                val token = preferencesManager.authToken.first()
                if (user != null && token != null) {
                    UserSession.Authenticated(user, token)
                } else {
                    UserSession.NotAuthenticated
                }
            } else {
                UserSession.NotAuthenticated
            }
        }
    }

    override suspend fun login(credentials: LoginCredentials): Result<AuthToken> {
        return try {
            Timber.d("Attempting login for user: ${credentials.username}")
            
            val response = api.login(
                username = credentials.username,
                password = credentials.password
            )
            
            if (response.isSuccessful && response.body() != null) {
                val authResponse = response.body()!!
                val authToken = authResponse.toDomain()
                
                // Save to preferences
                preferencesManager.saveAuthToken(authToken.accessToken)
                preferencesManager.saveUserData(authToken.user)
                preferencesManager.setLoggedIn(true)
                
                // Cache user in database
                userDao.insert(UserEntity.fromDomain(authToken.user))
                
                Timber.d("Login successful for user: ${authToken.user.username}")
                Result.success(authToken)
            } else {
                val errorBody = response.errorBody()?.string() ?: "Unknown error"
                Timber.e("Login failed: $errorBody")
                Result.failure(Exception("Login failed: $errorBody"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Login error")
            Result.failure(e)
        }
    }

    override suspend fun register(data: RegistrationData): Result<User> {
        return try {
            Timber.d("Attempting registration for user: ${data.username}")
            
            val request = RegisterRequestDto(
                username = data.username,
                email = data.email,
                password = data.password,
                firstName = data.firstName,
                lastName = data.lastName,
                phone = data.phone,
                location = data.location,
                role = data.role.value
            )
            
            val response = api.register(request)
            
            if (response.isSuccessful && response.body() != null) {
                val authResponse = response.body()!!
                val authToken = authResponse.toDomain()
                
                // Save auth token and user data so user is logged in after registration
                preferencesManager.saveAuthToken(authToken.accessToken)
                preferencesManager.saveUserData(authToken.user)
                preferencesManager.setLoggedIn(true)
                
                // Cache user in database
                userDao.insert(UserEntity.fromDomain(authToken.user))
                
                Timber.d("Registration successful for user: ${authToken.user.username}")
                Result.success(authToken.user)
            } else {
                val errorBody = response.errorBody()?.string() ?: "Unknown error"
                Timber.e("Registration failed: $errorBody")
                Result.failure(Exception("Registration failed: $errorBody"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Registration error")
            Result.failure(e)
        }
    }

    override suspend fun logout() {
        Timber.d("Logging out user")
        preferencesManager.clearSession()
    }

    override suspend fun getCurrentUser(): Result<User> {
        return try {
            val response = api.getCurrentUser()
            
            if (response.isSuccessful && response.body() != null) {
                val user = response.body()!!.toDomain()
                
                // Update cached user data
                preferencesManager.saveUserData(user)
                userDao.insert(UserEntity.fromDomain(user))
                
                Result.success(user)
            } else {
                // Try to get from cache
                val cachedUser = preferencesManager.userData.first()
                if (cachedUser != null) {
                    Result.success(cachedUser)
                } else {
                    Result.failure(Exception("Failed to get current user"))
                }
            }
        } catch (e: Exception) {
            // Try to get from cache on network error
            val cachedUser = preferencesManager.userData.first()
            if (cachedUser != null) {
                Result.success(cachedUser)
            } else {
                Result.failure(e)
            }
        }
    }

    override suspend fun isAuthenticated(): Boolean {
        return preferencesManager.isLoggedIn.first() && 
               preferencesManager.authToken.first() != null
    }

    override suspend fun getStoredToken(): String? {
        return preferencesManager.authToken.first()
    }

    override suspend fun refreshToken(): Result<AuthToken> {
        // For now, just return failure as the API doesn't have a refresh endpoint
        // In a real app, this would call a token refresh endpoint
        return Result.failure(Exception("Token refresh not implemented"))
    }
}
