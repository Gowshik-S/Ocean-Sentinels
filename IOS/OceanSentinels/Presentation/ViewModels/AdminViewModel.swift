import Foundation
import Observation

// MARK: - AdminViewModel

/// ViewModel for admin user management — list all users, create rescue teams/authorities, delete users.
@Observable
@MainActor
final class AdminViewModel {

    // MARK: - State

    var users: [User] = []
    var rescueTeams: [User] = []
    var authorities: [User] = []
    var citizens: [User] = []

    var isLoading: Bool = false
    var error: String?

    var createUserState: CreateUserState = .idle
    var deleteUserState: DeleteUserState = .idle

    var rescueTeamsCount: Int = 0
    var authoritiesCount: Int = 0
    var citizensCount: Int = 0

    // MARK: - Dependencies

    private let userRepository: UserRepository

    // MARK: - Init

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    // MARK: - Load Users

    /// Load all users and categorize by role.
    func loadAllUsers() {
        Task {
            isLoading = true
            error = nil

            do {
                let userList = try await userRepository.getAllUsers()
                users = userList
                categorizeUsers(userList)
                AppLogger.admin.debug("Loaded \(userList.count) users")
            } catch {
                self.error = error.localizedDescription
                AppLogger.admin.error("Failed to load users: \(error.localizedDescription)")
            }

            isLoading = false
        }
    }

    private func categorizeUsers(_ users: [User]) {
        rescueTeams = users.filter { $0.role == .rescueTeam }
        authorities = users.filter { $0.role == .authority }
        citizens = users.filter { $0.role == .public }

        rescueTeamsCount = rescueTeams.count
        authoritiesCount = authorities.count
        citizensCount = citizens.count
    }

    // MARK: - Create Users

    /// Create a new rescue team member.
    func createRescueTeam(
        username: String,
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        phone: String? = nil,
        location: String? = nil
    ) {
        createUser(
            username: username, email: email, password: password,
            firstName: firstName, lastName: lastName,
            role: .rescueTeam, phone: phone, location: location
        )
    }

    /// Create a new authority member.
    func createAuthority(
        username: String,
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        phone: String? = nil,
        location: String? = nil
    ) {
        createUser(
            username: username, email: email, password: password,
            firstName: firstName, lastName: lastName,
            role: .authority, phone: phone, location: location
        )
    }

    /// Create a new user with specified role.
    private func createUser(
        username: String,
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        role: UserRole,
        phone: String? = nil,
        location: String? = nil
    ) {
        Task {
            createUserState = .loading

            do {
                let user = try await userRepository.createUser(
                    username: username,
                    email: email,
                    password: password,
                    firstName: firstName,
                    lastName: lastName,
                    role: role,
                    phone: phone,
                    location: location
                )
                createUserState = .success(user)
                loadAllUsers() // Refresh the list
                AppLogger.admin.debug("User created: \(user.username)")
            } catch {
                createUserState = .error(error.localizedDescription)
                AppLogger.admin.error("Failed to create user: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Delete User

    /// Delete a user by ID.
    func deleteUser(userId: Int) {
        Task {
            deleteUserState = .loading

            do {
                try await userRepository.deleteUser(id: userId)
                deleteUserState = .success
                loadAllUsers() // Refresh the list
                AppLogger.admin.debug("User deleted: \(userId)")
            } catch {
                deleteUserState = .error(error.localizedDescription)
                AppLogger.admin.error("Failed to delete user: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - State Resets

    func resetCreateUserState() { createUserState = .idle }
    func resetDeleteUserState() { deleteUserState = .idle }
    func clearError() { error = nil }

    // MARK: - Convenience Properties

    var allUsers: [User] { users }

    var createUserError: String? {
        if case .error(let msg) = createUserState { return msg }
        return nil
    }

    var isCreatingUser: Bool { createUserState == .loading }
}

// MARK: - Create User State

enum CreateUserState: Equatable {
    case idle
    case loading
    case success(User)
    case error(String)

    static func == (lhs: CreateUserState, rhs: CreateUserState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading): return true
        case (.success(let a), .success(let b)): return a.id == b.id
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

// MARK: - Delete User State

enum DeleteUserState: Equatable {
    case idle
    case loading
    case success
    case error(String)
}
