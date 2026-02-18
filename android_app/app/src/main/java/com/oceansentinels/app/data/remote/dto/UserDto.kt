package com.oceansentinels.app.data.remote.dto

import com.google.gson.annotations.SerializedName
import com.oceansentinels.app.domain.model.*
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

/**
 * User DTOs for API communication
 */

data class UserDto(
    @SerializedName("id") val id: Int,
    @SerializedName("username") val username: String,
    @SerializedName("email") val email: String,
    @SerializedName("first_name") val firstName: String,
    @SerializedName("last_name") val lastName: String,
    @SerializedName("phone") val phone: String?,
    @SerializedName("location") val location: String?,
    @SerializedName("role") val role: String?,
    @SerializedName("is_active") val isActive: Boolean,
    @SerializedName("is_verified") val isVerified: Boolean,
    @SerializedName("created_at") val createdAt: String?,
    @SerializedName("last_login") val lastLogin: String?
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
            role = role?.let { UserRole.fromValue(it) } ?: UserRole.PUBLIC,
            isActive = isActive,
            isVerified = isVerified,
            createdAt = createdAt?.parseDateTime(),
            lastLogin = lastLogin?.parseDateTime()
        )
    }
}

data class LoginRequestDto(
    @SerializedName("username") val username: String,
    @SerializedName("password") val password: String
)

data class RegisterRequestDto(
    @SerializedName("username") val username: String,
    @SerializedName("email") val email: String,
    @SerializedName("password") val password: String,
    @SerializedName("first_name") val firstName: String,
    @SerializedName("last_name") val lastName: String,
    @SerializedName("phone") val phone: String?,
    @SerializedName("location") val location: String?,
    @SerializedName("role") val role: String = "public"
)

data class AuthResponseDto(
    @SerializedName("access_token") val accessToken: String,
    @SerializedName("token_type") val tokenType: String,
    @SerializedName("user") val user: UserDto
) {
    fun toDomain(): AuthToken {
        return AuthToken(
            accessToken = accessToken,
            tokenType = tokenType,
            user = user.toDomain()
        )
    }
}

data class UserUpdateRequestDto(
    @SerializedName("first_name") val firstName: String?,
    @SerializedName("last_name") val lastName: String?,
    @SerializedName("phone") val phone: String?,
    @SerializedName("location") val location: String?,
    @SerializedName("is_active") val isActive: Boolean?
)

// Extension function for parsing date strings
private fun String.parseDateTime(): LocalDateTime? {
    return try {
        LocalDateTime.parse(this, DateTimeFormatter.ISO_DATE_TIME)
    } catch (e: Exception) {
        try {
            LocalDateTime.parse(this.replace("Z", ""), DateTimeFormatter.ISO_LOCAL_DATE_TIME)
        } catch (e: Exception) {
            null
        }
    }
}
