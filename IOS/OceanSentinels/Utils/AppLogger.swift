import Foundation
import os.log

/// Centralized logger — replaces Timber (Android)
/// Uses Apple's unified logging system (os.Logger)
enum AppLogger {
    
    enum Level: Int, Comparable {
        case debug = 0, info = 1, warning = 2, error = 3
        static func < (lhs: Level, rhs: Level) -> Bool { lhs.rawValue < rhs.rawValue }
    }
    
    private static var minimumLevel: Level = .debug
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.oceansentinels.app", category: "OceanSentinels")
    
    static func configure(level: Level) {
        minimumLevel = level
    }
    
    static func d(_ message: String, tag: String = "") {
        guard minimumLevel <= .debug else { return }
        logger.debug("[\(tag)] \(message)")
    }
    
    static func i(_ message: String, tag: String = "") {
        guard minimumLevel <= .info else { return }
        logger.info("[\(tag)] \(message)")
    }
    
    static func w(_ message: String, tag: String = "") {
        guard minimumLevel <= .warning else { return }
        logger.warning("[\(tag)] \(message)")
    }
    
    static func e(_ message: String, error: (any Error)? = nil, tag: String = "") {
        logger.error("[\(tag)] \(message) \(error?.localizedDescription ?? "")")
    }

    // MARK: - Category Loggers (used by ViewModels and Repositories)

    /// Category-scoped logger with `.info()`, `.debug()`, `.warning()`, `.error()` methods.
    struct CategoryLogger {
        private let tag: String

        init(tag: String) { self.tag = tag }

        func debug(_ message: String) { AppLogger.d(message, tag: tag) }
        func info(_ message: String) { AppLogger.i(message, tag: tag) }
        func warning(_ message: String) { AppLogger.w(message, tag: tag) }
        func error(_ message: String) { AppLogger.e(message, tag: tag) }
    }

    static let auth = CategoryLogger(tag: "Auth")
    static let incidents = CategoryLogger(tag: "Incidents")
    static let admin = CategoryLogger(tag: "Admin")
    static let analytics = CategoryLogger(tag: "Analytics")
    static let mesh = CategoryLogger(tag: "Mesh")
    static let weather = CategoryLogger(tag: "Weather")
}
