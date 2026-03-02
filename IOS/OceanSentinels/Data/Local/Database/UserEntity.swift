import Foundation
import SwiftData

/// SwiftData entity for user caching.
/// Replaces Room UserEntity + UserDao.
@Model
final class UserEntity {
    @Attribute(.unique) var id: Int
    var username: String
    var email: String
    var firstName: String
    var lastName: String
    var phone: String?
    var location: String?
    var role: String?
    var isActive: Bool
    var isVerified: Bool
    var createdAt: Date?
    var lastLogin: Date?
    var cachedAt: Date
    
    init(
        id: Int,
        username: String,
        email: String,
        firstName: String,
        lastName: String,
        phone: String? = nil,
        location: String? = nil,
        role: String? = nil,
        isActive: Bool = true,
        isVerified: Bool = false,
        createdAt: Date? = nil,
        lastLogin: Date? = nil,
        cachedAt: Date = Date()
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.location = location
        self.role = role
        self.isActive = isActive
        self.isVerified = isVerified
        self.createdAt = createdAt
        self.lastLogin = lastLogin
        self.cachedAt = cachedAt
    }
    
    func toDomain() -> User {
        User(
            id: id,
            username: username,
            email: email,
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            location: location,
            role: UserRole.fromValue(role ?? "public"),
            isActive: isActive,
            isVerified: isVerified,
            createdAt: createdAt,
            lastLogin: lastLogin
        )
    }
    
    static func fromDomain(_ user: User) -> UserEntity {
        UserEntity(
            id: user.id,
            username: user.username,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            phone: user.phone,
            location: user.location,
            role: user.role.value,
            isActive: user.isActive,
            isVerified: user.isVerified,
            createdAt: user.createdAt,
            lastLogin: user.lastLogin
        )
    }
}
