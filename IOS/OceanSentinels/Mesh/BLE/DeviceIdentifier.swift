import Foundation
import CryptoKit
import Security
import os
#if canImport(UIKit)
import UIKit
#endif

/// Generates and persists a unique device identifier for mesh networking.
///
/// On iOS, there's no permanent MAC address access. This class generates
/// a persistent UUID-based ID stored in Keychain (survives app reinstall),
/// combined with identifierForVendor for a stable, unique device identity.
///
/// Replaces Android DeviceIdentifier (SharedPreferences + ANDROID_ID).
final class DeviceIdentifier {
    
    static let shared = DeviceIdentifier()
    
    private let logger = Logger(subsystem: "com.oceansentinels.app", category: "DeviceID")
    
    /// Length of the device ID (hex characters)
    private let deviceIdLength = 12
    /// Length of the fingerprint (hex characters — 16 hex = 8 bytes = 64 bits)
    private let fingerprintLength = 16
    
    // Keychain keys
    private let keychainServiceId = "com.oceansentinels.mesh"
    private let keychainDeviceIdKey = "device_mesh_id"
    private let keychainFingerprintKey = "device_fingerprint"
    
    private init() {}
    
    // MARK: - Device ID
    
    /// Get or generate a persistent unique device ID.
    /// Format: 12 hex chars (e.g. "a3f7c1b9e2d4")
    /// Stored in Keychain to survive app reinstalls.
    func getDeviceId() -> String {
        if let existing = keychainRead(key: keychainDeviceIdKey) {
            return existing
        }
        
        let newId = UUID().uuidString
            .replacingOccurrences(of: "-", with: "")
            .lowercased()
            .prefix(deviceIdLength)
        let idString = String(newId)
        
        keychainWrite(key: keychainDeviceIdKey, value: idString)
        logger.info("Generated new device ID: \(idString)")
        return idString
    }
    
    // MARK: - Device Fingerprint
    
    /// Get or generate a persistent device fingerprint.
    /// Combines the persistent device ID with identifierForVendor.
    /// Format: 16 hex chars (e.g. "a3f7c1b9e2d4f608")
    func getDeviceFingerprint() -> String {
        if let existing = keychainRead(key: keychainFingerprintKey) {
            return existing
        }
        
        let deviceId = getDeviceId()
        
        // Use identifierForVendor as iOS equivalent of ANDROID_ID
        #if os(iOS)
        let vendorId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        #else
        let vendorId = UUID().uuidString
        #endif
        
        let fp = generateFingerprint(deviceId: deviceId, vendorId: vendorId)
        keychainWrite(key: keychainFingerprintKey, value: fp)
        logger.info("Generated device fingerprint: \(fp)")
        return fp
    }
    
    /// Get mesh ID as raw bytes for BLE advertising payloads.
    /// Returns 8 bytes from the 16 hex char fingerprint.
    func getMeshIdBytes() -> Data {
        let fp = getDeviceFingerprint()
        return hexToData(fp)
    }
    
    // MARK: - Fingerprint Generation
    
    private func generateFingerprint(deviceId: String, vendorId: String) -> String {
        let payload = "\(deviceId)|\(vendorId)"
        let data = Data(payload.utf8)
        let hash = SHA256.hash(data: data)
        return hash.prefix(fingerprintLength / 2)
            .map { String(format: "%02x", $0) }
            .joined()
    }
    
    // MARK: - Keychain Operations
    
    private func keychainRead(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceId,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    private func keychainWrite(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        // Delete existing entry first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceId,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new entry
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceId,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess {
            logger.error("Keychain write failed for \(key): \(status)")
        }
    }
    
    // MARK: - Hex Utility
    
    private func hexToData(_ hex: String) -> Data {
        var data = Data(capacity: hex.count / 2)
        var index = hex.startIndex
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            if let byte = UInt8(hex[index..<nextIndex], radix: 16) {
                data.append(byte)
            }
            index = nextIndex
        }
        return data
    }
}
