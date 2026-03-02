import Foundation
import os

/// Implementation of AuthRepository.
/// Replaces Kotlin AuthRepositoryImpl with URLSession + SwiftData.
final class AuthRepositoryImpl: AuthRepository {
    
    private let api: OceanSentinelsAPI
    private let preferences: PreferencesManager
    private let database: DatabaseManager
    private let networkClient: NetworkClient
    private let logger = Logger(subsystem: "com.oceansentinels.app", category: "AuthRepo")
    
    init(
        api: OceanSentinelsAPI,
        preferences: PreferencesManager,
        database: DatabaseManager,
        networkClient: NetworkClient = .shared
    ) {
        self.api = api
        self.preferences = preferences
        self.database = database
        self.networkClient = networkClient
    }
    
    func getUserSession() -> UserSession {
        if preferences.isLoggedIn,
           let user = preferences.userData,
           let token = preferences.authToken {
            return .authenticated(user: user, token: token)
        }
        return .unauthenticated
    }
    
    func login(credentials: LoginCredentials) async throws -> AuthToken {
        try await login(username: credentials.username, password: credentials.password)
    }
    
    func login(username: String, password: String) async throws -> AuthToken {
        logger.debug("Attempting login for user: \(username)")
        
        let response: AuthResponseDTO = try await api.login(username: username, password: password)
        let authToken = response.toDomain()
        
        // Save to preferences
        preferences.saveAuthToken(authToken.accessToken)
        preferences.saveUserData(authToken.user)
        preferences.setLoggedIn(true)
        
        // Inject token into network client
        await networkClient.setAuthToken(authToken.accessToken)
        
        // Cache user in database
        let userEntity = UserEntity.fromDomain(authToken.user)
        try await database.insertUser(userEntity)
        
        logger.debug("Login successful for user: \(authToken.user.username)")
        return authToken
    }
    
    func register(data: RegistrationData) async throws -> User {
        logger.debug("Attempting registration for user: \(data.username)")
        
        let request = RegisterRequestDTO(
            username: data.username,
            email: data.email,
            password: data.password,
            firstName: data.firstName,
            lastName: data.lastName,
            phone: data.phone,
            location: data.location,
            role: data.role.value
        )
        
        let response = try await api.register(request: request)
        let authToken = response.toDomain()
        
        // Auto-login after registration
        preferences.saveAuthToken(authToken.accessToken)
        preferences.saveUserData(authToken.user)
        preferences.setLoggedIn(true)
        
        await networkClient.setAuthToken(authToken.accessToken)
        
        let userEntity = UserEntity.fromDomain(authToken.user)
        try await database.insertUser(userEntity)
        
        logger.debug("Registration successful for user: \(authToken.user.username)")
        return authToken.user
    }
    
    func logout() async {
        logger.debug("Logging out user")
        preferences.clearSession()
        await networkClient.setAuthToken(nil)
    }
    
    func getCurrentUser() async throws -> User {
        do {
            let userDTO = try await api.getCurrentUser()
            let user = userDTO.toDomain()
            
            // Update cached user data
            preferences.saveUserData(user)
            try await database.insertUser(UserEntity.fromDomain(user))
            
            return user
        } catch {
            // Try to get from cache on network error
            if let cachedUser = preferences.userData {
                return cachedUser
            }
            throw error
        }
    }
    
    func isAuthenticated() -> Bool {
        preferences.isLoggedIn && preferences.authToken != nil
    }
    
    func getStoredToken() -> String? {
        preferences.authToken
    }
    
    func refreshToken() async throws -> AuthToken {
        // API doesn't have a refresh endpoint yet
        throw NSError(domain: "AuthRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Token refresh not implemented"])
    }
    
    /// Restore auth state on app launch
    func restoreSession() async {
        if let token = preferences.authToken {
            await networkClient.setAuthToken(token)
        }
    }
}
