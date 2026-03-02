import Foundation

/// Repository protocol for user management operations.
protocol UserRepository {

    /// Fetches all users (admin-only).
    func getAllUsers() async throws -> [User]

    /// Fetches users filtered by role.
    func getUsersByRole(role: UserRole) async throws -> [User]

    /// Fetches a single user by ID.
    func getUser(id: Int) async throws -> User

    /// Creates a new user with the specified role (admin).
    func createUser(
        username: String,
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        role: UserRole,
        phone: String?,
        location: String?
    ) async throws -> User

    /// Creates a new user account as an admin (using RegistrationData).
    func adminCreateUser(data: RegistrationData) async throws -> User

    /// Updates a user's profile fields.
    func updateUser(
        id: Int,
        firstName: String?,
        lastName: String?,
        phone: String?,
        location: String?,
        isActive: Bool?
    ) async throws -> User

    /// Deletes a user by ID (admin-only).
    func deleteUser(id: Int) async throws

    /// Count of rescue team users.
    func getRescueTeamsCount() async throws -> Int

    /// Count of authority users.
    func getAuthoritiesCount() async throws -> Int
}
