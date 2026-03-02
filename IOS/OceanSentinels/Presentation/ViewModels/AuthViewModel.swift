import Foundation
import Observation

// MARK: - AuthViewModel

/// ViewModel for authentication — login, registration, logout, session management.
@Observable
@MainActor
final class AuthViewModel {

    // MARK: - State

    var userSession: UserSession = .loading
    var loginState: LoginState = .idle
    var registerState: RegisterState = .idle
    var currentUser: User?

    // MARK: - Dependencies

    private let authRepository: any AuthRepository

    // MARK: - Init

    init(authRepository: any AuthRepository) {
        self.authRepository = authRepository
        self.currentUser = nil

        Task { await observeUserSession() }
    }

    // MARK: - Session Observation

    private func observeUserSession() async {
        let session = authRepository.getUserSession()
        self.userSession = session
        if case .authenticated(let user, _) = session {
            self.currentUser = user
        } else {
            self.currentUser = nil
        }
    }

    // MARK: - Login

    /// Login with username and password.
    func login(username: String, password: String) {
        Task {
            loginState = .loading

            do {
                let authToken = try await authRepository.login(
                    credentials: LoginCredentials(username: username, password: password)
                )
                AppLogger.auth.info("Login successful for user: \(authToken.user.username)")
                loginState = .success(authToken.user)
                currentUser = authToken.user
                userSession = .authenticated(user: authToken.user, token: authToken.accessToken)
            } catch {
                AppLogger.auth.error("Login failed: \(error.localizedDescription)")
                loginState = .error(error.localizedDescription)
            }
        }
    }

    /// Demo login for testing.
    func demoLogin(role: UserRole) {
        let credentials: (String, String) = switch role {
        case .public:
            ("sihcitizen@vi.com", "SIH@2025")
        case .admin:
            ("OceanAdmin1", "admin")
        case .rescueTeam:
            ("sihrescue@vi.com", "Ocean@123")
        case .authority:
            ("sihauthority@vi.com", "Ocean@123")
        }
        login(username: credentials.0, password: credentials.1)
    }

    // MARK: - Registration

    /// Register a new user.
    func register(
        username: String,
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        phone: String? = nil,
        location: String? = nil
    ) {
        Task {
            registerState = .loading

            do {
                let user = try await authRepository.register(
                    data: RegistrationData(
                        username: username,
                        email: email,
                        password: password,
                        firstName: firstName,
                        lastName: lastName,
                        phone: phone,
                        location: location,
                        role: .public
                    )
                )
                AppLogger.auth.info("Registration successful for user: \(user.username)")
                registerState = .success(user)
            } catch {
                AppLogger.auth.error("Registration failed: \(error.localizedDescription)")
                registerState = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - Logout

    func logout() {
        Task {
            await authRepository.logout()
            currentUser = nil
            userSession = .unauthenticated
            loginState = .idle
        }
    }

    // MARK: - State Resets

    func resetLoginState() {
        loginState = .idle
    }

    func resetRegisterState() {
        registerState = .idle
    }

    // MARK: - Queries

    func isAuthenticated() -> Bool {
        return authRepository.isAuthenticated()
    }
}

// MARK: - Login State

enum LoginState: Equatable {
    case idle
    case loading
    case success(User)
    case error(String)

    static func == (lhs: LoginState, rhs: LoginState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading): return true
        case (.success(let a), .success(let b)): return a.id == b.id
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

// MARK: - Register State

enum RegisterState: Equatable {
    case idle
    case loading
    case success(User)
    case error(String)

    static func == (lhs: RegisterState, rhs: RegisterState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading): return true
        case (.success(let a), .success(let b)): return a.id == b.id
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}
