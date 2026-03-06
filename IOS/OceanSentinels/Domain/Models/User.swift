import Foundation

// MARK: - UserRole

enum UserRole: String, Codable, CaseIterable, Identifiable {
    case `public` = "PUBLIC"
    case authority = "AUTHORITY"
    case rescueTeam = "RESCUE_TEAM"
    case admin = "ADMIN"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .public: return "Public"
        case .authority: return "Authority"
        case .rescueTeam: return "Rescue Team"
        case .admin: return "Admin"
        }
    }

    var value: String { rawValue }

    static func fromValue(_ value: String) -> UserRole {
        let normalized = value.uppercased().replacingOccurrences(of: "-", with: "_")
        return UserRole(rawValue: normalized) ?? .public
    }
}

// MARK: - User

struct User: Codable, Identifiable, Equatable {
    let id: Int
    let username: String
    let email: String
    let firstName: String
    let lastName: String
    let phone: String?
    let location: String?
    let role: UserRole
    let isActive: Bool
    let isVerified: Bool
    let createdAt: Date?
    let lastLogin: Date?

    // MARK: - Computed Properties

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var displayName: String {
        let full = fullName.trimmingCharacters(in: .whitespaces)
        return full.isEmpty ? username : full
    }

    var isAdmin: Bool {
        role == .admin
    }

    var isAuthority: Bool {
        role == .authority
    }

    var isRescueTeam: Bool {
        role == .rescueTeam
    }

    var isPublic: Bool {
        role == .public
    }

    var canVerifyIncidents: Bool {
        role == .authority || role == .admin
    }

    var canDeployResponse: Bool {
        role == .authority || role == .rescueTeam || role == .admin
    }

    var canResolveIncidents: Bool {
        role == .authority || role == .rescueTeam || role == .admin
    }

    var canAccessAdminDashboard: Bool {
        role == .admin
    }

    var canAccessIncidentReports: Bool {
        role == .authority || role == .admin
    }
}

// MARK: - LoginCredentials

struct LoginCredentials: Codable, Equatable {
    let username: String
    let password: String
}

// MARK: - RegistrationData

struct RegistrationData: Codable, Equatable {
    let username: String
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let phone: String?
    let location: String?
    let role: UserRole
}

// MARK: - AuthToken

struct AuthToken: Codable, Equatable {
    let accessToken: String
    let tokenType: String
    let user: User
}

// MARK: - UserSession

enum UserSession: Equatable {
    case loading
    case unauthenticated
    case authenticated(user: User, token: String)
}
