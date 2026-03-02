import Foundation

/// Repository protocol for authentication operations.
protocol AuthRepository {

    /// Authenticates a user with the given credentials.
    func login(credentials: LoginCredentials) async throws -> AuthToken

    /// Registers a new user account.
    func register(data: RegistrationData) async throws -> User

    /// Logs out the current user, clearing stored session data.
    func logout() async

    /// Checks whether the current user is authenticated.
    func isAuthenticated() -> Bool

    /// Returns the current user session state.
    func getUserSession() -> UserSession

    /// Retrieves the stored authentication token, if available.
    func getStoredToken() -> String?

    /// Fetches the currently authenticated user's profile.
    func getCurrentUser() async throws -> User

    /// Restore auth state on app launch.
    func restoreSession() async
}
