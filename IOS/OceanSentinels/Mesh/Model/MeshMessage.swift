import Foundation
import CryptoKit

// MARK: - Mesh Message

/// Represents a mesh message that can be relayed between devices.
/// Each message has a unique deterministic ID to prevent spam/duplicates.
///
/// Relay strategy (time-based, NOT hop-limited):
/// ─────────────────────────────────────────────
/// The message has NO hop-count TTL limit. It will keep relaying across
/// devices indefinitely until one of these conditions is met:
///   1. A device with internet delivers it to the server → DELIVERED
///   2. The message exceeds messageLifetimeMs (72 hours) → expired, dropped
///   3. The relay path reaches maxRelayPath (255 devices) → loop safety, dropped
///
/// Why no hop TTL:
///   In disaster/ocean scenarios, there may be 10, 20, or even 50+ devices
///   in a chain before reaching one with internet. A hop TTL would silently
///   kill hazard reports. Time-based expiry (72h) allows the message to
///   survive across any number of hops.
struct MeshMessage: Codable, Equatable, Identifiable {
    var id: String { messageId }
    
    /// Unique deterministic ID: SHA-256(deviceMac + timestamp + payload) → first 32 hex chars
    let messageId: String
    /// Device ID of the original sender (UUID-based, not actual MAC)
    let originDeviceMac: String
    /// Unique device fingerprint
    let originDeviceFingerprint: String
    /// Hazard type from the incident report
    let hazardType: String
    /// Location description
    let location: String
    /// GPS latitude
    let latitude: Double?
    /// GPS longitude
    let longitude: Double?
    /// Description of the hazard
    let description: String
    /// Urgency level: low, medium, high, critical
    let urgency: String
    /// Unix timestamp (millis) when the report was created
    let createdAtMillis: Int64
    /// Hop counter: incremented at each relay for diagnostics only (NOT used for TTL)
    var hopCount: Int
    /// Delivery status
    var status: MeshMessageStatus
    /// List of device IDs that have relayed this message (loop prevention)
    var relayPath: [String]
    /// Photo URL if any
    let photoUrl: String?
    /// Contact info if any
    let contactInfo: String?
    /// The reporter's user ID in Ocean Sentinels (if logged in)
    let reporterUserId: Int?
    /// Reference ID from server (assigned after successful upload)
    var serverReferenceId: String?
    
    // MARK: - Constants
    
    /// Message lifetime: 72 hours in milliseconds
    static let messageLifetimeMs: Int64 = 72 * 60 * 60 * 1000
    
    /// Maximum relay path length (loop safety bound).
    /// 255 allows a message to traverse up to 255 unique devices.
    /// With S=8 Coded PHY (~400m per hop), that's ~102 km theoretical max.
    static let maxRelayPath = 255
    
    // MARK: - Init
    
    init(
        messageId: String,
        originDeviceMac: String,
        originDeviceFingerprint: String,
        hazardType: String,
        location: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        description: String,
        urgency: String,
        createdAtMillis: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        hopCount: Int = 0,
        status: MeshMessageStatus = .pending,
        relayPath: [String] = [],
        photoUrl: String? = nil,
        contactInfo: String? = nil,
        reporterUserId: Int? = nil,
        serverReferenceId: String? = nil
    ) {
        self.messageId = messageId
        self.originDeviceMac = originDeviceMac
        self.originDeviceFingerprint = originDeviceFingerprint
        self.hazardType = hazardType
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.description = description
        self.urgency = urgency
        self.createdAtMillis = createdAtMillis
        self.hopCount = hopCount
        self.status = status
        self.relayPath = relayPath
        self.photoUrl = photoUrl
        self.contactInfo = contactInfo
        self.reporterUserId = reporterUserId
        self.serverReferenceId = serverReferenceId
    }
    
    // MARK: - Message ID Generation
    
    /// Generate a deterministic unique message ID from components.
    /// Same report produces the same ID — preventing spam.
    static func generateMessageId(
        deviceId: String,
        timestampMillis: Int64,
        hazardType: String,
        latitude: Double?,
        longitude: Double?,
        description: String
    ) -> String {
        let latStr = latitude.map { String($0) } ?? "null"
        let lonStr = longitude.map { String($0) } ?? "null"
        let payload: String = "\(deviceId)|\(timestampMillis)|\(hazardType)|\(latStr)|\(lonStr)|\(description)"
        let data = Data(payload.utf8)
        let hash = SHA256.hash(data: data)
        return hash.prefix(16).map { String(format: "%02x", $0) }.joined()
    }
    
    /// Generate a device fingerprint combining deviceId + vendorId.
    static func generateDeviceFingerprint(deviceId: String, vendorId: String) -> String {
        let payload = "\(deviceId)|\(vendorId)"
        let data = Data(payload.utf8)
        let hash = SHA256.hash(data: data)
        return hash.prefix(8).map { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Expiry
    
    /// Check if this message has expired based on creation time (72 hours).
    func isExpired() -> Bool {
        let nowMillis = Int64(Date().timeIntervalSince1970 * 1000)
        return (nowMillis - createdAtMillis) > Self.messageLifetimeMs
    }
    
    // MARK: - Relay
    
    /// Create a relayed copy with updated path and incremented hop count.
    /// Returns nil if expired, loop detected, or path limit reached.
    func relay(relayDeviceId: String) -> MeshMessage? {
        if isExpired() { return nil }
        if relayPath.contains(relayDeviceId) { return nil }
        if relayPath.count >= Self.maxRelayPath { return nil }
        
        var relayed = self
        relayed.hopCount = hopCount + 1
        relayed.relayPath = relayPath + [relayDeviceId]
        return relayed
    }
    
    // MARK: - Wire Format
    
    /// Serialize to bytes for BLE transmission.
    /// Wire format: [4-byte big-endian length prefix] + [UTF-8 JSON payload]
    func toBytes() -> Data {
        let json = toJson()
        let payload = Data(json.utf8)
        var result = Data(capacity: 4 + payload.count)
        
        // Big-endian length prefix
        let length = UInt32(payload.count)
        result.append(UInt8((length >> 24) & 0xFF))
        result.append(UInt8((length >> 16) & 0xFF))
        result.append(UInt8((length >> 8) & 0xFF))
        result.append(UInt8(length & 0xFF))
        result.append(payload)
        
        return result
    }
    
    /// Serialize to JSON string (compact, matching Android wire format)
    func toJson() -> String {
        var parts: [String] = []
        parts.append("\"id\":\"\(messageId)\"")
        parts.append("\"mac\":\"\(originDeviceMac)\"")
        parts.append("\"fp\":\"\(originDeviceFingerprint)\"")
        parts.append("\"ht\":\"\(jsonEscape(hazardType))\"")
        parts.append("\"loc\":\"\(jsonEscape(location))\"")
        if let lat = latitude { parts.append("\"lat\":\(lat)") }
        if let lng = longitude { parts.append("\"lng\":\(lng)") }
        parts.append("\"desc\":\"\(jsonEscape(description))\"")
        parts.append("\"urg\":\"\(urgency)\"")
        parts.append("\"ts\":\(createdAtMillis)")
        parts.append("\"hops\":\(hopCount)")
        let pathStr = relayPath.map { "\"\($0)\"" }.joined(separator: ",")
        parts.append("\"path\":[\(pathStr)]")
        if let photo = photoUrl { parts.append("\"photo\":\"\(jsonEscape(photo))\"") }
        if let contact = contactInfo { parts.append("\"contact\":\"\(jsonEscape(contact))\"") }
        if let uid = reporterUserId { parts.append("\"uid\":\(uid)") }
        
        return "{\(parts.joined(separator: ","))}"
    }
    
    /// Parse from JSON data received over BLE
    static func fromBytes(_ data: Data) -> MeshMessage? {
        guard data.count > 4 else { return nil }
        
        // Read 4-byte big-endian length prefix
        let length = Int(data[0]) << 24 | Int(data[1]) << 16 | Int(data[2]) << 8 | Int(data[3])
        
        guard data.count >= 4 + length else { return nil }
        
        let jsonData = data.subdata(in: 4..<(4 + length))
        return fromJsonData(jsonData)
    }
    
    /// Parse from JSON data
    static func fromJsonData(_ data: Data) -> MeshMessage? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return fromJson(json)
    }
    
    /// Parse from JSON dictionary
    static func fromJson(_ json: [String: Any]) -> MeshMessage? {
        guard let messageId = json["id"] as? String,
              let mac = json["mac"] as? String,
              let fp = json["fp"] as? String,
              let hazardType = json["ht"] as? String,
              let location = json["loc"] as? String,
              let description = json["desc"] as? String,
              let urgency = json["urg"] as? String,
              let timestamp = json["ts"] as? Int64 ?? (json["ts"] as? Int).map(Int64.init) else {
            return nil
        }
        
        return MeshMessage(
            messageId: messageId,
            originDeviceMac: mac,
            originDeviceFingerprint: fp,
            hazardType: hazardType,
            location: location,
            latitude: json["lat"] as? Double,
            longitude: json["lng"] as? Double,
            description: description,
            urgency: urgency,
            createdAtMillis: timestamp,
            hopCount: json["hops"] as? Int ?? 0,
            relayPath: json["path"] as? [String] ?? [],
            photoUrl: json["photo"] as? String,
            contactInfo: json["contact"] as? String,
            reporterUserId: json["uid"] as? Int
        )
    }
    
    // MARK: - Helpers
    
    private func jsonEscape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}

// MARK: - Mesh Message Status

/// Delivery status of a mesh message.
enum MeshMessageStatus: String, Codable {
    case pending = "pending"
    case sending = "sending"
    case relayed = "relayed"
    case delivered = "delivered"
    case failed = "failed"
    
    var value: String { rawValue }
    
    static func fromValue(_ value: String) -> MeshMessageStatus {
        MeshMessageStatus(rawValue: value) ?? .pending
    }
}

// MARK: - Mesh Transport

/// Transport method used for delivery.
enum MeshTransport: String, Codable {
    case internet = "internet"
    case bleCoded = "ble_coded"
    case bleStandard = "ble_standard"
    case localQueue = "local_queue"
    
    var value: String { rawValue }
    
    static func fromValue(_ value: String) -> MeshTransport {
        MeshTransport(rawValue: value) ?? .localQueue
    }
}
