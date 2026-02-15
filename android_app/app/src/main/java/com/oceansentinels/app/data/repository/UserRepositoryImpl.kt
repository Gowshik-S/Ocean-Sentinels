package com.oceansentinels.app.data.repository

import com.oceansentinels.app.data.local.database.dao.UserDao
import com.oceansentinels.app.data.local.database.entity.UserEntity
import com.oceansentinels.app.data.remote.api.OceanSentinelsApi
import com.oceansentinels.app.data.remote.dto.RegisterRequestDto
import com.oceansentinels.app.data.remote.dto.UserUpdateRequestDto
import com.oceansentinels.app.domain.model.User
import com.oceansentinels.app.domain.model.UserRole
import com.oceansentinels.app.domain.repository.UserRepository
import kotlinx.coroutines.flow.first
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Implementation of UserRepository
 */
@Singleton
class UserRepositoryImpl @Inject constructor(
    private val api: OceanSentinelsApi,
    private val userDao: UserDao
) : UserRepository {

    override suspend fun getAllUsers(): Result<List<User>> {
        return try {
            Timber.d("Fetching all users")
            
            val response = api.getAllUsers()
            
            if (response.isSuccessful && response.body() != null) {
                val users = response.body()!!.map { it.toDomain() }
                
                // Cache users
                val entities = users.map { UserEntity.fromDomain(it) }
                userDao.insertAll(entities)
                
                Timber.d("Fetched ${users.size} users")
                Result.success(users)
            } else {
                // Try cache
                val cached = userDao.getAllUsers().first()
                if (cached.isNotEmpty()) {
                    Result.success(cached.map { it.toDomain() })
                } else {
                    Result.failure(Exception("Failed to fetch users"))
                }
            }
        } catch (e: Exception) {
            Timber.e(e, "Error fetching users")
            val cached = userDao.getAllUsers().first()
            if (cached.isNotEmpty()) {
                Result.success(cached.map { it.toDomain() })
            } else {
                Result.failure(e)
            }
        }
    }

    override suspend fun getUsersByRole(role: UserRole): Result<List<User>> {
        return try {
            val allUsersResult = getAllUsers()
            
            if (allUsersResult.isSuccess) {
                val filtered = allUsersResult.getOrThrow().filter { it.role == role }
                Result.success(filtered)
            } else {
                val cached = userDao.getUsersByRole(role.value).first()
                Result.success(cached.map { it.toDomain() })
            }
        } catch (e: Exception) {
            Timber.e(e, "Error fetching users by role")
            Result.failure(e)
        }
    }

    override suspend fun getUser(id: Int): Result<User> {
        return try {
            val response = api.getUser(id)
            
            if (response.isSuccessful && response.body() != null) {
                val user = response.body()!!.toDomain()
                userDao.insert(UserEntity.fromDomain(user))
                Result.success(user)
            } else {
                val cached = userDao.getUserById(id)
                if (cached != null) {
                    Result.success(cached.toDomain())
                } else {
                    Result.failure(Exception("User not found"))
                }
            }
        } catch (e: Exception) {
            val cached = userDao.getUserById(id)
            if (cached != null) {
                Result.success(cached.toDomain())
            } else {
                Result.failure(e)
            }
        }
    }

    override suspend fun createUser(
        username: String,
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        role: UserRole,
        phone: String?,
        location: String?
    ): Result<User> {
        return try {
            Timber.d("Creating user: $username with role: ${role.value}")
            
            val request = RegisterRequestDto(
                username = username,
                email = email,
                password = password,
                firstName = firstName,
                lastName = lastName,
                phone = phone,
                location = location,
                role = role.value
            )
            
            val response = api.adminCreateUser(request)
            
            if (response.isSuccessful && response.body() != null) {
                val user = response.body()!!.toDomain()
                userDao.insert(UserEntity.fromDomain(user))
                Timber.d("User created successfully: ${user.username}")
                Result.success(user)
            } else {
                val errorBody = response.errorBody()?.string() ?: "Unknown error"
                Timber.e("Failed to create user: $errorBody")
                Result.failure(Exception("Failed to create user: $errorBody"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error creating user")
            Result.failure(e)
        }
    }

    override suspend fun updateUser(
        id: Int,
        firstName: String?,
        lastName: String?,
        phone: String?,
        location: String?,
        isActive: Boolean?
    ): Result<User> {
        return try {
            Timber.d("Updating user: $id")
            
            val request = UserUpdateRequestDto(
                firstName = firstName,
                lastName = lastName,
                phone = phone,
                location = location,
                isActive = isActive
            )
            
            // Note: The API might need a specific endpoint for updating other users
            // For now, we'll just update in local cache
            val existingUser = userDao.getUserById(id)
            if (existingUser != null) {
                val updated = existingUser.copy(
                    firstName = firstName ?: existingUser.firstName,
                    lastName = lastName ?: existingUser.lastName,
                    phone = phone ?: existingUser.phone,
                    location = location ?: existingUser.location,
                    isActive = isActive ?: existingUser.isActive
                )
                userDao.update(updated)
                Result.success(updated.toDomain())
            } else {
                Result.failure(Exception("User not found"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error updating user")
            Result.failure(e)
        }
    }

    override suspend fun deleteUser(id: Int): Result<Unit> {
        return try {
            Timber.d("Deleting user: $id")
            
            val response = api.deleteUser(id)
            
            if (response.isSuccessful) {
                userDao.deleteById(id)
                Timber.d("User deleted successfully")
                Result.success(Unit)
            } else {
                val errorBody = response.errorBody()?.string() ?: "Unknown error"
                Timber.e("Failed to delete user: $errorBody")
                Result.failure(Exception("Failed to delete user: $errorBody"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error deleting user")
            Result.failure(e)
        }
    }

    override suspend fun getRescueTeamsCount(): Result<Int> {
        return try {
            val count = userDao.countByRole(UserRole.RESCUE_TEAM.value)
            Result.success(count)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getAuthoritiesCount(): Result<Int> {
        return try {
            val count = userDao.countByRole(UserRole.AUTHORITY.value)
            Result.success(count)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
