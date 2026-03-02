import Foundation

// MARK: - User DTOs

struct UserDTO: Codable {
    let id: Int
    let username: String
    let email: String
    let firstName: String
    let lastName: String
    let phone: String?
    let location: String?
    let role: String?
    let isActive: Bool
    let isVerified: Bool
    let createdAt: String?
    let lastLogin: String?
    
    enum CodingKeys: String, CodingKey {
        case id, username, email
        case firstName = "first_name"
        case lastName = "last_name"
        case phone, location, role
        case isActive = "is_active"
        case isVerified = "is_verified"
        case createdAt = "created_at"
        case lastLogin = "last_login"
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
            createdAt: createdAt?.parseISO8601(),
            lastLogin: lastLogin?.parseISO8601()
        )
    }
}

struct RegisterRequestDTO: Codable {
    let username: String
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let phone: String?
    let location: String?
    let role: String
    
    enum CodingKeys: String, CodingKey {
        case username, email, password
        case firstName = "first_name"
        case lastName = "last_name"
        case phone, location, role
    }
}

struct AuthResponseDTO: Codable {
    let accessToken: String
    let tokenType: String
    let user: UserDTO
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case user
    }
    
    func toDomain() -> AuthToken {
        AuthToken(
            accessToken: accessToken,
            tokenType: tokenType,
            user: user.toDomain()
        )
    }
}

struct UserUpdateRequestDTO: Codable {
    let firstName: String?
    let lastName: String?
    let phone: String?
    let location: String?
    let isActive: Bool?
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case phone, location
        case isActive = "is_active"
    }
}
