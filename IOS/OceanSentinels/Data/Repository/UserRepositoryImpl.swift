import Foundation
import os

/// Implementation of UserRepository.
/// Replaces Kotlin UserRepositoryImpl.
final class UserRepositoryImpl: UserRepository {
    
    private let api: OceanSentinelsAPI
    private let database: DatabaseManager
    private let logger = Logger(subsystem: "com.oceansentinels.app", category: "UserRepo")
    
    init(api: OceanSentinelsAPI, database: DatabaseManager) {
        self.api = api
        self.database = database
    }
    
    func getAllUsers() async throws -> [User] {
        logger.debug("Fetching all users")
        
        do {
            let userDTOs = try await api.getAllUsers()
            let users = userDTOs.map { $0.toDomain() }
            
            // Cache users
            let entities = users.map { UserEntity.fromDomain($0) }
            try await database.insertUsers(entities)
            
            logger.debug("Fetched \(users.count) users")
            return users
        } catch {
            // Try cache
            let cached = try await database.fetchAllUsers()
            if !cached.isEmpty {
                return cached.map { $0.toDomain() }
            }
            throw error
        }
    }
    
    func getUsersByRole(role: UserRole) async throws -> [User] {
        let allUsers = try await getAllUsers()
        return allUsers.filter { $0.role == role }
    }
    
    func getUser(id: Int) async throws -> User {
        do {
            let dto = try await api.getUser(id: id)
            let user = dto.toDomain()
            try await database.insertUser(UserEntity.fromDomain(user))
            return user
        } catch {
            if let cached = try await database.fetchUser(byId: id) {
                return cached.toDomain()
            }
            throw error
        }
    }
    
    func createUser(
        username: String,
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        role: UserRole,
        phone: String?,
        location: String?
    ) async throws -> User {
        logger.debug("Creating user: \(username) with role: \(role.value)")
        
        let request = RegisterRequestDTO(
            username: username,
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            location: location,
            role: role.value
        )
        
        let dto = try await api.adminCreateUser(request: request)
        let user = dto.toDomain()
        try await database.insertUser(UserEntity.fromDomain(user))
        
        logger.debug("User created successfully: \(user.username)")
        return user
    }
    
    func updateUser(
        id: Int,
        firstName: String?,
        lastName: String?,
        phone: String?,
        location: String?,
        isActive: Bool?
    ) async throws -> User {
        logger.debug("Updating user: \(id)")
        
        // Update in local cache
        guard let existingEntity = try await database.fetchUser(byId: id) else {
            throw NSError(domain: "UserRepo", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        existingEntity.firstName = firstName ?? existingEntity.firstName
        existingEntity.lastName = lastName ?? existingEntity.lastName
        existingEntity.phone = phone ?? existingEntity.phone
        existingEntity.location = location ?? existingEntity.location
        existingEntity.isActive = isActive ?? existingEntity.isActive
        
        // The @Model property mutation auto-saves in SwiftData context
        return existingEntity.toDomain()
    }
    
    func deleteUser(id: Int) async throws {
        logger.debug("Deleting user: \(id)")
        try await api.deleteUser(id: id)
        try await database.deleteAllUsers() // Simplified; ideally delete by ID
    }
    
    func getRescueTeamsCount() async throws -> Int {
        let users = try await database.fetchAllUsers()
        return users.filter { $0.role == UserRole.rescueTeam.value }.count
    }
    
    func getAuthoritiesCount() async throws -> Int {
        let users = try await database.fetchAllUsers()
        return users.filter { $0.role == UserRole.authority.value }.count
    }

    func adminCreateUser(data: RegistrationData) async throws -> User {
        try await createUser(
            username: data.username,
            email: data.email,
            password: data.password,
            firstName: data.firstName,
            lastName: data.lastName,
            role: data.role,
            phone: data.phone,
            location: data.location
        )
    }
}
