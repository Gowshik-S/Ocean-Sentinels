package com.oceansentinels.app.data.local.database.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import com.oceansentinels.app.domain.model.User
import com.oceansentinels.app.domain.model.UserRole
import java.time.LocalDateTime

/**
 * User entity for Room database
 */
@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: Int,
    
    @ColumnInfo(name = "username")
    val username: String,
    
    @ColumnInfo(name = "email")
    val email: String,
    
    @ColumnInfo(name = "first_name")
    val firstName: String,
    
    @ColumnInfo(name = "last_name")
    val lastName: String,
    
    @ColumnInfo(name = "phone")
    val phone: String?,
    
    @ColumnInfo(name = "location")
    val location: String?,
    
    @ColumnInfo(name = "role")
    val role: String,
    
    @ColumnInfo(name = "is_active")
    val isActive: Boolean,
    
    @ColumnInfo(name = "is_verified")
    val isVerified: Boolean,
    
    @ColumnInfo(name = "created_at")
    val createdAt: LocalDateTime?,
    
    @ColumnInfo(name = "last_login")
    val lastLogin: LocalDateTime?,
    
    @ColumnInfo(name = "cached_at")
    val cachedAt: LocalDateTime = LocalDateTime.now()
) {
    fun toDomain(): User {
        return User(
            id = id,
            username = username,
            email = email,
            firstName = firstName,
            lastName = lastName,
            phone = phone,
            location = location,
            role = UserRole.fromValue(role),
            isActive = isActive,
            isVerified = isVerified,
            createdAt = createdAt,
            lastLogin = lastLogin
        )
    }
    
    companion object {
        fun fromDomain(user: User): UserEntity {
            return UserEntity(
                id = user.id,
                username = user.username,
                email = user.email,
                firstName = user.firstName,
                lastName = user.lastName,
                phone = user.phone,
                location = user.location,
                role = user.role.value,
                isActive = user.isActive,
                isVerified = user.isVerified,
                createdAt = user.createdAt,
                lastLogin = user.lastLogin
            )
        }
    }
}
